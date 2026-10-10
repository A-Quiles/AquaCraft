class_name ShopArt
extends RefCounted
## Dibujos de la tienda y la estantería: aparatos, peceras, comida y productos.
## Cada función pinta dentro de un Rect2 (se escala sola) para usarla en miniaturas de cualquier tamaño.

const GLASS := Color(0.85, 0.96, 1.0, 0.35)
const GLASS_EDGE := Color(0.9, 1.0, 1.0, 0.85)
const DARK := Color(0.16, 0.18, 0.21)


static func _u(r: Rect2) -> float:
	return minf(r.size.x, r.size.y) / 140.0


static func _rr(ci: CanvasItem, r: Rect2, col: Color, rad := 6.0) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(int(rad))
	s.anti_aliasing = true
	ci.draw_style_box(s, r)


static func _bubbles(ci: CanvasItem, p: Vector2, u: float, n := 4) -> void:
	for i in n:
		var q := p + Vector2(sin(i * 2.1) * 6.0 * u, -i * 13.0 * u)
		ci.draw_arc(q, (3.0 + i * 0.8) * u, 0, TAU, 14, Color(1, 1, 1, 0.85), 1.5 * u, true)


# ───────────────────────── Aparatos ─────────────────────────

static func equipment(ci: CanvasItem, id: String, r: Rect2) -> void:
	var u := _u(r)
	var c := r.get_center()
	match id:
		"filtro_mini":
			_rr(ci, Rect2(c + Vector2(-6, -8) * u, Vector2(12, 62) * u), Color(0.22, 0.24, 0.27))
			_rr(ci, Rect2(c + Vector2(-34, -44) * u, Vector2(68, 44) * u), Color(0.2, 0.55, 0.62), 8 * u)
			_rr(ci, Rect2(c + Vector2(-34, -44) * u, Vector2(68, 10) * u), Color(0.3, 0.7, 0.77), 5 * u)
			ci.draw_rect(Rect2(c + Vector2(-44, -30) * u, Vector2(10, 36) * u), Color(0.75, 0.92, 1.0, 0.75))
			_rr(ci, Rect2(c + Vector2(-10, 48) * u, Vector2(20, 10) * u), Color(0.12, 0.13, 0.15), 3 * u)
		"esponja":
			ci.draw_line(c + Vector2(0, -36) * u, c + Vector2(10, -64) * u, Color(0.8, 0.95, 0.95, 0.9), 3 * u, true)
			_rr(ci, Rect2(c + Vector2(-24, -38) * u, Vector2(48, 78) * u), Color(0.15, 0.16, 0.18), 10 * u)
			for k in 7:
				ci.draw_line(c + Vector2(-24, -28 + k * 10) * u, c + Vector2(24, -28 + k * 10) * u, Color(0.28, 0.3, 0.33), 2.5 * u, true)
			ci.draw_colored_polygon(DecorArt.ell(c + Vector2(0, 46) * u, 30 * u, 7 * u), Color(0.3, 0.3, 0.33))
			_bubbles(ci, c + Vector2(10, -70) * u, u * 0.8, 3)
		"mochila":
			_rr(ci, Rect2(c + Vector2(-8, 0) * u, Vector2(16, 60) * u), Color(0.25, 0.27, 0.3))
			_rr(ci, Rect2(c + Vector2(-46, -52) * u, Vector2(92, 56) * u), Color(0.2, 0.22, 0.25), 8 * u)
			for k in 6:
				ci.draw_line(c + Vector2(-34 + k * 13, -36) * u, c + Vector2(-34 + k * 13, -8) * u, Color(0.32, 0.35, 0.4), 3 * u, true)
			ci.draw_rect(Rect2(c + Vector2(-46, 4) * u, Vector2(40, 22) * u), Color(0.75, 0.92, 1.0, 0.7))
			_rr(ci, Rect2(c + Vector2(-46, -58) * u, Vector2(92, 10) * u), Color(0.35, 0.38, 0.43), 4 * u)
		"canister":
			ci.draw_line(c + Vector2(-14, -40) * u, c + Vector2(-30, -66) * u, Color(0.45, 0.8, 0.6, 0.9), 6 * u, true)
			ci.draw_line(c + Vector2(14, -40) * u, c + Vector2(30, -66) * u, Color(0.45, 0.8, 0.6, 0.9), 6 * u, true)
			_rr(ci, Rect2(c + Vector2(-34, -40) * u, Vector2(68, 100) * u), Color(0.2, 0.22, 0.25), 14 * u)
			_rr(ci, Rect2(c + Vector2(-38, -46) * u, Vector2(76, 18) * u), Color(0.3, 0.33, 0.37), 8 * u)
			for x in [-38.0, 30.0]:
				_rr(ci, Rect2(c + Vector2(x, -30) * u, Vector2(8, 16) * u), Color(0.15, 0.6, 0.55), 3 * u)
			ci.draw_rect(Rect2(c + Vector2(-26, -10) * u, Vector2(8, 60) * u), Color(1, 1, 1, 0.08))
		"skimmer":
			_rr(ci, Rect2(c + Vector2(-26, -10) * u, Vector2(52, 72) * u), Color(0.82, 0.92, 0.98, 0.5), 6 * u)
			_rr(ci, Rect2(c + Vector2(-20, -60) * u, Vector2(40, 50) * u), Color(0.85, 0.94, 1.0, 0.55), 6 * u)
			ci.draw_rect(Rect2(c + Vector2(-16, -40) * u, Vector2(32, 24) * u), Color(0.5, 0.36, 0.16, 0.85))
			for k in 9:
				ci.draw_circle(c + Vector2(-14 + (k % 3) * 14, 6 + (k / 3) * 16) * u, 4 * u, Color(1, 1, 1, 0.7))
			_rr(ci, Rect2(c + Vector2(-30, 60) * u, Vector2(60, 10) * u), DARK, 3 * u)
		"calentador_mini", "calentador_fijo", "calentador":
			var l: float = {"calentador_mini": 70.0, "calentador_fijo": 96.0, "calentador": 116.0}[id]
			var top := c + Vector2(0, -l * 0.5) * u
			_rr(ci, Rect2(top + Vector2(-11, 0) * u, Vector2(22, l) * u), Color(0.82, 0.95, 1.0, 0.45), 10 * u)
			ci.draw_rect(Rect2(top + Vector2(-4, 24) * u, Vector2(8, l - 34) * u), Color(1.0, 0.45, 0.2, 0.9))
			_rr(ci, Rect2(top + Vector2(-13, -4) * u, Vector2(26, 22) * u), DARK, 5 * u)
			if id == "calentador":
				ci.draw_circle(top + Vector2(0, -10) * u, 9 * u, Color(0.95, 0.4, 0.3))
				ci.draw_line(top + Vector2(0, -10) * u, top + Vector2(0, -17) * u, Color.WHITE, 2 * u, true)
			ci.draw_rect(Rect2(top + Vector2(-7, 22) * u, Vector2(3, l - 30) * u), Color(1, 1, 1, 0.4))
		"difusor":
			ci.draw_line(c + Vector2(0, 30) * u, c + Vector2(-30, -60) * u, Color(0.8, 0.95, 0.95, 0.9), 3 * u, true)
			ci.draw_colored_polygon(DecorArt.ell(c + Vector2(0, 40) * u, 36 * u, 14 * u), Color(0.6, 0.62, 0.66))
			ci.draw_colored_polygon(DecorArt.ell(c + Vector2(0, 34) * u, 34 * u, 9 * u), Color(0.75, 0.78, 0.82))
			for k in 12:
				_bubbles(ci, c + Vector2(-24 + k * 4.5, 20 - (k % 4) * 8) * u, u * 0.55, 2)
		"bomba":
			ci.draw_line(c + Vector2(-12, -26) * u, c + Vector2(-30, -64) * u, Color(0.8, 0.95, 0.95, 0.9), 3 * u, true)
			ci.draw_line(c + Vector2(12, -26) * u, c + Vector2(30, -64) * u, Color(0.8, 0.95, 0.95, 0.9), 3 * u, true)
			_rr(ci, Rect2(c + Vector2(-48, -28) * u, Vector2(96, 64) * u), Color(0.9, 0.92, 0.94), 18 * u)
			_rr(ci, Rect2(c + Vector2(-48, 22) * u, Vector2(96, 14) * u), Color(0.75, 0.78, 0.82), 8 * u)
			ci.draw_circle(c + Vector2(28, -6) * u, 6 * u, Color(0.3, 0.8, 0.5))
			for x in [-12.0, 12.0]:
				_rr(ci, Rect2(c + Vector2(x - 4, -34) * u, Vector2(8, 10) * u), Color(0.45, 0.48, 0.52), 2 * u)
		"circulacion":
			_rr(ci, Rect2(c + Vector2(-14, -10) * u, Vector2(28, 52) * u), DARK, 6 * u)
			ci.draw_circle(c + Vector2(0, -20) * u, 40 * u, Color(0.22, 0.24, 0.28))
			ci.draw_circle(c + Vector2(0, -20) * u, 32 * u, Color(0.75, 0.9, 1.0, 0.45))
			for k in 3:
				var a := k * TAU / 3.0
				DecorArt.leaf(ci, c + Vector2(0, -20) * u, a, 28 * u, 14 * u, Color(0.3, 0.6, 0.85), Color(0.5, 0.8, 1.0), 0.3)
			ci.draw_circle(c + Vector2(0, -20) * u, 7 * u, DARK)
		"led_pro", "led_plantada":
			var rgb := id == "led_plantada"
			var bar := Rect2(c + Vector2(-60, -30) * u, Vector2(120, 22) * u)
			for k in 6:
				var col := Color(1, 1, 0.9, 0.16)
				if rgb:
					col = [Color(1, 0.3, 0.3, 0.16), Color(0.3, 1, 0.4, 0.16), Color(0.4, 0.5, 1, 0.16)][k % 3]
				var x0 := bar.position.x + (10 + k * 20) * u
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x0, bar.end.y), Vector2(x0 + 8 * u, bar.end.y),
					Vector2(x0 + 18 * u, bar.end.y + 70 * u), Vector2(x0 - 10 * u, bar.end.y + 70 * u)]), col)
			_rr(ci, bar, DARK, 6 * u)
			for k in 10:
				var col := Color(1, 1, 0.95)
				if rgb:
					col = [Color(1, 0.4, 0.4), Color(0.4, 1, 0.5), Color(0.5, 0.6, 1)][k % 3]
				ci.draw_circle(bar.position + Vector2(10 + k * 11.2, 16) * u, 3.2 * u, col)
			_rr(ci, Rect2(bar.position + Vector2(-6, -4) * u, Vector2(12, 30) * u), Color(0.3, 0.33, 0.37), 3 * u)
			_rr(ci, Rect2(Vector2(bar.end.x - 6 * u, bar.position.y - 4 * u), Vector2(12, 30) * u), Color(0.3, 0.33, 0.37), 3 * u)
		"tira":
			var s := Rect2(c + Vector2(-14, -58) * u, Vector2(28, 116) * u)
			_rr(ci, s, Color(0.08, 0.1, 0.12), 5 * u)
			for k in 7:
				ci.draw_rect(Rect2(s.position + Vector2(4, 6 + k * 15.5) * u, Vector2(20, 12) * u), Color(0.3, 0.95, 0.5) if k == 3 else Color(0.2, 0.25, 0.3))
			ci.draw_string(UI.bold, s.position + Vector2(32, 60) * u, "25°", HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * u), UI.NAVY)
		"digital":
			ci.draw_line(c + Vector2(30, 10) * u, c + Vector2(44, 62) * u, DARK, 3 * u, true)
			ci.draw_circle(c + Vector2(44, 62) * u, 5 * u, Color(0.7, 0.72, 0.75))
			var b := Rect2(c + Vector2(-50, -36) * u, Vector2(100, 56) * u)
			_rr(ci, b, Color(0.93, 0.95, 0.97), 8 * u)
			_rr(ci, b.grow(-7 * u), Color(0.55, 0.75, 0.6), 4 * u)
			ci.draw_string(UI.bold, b.position + Vector2(12, 40) * u, "25.4°", HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * u), Color(0.08, 0.15, 0.1))
		"ato":
			ci.draw_line(c + Vector2(20, -46) * u, c + Vector2(56, -64) * u, Color(0.8, 0.95, 0.95, 0.9), 4 * u, true)
			_rr(ci, Rect2(c + Vector2(-40, -44) * u, Vector2(70, 100) * u), Color(0.85, 0.94, 1.0, 0.55), 10 * u)
			ci.draw_rect(Rect2(c + Vector2(-34, -6) * u, Vector2(58, 56) * u), Color(0.4, 0.75, 1.0, 0.55))
			_rr(ci, Rect2(c + Vector2(-44, -52) * u, Vector2(78, 12) * u), DARK, 4 * u)
			_rr(ci, Rect2(c + Vector2(40, 10) * u, Vector2(16, 30) * u), DARK, 4 * u)


