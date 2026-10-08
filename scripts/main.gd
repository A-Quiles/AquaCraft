extends Node2D
## Escena principal: habitación, mueble, pecera, marco y la interfaz. Gestiona el toque en el agua.

const ROOM := preload("res://shaders/room.gdshader")

enum Mode { NORMAL, FEED, CLEAN, EDIT }

var mode := Mode.NORMAL
var food_type := "escamas"
var tank: TankView
var hud: Hud
var tank_rect := Rect2()

var _room: ColorRect
var _furniture: Node2D
var _frame: Node2D
var _last_drag := Vector2.INF
var _drag_idx := -1                  ## decoración que se arrastra en modo Decorar
var _drag_off := 0.0
var _drag_from := Vector2.ZERO
var _drag_moved := false
var _feed_cd := 0.0
var _night := 0.0
var _night_acc := 999.0


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
	tank = TankView.new()
	add_child(tank)
	_frame = Node2D.new()
	_frame.z_index = 60
	_frame.draw.connect(_draw_frame)
	add_child(_frame)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.main = self
	layer.add_child(hud)
	get_viewport().size_changed.connect(_layout)
	Game.tank_changed.connect(_layout)
	_layout()
	if Game._arg("shot") != "":
		_screenshot.call_deferred()


## Captura para la ficha de la tienda / revisión visual: `-- demo=2 open=shop:3 shot=out.png`
func _screenshot() -> void:
	var open := Game._arg("open")
	await get_tree().create_timer(0.6).timeout
	match open.get_slice(":", 0):
		"shop": hud.open_shop(int(open.get_slice(":", 1)))
		"fish": hud.open_fish(Game.fish[int(open.get_slice(":", 1))].id if open.contains(":") else -1)
		"missions": hud.open_missions()
		"thermo": hud.open_thermostat()
		"feed":
			set_mode(Mode.FEED)
			for i in 4:
				tank.food.drop(tank.size.x * (0.25 + i * 0.17), "escamas")
		"edit":
			set_mode(Mode.EDIT)
			tank.selected_decor = 1
			tank.queue_redraw_top()
		"equip": hud.open_equipment(open.get_slice(":", 1))
		"decor": hud.open_decor_menu(0)
		"tutorial":
			hud.start_tutorial()
			await get_tree().process_frame
			for i in int(open.get_slice(":", 1)):
				hud._tutorial._advance()
		"algae":
			for i in Game.algae.size():
				Game.algae[i] = mini(255, int(Game._weights[i] * float(open.get_slice(":", 1))))
			Game._refresh_water()
			Game.algae_changed.emit()
			Game.changed.emit()
		"clean", "dirty":
			for i in Game.algae.size():
				Game.algae[i] = mini(255, int(Game._weights[i] * 150.0))
			Game._refresh_water()
			Game.algae_changed.emit()
			Game.changed.emit()
			if open == "clean":
				set_mode(Mode.CLEAN)
			for i in (30 if open == "clean" else 0):
				tank.clean_stroke(Vector2(tank.size.x * (0.2 + i * 0.02), tank.size.y * (0.3 + sin(i * 0.4) * 0.1)))
	await _save_shot()


func _save_shot() -> void:
	var delay := Game._arg("delay")
	await get_tree().create_timer(float(delay) if delay != "" else 2.5).timeout
	get_viewport().get_texture().get_image().save_png(Game._arg("shot"))
	get_tree().quit()


func _process(dt: float) -> void:
	_feed_cd = maxf(0.0, _feed_cd - dt)
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
	var stand: float = [96.0, 84.0, 64.0, 40.0][tier]
	var avail := Rect2(0, top, vp.x, vp.y - top - bottom - stand)
	# La pecera crece con la pantalla: en móviles altos aprovecha la altura en vez de dejar pared vacía.
	var w: float = vp.x * [0.8, 0.88, 0.95, 1.0][tier] - (28.0 if tier == 3 else 0.0)
	var h: float = minf(avail.size.y * [0.62, 0.74, 0.86, 0.95][tier], w * [1.3, 1.25, 1.4, 2.0][tier])
	var r := Rect2(Vector2((vp.x - w) * 0.5, avail.end.y - h), Vector2(w, h))
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


func set_mode(m: Mode) -> void:
	mode = Mode.NORMAL if mode == m else m
	tank.overlay.sponge_t = 0.0
	tank.editing = mode == Mode.EDIT
	tank.selected_decor = -1
	tank.queue_redraw_top()
	hud.refresh_mode()


