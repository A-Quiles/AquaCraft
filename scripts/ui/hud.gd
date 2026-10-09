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
var _sheet: Control
var _modal: Modal
var _temp_alarm := false
var _tutorial: Control


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
		(start_tutorial if Game.stats.get("setup", false) else open_setup).call_deferred()


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

	var chips := UI.hbox(8)
	for c in [["temp", "thermo"], ["ph", "ph"], ["sal", "ph"], ["o2", "o2"], ["clean", "sparkle"]]:
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
		var l := UI.label("—", 22, Color.WHITE, UI.bold)
		h.add_child(l)
		var dot := Dot.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dot)
		b.add_child(h)
		b.pressed.connect(_chip_tip.bind(c[0]))
		chips.add_child(b)
		_chips[c[0]] = [l, dot, b]
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

	# Aviso del modo activo con botón para soltar la herramienta (bote de comida, esponja...).
	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", _glass())
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var hh := UI.hbox(12)
	_hint_label = UI.wrap(UI.label("", 21, Color.WHITE, UI.bold))
	_hint_label.custom_minimum_size.x = 430
	hh.add_child(_hint_label)
	var done := UI.button("Listo", UI.CORAL, UI.CORAL_D)
	done.add_theme_font_size_override("font_size", 21)
	done.pressed.connect(func(): main.set_mode(main.mode))
	hh.add_child(done)
	_hint.add_child(hh)
	v.add_child(_hint)

	var bar := UI.hbox(8)
	for it in [["edit", "plant", "Decorar"], ["shop", "shop", "Tienda"], ["fish", "fish", "Peces"], ["missions", "missions", "Misiones"]]:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 118)
		var col := UI.vbox(2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.offset_top = 8
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic := VIcon.make(it[1], 54)
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
		"edit": main.set_mode(main.Mode.EDIT)
		"shop": open_shop(0)
		"fish": open_fish(-1)
		"missions": open_missions()


func refresh_mode() -> void:
	_style_bar(_bar.edit, main.mode == main.Mode.EDIT)
	for k in ["shop", "fish", "missions"]:
		_style_bar(_bar[k], false)
	_hint.visible = main.mode != main.Mode.NORMAL
	_hint_label.text = {main.Mode.FEED: "Toca el agua para echar %s" % Catalog.FOODS[main.food_type].name.to_lower(),
		main.Mode.CLEAN: "Frota el cristal con el limpiador para quitar las algas",
		main.Mode.EDIT: "Arrastra plantas, adornos o aparatos · tócalos para más opciones"}.get(main.mode, "")


func refresh() -> void:
	_coins.text = UI.num(Game.coins)
	_pearls.text = UI.num(Game.pearls)
	_badge.level = Game.level
	_badge.progress = float(Game.xp) / Game.xp_need(Game.level)
	_badge.queue_redraw()
	var w := Game.water()
	var out_t := 0
	var out_ph := 0
	var out_sal := 0
	for f in Game.fish:
		var pr := Game.fish_problems(f)
		out_t += int("Temperatura" in pr)
		out_ph += int("pH" in pr)
		out_sal += int("Salinidad" in pr)
	var n := maxi(1, Game.fish.size())
	var t_txt := Game.thermometer_text()
	if t_txt == "":
		_chip("temp", "¿? °C", 1)
	else:
		_chip("temp", t_txt, 0 if out_t == 0 else (1 if out_t * 2 < n else 2))
		if out_t > 0 and Game.equipment.thermo == "digital" and not _temp_alarm:
			show_toast("Alarma del termómetro: a algunos peces no les va esta temperatura", "thermo")
		_temp_alarm = out_t > 0
	_chip("ph", "pH %.1f" % w.ph, 0 if out_ph == 0 else (1 if out_ph * 2 < n else 2))
	_chips.sal[2].visible = Game.water_kind == "salada"
	_chip("sal", "%.3f" % Game.salinity, 0 if out_sal == 0 else (1 if out_sal * 2 < n else 2))
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
			if Game.thermometer_text() == "":
				show_toast("Sin termómetro no sabes la temperatura. Instala uno (o cámbiale la pila).", "thermo")
			elif Game.equipment.heater == "calentador":
				open_thermostat()
			elif Game.equipment.heater != "":
				show_toast("El calentador fijo mantiene el agua a 25 °C. Con termostato podrás elegirla.", "thermo")
			else:
				show_toast("Agua a temperatura ambiente. Un calentador la mantiene estable.", "thermo")
		"ph":
			show_toast("pH %.1f. Las algas lo bajan y la raíz de manglar lo acidifica. Cada especie tiene su rango." % w.ph, "ph")
		"sal":
			open_salinity()
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
	if _modal and is_instance_valid(_modal) and not _modal.closing:
		_modal.close()
		return true
	if _sheet and is_instance_valid(_sheet) and not _sheet.get("closing"):
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


func start_tutorial() -> void:
	if _tutorial and is_instance_valid(_tutorial):
		return
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_tutorial = Tutorial.new()
	_tutorial.hud = self
	_tutorial.main = main
	layer.add_child(_tutorial)
	_tutorial.tree_exited.connect(layer.queue_free)


## Primera partida: elegir modo de juego y tipo de agua. Reinicia la escena con la pecera nueva.
func open_setup() -> void:
	var m := Modal.new(false)
	m.centered(UI.title("¡Bienvenido a AquaCraft!", 40))
	m.box.add_child(_center_label("¿Cómo quieres jugar? Podrás cambiarlo luego en Misiones.", 23))
	var pick := {"mode": "normal", "water": "dulce"}
	var mode_buttons := {}
	var desc := _center_label(Catalog.MODES.normal.desc, 21)
	for id in Catalog.MODE_ORDER:
		var b := UI.button(Catalog.MODES[id].name)
		b.custom_minimum_size.y = 64
		mode_buttons[id] = b
		m.box.add_child(b)
	m.box.add_child(desc)
	var water_row := UI.hbox(10)
	var water_buttons := {}
	for wid in ["dulce", "salada"]:
		var b := UI.button(Catalog.WATER_NAMES[wid])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		water_buttons[wid] = b
		water_row.add_child(b)
	m.box.add_child(water_row)
	var paint := func():
		for id in mode_buttons:
			var on: bool = pick.mode == id
			UI.button_colors(mode_buttons[id], UI.TEAL if on else Color("e7ddd0"), UI.TEAL_D if on else Color("cfc2ae"))
			for k in ["font_color", "font_hover_color", "font_pressed_color"]:
				mode_buttons[id].add_theme_color_override(k, Color.WHITE if on else UI.NAVY)
		for wid in water_buttons:
			var on: bool = pick.water == wid
			UI.button_colors(water_buttons[wid], UI.LAV if on else Color("e7ddd0"), UI.LAV_D if on else Color("cfc2ae"))
			for k in ["font_color", "font_hover_color", "font_pressed_color"]:
				water_buttons[wid].add_theme_color_override(k, Color.WHITE if on else UI.NAVY)
		desc.text = Catalog.MODES[pick.mode].desc
	for id in mode_buttons:
		mode_buttons[id].pressed.connect(func():
			pick.mode = id
			paint.call())
	for wid in water_buttons:
		water_buttons[wid].pressed.connect(func():
			pick.water = wid
			paint.call())
	paint.call()
	var go := UI.button("¡Empezar!", UI.CORAL, UI.CORAL_D)
	go.custom_minimum_size.y = 72
	go.pressed.connect(func():
		Game.new_game(pick.mode, pick.water)
		Game.stats.setup = true
		Game.save_game()
		get_tree().reload_current_scene())
	m.box.add_child(go)
	_show_modal(m)


func open_mode_picker() -> void:
	var m := Modal.new()
	m.centered(UI.title("Modo de juego", 38))
	for id in Catalog.MODE_ORDER:
		var b := UI.button(Catalog.MODES[id].name + ("  (actual)" if id == Game.mode else ""), UI.TEAL if id == Game.mode else UI.LAV, UI.TEAL_D if id == Game.mode else UI.LAV_D)
		b.custom_minimum_size.y = 64
		b.pressed.connect(func():
			Game.set_game_mode(id)
			m.close())
		m.box.add_child(b)
		m.box.add_child(_center_label(Catalog.MODES[id].desc, 20))
	_show_modal(m)


## Salinidad (agua salada): se concentra al evaporarse el agua; se corrige reponiendo agua dulce.
func open_salinity() -> void:
	var m := Modal.new()
	m.centered(VIcon.make("ph", 64))
	m.centered(UI.title("Salinidad %.3f" % Game.salinity, 38))
	m.box.add_child(_center_label("Ideal: %.3f – %.3f. El agua se evapora y la sal se concentra; repón con agua dulce (nunca salada)." % [Catalog.SALINITY[0], Catalog.SALINITY[1]], 22))
	if float(Game.mk("evap")) <= 0.0:
		m.box.add_child(_center_label("En modo Relax la salinidad se mantiene sola.", 21, UI.MUTED))
	elif Game.equipment.ato != "":
		m.box.add_child(_center_label("Tu reposición automática se encarga (si tiene el depósito lleno).", 21, UI.MUTED))
	m.box.add_child(_hold_button("Mantén pulsado: reponer agua dulce", func():
		Game.top_up()
		m.close()))
	_show_modal(m)


## Producto de la estantería: qué hace, cuánto queda y cómo está el agua ahora.
func open_product(id: String) -> void:
	var pr: Dictionary = Catalog.PRODUCTS[id]
	var m := Modal.new()
	m.centered(VIcon.make("ph" if id != "antialgas" else "sparkle", 64))
	m.centered(UI.title(pr.name, 38))
	m.box.add_child(_center_label(pr.desc, 22))
	var w := Game.water()
	var info := "Ahora: pH %.2f · cristal limpio al %d%%" % [w.ph, roundi(100.0 - w.dirt)]
	var seen := {}
	for f in Game.fish:
		var sp: Dictionary = Catalog.SPECIES[f.genes.sp]
		if not seen.has(sp.name):
			seen[sp.name] = true
			info += "\n%s: pH %.1f–%.1f" % [sp.name, sp.ph[0], sp.ph[1]]
	m.box.add_child(_center_label(info, 21, UI.NAVY))
	var n: int = Game.products.get(id, 0)
	var use := UI.button("Echar al agua (te quedan %d)" % n, UI.TEAL, UI.TEAL_D)
	use.custom_minimum_size.y = 68
	use.disabled = n <= 0
	use.pressed.connect(func():
		Game.use_product(id)
		m.close())
	m.box.add_child(use)
	var buy := UI.price_button(pr.price, "coins", "+%d" % pr.pack)
	buy.pressed.connect(func():
		Game.buy_product(id)
		m.close()
		open_product(id))
	m.box.add_child(buy)
	_show_modal(m)


## Ficha de un aparato: estado, efecto y mantenimiento (mantener pulsado).
func open_equipment(slot: String) -> void:
	var id: String = Game.equipment.get(slot, "")
	var m := Modal.new()
	var icons := {"filter": "sparkle", "heater": "thermo", "pump": "o2", "light": "star", "thermo": "thermo", "ato": "ph"}
	m.centered(VIcon.make(icons[slot], 64))
	if id == "":
		m.centered(UI.title(Catalog.SLOT_NAMES[slot], 38))
		m.box.add_child(_center_label("Llevas la luz básica de serie. Una pantalla LED da más color y felicidad.", 24))
	else:
		var e: Dictionary = Catalog.EQUIPMENT[id]
		m.centered(UI.title(e.name, 36))
		m.box.add_child(_center_label(e.desc, 23))
		if e.wear > 0.0:
			var cond := Game.condition(slot)
			var row := UI.hbox(12)
			row.add_child(UI.label("Estado", 24, UI.NAVY, UI.bold))
			var bar := UI.bar(cond, UI.GOOD if cond >= 60.0 else (UI.WARN if cond >= 30.0 else UI.BAD), 18)
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(bar)
			row.add_child(UI.label("%d%%" % roundi(cond), 24, UI.NAVY, UI.bold))
			m.box.add_child(row)
			if cond < 60.0:
				m.box.add_child(_center_label("Rinde al %d%%. Hazle mantenimiento para que vuelva a funcionar al máximo." % roundi(Game.efficiency(slot) * 100.0), 21, UI.BAD))
			m.box.add_child(_hold_button("Mantén pulsado: %s" % e.maint, func():
				Game.maintain(slot)
				m.close()))
		else:
			m.box.add_child(_center_label("No necesita mantenimiento.", 22, UI.MUTED))
		if id == "calentador":
			var t := UI.button("Ajustar temperatura")
			t.pressed.connect(func():
				m.close()
				open_thermostat())
			m.box.add_child(t)
	var shop := UI.button("Ver otros modelos", UI.SAND, Color("e2d3bd"))
	shop.add_theme_color_override("font_color", UI.NAVY)
	shop.pressed.connect(func():
		m.close()
		open_shop(2))
	m.box.add_child(shop)
	_show_modal(m)


## Opciones de una decoración colocada (modo Decorar).
func open_decor_menu(i: int) -> void:
	if i < 0 or i >= Game.decor.size():
		return
	var it: Dictionary = Game.decor[i]
	var d: Dictionary = Catalog.DECOR[it.id]
	var m := Modal.new()
	var pv := Previews.decor(it.id, 150)
	pv.custom_minimum_size.x = 300
	m.centered(pv)
	m.centered(UI.title(d.name, 36))
	m.box.add_child(_center_label(d.desc, 22))
	var layers := ["Al fondo", "En medio", "Delante de los peces"]
	var row := UI.hbox(10)
	var flip := UI.button("Voltear")
	flip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flip.pressed.connect(func():
		Game.flip_decor(i)
		m.close())
	row.add_child(flip)
	var layer := UI.button(layers[(int(it.layer) + 1) % 3], UI.LAV, UI.LAV_D)
	layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer.pressed.connect(func():
		Game.cycle_decor_layer(i)
		m.close())
	row.add_child(layer)
	m.box.add_child(row)
	m.box.add_child(_center_label("Ahora: %s" % layers[int(it.layer)].to_lower(), 20, UI.MUTED))
	var store := UI.button("Guardar en el inventario", UI.CORAL, UI.CORAL_D)
	store.pressed.connect(func():
		main.tank.selected_decor = -1
		Game.store_decor(i)
		m.close())
	m.box.add_child(store)
	_show_modal(m)


func _center_label(text: String, size := 24, color := UI.MUTED) -> Label:
	var l := UI.wrap(UI.label(text, size, color, UI.bold if color != UI.MUTED else null))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Botón que hay que mantener pulsado (evita mantenimientos por error y da sensación de "hacerlo").
func _hold_button(text: String, on_done: Callable) -> Button:
	var b := UI.button(text, UI.TEAL, UI.TEAL_D)
	b.custom_minimum_size.y = 76
	var fill := ColorRect.new()
	fill.color = Color(1, 1, 1, 0.28)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = Vector2(0, 0)
	b.add_child(fill)
	var tw: Array = [null]
	b.button_down.connect(func():
		fill.size = Vector2(0, b.size.y)
		tw[0] = b.create_tween()
		tw[0].tween_property(fill, "size:x", b.size.x, 1.2)
		tw[0].tween_callback(on_done))
	b.button_up.connect(func():
		if tw[0] and tw[0].is_running():
			tw[0].kill()
			fill.size.x = 0.0)
	return b


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
