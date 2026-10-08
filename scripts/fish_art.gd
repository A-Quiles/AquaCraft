class_name FishArt
extends RefCounted
## Traduce genes → parámetros del shader de pez.

const SHADER := preload("res://shaders/fish.gdshader")
const WHITE := preload("res://assets/textures/dot.png")  # cualquier textura: el shader solo usa UV


static func material(g: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	var sh: Dictionary = Catalog.SPECIES[g.sp].shape
	var c := Genetics.colors(g)
	m.set_shader_parameter("col_body", c[0])
	m.set_shader_parameter("col_pat", c[1])
	m.set_shader_parameter("col_fin", c[2])
	m.set_shader_parameter("aspect", aspect(g))
	m.set_shader_parameter("body_len", sh.len)
	m.set_shader_parameter("body_h", sh.h)
	m.set_shader_parameter("tail_type", sh.tail)
	m.set_shader_parameter("tail_len", sh.tl)
	m.set_shader_parameter("tail_h", sh.th)
	m.set_shader_parameter("dorsal", sh.dor)
	m.set_shader_parameter("anal", sh.ana)
	m.set_shader_parameter("sweep", sh.sweep)
	m.set_shader_parameter("point", sh.point)
	m.set_shader_parameter("pattern", int(g.pat))
	m.set_shader_parameter("seed", fmod(absf(float(hash(str(g.a)))) / 1000.0, 1.0))
	m.set_shader_parameter("neon", 1.0 if g.neon else 0.0)
	m.set_shader_parameter("albino", 1.0 if g.albino else 0.0)
	m.set_shader_parameter("veil", 1.0 if g.veil else 0.0)
	return m


## Tamaño en píxeles del quad según especie, gen de tamaño y crecimiento (0..1).
static func size_px(g: Dictionary, grow := 1.0) -> Vector2:
	var w: float = Catalog.SPECIES[g.sp].shape.px * g.size * (0.42 + 0.58 * grow)
	return Vector2(w, w / aspect(g))


## Los peces con velo necesitan un quad más alto para que las aletas no se corten.
static func aspect(g: Dictionary) -> float:
	return Catalog.SPECIES[g.sp].shape.aspect / (1.3 if g.veil else 1.0)
