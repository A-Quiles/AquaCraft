class_name Hud
extends Control
## Interfaz siempre visible: nivel, monedas, perlas, parámetros del agua, avisos y barra inferior.

var main: Node                       ## main.gd
var _coins: Label
var _pearls: Label
var _badge: LevelBadge
var _chips := {}                     ## clave → [label, dot]
var _toasts: VBoxContainer
var _bar := {}                       ## clave → Button
var _mission_dot: Control
var _hint: PanelContainer
var _hint_label: Label
var _food_row: HBoxContainer
var _food_buttons := {}
var _sheet: Control
var _modal: Modal


## Márgenes seguros (notch / barra de gestos) en unidades del lienzo: x = arriba, y = abajo.
static func safe_margins() -> Vector2:
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return Vector2.ZERO
	var safe := DisplayServer.get_display_safe_area()
	var vp: Vector2 = (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size
	var k := vp.y / float(win.y)
	return Vector2(maxf(0.0, safe.position.y) * k, maxf(0.0, win.y - safe.end.y) * k)


func _ready() -> void:
	theme = UI.setup()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top()
	_build_bottom()
	Game.changed.connect(refresh)
	Game.toast.connect(show_toast)
	Game.level_up.connect(_on_level_up)
	refresh()
	refresh_mode()
	if not Game.started:
		_welcome.call_deferred()


func _glass(radius := 26) -> StyleBoxFlat:
	var s := UI.box(Color(0.04, 0.12, 0.19, 0.58), radius)
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.content_margin_left = 12
	s.content_margin_right = 16
	return s


func _build_top() -> void:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_TOP_WIDE)
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", int(safe_margins().x) + 14)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var v := UI.vbox(12)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)

	var row := UI.hbox(12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge = LevelBadge.new()
	_badge.custom_minimum_size = Vector2(84, 84)
	_badge.gui_input.connect(_tap.bind(open_missions))
	row.add_child(_badge)
	var name_box := UI.vbox(0)
	name_box.alignment = BoxContainer.ALIGNMENT_CENTER
	name_box.add_child(UI.label("AquaCraft", 30, Color.WHITE, UI.heading))
	row.add_child(name_box)
	row.add_child(UI.spacer())
	_coins = _currency(row, "coin", func(): open_shop(0))
	_pearls = _currency(row, "pearl", func(): open_missions())
	v.add_child(row)

	var chips := UI.hbox(10)
	for c in [["temp", "thermo"], ["ph", "ph"], ["o2", "o2"], ["clean", "sparkle"]]:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 56
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, _glass(22))
		var h := UI.hbox(6)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(VIcon.make(c[1], 28))
		var l := UI.label("—", 24, Color.WHITE, UI.bold)
		h.add_child(l)
		var dot := Dot.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dot)
		b.add_child(h)
		b.pressed.connect(_chip_tip.bind(c[0]))
		chips.add_child(b)
		_chips[c[0]] = [l, dot]
	v.add_child(chips)

	_toasts = UI.vbox(8)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_child(_toasts)


func _currency(row: HBoxContainer, icon: String, on_tap: Callable) -> Label:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _glass())
	p.custom_minimum_size = Vector2(150, 56)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := UI.hbox(8)
	h.add_child(VIcon.make(icon, 34))
	var l := UI.label("0", 27, Color.WHITE, UI.bold)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(l)
	p.add_child(h)
	p.gui_input.connect(_tap.bind(on_tap))
	row.add_child(p)
	return l


func _tap(e: InputEvent, cb: Callable) -> void:
	if (e is InputEventScreenTouch or e is InputEventMouseButton) and not e.pressed:
		cb.call()


