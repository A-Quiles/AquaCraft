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
const SUB_TOP := 0.8                 ## la superficie del sustrato (sin moldear) está hacia el 80% de la altura
const SUB_RECT := 0.5                ## el rect del sustrato empieza más arriba para que quepan las montañas

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
var _front: Node2D
var _top: Node2D
var _decor_nodes: Array = []
var equip_rects := {}                ## hueco → Rect2 local (para tocar y avisos)
var editing := false                 ## modo Decorar
var selected_decor := -1
var selected_equip := ""


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
	_front = _node()
	_front.z_index = 25
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
	_top = Node2D.new()
	add_child(_top)
	_top.z_index = 55
	_top.draw.connect(_draw_top)
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


## Pecera redonda: centro (position) y radio (size.x) en coordenadas locales.
func bowl() -> Rect2:
	return Rect2(Vector2(size.x * 0.5, size.y - size.x * 0.5), Vector2(size.x * 0.5, 0.0))


## Mantiene un punto (con medio tamaño `half`) dentro del agua: sobre la arena moldeada y,
## en la pecera redonda, dentro del cristal.
func fit(p: Vector2, half: Vector2) -> Vector2:
	p.y = minf(p.y, surface_y(p.x) - half.y * 0.9)
	if Game.is_round():
		var b := bowl()
		var maxr := b.size.x - maxf(half.x, half.y) - 6.0
		var v := p - b.position
		if v.length() > maxr:
			p = b.position + v.normalized() * maxr
	return p


