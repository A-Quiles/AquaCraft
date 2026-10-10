class_name ShopSheet
extends Sheet
## Mercado: peces (y exóticos del día), peceras, equipo, decoración/sustrato y comida.

const TABS := ["Peces", "Peceras", "Equipo", "Decorar", "Cuidados"]

var tab := 0
var _list: VBoxContainer
var _scroll: ScrollContainer


func _init(start_tab := 0) -> void:
	super("Tienda", 0.84)
	tab = start_tab
	_build()


func _build() -> void:
	var keep := _scroll.scroll_vertical if _scroll else 0
	clear_body()
	tabs(TABS, tab, func(i: int):
		tab = i
		_scroll = null
		_build())
	_list = scroll_area()
	_scroll = _list.get_parent()
	match tab:
		0: _fish_tab()
		1: _tank_tab()
		2: _equip_tab()
		3: _decor_tab()
		4: _food_tab()
	if keep > 0:
		(func(): _scroll.scroll_vertical = keep).call_deferred()


func _after(action: Callable) -> void:
	action.call()
	_build()


func _section(text: String, sub := "") -> void:
	var h := UI.hbox(10)
	h.add_child(UI.title(text, 30))
	if sub != "":
		var s := UI.label(sub, 22, UI.MUTED, UI.bold)
		s.size_flags_vertical = Control.SIZE_SHRINK_END
		h.add_child(s)
	_list.add_child(h)


func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	_list.add_child(g)
	return g


## Tarjeta estándar: miniatura, nombre, descripción y acción.
func _card(grid: GridContainer, preview: Control, name: String, desc: String, action: Control, badge: Control = null, warn := "") -> void:
	var c := UI.card()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(8)
	var top := Control.new()
	top.custom_minimum_size = preview.custom_minimum_size
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.add_child(preview)
	if badge:
		badge.position = Vector2(0, 0)
		top.add_child(badge)
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", UI.box(Color("eaf7f8"), 18))
	bg.add_child(top)
	v.add_child(bg)
	v.add_child(UI.label(name, 25, UI.NAVY, UI.bold))
	var d := UI.wrap(UI.label(desc, 20, UI.MUTED))
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	if warn != "":
		v.add_child(UI.wrap(UI.label(warn, 19, UI.BAD, UI.bold)))
	v.add_child(action)
	c.add_child(v)
	grid.add_child(c)


func _price(amount: int, cur: String, level: int, on_buy: Callable) -> Button:
	if Game.level < level:
		var b := UI.button("Nivel %d" % level)
		b.disabled = true
		b.custom_minimum_size.y = 62
		return b
	var b := UI.price_button(amount, cur)
	var have := Game.coins if cur == "coins" else Game.pearls
	if have < amount:
		b.modulate = Color(1, 1, 1, 0.55)
	b.pressed.connect(_after.bind(on_buy))
	return b


func _state(text: String) -> Button:
	var b := UI.button(text)
	b.disabled = true
	b.custom_minimum_size.y = 62
	return b


# ───────────────────────── Pestañas ─────────────────────────

func _fish_tab() -> void:
	var ev := Game.current_event()
	if not ev.is_empty():
		_section("Evento: %s" % ev.name, "quedan %d días" % Game.event_days_left(ev))
		var ge := _grid()
		var info: Array = ev.fish[Game.water_kind]
		var r := RandomNumberGenerator.new()
		r.seed = 5
		var g := Genetics.random_genes(info[0], r)
		for k in 3:
			g[["a", "b", "f"][k]] = Genetics._hsv(info[2][k])
		g.ev = ev.id
		_card(ge, Previews.fish(g), info[1], "Edición limitada: solo durante %s. Cuenta como una variante nueva." % ev.name,
			_price(int(Catalog.SPECIES[info[0]].price * Catalog.EVENT_FISH_PRICE), "coins", 1, Game.buy_event_fish), UI.pill("Evento", UI.CORAL))
		var did: String = ev.decor
		var dd: Dictionary = Catalog.DECOR[did]
		_card(ge, Previews.decor(did), dd.name, dd.desc, _price(dd.price, dd.cur, 1, Game.buy_decor.bind(did)), UI.pill("Evento", UI.CORAL))
	_section("Exóticos de hoy", "con mutación")
	var g := _grid()
	var offers := Game.daily_offers()
	for i in offers.size():
		var o: Dictionary = offers[i]
		var genes: Dictionary = o.genes
		var muts := ", ".join(Genetics.mutation_names(genes))
		var act: Control = _state("Vendido") if o.sold else _price(o.price, "coins", 1, Game.buy_offer.bind(i))
		_card(g, Previews.fish(genes), Catalog.SPECIES[genes.sp].name, muts, act, UI.rarity_pill(Genetics.rarity(genes)))
	_section("Especies", "Espacio: %d/%d" % [Game.fish.size() + Game.eggs.size(), Game.capacity()])
	g = _grid()
	for sp in Catalog.SPECIES_ORDER:
		var s: Dictionary = Catalog.SPECIES[sp]
		if not Catalog.fits(s, Game.water_kind):
			continue
		var r := RandomNumberGenerator.new()
		r.seed = hash(sp)
		var desc := "%s\n%s.\n%d–%d °C · pH %.1f–%.1f" % [s.desc, Game.diet_text(sp), s.temp[0], s.temp[1], s.ph[0], s.ph[1]]
		_card(g, Previews.fish(Genetics.random_genes(sp, r)), s.name, desc, _price(s.price, "coins", s.level, Game.buy_fish.bind(sp)), null,
			Game.compat_warning(sp) if Game.level >= s.level else "")


