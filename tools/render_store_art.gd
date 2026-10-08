extends SceneTree
## Genera el icono de la app y el gráfico destacado de Google Play con el mismo arte del juego.
##   godot --rendering-driver opengl3 -s tools/render_store_art.gd
## Salida: assets/icon.png (512), assets/android/icon_{foreground,background}.png (432),
##         store/feature_graphic.png (1024×500)

const WATER := preload("res://shaders/water.gdshader")
const CAUSTICS := preload("res://assets/textures/caustics.png")
const NOISE := preload("res://assets/textures/noise.png")


func _initialize() -> void:
	UI.setup()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/android"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://store"))
	_run.call_deferred()


func _run() -> void:
	var betta := {"sp": "betta", "a": [0.62, 0.85, 0.95], "b": [0.92, 0.75, 1.0], "f": [0.66, 0.8, 0.95],
		"pat": 1, "size": 1.0, "neon": false, "albino": false, "veil": true, "rare_col": false}

	# Icono completo 512
	var vp := _viewport(Vector2i(512, 512), false)
	_water(vp, Vector2(512, 512))
	_bubbles(vp, [Vector2(400, 120), Vector2(430, 70), Vector2(380, 40)], 1.6)
	_fish(vp, betta, Vector2(262, 270), 4.4)
	await _save(vp, "res://assets/icon.png")

	# Icono adaptativo: fondo y primer plano (zona segura = 66% central)
	vp = _viewport(Vector2i(432, 432), false)
	_water(vp, Vector2(432, 432))
	await _save(vp, "res://assets/android/icon_background.png")
	vp = _viewport(Vector2i(432, 432), true)
	_bubbles(vp, [Vector2(300, 140), Vector2(320, 105)], 1.2)
	_fish(vp, betta, Vector2(220, 225), 2.75)
	await _save(vp, "res://assets/android/icon_foreground.png")

	# Gráfico destacado 1024×500
	vp = _viewport(Vector2i(1024, 500), false)
	_water(vp, Vector2(1024, 500))
	var deco := Node2D.new()
	vp.add_child(deco)
	deco.draw.connect(func():
		for d in [["vallisneria", 640.0, 1.1], ["rotala", 980.0, 1.0], ["castillo", 860.0, 0.95], ["helecho", 720.0, 1.0], ["rocas", 560.0, 0.9]]:
			deco.draw_set_transform(Vector2(d[1], 505), 0.0, Vector2.ONE)
			DecorArt.draw(deco, d[0], d[2], 3)
		deco.draw_set_transform(Vector2.ZERO))
	var sub := ColorRect.new()
	sub.position = Vector2(0, 430)
	sub.size = Vector2(1024, 70)
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/substrate.gdshader")
	for k in 3:
		sm.set_shader_parameter(["col_a", "col_b", "col_c"][k], Catalog.color(Catalog.SUBSTRATES.arena.cols[k]))
	sm.set_shader_parameter("pebble", 0.0)
	sm.set_shader_parameter("size", sub.size)
	sm.set_shader_parameter("caustics", CAUSTICS)
	sm.set_shader_parameter("noise", NOISE)
	sub.material = sm
	vp.add_child(sub)
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for f in [["discus", Vector2(860, 170), 1.5, 1], ["goldfish", Vector2(690, 120), 1.3, 0], ["neon", Vector2(950, 330), 1.3, 0],
			["rainbow", Vector2(610, 360), 1.2, 0], ["guppy", Vector2(975, 75), 1.4, 0]]:
		_fish(vp, Genetics.random_genes(f[0], r, f[3]), f[1], f[2])
	_fish(vp, betta, Vector2(800, 320), 2.0)
	var title := UI.label("AquaCraft", 112, Color.WHITE, UI.heading)
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.15, 0.25, 0.55))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.position = Vector2(60, 120)
	vp.add_child(title)
	var tag := UI.label("Cría peces únicos en tu acuario cozy", 34, Color(1, 1, 1, 0.95), UI.bold)
	tag.position = Vector2(66, 270)
	vp.add_child(tag)
	await _save(vp, "res://store/feature_graphic.png")
	print("arte generado")
	quit()


func _viewport(size: Vector2i, transparent: bool) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = transparent
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	return vp


func _water(vp: SubViewport, size: Vector2) -> void:
	var w := ColorRect.new()
	w.size = size
	var m := ShaderMaterial.new()
	m.shader = WATER
	m.set_shader_parameter("size", size)
	m.set_shader_parameter("light", 1.2)
	m.set_shader_parameter("caustics", CAUSTICS)
	m.set_shader_parameter("noise", NOISE)
	w.material = m
	vp.add_child(w)


func _fish(vp: SubViewport, g: Dictionary, center: Vector2, zoom: float) -> void:
	var p := FishPreview.make(g, zoom)
	p.material.set_shader_parameter("auto_wag", 0.0)
	p.material.set_shader_parameter("phase", 1.2)
	p.size = p.custom_minimum_size
	p.position = center - p.size * 0.5
	vp.add_child(p)


func _bubbles(vp: SubViewport, pts: Array, k: float) -> void:
	var n := Node2D.new()
	vp.add_child(n)
	n.draw.connect(func():
		for i in pts.size():
			var r := (14.0 - i * 3.0) * k
			n.draw_arc(pts[i], r, 0, TAU, 32, Color(1, 1, 1, 0.85), 3.0 * k, true)
			n.draw_circle(pts[i] + Vector2(-r * 0.35, -r * 0.35), r * 0.25, Color(1, 1, 1, 0.9)))


func _save(vp: SubViewport, path: String) -> void:
	for i in 4:
		await process_frame
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	vp.queue_free()