## Coloca la pecera en `rect` (coordenadas del padre) y lo reconstruye todo.
func layout(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	_water.size = size
	_glass.size = size
	_sub.position = Vector2(0, size.y * SUB_RECT)
	_sub.size = Vector2(size.x, size.y * (1.0 - SUB_RECT))
	_water.material.set_shader_parameter("size", size)
	_glass.material.set_shader_parameter("size", size)
	_sub.material.set_shader_parameter("size", _sub.size)
	_sub.material.set_shader_parameter("tank", size)
	_sub.material.set_shader_parameter("rect_top", size.y * SUB_RECT)
	_motes.emission_rect_extents = size * 0.5
	_motes.position = size * 0.5
	rebuild()
	for a in actors.values():
		a.position = fit(a.position.clamp(swim_rect(a.data.genes).position, swim_rect(a.data.genes).end), a.size_px() * 0.5)
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
	sm.set_shader_parameter("terrain", _terrain_arr())
	# El agua salada es más azul y transparente.
	var marine := Game.water_kind == "salada"
	_water.material.set_shader_parameter("top_col", Color(0.5, 0.88, 1.0) if marine else Color(0.42, 0.88, 0.9))
	_water.material.set_shader_parameter("deep_col", Color(0.02, 0.17, 0.42) if marine else Color(0.02, 0.24, 0.38))
	sm.set_shader_parameter("fog_col", Color(0.04, 0.22, 0.45) if marine else Color(0.04, 0.3, 0.42))
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
	var light := lerpf(0.8, 1.15, Game.efficiency("light")) if Game.equipment.light != "" else 0.8
	_water.material.set_shader_parameter("murk", clampf((w.dirt - 20.0) / 70.0, 0.0, 1.0))
	_water.material.set_shader_parameter("light", light)
	_sub.material.set_shader_parameter("light", light)


func set_night(n: float) -> void:
	_water.material.set_shader_parameter("night", n * 0.35)
	_glass.material.set_shader_parameter("night", n)


func _process(_dt: float) -> void:
	if editing or not Game.needs_maintenance().is_empty() or Game.equipment.thermo == "digital":
		_top.queue_redraw()
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
	return size.y * SUB_TOP + e * sh - terrain_at(x / size.x) * size.y


## Altura moldeada por el jugador en u (0..1), interpolada suave entre los puntos de control.
func terrain_at(u: float) -> float:
	var t: Array = Game.terrain
	if t.size() != Catalog.TERRAIN_N:
		return 0.0
	var f := clampf(u, 0.0, 1.0) * (Catalog.TERRAIN_N - 1)
	var i := mini(int(f), Catalog.TERRAIN_N - 2)
	var k := f - i
	k = k * k * (3.0 - 2.0 * k)
	return lerpf(float(t[i]), float(t[i + 1]), k)


func _terrain_arr() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(Catalog.TERRAIN_N)
	if Game.terrain.size() == Catalog.TERRAIN_N:
		for i in Catalog.TERRAIN_N:
			out[i] = float(Game.terrain[i])
	return out


## Tras moldear la arena: recoloca lo que se apoya en ella sin reconstruir la pecera.
func terrain_changed() -> void:
	_sub.material.set_shader_parameter("terrain", _terrain_arr())
	for i in _decor_nodes.size():
		set_decor_x(i, _decor_nodes[i].position.x)
	for c in _chest_bubbles:
		c.queue_free()
	_chest_bubbles.clear()
	_build_pump()
	_equip.queue_redraw()
	_eggs.queue_redraw()


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
	for n in _back.get_children() + _mid.get_children() + _front.get_children():
		n.queue_free()
	for c in _chest_bubbles:
		c.queue_free()
	_chest_bubbles.clear()
	_decor_nodes.clear()
	var u := decor_scale()
	for i in Game.decor.size():
		var it: Dictionary = Game.decor[i]
		var d: Dictionary = Catalog.DECOR[it.id]
		var item := DecorItem.new()
		item.id = it.id
		item.index = i
		item.layer = int(it.layer)
		item.u = u * (1.1 if d.kind == "plant" else 1.0) * (1.08 if item.layer == 2 else 1.0)
		item.sd = i * 977 + Game.tank_tier
		item.scale.x = -1.0 if it.flip else 1.0
		if d.kind == "plant":
			var m := ShaderMaterial.new()
			m.shader = SWAY
			m.set_shader_parameter("height", DecorArt.BOUNDS[it.id].size.y * item.u)
			m.set_shader_parameter("amp", 8.0 * u)
			m.set_shader_parameter("phase", i * 1.7)
			item.material = m
		[_back, _mid, _front][item.layer].add_child(item)
		_decor_nodes.append(item)
		set_decor_x(i, it.x * size.x)
		if it.id == "cofre":
			var cb := _make_bubbles()
			cb.amount = 10
			cb.explosiveness = 0.85
			cb.lifetime = (item.position.y - 50.0 * u) / 135.0
			cb.position = item.position + Vector2(0, -50 * u)
			_chest_bubbles.append(cb)
			add_child(cb)
			move_child(cb, _fish_layer.get_index())


## Mueve el dibujo de una decoración (durante el arrastre; Game se actualiza al soltar).
func set_decor_x(i: int, x: float) -> void:
	var item: DecorItem = _decor_nodes[i]
	var m := 0.17 if Game.is_round() else 0.03
	x = clampf(x, size.x * m, size.x * (1.0 - m))
	item.position = Vector2(x, surface_y(x) + [2.0, 6.0, 16.0][item.layer])


func decor_x(i: int) -> float:
	return _decor_nodes[i].position.x


func queue_redraw_top() -> void:
	_top.queue_redraw()


## Mueve un aparato mientras se arrastra (modo Decorar).
func preview_equip_x(slot: String, x: float) -> void:
	Game.equip_pos[slot] = clampf(x / size.x, 0.04, 0.96)
	if Game.is_round():
		Game.equip_pos[slot] = clampf(Game.equip_pos[slot], 0.24, 0.76)
	_equip.queue_redraw()


## Decoración bajo el dedo (la de delante primero). -1 si no hay.
func decor_at(p: Vector2) -> int:
	var best := -1
	var best_key := -1.0
	for item: DecorItem in _decor_nodes:
		var b: Rect2 = DecorArt.BOUNDS[item.id]
		var r := Rect2(b.position * item.u, b.size * item.u)
		if item.scale.x < 0.0:
			r.position.x = -r.end.x
		if r.grow(6.0).has_point(p - item.position):
			var key := item.layer * 100.0 + item.index
			if key > best_key:
				best_key = key
				best = item.index
	return best


func decor_rect(i: int) -> Rect2:
	var item: DecorItem = _decor_nodes[i]
	var b: Rect2 = DecorArt.BOUNDS[item.id]
	var r := Rect2(b.position * item.u, b.size * item.u)
	if item.scale.x < 0.0:
		r.position.x = -r.end.x
	r.position += item.position
	return r


## Aparato bajo el dedo ("" si ninguno). Incluye la tapa (luz) por encima del agua.
func equipment_at(p: Vector2) -> String:
	for slot in ["thermo", "ato", "filter", "heater", "pump", "light"]:
		if equip_rects.has(slot) and (equip_rects[slot] as Rect2).grow(10.0).has_point(p):
			return slot
	return ""


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


## Burbujas del aireador: menos cuanto más sucia está la piedra.
func _build_pump() -> void:
	_bubbles.position = Vector2(size.x * 0.08, surface_y(size.x * 0.08) - 8.0)
	_bubbles.lifetime = _bubbles.position.y / 130.0
	_update_pump_amount()


func _update_pump_amount() -> void:
	var base: int = {"difusor": 14, "bomba": 26, "circulacion": 38}.get(Game.equipment.pump, 0)
	var amount := maxi(2, int(base * snappedf(Game.efficiency("pump"), 0.25))) if base > 0 else 0
	_bubbles.emitting = amount > 0
	if amount > 0 and amount != _bubbles.amount:
		_bubbles.amount = amount


func _fade_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.12, Color(1, 1, 1, 1))
	g.add_point(0.85, Color(1, 1, 1, 1))
	return g


