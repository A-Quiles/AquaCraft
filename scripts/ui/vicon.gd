class_name VIcon
extends Control
## Iconos vectoriales propios, dibujados en código (nítidos a cualquier tamaño, 0 KB de assets).
## Estilo «duotono»: trazo fino redondeado en el color de acento y un relleno translúcido del mismo tono.
## Las divisas (moneda y perla) van rellenas para reconocerse de un vistazo.

const INK := Color("e8f1f7")

var kind := "coin"
var tint := Color(0, 0, 0, 0)        ## si a > 0, el icono se pinta de un solo color

var _r := 16.0
var _w := 2.0


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
	return Color(tint, col.a) if tint.a > 0.0 else col


## Trazo (abierto o cerrado) en coordenadas relativas al centro, en unidades de radio.
func _line(c: Vector2, pts: Array, col: Color, closed := false, w := -1.0) -> void:
	var p := PackedVector2Array()
	for q in pts:
		p.append(c + (q as Vector2) * _r)
	if closed:
		p.append(p[0])
	draw_polyline(p, _c(col), _w if w < 0.0 else w, true)
	for q in [p[0], p[p.size() - 1]]:                  # extremos redondeados
		draw_circle(q, (_w if w < 0.0 else w) * 0.5, _c(col))


func _shape(c: Vector2, pts: Array, col: Color, fill_a := 0.22) -> void:
	var p := PackedVector2Array()
	for q in pts:
		p.append(c + (q as Vector2) * _r)
	draw_colored_polygon(p, _c(Color(col, fill_a)))
	_line(c, pts, col, true)


func _ring(c: Vector2, rad: float, col: Color, fill_a := 0.22) -> void:
	if fill_a > 0.0:
		draw_circle(c, rad * _r, _c(Color(col, fill_a)))
	draw_arc(c, rad * _r, 0, TAU, 32, _c(col), _w, true)


func _ell(cx: float, cy: float, rx: float, ry: float, n := 20, a0 := 0.0, a1 := TAU) -> Array:
	var out: Array = []
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		out.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return out


