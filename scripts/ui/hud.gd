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
var _edit_row: HBoxContainer          ## Decorar: mover objetos / moldear arena
var _sculpt_btn: Button
var _flat_btn: Button
var _names_btn: Button                ## mostrar / ocultar nombres sobre los peces
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
	elif Game.streak.get("pending", false):
		open_streak.call_deferred()
	if Game.started:
		Game.ask_notifications.call_deferred()


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
	# Nombre de la pecera: tocarlo abre el selector de peceras.
	var name_btn := Button.new()
	name_btn.focus_mode = Control.FOCUS_NONE
	name_btn.text = Game.tank_name + ("  %d/%d" % [Game.active + 1, Game.tanks.size()] if Game.tanks.size() > 1 else "")
	name_btn.add_theme_font_override("font", UI.heading)
	name_btn.add_theme_font_size_override("font_size", 28)
	for st in ["normal", "hover", "pressed"]:
		name_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		name_btn.add_theme_color_override(k, Color.WHITE)
	name_btn.pressed.connect(open_tank_picker)
	row.add_child(name_btn)
	row.add_child(UI.spacer())
	_coins = _currency(row, "coin", func(): open_shop(0))
	_pearls = _currency(row, "pearl", func(): open_missions())
	var gear := Button.new()
	gear.focus_mode = Control.FOCUS_NONE
	gear.custom_minimum_size = Vector2(56, 56)
	gear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for st in ["normal", "hover", "pressed"]:
		gear.add_theme_stylebox_override(st, _glass(28))
	var gi := VIcon.make("gear", 32)
	gi.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	gear.add_child(gi)
	gear.pressed.connect(open_settings)
	row.add_child(gear)
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
	var hv := UI.vbox(10)
	var hh := UI.hbox(12)
	_hint_label = UI.wrap(UI.label("", 21, Color.WHITE, UI.bold))
	_hint_label.custom_minimum_size.x = 430
	hh.add_child(_hint_label)
	var done := UI.button("Listo", UI.CORAL, UI.CORAL_D)
	done.add_theme_font_size_override("font_size", 21)
	done.pressed.connect(func(): main.set_mode(main.mode))
	hh.add_child(done)
	hv.add_child(hh)
	_edit_row = UI.hbox(10)
	_sculpt_btn = UI.button("", UI.LAV, UI.LAV_D)
	_sculpt_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sculpt_btn.add_theme_font_size_override("font_size", 21)
	_sculpt_btn.pressed.connect(func(): main.set_sculpt(not main.sculpt))
	_edit_row.add_child(_sculpt_btn)
	_flat_btn = UI.button("Allanar", UI.SAND, Color("e2d3bd"))
	_flat_btn.add_theme_color_override("font_color", UI.NAVY)
	_flat_btn.add_theme_font_size_override("font_size", 21)
	_flat_btn.pressed.connect(func(): main.flatten_terrain())
	_edit_row.add_child(_flat_btn)
	hv.add_child(_edit_row)
	_hint.add_child(hv)
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
	_names_btn = Button.new()
	_names_btn.focus_mode = Control.FOCUS_NONE
	_names_btn.text = "Nombres"
	_names_btn.add_theme_font_override("font", UI.bold)
	_names_btn.add_theme_font_size_override("font_size", 20)
	_names_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	var nb := safe_margins().y + 14.0 + 118.0 + 16.0
	_names_btn.offset_left = -190
	_names_btn.offset_right = -18
	_names_btn.offset_top = -nb - 58
	_names_btn.offset_bottom = -nb
	_names_btn.pressed.connect(func():
		Game.show_names = not Game.show_names
		Game.save_game()
		_style_names())
	add_child(_names_btn)
	_mission_dot = Dot.new()
	_mission_dot.color = UI.BAD
	_mission_dot.custom_minimum_size = Vector2(22, 22)
	_mission_dot.position = Vector2(8, 8)
	_bar.missions.add_child(_mission_dot)
	v.add_child(bar)


