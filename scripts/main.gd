extends Node2D
## Escena principal: habitación, mueble, pecera, marco y la interfaz. Gestiona el toque en el agua.

const ROOM := preload("res://shaders/room.gdshader")
const SHELF_SPACE := 190.0           ## alto reservado sobre la pecera: estantería de pared + hueco hasta la tapa
const SHELF_Y := 104.0               ## balda de la estantería, bajo la barra superior
const SHELF_ITEMS := ["sponge", "food", "water", "siphon"]
const SHELF_NAMES := {"sponge": "Limpiar", "food": "Comida", "water": "Agua", "siphon": "Sifón"}

enum Mode { NORMAL, FEED, CLEAN, EDIT, VACUUM }

var mode := Mode.NORMAL
var food_type := "escamas"
var tank: TankView
var hud: Hud
var tank_rect := Rect2()

var _room: ColorRect
var _furniture: Node2D
var _frame: Node2D
var _bowl_mask: Node2D               ## pinta la pared encima de lo que asoma fuera de la pecera redonda
var _props: Node2D
var prop_rects := {}                 ## nombre → Rect2 de los objetos de la estantería
var _last_drag := Vector2.INF
var _drag_idx := -1                  ## decoración que se arrastra en modo Decorar
var _drag_off := 0.0
var _drag_from := Vector2.ZERO
var _drag_moved := false
var _drag_equip := ""                ## aparato que se arrastra en modo Decorar
var sculpt := false                  ## Decorar → moldear la arena
var _feed_cd := 0.0
var _night := 0.0
var _night_acc := 999.0
const ZOOM_MAX := 2.6                ## acercar con dos dedos, como una foto
var cam: Camera2D
var _touches := {}                   ## dedo → posición en pantalla
var _pinch := {}                     ## inicio del pellizco: dist, zoom, punto del mundo
var _gesture := false                ## hubo pellizco o arrastre de cámara: soltar no cuenta como toque
var _tap_from := Vector2.INF         ## dónde empezó el toque (pantalla), para actuar al soltar


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0b2b3e"))
	_room = ColorRect.new()
	_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room.material = ShaderMaterial.new()
	_room.material.shader = ROOM
	add_child(_room)
	_furniture = Node2D.new()
	_furniture.draw.connect(_draw_furniture)
	add_child(_furniture)
	_props = Node2D.new()
	_props.z_index = 61
	_props.draw.connect(_draw_props)
	add_child(_props)
	tank = TankView.new()
	add_child(tank)
	_bowl_mask = Node2D.new()
	_bowl_mask.z_index = 58
	_bowl_mask.material = _room.material
	_bowl_mask.draw.connect(_draw_bowl_mask)
	add_child(_bowl_mask)
	_frame = Node2D.new()
	_frame.z_index = 60
	_frame.draw.connect(_draw_frame)
	add_child(_frame)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.main = self
	layer.add_child(hud)
	get_viewport().size_changed.connect(_layout)
	Game.tank_changed.connect(_layout)
	Game.changed.connect(_frame.queue_redraw)
	Game.changed.connect(_props.queue_redraw)
	_layout()
	if Game._arg("promo") != "":
		_promo.call_deferred()
	if Game._arg("shot") != "":
		_screenshot.call_deferred()