const EQUIP_X := {"pump": 0.08, "heater": 0.05, "esponja": 0.92, "mochila": 0.84, "skimmer": 0.88, "canister": 0.9,
	"filtro_mini": 0.86, "tira": 0.94, "digital": 0.86, "ato": 0.6}
const ROUND_X := {"heater": 0.3, "filter": 0.62, "thermo": 0.75}


## Posición x (0..1) de un aparato: la que eligió el jugador o la de fábrica.
func equip_x(slot: String) -> float:
	var id: String = Game.equipment.get(slot, "")
	if Game.is_round():
		return clampf(Game.equip_pos.get(slot, ROUND_X.get(slot, 0.5)), 0.24, 0.76)
	return Game.equip_pos.get(slot, EQUIP_X.get(slot, EQUIP_X.get(id, 0.5)))


## Suciedad visible: manchas pardas y verdes que crecen con el desgaste (determinista: no parpadea).
func _grime(ci: CanvasItem, r: Rect2, amount: float, sd: int) -> void:
	if amount <= 0.02:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	for i in int(4 + amount * 22):
		var p := r.position + Vector2(rng.randf(), rng.randf()) * r.size
		var rad := rng.randf_range(1.5, 5.0) * (0.6 + amount)
		var col := Color(0.35, 0.28, 0.12, 0.75) if rng.randf() < 0.6 else Color(0.3, 0.45, 0.15, 0.7)
		if rng.randf() < amount * 1.3:
			ci.draw_circle(p, rad, col)
	ci.draw_rect(r, Color(0.3, 0.25, 0.1, 0.35 * amount))


