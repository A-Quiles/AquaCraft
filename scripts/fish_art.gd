class_name FishArt
extends RefCounted
## Traduce genes → pez 3D: malla de la especie (FishMesh) + materiales de cuerpo y aletas con sus colores,
## patrón y mutaciones.

const BODY := preload("res://shaders/fish_body.gdshader")
const FINS := preload("res://shaders/fish_fins.gdshader")


## Pez listo para poner en un FishStage. Sus dos materiales van en meta "mats".
static func model(g: Dictionary) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = FishMesh.get_mesh(g.sp, bool(g.veil))
	var mats: Array = []
	for sh in [BODY, FINS]:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		_fill(mat, g)
		mats.append(mat)
	m.set_surface_override_material(0, mats[0])
	m.set_surface_override_material(1, mats[1])
	m.set_meta("mats", mats)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


static func set_param(m: MeshInstance3D, key: String, value: Variant) -> void:
	for mat in m.get_meta("mats"):
		(mat as ShaderMaterial).set_shader_parameter(key, value)


static func _fill(m: ShaderMaterial, g: Dictionary) -> void:
	var sh: Dictionary = Catalog.SPECIES[g.sp].shape
	var c := Genetics.colors(g)
	m.set_shader_parameter("col_body", c[0])
	m.set_shader_parameter("col_pat", c[1])
	m.set_shader_parameter("col_fin", c[2])
	m.set_shader_parameter("aspect", aspect(g))
	m.set_shader_parameter("body_len", sh.len)
	m.set_shader_parameter("h_top", sh.ht)
	m.set_shader_parameter("h_bot", sh.hb)
	m.set_shader_parameter("peak", sh.peak)
	m.set_shader_parameter("k_front", sh.kf)
	m.set_shader_parameter("k_rear", sh.kr)
	m.set_shader_parameter("k_bot", sh.kb)
	m.set_shader_parameter("ped", sh.ped)
	m.set_shader_parameter("tail_type", sh.tail)
	m.set_shader_parameter("tail_len", sh.tl)
	m.set_shader_parameter("tail_h", sh.th)
	m.set_shader_parameter("dorsal", Vector4(sh.d[0], sh.d[1], sh.d[2], sh.d[3]))
	m.set_shader_parameter("dorsal_pt", sh.get("dp", 0.7))
	m.set_shader_parameter("dorsal2", sh.get("d2", 0.0))
	m.set_shader_parameter("anal", Vector4(sh.a[0], sh.a[1], sh.a[2], sh.a[3]))
	m.set_shader_parameter("adipose", sh.get("adip", 0.0))
	m.set_shader_parameter("barbels", sh.get("barb", 0.0))
	m.set_shader_parameter("threads", sh.get("thr", 0.0))
	m.set_shader_parameter("eye_t", sh.get("eye", 0.82))
	m.set_shader_parameter("pattern", int(g.pat))
	m.set_shader_parameter("seed", fmod(absf(float(hash(str(g.a)))) / 1000.0, 1.0))
	m.set_shader_parameter("neon", 1.0 if g.neon else 0.0)
	m.set_shader_parameter("albino", 1.0 if g.albino else 0.0)
	m.set_shader_parameter("veil", 1.0 if g.veil else 0.0)


## Tamaño en píxeles del pez según especie, gen de tamaño y crecimiento (0..1).
static func size_px(g: Dictionary, grow := 1.0) -> Vector2:
	var w: float = Catalog.SPECIES[g.sp].shape.px * g.size * (0.42 + 0.58 * grow)
	return Vector2(w, w / aspect(g))


## Los peces con velo necesitan un hueco más alto para que las aletas no se corten.
static func aspect(g: Dictionary) -> float:
	return Catalog.SPECIES[g.sp].shape.aspect / (1.3 if g.veil else 1.0)