func _build_bottom() -> void:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	m.grow_vertical = Control.GROW_DIRECTION_BEGIN
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_bottom", int(safe_margins().y) + 14)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var v := UI.vbox(12)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)

	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", _glass())
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint_label = UI.label("", 22, Color.WHITE, UI.bold)
	_hint.add_child(_hint_label)
	v.add_child(_hint)

	_food_row = UI.hbox(10)
	_food_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for id in Catalog.FOOD_ORDER:
		var b := UI.button("")
		b.custom_minimum_size = Vector2(200, 60)
		b.pressed.connect(func():
			main.food_type = id
			refresh_food())
		_food_row.add_child(b)
		_food_buttons[id] = b
	v.add_child(_food_row)

	var bar := UI.hbox(10)
	for it in [["feed", "food", "Comida"], ["clean", "sponge", "Limpiar"], ["shop", "shop", "Tienda"],
			["fish", "fish", "Peces"], ["missions", "missions", "Misiones"]]:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 118)
		var col := UI.vbox(2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.offset_top = 8
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic := VIcon.make(it[1], 56)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(ic)
		var l := UI.label(it[2], 20, UI.NAVY, UI.bold)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		b.add_child(col)
		b.set_meta("label", l)
		b.pressed.connect(_on_bar.bind(it[0]))
		bar.add_child(b)
		_bar[it[0]] = b
	_mission_dot = Dot.new()
	_mission_dot.color = UI.BAD
	_mission_dot.custom_minimum_size = Vector2(22, 22)
	_mission_dot.position = Vector2(8, 8)
	_bar.missions.add_child(_mission_dot)
	v.add_child(bar)


func _style_bar(b: Button, active: bool) -> void:
	var bg := UI.TEAL if active else Color("fffaf2")
	var dark := UI.TEAL_D if active else Color("d9ccb8")
	for st in ["normal", "hover"]:
		b.add_theme_stylebox_override(st, UI.box(bg, 30, 7, dark))
	b.add_theme_stylebox_override("pressed", UI.box(dark.lerp(bg, 0.5), 30, 3, dark, 4))
	(b.get_meta("label") as Label).add_theme_color_override("font_color", Color.WHITE if active else UI.NAVY)


func _on_bar(k: String) -> void:
	match k:
		"feed": main.set_mode(main.Mode.FEED)
		"clean": main.set_mode(main.Mode.CLEAN)
		"shop": open_shop(0)
		"fish": open_fish(-1)
		"missions": open_missions()


func refresh_mode() -> void:
	_style_bar(_bar.feed, main.mode == main.Mode.FEED)
	_style_bar(_bar.clean, main.mode == main.Mode.CLEAN)
	for k in ["shop", "fish", "missions"]:
		_style_bar(_bar[k], false)
	_food_row.visible = main.mode == main.Mode.FEED
	_hint.visible = main.mode != main.Mode.NORMAL
	_hint_label.text = "Toca el agua para echar comida" if main.mode == main.Mode.FEED else "Desliza el dedo por el cristal para quitar las algas"
	refresh_food()


func refresh_food() -> void:
	for id in _food_buttons:
		var b: Button = _food_buttons[id]
		var n := "∞" if id == "escamas" else str(Game.food.get(id, 0))
		b.text = "%s  %s" % [Catalog.FOODS[id].name.split(" ")[0], n]
		var on: bool = main.food_type == id
		UI.button_colors(b, UI.CORAL if on else Color("fffaf2"), UI.CORAL_D if on else Color("d9ccb8"))
		b.add_theme_color_override("font_color", Color.WHITE if on else UI.NAVY)
		b.add_theme_color_override("font_hover_color", Color.WHITE if on else UI.NAVY)


func refresh() -> void:
	_coins.text = UI.num(Game.coins)
	_pearls.text = UI.num(Game.pearls)
	_badge.level = Game.level
	_badge.progress = float(Game.xp) / Game.xp_need(Game.level)
	_badge.queue_redraw()
	var w := Game.water()
	var out_t := 0
	var out_ph := 0
	for f in Game.fish:
		var s: Dictionary = Catalog.SPECIES[f.genes.sp]
		if Game.water_temp < s.temp[0] - 0.5 or Game.water_temp > s.temp[1] + 0.5: out_t += 1
		if w.ph < s.ph[0] - 0.2 or w.ph > s.ph[1] + 0.2: out_ph += 1
	var n := maxi(1, Game.fish.size())
	_chip("temp", "%.0f°C" % Game.water_temp, 0 if out_t == 0 else (1 if out_t * 2 < n else 2))
	_chip("ph", "pH %.1f" % w.ph, 0 if out_ph == 0 else (1 if out_ph * 2 < n else 2))
	_chip("o2", "%d%%" % roundi(w.o2), 0 if w.o2 >= 70.0 else (1 if w.o2 >= 55.0 else 2))
	_chip("clean", "%d%%" % roundi(100.0 - w.dirt), 0 if w.dirt < 40.0 else (1 if w.dirt < 70.0 else 2))
	_mission_dot.visible = Game.has_claimable()


func _chip(k: String, text: String, level: int) -> void:
	_chips[k][0].text = text
	_chips[k][1].color = [UI.GOOD, UI.WARN, UI.BAD][level]
	_chips[k][1].queue_redraw()


func _chip_tip(k: String) -> void:
	var w := Game.water()
	match k:
		"temp":
			if Game.equipment.heater != "":
				open_thermostat()
			else:
				show_toast("Agua a %.0f °C, como la habitación. Un calentador te deja elegir la temperatura." % Game.water_temp, "thermo")
		"ph":
			show_toast("pH %.1f. Las algas lo bajan y la raíz de manglar lo acidifica. Cada especie tiene su rango." % w.ph, "ph")
		"o2":
			show_toast("Oxígeno %d%%. Más peces consumen más; una bomba de aire o plantas ayudan." % roundi(w.o2), "o2")
		"clean":
			show_toast("Cristal limpio al %d%%. Pulsa Limpiar y frota. Un filtro frena las algas." % roundi(100.0 - w.dirt), "sponge")


# ───────────────────────── Avisos ─────────────────────────

func show_toast(text: String, icon := "star") -> void:
	if _toasts.get_child_count() >= 3:
		_toasts.get_child(0).queue_free()
	var p := UI.card(Color(1, 0.99, 0.96, 0.97), 26)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.custom_minimum_size.x = 0
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(10)
	var ic := VIcon.make(icon, 34)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var l := UI.wrap(UI.label(text, 23, UI.NAVY, UI.bold))
	l.custom_minimum_size.x = mini(560, 14 * text.length() + 20)
	h.add_child(l)
	p.add_child(h)
	_toasts.add_child(p)
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.4 + text.length() * 0.025)
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	tw.tween_callback(p.queue_free)


