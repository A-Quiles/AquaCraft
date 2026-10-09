extends Node2D
## Escena principal: habitación, mueble, pecera, marco y la interfaz. Gestiona el toque en el agua.

const ROOM := preload("res://shaders/room.gdshader")
const SHELF_SPACE := 150.0           ## alto reservado sobre la tapa para la estantería de cuidados

enum Mode { NORMAL, FEED, CLEAN, EDIT }

var mode := Mode.NORMAL
var food_type := "escamas"
var tank: TankView
var hud: Hud
var tank_rect := Rect2()

var _room: ColorRect
var _furniture: Node2D
var _frame: Node2D
var _props: Node2D
var prop_rects := {}                 ## nombre → Rect2 de los objetos de la estantería
var _last_drag := Vector2.INF
var _drag_idx := -1                  ## decoración que se arrastra en modo Decorar
var _drag_off := 0.0
var _drag_from := Vector2.ZERO
var _drag_moved := false
var _drag_equip := ""                ## aparato que se arrastra en modo Decorar
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
	_props = Node2D.new()
	_props.z_index = 61
	_props.draw.connect(_draw_props)
	add_child(_props)
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
	Game.changed.connect(_frame.queue_redraw)
	Game.changed.connect(_props.queue_redraw)
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
	var stand: float = [96.0, 84.0, 64.0, 40.0][tier]
	var avail := Rect2(0, top, vp.x, vp.y - top - bottom - stand)
	# La pecera crece con la pantalla: en móviles altos aprovecha la altura en vez de dejar pared vacía.
	# Pecera más contenida; el conjunto mueble + pecera se centra en la pantalla en móviles altos.
	var w: float = vp.x * [0.66, 0.78, 0.9, 1.0][tier] - (28.0 if tier == 3 else 0.0)
	var h: float = minf(avail.size.y * [0.46, 0.56, 0.7, 0.9][tier], w * [0.95, 0.92, 1.05, 1.7][tier])
	var bottom_y: float = minf(avail.end.y, avail.position.y + avail.size.y * 0.5 + h * 0.5 + 40.0)
	h = minf(h, bottom_y - top - SHELF_SPACE)          # deja sitio para la estantería
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
	_props.queue_redraw()


func set_mode(m: Mode) -> void:
	mode = Mode.NORMAL if mode == m else m
	tank.overlay.sponge_t = 0.0
	_props.queue_redraw()
	tank.editing = mode == Mode.EDIT
	tank.selected_decor = -1
	tank.selected_equip = ""
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
		var prop := prop_at(event.position)
		if prop != "":
			use_prop(prop)
			return
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
				var a := tank.fish_at(p)
				var slot := tank.equipment_at(p)
				if a:
					hud.open_fish(a.data.id)
				elif slot != "":
					hud.open_equipment(slot)
				else:
					tank.startle(p)
	elif event is InputEventScreenDrag and mode == Mode.EDIT and (_drag_idx >= 0 or _drag_equip != ""):
		var p := tank.to_local(event.position)
		if p.distance_to(_drag_from) > 8.0:
			_drag_moved = true
		if _drag_equip != "":
			tank.preview_equip_x(_drag_equip, p.x + _drag_off)
		else:
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
	var space := r.position.y - SHELF_SPACE - top
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


# ───────────────────────── Estantería de cuidados ─────────────────────────

func prop_at(p: Vector2) -> String:
	for k in prop_rects:
		if (prop_rects[k] as Rect2).grow(6.0).has_point(p):
			return k
	return ""


## Coger/soltar un objeto de la estantería: botes de comida, limpiador o productos.
func use_prop(k: String) -> void:
	if k == "sponge":
		set_mode(Mode.CLEAN)
	elif k.begins_with("food:"):
		var id := k.substr(5)
		if id != "escamas" and int(Game.food.get(id, 0)) <= 0:
			hud.show_toast("No te queda %s. Cómpralo en la tienda." % Catalog.FOODS[id].name.to_lower(), "food")
			return
		if mode == Mode.FEED and food_type == id:
			set_mode(Mode.FEED)
		else:
			food_type = id
			mode = Mode.NORMAL
			set_mode(Mode.FEED)
	elif k.begins_with("prod:"):
		hud.open_product(k.substr(5))