## Captura para la ficha de la tienda / revisión visual: `-- demo=2 open=shop:3 shot=out.png`
func _screenshot() -> void:
	var open := Game._arg("open")
	await get_tree().create_timer(0.6).timeout
	match open.get_slice(":", 0):
		"shop": hud.open_shop(int(open.get_slice(":", 1)))
		"fish": hud.open_fish(Game.fish[int(open.get_slice(":", 1))].id if open.contains(":") else -1)
		"missions":
			Game._refresh_orders(Time.get_unix_time_from_system())
			Game._refresh_orders(Time.get_unix_time_from_system())
			hud.open_missions(int(open.get_slice(":", 1)) if open.contains(":") else 0)
		"settings": hud.open_settings()
		"zoom":
			for i in 3:
				tank.overlay.rewards.append({"pos": tank.size * Vector2(0.3 + i * 0.2, 0.5 - i * 0.1), "coins": 4, "pearl": i == 2, "age": 1.0})
			if open.contains(":"):
				_set_zoom(float(open.get_slice(":", 1)), tank.global_position + tank.size * 0.5)
		"tanks": hud.open_tank_picker()
		"streak":
			Game.streak = {"n": 4, "pending": true, "last": ""}
			hud.open_streak()
		"thermo": hud.open_thermostat()
		"feed":
			set_mode(Mode.FEED)
			for i in 4:
				tank.food.drop(tank.size.x * (0.25 + i * 0.17), "escamas")
		"edit":
			set_mode(Mode.EDIT)
			tank.selected_decor = 1
			tank.queue_redraw_top()
		"sculpt":
			set_mode(Mode.EDIT)
			set_sculpt(true)
			for k in 40:
				_sculpt(Vector2(tank.size.x * 0.25, 0), 0.006)
				_sculpt(Vector2(tank.size.x * 0.7, 0), 0.004)
				_sculpt(Vector2(tank.size.x * 0.95, 0), -0.0015)
		"equip": hud.open_equipment(open.get_slice(":", 1))
		"food": use_prop("food")
		"water": hud.open_water_panel()
		"names":
			Game.show_names = true
			hud.refresh_mode()
		"floor":
			Game._ensure_floor()
			for i in Game.floor_dirt.size():
				Game.floor_dirt[i] = 0.75
			Game.floor_changed.emit()
			set_mode(Mode.VACUUM)
			for i in 30:
				tank.vacuum_stroke(Vector2(tank.size.x * (0.1 + i * 0.012), tank.surface_y(tank.size.x * (0.1 + i * 0.012)) - 10.0))
		"wear":
			for slot in Game.equipment:
				Game.equip_cond[slot] = float(open.get_slice(":", 1))
			Game.tank_changed.emit()
		"decor": hud.open_decor_menu(0)
		"tutorial":
			hud.start_tutorial()
			await get_tree().process_frame
			for i in int(open.get_slice(":", 1)):
				hud._tutorial._advance()
			if Game._arg("then") == "shop":
				hud.open_shop(0)
		"algae":
			for i in Game.algae.size():
				Game.algae[i] = mini(255, int(Game.algae_weights()[i] * float(open.get_slice(":", 1))))
			Game._refresh_water()
			Game.algae_changed.emit()
			Game.changed.emit()
		"clean", "dirty":
			for i in Game.algae.size():
				Game.algae[i] = mini(255, int(Game.algae_weights()[i] * 150.0))
			Game._refresh_water()
			Game.algae_changed.emit()
			Game.changed.emit()
			if open == "clean":
				set_mode(Mode.CLEAN)
			for i in (30 if open == "clean" else 0):
				tank.clean_stroke(Vector2(tank.size.x * (0.2 + i * 0.02), tank.size.y * (0.3 + sin(i * 0.4) * 0.1)))
	await _save_shot()


## Vídeo promocional (~22 s): `godot --write-movie promo.avi --fixed-fps 30 -- demo=3 promo=1`
func _promo() -> void:
	var wait := func(s: float): await get_tree().create_timer(s).timeout
	await wait.call(1.5)
	set_mode(Mode.FEED)
	for i in 8:
		tank.food.drop(tank.size.x * (0.2 + i * 0.08), "escamas")
		await wait.call(0.25)
	await wait.call(2.0)
	set_mode(Mode.FEED)
	Game.show_names = true
	await wait.call(2.5)
	Game.show_names = false
	hud.open_fish(Game.fish[1].id)
	await wait.call(2.5)
	hud.back()
	await wait.call(0.6)
	hud.open_shop(0)
	await wait.call(1.5)
	(hud._sheet as ShopSheet)._scroll.scroll_vertical = 600
	await wait.call(1.5)
	hud.back()
	await wait.call(0.6)
	hud.open_missions(2)
	await wait.call(2.5)
	hud.back()
	await wait.call(0.6)
	for i in Game.algae.size():
		Game.algae[i] = mini(255, int(Game.algae_weights()[i] * 120.0))
	Game.algae_changed.emit()
	set_mode(Mode.CLEAN)
	for i in 40:
		tank.clean_stroke(Vector2(tank.size.x * (0.15 + i * 0.018), tank.size.y * (0.35 + sin(i * 0.5) * 0.12)))
		await wait.call(0.05)
	set_mode(Mode.CLEAN)
	await wait.call(2.0)
	get_tree().quit()


func _save_shot() -> void:
	var delay := Game._arg("delay")
	await get_tree().create_timer(float(delay) if delay != "" else 2.5).timeout
	get_viewport().get_texture().get_image().save_png(Game._arg("shot"))
	get_tree().quit()


func _process(dt: float) -> void:
	_feed_cd = maxf(0.0, _feed_cd - dt)
	if Game.equipment.light != "" and Game.condition("light") < 30.0:
		_frame.queue_redraw()
	_night_acc += dt
	if _night_acc > 30.0:
		_night_acc = 0.0
		var t := Time.get_time_dict_from_system()
		var h: float = t.hour + t.minute / 60.0
		_night = clampf(maxf(smoothstep(19.0, 22.0, h), 1.0 - smoothstep(6.0, 8.5, h)), 0.0, 1.0)
		if Game._arg("night") != "":
			_night = float(Game._arg("night"))
		_room.material.set_shader_parameter("night", _night)
		tank.set_night(_night)


