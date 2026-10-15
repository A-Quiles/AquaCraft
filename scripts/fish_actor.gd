class_name FishActor
extends Node2D
## Un pez en la pecera: deambula, busca comida y se asusta. La lógica va en 2D; su cuerpo es un modelo
## 3D en el escenario de la pecera (TankView.stage), que gira con volumen al cambiar de sentido.

var data: Dictionary                 ## referencia al pez en Game.fish (se actualiza solo)
var tank: TankView
var model: MeshInstance3D
var yaw_wander := 0.0                ## leve giro hacia/desde el cristal mientras nada
var vel := Vector2.ZERO
var target := Vector2.ZERO
var depth := 0.0
var depth_target := 0.0
var facing := 1.0
var turn := 1.0
var phase := 0.0
var retarget := 0.0
var flee := 0.0
var heart := 0.0


func setup(f: Dictionary, t: TankView) -> void:
	data = f
	tank = t
	model = FishArt.model(f.genes)
	t.stage.add_child(model)
	tree_exiting.connect(model.queue_free)
	depth = randf() * 0.6
	depth_target = depth
	facing = 1.0 if randf() < 0.5 else -1.0
	turn = facing
	position = _random_point()
	target = _random_point()


func size_px() -> Vector2:
	return FishArt.size_px(data.genes, data.grow) * (1.0 - depth * 0.22)


func _process(dt: float) -> void:
	var sp: Dictionary = Catalog.SPECIES[data.genes.sp]
	var hp: float = data.health
	var speed: float = sp.speed * (0.55 + 0.45 * hp / 100.0) * (0.75 + 0.25 * data.grow)
	retarget -= dt
	flee = maxf(0.0, flee - dt)
	heart = maxf(0.0, heart - dt)

	var chasing := false
	if data.hunger > 10.0 and flee <= 0.0:
		var food := tank.food.nearest(position, sp.diet)
		if food != null:
			chasing = true
			target = food.pos
			speed *= 1.7
			if position.distance_to(food.pos) < maxf(9.0, size_px().x * 0.32):
				tank.food.eat(food)
				Game.fish_ate(data.id, food.type)
				Sfx.play("bubble", 140, -12.0)
				tank.overlay.burst(position + Vector2(size_px().x * 0.4 * facing, 0), "bubble", 2)
				if food.type == "artemia":
					heart = 1.6
	if not chasing and (retarget <= 0.0 or position.distance_to(target) < 18.0):
		target = _random_point()
		retarget = randf_range(2.5, 7.0)
		depth_target = clampf(depth_target + randf_range(-0.3, 0.3), 0.0, 0.65)
	if flee > 0.0:
		speed *= 2.6

	var desired := (target - position).limit_length(1.0) * speed
	if position.distance_to(target) > 30.0:
		desired = (target - position).normalized() * speed
	vel = vel.lerp(desired, 1.0 - exp(-dt * (4.0 if flee > 0.0 else 1.6)))
	position += vel * dt
	var r := tank.swim_rect(data.genes)
	position = tank.fit(position.clamp(r.position, r.end), size_px() * 0.5)

	if absf(vel.x) > 5.0:
		facing = signf(vel.x)
	turn = move_toward(turn, facing, dt * 3.2)
	if retarget > 6.5 or randf() < dt * 0.2:
		yaw_wander = randf_range(-0.35, 0.35)
	depth = move_toward(depth, depth_target, dt * 0.05)
	phase += dt * (3.5 + vel.length() * 0.09)
	# Cuerpo 3D: girar es rotar sobre el eje vertical (se ve de frente a media vuelta); inclinarse, cabecear.
	var sz := FishArt.size_px(data.genes, data.grow).x * 0.5 * (1.0 - depth * 0.22)
	var yaw := acos(clampf(turn, -1.0, 1.0)) + yaw_wander * absf(turn)
	var pitch := clampf(atan2(-vel.y, absf(vel.x) + 20.0) * 0.6, -0.45, 0.45)
	model.transform = Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, pitch) * Basis.from_scale(Vector3.ONE * sz),
		FishStage.to3d(position, -depth * 120.0))
	FishArt.set_param(model, "phase", phase)
	FishArt.set_param(model, "depth", depth)
	FishArt.set_param(model, "sick", clampf((50.0 - hp) / 40.0, 0.0, 1.0))


## Huida al tocar el agua cerca.
func startle(from: Vector2) -> void:
	var away := (position - from).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT.rotated(randf() * TAU)
	target = position + away * randf_range(120.0, 200.0)
	flee = 0.8
	retarget = 1.2


func _random_point() -> Vector2:
	var r := tank.swim_rect(data.genes)
	var zone: String = Catalog.SPECIES[data.genes.sp].zone
	var x := randf_range(r.position.x, r.end.x)
	var half := FishArt.size_px(data.genes, data.grow) * 0.5
	match zone:
		"bottom": return tank.fit(Vector2(x, maxf(r.end.y, tank.surface_y(x)) - randf() * 18.0), half)
		"top": return tank.fit(Vector2(x, lerpf(r.position.y, r.end.y, randf() * 0.45)), half)
	return tank.fit(Vector2(x, lerpf(r.position.y, r.end.y, randf_range(0.05, 0.9))), half)
