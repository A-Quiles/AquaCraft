class_name EquipArt
extends RefCounted
## Piezas 2D con volumen para los aparatos: cajas con degradado y sombra, cilindros con brillo
## y animaciones sencillas (chorro, burbujas, ondas). Las usan la pecera y la tienda.


## Polígono convexo de rectángulo redondeado (para pintar con color por vértice).
static func rpoly(r: Rect2, rad: float, off := Vector2.ZERO) -> PackedVector2Array:
	rad = clampf(rad, 0.0, minf(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	if rad < 1.0:
		for p in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			pts.append(p + off)
		return pts
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for i in 4:
		for k in 5:
			var a := deg_to_rad(-90.0 + i * 90.0 + k * 22.5)
			pts.append(cs[i] + Vector2(cos(a), sin(a)) * rad + off)
	return pts


## Sombra suave proyectada (la luz viene de arriba a la izquierda).
static func shade(ci: CanvasItem, r: Rect2, rad: float, a := 0.1) -> void:
	for i in 3:
		ci.draw_colored_polygon(rpoly(r.grow(i * 1.6), rad + i * 1.6, Vector2(2.5, 3.5)), Color(0, 0.04, 0.08, a))


## Caja con volumen: degradado vertical, filo oscuro, brillo en el borde superior y sombra.
static func body(ci: CanvasItem, r: Rect2, col: Color, rad := 6.0, shadow := true) -> void:
	if shadow:
		shade(ci, r, rad, 0.1 * col.a)
	var pts := rpoly(r, rad)
	var cols := PackedColorArray()
	for p in pts:
		var k := clampf((p.y - r.position.y) / maxf(r.size.y, 1.0), 0.0, 1.0)
		cols.append(col.lightened(0.28).lerp(col.darkened(0.34), k))
	ci.draw_polygon(pts, cols)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, Color(col.darkened(0.6), 0.55 * col.a), 1.2, true)
	var m := minf(rad * 0.8, r.size.x * 0.4) + 1.0
	ci.draw_line(Vector2(r.position.x + m, r.position.y + 1.8), Vector2(r.end.x - m, r.position.y + 1.8), Color(1, 1, 1, 0.38 * col.a), 1.6, true)


## Cilindro vertical: sombra a los lados, luz a la izquierda y brillo especular.
static func tube(ci: CanvasItem, r: Rect2, col: Color, caps := true) -> void:
	var w := r.size.x
	if caps:
		ci.draw_colored_polygon(DecorArt.ell(Vector2(r.get_center().x, r.end.y), w * 0.5, w * 0.14), col.darkened(0.45))
	var xs := [0.0, 0.28, 0.62, 1.0]
	var cs := [col.darkened(0.45), col.lightened(0.4), col, col.darkened(0.5)]
	for i in 3:
		var a: float = r.position.x + w * xs[i]
		var b: float = r.position.x + w * xs[i + 1]
		ci.draw_polygon(PackedVector2Array([Vector2(a, r.position.y), Vector2(b, r.position.y), Vector2(b, r.end.y), Vector2(a, r.end.y)]),
			PackedColorArray([cs[i], cs[i + 1], cs[i + 1], cs[i]]))
	ci.draw_line(Vector2(r.position.x + w * 0.22, r.position.y + 2), Vector2(r.position.x + w * 0.22, r.end.y - 2), Color(1, 1, 1, 0.45 * col.a), maxf(1.2, w * 0.09), true)
	if caps:
		ci.draw_colored_polygon(DecorArt.ell(Vector2(r.get_center().x, r.position.y), w * 0.5, w * 0.14), col.lightened(0.3))


## Manguera con relieve: contorno, cuerpo y brillo.
static func hose(ci: CanvasItem, pts: PackedVector2Array, w: float, col: Color) -> void:
	ci.draw_polyline(pts, Color(col.darkened(0.5), col.a), w + 2.0, true)
	ci.draw_polyline(pts, col, w, true)
	var hi := PackedVector2Array()
	for p in pts:
		hi.append(p + Vector2(-w * 0.2, 0))
	ci.draw_polyline(hi, Color(col.lightened(0.5), col.a * 0.8), maxf(1.0, w * 0.3), true)


## Burbujas que suben desde p hasta h píxeles por encima, repartidas en `spread` de ancho.
static func bubbles(ci: CanvasItem, p: Vector2, h: float, t: float, n: int, a := 0.8, spread := 3.0, col := Color.WHITE) -> void:
	if a <= 0.02 or h <= 1.0:
		return
	for k in n:
		var ph := fposmod(t * (0.3 + 0.18 * fposmod(k * 0.37, 1.0)) + float(k) / n, 1.0)
		var q := p + Vector2(sin(t * 2.0 + k * 1.7) * spread * 0.5 + (fposmod(k * 0.618, 1.0) - 0.5) * spread, -ph * h)
		var rad := 1.3 + (k * 7 % 3) * 0.6
		var al := a * minf(1.0, (1.0 - ph) * 3.0) * minf(1.0, ph * 8.0)
		ci.draw_circle(q, rad, Color(col, al * 0.18))
		ci.draw_arc(q, rad, 0, TAU, 10, Color(col, al), 1.0, true)
		ci.draw_circle(q + Vector2(-rad * 0.35, -rad * 0.35), rad * 0.3, Color(1, 1, 1, al))


## Ondas que se abren en p (donde cae agua).
static func ripple(ci: CanvasItem, p: Vector2, t: float, rx: float, a := 0.5) -> void:
	for k in 2:
		var ph := fposmod(t * 1.1 + k * 0.5, 1.0)
		var pts := DecorArt.ell(p, rx * (0.3 + ph), rx * 0.28 * (0.3 + ph), 18)
		pts.append(pts[0])
		ci.draw_polyline(pts, Color(0.9, 1.0, 1.0, a * (1.0 - ph)), 1.2, true)


## Chorro de agua que cae de y0 a y1 con vetas que bajan, y ondas al final.
static func stream(ci: CanvasItem, cx: float, y0: float, y1: float, w: float, t: float, a := 1.0) -> void:
	if a <= 0.03 or y1 <= y0:
		return
	var len := y1 - y0
	ci.draw_rect(Rect2(cx - w * 0.5, y0, w, len), Color(0.85, 0.95, 1.0, 0.26 * a))
	var n := maxi(1, int(w / 6.0))
	for i in n:
		var x := cx - w * 0.5 + (i + 0.5) * w / n
		for k in 3:
			var y := y0 + fposmod(t * (80.0 + 17.0 * i) + k * len / 3.0 + i * 9.0, len)
			ci.draw_line(Vector2(x, y), Vector2(x, minf(y + 7.0, y1)), Color(1, 1, 1, 0.55 * a), 1.3, true)
	ci.draw_line(Vector2(cx - w * 0.5 + 1, y0), Vector2(cx - w * 0.5 + 1, y1), Color(1, 1, 1, 0.4 * a), 1.2, true)
	ripple(ci, Vector2(cx, y1), t, maxf(w, 8.0), 0.55 * a)
	bubbles(ci, Vector2(cx, y1), 16.0, t, 4, 0.7 * a, w)
