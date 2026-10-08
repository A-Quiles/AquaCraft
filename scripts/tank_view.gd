class_name TankView
extends Node2D
## La pecera completa: agua, plantas, sustrato, equipo, adornos, huevos, peces, comida,
## burbujas, motas y cristal con algas. Se reconstruye cuando cambia la pecera o la decoración.

const WATER := preload("res://shaders/water.gdshader")
const SUBSTRATE := preload("res://shaders/substrate.gdshader")
const GLASS := preload("res://shaders/glass.gdshader")
const SWAY := preload("res://shaders/sway.gdshader")
const CAUSTICS := preload("res://assets/textures/caustics.png")
const NOISE := preload("res://assets/textures/noise.png")
const BUBBLE := preload("res://assets/textures/bubble.png")
const DOT := preload("res://assets/textures/dot.png")
const SUB_TOP := 0.8                 ## el rect del sustrato empieza al 80% de la altura

var size := Vector2(520, 460)
var actors := {}                     ## id → FishActor
var food: FoodLayer
var overlay: TankOverlay

var _water: ColorRect
var _back: Node2D
var _sub: ColorRect
var _equip: Node2D
var _mid: Node2D
var _eggs: Node2D
var _fish_layer: Node2D
var _bubbles: CPUParticles2D
var _chest_bubbles: Array[CPUParticles2D] = []
var _motes: CPUParticles2D
var _glass: ColorRect
var _algae_img: Image
var _algae_tex: ImageTexture
var _algae_dirty := true
var _sub_seed := 1.3


func _ready() -> void:
	_water = _rect(WATER)
	_back = _node()
	_sub = _rect(SUBSTRATE)
	_equip = _node()
	_equip.draw.connect(_draw_equipment)
	_mid = _node()
	_eggs = _node()
	_eggs.draw.connect(_draw_eggs)
	_fish_layer = _node()
	food = FoodLayer.new()
	food.tank = self
	add_child(food)
	_bubbles = _make_bubbles()
	add_child(_bubbles)
	_motes = CPUParticles2D.new()
	_motes.texture = DOT
	_motes.amount = 36
	_motes.lifetime = 14.0
	_motes.preprocess = 14.0
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.direction = Vector2(0.3, -1)
	_motes.spread = 60.0
	_motes.initial_velocity_min = 2.0
	_motes.initial_velocity_max = 7.0
	_motes.gravity = Vector2.ZERO
	_motes.scale_amount_min = 0.08
	_motes.scale_amount_max = 0.2
	_motes.color = Color(0.85, 1.0, 0.95, 0.3)
	_motes.color_ramp = _fade_ramp()
	add_child(_motes)
	overlay = TankOverlay.new()
	overlay.tank = self
	overlay.z_index = 40
	add_child(overlay)
	_glass = _rect(GLASS)
	_glass.z_index = 50
	_algae_img = Image.create_from_data(Game.GW, Game.GH, false, Image.FORMAT_L8, Game.algae)
	_algae_tex = ImageTexture.create_from_image(_algae_img)
	_glass.material.set_shader_parameter("algae", _algae_tex)
	for m in [_water.material, _sub.material, _glass.material]:
		m.set_shader_parameter("noise", NOISE)
		m.set_shader_parameter("caustics", CAUSTICS)
	Game.fish_added.connect(_on_fish_added)
	Game.fish_removed.connect(_on_fish_removed)
	Game.eggs_changed.connect(_eggs.queue_redraw)
	Game.algae_changed.connect(func(): _algae_dirty = true)
	Game.changed.connect(_refresh_water)
	Game.changed.connect(_equip.queue_redraw)


func _rect(shader: Shader) -> ColorRect:
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = shader
	r.material = m
	add_child(r)
	return r


func _node() -> Node2D:
	var n := Node2D.new()
	add_child(n)
	return n


