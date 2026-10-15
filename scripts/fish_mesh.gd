class_name FishMesh
extends RefCounted
## Malla 3D de cada especie a partir de su perfil (Catalog.SPECIES[sp].shape), con los mismos ejes que el
## pez 2D: x de -1 (cola) a 1 (hocico), y hacia arriba, z hacia la cámara. Superficie 0: cuerpo cerrado
## con volumen; superficie 1: plano medio para cola, dorsal y anal + aletas laterales a cada lado.

const RINGS := 30
const AROUND := 22
const NOSE := 0.97
## Grosor (mitad del ancho / mitad del alto). Por defecto, los peces altos son más planos.
const THICK := {"goldfish": 0.62, "pleco": 0.8, "corydoras": 0.62, "pez_cofre": 0.85, "mandarin": 0.62, "molly": 0.5,
	"gobio_fuego": 0.55, "limpiador": 0.5, "banggai": 0.36, "hacha": 0.3}

static var _cache := {}


static func get_mesh(sp: String, veil: bool) -> ArrayMesh:
	var key := sp + ("_v" if veil else "")
	if not _cache.has(key):
		_cache[key] = _build(sp, veil)
	return _cache[key]


static func _prof(sh: Dictionary, t: float, kr: float, kf: float) -> float:
	t = clampf(t, 0.0, 1.0)
	var pk: float = sh.peak
	var u := (pk - t) / pk if t < pk else (t - pk) / (1.0 - pk)
	var b := maxf(0.0, 1.0 - u * u)
	return lerpf(sh.ped, 1.0, pow(b, kr)) if t < pk else pow(b, kf)


static func top_at(sh: Dictionary, t: float) -> float:
	return sh.ht * _prof(sh, t, sh.kr, sh.kf)


static func bot_at(sh: Dictionary, t: float) -> float:
	return -sh.hb * _prof(sh, t, sh.kb, lerpf(sh.kf, sh.kb, 0.5))


static func thickness(sp: String) -> float:
	var sh: Dictionary = Catalog.SPECIES[sp].shape
	return THICK.get(sp, clampf(0.62 - (sh.ht + sh.hb) * 0.42, 0.24, 0.55))


## Mitad del ancho del cuerpo en t (el pedúnculo es más estrecho; el morro se cierra).
static func half_width(sp: String, t: float) -> float:
	var sh: Dictionary = Catalog.SPECIES[sp].shape
	var h := (top_at(sh, t) - bot_at(sh, t)) * 0.5
	return thickness(sp) * h * lerpf(0.55, 1.0, smoothstep(0.0, 0.35, t))


static func _build(sp: String, veil: bool) -> ArrayMesh:
	var sh: Dictionary = Catalog.SPECIES[sp].shape
	var L: float = sh.len * 2.0
	var xs := NOSE - L
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# ── Cuerpo: anillos de sección ovalada, más juntos en el morro y la cola ──
	for i in RINGS + 1:
		var t := 0.5 - 0.5 * cos(PI * float(i) / RINGS)
		var top := top_at(sh, t)
		var bot := bot_at(sh, t)
		var mid := (top + bot) * 0.5
		var hh := maxf((top - bot) * 0.5, 0.0005)
		var w := maxf(half_width(sp, t), 0.0005)
		for j in AROUND:
			var a := TAU * j / AROUND
			var sy := sin(a)
			var cz := cos(a)
			st.set_uv(Vector2(t, float(j) / AROUND))
			st.add_vertex(Vector3(xs + L * t, mid + hh * signf(sy) * pow(absf(sy), 0.85), w * signf(cz) * pow(absf(cz), 0.8)))
	for i in RINGS:
		for j in AROUND:
			var a := i * AROUND + j
			var b := i * AROUND + (j + 1) % AROUND
			var c := a + AROUND
			var d := b + AROUND
			st.add_index(a); st.add_index(b); st.add_index(c)
			st.add_index(b); st.add_index(d); st.add_index(c)
	# Tapa del pedúnculo (la cola la cubre, pero así no se ve hueco al girar).
	var center := (RINGS + 1) * AROUND
	var t0 := 0.0
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(xs, (top_at(sh, t0) + bot_at(sh, t0)) * 0.5, 0))
	for j in AROUND:
		st.add_index(center); st.add_index((j + 1) % AROUND); st.add_index(j)
	st.generate_normals()
	var mesh := st.commit()

	# ── Aletas: plano medio (cola, dorsal, anal) y laterales (pectoral y pélvica a cada lado) ──
	var aspect: float = sh.aspect / (1.3 if veil else 1.0)
	var ylim := 1.0 / aspect
	var fs := SurfaceTool.new()
	fs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 28
	var ny := 6
	for i in nx + 1:
		for j in ny + 1:
			fs.set_color(Color(0, 0, 0))
			fs.set_uv2(Vector2.ZERO)
			fs.set_normal(Vector3(0, 0, 1))
			fs.add_vertex(Vector3(lerpf(-1.0, 1.0, float(i) / nx), lerpf(-ylim, ylim, float(j) / ny), 0.0))
	for i in nx:
		for j in ny:
			var a := i * (ny + 1) + j
			fs.add_index(a); fs.add_index(a + ny + 1); fs.add_index(a + 1)
			fs.add_index(a + 1); fs.add_index(a + ny + 1); fs.add_index(a + ny + 2)
	var base := (nx + 1) * (ny + 1)
	var eye: float = sh.get("eye", 0.82)
	# Pectoral: tras el opérculo, a media altura baja.
	var pt := clampf(eye - 0.19, 0.0, 1.0)
	var pc := Vector2(xs + L * pt, lerpf((top_at(sh, pt) + bot_at(sh, pt)) * 0.5, bot_at(sh, pt), 0.3))
	var plen := clampf(L * 0.15, 0.06, 0.16) * (1.0 + (0.4 if veil else 0.0))
	# Pélvica: bajo el vientre (el pez ángel lleva filamentos en su lugar).
	var vt := clampf(eye - 0.3, 0.25, 0.7)
	var hp := top_at(sh, vt) - bot_at(sh, vt)
	var pv := Vector2(xs + L * vt, bot_at(sh, vt) + hp * 0.14)
	var vlen := clampf(hp * 0.42, 0.035, 0.15) * (1.0 + (0.6 if veil else 0.0))
	var fins := [[0.5, pc, plen * 1.5, half_width(sp, pt) * 0.95 + 0.006]]
	if float(sh.get("thr", 0.0)) <= 0.0:
		fins.append([1.0, pv, vlen * 1.6, half_width(sp, vt) * 0.55 + 0.004])
	for f in fins:
		for side in [-1.0, 1.0]:
			var c: Vector2 = f[1]
			var r: float = f[2]
			for k in 4:
				var o := Vector2(-1 if k % 2 == 0 else 1, -1 if k < 2 else 1) * r
				fs.set_color(Color(f[0], 0, 0))
				fs.set_uv2(c)
				fs.set_normal(Vector3(0, 0, side))
				fs.add_vertex(Vector3(c.x + o.x, c.y + o.y, side * float(f[3])))
			fs.add_index(base); fs.add_index(base + 1); fs.add_index(base + 2)
			fs.add_index(base + 1); fs.add_index(base + 3); fs.add_index(base + 2)
			base += 4
	return fs.commit(mesh)
