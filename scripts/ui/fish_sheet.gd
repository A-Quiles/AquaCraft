class_name FishSheet
extends Sheet
## Tus peces: lista, ficha (genes, valor, criar, vender) y huevos en incubación.

var tank: TankView
var tab := 0
var _list: VBoxContainer
var _confirm_sell := false
var _timer: Timer


func _init(fish_id: int, t: TankView) -> void:
	super("Mis peces", 0.84)
	tank = t
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.autostart = true
	_timer.timeout.connect(func():
		if tab == 1:
			_show_list())
	add_child(_timer)
	if fish_id >= 0:
		_show_detail(fish_id)
	else:
		_show_list()


func _show_list() -> void:
	clear_body()
	title_label.text = "Mis peces"
	tank.overlay.selected_id = -1
	tabs(["Peces %d/%d" % [Game.fish.size(), Game.capacity()], "Huevos %d" % Game.eggs.size()], tab, func(i: int):
		tab = i
		_show_list())
	_list = scroll_area()
	if tab == 0:
		var sorted := Game.fish.duplicate()
		sorted.sort_custom(func(a, b): return Genetics.rarity(a.genes) > Genetics.rarity(b.genes))
		for f in sorted:
			_list.add_child(_fish_row(f, _show_detail.bind(f.id)))
		if Game.fish.is_empty():
			_list.add_child(UI.label("No tienes peces. ¡Pásate por la tienda!", 24, UI.MUTED))
	else:
		_eggs()


## Fila de pez (botón con aspecto de tarjeta).
func _fish_row(f: Dictionary, on_tap: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 128
	for st in ["normal", "hover"]:
		b.add_theme_stylebox_override(st, UI.box(Color.WHITE, 24, 5, Color("eadfce")))
	b.add_theme_stylebox_override("pressed", UI.box(Color("f4fbfb"), 24, 2, Color("eadfce"), 3))
	b.pressed.connect(on_tap)
	var h := UI.hbox(14)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -18
	h.offset_top = 8
	h.offset_bottom = -10
	var pv := Previews.fish(f.genes, 100)
	pv.custom_minimum_size.x = 170
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", UI.box(Color("dff3f5"), 18))
	bg.add_child(pv)
	h.add_child(bg)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var r1 := UI.hbox(8)
	r1.add_child(UI.label(f.name, 27, UI.NAVY, UI.heading))
	r1.add_child(UI.rarity_pill(Genetics.rarity(f.genes)))
	v.add_child(r1)
	v.add_child(UI.label("%s · %s" % [Catalog.SPECIES[f.genes.sp].name, Game.stage_name(f)], 20, UI.MUTED, UI.bold))
	var bars := UI.hbox(10)
	for sb in [["food", 100.0 - f.hunger, UI.CORAL], ["health", f.health, UI.GOOD], ["happy", f.happy, UI.SUN]]:
		var s := UI.stat_bar(sb[0], sb[1], sb[2])
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bars.add_child(s)
	v.add_child(bars)
	for c in v.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	b.add_child(h)
	return b


func _show_detail(id: int) -> void:
	var f := Game.get_fish(id)
	if f.is_empty():
		_show_list()
		return
	_confirm_sell = false
	tank.overlay.selected_id = id
	clear_body()
	title_label.text = f.name
	var back := UI.button("‹ Mis peces", UI.SAND, Color("e2d3bd"))
	back.add_theme_color_override("font_color", UI.NAVY)
	back.add_theme_color_override("font_hover_color", UI.NAVY)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_show_list)
	body.add_child(back)
	var v := scroll_area()
	var aq := PanelContainer.new()
	var st := UI.box(Color("0f5a73"), 26)
	st.bg_color = Color("12627c")
	aq.add_theme_stylebox_override("panel", st)
	aq.add_child(Previews.fish(f.genes, 230, 480))
	v.add_child(aq)

	var g: Dictionary = f.genes
	var pills := UI.hbox(8)
	pills.add_child(UI.rarity_pill(Genetics.rarity(g)))
	pills.add_child(UI.pill(Catalog.SPECIES[g.sp].name, UI.TEAL))
	pills.add_child(UI.pill(Game.stage_name(f), UI.LAV))
	if f.bred:
		pills.add_child(UI.pill("Criado por ti", UI.CORAL))
	v.add_child(pills)

	var stats := UI.card()
	var sv := UI.vbox(10)
	for row in [["food", "Saciedad", 100.0 - f.hunger, UI.CORAL], ["health", "Salud", f.health, UI.GOOD],
			["happy", "Felicidad", f.happy, UI.SUN]]:
		var h := UI.hbox(10)
		h.add_child(VIcon.make(row[0], 30))
		var l := UI.label(row[1], 22, UI.NAVY, UI.bold)
		l.custom_minimum_size.x = 130
		h.add_child(l)
		var b := UI.bar(row[2], row[3], 16)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
		sv.add_child(h)
	if f.grow < 1.0:
		sv.add_child(UI.label("Creciendo: %d%%  (los gránulos aceleran)" % int(f.grow * 100.0), 21, UI.MUTED, UI.bold))
	if int(f.get("problems", 0)) > 0:
		sv.add_child(UI.wrap(UI.label("Algo le molesta: revisa temperatura, pH, oxígeno, limpieza o hambre.", 21, UI.BAD, UI.bold)))
	stats.add_child(sv)
	v.add_child(stats)

	var genes := UI.card()
	var gv := UI.vbox(6)
	gv.add_child(UI.label("Genes", 24, UI.NAVY, UI.heading))
	var muts := Genetics.mutation_names(g)
	for line in ["Patrón: %s" % Catalog.PATTERN_NAMES[g.pat], "Tamaño: %.2f" % g.size,
			"Mutaciones: %s" % (", ".join(muts) if not muts.is_empty() else "ninguna")]:
		gv.add_child(UI.wrap(UI.label(line, 22, UI.MUTED, UI.bold)))
	genes.add_child(gv)
	v.add_child(genes)

	var value := Genetics.value(f)
	var actions := UI.hbox(12)
	var block := Game.breed_block(f)
	var breed := UI.button("Criar" if block == "" else block, UI.TEAL)
	breed.disabled = block != ""
	breed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	breed.custom_minimum_size.y = 68
	breed.pressed.connect(_show_partners.bind(id))
	actions.add_child(breed)
	var sell := UI.price_button(value, "coins", "Vender")
	sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell.custom_minimum_size.y = 68
	sell.pressed.connect(func():
		if not _confirm_sell:
			_confirm_sell = true
			UI.button_colors(sell, UI.CORAL, UI.CORAL_D)
			sell.get_child(0).get_child(0).text = "¿Seguro?"
			return
		Game.sell_fish(id)
		_show_list())
	actions.add_child(sell)
	v.add_child(actions)