func _draw() -> void:
	_r = minf(size.x, size.y) * 0.5
	_w = maxf(1.4, _r * 0.13)
	var c := size * 0.5
	match kind:
		"coin":
			draw_circle(c, _r * 0.92, _c(Color("c98c17")))
			draw_circle(c + Vector2(0, -_r * 0.05), _r * 0.84, _c(Color("f2b53a")))
			draw_arc(c, _r * 0.62, 0, TAU, 28, _c(Color("d99a22")), _w * 0.8, true)
			_line(c, [Vector2(-0.32, 0.06), Vector2(-0.16, -0.08), Vector2(0.0, 0.06), Vector2(0.16, -0.08), Vector2(0.32, 0.06)], Color("fff0c2"), false, _w * 0.8)
		"pearl":
			draw_circle(c, _r * 0.86, _c(Color("8c7af0")))
			draw_circle(c + Vector2(-_r * 0.05, -_r * 0.06), _r * 0.74, _c(Color("cfc5ff")))
			draw_circle(c + Vector2(-_r * 0.28, -_r * 0.3), _r * 0.18, _c(Color(1, 1, 1, 0.9)))
		"food":
			_shape(c, [Vector2(-0.48, -0.32), Vector2(0.48, -0.32), Vector2(0.42, 0.82), Vector2(-0.42, 0.82)], Color("ff9a52"))
			_line(c, [Vector2(-0.58, -0.32), Vector2(0.58, -0.32)], Color("ff9a52"))
			for k in 3:
				draw_circle(c + Vector2(-0.3 + k * 0.3, -0.62 - (k % 2) * 0.16) * _r, _w * 0.75, _c(Color("ff9a52")))
		"sponge":
			_shape(c, [Vector2(-0.8, -0.1), Vector2(0.8, -0.1), Vector2(0.8, 0.55), Vector2(-0.8, 0.55)], Color("c7e05a"))
			_line(c, [Vector2(-0.4, -0.1), Vector2(-0.4, -0.55), Vector2(0.4, -0.55), Vector2(0.4, -0.1)], Color("c7e05a"))
			_line(c, [Vector2(-0.45, 0.22), Vector2(0.45, 0.22)], Color("c7e05a"))
		"shop":
			_shape(c, [Vector2(-0.72, -0.1), Vector2(0.72, -0.1), Vector2(0.72, 0.8), Vector2(-0.72, 0.8)], Color("2ec4b6"), 0.16)
			var aw: Array = [Vector2(-0.88, -0.1)]
			for k in 4:
				aw.append(Vector2(-0.88 + (k + 0.5) * 0.44, 0.12))
				aw.append(Vector2(-0.88 + (k + 1) * 0.44, -0.1))
			_line(c, aw, Color("2ec4b6"))
			_line(c, [Vector2(-0.88, -0.1), Vector2(-0.7, -0.72), Vector2(0.7, -0.72), Vector2(0.88, -0.1)], Color("2ec4b6"))
			_line(c, [Vector2(-0.18, 0.8), Vector2(-0.18, 0.35), Vector2(0.18, 0.35), Vector2(0.18, 0.8)], Color("2ec4b6"))
		"fish":
			var body := _ell(0.12, 0.0, 0.6, 0.4, 24, -2.45, 2.45)
			body.append(Vector2(-0.82, 0.38))
			body.append(Vector2(-0.82, -0.38))
			_shape(c, body, Color("ffa94d"))
			draw_circle(c + Vector2(0.4, -0.1) * _r, _w * 0.8, _c(Color("ffa94d")))
			_line(c, [Vector2(0.02, -0.22), Vector2(0.1, 0.0), Vector2(0.02, 0.22)], Color("ffa94d"), false, _w * 0.7)
		"egg":
			_shape(c, _ell(-0.3, 0.18, 0.36, 0.46, 20), Color("ffc46b"))
			_shape(c, _ell(0.32, -0.12, 0.36, 0.46, 20), Color("ffc46b"))
		"missions":
			_shape(c, [Vector2(-0.62, -0.7), Vector2(0.62, -0.7), Vector2(0.62, 0.88), Vector2(-0.62, 0.88)], Color("2ec4b6"), 0.14)
			_line(c, [Vector2(-0.25, -0.84), Vector2(0.25, -0.84), Vector2(0.25, -0.58), Vector2(-0.25, -0.58)], Color("2ec4b6"), true)
			for k in 3:
				var y := -0.25 + k * 0.36
				_line(c, [Vector2(-0.4, y), Vector2(-0.28, y + 0.11), Vector2(-0.1, y - 0.1)], Color("4fd18b"), false, _w * 0.85)
				_line(c, [Vector2(0.06, y), Vector2(0.4, y)], INK, false, _w * 0.85)
		"thermo":
			var st: Array = [Vector2(-0.2, 0.35)] + _ell(0.0, -0.62, 0.2, 0.2, 10, PI, TAU) + [Vector2(0.2, 0.35)]
			st += _ell(0.0, 0.58, 0.34, 0.34, 18, -1.0, PI + 1.0).slice(1)
			_shape(c, st, Color("ff6b5e"), 0.14)
			draw_circle(c + Vector2(0, 0.58) * _r, _r * 0.18, _c(Color("ff6b5e")))
			_line(c, [Vector2(0, 0.45), Vector2(0, -0.2)], Color("ff6b5e"), false, _w * 1.1)
		"ph":
			var d: Array = [Vector2(0, -0.88)] + _ell(0.0, 0.28, 0.56, 0.56, 22, -0.25, PI + 0.25)
			_shape(c, d, Color("4cc9f0"))
			_line(c, [Vector2(-0.3, 0.32), Vector2(-0.15, 0.24), Vector2(0.0, 0.32), Vector2(0.15, 0.24), Vector2(0.3, 0.32)], Color("4cc9f0"), false, _w * 0.8)
		"o2":
			for b in [[Vector2(-0.3, 0.32), 0.38], [Vector2(0.36, -0.05), 0.28], [Vector2(-0.08, -0.55), 0.2]]:
				_ring(c + b[0] * _r, b[1], Color("4cc9f0"), 0.16)
			draw_arc(c + Vector2(-0.3, 0.32) * _r, _r * 0.24, PI * 1.05, PI * 1.45, 8, _c(Color(1, 1, 1, 0.8)), _w * 0.8, true)
		"sparkle", "star":
			var pts: Array = []
			var n := 4 if kind == "sparkle" else 5
			for i in n * 2:
				var a := -PI * 0.5 + PI * i / n
				pts.append(Vector2(cos(a), sin(a)) * (0.92 if i % 2 == 0 else (0.34 if n == 4 else 0.42)))
			_shape(c, pts, Color("f2b53a") if kind == "star" else Color("7ee8d8"), 0.6 if kind == "star" else 0.3)
		"heart":
			var h: Array = _ell(-0.34, -0.18, 0.36, 0.36, 12, PI * 0.8, PI * 2.0) + _ell(0.34, -0.18, 0.36, 0.36, 12, PI, PI * 2.2) + [Vector2(0, 0.78)]
			_shape(c, h, Color("ff7a9a"), 0.45)
		"health":
			var k := 0.24
			_shape(c, [Vector2(-k, -0.75), Vector2(k, -0.75), Vector2(k, -k), Vector2(0.75, -k), Vector2(0.75, k), Vector2(k, k),
				Vector2(k, 0.75), Vector2(-k, 0.75), Vector2(-k, k), Vector2(-0.75, k), Vector2(-0.75, -k), Vector2(-k, -k)], Color("ff6b5e"), 0.3)
		"close", "plus", "minus":
			var col := INK if kind == "close" else Color.WHITE
			if kind == "close":
				_line(c, [Vector2(-0.5, -0.5), Vector2(0.5, 0.5)], col)
				_line(c, [Vector2(0.5, -0.5), Vector2(-0.5, 0.5)], col)
			else:
				_line(c, [Vector2(-0.55, 0), Vector2(0.55, 0)], col, false, _w * 1.4)
				if kind == "plus":
					_line(c, [Vector2(0, -0.55), Vector2(0, 0.55)], col, false, _w * 1.4)
		"back":
			_line(c, [Vector2(0.25, -0.6), Vector2(-0.35, 0), Vector2(0.25, 0.6)], INK, false, _w * 1.3)
		"check":
			_line(c, [Vector2(-0.6, 0), Vector2(-0.15, 0.45), Vector2(0.65, -0.5)], Color.WHITE, false, _w * 1.5)
		"lock":
			draw_arc(c + Vector2(0, -0.2) * _r, _r * 0.36, PI, TAU, 14, _c(Color("8ea4b9")), _w, true)
			_shape(c, [Vector2(-0.58, -0.2), Vector2(0.58, -0.2), Vector2(0.58, 0.75), Vector2(-0.58, 0.75)], Color("8ea4b9"))
		"clock":
			_ring(c, 0.82, INK, 0.1)
			_line(c, [Vector2(0, -0.48), Vector2(0, 0), Vector2(0.34, 0.14)], INK)
		"dna":
			for s in [0.0, PI]:
				var pts: Array = []
				for i in 13:
					pts.append(Vector2(sin(i * 0.55 + s) * 0.42, -0.85 + 1.7 * i / 12.0))
				_line(c, pts, Color("8c7af0") if s == 0.0 else Color("ff6b5e"))
			for i: int in [2, 5, 8, 11]:
				var y := -0.85 + 1.7 * i / 12.0
				_line(c, [Vector2(sin(i * 0.55) * 0.42, y), Vector2(sin(i * 0.55 + PI) * 0.42, y)], INK, false, _w * 0.6)
		"tank":
			_shape(c, [Vector2(-0.82, -0.55), Vector2(0.82, -0.55), Vector2(0.82, 0.7), Vector2(-0.82, 0.7)], Color("4cc9f0"), 0.1)
			var wv: Array = []
			for i in 9:
				wv.append(Vector2(-0.82 + 1.64 * i / 8.0, -0.25 + 0.06 * sin(i * 1.6)))
			_line(c, wv, Color("4cc9f0"), false, _w * 0.8)
			_line(c, [Vector2(-0.95, -0.7), Vector2(0.95, -0.7)], INK)
			_line(c, [Vector2(-0.82, 0.48), Vector2(0.82, 0.48)], Color("e8c98a"), false, _w * 0.8)
		"gear":
			var g: Array = []
			for i in 32:
				var a := TAU * i / 32.0
				g.append(Vector2(cos(a), sin(a)) * (0.86 if (i / 2) % 2 == 0 else 0.64))
			_shape(c, g, INK, 0.12)
			_ring(c, 0.26, INK, 0.0)
		"plant":
			_line(c, [Vector2(0, 0.85), Vector2(0, -0.1)], Color("4fd18b"))
			_shape(c, [Vector2(0, -0.05), Vector2(-0.35, -0.2), Vector2(-0.62, -0.62), Vector2(-0.2, -0.55), Vector2(0, -0.05)], Color("4fd18b"), 0.28)
			_shape(c, [Vector2(0, 0.3), Vector2(0.3, 0.08), Vector2(0.7, -0.2), Vector2(0.28, -0.28), Vector2(0, 0.3)], Color("4fd18b"), 0.28)
		"happy":
			_ring(c, 0.82, Color("f2b53a"), 0.18)
			draw_circle(c + Vector2(-0.28, -0.15) * _r, _w * 0.8, _c(Color("f2b53a")))
			draw_circle(c + Vector2(0.28, -0.15) * _r, _w * 0.8, _c(Color("f2b53a")))
			draw_arc(c + Vector2(0, 0.02) * _r, _r * 0.38, 0.35, PI - 0.35, 12, _c(Color("f2b53a")), _w, true)
		_:
			_ring(c, 0.7, INK, 0.1)