func _draw_equipment() -> void:
	var ci := _equip
	var e: Dictionary = Game.equipment
	var u := decor_scale()
	equip_rects.clear()
	if "light" in Catalog.TANKS[Game.tank_tier].equip:
		equip_rects["light"] = Rect2(0, -34, size.x, 34)
	var wear := func(slot: String) -> float: return clampf(1.0 - Game.condition(slot) / 100.0, 0.0, 1.0)
	if e.pump != "":
		var x := equip_x("pump") * size.x
		var p := Vector2(x, surface_y(x) - 4.0)
		ci.draw_line(p, Vector2(p.x - 10, 0), Color(0.85, 0.95, 0.95, 0.35), 2.5 * u, true)
		var stone := Color(0.75, 0.78, 0.82).lerp(Color(0.38, 0.32, 0.18), wear.call("pump"))
		ci.draw_colored_polygon(DecorArt.ell(p, 14 * u, 6 * u), stone.darkened(0.25))
		ci.draw_colored_polygon(DecorArt.ell(p + Vector2(0, -2), 12 * u, 3 * u), stone)
		equip_rects["pump"] = Rect2(p - Vector2(18, 14) * u, Vector2(36, 22) * u)
		_grime(ci, Rect2(p - Vector2(12, 6) * u, Vector2(24, 9) * u), wear.call("pump"), 11)
	if e.heater != "":
		var r := Rect2(equip_x("heater") * size.x - 6.5 * u, size.y * 0.06, 13 * u, size.y * (0.26 if e.heater == "calentador_mini" else 0.42))
		var w: float = wear.call("heater")
		ci.draw_rect(r, Color(0.8, 0.95, 1.0, 0.28))
		var on := Game.water_temp < Game._temp_target() - 0.1
		ci.draw_rect(Rect2(r.position + Vector2(4 * u, 20 * u), Vector2(5 * u, r.size.y - 30 * u)), Color(1.0, 0.45, 0.2, (0.85 if on else 0.3) * (1.0 - w * 0.6)))
		ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 16 * u)), Color(0.15, 0.17, 0.2))
		# Cal: costra blanquecina que va cubriendo el tubo.
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in int(w * 26):
			ci.draw_circle(r.position + Vector2(rng.randf() * r.size.x, 16 * u + rng.randf() * (r.size.y - 16 * u)), rng.randf_range(2, 4.5) * u, Color(0.95, 0.94, 0.88, 0.75))
		equip_rects["heater"] = r
	var dirty: float = wear.call("filter")
	var fx := equip_x("filter") * size.x
	match e.filter:
		"filtro_mini":
			# Mini cascada colgada del borde: caja pequeña, chorrito y tubo de aspiración.
			var r := Rect2(fx - 20 * u, -10 * u, 40 * u, 30 * u)
			ci.draw_rect(Rect2(fx - 4 * u, r.end.y, 8 * u, size.y * 0.3), Color(0.22, 0.24, 0.27, 0.9))
			ci.draw_rect(r, Color(0.2, 0.55, 0.62))
			ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 6 * u)), Color(0.28, 0.68, 0.75))
			ci.draw_rect(Rect2(r.position.x - 6 * u, r.position.y + 10 * u, 6 * u, (8 + 22 * (1.0 - dirty)) * u), Color(0.85, 0.95, 1.0, 0.5 * (1.0 - dirty)))
			_grime(ci, r, dirty, 24)
			equip_rects["filter"] = Rect2(r.position, Vector2(r.size.x, r.size.y + size.y * 0.3))
		"esponja":
			var c := Vector2(fx, surface_y(fx))
			ci.draw_line(c + Vector2(0, -60 * u), Vector2(c.x, 0), Color(0.85, 0.95, 0.95, 0.4), 3.0 * u, true)
			var sp := Rect2(c + Vector2(-16, -62) * u, Vector2(32, 58) * u)
			ci.draw_rect(sp, Color(0.18, 0.2, 0.22).lerp(Color(0.36, 0.3, 0.16), dirty))
			for k in 6:
				ci.draw_line(sp.position + Vector2(0, 8 + k * 9) * u, sp.position + Vector2(32, 8 + k * 9) * u, Color(0.28, 0.3, 0.33).lerp(Color(0.42, 0.36, 0.2), dirty), 2.0, true)
			_grime(ci, sp, dirty, 21)
			equip_rects["filter"] = sp
		"mochila":
			var r := Rect2(fx - 35 * u, -6, 70 * u, 64 * u)
			ci.draw_rect(r, Color(0.16, 0.18, 0.2))
			# Cascada de salida: se debilita cuando el cartucho está saturado.
			ci.draw_rect(Rect2(r.position.x + 8, 52 * u, 54 * u, (10 + 30 * (1.0 - dirty)) * u), Color(0.85, 0.95, 1.0, 0.45 * (1.0 - dirty)))
			var tube := Rect2(r.position.x + 26 * u, 58 * u, 18 * u, size.y * 0.5)
			ci.draw_rect(tube, Color(0.2, 0.22, 0.24))
			_grime(ci, tube, dirty, 22)
			equip_rects["filter"] = Rect2(r.position, Vector2(r.size.x, 58 * u + size.y * 0.5))
		"skimmer":
			var r := Rect2(fx - 23 * u, size.y * 0.08, 46 * u, size.y * 0.5)
			ci.draw_rect(r, Color(0.85, 0.92, 0.98, 0.35))
			# Vaso colector: se llena de espuma marrón.
			ci.draw_rect(Rect2(r.position + Vector2(6, 6) * u, Vector2(34 * u, r.size.y * 0.25)), Color(0.85, 0.92, 0.98, 0.25))
			ci.draw_rect(Rect2(r.position + Vector2(6 * u, 6 * u + r.size.y * 0.25 * (1.0 - dirty)), Vector2(34 * u, r.size.y * 0.25 * dirty)), Color(0.45, 0.33, 0.15, 0.85))
			for k in 8:
				ci.draw_circle(r.position + Vector2(12 + (k % 3) * 10, r.size.y * (0.38 + k * 0.07)) * Vector2(u, 1), 3.0 * u, Color(1, 1, 1, 0.55 * (1.0 - dirty * 0.7)))
			ci.draw_rect(Rect2(r.position.x - 4, r.end.y, r.size.x + 8, 14 * u), Color(0.15, 0.17, 0.2))
			equip_rects["filter"] = r
		"canister":
			var pipe := Color(0.6, 0.9, 0.75, 0.45).lerp(Color(0.42, 0.4, 0.18, 0.8), dirty)
			ci.draw_line(Vector2(fx, 0), Vector2(fx, size.y * 0.7), pipe, 9 * u, true)
			var head := Rect2(fx - 8 * u, size.y * 0.7, 16 * u, 40 * u)
			ci.draw_rect(head, pipe)
			_grime(ci, head, dirty, 23)
			ci.draw_line(Vector2(size.x * 0.12, 0), Vector2(size.x * 0.12, size.y * 0.12), pipe, 9 * u, true)
			equip_rects["filter"] = Rect2(fx - 14 * u, 0, 28 * u, size.y * 0.7 + 40 * u)
	if e.ato != "":
		var p := Vector2(equip_x("ato") * size.x, size.y * 0.035)
		ci.draw_rect(Rect2(p, Vector2(26 * u, 12 * u)), Color(0.15, 0.17, 0.2))
		ci.draw_line(p + Vector2(13 * u, 12 * u), p + Vector2(13 * u, 34 * u), Color(0.85, 0.95, 1.0, 0.5 * (1.0 - wear.call("ato"))), 3.0 * u, true)
		equip_rects["ato"] = Rect2(p - Vector2(8, 8), Vector2(42 * u, 48 * u))
	var tx := equip_x("thermo") * size.x
	match e.thermo:
		"tira": equip_rects["thermo"] = Rect2(tx - 10 * u, size.y * 0.1, 20 * u, size.y * 0.24)
		"digital": equip_rects["thermo"] = Rect2(tx - 43 * u, size.y * 0.07, 86 * u, 40 * u)
	_update_pump_amount()
	_top.queue_redraw()