## Coloca la pecera en `rect` (coordenadas del padre) y lo reconstruye todo.
func layout(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	_water.size = size
	_glass.size = size
	_sub.position = Vector2(0, size.y * SUB_TOP)
	_sub.size = Vector2(size.x, size.y * (1.0 - SUB_TOP))
	_water.material.set_shader_parameter("size", size)
	_glass.material.set_shader_parameter("size", size)
	_sub.material.set_shader_parameter("size", _sub.size)
	_motes.emission_rect_extents = size * 0.5
	_motes.position = size * 0.5
	rebuild()
	for a in actors.values():
		a.position = a.position.clamp(swim_rect(a.data.genes).position, swim_rect(a.data.genes).end)
		a.target = a.position


func rebuild() -> void:
	_sub_seed = 1.3 + Game.tank_tier * 2.1
	var sub: Dictionary = Catalog.SUBSTRATES[Game.substrate]
	var sm: ShaderMaterial = _sub.material
	sm.set_shader_parameter("col_a", Catalog.color(sub.cols[0]))
	sm.set_shader_parameter("col_b", Catalog.color(sub.cols[1]))
	sm.set_shader_parameter("col_c", Catalog.color(sub.cols[2]))
	sm.set_shader_parameter("pebble", sub.pebble)
	sm.set_shader_parameter("seed", _sub_seed)
	_build_decor()
	_build_pump()
	_equip.queue_redraw()
	_eggs.queue_redraw()
	for f in Game.fish:
		if not actors.has(f.id):
			_on_fish_added(f)
	_refresh_water()


func _refresh_water() -> void:
	var w := Game.water()
	var light := 1.15 if Game.equipment.light != "" else 0.8
	_water.material.set_shader_parameter("murk", clampf((w.dirt - 20.0) / 70.0, 0.0, 1.0))
	_water.material.set_shader_parameter("light", light)
	_sub.material.set_shader_parameter("light", light)


func set_night(n: float) -> void:
	_water.material.set_shader_parameter("night", n * 0.35)
	_glass.material.set_shader_parameter("night", n)


func _process(_dt: float) -> void:
	if not Game.eggs.is_empty():
		_eggs.queue_redraw()
	if _algae_dirty:
		_algae_dirty = false
		_algae_img.set_data(Game.GW, Game.GH, false, Image.FORMAT_L8, Game.algae)
		_algae_tex.update(_algae_img)


# ───────────────────────── Geometría ─────────────────────────

## Altura (y local) de la superficie del sustrato en x. Igual que en substrate.gdshader.
func surface_y(x: float) -> float:
	var sh := size.y * (1.0 - SUB_TOP)
	var xa := x / sh
	var e := 0.3 + 0.08 * sin(xa * 1.9 + _sub_seed) + 0.05 * sin(xa * 4.7 + _sub_seed * 2.3) + 0.02 * sin(xa * 11.0)
	return size.y * SUB_TOP + e * sh


func swim_rect(g: Dictionary) -> Rect2:
	var s := FishArt.size_px(g) * 0.5
	var top := size.y * 0.06 + s.y
	var bottom := size.y * SUB_TOP + size.y * (1.0 - SUB_TOP) * 0.22 - s.y * 0.8
	return Rect2(Vector2(s.x + 6.0, top), Vector2(size.x - 2.0 * s.x - 12.0, maxf(10.0, bottom - top)))


func decor_scale() -> float:
	return clampf(size.y / 520.0, 0.8, 1.3)


# ───────────────────────── Peces ─────────────────────────

func _on_fish_added(f: Dictionary) -> void:
	var a := FishActor.new()
	_fish_layer.add_child(a)
	a.setup(f, self)
	actors[f.id] = a


func _on_fish_removed(id: int) -> void:
	if actors.has(id):
		overlay.burst(actors[id].position, "sparkle", 10)
		actors[id].queue_free()
		actors.erase(id)


func fish_at(p: Vector2) -> FishActor:
	var best: FishActor = null
	var bd := INF
	for a in actors.values():
		var s: Vector2 = a.size_px()
		var d: float = a.position.distance_to(p)
		if d < maxf(s.x * 0.6, 34.0) and d < bd:
			bd = d
			best = a
	return best


func startle(p: Vector2) -> void:
	overlay.ripple(p)
	for a in actors.values():
		if a.position.distance_to(p) < 140.0:
			a.startle(p)


func clean_stroke(p: Vector2) -> void:
	overlay.sponge_pos = p
	overlay.sponge_t = 0.6
	var got := Game.clean_at(Vector2(p.x / size.x, p.y / size.y))
	if got > 0.05 and randf() < 0.5:
		overlay.burst(p + Vector2(randf_range(-20, 20), randf_range(-15, 15)), "sparkle", 1)


# ───────────────────────── Decoración y equipo ─────────────────────────

func _build_decor() -> void:
	for n in _back.get_children() + _mid.get_children():
		n.queue_free()
	for c in _chest_bubbles:
		c.queue_free()
	_chest_bubbles.clear()
	var u := decor_scale()
	var slots: int = Catalog.TANKS[Game.tank_tier].slots
	var xs := _slot_positions(slots)
	for i in Game.decor.size():
		var id: String = Game.decor[i]
		var d: Dictionary = Catalog.DECOR[id]
		var item := DecorItem.new()
		item.id = id
		item.u = u * (1.1 if d.kind == "plant" else 1.0)
		item.sd = i * 977 + Game.tank_tier
		var x: float = xs[i] * size.x
		item.position = Vector2(x, surface_y(x) + (2.0 if d.kind == "plant" else 6.0))
		if d.kind == "plant":
			var m := ShaderMaterial.new()
			m.shader = SWAY
			m.set_shader_parameter("height", DecorArt.BOUNDS[id].size.y * item.u)
			m.set_shader_parameter("amp", 8.0 * u)
			m.set_shader_parameter("phase", i * 1.7)
			item.material = m
			_back.add_child(item)
		else:
			_mid.add_child(item)
		if id == "cofre":
			var cb := _make_bubbles()
			cb.amount = 10
			cb.explosiveness = 0.85
			cb.lifetime = (item.position.y - 50.0 * u) / 135.0
			cb.position = item.position + Vector2(0, -50 * u)
			_chest_bubbles.append(cb)
			add_child(cb)
			move_child(cb, _fish_layer.get_index())


## Orden de llenado: extremos primero y luego hacia el centro, con un poco de azar fijo.
func _slot_positions(n: int) -> Array:
	var raw: Array = []
	for i in n:
		raw.append(0.1 + 0.8 * (i + 0.5) / n + sin(i * 12.9898) * 0.025)
	var order: Array = []
	var lo := 0
	var hi := n - 1
	while lo <= hi:
		order.append(raw[lo])
		if hi != lo:
			order.append(raw[hi])
		lo += 1
		hi -= 1
	return order


func _make_bubbles() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = BUBBLE
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(7, 2)
	p.direction = Vector2(0, -1)
	p.spread = 7.0
	p.gravity = Vector2(0, -25)
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 110.0
	p.tangential_accel_min = -12.0
	p.tangential_accel_max = 12.0
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.32
	p.color_ramp = _fade_ramp()
	p.z_index = 30
	return p


func _build_pump() -> void:
	var amount: int = {"difusor": 14, "bomba": 26, "circulacion": 38}.get(Game.equipment.pump, 0)
	_bubbles.emitting = amount > 0
	if amount > 0:
		_bubbles.amount = amount
		_bubbles.position = Vector2(size.x * 0.08, surface_y(size.x * 0.08) - 8.0)
		_bubbles.lifetime = _bubbles.position.y / 130.0


func _fade_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.12, Color(1, 1, 1, 1))
	g.add_point(0.85, Color(1, 1, 1, 1))
	return g


