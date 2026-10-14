class_name RoomArt
extends RefCounted
## Dibujo de la habitación según el estilo (Catalog.STANDS / THEMES): mueble, atrezo sobre el mueble,
## cuadro de la pared, guirnalda y nieve. Lo usan la escena principal y las miniaturas de la tienda.

const XMAS_BULBS := [Color("ff4d4d"), Color("ffd23f"), Color("4dd2ff"), Color("7dff7a"), Color("ff8ad8")]


static func _c(hex: String) -> Color:
	return Catalog.color(hex)


## Papel pintado de la pared (room.gdshader) según Catalog.WALLS.
static func apply_wall(m: ShaderMaterial, id: String) -> void:
	var w: Dictionary = Catalog.WALLS.get(id, Catalog.WALLS.clasica)
	m.set_shader_parameter("wall_top", Catalog.color(w.cols[0]))
	m.set_shader_parameter("wall_low", Catalog.color(w.cols[1]))
	m.set_shader_parameter("wall_acc", Catalog.color(w.cols[2]))
	m.set_shader_parameter("pat", int(w.pat))


## Fondo trasero de la pecera (water.gdshader) según Catalog.BACKDROPS.
static func apply_backdrop(m: ShaderMaterial, id: String) -> void:
	var b: Dictionary = Catalog.BACKDROPS.get(id, Catalog.BACKDROPS.agua)
	m.set_shader_parameter("bg", int(b.bg))
	m.set_shader_parameter("bg_a", Catalog.color(b.cols[0]))
	m.set_shader_parameter("bg_b", Catalog.color(b.cols[1]))


# ───────────────────────── Mueble ─────────────────────────