func _tank_tab() -> void:
	_section("Peceras", "tus peces y adornos se mudan solos")
	var g := _grid()
	for i in Catalog.TANKS.size():
		var t: Dictionary = Catalog.TANKS[i]
		var desc := "%s\nHasta %d peces · %d adornos" % [t.desc, t.cap, t.slots]
		var act: Control
		if i == Game.tank_tier:
			act = _state("En uso")
		elif i < Game.tank_tier:
			act = _state("Superada")
		else:
			act = _price(t.price, "coins", t.level, Game.buy_tank.bind(i))
		_card(g, Previews.art("tank", i), t.name, desc, act)
	_section("Más peceras", "tienes %d de %d" % [Game.tanks.size(), Catalog.TANK_SLOTS.size()])
	var gs := _grid()
	var more := UI.button("Ver peceras")
	more.custom_minimum_size.y = 62
	more.pressed.connect(func():
		close()
		get_parent().open_tank_picker())
	_card(gs, Previews.art("tank", 1), "Otra pecera", "Cría aparte, separa peces que no se llevan o ten agua dulce y salada a la vez.", more)
	var other := "salada" if Game.water_kind == "dulce" else "dulce"
	_section("Tipo de agua", Catalog.WATER_NAMES[Game.water_kind])
	var g2 := _grid()
	var desc := "Peces, plantas y cuidados distintos. La pecera debe estar vacía; lo incompatible se guarda."
	_card(g2, Previews.icon("ph"), "Pasar a %s" % Catalog.WATER_NAMES[other].to_lower(), desc, _price(400, "coins", 1, Game.convert_water))


func _equip_tab() -> void:
	var t: Dictionary = Catalog.TANKS[Game.tank_tier]
	var note := UI.wrap(UI.label("Tu %s admite equipo %s. Lo básico es barato pero se gasta antes, rinde menos y se rompe si lo descuidas." % [
		t.name, "solo básico" if t.max_q == 1 else ("hasta estándar" if t.max_q == 2 else "de cualquier calidad")], 21, UI.MUTED, UI.bold))
	_list.add_child(note)
	for slot in (["filter", "heater", "pump", "light", "thermo", "ato"] if Game.water_kind == "salada" else ["filter", "heater", "pump", "light", "thermo"]):
		_section(Catalog.SLOT_NAMES[slot], "uno a la vez" if slot in t.equip else "no cabe en esta pecera")
		var g := _grid()
		for id in Catalog.EQUIPMENT_ORDER:
			var e: Dictionary = Catalog.EQUIPMENT[id]
			if e.slot != slot or not Catalog.fits(e, Game.water_kind):
				continue
			var cur: String = Game.equipment[slot]
			var why := Game.install_block(id)
			var stored := int(Game.equip_inv.get(id, 0))
			var act: Control
			if cur == id:
				act = _state("Instalado · %d%%" % roundi(Game.condition(slot)) if e.wear > 0.0 else "Instalado")
			elif why != "":
				act = _state(why)
			elif stored > 0:
				act = UI.button("Instalar (guardado)")
				act.custom_minimum_size.y = 62
				act.add_theme_font_size_override("font_size", 21)
				act.pressed.connect(_after.bind(Game.install_stored.bind(id)))
			elif cur != "" and int(Catalog.EQUIPMENT[cur].q) > int(e.q):
				act = _state("Tienes uno mejor")
			else:
				act = _price(e.price, "coins", e.level, Game.buy_equipment.bind(id))
			var desc: String = e.desc + ("\nMantenimiento: %s" % e.maint.to_lower() if e.wear > 0.0 else "")
			_card(g, Previews.art("equipment", id), e.name, desc, act, UI.pill(Catalog.QUALITY_NAMES[e.q], Catalog.color(Catalog.QUALITY_COLORS[e.q])))


