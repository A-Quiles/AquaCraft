class_name Glass
extends RefCounted
## Estilo propio de AquaCraft: piezas de «cristal de pecera» generadas al vuelo (sin imágenes externas).
## - Botón: gota de color con labio inferior en relieve, brillo curvo arriba y una burbujita.
## - Panel: cristal azul profundo con borde superior ondulado como la superficie del agua, filo de luz,
##   reflejo diagonal y burbujas en la esquina.
## - Tarjeta: cristal más claro con filo fino.
## Todo se cachea por color y se usa como StyleBoxTexture (nueve trozos; el centro se estira).

static var _cache := {}


static func _sdf(p: Vector2, size: Vector2, r: float) -> float:
	var q := (p - size * 0.5).abs() - (size * 0.5 - Vector2(r, r))
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r


static func _cov(d: float) -> float:
	return clampf(0.5 - d, 0.0, 1.0)


static func _over(dst: Color, src: Color) -> Color:
	var a := src.a + dst.a * (1.0 - src.a)
	if a <= 0.0:
		return Color(0, 0, 0, 0)
	return Color((src.r * src.a + dst.r * dst.a * (1.0 - src.a)) / a, (src.g * src.a + dst.g * dst.a * (1.0 - src.a)) / a,
		(src.b * src.a + dst.b * dst.a * (1.0 - src.a)) / a, a)


## Botón con relieve. pressed: labio casi hundido.
static func button(col: Color, pressed := false) -> StyleBoxTexture:
	var key := "b%s%s" % [col.to_html(), pressed]
	if not _cache.has(key):
		const S := 96
		const R := 30.0
		var lip := 3.0 if pressed else 8.0
		var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
		var face := Vector2(S, S - lip)
		for y in S:
			for x in S:
				var p := Vector2(x + 0.5, y + 0.5)
				var a_full := _cov(_sdf(p, Vector2(S, S), R))
				if a_full <= 0.0:
					continue
				var d_top := _sdf(p, face, R)
				var c := col.darkened(0.38)                                   # labio inferior
				if d_top < 0.5:
					var k := float(y) / face.y
					var top := col.lightened(0.14).lerp(col.darkened(0.06), k)
					c = top.lerp(c, clampf(d_top + 0.5, 0.0, 1.0))
					# Filo de luz arriba y sombra abajo, junto al borde.
					var rim := clampf(1.0 + d_top / 3.0, 0.0, 1.0)
					c = c.lerp(col.lightened(0.45) if k < 0.5 else col.darkened(0.2), rim * 0.55)
					# Brillo curvo: media luna clara en la mitad superior.
					var g := Vector2((p.x - S * 0.5) / (S * 0.42), (p.y - face.y * 0.12) / (face.y * 0.34))
					if g.length() < 1.0 and p.y < face.y * 0.46:
						c = c.lerp(Color.WHITE, 0.24 * (1.0 - g.length()) * (1.0 - k * 1.8))
				# Burbujita (en la esquina: no se estira).
				var bd := p.distance_to(Vector2(R * 0.62, R * 0.55))
				if bd < 4.2:
					c = c.lerp(Color.WHITE, 0.75 * clampf(4.2 - bd, 0.0, 1.0))
				img.set_pixel(x, y, Color(c, a_full * (0.6 if pressed and col.a < 1.0 else col.a)))
		var sb := StyleBoxTexture.new()
		sb.texture = ImageTexture.create_from_image(img)
		sb.set_texture_margin_all(32)
		sb.content_margin_left = 20
		sb.content_margin_right = 20
		sb.content_margin_top = 12 + (5.0 if pressed else 0.0)
		sb.content_margin_bottom = 12 + lip - (5.0 if pressed else 0.0)
		_cache[key] = sb
	return _cache[key]


## Panel grande (hojas, ventanas): cristal profundo con superficie ondulada arriba.
static func panel(tint := Color("123a52"), wavy := true) -> StyleBoxTexture:
	var key := "p%s%s" % [tint.to_html(), wavy]
	if not _cache.has(key):
		const S := 160
		const M := 48
		const R := 40.0
		var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
		for y in S:
			for x in S:
				var p := Vector2(x + 0.5, y + 0.5)
				# Superficie del agua: el borde superior ondula (periodo 32: casa con el trozo central de 64).
				var wave := (2.2 * sin(p.x / 32.0 * TAU) + 1.2 * sin(p.x / 16.0 * TAU + 1.3)) if wavy else 0.0
				var q := p - Vector2(0, wave * smoothstep(R, R + 6.0, minf(p.x, S - p.x)))
				var d := _sdf(q, Vector2(S, S), R)
				var a := _cov(d)
				if a <= 0.0:
					continue
				var k := float(y) / S
				var c := Color(tint.lightened(0.12).lerp(tint.darkened(0.35), k), 0.97)
				# Reflejo diagonal suave arriba a la izquierda.
				var diag := (p.x + p.y * 1.6) / S
				if diag > 0.18 and diag < 0.34:
					c = _over(c, Color(1, 1, 1, 0.045))
				# Filo de luz (más fuerte arriba) y línea oscura por dentro.
				var rim := clampf(1.0 + d / 2.6, 0.0, 1.0)
				c = _over(c, Color(0.6, 0.97, 1.0, rim * lerpf(0.75, 0.18, k)))
				var inner := clampf(1.0 - absf(d + 4.0) / 1.2, 0.0, 1.0)
				c = _over(c, Color(0, 0.05, 0.1, inner * 0.5))
				# Burbujas en la esquina superior izquierda.
				for b in [[Vector2(22, 30), 5.0], [Vector2(32, 20), 3.0], [Vector2(15, 18), 2.2]]:
					var bd := absf(p.distance_to(b[0]) - b[1])
					if bd < 1.2:
						c = _over(c, Color(0.8, 1.0, 1.0, 0.55 * (1.2 - bd)))
				img.set_pixel(x, y, Color(c, c.a * a))
		var sb := StyleBoxTexture.new()
		sb.texture = ImageTexture.create_from_image(img)
		sb.set_texture_margin_all(M)
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		sb.content_margin_left = 26
		sb.content_margin_right = 26
		sb.content_margin_top = 18
		sb.content_margin_bottom = 20
		_cache[key] = sb
	return _cache[key]


## Tarjeta dentro de un panel: cristal más claro con filo fino y brillo arriba.
static func card(tint := Color("1a4a63"), alpha := 0.9) -> StyleBoxTexture:
	var key := "c%s%.2f" % [tint.to_html(), alpha]
	if not _cache.has(key):
		const S := 80
		const R := 22.0
		var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
		for y in S:
			for x in S:
				var p := Vector2(x + 0.5, y + 0.5)
				var d := _sdf(p, Vector2(S, S), R)
				var a := _cov(d)
				if a <= 0.0:
					continue
				var k := float(y) / S
				var c := Color(tint.lightened(0.06).lerp(tint.darkened(0.12), k), alpha)
				var rim := clampf(1.0 + d / 1.8, 0.0, 1.0)
				c = _over(c, Color(0.7, 0.97, 1.0, rim * lerpf(0.4, 0.1, k)))
				img.set_pixel(x, y, Color(c, c.a * a))
		var sb := StyleBoxTexture.new()
		sb.texture = ImageTexture.create_from_image(img)
		sb.set_texture_margin_all(26)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 14
		sb.content_margin_bottom = 14
		_cache[key] = sb
	return _cache[key]