## Por encima del cristal: termómetro pegado, avisos de mantenimiento y selección del modo Decorar.
func _draw_top() -> void:
	var ci := _top
	var u := decor_scale()
	var font := UI.bold
	if equip_rects.has("thermo"):
		var r: Rect2 = equip_rects.thermo
		if Game.equipment.thermo == "tira":
			# Tira de cristal líquido: solo se ilumina la casilla más cercana y su número.
			ci.draw_rect(r, Color(0.08, 0.1, 0.12, 0.9))
			var t := clampi(roundi(Game.water_temp), 18, 31)
			var degs := [30, 28, 26, 24, 22, 20, 18]
			var best := 0
			for k in degs.size():
				if absi(degs[k] - t) < absi(degs[best] - t):
					best = k
			for k in degs.size():
				var cell := Rect2(r.position + Vector2(3, 4 + k * (r.size.y - 8) / 7.0), Vector2(r.size.x - 6, (r.size.y - 8) / 7.0 - 2))
				ci.draw_rect(cell, Color(0.3, 0.95, 0.5) if k == best else Color(0.2, 0.25, 0.3))
				if k == best:
					var lx := cell.position.x - 38 * u if r.position.x > 50.0 else cell.end.x + 6 * u
					ci.draw_string(font, Vector2(lx, cell.end.y), "%d°" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * u), Color.WHITE)
		else:
			var batt := Game.condition("thermo") / 100.0
			ci.draw_rect(r, Color(0.92, 0.94, 0.96))
			ci.draw_rect(r.grow(-4), Color(0.55, 0.75, 0.6).lerp(Color(0.45, 0.5, 0.47), 1.0 - batt) if batt > 0.0 else Color(0.4, 0.45, 0.42))
			var txt := Game.thermometer_text()
			ci.draw_string(font, r.position + Vector2(8, r.size.y * 0.72), txt, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10, int(22 * u), Color(0.08, 0.15, 0.1, 0.25 + 0.75 * minf(1.0, batt * 2.0)))
			# Pila: icono que se vacía (y parpadea cuando está casi agotada).
			var b := Rect2(r.end.x - 16 * u, r.position.y + 6 * u, 10 * u, 6 * u)
			if batt > 0.25 or fmod(Time.get_ticks_msec() / 500.0, 2.0) < 1.0:
				ci.draw_rect(b, Color(0.1, 0.15, 0.1), false, 1.0)
				ci.draw_rect(Rect2(b.position, Vector2(b.size.x * batt, b.size.y)), Color(0.1, 0.15, 0.1) if batt > 0.25 else UI.BAD)
	var t := Time.get_ticks_msec() / 1000.0
	for slot in Game.needs_maintenance():
		if equip_rects.has(slot):
			var r: Rect2 = equip_rects[slot]
			var p := Vector2(clampf(r.get_center().x, 20.0, size.x - 20.0), maxf(r.position.y - 16.0, 16.0) + sin(t * 3.0) * 3.0)
			ci.draw_circle(p, 15.0, UI.WARN)
			ci.draw_string(font, p + Vector2(-4, 8), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	if editing:
		for slot in equip_rects:
			if slot != "light":
				var r: Rect2 = equip_rects[slot]
				var sel: bool = slot == selected_equip
				ci.draw_rect(r.grow(4.0), Color(0.55, 0.95, 1.0, 0.95 if sel else 0.45), false, 3.0 if sel else 1.5)
		for i in _decor_nodes.size():
			var r := decor_rect(i)
			var sel := i == selected_decor
			ci.draw_rect(r, Color(1, 1, 1, 0.9 if sel else 0.35), false, 3.0 if sel else 1.5)
			if sel:
				ci.draw_rect(r, Color(1, 1, 1, 0.08))


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
	var index := 0
	var layer := 1
	var u := 1.0
	var sd := 0

	func _draw() -> void:
		DecorArt.draw(self, id, u, sd)