## Mueble bajo la pecera: encimera en top_y y cuerpo hasta bottom_y.
static func stand(ci: CanvasItem, x0: float, x1: float, top_y: float, bottom_y: float, id: String) -> void:
	var s: Dictionary = Catalog.STANDS.get(id, Catalog.STANDS.roble)
	var top_c := _c(s.cols[0])
	var body_c := _c(s.cols[1])
	var door_c := _c(s.cols[2])
	var acc := _c(s.cols[3])
	ci.draw_rect(Rect2(x0, top_y + 6, x1 - x0, bottom_y - top_y), Color(0, 0, 0, 0.25))
	var plank := Rect2(x0 - 10, top_y, x1 - x0 + 20, 22)
	var body := Rect2(x0, plank.end.y, x1 - x0, bottom_y - plank.end.y)
	var cols := 2 if body.size.x < 600 else 3
	match int(s.kind):
		1:
			# Industrial: estructura de metal abierta, balda baja con cajas.
			ci.draw_rect(body, Color(0, 0, 0, 0.22))
			var shelf_y := body.position.y + minf(150.0, body.size.y * 0.5)
			for lx in [body.position.x + 4.0, body.end.x - 18.0, body.get_center().x - 7.0]:
				ci.draw_rect(Rect2(lx, body.position.y, 14, body.size.y), body_c)
				ci.draw_rect(Rect2(lx + 2, body.position.y, 3, body.size.y), door_c.lightened(0.25))
			ci.draw_rect(Rect2(body.position.x, body.position.y, body.size.x, 10), body_c)
			ci.draw_rect(Rect2(body.position.x, shelf_y, body.size.x, 16), top_c.darkened(0.1))
			ci.draw_rect(Rect2(body.position.x, shelf_y + 12, body.size.x, 4), top_c.darkened(0.35))
			for i in 3:
				var bw := 70.0 + i * 12.0
				var bx := body.position.x + 40.0 + i * (body.size.x - 120.0) / 2.0 - bw * 0.5 + 30.0
				var box := Rect2(bx, shelf_y - 54 + i * 6, bw, 54 - i * 6)
				ci.draw_rect(box, [Color("c9a27a"), Color("8fb3a0"), Color("d8c7a6")][i])
				ci.draw_rect(Rect2(box.position + Vector2(bw * 0.35, 8), Vector2(bw * 0.3, 8)), Color(0, 0, 0, 0.2))
			for k in 2:
				var sx := body.position.x + 20.0 + k * (body.size.x - 40.0)
				ci.draw_line(Vector2(sx, body.position.y + 10), Vector2(body.get_center().x, shelf_y), Color(acc, 0.5), 3.0)
		2:
			# Cajones: filas de cajones con tirador.
			ci.draw_rect(body, body_c)
			var cw := (body.size.x - 28.0) / cols
			for i in cols:
				for r in 4:
					var d := Rect2(body.position.x + 14 + i * cw + 6, body.position.y + 14 + r * 78.0, cw - 12, 70)
					if d.position.y > bottom_y:
						break
					ci.draw_rect(d, door_c)
					ci.draw_rect(d, body_c.darkened(0.25), false, 3.0)
					ci.draw_rect(Rect2(d.get_center().x - 26, d.position.y + 30, 52, 9), acc)
					ci.draw_rect(Rect2(d.get_center().x - 26, d.position.y + 30, 52, 3), acc.lightened(0.35))
		3:
			# Bambú: cañas verticales con nudos.
			ci.draw_rect(body, body_c)
			var n := int(body.size.x / 22.0)
			for i in n:
				var bx := body.position.x + 4.0 + i * body.size.x / n
				var w := body.size.x / n - 4.0
				var cane := door_c.darkened(0.08 * (i % 2))
				ci.draw_rect(Rect2(bx, body.position.y, w, body.size.y), cane)
				ci.draw_rect(Rect2(bx + w * 0.2, body.position.y, w * 0.18, body.size.y), cane.lightened(0.2))
				var k := 0
				while body.position.y + 40.0 + k * 92.0 + (i % 3) * 18.0 < bottom_y:
					var ny := body.position.y + 40.0 + k * 92.0 + (i % 3) * 18.0
					ci.draw_rect(Rect2(bx - 1, ny, w + 2, 5), acc)
					k += 1
		_:
			ci.draw_rect(body, body_c)
			for k in 12:
				var y := body.position.y + 12 + k * 23
				ci.draw_line(Vector2(body.position.x, y), Vector2(body.end.x, y + 4), Color(0, 0, 0, 0.06), 2.0)
			var dw := (body.size.x - 28.0) / cols
			for i in cols:
				var d := Rect2(body.position.x + 14 + i * dw + 6, body.position.y + 16, dw - 12, body.size.y - 10)
				ci.draw_rect(d, door_c)
				ci.draw_rect(d.grow(-14), door_c.lightened(0.05))
				ci.draw_rect(d.grow(-14), body_c.darkened(0.15), false, 2.0)
				ci.draw_rect(d, body_c.darkened(0.25), false, 3.0)
				ci.draw_circle(Vector2(d.end.x - 22 if i % 2 == 0 else d.position.x + 22, d.position.y + 44), 7, acc)
	ci.draw_rect(plank, top_c)
	ci.draw_rect(Rect2(plank.position, Vector2(plank.size.x, 4)), top_c.lightened(0.18))
	ci.draw_rect(Rect2(plank.position.x, plank.end.y - 6, plank.size.x, 6), top_c.darkened(0.22))


# ───────────────────────── Atrezo sobre el mueble ─────────────────────────