func _show_partners(id: int) -> void:
	var f := Game.get_fish(id)
	clear_body()
	title_label.text = "Elige pareja"
	var back := UI.button("‹ %s" % f.name, UI.SAND, Color("e2d3bd"))
	back.add_theme_color_override("font_color", UI.NAVY)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_show_detail.bind(id))
	body.add_child(back)
	var v := scroll_area()
	var partners := Game.breed_partners(f)
	if Game.space_left() <= 0:
		v.add_child(UI.wrap(UI.label("La pecera está llena. Vende algún pez o amplía la pecera para que quepan las crías.", 24, UI.BAD, UI.bold)))
		return
	if partners.is_empty():
		v.add_child(UI.wrap(UI.label("No hay pareja disponible. Necesitas otro %s adulto, sano, feliz y descansado." % Catalog.SPECIES[f.genes.sp].name.to_lower(), 24, UI.MUTED, UI.bold)))
		return
	v.add_child(UI.wrap(UI.label("Las crías heredan colores, patrón, tamaño y mutaciones de ambos padres.", 22, UI.MUTED)))
	for p in partners:
		v.add_child(_fish_row(p, func():
			if Game.breed(id, p.id):
				tab = 1
				_show_list()))


func _eggs() -> void:
	if Game.eggs.is_empty():
		_list.add_child(UI.wrap(UI.label("No hay huevos. Abre la ficha de un pez adulto y pulsa «Criar».", 24, UI.MUTED)))
		return
	var now := Time.get_unix_time_from_system()
	for e in Game.eggs:
		var c := UI.card()
		var h := UI.hbox(14)
		h.add_child(VIcon.make("egg", 64))
		var v := UI.vbox(6)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.label("Huevo de %s" % Catalog.SPECIES[e.genes.sp].name, 25, UI.NAVY, UI.heading))
		v.add_child(UI.label("%s · faltan %s" % [e.get("parents", ""), Game.fmt_duration(e.hatch_at - now)], 20, UI.MUTED, UI.bold))
		var pb := UI.bar(100.0 * (1.0 - (e.hatch_at - now) / maxf(1.0, e.total)), UI.SUN, 14)
		v.add_child(pb)
		h.add_child(v)
		var b := UI.price_button(Game.hatch_cost(e), "pearls", "Ya")
		b.custom_minimum_size = Vector2(150, 64)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(func():
			Game.hatch_now(e.id)
			_show_list())
		h.add_child(b)
		c.add_child(h)
		_list.add_child(c)
