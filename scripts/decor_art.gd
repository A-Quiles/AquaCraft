class_name DecorArt
extends RefCounted
## Dibujo procedural de plantas y adornos. Origen = centro de la base, hacia arriba es -y.
## `u` escala todo (1.0 ≈ pecera de 520 px de alto). Las plantas usan sway.gdshader.

const BOUNDS := {
	"vallisneria": Rect2(-75, -235, 150, 238), "helecho": Rect2(-120, -135, 240, 140),
	"anubias": Rect2(-90, -85, 180, 90), "rotala": Rect2(-65, -205, 130, 208),
	"musgo": Rect2(-55, -52, 110, 55), "planta_rosa": Rect2(-65, -160, 130, 163),
	"rocas": Rect2(-72, -64, 144, 67), "tronco": Rect2(-75, -150, 150, 155),
	"cueva": Rect2(-88, -66, 176, 69), "castillo": Rect2(-70, -192, 140, 195),
	"anfora": Rect2(-62, -64, 124, 67), "barco": Rect2(-125, -190, 250, 195),
	"cofre": Rect2(-42, -72, 84, 75), "coral": Rect2(-85, -155, 170, 158),
	"caulerpa": Rect2(-55, -125, 110, 128), "anemona": Rect2(-70, -105, 140, 108),
	"coral_blando": Rect2(-60, -120, 120, 123), "roca_viva": Rect2(-80, -78, 160, 81),
	"coral_cerebro": Rect2(-62, -66, 124, 69),
	"calabaza": Rect2(-62, -98, 124, 101), "arbol_coral": Rect2(-62, -175, 124, 178),
	"cerezo": Rect2(-85, -150, 170, 153), "castillo_arena": Rect2(-78, -150, 156, 153),
}