func _style_names() -> void:
	var on := Game.show_names
	for st in ["normal", "hover", "pressed"]:
		_names_btn.add_theme_stylebox_override(st, UI.box(UI.TEAL, 26, 4, UI.TEAL_D) if on else _glass(26))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		_names_btn.add_theme_color_override(k, Color.WHITE)
	_names_btn.text = "Nombres: sí" if on else "Nombres: no"


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
		main.Mode.VACUUM: "Pasa el sifón por la arena para aspirar la suciedad del fondo",
		main.Mode.EDIT: "Desliza hacia arriba para amontonar arena y hacia abajo para quitarla" if main.sculpt
			else "Arrastra plantas, adornos o aparatos · tócalos para más opciones"}.get(main.mode, "")
	_edit_row.visible = main.mode == main.Mode.EDIT
	_names_btn.visible = main.mode == main.Mode.NORMAL
	_style_names()
	_sculpt_btn.text = "Mover objetos" if main.sculpt else "Moldear la arena"
	_flat_btn.visible = main.sculpt


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
	var dirt := maxf(w.dirt, w.waste)
	_chip("clean", "%d%%" % roundi(100.0 - dirt), 0 if dirt < 40.0 else (1 if dirt < 70.0 else 2))
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
		"ph", "sal", "o2":
			open_water_panel()
		"clean":
			show_toast("Cristal limpio al %d%% · fondo limpio al %d%%. Usa el limpiacristales y el sifón de la estantería." % [
				roundi(100.0 - w.dirt), roundi(100.0 - w.waste)], "sponge")


# ───────────────────────── Avisos ─────────────────────────

func show_toast(text: String, icon := "star") -> void:
	if Game._arg("shot") != "" or Game._arg("promo") != "":
		return                                    # capturas y vídeo para la tienda: sin avisos
	var snd: String = {"coin": "coin", "egg": "hatch", "star": "chime", "dna": "chime", "health": "error", "pearl": "chime", "sparkle": "chime"}.get(icon, "")
	if snd != "":
		Sfx.play(snd, 200, -3.0)
	if icon == "coin":
		Sfx.vibrate(20)
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


func open_missions(tab := 0) -> void:
	_open(MissionsSheet.new(tab))


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


## Bote «Agua» de la estantería: cómo está el agua, qué piden tus peces y los productos para corregirlo.
func open_water_panel() -> void:
	var m := Modal.new()
	m.centered(UI.title("Agua", 40))
	var w := Game.water()
	var info := "pH %.2f · oxígeno %d%% · cristal %d%% · fondo %d%% limpio" % [w.ph, roundi(w.o2), roundi(100.0 - w.dirt), roundi(100.0 - w.waste)]
	if Game.water_kind == "salada":
		info += "\nSalinidad %.3f (ideal %.3f–%.3f)" % [Game.salinity, Catalog.SALINITY[0], Catalog.SALINITY[1]]
	var seen := {}
	for f in Game.fish:
		var sp: Dictionary = Catalog.SPECIES[f.genes.sp]
		if not seen.has(sp.name):
			seen[sp.name] = true
			info += "\n%s: pH %.1f–%.1f" % [sp.name, sp.ph[0], sp.ph[1]]
	m.box.add_child(_center_label(info, 20, UI.NAVY))
	var list := m.scroll_box(minf(620.0, get_viewport_rect().size.y * 0.5))
	for id in Catalog.PRODUCT_ORDER:
		var pr: Dictionary = Catalog.PRODUCTS[id]
		if not Catalog.fits(pr, Game.water_kind):
			continue
		var n: int = Game.products.get(id, 0)
		var use := UI.button("Usar")
		use.disabled = n <= 0
		use.pressed.connect(func():
			Game.use_product(id)
			m.close())
		var buy := UI.price_button(pr.price, "coins", "+%d" % pr.pack)
		buy.pressed.connect(func():
			Game.buy_product(id)
			m.close()
			open_water_panel())
		list.add_child(_pick_row(Previews.art("product", id, 70), "%s  ×%d" % [pr.name, n], pr.desc, [use, buy]))
	if Game.water_kind == "salada":
		var top := UI.button("Reponer")
		top.pressed.connect(func():
			Game.top_up()
			m.close())
		list.add_child(_pick_row(Previews.icon("ph", 70, 50), "Agua dulce", "Baja la salinidad 2 milésimas. Úsala cuando se evapore el agua.", [top]))
	_show_modal(m)


## Bote «Comida»: elige qué alimento coges y a cuál de tus peces le gusta.
func open_food_picker() -> void:
	var m := Modal.new()
	m.centered(UI.title("¿Qué comida?", 38))
	for id in Catalog.FOOD_ORDER:
		var fd: Dictionary = Catalog.FOODS[id]
		var n := -1 if id == "escamas" else int(Game.food.get(id, 0))
		var eaters := {}
		for f in Game.fish:
			if id in Catalog.SPECIES[f.genes.sp].diet:
				eaters[Catalog.SPECIES[f.genes.sp].name] = true
		var desc: String = ("Lo comen: " + ", ".join(eaters.keys())) if not eaters.is_empty() else "Ninguno de tus peces lo come."
		var act: Button
		if n == 0:
			act = UI.price_button(fd.price, "coins", "+%d" % fd.pack)
			act.pressed.connect(func():
				Game.buy_food(id)
				m.close()
				open_food_picker())
		else:
			act = UI.button("Coger", UI.CORAL, UI.CORAL_D)
			act.pressed.connect(func():
				m.close()
				main.pick_food(id))
		m.box.add_child(_pick_row(Previews.art("food", id, 70), "%s  %s" % [fd.name, "∞" if n < 0 else "×%d" % n], desc, [act]))
	_show_modal(m)


