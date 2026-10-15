class_name FishStage
extends SubViewport
## Escenario 3D de los peces: cámara ortográfica de frente al cristal (1 unidad = 1 píxel de la pecera),
## luz de la pantalla LED desde arriba, rebote azulado del fondo y fondo transparente. Lo usan la
## pecera (todos sus peces) y las miniaturas de la interfaz (un pez cada una).

var cam: Camera3D
var key: DirectionalLight3D
var fill: DirectionalLight3D
var world_size := Vector2(100, 100)


func _init() -> void:
	own_world_3d = true
	transparent_bg = true
	msaa_3d = Viewport.MSAA_4X
	gui_disable_input = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 1.0
	cam.far = 2000.0
	add_child(cam)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.78, 0.86)
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	key = DirectionalLight3D.new()                # LED de la tapa: arriba y algo por delante
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.98, 0.94)
	key.rotation = Vector3(deg_to_rad(-62), deg_to_rad(-18), 0)
	add_child(key)
	fill = DirectionalLight3D.new()               # rebote del fondo: de abajo y detrás, azul
	fill.light_energy = 0.35
	fill.light_color = Color(0.55, 0.85, 1.0)
	fill.rotation = Vector3(deg_to_rad(40), deg_to_rad(160), 0)
	add_child(fill)


## Encuadra un rectángulo de `s` píxeles (x a la derecha, y hacia abajo como en 2D) y fija la resolución.
func frame(s: Vector2, res_scale: float) -> void:
	world_size = s
	cam.size = s.y
	cam.position = Vector3(s.x * 0.5, -s.y * 0.5, 1000.0)
	size = Vector2i(maxi(8, int(s.x * res_scale)), maxi(8, int(s.y * res_scale)))


func set_light(k: float) -> void:
	key.light_energy = 1.25 * k
	fill.light_energy = 0.35 * lerpf(0.6, 1.0, k)


## Posición 2D (píxeles, y hacia abajo) → 3D.
static func to3d(p: Vector2, z := 0.0) -> Vector3:
	return Vector3(p.x, -p.y, z)