## Objetos a los lados de la pecera, sobre la encimera (lx/rx: centros de cada hueco).
static func side_props(ci: CanvasItem, amb: String, lx: float, rx: float, y: float) -> void:
	match amb:
		"navidad":
			for i in 3:
				var w := 52.0 - i * 10.0
				var b := Rect2(lx - w * 0.5 + i * 6.0, y - 34 - i * 30.0, w, 34 if i == 0 else 30)
				var col: Color = [Color("d6333d"), Color("2a9a4a"), Color("f2c14e")][i]
				ci.draw_rect(b, col)
				ci.draw_rect(Rect2(b.get_center().x - 3, b.position.y, 6, b.size.y), Color.WHITE if i != 2 else Color("d6333d"))
				ci.draw_rect(Rect2(b.position.x, b.get_center().y - 3, b.size.x, 6), Color.WHITE if i != 2 else Color("d6333d"))
			# Abeto con bolas y estrella.
			ci.draw_rect(Rect2(rx - 7, y - 16, 14, 16), Color("6b4428"))
			for k in 3:
				var w := 52.0 - k * 13.0
				var by := y - 14.0 - k * 26.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(rx - w, by), Vector2(rx + w, by), Vector2(rx, by - 40)]), Color("1f7a3f").lightened(k * 0.06))
			for k in 7:
				var p := Vector2(rx + sin(k * 2.4) * (36.0 - k * 4.0), y - 22.0 - k * 10.0)
				ci.draw_circle(p, 4.0, XMAS_BULBS[k % XMAS_BULBS.size()])
			_star(ci, Vector2(rx, y - 96), 11.0, Color("ffd23f"))
		"otono":
			for k in 2:
				var c := Vector2(lx - 14 + k * 30, y - 16 - k * 4)
				var r := 24.0 - k * 6.0
				ci.draw_colored_polygon(DecorArt.ell(c, r * 1.25, r * 0.8), Color("e07a2a").darkened(k * 0.1))
				for s in [-0.5, 0.5]:
					ci.draw_colored_polygon(DecorArt.ell(c + Vector2(r * s, 0), r * 0.45, r * 0.78), Color("f0913a").darkened(k * 0.1))
				ci.draw_rect(Rect2(c.x - 3, c.y - r * 0.8 - 8, 6, 10), Color("5a7a2a"))
			_candle(ci, Vector2(rx - 16, y), 22.0, Color("f3e3c3"))
			_candle(ci, Vector2(rx + 14, y), 34.0, Color("f3e3c3"))
			for k in 4:
				DecorArt.leaf(ci, Vector2(rx - 40 + k * 22, y - 2), 1.4 + k * 0.6, 18.0, 10.0, Color("c2492a"), Color("f2b33d"), 0.0)
		"halloween":
			var c := Vector2(lx, y - 26)
			ci.draw_colored_polygon(DecorArt.ell(c, 34, 25), Color("ef7a1a"))
			for s in [-0.55, 0.55]:
				ci.draw_colored_polygon(DecorArt.ell(c + Vector2(34 * s, 0), 14, 24), Color("f99236"))
			ci.draw_rect(Rect2(c.x - 4, c.y - 34, 8, 12), Color("4a6a24"))
			var glow := Color("ffe27a")
			for s in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(12 * s - 7, -4), c + Vector2(12 * s + 7, -4), c + Vector2(12 * s, -14)]), glow)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-16, 6), c + Vector2(16, 6), c + Vector2(10, 14), c + Vector2(4, 9),
				c + Vector2(-2, 15), c + Vector2(-8, 9), c + Vector2(-13, 14)]), glow)
			for k in 3:
				_candle(ci, Vector2(rx - 22 + k * 22, y), 20.0 + (k % 2) * 16.0, Color("efe6d8"))
		"primavera":
			# Jarrón con tulipanes y una pila de libros con taza.
			var vb := Vector2(rx, y)
			for k in 5:
				var a := -0.5 + k * 0.25
				var tip := vb + Vector2(sin(a) * 50.0, -66.0 - absf(k - 2) * -6.0)
				ci.draw_line(vb + Vector2(0, -30), tip, Color("4c9a4a"), 3.0)
				ci.draw_colored_polygon(DecorArt.ell(tip, 8, 11), [Color("ff6fa8"), Color("ffd23f"), Color("ff8a5b"), Color("ffffff"), Color("c86bff")][k])
			ci.draw_colored_polygon(PackedVector2Array([vb + Vector2(-18, -40), vb + Vector2(18, -40), vb + Vector2(24, 0), vb + Vector2(-24, 0)]), Color("9fd3e6"))
			ci.draw_rect(Rect2(vb.x - 18, vb.y - 40, 36, 5), Color(1, 1, 1, 0.5))
			for k in 2:
				ci.draw_rect(Rect2(lx - 34 + k * 4, y - 14 - k * 14, 66 - k * 8, 14), [Color("f4a7b9"), Color("a8dccf")][k])
			ci.draw_rect(Rect2(lx - 8, y - 46, 22, 18), Color.WHITE)
			ci.draw_arc(Vector2(lx + 17, y - 38), 6, -PI * 0.5, PI * 0.5, 8, Color.WHITE, 3.0)
		"zen":
			for k in 4:
				var r := 26.0 - k * 5.0
				ci.draw_colored_polygon(DecorArt.ell(Vector2(lx + (k % 2) * 4.0, y - 10 - k * 17.0), r, 9 - k * 0.8), Color("7d8a8a").lightened(k * 0.08))
			# Bonsái en maceta plana.
			ci.draw_rect(Rect2(rx - 34, y - 14, 68, 14), Color("5a4a6a"))
			ci.draw_rect(Rect2(rx - 38, y - 18, 76, 6), Color("6b5a7a"))
			ci.draw_line(Vector2(rx, y - 16), Vector2(rx - 6, y - 44), Color("5a3a22"), 7.0)
			ci.draw_line(Vector2(rx - 6, y - 44), Vector2(rx + 18, y - 64), Color("5a3a22"), 5.0)
			ci.draw_line(Vector2(rx - 6, y - 44), Vector2(rx - 26, y - 58), Color("5a3a22"), 4.0)
			for c in [Vector2(rx + 22, y - 70), Vector2(rx - 28, y - 64), Vector2(rx - 4, y - 80), Vector2(rx + 8, y - 60)]:
				ci.draw_colored_polygon(DecorArt.ell(c, 20, 11), Color("3f7a3a"))
				ci.draw_colored_polygon(DecorArt.ell(c + Vector2(-3, -3), 13, 6), Color("5f9a4a"))
		"playa":
			# Estrella de mar y concha; tarro con arena y conchitas.
			_star(ci, Vector2(lx - 12, y - 8), 16.0, Color("ff8a5b"), 0.45)
			var sc := Vector2(lx + 22, y - 12)
			ci.draw_colored_polygon(DecorArt.ell(sc, 16, 12), Color("f6e3cf"))
			for k in 5:
				ci.draw_line(sc + Vector2(0, 10), sc + Vector2(-12 + k * 6, -10), Color("d9b99a"), 2.0)
			var j := Rect2(rx - 22, y - 58, 44, 58)
			ci.draw_rect(j, Color(0.85, 0.95, 1.0, 0.35))
			ci.draw_rect(Rect2(j.position.x, j.end.y - 22, j.size.x, 22), Color("e8d39a"))
			for k in 3:
				ci.draw_circle(Vector2(j.position.x + 10 + k * 12, j.end.y - 24), 4, [Color("ff9ab0"), Color("fff0d8"), Color("ffcf7a")][k])
			ci.draw_rect(Rect2(j.position.x - 2, j.position.y - 6, j.size.x + 4, 8), Color("b07a4f"))
			ci.draw_rect(j, Color(1, 1, 1, 0.7), false, 2.0)
		_:
			for k in 3:
				var bw := 68.0 - k * 8.0
				ci.draw_rect(Rect2(lx - bw * 0.5 + k * 3, y - 16 - k * 16, bw, 16), [Color("e76f51"), Color("2a9d8f"), Color("e9c46a")][k])
				ci.draw_rect(Rect2(lx - bw * 0.5 + k * 3, y - 10 - k * 16, bw, 2), Color(1, 1, 1, 0.5))
			var pot := PackedVector2Array([Vector2(rx - 24, y - 44), Vector2(rx + 24, y - 44), Vector2(rx + 17, y), Vector2(rx - 17, y)])
			for i in 7:
				DecorArt.leaf(ci, Vector2(rx, y - 40), lerpf(-1.1, 1.1, i / 6.0), 52.0 - absf(i - 3) * 6.0, 18.0, Color("2e7d4f"), Color("6fcf8a"), 0.12)
			ci.draw_colored_polygon(pot, Color("d9774e"))
			ci.draw_rect(Rect2(rx - 27, y - 50, 54, 10), Color("c4633d"))