## Fila de selector: dibujo, título, texto y botones a la derecha.
func _pick_row(art: Control, title: String, desc: String, buttons: Array) -> Control:
	var c := UI.card(Color.WHITE, 22)
	var h := UI.hbox(10)
	art.custom_minimum_size = Vector2(70, 70)
	h.add_child(art)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label(title, 21, UI.NAVY, UI.bold))
	v.add_child(UI.wrap(UI.label(desc, 17, UI.MUTED)))
	h.add_child(v)
	var bv := UI.vbox(6)
	bv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for b: Button in buttons:
		b.custom_minimum_size = Vector2(156, 50)
		b.add_theme_font_size_override("font_size", 19)
		bv.add_child(b)
	h.add_child(bv)
	c.add_child(h)
	return c


## Ficha de un aparato: estado, efecto y mantenimiento (mantener pulsado).
func open_equipment(slot: String) -> void:
	var id: String = Game.equipment.get(slot, "")
	var m := Modal.new()
	var icons := {"filter": "sparkle", "heater": "thermo", "pump": "o2", "light": "star", "thermo": "thermo", "ato": "ph"}
	if id != "":
		var art := Previews.art("equipment", id, 160)
		art.custom_minimum_size.x = 200
		m.centered(art)
	else:
		m.centered(VIcon.make(icons[slot], 64))
	if id == "":
		m.centered(UI.title(Catalog.SLOT_NAMES[slot], 38))
		var why := "Llevas la luz básica de serie. Una pantalla LED da más color y felicidad." if slot == "light" else "No tienes ninguno instalado."
		if not slot in Catalog.TANKS[Game.tank_tier].equip:
			why = "Tu pecera no admite este aparato: amplíala en la tienda."
		m.box.add_child(_center_label(why, 24))
		for sid in Game.equip_inv:
			if Catalog.EQUIPMENT[sid].slot == slot and Game.install_block(sid) == "" and Catalog.fits(Catalog.EQUIPMENT[sid], Game.water_kind):
				var ins := UI.button("Instalar %s (guardado)" % Catalog.EQUIPMENT[sid].name)
				ins.pressed.connect(func():
					Game.install_stored(sid)
					m.close())
				m.box.add_child(ins)
	else:
		var e: Dictionary = Catalog.EQUIPMENT[id]
		m.centered(UI.title(e.name, 36))
		m.centered(UI.pill(Catalog.QUALITY_NAMES[e.q], Catalog.color(Catalog.QUALITY_COLORS[e.q])))
		m.box.add_child(_center_label(e.desc, 23))
		if int(e.q) == 1 and e.wear > 0.0:
			m.box.add_child(_center_label("Es básico: si llega al 0% se rompe y tendrás que comprar otro.", 21, UI.MUTED))
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
		var rem := UI.button("Retirar y guardar", UI.CORAL, UI.CORAL_D)
		rem.pressed.connect(func():
			Game.remove_equipment(slot)
			m.close())
		m.box.add_child(rem)
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
	if Game.plant_grows(it.id):
		var g := float(it.get("g", 1.0))
		m.box.add_child(_center_label("Tamaño: %d%%%s" % [roundi(g * 100.0), " · ¡pide poda!" if Game.needs_prune(i) else " · crece con la luz"], 21, UI.BAD if Game.needs_prune(i) else UI.NAVY))
		if Game.needs_prune(i):
			var cut := UI.button("Podar (+1 esqueje)", UI.TEAL, UI.TEAL_D)
			cut.pressed.connect(func():
				Game.prune_decor(i)
				m.close())
			m.box.add_child(cut)
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
	Sfx.play("levelup", 500)
	Sfx.vibrate(60)
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


# ───────────────────────── Peceras, ajustes y racha ─────────────────────────