func _layout() -> void:
	var vp := get_viewport_rect().size
	var safe := Hud.safe_margins()
	var top := safe.x + 196.0
	var bottom := safe.y + 150.0
	var tier := Game.tank_tier
	var stand: float = [120.0, 96.0, 84.0, 64.0, 40.0][tier]
	var avail := Rect2(0, top, vp.x, vp.y - top - bottom - stand)
	# La pecera crece con la pantalla: en móviles altos aprovecha la altura en vez de dejar pared vacía.
	# Pecera más contenida; el conjunto mueble + pecera se centra en la pantalla en móviles altos.
	var w: float = vp.x * [0.58, 0.66, 0.78, 0.9, 1.0][tier] - (28.0 if tier == 4 else 0.0)
	var h: float = minf(avail.size.y * [0.5, 0.46, 0.56, 0.7, 0.9][tier], w * [Game.BOWL_H, 0.95, 0.92, 1.05, 1.7][tier])
	var bottom_y: float = minf(avail.end.y, avail.position.y + avail.size.y * 0.5 + h * 0.5 + 40.0)
	h = minf(h, bottom_y - top - SHELF_SPACE)          # deja sitio para la estantería
	if Game.is_round():
		w = h / Game.BOWL_H                            # la bola conserva sus proporciones
	var r := Rect2(Vector2((vp.x - w) * 0.5, bottom_y - h), Vector2(w, h))
	_room.size = vp
	_room.material.set_shader_parameter("size", vp)
	_room.material.set_shader_parameter("tank", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	if r != tank_rect:
		tank_rect = r
		tank.layout(r)
	else:
		tank.rebuild()
	_furniture.queue_redraw()
	_frame.queue_redraw()
	_bowl_mask.queue_redraw()
	_props.queue_redraw()
	_set_zoom(cam.zoom.x, cam.position if cam.zoom.x > 1.0 else vp * 0.5)


func set_mode(m: Mode) -> void:
	mode = Mode.NORMAL if mode == m else m
	sculpt = false
	tank.overlay.sponge_t = 0.0
	_props.queue_redraw()
	tank.editing = mode == Mode.EDIT
	tank.selected_decor = -1
	tank.selected_equip = ""
	tank.queue_redraw_top()
	hud.refresh_mode()


## Decorar: alterna entre mover objetos y moldear la arena.
func set_sculpt(on: bool) -> void:
	sculpt = on
	tank.editing = mode == Mode.EDIT and not on        # sin recuadros mientras se moldea
	tank.selected_decor = -1
	tank.selected_equip = ""
	tank.queue_redraw_top()
	hud.refresh_mode()


## Sube (dy > 0) o baja la arena alrededor de x con un pincel suave.
func _sculpt(p: Vector2, dy: float) -> void:
	var n := Catalog.TERRAIN_N
	if Game.terrain.size() != n:
		Game.terrain = []
		Game.terrain.resize(n)
		Game.terrain.fill(0.0)
	var u := p.x / tank.size.x
	for i in n:
		var d := (u - float(i) / (n - 1)) / 0.085
		Game.terrain[i] = clampf(float(Game.terrain[i]) + dy * exp(-d * d), Catalog.TERRAIN_MIN, Catalog.TERRAIN_MAX)
	tank.terrain_changed()


func flatten_terrain() -> void:
	Game.terrain = []
	tank.rebuild()
	Game.save_game()


# ───────────────────────── Toques en el agua ─────────────────────────

## Pantalla → mundo (la cámara puede estar acercada).
func _w(screen: Vector2) -> Vector2:
	return cam.position + (screen - get_viewport_rect().size * 0.5) / cam.zoom.x


func _set_zoom(z: float, center: Vector2) -> void:
	var vp := get_viewport_rect().size
	z = clampf(z, 1.0, ZOOM_MAX)
	var half := vp * 0.5 / z
	cam.zoom = Vector2(z, z)
	cam.position = Vector2(clampf(center.x, half.x, vp.x - half.x), clampf(center.y, half.y, vp.y - half.y))
	# El resplandor de la pared sigue a la pecera en pantalla.
	var tl := (tank_rect.position - cam.position) * z + vp * 0.5
	_room.material.set_shader_parameter("tank", Vector4(tl.x, tl.y, tank_rect.size.x * z, tank_rect.size.y * z))


func _zoom_gestures(event: InputEvent) -> bool:
	if hud._tutorial and is_instance_valid(hud._tutorial):
		return false                                   # durante el tutorial, sin zoom
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var z: float = cam.zoom.x * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15)
		var anchor := _w(event.position)
		_set_zoom(z, anchor - (event.position - get_viewport_rect().size * 0.5) / clampf(z, 1.0, ZOOM_MAX))
		return true
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_gesture = false
		else:
			_touches.erase(event.index)
		if _touches.size() >= 2:
			var ps: Array = _touches.values()
			var mid: Vector2 = (ps[0] + ps[1]) * 0.5
			_pinch = {"d": maxf(10.0, ps[0].distance_to(ps[1])), "z": cam.zoom.x, "w": _w(mid)}
			_gesture = true
			_drag_idx = -1
			_drag_equip = ""
			_last_drag = Vector2.INF
			return true
		if not _pinch.is_empty():
			_pinch = {}
			return true
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if not _pinch.is_empty() and _touches.size() >= 2:
			var ps: Array = _touches.values()
			var mid: Vector2 = (ps[0] + ps[1]) * 0.5
			var z := clampf(float(_pinch.z) * ps[0].distance_to(ps[1]) / float(_pinch.d), 1.0, ZOOM_MAX)
			_set_zoom(z, _pinch.w - (mid - get_viewport_rect().size * 0.5) / z)
			return true
		# Con la pecera acercada, arrastrar un dedo la mueve (solo sin herramienta en la mano).
		if mode == Mode.NORMAL and cam.zoom.x > 1.01 and _tap_from != Vector2.INF \
				and (_gesture or event.position.distance_to(_tap_from) > 14.0):
			_gesture = true
			_set_zoom(cam.zoom.x, cam.position - event.relative / cam.zoom.x)
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if _zoom_gestures(event):
		return
	if event is InputEventScreenTouch:
		var p := tank.to_local(_w(event.position))
		# La tapa (luz) queda por encima del agua: también se puede tocar.
		var inside := Rect2(0, -34, tank.size.x, tank.size.y + 34).has_point(p)
		if not event.pressed:
			_last_drag = Vector2.INF
			# Los toques normales actúan al soltar: así un pellizco o un arrastre no abren nada sin querer.
			if mode == Mode.NORMAL and not _gesture and _tap_from != Vector2.INF and event.position.distance_to(_tap_from) < 14.0:
				_tap(tank.to_local(_w(_tap_from)))
			if _touches.is_empty():
				_gesture = false
				_tap_from = Vector2.INF
			if mode == Mode.EDIT and sculpt:
				tank.rebuild()                 # recoloca burbujas del cofre, etc.
				Game.save_game()
			elif mode == Mode.EDIT:
				_end_decor_drag()
			return
		# Las burbujas de premio se recogen con cualquier herramienta en la mano.
		var rw := tank.overlay.reward_at(p)
		if rw >= 0:
			tank.overlay.collect(rw)
			return
		var prop := prop_at(_w(event.position))
		if prop != "":
			use_prop(prop)
			return
		_tap_from = event.position
		if not inside:
			return
		match mode:
			Mode.FEED:
				if p.y > 0.0 and _feed_cd <= 0.0 and Game.use_food(food_type):
					_feed_cd = 0.22
					tank.food.drop(p.x, food_type)
					_props.queue_redraw()
			Mode.CLEAN:
				_last_drag = p
				tank.clean_stroke(p)
			Mode.VACUUM:
				_last_drag = p
				tank.vacuum_stroke(p)
			Mode.EDIT when sculpt:
				_last_drag = p
			Mode.EDIT:
				# Los aparatos (filtro, termómetro...) se cogen antes que la decoración.
				var slot := tank.equipment_at(p)
				_drag_equip = slot if slot != "light" else ""
				_drag_idx = -1 if _drag_equip != "" else tank.decor_at(p)
				tank.selected_equip = _drag_equip
				tank.selected_decor = _drag_idx
				tank.queue_redraw_top()
				_drag_from = p
				_drag_moved = false
				if _drag_equip != "":
					_drag_off = tank.equip_x(_drag_equip) * tank.size.x - p.x
				elif _drag_idx >= 0:
					_drag_off = Game.decor[_drag_idx].x * tank.size.x - p.x
			Mode.NORMAL:
				pass                                     # se resuelve al soltar (_tap)
	elif event is InputEventScreenDrag and mode == Mode.EDIT and sculpt:
		var p := tank.to_local(_w(event.position))
		if _last_drag == Vector2.INF or not Rect2(Vector2.ZERO, tank.size).has_point(p):
			return
		# Arrastrar hacia arriba amontona arena; hacia abajo la quita.
		_sculpt(p, (_last_drag.y - p.y) / tank.size.y * 0.9)
		_last_drag = p
	elif event is InputEventScreenDrag and mode == Mode.EDIT and (_drag_idx >= 0 or _drag_equip != ""):
		var p := tank.to_local(_w(event.position))
		if p.distance_to(_drag_from) > 8.0:
			_drag_moved = true
		if _drag_equip != "":
			tank.preview_equip_x(_drag_equip, p.x + _drag_off)
		else:
			tank.set_decor_x(_drag_idx, p.x + _drag_off)
	elif event is InputEventScreenDrag and (mode == Mode.CLEAN or mode == Mode.VACUUM):
		var p := tank.to_local(_w(event.position))
		if not Rect2(Vector2.ZERO, tank.size).has_point(p):
			return
		if _last_drag == Vector2.INF:
			_last_drag = p
		# Interpolamos para que un deslizamiento rápido no deje huecos.
		var steps := maxi(1, int(_last_drag.distance_to(p) / 14.0))
		for i in steps:
			var q := _last_drag.lerp(p, float(i + 1) / steps)
			if mode == Mode.CLEAN:
				tank.clean_stroke(q)
			else:
				tank.vacuum_stroke(q)
		_last_drag = p