static func _candle(ci: CanvasItem, base: Vector2, h: float, col: Color) -> void:
	ci.draw_rect(Rect2(base.x - 7, base.y - h, 14, h), col)
	ci.draw_rect(Rect2(base.x - 7, base.y - h, 4, h), col.lightened(0.3))
	ci.draw_circle(base + Vector2(0, -h - 14), 14, Color(1.0, 0.8, 0.3, 0.18))
	ci.draw_colored_polygon(DecorArt.ell(base + Vector2(0, -h - 8), 4, 8), Color("ffb02e"))
	ci.draw_colored_polygon(DecorArt.ell(base + Vector2(0, -h - 6), 2, 4), Color("fff3b0"))


static func _star(ci: CanvasItem, c: Vector2, r: float, col: Color, inner := 0.45) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + PI * i / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * inner))
	ci.draw_colored_polygon(pts, col)


# ───────────────────────── Pared: cuadro y guirnalda ─────────────────────────

## Cuadro de la pared (o corona, o pergamino) según el ambiente.
static func picture(ci: CanvasItem, fr: Rect2, amb: String) -> void:
	if amb == "navidad":
		# Corona de acebo con lazo.
		var c := fr.get_center()
		var r := minf(fr.size.x, fr.size.y) * 0.42
		for i in 22:
			var a := TAU * i / 22.0
			ci.draw_circle(c + Vector2(cos(a), sin(a)) * r, 13, Color("1f6b3a").lightened((i % 3) * 0.07))
		for i in 8:
			var a := TAU * i / 8.0 + 0.3
			ci.draw_circle(c + Vector2(cos(a), sin(a)) * (r + 4), 4.5, Color("e0303c"))
		var b := c + Vector2(0, r)
		ci.draw_colored_polygon(PackedVector2Array([b, b + Vector2(-24, -12), b + Vector2(-24, 12)]), Color("d6333d"))
		ci.draw_colored_polygon(PackedVector2Array([b, b + Vector2(24, -12), b + Vector2(24, 12)]), Color("d6333d"))
		ci.draw_circle(b, 6, Color("b3242c"))
		return
	if amb == "zen":
		# Pergamino colgado con un ensō.
		var sr := Rect2(fr.position.x + fr.size.x * 0.22, fr.position.y - 6, fr.size.x * 0.56, fr.size.y + 30)
		ci.draw_rect(Rect2(sr.position + Vector2(4, 6), sr.size), Color(0, 0, 0, 0.15))
		ci.draw_rect(sr, Color("f4ecd8"))
		ci.draw_rect(Rect2(sr.position.x - 6, sr.position.y, sr.size.x + 12, 8), Color("5a3a22"))
		ci.draw_rect(Rect2(sr.position.x - 6, sr.end.y - 8, sr.size.x + 12, 8), Color("5a3a22"))
		ci.draw_arc(sr.get_center() + Vector2(0, -6), sr.size.x * 0.3, 0.4, TAU - 0.2, 32, Color("2a2a2a"), 5.0, true)
		ci.draw_circle(sr.get_center() + Vector2(sr.size.x * 0.22, sr.size.y * 0.32), 4, Color("c43a2a"))
		return
	ci.draw_rect(Rect2(fr.position + Vector2(5, 7), fr.size), Color(0, 0, 0, 0.18))
	var frame_c := Color("8a5a36")
	if amb == "halloween":
		frame_c = Color("2a1d35")
	elif amb == "primavera" or amb == "playa":
		frame_c = Color("f4efe6")
	ci.draw_rect(fr, frame_c)
	var mat := fr.grow(-10)
	ci.draw_rect(mat, Color("fff3df"))
	var art := mat.grow(-9)
	match amb:
		"otono":
			ci.draw_rect(art, Color("f6c98a"))
			ci.draw_rect(Rect2(art.position + Vector2(0, art.size.y * 0.78), Vector2(art.size.x, art.size.y * 0.22)), Color("b06a3a"))
			var t := art.position + Vector2(art.size.x * 0.5, art.size.y * 0.8)
			ci.draw_line(t, t + Vector2(0, -art.size.y * 0.4), Color("5a3519"), 5.0)
			for c in [Vector2(-14, -38), Vector2(12, -42), Vector2(0, -52), Vector2(-4, -30), Vector2(18, -30)]:
				ci.draw_circle(t + c, 13, [Color("e0602a"), Color("f2a33d"), Color("c2412a")][int(c.x + 40) % 3])
		"halloween":
			ci.draw_rect(art, Color("3a2458"))
			ci.draw_circle(art.position + Vector2(art.size.x * 0.68, art.size.y * 0.36), 18, Color("ffe9a8"))
			for k in 3:
				var b := art.position + Vector2(20 + k * 26, 22 + (k % 2) * 14)
				ci.draw_colored_polygon(PackedVector2Array([b, b + Vector2(-9, -5), b + Vector2(-5, 2), b + Vector2(0, -1), b + Vector2(5, 2), b + Vector2(9, -5)]), Color("120a1e"))
			ci.draw_rect(Rect2(art.position + Vector2(0, art.size.y * 0.8), Vector2(art.size.x, art.size.y * 0.2)), Color("1a1028"))
		"primavera":
			ci.draw_rect(art, Color("e6f4fb"))
			ci.draw_line(art.position + Vector2(0, art.size.y * 0.3), art.end - Vector2(art.size.x * 0.2, art.size.y * 0.25), Color("5a3a2a"), 4.0)
			for k in 6:
				var p := art.position + Vector2(14 + k * 16, art.size.y * (0.32 + k * 0.06))
				_star(ci, p, 9.0, Color("ffb7cf"), 0.7)
				ci.draw_circle(p, 2.5, Color("e85a8a"))
		"playa":
			ci.draw_rect(art, Color("8fdcf2"))
			ci.draw_circle(art.position + Vector2(art.size.x * 0.75, art.size.y * 0.25), 12, Color("ffd23f"))
			ci.draw_rect(Rect2(art.position + Vector2(0, art.size.y * 0.55), Vector2(art.size.x, art.size.y * 0.2)), Color("2a8fc4"))
			ci.draw_rect(Rect2(art.position + Vector2(0, art.size.y * 0.75), Vector2(art.size.x, art.size.y * 0.25)), Color("f1d39a"))
			var pb := art.position + Vector2(art.size.x * 0.25, art.size.y * 0.85)
			ci.draw_line(pb, pb + Vector2(8, -46), Color("8a5a36"), 4.0)
			for a in [-2.4, -1.9, -1.2, -0.7]:
				DecorArt.leaf(ci, pb + Vector2(8, -46), a + PI * 0.5, 26.0, 8.0, Color("2e7d4f"), Color("6fcf8a"), 0.3)
		_:
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