# ───────────────────────── Peceras ─────────────────────────

static func tank(ci: CanvasItem, i: int, r: Rect2) -> void:
	var u := _u(r)
	var c := r.get_center() + Vector2(0, 6) * u
	var water_top := Color(0.45, 0.85, 0.92)
	var water_deep := Color(0.1, 0.42, 0.6)
	var t: Rect2
	if i == 0:
		var rad := 52.0 * u
		var cc := c + Vector2(0, -4) * u
		ci.draw_circle(cc, rad, water_deep)
		ci.draw_circle(cc + Vector2(-6, -8) * u, rad * 0.8, water_top.lerp(water_deep, 0.4))
		ci.draw_colored_polygon(DecorArt.ell(cc + Vector2(0, rad * 0.78), rad * 0.62, 8 * u), Color(0.9, 0.8, 0.6))
		ci.draw_arc(cc, rad, 0, TAU, 48, GLASS_EDGE, 3 * u, true)
		ci.draw_arc(cc, rad * 0.82, PI * 1.1, PI * 1.4, 12, Color(1, 1, 1, 0.5), 4 * u, true)
		ci.draw_colored_polygon(DecorArt.ell(cc + Vector2(0, -rad * 0.86), rad * 0.5, 6 * u), Color(0.6, 0.85, 0.95))
		_rr(ci, Rect2(cc + Vector2(-34 * u, rad * 0.94), Vector2(68, 10) * u), Color(0.45, 0.3, 0.2), 3 * u)
		_fishlet(ci, cc + Vector2(-8, 4) * u, u, Color(1.0, 0.55, 0.2))
		return
	var dims: Array = [Vector2(), Vector2(76, 76), Vector2(104, 72), Vector2(124, 64), Vector2(128, 82)]
	var d: Vector2 = dims[i] * u
	t = Rect2(c - d * 0.5, d)
	ci.draw_rect(t, water_deep)
	ci.draw_rect(Rect2(t.position, Vector2(t.size.x, t.size.y * 0.5)), water_top.lerp(water_deep, 0.35))
	ci.draw_rect(Rect2(t.position.x, t.end.y - 12 * u, t.size.x, 12 * u), Color(0.9, 0.8, 0.6))
	for k in int(2 + i):
		var x := t.position.x + t.size.x * (0.15 + 0.7 * k / maxf(1.0, 1.0 + i))
		DecorArt.blade(ci, Vector2(x, t.end.y - 10 * u), t.size.y * 0.55, 5 * u, 4 * u, Color(0.2, 0.55, 0.3), Color(0.45, 0.85, 0.5), 6)
	_fishlet(ci, t.get_center() + Vector2(8, -6) * u, u, Color(1.0, 0.55, 0.2))
	if i >= 3:
		_fishlet(ci, t.get_center() + Vector2(-26, 8) * u, u * 0.8, Color(0.3, 0.6, 1.0))
	ci.draw_rect(t, GLASS_EDGE, false, 2.5 * u)
	ci.draw_line(t.position + Vector2(8, 6) * u, t.position + Vector2(20, t.size.y / u - 18) * u, Color(1, 1, 1, 0.35), 3 * u, true)
	var wood := i == 4
	var trim := Color(0.42, 0.27, 0.16) if wood else DARK
	_rr(ci, Rect2(t.position + Vector2(-4, -8) * u, Vector2(t.size.x + 8 * u, 9 * u)), trim, 3 * u)
	_rr(ci, Rect2(Vector2(t.position.x - 4 * u, t.end.y), Vector2(t.size.x + 8 * u, 7 * u)), trim, 3 * u)
	if wood:
		_rr(ci, Rect2(Vector2(t.position.x, t.end.y + 7 * u), Vector2(t.size.x, 14 * u)), Color(0.55, 0.36, 0.22), 2 * u)