func _tap(p: Vector2) -> void:
	if not Rect2(0, -34, tank.size.x, tank.size.y + 34).has_point(p):
		return
	var a := tank.fish_at(p)
	var slot := tank.equipment_at(p)
	if a:
		hud.open_fish(a.data.id)
	elif slot != "":
		hud.open_equipment(slot)
	else:
		tank.startle(p)


## Al soltar: si se movió, se guarda la posición; si fue un toque, se abren sus opciones.
func _end_decor_drag() -> void:
	if _drag_equip != "":
		var slot := _drag_equip
		_drag_equip = ""
		if _drag_moved:
			Game.save_game()
		else:
			hud.open_equipment(slot)
		return
	if _drag_idx < 0:
		return
	var i := _drag_idx
	_drag_idx = -1
	if _drag_moved:
		Game.move_decor(i, tank.decor_x(i) / tank.size.x)
		if Game.decor[i].id == "cofre":
			tank.rebuild()
		tank.selected_decor = i
	else:
		hud.open_decor_menu(i)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if hud.back():
			return
		if mode != Mode.NORMAL:
			set_mode(mode)
			return
		Game.save_game()
		get_tree().quit()


# ───────────────────────── Mueble y marco ─────────────────────────

func _draw_furniture() -> void:
	var ci := _furniture
	var vp := get_viewport_rect().size
	var r := tank_rect
	_draw_wall(ci, vp, r)
	var top_y := r.end.y + stand_gap()
	var x0 := 16.0 if Game.tank_tier < 4 else 0.0
	var x1 := vp.x - x0
	# Sombra en la pared y encimera
	ci.draw_rect(Rect2(x0, top_y + 6, x1 - x0, vp.y - top_y), Color(0, 0, 0, 0.25))
	var plank := Rect2(x0 - 10, top_y, x1 - x0 + 20, 22)
	ci.draw_rect(plank, Color("b07a4f"))
	ci.draw_rect(Rect2(plank.position.x, plank.end.y - 6, plank.size.x, 6), Color("8a5a36"))
	var body := Rect2(x0, plank.end.y, x1 - x0, vp.y - plank.end.y)
	ci.draw_rect(body, Color("74492c"))
	for k in 12:
		var y := body.position.y + 12 + k * 23
		ci.draw_line(Vector2(body.position.x, y), Vector2(body.end.x, y + 4), Color(0, 0, 0, 0.06), 2.0)
	var doors := 2 if body.size.x < 600 else 3
	var dw := (body.size.x - 28.0) / doors
	for i in doors:
		var d := Rect2(body.position.x + 14 + i * dw + 6, body.position.y + 16, dw - 12, body.size.y - 10)
		ci.draw_rect(d, Color("82522f"))
		ci.draw_rect(d, Color("5e3a22"), false, 3.0)
		ci.draw_circle(Vector2(d.end.x - 22 if i % 2 == 0 else d.position.x + 22, d.position.y + 44), 7, Color("e6b85c"))
	ci.draw_colored_polygon(DecorArt.ell(Vector2(r.get_center().x, top_y + 2), r.size.x * 0.55, 8), Color(0, 0, 0, 0.18))
	# Atrezo sobre el mueble si sobra sitio a los lados
	var side := r.position.x - x0
	if side > 70.0:
		var bx := x0 + side * 0.45
		for k in 3:
			var bw := 68.0 - k * 8.0
			ci.draw_rect(Rect2(bx - bw * 0.5 + k * 3, top_y - 16 - k * 16, bw, 16), [Color("e76f51"), Color("2a9d8f"), Color("e9c46a")][k])
			ci.draw_rect(Rect2(bx - bw * 0.5 + k * 3, top_y - 10 - k * 16, bw, 2), Color(1, 1, 1, 0.5))
		var px := x1 - side * 0.45
		var pot := PackedVector2Array([Vector2(px - 24, top_y - 44), Vector2(px + 24, top_y - 44), Vector2(px + 17, top_y), Vector2(px - 17, top_y)])
		for i in 7:
			DecorArt.leaf(ci, Vector2(px, top_y - 40), lerpf(-1.1, 1.1, i / 6.0), 52.0 - absf(i - 3) * 6.0, 18.0, Color("2e7d4f"), Color("6fcf8a"), 0.12)
		ci.draw_colored_polygon(pot, Color("d9774e"))
		ci.draw_rect(Rect2(px - 27, top_y - 50, 54, 10), Color("c4633d"))