func _draw_equipment() -> void:
	var ci := _equip
	var e: Dictionary = Game.equipment
	var u := decor_scale()
	if e.pump != "":
		var p := Vector2(size.x * 0.08, surface_y(size.x * 0.08) - 4.0)
		ci.draw_line(p, Vector2(p.x - 10, 0), Color(0.85, 0.95, 0.95, 0.35), 2.5 * u, true)
		ci.draw_colored_polygon(DecorArt.ell(p, 14 * u, 6 * u), Color(0.55, 0.58, 0.62))
		ci.draw_colored_polygon(DecorArt.ell(p + Vector2(0, -2), 12 * u, 3 * u), Color(0.75, 0.78, 0.82))
	if e.heater != "":
		var x := size.x * 0.03
		var r := Rect2(x, size.y * 0.06, 13 * u, size.y * 0.42)
		ci.draw_rect(r, Color(0.8, 0.95, 1.0, 0.28))
		var on := absf(Game.water_temp - Game.heater_target) > 0.2
		ci.draw_rect(Rect2(r.position + Vector2(4 * u, 20 * u), Vector2(5 * u, r.size.y - 30 * u)), Color(1.0, 0.45, 0.2, 0.85 if on else 0.35))
		ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 16 * u)), Color(0.15, 0.17, 0.2))
	match e.filter:
		"esponja":
			var c := Vector2(size.x * 0.92, surface_y(size.x * 0.92))
			ci.draw_line(c + Vector2(0, -60 * u), Vector2(c.x, 0), Color(0.85, 0.95, 0.95, 0.4), 3.0 * u, true)
			var sp := Rect2(c + Vector2(-16, -62) * u, Vector2(32, 58) * u)
			ci.draw_rect(sp, Color(0.18, 0.2, 0.22))
			for k in 6:
				ci.draw_line(sp.position + Vector2(0, 8 + k * 9) * u, sp.position + Vector2(32, 8 + k * 9) * u, Color(0.28, 0.3, 0.33), 2.0, true)
		"mochila":
			ci.draw_rect(Rect2(size.x * 0.78, -6, 70 * u, 64 * u), Color(0.16, 0.18, 0.2))
			ci.draw_rect(Rect2(size.x * 0.78 + 8, 52 * u, 54 * u, 10 * u), Color(0.85, 0.95, 1.0, 0.35))
			ci.draw_rect(Rect2(size.x * 0.78 + 22 * u, 58 * u, 18 * u, size.y * 0.5), Color(0.2, 0.22, 0.24))
		"canister":
			var x := size.x * 0.9
			ci.draw_line(Vector2(x, 0), Vector2(x, size.y * 0.7), Color(0.6, 0.9, 0.75, 0.45), 9 * u, true)
			ci.draw_rect(Rect2(x - 8 * u, size.y * 0.7, 16 * u, 40 * u), Color(0.6, 0.9, 0.75, 0.4))
			ci.draw_line(Vector2(size.x * 0.12, 0), Vector2(size.x * 0.12, size.y * 0.12), Color(0.6, 0.9, 0.75, 0.45), 9 * u, true)


func _draw_eggs() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for e in Game.eggs:
		var x: float = e.x * size.x
		var base := Vector2(x, surface_y(x) - 5.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = e.id
		for k in 9:
			var p := base + Vector2(rng.randf_range(-14, 14), -rng.randf_range(0, 10))
			_eggs.draw_circle(p, 5.0, Color(1.0, 0.75, 0.35, 0.75))
			_eggs.draw_circle(p + Vector2(0.8, 0.8), 2.0 + 0.4 * sin(t * 3.0 + k), Color(0.35, 0.2, 0.1, 0.6))
			_eggs.draw_circle(p + Vector2(-1.8, -1.8), 1.3, Color(1, 1, 1, 0.9))


class DecorItem extends Node2D:
	var id: String
	var u := 1.0
	var sd := 0

	func _draw() -> void:
		DecorArt.draw(self, id, u, sd)
