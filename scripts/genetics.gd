class_name Genetics
extends RefCounted
## Genes de un pez (Dictionary, se guarda tal cual en JSON):
##   sp: especie · a/b/f: colores HSV [h,s,v] de cuerpo, patrón y aletas
##   pat: patrón (índice de Catalog.PATTERN_NAMES) · size: 0.8–1.35
##   neon / albino / veil / rare_col: mutaciones

const BASE_MUTATION := 0.025
const MUTATIONS := ["neon", "albino", "veil", "rare_col", "pattern", "giant"]


static func random_genes(sp: String, rng: RandomNumberGenerator, mutations := 0) -> Dictionary:
	var s: Dictionary = Catalog.SPECIES[sp]
	var preset: Array = s.presets[rng.randi() % s.presets.size()]
	var pats: Array = s.patterns
	var g := {
		"sp": sp,
		"a": _jitter(_hsv(preset[0]), rng),
		"b": _jitter(_hsv(preset[1]), rng),
		"f": _jitter(_hsv(preset[2]), rng),
		"pat": int(pats[rng.randi() % pats.size()]),
		"size": clampf(1.0 + rng.randfn(0.0, 0.05), 0.88, 1.12),
		"neon": false, "albino": false, "veil": false, "rare_col": false,
	}
	for i in mutations:
		mutate(g, rng)
	return g


## Cruce: cada gen viene de uno de los padres (los colores se mezclan) + posible mutación espontánea.
static func breed(p: Dictionary, q: Dictionary, rng: RandomNumberGenerator, mut_chance: float) -> Dictionary:
	var g := {"sp": p.sp}
	if bool(p.rare_col) != bool(q.rare_col):
		var carrier: Dictionary = p if p.rare_col else q
		var other: Dictionary = q if p.rare_col else p
		var src: Dictionary = carrier if rng.randf() < 0.5 else other
		for k in ["a", "b", "f"]:
			g[k] = _jitter(src[k], rng)
		g.rare_col = src.rare_col
	else:
		var t := rng.randf()
		for k in ["a", "b", "f"]:
			g[k] = _jitter(_mix_hsv(p[k], q[k], t), rng)
		g.rare_col = p.rare_col
	g.pat = int(p.pat) if rng.randf() < 0.5 else int(q.pat)
	g.size = clampf((float(p.size) + float(q.size)) * 0.5 + rng.randfn(0.0, 0.05), 0.8, 1.35)
	for m in ["neon", "albino", "veil"]:
		var n := int(bool(p[m])) + int(bool(q[m]))
		g[m] = rng.randf() < [0.0, 0.4, 0.8][n]
	if rng.randf() < mut_chance:
		mutate(g, rng)
	return g


## Aplica una mutación que el pez aún no tenga.
static func mutate(g: Dictionary, rng: RandomNumberGenerator) -> void:
	var pool: Array = []
	for m in MUTATIONS:
		if m == "pattern":
			if g.pat in Catalog.SPECIES[g.sp].patterns:
				pool.append(m)
		elif m == "giant":
			if g.size < 1.22:
				pool.append(m)
		elif not g[m]:
			pool.append(m)
	if pool.is_empty():
		return
	match pool[rng.randi() % pool.size()]:
		"neon": g.neon = true
		"albino": g.albino = true
		"veil": g.veil = true
		"giant": g.size = rng.randf_range(1.24, 1.32)
		"pattern":
			var others: Array = []
			for i in Catalog.PATTERN_NAMES.size():
				if not (i in Catalog.SPECIES[g.sp].patterns):
					others.append(i)
			g.pat = others[rng.randi() % others.size()]
		"rare_col":
			var shift := rng.randf_range(0.25, 0.75)
			for k in ["a", "b", "f"]:
				var c: Array = g[k]
				g[k] = [fposmod(c[0] + shift, 1.0), maxf(c[1], 0.55), maxf(c[2], 0.6)]
			g.rare_col = true


static func rarity(g: Dictionary) -> int:
	var sc := 0
	if g.neon: sc += 2
	if g.albino: sc += 2
	if g.veil: sc += 1
	if g.rare_col: sc += 1
	if not (int(g.pat) in Catalog.SPECIES[g.sp].patterns): sc += 1
	if g.size >= 1.22: sc += 1
	return mini(sc, 4)


static func mutation_names(g: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if g.neon: out.append("Neón")
	if g.albino: out.append("Albino")
	if g.veil: out.append("Velo")
	if g.rare_col: out.append("Color raro")
	if not (int(g.pat) in Catalog.SPECIES[g.sp].patterns): out.append("Patrón raro")
	if g.size >= 1.22: out.append("Gigante")
	return out


## Clave de colección: especie + patrón + mutaciones + familia de color.
static func variant_key(g: Dictionary) -> String:
	return "%s|%d|%d%d%d%d|%d" % [g.sp, int(g.pat), int(g.neon), int(g.albino), int(g.veil), int(g.rare_col), int(g.a[0] * 6.0) % 6]


static func value(f: Dictionary) -> int:
	var g: Dictionary = f.genes
	var stage := 0.25 if f.grow < 0.35 else (0.55 if f.grow < 1.0 else 1.0)
	var v: float = Catalog.SPECIES[g.sp].price * 0.7 * Catalog.RARITY_MULT[rarity(g)] \
		* (0.6 + 0.4 * g.size) * stage * (0.4 + 0.6 * f.health / 100.0)
	return maxi(1, roundi(v))


static func colors(g: Dictionary) -> Array[Color]:
	return [_col(g.a), _col(g.b), _col(g.f)]


static func normalize(g: Dictionary) -> Dictionary:
	g.pat = int(g.pat)
	g.size = float(g.size)
	for m in ["neon", "albino", "veil", "rare_col"]:
		g[m] = bool(g.get(m, false))
	return g


static func _col(c: Array) -> Color:
	return Color.from_hsv(c[0], c[1], c[2])


static func _hsv(hex: String) -> Array:
	var c := Color.html(hex)
	return [c.h, c.s, c.v]


static func _jitter(c: Array, rng: RandomNumberGenerator) -> Array:
	return [fposmod(c[0] + rng.randf_range(-0.015, 0.015), 1.0),
		clampf(c[1] + rng.randf_range(-0.05, 0.05), 0.0, 1.0),
		clampf(c[2] + rng.randf_range(-0.04, 0.04), 0.05, 1.0)]


static func _mix_hsv(x: Array, y: Array, t: float) -> Array:
	var dh := fposmod(y[0] - x[0] + 0.5, 1.0) - 0.5  # camino corto en el círculo de tono
	return [fposmod(x[0] + dh * t, 1.0), lerpf(x[1], y[1], t), lerpf(x[2], y[2], t)]