# ───────────────────────── Hojas y ventanas ─────────────────────────

func _open(c: Control) -> void:
	if _sheet and is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = c
	add_child(c)
	main.tank.overlay.selected_id = -1


func open_shop(tab: int) -> void:
	if main.mode != main.Mode.NORMAL:
		main.set_mode(main.mode)
	_open(ShopSheet.new(tab))


func open_fish(id: int) -> void:
	if main.mode != main.Mode.NORMAL:
		main.set_mode(main.mode)
	var s := FishSheet.new(id, main.tank)
	_open(s)
	main.tank.overlay.selected_id = id


func open_missions() -> void:
	_open(MissionsSheet.new())


func _show_modal(m: Modal) -> void:
	if _modal and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = m
	add_child(m)


## Botón atrás de Android: cierra lo que haya abierto. Devuelve true si cerró algo.
func back() -> bool:
	if _modal and is_instance_valid(_modal) and not _modal.is_queued_for_deletion():
		_modal.close()
		return true
	if _sheet and is_instance_valid(_sheet) and not _sheet.is_queued_for_deletion():
		_sheet.close()
		return true
	return false


func open_thermostat() -> void:
	var m := Modal.new()
	m.centered(VIcon.make("thermo", 64))
	m.centered(UI.title("Calentador", 40))
	var row := UI.hbox(24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var val := UI.label("%.0f °C" % Game.heater_target, 52, UI.NAVY, UI.heading)
	var minus := UI.button("")
	minus.add_child(_centered_icon("minus"))
	var plus := UI.button("")
	plus.add_child(_centered_icon("plus"))
	for b in [minus, plus]:
		b.custom_minimum_size = Vector2(84, 84)
	minus.pressed.connect(func():
		Game.set_heater_target(Game.heater_target - 1.0)
		val.text = "%.0f °C" % Game.heater_target)
	plus.pressed.connect(func():
		Game.set_heater_target(Game.heater_target + 1.0)
		val.text = "%.0f °C" % Game.heater_target)
	row.add_child(minus)
	row.add_child(val)
	row.add_child(plus)
	m.box.add_child(row)
	var seen := {}
	var lines := PackedStringArray()
	for f in Game.fish:
		var sp: String = f.genes.sp
		if not seen.has(sp):
			seen[sp] = true
			var s: Dictionary = Catalog.SPECIES[sp]
			lines.append("%s: %d–%d °C" % [s.name, s.temp[0], s.temp[1]])
	var info := UI.wrap(UI.label("Tus peces están cómodos entre:\n" + "\n".join(lines), 23, UI.MUTED))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.box.add_child(info)
	var ok := UI.button("Listo")
	ok.pressed.connect(m.close)
	m.box.add_child(ok)
	_show_modal(m)


func _centered_icon(k: String) -> VIcon:
	var i := VIcon.make(k, 36)
	i.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	return i


func _welcome() -> void:
	var m := Modal.new(false)
	var fish := UI.hbox(0)
	for f in Game.fish:
		fish.add_child(FishPreview.make(f.genes, 1.4))
	m.centered(fish)
	m.centered(UI.title("¡Bienvenido a AquaCraft!", 40))
	var t := UI.wrap(UI.label("Tu primera pecera ya tiene inquilinos. Dales de comer, mantén el cristal limpio y cría peces únicos para vender. Las misiones te guiarán.", 25, UI.MUTED))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.box.add_child(t)
	var go := UI.button("¡A bucear!", UI.CORAL, UI.CORAL_D)
	go.custom_minimum_size.y = 72
	go.pressed.connect(func():
		Game.started = true
		Game.save_game()
		m.close())
	m.box.add_child(go)
	_show_modal(m)


func _on_level_up(lv: int) -> void:
	var m := Modal.new()
	m.centered(VIcon.make("star", 90))
	m.centered(UI.title("¡Nivel %d!" % lv, 52))
	m.centered(UI.label("+%d perlas" % (2 + lv / 2), 28, UI.LAV_D, UI.bold))
	var news := PackedStringArray()
	for sp in Catalog.SPECIES_ORDER:
		if Catalog.SPECIES[sp].level == lv: news.append(Catalog.SPECIES[sp].name)
	for t in Catalog.TANKS:
		if t.level == lv: news.append(t.name)
	for id in Catalog.EQUIPMENT_ORDER:
		if Catalog.EQUIPMENT[id].level == lv: news.append(Catalog.EQUIPMENT[id].name)
	for id in Catalog.DECOR_ORDER:
		if Catalog.DECOR[id].level == lv: news.append(Catalog.DECOR[id].name)
	if not news.is_empty():
		var l := UI.wrap(UI.label("Nuevo en la tienda: " + ", ".join(news), 24, UI.MUTED))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m.box.add_child(l)
	var ok := UI.button("¡Genial!")
	ok.pressed.connect(m.close)
	m.box.add_child(ok)
	_show_modal(m)


class Dot extends Control:
	var color := Color.WHITE

	func _draw() -> void:
		draw_circle(size * 0.5, minf(size.x, size.y) * 0.5, color)


class LevelBadge extends Control:
	var level := 1
	var progress := 0.0

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		draw_circle(c, r, Color(0.04, 0.12, 0.19, 0.7))
		draw_arc(c, r - 5, 0, TAU, 40, Color(1, 1, 1, 0.15), 7, true)
		draw_arc(c, r - 5, -PI * 0.5, -PI * 0.5 + TAU * clampf(progress, 0.0, 1.0), 40, UI.SUN, 7, true)
		var txt := str(level)
		var fs := 34
		var w := UI.heading.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(UI.heading, c + Vector2(-w * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