# ───────────────────────── Toques en el agua ─────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var p := tank.to_local(event.position)
		# La tapa (luz) queda por encima del agua: también se puede tocar.
		var inside := Rect2(0, -34, tank.size.x, tank.size.y + 34).has_point(p)
		if not event.pressed:
			_last_drag = Vector2.INF
			if mode == Mode.EDIT:
				_end_decor_drag()
			return
		if not inside:
			return
		match mode:
			Mode.FEED:
				if p.y > 0.0 and _feed_cd <= 0.0 and Game.use_food(food_type):
					_feed_cd = 0.22
					tank.food.drop(p.x, food_type)
					hud.refresh_food()
			Mode.CLEAN:
				_last_drag = p
				tank.clean_stroke(p)
			Mode.EDIT:
				_drag_idx = tank.decor_at(p)
				tank.selected_decor = _drag_idx
				tank.queue_redraw_top()
				if _drag_idx >= 0:
					_drag_off = Game.decor[_drag_idx].x * tank.size.x - p.x
					_drag_from = p
					_drag_moved = false
			Mode.NORMAL:
				var a := tank.fish_at(p)
				var slot := tank.equipment_at(p)
				if a:
					hud.open_fish(a.data.id)
				elif slot != "":
					hud.open_equipment(slot)
				else:
					tank.startle(p)
	elif event is InputEventScreenDrag and mode == Mode.EDIT and _drag_idx >= 0:
		var p := tank.to_local(event.position)
		if p.distance_to(_drag_from) > 8.0:
			_drag_moved = true
		tank.set_decor_x(_drag_idx, p.x + _drag_off)
	elif event is InputEventScreenDrag and mode == Mode.CLEAN:
		var p := tank.to_local(event.position)
		if not Rect2(Vector2.ZERO, tank.size).has_point(p):
			return
		if _last_drag == Vector2.INF:
			_last_drag = p
		# Interpolamos para que un deslizamiento rápido no deje huecos.
		var steps := maxi(1, int(_last_drag.distance_to(p) / 14.0))
		for i in steps:
			tank.clean_stroke(_last_drag.lerp(p, float(i + 1) / steps))
		_last_drag = p


## Al soltar: si se movió, se guarda la posición; si fue un toque, se abren sus opciones.
func _end_decor_drag() -> void:
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
	var top_y := r.end.y + 14.0
	var x0 := 16.0 if Game.tank_tier < 3 else 0.0
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
	var space := r.position.y - 40.0 - top
	if space < 150.0:
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
	if space < 270.0:
		return
	# Estante con cactus, bote de comida y una pecerita redonda
	var sy := r.position.y - 70.0
	var sx := vp.x * 0.6
	ci.draw_rect(Rect2(sx, sy + 4, 240, 16), Color(0, 0, 0, 0.18))
	ci.draw_rect(Rect2(sx, sy, 240, 14), Color("b07a4f"))
	ci.draw_rect(Rect2(sx, sy + 10, 240, 4), Color("8a5a36"))
	var pot := sx + 34.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(pot - 18, sy - 30), Vector2(pot + 18, sy - 30), Vector2(pot + 13, sy), Vector2(pot - 13, sy)]), Color("e07a5f"))
	ci.draw_colored_polygon(DecorArt.ell(Vector2(pot, sy - 52), 13, 24), Color("5fae6e"))
	ci.draw_colored_polygon(DecorArt.ell(Vector2(pot - 15, sy - 50), 6, 10), Color("6fbf7e"))
	var jar := Rect2(sx + 78, sy - 56, 40, 56)
	ci.draw_rect(jar, Color("ff8a3d"))
	ci.draw_rect(Rect2(jar.position + Vector2(-3, -10), Vector2(46, 12)), Color("2a9d8f"))
	ci.draw_rect(Rect2(jar.position + Vector2(6, 18), Vector2(28, 20)), Color("fff3df"))
	ci.draw_circle(jar.position + Vector2(20, 28), 6, Color("ffb347"))
	var bowl := Vector2(sx + 180, sy - 34)
	ci.draw_circle(bowl, 34, Color(0.75, 0.95, 1.0, 0.35))
	ci.draw_circle(bowl + Vector2(0, 6), 28, Color(0.35, 0.78, 0.9, 0.6))
	ci.draw_colored_polygon(PackedVector2Array([bowl + Vector2(-6, 8), bowl + Vector2(-16, 1), bowl + Vector2(-16, 15)]), Color("ff7a3d"))
	ci.draw_colored_polygon(DecorArt.ell(bowl + Vector2(4, 8), 11, 7), Color("ff9a3a"))
	ci.draw_arc(bowl, 34, PI * 1.15, PI * 1.6, 12, Color(1, 1, 1, 0.6), 3.0, true)
	ci.draw_rect(Rect2(bowl + Vector2(-20, -36), Vector2(40, 6)), Color(0.85, 0.97, 1.0, 0.5))


func _draw_frame() -> void:
	var ci := _frame
	var r := tank_rect
	var wood := Game.tank_tier == 3
	var dark := Color("6b4428") if wood else Color("22303c")
	var lid := Rect2(r.position.x - 10, r.position.y - 30, r.size.x + 20, 30)
	ci.draw_rect(lid, dark)
	ci.draw_rect(Rect2(lid.position, Vector2(lid.size.x, 6)), dark.lightened(0.2))
	var led := 1.0 if Game.equipment.light != "" else 0.6
	ci.draw_rect(Rect2(r.position.x + 12, r.position.y - 6, r.size.x - 24, 4), Color(0.85, 1.0, 1.0, 0.9 * led))
	for k in 4:
		ci.draw_rect(Rect2(r.position.x + 12, r.position.y - 2 + k * 3, r.size.x - 24, 3), Color(0.7, 1.0, 1.0, 0.12 * led * (1.0 - k / 4.0)))
	ci.draw_rect(Rect2(r.position.x - 10, r.end.y, r.size.x + 20, 16), dark)
	ci.draw_rect(Rect2(r.position.x - 10, r.end.y, r.size.x + 20, 4), dark.lightened(0.25))
	for x in [r.position.x - 4.0, r.end.x]:
		ci.draw_rect(Rect2(x, r.position.y, 4, r.size.y), Color(0.75, 0.97, 0.92, 0.55) if not wood else dark)