## Pared: cuadro con un pez y estante con atrezo, solo si queda sitio sobre la pecera.
func _draw_wall(ci: Node2D, vp: Vector2, r: Rect2) -> void:
	var top := Hud.safe_margins().x + 200.0
	if r.position.y - top < 165.0:
		return
	# Cuadro
	var fr := Rect2(vp.x * 0.07, top + 20.0, 150.0, 116.0)
	ci.draw_rect(Rect2(fr.position + Vector2(5, 7), fr.size), Color(0, 0, 0, 0.18))
	ci.draw_rect(fr, Color("8a5a36"))
	var mat := fr.grow(-10)
	ci.draw_rect(mat, Color("fff3df"))
	var art := mat.grow(-9)
	ci.draw_rect(art, Color("9fdde6"))
	ci.draw_rect(Rect2(art.position + Vector2(0, art.size.y * 0.72), Vector2(art.size.x, art.size.y * 0.28)), Color("f1d39a"))
	var fc := art.get_center() + Vector2(6, -4)
	ci.draw_colored_polygon(PackedVector2Array([fc + Vector2(-18, 0), fc + Vector2(-38, -16), fc + Vector2(-38, 16)]), Color("ff8a5b"))
	ci.draw_colored_polygon(DecorArt.ell(fc, 26, 16), Color("ffa26b"))
	ci.draw_circle(fc + Vector2(14, -4), 3.5, Color("1d3557"))
	for b in [Vector2(30, -18), Vector2(38, -30), Vector2(33, -42)]:
		ci.draw_arc(fc + b, 4.0, 0, TAU, 12, Color(1, 1, 1, 0.9), 1.6, true)
	DecorArt.blade(ci, art.position + Vector2(14, art.size.y), 46, 7, 6, Color("2e7d4f"), Color("6fcf8a"), 6)
	DecorArt.blade(ci, art.position + Vector2(22, art.size.y), 34, 6, -5, Color("2e7d4f"), Color("8fe3a0"), 6)