static func _fishlet(ci: CanvasItem, p: Vector2, u: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-10, 0) * u, p + Vector2(-19, -7) * u, p + Vector2(-19, 7) * u]), col.darkened(0.15))
	ci.draw_colored_polygon(DecorArt.ell(p, 13 * u, 7 * u), col)
	ci.draw_circle(p + Vector2(7, -2) * u, 1.8 * u, UI.NAVY)


# ───────────────────────── Comida y productos ─────────────────────────

## Bote de comida de pie sobre `base` (centro de la base). `label` corto, se pinta en la etiqueta.
static func jar(ci: CanvasItem, base: Vector2, col: Color, label: String, k := 1.0, fs := 15) -> void:
	var j := Rect2(base + Vector2(-26, -66) * k, Vector2(52, 66) * k)
	ci.draw_rect(Rect2(j.position + Vector2(3, 4) * k, j.size), Color(0, 0, 0, 0.15))
	_rr(ci, j, Color(0.95, 0.97, 1.0, 0.6), 8 * k)
	_rr(ci, Rect2(j.position + Vector2(4, 22) * k, Vector2(44, 40) * k), col.darkened(0.08), 6 * k)
	_rr(ci, Rect2(j.position + Vector2(-3, -10) * k, Vector2(58, 14) * k), col.darkened(0.45), 4 * k)
	_rr(ci, Rect2(j.position + Vector2(3, 26) * k, Vector2(46, 22) * k), Color("fff3df"), 3 * k)
	ci.draw_string(UI.bold, j.position + Vector2(0, 43) * k, label, HORIZONTAL_ALIGNMENT_CENTER, j.size.x, int(fs * k), UI.NAVY)
	ci.draw_rect(Rect2(j.position + Vector2(5, 4) * k, Vector2(5, 16) * k), Color(1, 1, 1, 0.55))


