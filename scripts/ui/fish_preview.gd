class_name FishPreview
extends Control
## Pez animado para la interfaz (tarjetas de tienda, fichas...).

var genes: Dictionary


static func make(g: Dictionary, zoom := 1.0) -> FishPreview:
	var p := FishPreview.new()
	p.genes = g
	p.material = FishArt.material(g)
	p.material.set_shader_parameter("auto_wag", 5.0)
	p.material.set_shader_parameter("wag_amp", 0.7)
	p.custom_minimum_size = FishArt.size_px(g) * zoom
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _draw() -> void:
	# Se ajusta al rect conservando la proporción del pez.
	var want := FishArt.size_px(genes)
	var k := minf(size.x / want.x, size.y / want.y)
	var s := want * k
	draw_texture_rect(FishArt.WHITE, Rect2((size - s) * 0.5, s), false)
