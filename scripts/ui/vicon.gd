class_name VIcon
extends Control
## Iconos vectoriales dibujados en código (nítidos a cualquier tamaño, 0 KB de assets).

var kind := "coin"
var tint := Color(0, 0, 0, 0)        ## si a > 0, el icono se pinta de un solo color


static func make(k: String, px := 32.0, t := Color(0, 0, 0, 0)) -> VIcon:
	var i := VIcon.new()
	i.kind = k
	i.tint = t
	i.custom_minimum_size = Vector2(px, px)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


func set_kind(k: String) -> void:
	kind = k
	queue_redraw()


func _c(col: Color) -> Color:
	return tint if tint.a > 0.0 else col


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := size * 0.5
	match kind:
		"coin":
			draw_circle(c, r, _c(Color("e09a1d")))
			draw_circle(c + Vector2(0, -r * 0.06), r * 0.86, _c(Color("ffc94a")))
			draw_arc(c, r * 0.6, 0, TAU, 24, _c(Color("e8a72a")), r * 0.12, true)
			draw_arc(c, r * 0.72, PI * 1.1, PI * 1.5, 10, _c(Color("fff1b8")), r * 0.12, true)
		"pearl":
			draw_circle(c, r * 0.92, _c(Color("c9b8ff")))
			draw_circle(c + Vector2(-r * 0.06, -r * 0.08), r * 0.78, _c(Color("f1ecff")))
			draw_circle(c + Vector2(r * 0.18, r * 0.2), r * 0.4, _c(Color("e4d9ff")))
			draw_circle(c + Vector2(-r * 0.3, -r * 0.32), r * 0.2, _c(Color.WHITE))
		"food":
			var body := Rect2(c + Vector2(-r * 0.5, -r * 0.45), Vector2(r, r * 1.35))
			draw_rect(body, _c(Color("ff8a3d")))
			draw_rect(Rect2(body.position + Vector2(-r * 0.06, -r * 0.3), Vector2(r * 1.12, r * 0.32)), _c(Color("2a9d8f")))
			draw_rect(Rect2(body.position + Vector2(r * 0.15, r * 0.35), Vector2(r * 0.7, r * 0.4)), _c(Color("ffe2c2")))
			for k in 3:
				draw_circle(c + Vector2(-r * 0.3 + k * r * 0.3, -r * 0.95 + (k % 2) * r * 0.12), r * 0.1, _c(Color("ff8a3d")))
		"sponge":
			var b := Rect2(c + Vector2(-r * 0.8, -r * 0.45), Vector2(r * 1.6, r * 1.0))
			draw_rect(b, _c(Color("ffd34d")))
			draw_rect(Rect2(b.position, Vector2(b.size.x, r * 0.3)), _c(Color("4fc27a")))
			for h in [Vector2(-0.4, 0.15), Vector2(0.1, 0.3), Vector2(0.45, 0.05), Vector2(-0.05, 0.0)]:
				draw_circle(c + h * r, r * 0.09, _c(Color("e0a92c")))
			draw_arc(c + Vector2(r * 0.6, -r * 0.75), r * 0.18, 0, TAU, 12, _c(Color("9fe6ff")), r * 0.08, true)
		"shop":
			draw_rect(Rect2(c + Vector2(-r * 0.75, -r * 0.1), Vector2(r * 1.5, r * 0.95)), _c(Color("fff1e0")))
			draw_rect(Rect2(c + Vector2(-r * 0.2, r * 0.25), Vector2(r * 0.4, r * 0.6)), _c(Color("2a9d8f")))
			for k in 4:
				var x0 := -r * 0.9 + k * r * 0.45
				var col := Color("ff7a6b") if k % 2 == 0 else Color("ffffff")
				draw_colored_polygon(PackedVector2Array([c + Vector2(x0, -r * 0.7), c + Vector2(x0 + r * 0.45, -r * 0.7),
					c + Vector2(x0 + r * 0.45, -r * 0.15), c + Vector2(x0, -r * 0.15)]), _c(col))
				draw_circle(c + Vector2(x0 + r * 0.225, -r * 0.15), r * 0.225, _c(col))
		"fish":
			var body := DecorArt.ell(c + Vector2(r * 0.12, 0), r * 0.62, r * 0.42)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.4, 0), c + Vector2(-r * 0.95, -r * 0.45), c + Vector2(-r * 0.95, r * 0.45)]), _c(Color("ff9a3a")))
			draw_colored_polygon(body, _c(Color("ffb347")))
			draw_circle(c + Vector2(r * 0.42, -r * 0.08), r * 0.1, _c(Color("1d3557")))
		"egg":
			for e in [Vector2(-0.35, 0.2), Vector2(0.35, 0.2), Vector2(0, -0.3)]:
				draw_circle(c + e * r, r * 0.42, _c(Color("ffb347")))
				draw_circle(c + e * r + Vector2(-r * 0.12, -r * 0.12), r * 0.12, _c(Color("fff4d6")))
		"missions":
			draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.8), Vector2(r * 1.4, r * 1.7)), _c(Color("ffe9c7")))
			draw_rect(Rect2(c + Vector2(-r * 0.3, -r * 0.95), Vector2(r * 0.6, r * 0.3)), _c(Color("2a9d8f")))
			for k in 3:
				var y := -r * 0.3 + k * r * 0.42
				draw_polyline(PackedVector2Array([c + Vector2(-r * 0.45, y), c + Vector2(-r * 0.3, y + r * 0.13), c + Vector2(-r * 0.1, y - r * 0.12)]), _c(Color("4fc27a")), r * 0.1, true)
				draw_line(c + Vector2(r * 0.05, y), c + Vector2(r * 0.5, y), _c(Color("9aa7b5")), r * 0.1, true)
		"thermo":
			draw_line(c + Vector2(0, -r * 0.75), c + Vector2(0, r * 0.35), _c(Color("e6ecf1")), r * 0.42, true)
			draw_circle(c + Vector2(0, r * 0.5), r * 0.36, _c(Color("ff5a5f")))
			draw_line(c + Vector2(0, -r * 0.3), c + Vector2(0, r * 0.4), _c(Color("ff5a5f")), r * 0.2, true)
		"ph":
			var pts := PackedVector2Array([c + Vector2(0, -r * 0.9)])
			for i in 17:
				var a := -PI * 0.15 + PI * 1.3 * i / 16.0
				pts.append(c + Vector2(0, r * 0.25) + Vector2(cos(a), sin(a)) * r * 0.58)
			draw_colored_polygon(pts, _c(Color("4cc9f0")))
			draw_circle(c + Vector2(-r * 0.2, r * 0.15), r * 0.13, _c(Color("e6f9ff")))
		"o2":
			for b in [[Vector2(-0.3, 0.3), 0.38], [Vector2(0.35, -0.05), 0.28], [Vector2(-0.1, -0.5), 0.2]]:
				draw_arc(c + b[0] * r, b[1] * r, 0, TAU, 20, _c(Color("4cc9f0")), r * 0.13, true)
		"sparkle", "star":
			var pts := PackedVector2Array()
			var n := 4 if kind == "sparkle" else 5
			for i in n * 2:
				var a := -PI * 0.5 + PI * i / n
				pts.append(c + Vector2(cos(a), sin(a)) * r * (0.95 if i % 2 == 0 else (0.32 if n == 4 else 0.45)))
			draw_colored_polygon(pts, _c(Color("ffc94a") if kind == "star" else Color("7ee0d0")))
		"heart":
			draw_circle(c + Vector2(-r * 0.4, -r * 0.2), r * 0.45, _c(Color("ff6b8a")))
			draw_circle(c + Vector2(r * 0.4, -r * 0.2), r * 0.45, _c(Color("ff6b8a")))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.83, 0), c + Vector2(r * 0.83, 0), c + Vector2(0, r * 0.85)]), _c(Color("ff6b8a")))
		"health":
			draw_rect(Rect2(c + Vector2(-r * 0.22, -r * 0.7), Vector2(r * 0.44, r * 1.4)), _c(Color("ff5a5f")))
			draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.22), Vector2(r * 1.4, r * 0.44)), _c(Color("ff5a5f")))
		"close", "plus", "minus":
			var w := r * 0.22
			if kind == "close":
				draw_line(c + Vector2(-r, -r) * 0.55, c + Vector2(r, r) * 0.55, _c(Color("1d3557")), w, true)
				draw_line(c + Vector2(r, -r) * 0.55, c + Vector2(-r, r) * 0.55, _c(Color("1d3557")), w, true)
			else:
				draw_line(c + Vector2(-r * 0.6, 0), c + Vector2(r * 0.6, 0), _c(Color.WHITE), w, true)
				if kind == "plus":
					draw_line(c + Vector2(0, -r * 0.6), c + Vector2(0, r * 0.6), _c(Color.WHITE), w, true)
		"back":
			draw_polyline(PackedVector2Array([c + Vector2(r * 0.25, -r * 0.6), c + Vector2(-r * 0.35, 0), c + Vector2(r * 0.25, r * 0.6)]), _c(Color("1d3557")), r * 0.22, true)
		"check":
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.6, 0), c + Vector2(-r * 0.15, r * 0.45), c + Vector2(r * 0.65, -r * 0.5)]), _c(Color.WHITE), r * 0.24, true)
		"lock":
			draw_arc(c + Vector2(0, -r * 0.2), r * 0.38, PI, TAU, 14, _c(Color("7d8fa3")), r * 0.16, true)
			draw_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.2), Vector2(r * 1.2, r * 0.95)), _c(Color("7d8fa3")))
		"clock":
			draw_circle(c, r * 0.85, _c(Color("ffffff")))
			draw_arc(c, r * 0.85, 0, TAU, 28, _c(Color("1d3557")), r * 0.13, true)
			draw_line(c, c + Vector2(0, -r * 0.5), _c(Color("1d3557")), r * 0.12, true)
			draw_line(c, c + Vector2(r * 0.35, r * 0.1), _c(Color("1d3557")), r * 0.12, true)
		"dna":
			for s in [0.0, PI]:
				var pts := PackedVector2Array()
				for i in 13:
					var y := -r * 0.85 + r * 1.7 * i / 12.0
					pts.append(c + Vector2(sin(i * 0.55 + s) * r * 0.45, y))
				draw_polyline(pts, _c(Color("8f7bff") if s == 0.0 else Color("ff7a6b")), r * 0.14, true)
		"tank":
			draw_rect(Rect2(c + Vector2(-r * 0.85, -r * 0.6), Vector2(r * 1.7, r * 1.25)), _c(Color("bdefff")))
			draw_rect(Rect2(c + Vector2(-r * 0.85, -r * 0.25), Vector2(r * 1.7, r * 0.9)), _c(Color("4cc9f0")))
			draw_rect(Rect2(c + Vector2(-r * 0.95, -r * 0.72), Vector2(r * 1.9, r * 0.16)), _c(Color("1d3557")))
			draw_rect(Rect2(c + Vector2(-r * 0.85, r * 0.45), Vector2(r * 1.7, r * 0.2)), _c(Color("e3c48a")))
		"gear":
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(c, c + Vector2(cos(a), sin(a)) * r * 0.9, _c(Color("7d8fa3")), r * 0.32, true)
			draw_circle(c, r * 0.62, _c(Color("7d8fa3")))
			draw_circle(c, r * 0.25, _c(Color("fff8ee")))
		"plant":
			DecorArt.leaf(self, c + Vector2(0, r * 0.8), -0.5, r * 1.4, r * 0.7, _c(Color("2e8b57")), _c(Color("5fd39a")), 0.0, 0.8, 8)
			DecorArt.leaf(self, c + Vector2(0, r * 0.8), 0.55, r * 1.1, r * 0.6, _c(Color("2e8b57")), _c(Color("7ee0a0")), 0.0, 0.8, 8)
		"happy":
			draw_circle(c, r * 0.85, _c(Color("ffd34d")))
			draw_circle(c + Vector2(-r * 0.3, -r * 0.15), r * 0.1, _c(Color("1d3557")))
			draw_circle(c + Vector2(r * 0.3, -r * 0.15), r * 0.1, _c(Color("1d3557")))
			draw_arc(c + Vector2(0, r * 0.05), r * 0.4, 0.3, PI - 0.3, 12, _c(Color("1d3557")), r * 0.1, true)
