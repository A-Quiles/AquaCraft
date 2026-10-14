class_name Previews
extends RefCounted
## Miniaturas para las tarjetas de la tienda.

static func decor(id: String, h := 140.0) -> Control:
	var c := DecorThumb.new()
	c.id = id
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func substrate(id: String, h := 140.0) -> Control:
	var c := SubThumb.new()
	c.id = id
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Dibujo de la tienda (ShopArt): kind = equipment / tank / food / product.
static func art(kind: String, id: Variant, h := 140.0) -> Control:
	var c := ArtThumb.new()
	c.kind = kind
	c.id = id
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func icon(kind: String, h := 140.0, px := 96.0) -> Control:
	var c := CenterContainer.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(VIcon.make(kind, px))
	return c


static func fish(g: Dictionary, h := 140.0, maxw := 230.0) -> Control:
	var c := CenterContainer.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := FishPreview.make(g, 1.0)
	var want := FishArt.size_px(g)
	var k := minf(h * 0.85 / want.y, maxw / want.x)
	p.custom_minimum_size = want * k
	c.add_child(p)
	return c


## Miniatura de estilo: kind = wall / stand / backdrop / ambience / theme (habitación en pequeño).
static func style(kind: String, id: String, h := 140.0) -> Control:
	var c := StyleThumb.new()
	c.kind = kind
	c.id = id
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.clip_contents = true
	return c


class DecorThumb extends Control:
	var id := ""

	func _draw() -> void:
		var b: Rect2 = DecorArt.BOUNDS[id]
		var k := minf(size.x * 0.9 / b.size.x, size.y * 0.92 / b.size.y)
		draw_set_transform(Vector2(size.x * 0.5 - (b.position.x + b.size.x * 0.5) * k, size.y * 0.96), 0.0, Vector2(k, k))
		DecorArt.draw(self, id, 1.0, 7)
		draw_set_transform(Vector2.ZERO)


class SubThumb extends Control:
	var id := ""

	func _draw() -> void:
		var s: Dictionary = Catalog.SUBSTRATES[id]
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id)
		var cols: Array = s.cols
		var r := Rect2(size.x * 0.12, size.y * 0.2, size.x * 0.76, size.y * 0.6)
		draw_rect(r, Catalog.color(cols[2]).darkened(0.2))
		var big: float = 9.0 if s.pebble > 0.5 else 3.0
		for i in (70 if s.pebble > 0.5 else 400):
			var p := Vector2(rng.randf_range(r.position.x + big, r.end.x - big), rng.randf_range(r.position.y + big, r.end.y - big))
			var c := Catalog.color(cols[rng.randi() % 3])
			draw_circle(p, big * rng.randf_range(0.7, 1.1), c.darkened(0.2))
			draw_circle(p + Vector2(-1, -1) * big * 0.2, big * rng.randf_range(0.5, 0.8), c)


class ArtThumb extends Control:
	var kind := ""
	var id: Variant

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		match kind:
			"equipment": ShopArt.equipment(self, id, r)
			"tank": ShopArt.tank(self, id, r)
			"food": ShopArt.food(self, id, r)
			"product": ShopArt.product(self, id, r)


class StyleThumb extends Control:
	const ROOM := preload("res://shaders/room.gdshader")
	const WATER := preload("res://shaders/water.gdshader")
	const W := 720.0                     ## se dibuja como si midiera lo que la pantalla y se escala
	var kind := ""
	var id := ""
	var _wall: ColorRect
	var _water: ColorRect

	func _ready() -> void:
		var wall_id := id if kind == "wall" else (id if kind == "theme" else "")
		if wall_id != "" or kind == "stand" or kind == "ambience":
			_wall = _shader_rect(ROOM)
			RoomArt.apply_wall(_wall.material, wall_id if wall_id != "" else "clasica")
			_wall.material.set_shader_parameter("thumb", true)
		if kind == "backdrop" or kind == "theme":
			_water = _shader_rect(WATER)
			RoomArt.apply_backdrop(_water.material, id)
			_water.material.set_shader_parameter("noise", preload("res://assets/textures/noise.png"))
			_water.material.set_shader_parameter("caustics", preload("res://assets/textures/caustics.png"))
		resized.connect(_fit)
		_fit()

	func _shader_rect(sh: Shader) -> ColorRect:
		var r := ColorRect.new()
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.material = ShaderMaterial.new()
		r.material.shader = sh
		r.show_behind_parent = true
		add_child(r)
		return r

	func _fit() -> void:
		var k := size.x / W
		if _wall:
			_wall.size = size
			_wall.material.set_shader_parameter("size", size / maxf(k, 0.01))
		if _water:
			var r := Rect2(Vector2.ZERO, size) if kind == "backdrop" else _tank_rect()
			_water.position = r.position
			_water.size = r.size
			_water.material.set_shader_parameter("size", r.size / maxf(k, 0.01))
		queue_redraw()

	func _tank_rect() -> Rect2:
		var k := size.x / W
		return Rect2(Vector2(150, 70) * k, Vector2(420, size.y / k - 70 - 92) * k)

	func _draw() -> void:
		var k := size.x / W
		if k <= 0.0:
			return
		var h := size.y / k
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
		match kind:
			"stand":
				RoomArt.stand(self, 40, W - 40, h * 0.3, h + 40, id)
			"ambience":
				RoomArt.garland(self, -10, W + 10, 10, id)
				RoomArt.picture(self, Rect2(W * 0.5 - 95, 60, 190, h - 150), id)
				draw_rect(Rect2(0, h - 40, W, 40), Color("b07a4f"))
				RoomArt.side_props(self, id, 110, W - 110, h - 40)
			"theme":
				var tr := _tank_rect()
				var t := Rect2(tr.position / k, tr.size / k)
				RoomArt.garland(self, -10, W + 10, 4, id)
				draw_rect(Rect2(t.position.x - 10, t.position.y - 18, t.size.x + 20, 18), Color("22303c"))
				draw_rect(Rect2(t.position.x - 10, t.end.y, t.size.x + 20, 12), Color("22303c"))
				draw_rect(Rect2(t.position.x, t.end.y - 22, t.size.x, 22), Color("d8c49a"))
				RoomArt.stand(self, 20, W - 20, t.end.y + 12, h + 40, id)
				RoomArt.side_props(self, id, 75, W - 75, t.end.y + 12)
				if id == "navidad":
					RoomArt.snow(self, t.position.x - 10, t.end.x + 10, t.position.y - 18)
		draw_set_transform(Vector2.ZERO)