## Guirnalda de lado a lado de la pared, bajo la barra superior. blink alterna las luces navideñas.
static func garland(ci: CanvasItem, x0: float, x1: float, y: float, amb: String, blink := 0) -> void:
	if amb == "" or amb == "zen":
		return
	var n := 13
	var sag := 16.0
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		pts.append(Vector2(lerpf(x0, x1, t), y + sag * (1.0 - pow(2.0 * fmod(t * 3.0, 1.0) - 1.0, 2.0))))
	match amb:
		"navidad":
			for i in range(0, 60):
				var t := i / 59.0
				var p := _along(pts, t)
				ci.draw_circle(p + Vector2(0, 2), 9.0, Color("1a5a32"))
				ci.draw_circle(p + Vector2(sin(i * 1.7) * 4.0, sin(i * 2.3) * 3.0), 7.0, Color("2a7a42"))
			for i in 18:
				var p := _along(pts, (i + 0.5) / 18.0) + Vector2(0, 9)
				var col: Color = XMAS_BULBS[(i + blink) % XMAS_BULBS.size()]
				var on := (i + blink) % 3 != 0
				ci.draw_circle(p + Vector2(0, 4), 10.0, Color(col, 0.25 if on else 0.0))
				ci.draw_colored_polygon(DecorArt.ell(p + Vector2(0, 4), 4.5, 6.5), col if on else col.darkened(0.45))
				ci.draw_rect(Rect2(p.x - 3, p.y - 3, 6, 4), Color("3a4046"))
		"otono":
			ci.draw_polyline(pts, Color("7a5a3a"), 2.0, true)
			for i in 16:
				var p := _along(pts, (i + 0.5) / 16.0)
				DecorArt.leaf(ci, p, PI + sin(i * 1.3) * 0.5, 22.0, 13.0, [Color("c2412a"), Color("e07a2a"), Color("d9a02a")][i % 3], Color("f2c46b"), 0.05)
		"primavera":
			ci.draw_polyline(pts, Color("7a9a5a"), 2.0, true)
			for i in 20:
				var p := _along(pts, (i + 0.5) / 20.0) + Vector2(0, 3)
				_star(ci, p, 9.0, Color("ffd0e0") if i % 2 == 0 else Color.WHITE, 0.72)
				ci.draw_circle(p, 3.0, Color("f28ab0"))
		_:
			# Banderines (Halloween y playa).
			ci.draw_polyline(pts, Color("f4efe6") if amb == "playa" else Color("2a1d35"), 2.0, true)
			var flags: Array = [Color("ff8a2a"), Color("2a1d35"), Color("8a4ad0")] if amb == "halloween" \
				else [Color("2a8fc4"), Color("ffffff"), Color("ff6a5a"), Color("ffd23f")]
			for i in 15:
				var a := _along(pts, i / 15.0 + 0.01)
				var b := _along(pts, (i + 1) / 15.0 - 0.01)
				var tip := (a + b) * 0.5 + Vector2(0, 26)
				ci.draw_colored_polygon(PackedVector2Array([a, b, tip]), flags[i % flags.size()])
				if amb == "halloween" and i % 3 == 1:
					var c := (a + b) * 0.5 + Vector2(0, 9)
					ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(-8, -4), c + Vector2(-4, 2), c + Vector2(0, 0), c + Vector2(4, 2), c + Vector2(8, -4)]), Color("ff8a2a"))


static func _along(pts: PackedVector2Array, t: float) -> Vector2:
	var f := clampf(t, 0.0, 1.0) * (pts.size() - 1)
	var i := mini(int(f), pts.size() - 2)
	return pts[i].lerp(pts[i + 1], f - i)


## Capa de nieve sobre un borde horizontal (balda, tapa, encimera).
static func snow(ci: CanvasItem, x0: float, x1: float, y: float) -> void:
	var pts := PackedVector2Array([Vector2(x0 - 2, y + 2)])
	var n := int((x1 - x0) / 14.0)
	for i in n + 1:
		var x := lerpf(x0, x1, float(i) / n)
		pts.append(Vector2(x, y - 5.0 - 3.0 * absf(sin(i * 1.9)) - (2.0 if i % 4 == 0 else 0.0)))
	pts.append(Vector2(x1 + 2, y + 2))
	ci.draw_colored_polygon(pts, Color("f6fbff"))
	for i in int(n / 3.0):
		var x := x0 + 10.0 + i * 42.0
		if x < x1 - 6.0:
			ci.draw_colored_polygon(DecorArt.ell(Vector2(x, y + 3), 4, 6), Color("f6fbff"))