## Elegir pecera (o comprar otra). Cambiar recarga la escena con la pecera elegida.
func open_tank_picker() -> void:
	var m := Modal.new()
	m.centered(UI.title("Tus peceras", 38))
	for i in Game.tanks.size():
		var t: Dictionary = Game._snapshot() if i == Game.active else Game.tanks[i]
		var info := "%s · %s · %d peces" % [Catalog.TANKS[t.tank_tier].name, Catalog.WATER_NAMES[t.water_kind], t.fish.size()]
		var b := UI.button("En uso" if i == Game.active else "Ir")
		b.disabled = i == Game.active
		b.pressed.connect(func():
			m.close()
			Game.switch_tank(i)
			get_tree().reload_current_scene())
		m.box.add_child(_pick_row(Previews.art("tank", int(t.tank_tier), 70), t.tank_name, info, [b]))
	var why := Game.can_buy_tank_slot()
	if why == "Máximo de peceras":
		m.box.add_child(_center_label("Tienes el máximo de peceras (%d)." % Catalog.TANK_SLOTS.size(), 21))
	else:
		var price := int(Catalog.TANK_SLOTS[Game.tanks.size()].price)
		m.box.add_child(_center_label("Otra pecera para criar aparte, separar peces que no se llevan o tener dulce y salada a la vez.", 20))
		var row := UI.hbox(10)
		for wid in ["dulce", "salada"]:
			var b: Button
			if why != "":
				b = UI.button("%s · %s" % [Catalog.WATER_NAMES[wid], why])
				b.disabled = true
			else:
				b = UI.price_button(price, "coins", wid.capitalize())
				b.pressed.connect(func():
					if Game.buy_tank_slot(wid):
						m.close()
						get_tree().reload_current_scene())
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)
		m.box.add_child(row)
	_show_modal(m)


func open_settings() -> void:
	var m := Modal.new()
	m.centered(UI.title("Ajustes", 40))
	for k in [["music", "Música"], ["sfx", "Efectos de sonido"], ["vibration", "Vibración"], ["notify", "Avisos (hambre, huevos...)"]]:
		var row := UI.hbox(10)
		var l := UI.label(k[1], 23, UI.NAVY, UI.bold)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b := UI.button("")
		b.custom_minimum_size = Vector2(130, 56)
		var paint := func():
			var on: bool = Game.settings[k[0]]
			b.text = "Sí" if on else "No"
			UI.button_colors(b, UI.TEAL if on else Color("c9d2db"), UI.TEAL_D if on else Color("aab6c2"))
		paint.call()
		b.pressed.connect(func():
			Game.settings[k[0]] = not Game.settings[k[0]]
			Game.save_game()
			Sfx.apply_settings()
			paint.call())
		row.add_child(b)
		m.box.add_child(row)
	var modes := UI.button("Modo de juego: %s" % Catalog.MODES[Game.mode].name, UI.LAV, UI.LAV_D)
	modes.pressed.connect(func():
		m.close()
		open_mode_picker())
	m.box.add_child(modes)
	var tut := UI.button("Repetir el tutorial", UI.SAND, Color("e2d3bd"))
	tut.add_theme_color_override("font_color", UI.NAVY)
	tut.pressed.connect(func():
		m.close()
		start_tutorial())
	m.box.add_child(tut)
	var priv := UI.button("Política de privacidad", UI.SAND, Color("e2d3bd"))
	priv.add_theme_color_override("font_color", UI.NAVY)
	priv.pressed.connect(func(): OS.shell_open(PRIVACY_URL))
	m.box.add_child(priv)
	m.box.add_child(_hold_button("Mantén pulsado: borrar partida", func():
		m.close()
		Game.reset_game()
		get_tree().reload_current_scene()))
	m.box.add_child(_center_label("AquaCraft %s · sin anuncios ni compras" % ProjectSettings.get_setting("application/config/version"), 19))
	_show_modal(m)


const PRIVACY_URL := "https://a-quiles.github.io/AquaCraft/privacidad.html"


## Premio de la racha diaria: 7 casillas, la de hoy resaltada.
func open_streak() -> void:
	if not Game.streak.get("pending", false):
		return
	var m := Modal.new(false)
	m.centered(VIcon.make("star", 70))
	var n := int(Game.streak.get("n", 1))
	m.centered(UI.title("¡Racha de %d día%s!" % [n, "" if n == 1 else "s"], 38))
	m.box.add_child(_center_label("Vuelve cada día: el premio mejora y el 7º es un huevo misterioso.", 21))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var today := Game.streak_day()
	for i in Catalog.STREAK.size():
		var c := UI.card(UI.SUN if i == today else (Color("dff3f5") if i < today else Color.WHITE), 18)
		c.custom_minimum_size = Vector2(128, 0)
		var v := UI.vbox(2)
		var l := UI.label("Día %d" % (i + 1), 19, UI.NAVY, UI.heading)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		var t := UI.wrap(UI.label(Catalog.STREAK[i].text, 16, UI.NAVY if i == today else UI.MUTED, UI.bold))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
		c.add_child(v)
		grid.add_child(c)
	m.centered(grid)
	var ok := UI.button("¡Recoger!", UI.CORAL, UI.CORAL_D)
	ok.custom_minimum_size.y = 70
	ok.pressed.connect(func():
		Game.claim_streak()
		m.close())
	m.box.add_child(ok)
	_show_modal(m)