# ───────────────────────── Estantería de cuidados ─────────────────────────

func prop_at(p: Vector2) -> String:
	for k in prop_rects:
		if (prop_rects[k] as Rect2).grow(6.0).has_point(p):
			return k
	return ""


## Coger/soltar un objeto de la estantería. Los botes abren un selector (qué comida / qué producto).
func use_prop(k: String) -> void:
	match k:
		"sponge": set_mode(Mode.CLEAN)
		"siphon": set_mode(Mode.VACUUM)
		"water": hud.open_water_panel()
		"food":
			if mode == Mode.FEED:
				set_mode(Mode.FEED)                  # soltar el bote
			else:
				# Coge directamente la última comida (si se acabó, escamas); en el aviso de abajo se cambia.
				pick_food(food_type if food_type == "escamas" or int(Game.food.get(food_type, 0)) > 0 else "escamas")


## Coge el bote con ese alimento (desde la estantería o los botones del aviso).
func pick_food(id: String) -> void:
	food_type = id
	mode = Mode.NORMAL
	set_mode(Mode.FEED)


func _draw_props() -> void:
	var ci := _props
	prop_rects.clear()
	var vp := get_viewport_rect().size
	# Balda de pared arriba a la derecha, lejos de la pecera (el cuadro queda a la izquierda).
	var step := 88.0
	var sw := step * SHELF_ITEMS.size() + 20.0
	var sx := vp.x - sw - 22.0
	var sy := Hud.safe_margins().x + 196.0 + SHELF_Y
	ci.draw_rect(Rect2(sx + 4, sy + 6, sw, 12), Color(0, 0, 0, 0.18))
	for bx in [sx + 26.0, sx + sw - 34.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx, sy + 10), Vector2(bx + 8, sy + 10), Vector2(bx + 8, sy + 34)]), Color("6b4428"))
	ci.draw_rect(Rect2(sx, sy, sw, 12), Color("b07a4f"))
	ci.draw_rect(Rect2(sx, sy + 9, sw, 3), Color("8a5a36"))
	var font := UI.bold
	for i in SHELF_ITEMS.size():
		var key: String = SHELF_ITEMS[i]
		var lifted := (key == "sponge" and mode == Mode.CLEAN) or (key == "food" and mode == Mode.FEED) or (key == "siphon" and mode == Mode.VACUUM)
		var base := Vector2(sx + 10.0 + step * (i + 0.5), sy - (12.0 if lifted else 0.0))
		if lifted:
			ci.draw_circle(base + Vector2(0, -32), 44, Color(1.0, 0.9, 0.5, 0.25))
		var r := Rect2()
		match key:
			"sponge":
				# Limpiacristales magnético: asa + esponja.
				var b := Rect2(base + Vector2(-30, -34), Vector2(60, 34))
				ci.draw_rect(Rect2(b.position + Vector2(0, 12), Vector2(60, 22)), Color("ffd34d"))
				for h in [Vector2(-18, -10), Vector2(-2, -6), Vector2(14, -12), Vector2(22, -4)]:
					ci.draw_circle(base + h, 2.6, Color("e0a92c"))
				ci.draw_rect(Rect2(b.position + Vector2(0, 4), Vector2(60, 9)), Color("2e9e6a"))
				ci.draw_rect(Rect2(b.position + Vector2(14, -6), Vector2(32, 10)), Color("3a4552"))
				r = Rect2(b.position + Vector2(0, -10), b.size + Vector2(0, 10))
			"food":
				var col := Catalog.color(Catalog.FOODS[food_type].col) if mode == Mode.FEED else Color("ff8a3d")
				ShopArt.jar(ci, base, col, "Comida", 1.0, 13)
				r = Rect2(base + Vector2(-30, -78), Vector2(60, 78))
			"water":
				ShopArt.bottle(ci, base, Color("3f8cff"), "Agua", 1.05, 13)
				var n := 0
				for id in Catalog.PRODUCT_ORDER:
					n += int(Game.products.get(id, 0))
				ci.draw_circle(base + Vector2(20, -56), 12, UI.NAVY if n > 0 else UI.BAD)
				ci.draw_string(font, base + Vector2(8, -51), str(n), HORIZONTAL_ALIGNMENT_CENTER, 24, 14, Color.WHITE)
				r = Rect2(base + Vector2(-26, -86), Vector2(52, 86))
			"siphon":
				# Sifón: campana transparente con su tubo enrollado.
				var bell := Rect2(base + Vector2(-14, -50), Vector2(28, 50))
				ci.draw_arc(base + Vector2(10, -58), 16, -PI * 0.9, PI * 0.6, 20, Color(0.85, 0.95, 1.0, 0.85), 5.0, true)
				ci.draw_rect(bell, Color(0.85, 0.95, 1.0, 0.35))
				ci.draw_rect(bell, Color(0.9, 1.0, 1.0, 0.9), false, 2.0)
				ci.draw_rect(Rect2(bell.position + Vector2(-2, -6), Vector2(32, 8)), Color(0.25, 0.55, 0.85))
				r = Rect2(base + Vector2(-26, -80), Vector2(56, 80))
		# Nombre debajo de la balda: se lee siempre.
		var nm: String = SHELF_NAMES[key]
		var w := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var tp := Vector2(base.x - w * 0.5, sy + 36 + (12.0 if lifted else 0.0))
		ci.draw_string_outline(font, tp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color(0.04, 0.12, 0.19, 0.7))
		ci.draw_string(font, tp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
		prop_rects[key] = Rect2(r.position, r.size + Vector2(0, 52)).grow(6)


func _draw_frame() -> void:
	var ci := _frame
	var r := tank_rect
	if Game.is_round():
		_draw_bowl(ci, r)
		return
	var wood := Game.tank_tier == 4
	var dark := Color("6b4428") if wood else Color("22303c")
	var lid := Rect2(r.position.x - 10, r.position.y - 30, r.size.x + 20, 30)
	ci.draw_rect(lid, dark)
	ci.draw_rect(Rect2(lid.position, Vector2(lid.size.x, 6)), dark.lightened(0.2))
	var led := 0.6
	if Game.equipment.light != "":
		# Se apaga poco a poco y parpadea cuando la tapa está muy sucia.
		var eff := Game.efficiency("light")
		led = lerpf(0.35, 1.0, eff)
		if Game.condition("light") < 30.0 and fmod(Time.get_ticks_msec() / 90.0, 7.0) < 1.0:
			led *= 0.3
	ci.draw_rect(Rect2(r.position.x + 12, r.position.y - 6, r.size.x - 24, 4), Color(0.85, 1.0, 1.0, 0.9 * led))
	for k in 4:
		ci.draw_rect(Rect2(r.position.x + 12, r.position.y - 2 + k * 3, r.size.x - 24, 3), Color(0.7, 1.0, 1.0, 0.12 * led * (1.0 - k / 4.0)))
	ci.draw_rect(Rect2(r.position.x - 10, r.end.y, r.size.x + 20, 16), dark)
	ci.draw_rect(Rect2(r.position.x - 10, r.end.y, r.size.x + 20, 4), dark.lightened(0.25))
	for x in [r.position.x - 4.0, r.end.x]:
		ci.draw_rect(Rect2(x, r.position.y, 4, r.size.y), Color(0.75, 0.97, 0.92, 0.55) if not wood else dark)


## Pecera redonda: canto del cristal, boca abierta, base plana sobre un soporte de madera y brillos.
func _draw_bowl(ci: Node2D, r: Rect2) -> void:
	var b := tank.bowl()
	var c := r.position + b.position
	var rad := b.size.x
	var rim_y := r.position.y - r.size.x * 0.035
	var a := asin(clampf((rim_y - c.y) / rad, -1.0, 1.0))       # ángulo del borde (lado derecho)
	var ab := asin(clampf((r.end.y - c.y) / rad, -1.0, 1.0))    # ángulo donde empieza la base plana
	var half := rad * cos(a)
	var flat := rad * cos(ab)
	var glass := Color(0.75, 0.97, 0.92, 0.55)
	ci.draw_arc(c, rad + 1.5, a, ab, 40, glass, 4.0, true)
	ci.draw_arc(c, rad + 1.5, PI - ab, PI - a, 40, glass, 4.0, true)
	# Fondo de vidrio grueso y plano.
	ci.draw_rect(Rect2(c.x - flat, r.end.y - 5.0, flat * 2.0, 7.0), Color(0.8, 0.98, 0.95, 0.45))
	ci.draw_line(Vector2(c.x - flat, r.end.y + 2.0), Vector2(c.x + flat, r.end.y + 2.0), glass, 3.0, true)
	# Soporte: peana de madera torneada entre la bola y el mueble.
	var plank := r.end.y + stand_gap()
	var top_w := flat * 1.15
	ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - top_w, r.end.y + 2.0), Vector2(c.x + top_w, r.end.y + 2.0),
		Vector2(c.x + top_w + 16.0, plank), Vector2(c.x - top_w - 16.0, plank)]), Color("8a5a36"))
	ci.draw_rect(Rect2(c.x - top_w, r.end.y + 2.0, top_w * 2.0, 3.0), Color("b07a4f"))
	ci.draw_line(Vector2(c.x - top_w - 8.0, plank - 5.0), Vector2(c.x + top_w + 8.0, plank - 5.0), Color(0, 0, 0, 0.18), 2.0)
	var lip := DecorArt.ell(Vector2(c.x, rim_y), half, 9.0)
	lip.append(lip[0])
	ci.draw_polyline(lip, Color(0.85, 1.0, 0.97, 0.7), 3.0, true)
	ci.draw_arc(c, rad * 0.86, PI + 0.25, PI + 0.85, 24, Color(1, 1, 1, 0.28), 9.0, true)
	ci.draw_arc(c, rad * 0.78, PI + 0.32, PI + 0.55, 12, Color(1, 1, 1, 0.22), 5.0, true)
	ci.draw_arc(c, rad * 0.9, -0.95, -0.55, 16, Color(1, 1, 1, 0.16), 6.0, true)