func _draw_props() -> void:
	var ci := _props
	prop_rects.clear()
	var r := tank_rect
	var vp := get_viewport_rect().size
	var sy := r.position.y - 46.0               # balda justo encima de la tapa
	var sw := minf(vp.x - 20.0, maxf(r.size.x + 40.0, 600.0))
	var sx := (vp.x - sw) * 0.5
	ci.draw_rect(Rect2(sx + 4, sy + 6, sw, 14), Color(0, 0, 0, 0.2))
	ci.draw_rect(Rect2(sx, sy, sw, 14), Color("b07a4f"))
	ci.draw_rect(Rect2(sx, sy + 10, sw, 4), Color("8a5a36"))
	var items: Array = ["sponge"]
	for f in Catalog.FOOD_ORDER:
		items.append("food:" + f)
	for p in Catalog.PRODUCT_ORDER:
		items.append("prod:" + p)
	var step := sw / items.size()
	var font := UI.bold
	for i in items.size():
		var k: String = items[i]
		var cx := sx + step * (i + 0.5)
		var lifted := (k == "sponge" and mode == Mode.CLEAN) or (k == "food:" + food_type and mode == Mode.FEED)
		var base := Vector2(cx, sy - (14.0 if lifted else 0.0))
		if lifted:
			ci.draw_circle(base + Vector2(0, -32), 40, Color(1.0, 0.9, 0.5, 0.25))
		if k == "sponge":
			# Limpiacristales magnético: asa + esponja.
			var b := Rect2(base + Vector2(-30, -34), Vector2(60, 34))
			ci.draw_rect(Rect2(b.position + Vector2(0, 12), Vector2(60, 22)), Color("ffd34d"))
			for h in [Vector2(-18, -10), Vector2(-2, -6), Vector2(14, -12), Vector2(22, -4)]:
				ci.draw_circle(base + h, 2.6, Color("e0a92c"))
			ci.draw_rect(Rect2(b.position + Vector2(0, 4), Vector2(60, 9)), Color("2e9e6a"))
			ci.draw_rect(Rect2(b.position + Vector2(14, -6), Vector2(32, 10)), Color("3a4552"))
			prop_rects[k] = b.grow(4)
		elif k.begins_with("food:"):
			var id := k.substr(5)
			var col := Catalog.color(Catalog.FOODS[id].col)
			var jar := Rect2(base + Vector2(-20, -54), Vector2(40, 54))
			ci.draw_rect(jar, Color(0.95, 0.97, 1.0, 0.55))
			ci.draw_rect(Rect2(jar.position + Vector2(3, 18), Vector2(34, 33)), col.darkened(0.1))
			ci.draw_rect(Rect2(jar.position + Vector2(-2, -8), Vector2(44, 10)), col.darkened(0.45))
			ci.draw_rect(Rect2(jar.position + Vector2(6, 22), Vector2(28, 16)), Color("fff3df"))
			var n := "∞" if id == "escamas" else str(Game.food.get(id, 0))
			ci.draw_string(font, jar.position + Vector2(0, 35), n, HORIZONTAL_ALIGNMENT_CENTER, 40, 15, UI.NAVY)
			ci.draw_rect(Rect2(jar.position + Vector2(4, 2), Vector2(4, 14)), Color(1, 1, 1, 0.5))
			prop_rects[k] = jar.grow(4)
		else:
			var id := k.substr(5)
			var pr: Dictionary = Catalog.PRODUCTS[id]
			var col := Catalog.color(pr.col)
			var bot := Rect2(base + Vector2(-15, -44), Vector2(30, 44))
			ci.draw_rect(bot, col)
			ci.draw_rect(Rect2(bot.position + Vector2(8, -14), Vector2(14, 14)), Color("eeeeee"))
			ci.draw_rect(Rect2(bot.position + Vector2(10, -22), Vector2(10, 9)), col.darkened(0.4))
			ci.draw_rect(Rect2(bot.position + Vector2(3, 12), Vector2(24, 16)), Color("fffaf2"))
			ci.draw_string(font, bot.position + Vector2(0, 25), pr.short, HORIZONTAL_ALIGNMENT_CENTER, 30, 12, UI.NAVY)
			var cnt: int = Game.products.get(id, 0)
			ci.draw_circle(bot.end + Vector2(-2, -42), 10, UI.NAVY if cnt > 0 else UI.BAD)
			ci.draw_string(font, bot.end + Vector2(-12, -37), str(cnt), HORIZONTAL_ALIGNMENT_CENTER, 20, 13, Color.WHITE)
			prop_rects[k] = Rect2(bot.position + Vector2(0, -22), bot.size + Vector2(0, 22)).grow(4)


func _draw_frame() -> void:
	var ci := _frame
	var r := tank_rect
	var wood := Game.tank_tier == 3
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