static func draw(ci: CanvasItem, id: String, u: float, sd: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	match id:
		"vallisneria": _vallisneria(ci, u, rng)
		"helecho": _helecho(ci, u, rng)
		"anubias": _anubias(ci, u, rng)
		"rotala": _rotala(ci, u, rng)
		"musgo": _musgo(ci, u, rng)
		"planta_rosa": _planta_rosa(ci, u, rng)
		"rocas": _rocas(ci, u, rng)
		"tronco": _tronco(ci, u, rng)
		"cueva": _cueva(ci, u, rng)
		"castillo": _castillo(ci, u, rng)
		"anfora": _anfora(ci, u, rng)
		"barco": _barco(ci, u, rng)
		"cofre": _cofre(ci, u, rng)
		"coral": _coral(ci, u, rng)
		"caulerpa": _caulerpa(ci, u, rng)
		"anemona": _anemona(ci, u, rng)
		"coral_blando": _coral_blando(ci, u, rng)
		"roca_viva": _roca_viva(ci, u, rng)
		"coral_cerebro": _coral_cerebro(ci, u, rng)
		"calabaza": _calabaza(ci, u, rng)
		"arbol_coral": _arbol_coral(ci, u, rng)
		"cerezo": _cerezo(ci, u, rng)
		"castillo_arena": _castillo_arena(ci, u, rng)


# ───────────────────────── Plantas ─────────────────────────

static func _vallisneria(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	for i in 12:
		var dark := rng.randf()
		var c0 := Color(0.08, 0.28, 0.15).lerp(Color(0.05, 0.2, 0.12), dark)
		var c1 := Color(0.45, 0.8, 0.4).lerp(Color(0.62, 0.82, 0.3), rng.randf() * 0.6).darkened(dark * 0.3)
		blade(ci, Vector2(rng.randf_range(-40, 40) * u, 0), rng.randf_range(130, 228) * u,
			rng.randf_range(7, 10.5) * u, rng.randf_range(-38, 38) * u, c0, c1, 12)


static func _helecho(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	ci.draw_colored_polygon(ell(Vector2(0, -4 * u), 22 * u, 7 * u), Color(0.32, 0.24, 0.16))
	for i in 9:
		var a := lerpf(-1.15, 1.15, i / 8.0) + rng.randf_range(-0.12, 0.12)
		leaf(ci, Vector2(rng.randf_range(-14, 14) * u, -6 * u), a, rng.randf_range(85, 135) * u,
			rng.randf_range(16, 24) * u, Color(0.08, 0.27, 0.14), Color(0.3, 0.6, 0.28).lerp(Color(0.4, 0.62, 0.22), rng.randf()), 0.18)


static func _anubias(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	limb(ci, [Vector2(-38, -6) * u, Vector2(0, -9) * u, Vector2(38, -5) * u], [9.0 * u, 10.0 * u, 7.0 * u],
		Color(0.42, 0.5, 0.25), Color(0.25, 0.3, 0.15))
	for i in 7:
		var bx := lerpf(-32, 32, i / 6.0) * u
		var a := lerpf(-1.0, 1.0, i / 6.0) + rng.randf_range(-0.2, 0.2)
		var stem := rng.randf_range(14, 26) * u
		var tip := Vector2(bx, -8 * u) + Vector2(sin(a), -cos(a)) * stem
		ci.draw_line(Vector2(bx, -8 * u), tip, Color(0.16, 0.36, 0.18), 3.0 * u, true)
		leaf(ci, tip, a * 1.15, rng.randf_range(48, 64) * u, rng.randf_range(30, 38) * u,
			Color(0.05, 0.24, 0.14), Color(0.2, 0.5, 0.3), 0.08, 0.95)


static func _rotala(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	for s in 6:
		var base := Vector2(rng.randf_range(-30, 30) * u, 0)
		var h := rng.randf_range(120, 195) * u
		var bend := rng.randf_range(-20, 20) * u
		var pts := PackedVector2Array()
		for i in 13:
			var t := i / 12.0
			pts.append(base + Vector2(bend * t * t, -h * t))
		var green := Color(0.32, 0.6, 0.26)
		var red := Color(0.95, 0.36, 0.32).lerp(Color(1.0, 0.55, 0.35), rng.randf())
		ci.draw_polyline(pts, green.lerp(red, 0.5).darkened(0.35), 2.2 * u, true)
		var n := int(h / (9.0 * u))
		for i in n:
			var t := float(i + 1) / (n + 1)
			var p := base + Vector2(bend * t * t, -h * t)
			var c := green.lerp(red, smoothstep(0.15, 0.85, t))
			for side in [-1.0, 1.0]:
				leaf(ci, p, side * (1.0 - t * 0.35) + rng.randf_range(-0.15, 0.15), (13.0 - t * 4.0) * u, 5.5 * u,
					c.darkened(0.25), c.lightened(0.15), 0.0, 1.0, 4)


static func _musgo(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	for b in [[-24.0, 20.0], [20.0, 24.0], [-2.0, 15.0]]:
		var c := Vector2(b[0] * u, -b[1] * 0.92 * u)
		var r: float = b[1] * u
		var pts := PackedVector2Array()
		for i in 56:
			var a := TAU * i / 56.0
			pts.append(c + Vector2(cos(a), sin(a)) * r * (1.0 + rng.randf_range(-0.07, 0.07)))
		ci.draw_polygon(pts, vgrad(pts, Color(0.44, 0.72, 0.32), Color(0.12, 0.32, 0.15)))
		var hi := PackedVector2Array()
		for i in 32:
			var a := TAU * i / 32.0
			hi.append(c + Vector2(-0.28, -0.32) * r + Vector2(cos(a), sin(a)) * r * 0.5 * (1.0 + rng.randf_range(-0.1, 0.1)))
		ci.draw_colored_polygon(hi, Color(0.7, 0.92, 0.5, 0.28))
		for i in 18:
			var a := rng.randf() * TAU
			ci.draw_circle(c + Vector2(cos(a), sin(a)) * r * rng.randf_range(0.6, 1.02), 1.6 * u, Color(0.55, 0.8, 0.38, 0.6))


static func _planta_rosa(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	ci.draw_colored_polygon(ell(Vector2(0, -3 * u), 26 * u, 6 * u), Color(0.55, 0.55, 0.6))
	for s in 4:
		var base := Vector2(rng.randf_range(-14, 14) * u, -4 * u)
		var h := rng.randf_range(95, 150) * u
		var bend := rng.randf_range(-45, 45) * u
		var pts := PackedVector2Array()
		for i in 11:
			var t := i / 10.0
			pts.append(base + Vector2(bend * t * t, -h * t))
		ci.draw_polyline(pts, Color(0.72, 0.18, 0.48), 3.0 * u, true)
		for i in range(2, 11):
			var t := i / 10.0
			var side := -1.0 if i % 2 == 0 else 1.0
			var c := Color(1.0, 0.4, 0.66).lerp(Color(1.0, 0.72, 0.86), t)
			leaf(ci, pts[i], side * 0.9 + bend / h * 0.8, (26.0 - t * 8.0) * u, 13.0 * u, c.darkened(0.15), c, 0.05, 1.0, 6)


# ───────────────────────── Adornos ─────────────────────────

static func _rocas(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var stones := [[-36.0, 30.0, 21.0], [10.0, 44.0, 31.0], [44.0, 19.0, 13.0]]
	for i in stones.size():
		var s: Array = stones[i]
		var tone := Color(0.46, 0.5, 0.55).lerp(Color(0.55, 0.48, 0.42), rng.randf())
		stone(ci, Vector2(s[0] * u, -s[2] * 0.9 * u), s[1] * u, s[2] * u, tone, rng)
	for i in 5:
		ci.draw_circle(Vector2(rng.randf_range(-10, 30) * u, -rng.randf_range(48, 56) * u), rng.randf_range(3, 6) * u, Color(0.32, 0.55, 0.26, 0.85))


static func _tronco(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var light := Color(0.62, 0.45, 0.3)
	var dark := Color(0.28, 0.17, 0.1)
	var main := [Vector2(-34, 0), Vector2(-12, -42), Vector2(14, -88), Vector2(34, -140)]
	for i in main.size():
		main[i] *= u
	limb(ci, [main[0], Vector2(-62, 2) * u], [14.0 * u, 4.0 * u], light, dark)
	limb(ci, [main[0], Vector2(22, 3) * u], [12.0 * u, 4.0 * u], light, dark)
	limb(ci, [main[1], Vector2(-46, -98) * u, Vector2(-58, -118) * u], [12.0 * u, 6.0 * u, 3.0 * u], light, dark)
	limb(ci, [main[2], Vector2(56, -106) * u, Vector2(70, -104) * u], [9.0 * u, 4.0 * u, 2.0 * u], light, dark)
	limb(ci, main, [26.0 * u, 20.0 * u, 13.0 * u, 6.0 * u], light, dark)
	for k in 3:
		var pts := PackedVector2Array()
		for i in main.size():
			pts.append(main[i] + Vector2(-6 + k * 5, 0) * u * (1.0 - i / 4.0))
		ci.draw_polyline(pts, Color(0.22, 0.13, 0.08, 0.45), 1.2 * u, true)


static func _cueva(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var x := lerpf(-84, 84, i / 32.0)
		var y := -60.0 * pow(maxf(0.0, 1.0 - pow(x / 84.0, 2.0)), 0.75) + rng.randf_range(-3, 3)
		pts.append(Vector2(x, minf(y, 0.0)) * u)
	ci.draw_polygon(pts, vgrad(pts, Color(0.66, 0.62, 0.56), Color(0.3, 0.28, 0.26)))
	for i in 7:
		var c := Vector2(rng.randf_range(-60, 60), rng.randf_range(-48, -14)) * u
		var tone := Color(0.6, 0.57, 0.52).lerp(Color(0.42, 0.4, 0.38), rng.randf())
		tone.a = 0.7
		ci.draw_colored_polygon(ell(c, rng.randf_range(10, 18) * u, rng.randf_range(7, 11) * u), tone)
	var arch := PackedVector2Array()
	for i in 21:
		var a := PI + PI * i / 20.0
		arch.append(Vector2(6 + cos(a) * 28, sin(a) * 26) * u)
	ci.draw_polygon(arch, vgrad(arch, Color(0.12, 0.1, 0.1), Color(0.02, 0.02, 0.03)))
	for i in 6:
		ci.draw_circle(Vector2(rng.randf_range(-50, 40), -rng.randf_range(44, 58)) * u, rng.randf_range(4, 7) * u, Color(0.3, 0.55, 0.25, 0.85))


static func _castillo(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var sand := Color(0.9, 0.8, 0.64)
	var shade := Color(0.66, 0.56, 0.44)
	var dark := Color(0.16, 0.13, 0.14)
	# Muralla y torres laterales con tejado
	block(ci, Rect2(-34, -72, 68, 72), u, sand, shade)
	for side in [-1.0, 1.0]:
		var x0: float = -62.0 if side < 0 else 30.0
		block(ci, Rect2(x0, -112, 32, 112), u, sand, shade)
		var roof := PackedVector2Array([Vector2(x0 - 5, -112) * u, Vector2(x0 + 37, -112) * u, Vector2(x0 + 16, -160) * u])
		ci.draw_polygon(roof, PackedColorArray([Color(0.35, 0.62, 0.78), Color(0.18, 0.38, 0.55), Color(0.5, 0.78, 0.9)]))
		window(ci, Vector2(x0 + 16, -80) * u, 6 * u, 10 * u, dark)
	# Torre central con almenas
	block(ci, Rect2(-24, -150, 48, 150), u, sand, shade)
	for i in 4:
		block(ci, Rect2(-24 + i * 13.5, -162, 8, 12), u, sand, shade)
	window(ci, Vector2(0, -116) * u, 7 * u, 12 * u, Color(0.95, 0.78, 0.42))
	window(ci, Vector2(0, 0) * u, 13 * u, 30 * u, dark)
	for i in 6:
		ci.draw_line(Vector2(-24, -20 - i * 21) * u, Vector2(24, -20 - i * 21) * u, Color(0.5, 0.4, 0.3, 0.25), 1.2 * u, true)
	for i in 9:
		ci.draw_circle(Vector2(rng.randf_range(-62, 62), -rng.randf_range(0, 14)) * u, rng.randf_range(4, 8) * u, Color(0.28, 0.52, 0.24, 0.9))


static func _anfora(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var xf := Transform2D(-0.32, Vector2(0, -28 * u))
	var body := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		var w := 46.0 * (1.0 - 0.18 * maxf(0.0, cos(a)))
		body.append(xf * (Vector2(cos(a) * w - 6, sin(a) * 25) * u))
	var neck := PackedVector2Array([xf * (Vector2(34, -11) * u), xf * (Vector2(58, -8) * u), xf * (Vector2(58, 8) * u), xf * (Vector2(34, 11) * u)])
	var terra := Color(0.84, 0.47, 0.3)
	var deep := Color(0.48, 0.22, 0.13)
	ci.draw_polygon(neck, vgrad(neck, terra, deep))
	for side in [-1.0, 1.0]:
		var arc := PackedVector2Array()
		for i in 9:
			var a := PI * i / 8.0
			arc.append(xf * (Vector2(30 + cos(a) * 9, side * (12 + sin(a) * 9)) * u))
		ci.draw_polyline(arc, deep, 4.0 * u, true)
	ci.draw_polygon(body, vgrad(body, terra, deep))
	var band := PackedVector2Array()
	for i in 15:
		band.append(xf * (Vector2(-36 + i * 5, -3 + (4 if i % 2 == 0 else -4)) * u))
	ci.draw_polyline(band, Color(0.2, 0.1, 0.08, 0.85), 2.0 * u, true)
	ci.draw_colored_polygon(PackedVector2Array([xf * (Vector2(-20, -18) * u), xf * (Vector2(10, -21) * u), xf * (Vector2(4, -15) * u)]), Color(1, 0.85, 0.7, 0.35))
	ci.draw_colored_polygon(ell(xf * (Vector2(59, 0) * u), 4 * u, 10 * u, 16, -0.32), Color(0.12, 0.06, 0.05))


static func _barco(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var xf := Transform2D(-0.14, Vector2(0, 0))
	var hull := PackedVector2Array()
	for p in [Vector2(-104, -60), Vector2(-40, -66), Vector2(40, -72), Vector2(102, -84), Vector2(116, -80),
			Vector2(100, -46), Vector2(70, -14), Vector2(20, -4), Vector2(-60, -6), Vector2(-96, -18), Vector2(-108, -40)]:
		hull.append(xf * (p * u))
	# Mástil roto y vela rasgada (detrás del casco)
	var mast_a := xf * (Vector2(-14, -66) * u)
	var mast_b := xf * (Vector2(-2, -182) * u)
	ci.draw_line(mast_a, mast_b, Color(0.32, 0.2, 0.12), 8.0 * u, true)
	ci.draw_line(xf * (Vector2(-46, -158) * u), xf * (Vector2(38, -164) * u), Color(0.32, 0.2, 0.12), 5.0 * u, true)
	var sail := PackedVector2Array()
	for p in [Vector2(-40, -156), Vector2(34, -161), Vector2(30, -120), Vector2(18, -112), Vector2(22, -96),
			Vector2(-4, -104), Vector2(-20, -92), Vector2(-26, -110), Vector2(-42, -104)]:
		sail.append(xf * (p * u))
	ci.draw_colored_polygon(sail, Color(0.88, 0.84, 0.72, 0.82))
	ci.draw_polygon(hull, vgrad(hull, Color(0.58, 0.4, 0.25), Color(0.22, 0.14, 0.09)))
	for k in 3:
		var pl := PackedVector2Array()
		for x in range(-100, 110, 20):
			var y := lerpf(-60, -80, (x + 100) / 210.0) + 15 + k * 14 + absf(x) * 0.02 * k
			pl.append(xf * (Vector2(x, y) * u))
		ci.draw_polyline(pl, Color(0.2, 0.12, 0.07, 0.6), 1.5 * u, true)
	var hole := PackedVector2Array()
	for p in [Vector2(14, -50), Vector2(30, -58), Vector2(46, -48), Vector2(40, -30), Vector2(24, -26), Vector2(18, -36)]:
		hole.append(xf * (p * u))
	ci.draw_colored_polygon(hole, Color(0.05, 0.04, 0.05))
	for x in [-70.0, -40.0, 72.0]:
		var c := xf * (Vector2(x, -44 + x * 0.06) * u)
		ci.draw_circle(c, 8.5 * u, Color(0.78, 0.64, 0.32))
		ci.draw_circle(c, 5.5 * u, Color(0.06, 0.12, 0.16))
	for i in 12:
		var p := xf * (Vector2(rng.randf_range(-90, 80), rng.randf_range(-24, -6)) * u)
		ci.draw_circle(p, rng.randf_range(4, 8) * u, Color(0.28, 0.5, 0.24, 0.9))
	for i in 10:
		ci.draw_circle(xf * (Vector2(rng.randf_range(-90, 90), rng.randf_range(-40, -14)) * u), 1.8 * u, Color(0.92, 0.9, 0.85, 0.8))


static func _cofre(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var wood := Color(0.6, 0.36, 0.18)
	var gold := Color(1.0, 0.8, 0.28)
	var lid := PackedVector2Array([Vector2(-32, -34) * u, Vector2(32, -34) * u, Vector2(26, -66) * u, Vector2(-30, -62) * u])
	ci.draw_polygon(lid, vgrad(lid, wood.darkened(0.15), wood.darkened(0.55)))
	ci.draw_circle(Vector2(0, -44) * u, 34 * u, Color(1.0, 0.85, 0.35, 0.16))
	for i in 16:
		var p := Vector2(rng.randf_range(-24, 24), -34 - rng.randf_range(0, 12) * (1.0 - absf(i - 8) / 10.0)) * u
		ci.draw_circle(p, 5.5 * u, Color(0.85, 0.6, 0.12))
		ci.draw_circle(p + Vector2(-0.8, -0.8) * u, 4.2 * u, Color(1.0, 0.86, 0.32))
	ci.draw_circle(Vector2(-10, -44) * u, 5 * u, Color(0.97, 0.95, 1.0))
	ci.draw_circle(Vector2(12, -46) * u, 6 * u, Color(0.3, 0.9, 0.95))
	var box := PackedVector2Array([Vector2(-34, -36) * u, Vector2(34, -36) * u, Vector2(34, 0) * u, Vector2(-34, 0) * u])
	ci.draw_polygon(box, vgrad(box, wood, wood.darkened(0.45)))
	for x in [-24.0, 24.0]:
		ci.draw_rect(Rect2(Vector2(x - 3.5, -36) * u, Vector2(7, 36) * u), gold.darkened(0.1))
	ci.draw_rect(Rect2(Vector2(-34, -38) * u, Vector2(68, 6) * u), gold)
	ci.draw_rect(Rect2(Vector2(-6, -30) * u, Vector2(12, 14) * u), gold)
	ci.draw_circle(Vector2(0, -23) * u, 2.4 * u, Color(0.2, 0.12, 0.05))


static func _coral(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	for a in [-0.55, -0.15, 0.25, 0.6]:
		_coral_branch(ci, Vector2(rng.randf_range(-12, 12) * u, 0), a + rng.randf_range(-0.1, 0.1), 52 * u, 13 * u, 3, rng)


static func _coral_branch(ci: CanvasItem, p: Vector2, a: float, l: float, w: float, depth: int, rng: RandomNumberGenerator) -> void:
	var e := p + Vector2(sin(a), -cos(a)) * l
	var t := 1.0 - depth / 3.0
	var c0 := Color(0.82, 0.28, 0.55).lerp(Color(1.0, 0.6, 0.78), t)
	var c1 := Color(0.9, 0.4, 0.62).lerp(Color(1.0, 0.78, 0.88), t)
	limb(ci, [p, e], [w, w * 0.72], c1, c0)
	if depth == 0:
		ci.draw_circle(e, w * 0.75, Color(1.0, 0.88, 0.94))
		ci.draw_circle(e, w * 1.6, Color(1.0, 0.7, 0.9, 0.18))
		return
	for s in [-1.0, 1.0]:
		_coral_branch(ci, e, a + s * rng.randf_range(0.3, 0.6), l * rng.randf_range(0.62, 0.78), w * 0.72, depth - 1, rng)


# ───────────────────────── Agua salada ─────────────────────────

static func _caulerpa(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	ci.draw_line(Vector2(-45, -3) * u, Vector2(45, -3) * u, Color(0.2, 0.45, 0.2), 3.0 * u, true)
	for s in 7:
		var base := Vector2(lerpf(-40, 40, s / 6.0) + rng.randf_range(-5, 5), -3) * u
		var h := rng.randf_range(55, 118) * u
		var bend := rng.randf_range(-14, 14) * u
		var n := int(h / (6.5 * u))
		for i in n:
			var t := float(i) / n
			var p := base + Vector2(bend * t * t, -h * t)
			var col := Color(0.18, 0.5, 0.22).lerp(Color(0.5, 0.86, 0.4), t)
			for side in [-1.0, 1.0]:
				ci.draw_circle(p + Vector2(side * 4.5 * u, 0), (3.6 - t * 1.2) * u, col)
			ci.draw_circle(p + Vector2(-1, -1) * u, 1.2 * u, Color(0.8, 1.0, 0.7, 0.6))


static func _anemona(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var col := PackedVector2Array([Vector2(-26, 0) * u, Vector2(26, 0) * u, Vector2(22, -26) * u, Vector2(-22, -26) * u])
	ci.draw_polygon(col, DecorArt.vgrad(col, Color(0.85, 0.45, 0.4), Color(0.55, 0.25, 0.22)))
	for i in 24:
		var a := lerpf(-1.25, 1.25, i / 23.0) + rng.randf_range(-0.08, 0.08)
		var base := Vector2(lerpf(-20, 20, i / 23.0), -24) * u
		var l := rng.randf_range(50, 78) * u * (1.0 - absf(a) * 0.25)
		var tip := base + Vector2(sin(a), -cos(a)) * l
		var c0 := Color(0.45, 0.75, 0.4)
		var c1 := Color(1.0, 0.55, 0.75) if i % 3 != 0 else Color(0.95, 0.7, 0.85)
		blade(ci, base, l, 9.0 * u, sin(a) * l * 0.9, c0, c1, 8)
		ci.draw_circle(base + Vector2(sin(a) * l * 0.9, -l), 5.2 * u, c1.lightened(0.15))


static func _coral_blando(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var tone := Color(0.95, 0.72, 0.6).lerp(Color(0.85, 0.6, 0.9), rng.randf())
	for b in 5:
		var a := lerpf(-0.7, 0.7, b / 4.0) + rng.randf_range(-0.1, 0.1)
		var base := Vector2(rng.randf_range(-12, 12), 0) * u
		var mid := base + Vector2(sin(a) * 30, -45 - rng.randf_range(0, 15)) * u
		var tip := mid + Vector2(sin(a) * 25, -rng.randf_range(35, 60)) * u
		limb(ci, [base, mid, tip], [16.0 * u, 13.0 * u, 10.0 * u], tone.lightened(0.15), tone.darkened(0.25))
		for k in 14:
			var p := tip + Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 6)) * u
			ci.draw_circle(p, 3.2 * u, Color(1.0, 0.95, 0.85, 0.85))
			ci.draw_circle(p, 1.3 * u, tone.darkened(0.2))


static func _roca_viva(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	stone(ci, Vector2(-26, -30) * u, 50 * u, 32 * u, Color(0.62, 0.55, 0.5), rng)
	stone(ci, Vector2(30, -22) * u, 40 * u, 24 * u, Color(0.6, 0.52, 0.48), rng)
	stone(ci, Vector2(-4, -58) * u, 30 * u, 18 * u, Color(0.66, 0.58, 0.52), rng)
	for i in 14:
		var c := Vector2(rng.randf_range(-62, 60), -rng.randf_range(8, 70)) * u
		ci.draw_colored_polygon(ell(c, rng.randf_range(5, 13) * u, rng.randf_range(3, 7) * u, 12), Color(0.72, 0.38, 0.62, 0.75))
	for i in 18:
		ci.draw_circle(Vector2(rng.randf_range(-60, 58), -rng.randf_range(6, 66)) * u, rng.randf_range(1.5, 3.5) * u, Color(0.2, 0.15, 0.15, 0.55))


static func _coral_cerebro(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var dome := PackedVector2Array()
	for i in 33:
		var a := PI + PI * i / 32.0
		dome.append(Vector2(cos(a) * 60, sin(a) * 62 + 2) * u)
	ci.draw_polygon(dome, vgrad(dome, Color(0.78, 0.86, 0.5), Color(0.45, 0.52, 0.3)))
	for k in 7:
		var r := 8.0 + k * 7.5
		var pts := PackedVector2Array()
		for i in 41:
			var a := PI + PI * i / 40.0
			var w := r + 3.0 * sin(i * 0.9 + k * 1.7)
			pts.append(Vector2(cos(a) * w * 0.97, sin(a) * w + 2) * u)
		ci.draw_polyline(pts, Color(0.32, 0.4, 0.22, 0.75), 2.4 * u, true)
	ci.draw_colored_polygon(ell(Vector2(-20, -42) * u, 20 * u, 9 * u, 16), Color(1, 1, 0.9, 0.16))


# ───────────────────────── Utilidades de dibujo ─────────────────────────

## Hoja de hierba que se estrecha hacia la punta (muchos vértices para que ondule bien).
# ───────────────────────── Eventos de temporada ─────────────────────────

static func _calabaza(ci: CanvasItem, u: float, _rng: RandomNumberGenerator) -> void:
	var c := Vector2(0, -42) * u
	ci.draw_colored_polygon(ell(c + Vector2(0, 40) * u, 58 * u, 8 * u), Color(0, 0, 0, 0.2))
	for k in [-2, 2, -1, 1, 0]:
		var pts := ell(c + Vector2(k * 17, 0) * u, 26 * u, 42 * u)
		ci.draw_polygon(pts, vgrad(pts, Color("ffa23a"), Color("c8501a")))
	# Cara tallada con luz dentro.
	var glow := Color(1.0, 0.85, 0.3)
	for side in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(side * 22, -6) * u, c + Vector2(side * 8, -6) * u, c + Vector2(side * 15, -20) * u]), glow)
	var mouth := PackedVector2Array([c + Vector2(-28, 10) * u, c + Vector2(-14, 18) * u, c + Vector2(-7, 12) * u, c + Vector2(0, 20) * u,
		c + Vector2(7, 12) * u, c + Vector2(14, 18) * u, c + Vector2(28, 10) * u, c + Vector2(14, 28) * u, c + Vector2(-14, 28) * u])
	ci.draw_colored_polygon(mouth, glow)
	ci.draw_circle(c, 46 * u, Color(1.0, 0.7, 0.2, 0.08))
	limb(ci, [c + Vector2(0, -38) * u, c + Vector2(4, -52) * u, c + Vector2(12, -56) * u], [10 * u, 7 * u, 5 * u], Color("6aa84f"), Color("38761d"))


static func _arbol_coral(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	ci.draw_colored_polygon(ell(Vector2(0, -2) * u, 40 * u, 7 * u), Color(0, 0, 0, 0.2))
	block(ci, Rect2(-8, -26, 16, 26), u, Color("8a5a36"), Color("5e3a22"))
	for tier in 4:
		var y := -26.0 - tier * 34.0
		var w := 58.0 - tier * 13.0
		var pts := PackedVector2Array([Vector2(-w, y) * u, Vector2(w, y) * u, Vector2(0, y - 52) * u])
		ci.draw_polygon(pts, vgrad(pts, Color("bff0e0"), Color("2f8f6f")))
		for k in 7:
			ci.draw_circle(Vector2(rng.randf_range(-w, w) * 0.8, y - rng.randf_range(4, 26)) * u, 3.2 * u, Color(1, 1, 1, 0.9))
		for k in 5:
			var col: Color = [Color("ff4a4a"), Color("ffd23f"), Color("4cb8ff"), Color("ff7ad9")][rng.randi() % 4]
			var p := Vector2(rng.randf_range(-w, w) * 0.75, y - rng.randf_range(6, 30)) * u
			ci.draw_circle(p, 6 * u, Color(col, 0.25))
			ci.draw_circle(p, 3 * u, col)
	var top := Vector2(0, -26 - 3 * 34 - 54) * u
	var star := PackedVector2Array()
	for i in 10:
		star.append(top + Vector2.from_angle(-PI / 2 + i * PI / 5) * (13.0 if i % 2 == 0 else 5.5) * u)
	ci.draw_colored_polygon(star, Color("ffd23f"))


static func _cerezo(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	stone(ci, Vector2(0, -10) * u, 46 * u, 16 * u, Color("7a7a82"), rng)
	limb(ci, [Vector2(0, -16), Vector2(-10, -50), Vector2(8, -86), Vector2(-4, -116)].map(func(v): return v * u),
		[16 * u, 13 * u, 9 * u, 6 * u], Color("8a5a40"), Color("4e2f20"))
	limb(ci, [Vector2(-6, -60), Vector2(-40, -84), Vector2(-62, -96)].map(func(v): return v * u), [8 * u, 6 * u, 4 * u], Color("8a5a40"), Color("4e2f20"))
	limb(ci, [Vector2(4, -80), Vector2(40, -100), Vector2(60, -118)].map(func(v): return v * u), [7 * u, 5 * u, 3 * u], Color("8a5a40"), Color("4e2f20"))
	for cl in [Vector2(-58, -104), Vector2(-30, -94), Vector2(0, -126), Vector2(30, -110), Vector2(58, -124), Vector2(-12, -96)]:
		for k in 9:
			var p: Vector2 = (cl + Vector2(rng.randf_range(-20, 20), rng.randf_range(-14, 14))) * u
			var col := Color("ffb7d5").lerp(Color("ff8ab8"), rng.randf())
			ci.draw_circle(p, rng.randf_range(5, 9) * u, col)
			ci.draw_circle(p + Vector2(-1.5, -1.5) * u, 2.2 * u, Color(1, 1, 1, 0.7))
	for k in 6:
		ci.draw_circle(Vector2(rng.randf_range(-70, 70), rng.randf_range(-60, -12)) * u, 3 * u, Color("ffc6dd"))


static func _castillo_arena(ci: CanvasItem, u: float, rng: RandomNumberGenerator) -> void:
	var sand := Color("f0d29a")
	var dark := Color("c8a466")
	ci.draw_colored_polygon(ell(Vector2(0, -4) * u, 76 * u, 10 * u), dark)
	block(ci, Rect2(-62, -62, 124, 60), u, sand, dark)
	for x in [-62.0, 30.0]:
		block(ci, Rect2(x, -112, 32, 52), u, sand, dark)
		for k in 3:
			block(ci, Rect2(x + k * 12, -122, 8, 10), u, sand, dark)
	block(ci, Rect2(-16, -98, 32, 38), u, sand.lightened(0.05), dark)
	for k in 3:
		block(ci, Rect2(-16 + k * 12, -108, 8, 10), u, sand, dark)
	window(ci, Vector2(0, -2) * u, 12 * u, 34 * u, Color("8a6a3a"))
	ci.draw_line(Vector2(0, -108) * u, Vector2(0, -146) * u, Color("6b4428"), 2.5 * u, true)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -146) * u, Vector2(26, -139) * u, Vector2(0, -132) * u]), Color("ff4a4a"))
	for k in 18:
		ci.draw_circle(Vector2(rng.randf_range(-60, 60), rng.randf_range(-110, -6)) * u, 1.4 * u, dark.darkened(0.2))
	for p in [Vector2(-48, -14), Vector2(44, -20)]:
		ci.draw_colored_polygon(ell(p * u, 7 * u, 5 * u), Color("ffd0e0"))
		for k in 4:
			ci.draw_line(p * u, (p + Vector2(-5 + k * 3.3, -5)) * u, Color("e8a0b8"), 1.2 * u, true)


static func blade(ci: CanvasItem, base: Vector2, h: float, w: float, bend: float, c0: Color, c1: Color, segs := 10) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var cl := PackedColorArray()
	var cr := PackedColorArray()
	for i in segs + 1:
		var t := float(i) / segs
		var c := base + Vector2(bend * t * t, -h * t)
		var nrm := Vector2(h, 2.0 * bend * t).normalized()
		var hw := w * 0.5 * (1.0 - t * 0.7) * (0.2 if i == segs else 1.0)
		left.append(c - nrm * hw)
		right.append(c + nrm * hw)
		var col := c0.lerp(c1, t)
		cl.append(col)
		cr.append(col.darkened(0.18))
	right.reverse()
	cr.reverse()
	ci.draw_polygon(left + right, cl + cr)


## Hoja lanceolada. a = ángulo desde la vertical. droop = cuánto cae la punta.
static func leaf(ci: CanvasItem, base: Vector2, a: float, l: float, w: float, c0: Color, c1: Color,
		droop := 0.15, roundness := 0.7, segs := 9) -> void:
	var dir := Vector2(sin(a), -cos(a))
	var perp := Vector2(-dir.y, dir.x)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var cl := PackedColorArray()
	var cr := PackedColorArray()
	var mid := PackedVector2Array()
	for i in segs + 1:
		var t := float(i) / segs
		var c := base + dir * l * t + Vector2(0, l * droop * t * t)
		var hw := w * 0.5 * pow(sin(PI * t), roundness)
		left.append(c + perp * hw)
		right.append(c - perp * hw)
		var col := c0.lerp(c1, t * 0.9 + 0.1)
		cl.append(col.lightened(0.08))
		cr.append(col.darkened(0.12))
		mid.append(c)
	right.reverse()
	cr.reverse()
	ci.draw_polygon(left + right, cl + cr)
	if segs > 5:
		ci.draw_polyline(mid, c1.lightened(0.25) * Color(1, 1, 1, 0.55), maxf(1.0, w * 0.06), true)


## Rama/tronco cónico con luz a un lado.
static func limb(ci: CanvasItem, pts: Array, widths: Array, light: Color, dark: Color) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in pts.size():
		var d: Vector2 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var n := Vector2(-d.y, d.x)
		left.append(pts[i] + n * widths[i] * 0.5)
		right.append(pts[i] - n * widths[i] * 0.5)
	var cols := PackedColorArray()
	for i in left.size():
		cols.append(light)
	right.reverse()
	for i in right.size():
		cols.append(dark)
	ci.draw_polygon(left + right, cols)
	ci.draw_circle(pts[-1], widths[-1] * 0.5, light.lerp(dark, 0.5))


static func stone(ci: CanvasItem, c: Vector2, rx: float, ry: float, tone: Color, rng: RandomNumberGenerator) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry * (0.85 if sin(a) > 0 else 1.0)) * (1.0 + rng.randf_range(-0.05, 0.05)))
	ci.draw_polygon(pts, vgrad(pts, tone.lightened(0.3), tone.darkened(0.5)))
	ci.draw_colored_polygon(ell(c + Vector2(-rx * 0.3, -ry * 0.45), rx * 0.4, ry * 0.22, 16), Color(1, 1, 1, 0.16))


static func block(ci: CanvasItem, r: Rect2, u: float, light: Color, shade: Color) -> void:
	var p := PackedVector2Array([r.position * u, Vector2(r.end.x, r.position.y) * u, r.end * u, Vector2(r.position.x, r.end.y) * u])
	ci.draw_polygon(p, PackedColorArray([light, shade, shade.darkened(0.15), light.darkened(0.12)]))


static func window(ci: CanvasItem, bottom: Vector2, hw: float, h: float, col: Color) -> void:
	var pts := PackedVector2Array([bottom + Vector2(-hw, 0), bottom + Vector2(-hw, -h + hw)])
	for i in 9:
		var a := PI + PI * i / 8.0
		pts.append(bottom + Vector2(0, -h + hw) + Vector2(cos(a), sin(a)) * hw)
	pts.append(bottom + Vector2(hw, 0))
	ci.draw_colored_polygon(pts, col)


static func ell(c: Vector2, rx: float, ry: float, n := 24, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


## Degradado vertical por vértice (arriba claro, abajo oscuro).
static func vgrad(pts: PackedVector2Array, top: Color, bottom: Color) -> PackedColorArray:
	var y0 := INF
	var y1 := -INF
	for p in pts:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, (p.y - y0) / maxf(1.0, y1 - y0)))
	return cols