## Hueco entre la pecera y la encimera: la redonda va sobre una peana.
func stand_gap() -> float:
	return 30.0 if Game.is_round() else 14.0


## Lo de la pecera es rectangular: en la redonda se tapan las esquinas con la propia pared (mismo shader).
func _draw_bowl_mask() -> void:
	if not Game.is_round():
		return
	var r := tank_rect
	var b := tank.bowl()
	var c := r.position + b.position
	var rad := b.size.x + 1.0
	var y0 := minf(r.position.y - 46.0, c.y - rad - 2.0)
	var y1 := r.end.y + 1.0
	for side: float in [-1.0, 1.0]:
		var xo := c.x + side * (rad + 3.0)
		var pts := PackedVector2Array([Vector2(xo, y0), Vector2(c.x, y0)])
		for i in 49:
			var a := -PI * 0.5 + side * PI * i / 48.0
			var q := c + Vector2(cos(a), sin(a)) * rad
			if q.y >= y1:
				# Base plana: el círculo se corta en el fondo de la pecera.
				pts.append(Vector2(c.x + side * sqrt(maxf(0.0, rad * rad - pow(y1 - c.y, 2.0))), y1))
				break
			pts.append(q)
		pts.append(Vector2(xo, y1))
		_bowl_mask.draw_colored_polygon(pts, Color.WHITE)
