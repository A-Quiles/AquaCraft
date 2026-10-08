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