func _decor_tab() -> void:
	var hint := UI.wrap(UI.label("Coloca y mueve las piezas con el botón «Decorar» de la pantalla principal.", 21, UI.MUTED, UI.bold))
	_list.add_child(hint)
	_section("Inventario", "%d/%d colocadas" % [Game.decor.size(), Game.decor_slots()])
	if Game.decor_inv.is_empty():
		_list.add_child(UI.label("No tienes piezas guardadas.", 22, UI.MUTED))
	else:
		var g := _grid()
		for id in Game.decor_inv:
			var d: Dictionary = Catalog.DECOR[id]
			var row := UI.hbox(8)
			var put := UI.button("Colocar")
			put.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			put.custom_minimum_size.y = 62
			put.pressed.connect(_after.bind(Game.place_decor.bind(id)))
			row.add_child(put)
			var sell := UI.button("+%d" % int(d.price / 2), UI.CORAL, UI.CORAL_D)
			sell.custom_minimum_size.y = 62
			sell.pressed.connect(_after.bind(Game.sell_decor_inv.bind(id)))
			row.add_child(sell)
			_card(g, Previews.decor(id, 110), "%s ×%d" % [d.name, Game.decor_inv[id]], "", row)
	_section("Sustrato")
	var g2 := _grid()
	for id in Catalog.SUBSTRATE_ORDER:
		var s: Dictionary = Catalog.SUBSTRATES[id]
		if not Catalog.fits(s, Game.water_kind):
			continue
		var act: Control
		if Game.substrate == id:
			act = _state("En uso")
		elif id in Game.owned_substrates:
			act = UI.button("Usar")
			act.custom_minimum_size.y = 62
			act.pressed.connect(_after.bind(Game.buy_substrate.bind(id)))
		else:
			act = _price(s.price, s.cur, s.level, Game.buy_substrate.bind(id))
		var desc := "+%d felicidad" % s.happy if s.happy > 0 else "Clásica y natural."
		if s.has("plants"):
			desc += "\nLas plantas rinden más."
		_card(g2, Previews.substrate(id, 110), s.name, desc, act)
	_section("Plantas y adornos")
	var g3 := _grid()
	for id in Catalog.DECOR_ORDER:
		var d: Dictionary = Catalog.DECOR[id]
		if not Catalog.fits(d, Game.water_kind) or d.has("event"):
			continue
		_card(g3, Previews.decor(id), d.name, d.desc, _price(d.price, d.cur, d.level, Game.buy_decor.bind(id)))


func _food_tab() -> void:
	_section("Comida")
	var g := _grid()
	for id in Catalog.FOOD_ORDER:
		var f: Dictionary = Catalog.FOODS[id]
		var act: Control
		if f.price == 0:
			act = _state("Gratis")
		else:
			act = _price(f.price, "coins", f.level, Game.buy_food.bind(id))
		var have := "∞" if f.price == 0 else str(Game.food.get(id, 0))
		var desc := "%s\nTienes: %s%s" % [f.desc, have, (" · pack de %d" % f.pack) if f.pack > 0 else ""]
		_card(g, Previews.art("food", id), f.name, desc, act)
	_section("Productos para el agua", "en el bote «Agua» de la estantería")
	var g2 := _grid()
	for id in Catalog.PRODUCT_ORDER:
		var pr: Dictionary = Catalog.PRODUCTS[id]
		if not Catalog.fits(pr, Game.water_kind):
			continue
		var desc := "%s\nTienes: %d · pack de %d" % [pr.desc, Game.products.get(id, 0), pr.pack]
		_card(g2, Previews.art("product", id), pr.name, desc, _price(pr.price, "coins", pr.level, Game.buy_product.bind(id)))