## Botella de producto de pie sobre `base`.
static func bottle(ci: CanvasItem, base: Vector2, col: Color, label: String, k := 1.0, fs := 14) -> void:
	var b := Rect2(base + Vector2(-20, -56) * k, Vector2(40, 56) * k)
	ci.draw_rect(Rect2(b.position + Vector2(3, 4) * k, b.size), Color(0, 0, 0, 0.15))
	_rr(ci, b, col, 9 * k)
	_rr(ci, Rect2(b.position + Vector2(11, -14) * k, Vector2(18, 16) * k), Color("eeeeee"), 3 * k)
	_rr(ci, Rect2(b.position + Vector2(13, -24) * k, Vector2(14, 12) * k), col.darkened(0.4), 3 * k)
	_rr(ci, Rect2(b.position + Vector2(4, 16) * k, Vector2(32, 22) * k), Color("fffaf2"), 3 * k)
	ci.draw_string(UI.bold, b.position + Vector2(0, 33) * k, label, HORIZONTAL_ALIGNMENT_CENTER, b.size.x, int(fs * k), UI.NAVY)
	ci.draw_rect(Rect2(b.position + Vector2(5, 6) * k, Vector2(4, 40) * k), Color(1, 1, 1, 0.3))


static func food(ci: CanvasItem, id: String, r: Rect2) -> void:
	var u := _u(r)
	var col := Catalog.color(Catalog.FOODS[id].col)
	var base := r.get_center() + Vector2(-14, 50) * u
	jar(ci, base, col, Catalog.FOODS[id].name.left(7), u * 1.25, 13)
	# Unos trozos sueltos al lado, con su forma real.
	var p := r.get_center() + Vector2(42, 40) * u
	for i in 5:
		var q := p + Vector2(sin(i * 2.4) * 14.0, -i * 9.0 + cos(i * 1.7) * 4.0) * u
		match id:
			"granulos": ci.draw_circle(q, 4.5 * u, col.darkened(0.15))
			"nori": ci.draw_rect(Rect2(q - Vector2(6, 4) * u, Vector2(12, 8) * u), col)
			"artemia":
				ci.draw_line(q - Vector2(5, 2) * u, q + Vector2(5, 2) * u, col, 3 * u, true)
				ci.draw_circle(q + Vector2(5, 2) * u, 2 * u, col.lightened(0.3))
			_: ci.draw_colored_polygon(PackedVector2Array([q + Vector2(-6, 0) * u, q + Vector2(0, -4) * u, q + Vector2(6, 1) * u, q + Vector2(-1, 4) * u]), col)


static func product(ci: CanvasItem, id: String, r: Rect2) -> void:
	var u := _u(r)
	var pr: Dictionary = Catalog.PRODUCTS[id]
	bottle(ci, r.get_center() + Vector2(0, 52) * u, Catalog.color(pr.col), pr.short, u * 1.6, 13)
