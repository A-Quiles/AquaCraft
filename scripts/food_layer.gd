class_name FoodLayer
extends Node2D
## Comida que cae, se posa en el fondo y, si nadie la come, se pudre (ensucia el agua).
## Todo se dibuja en un único _draw.

const ROT_TIME := 22.0

class Flake:
	var pos: Vector2
	var vel: Vector2
	var type: String
	var rot: float
	var age := 0.0
	var landed := -1.0
	var col: Color

var tank: TankView
var flakes: Array[Flake] = []


func drop(x: float, type: String) -> void:
	var n := 3 if type == "escamas" else 2
	var base: Color = Catalog.color(Catalog.FOODS[type].col)
	for i in n:
		var f := Flake.new()
		f.pos = Vector2(x + randf_range(-26.0, 26.0), randf_range(6.0, 16.0))
		f.vel = Vector2(randf_range(-6.0, 6.0), randf_range(14.0, 24.0))
		f.type = type
		f.rot = randf() * TAU
		f.col = base.lerp(Color(1.0, 0.85, 0.4), randf() * 0.35) if type == "escamas" else base
		flakes.append(f)
	tank.overlay.ripple(Vector2(x, 10.0))


func nearest(p: Vector2) -> Flake:
	var best: Flake = null
	var bd := INF
	for f in flakes:
		var d := p.distance_squared_to(f.pos)
		if d < bd:
			bd = d
			best = f
	return best


func eat(f: Flake) -> void:
	flakes.erase(f)


func _process(dt: float) -> void:
	if flakes.is_empty():
		return
	var rotted := 0
	for i in range(flakes.size() - 1, -1, -1):
		var f := flakes[i]
		f.age += dt
		if f.landed < 0.0:
			var sink := 46.0 if f.type == "granulos" else (20.0 if f.type == "artemia" else 26.0)
			f.vel.y = move_toward(f.vel.y, sink, dt * 20.0)
			f.vel.x = sin(f.age * 2.3 + f.rot) * 12.0
			f.pos += f.vel * dt
			f.rot += dt * 1.5
			var floor_y := tank.surface_y(f.pos.x) - 3.0
			if f.pos.y >= floor_y:
				f.pos.y = floor_y
				f.landed = f.age
		elif f.age - f.landed > ROT_TIME:
			flakes.remove_at(i)
			rotted += 1
	for i in rotted:
		Game.food_rotted()
	queue_redraw()


func _draw() -> void:
	for f in flakes:
		var fade := 1.0
		if f.landed >= 0.0:
			fade = clampf(1.0 - (f.age - f.landed - ROT_TIME + 5.0) / 5.0, 0.0, 1.0)
		var c := f.col
		c.a = fade
		match f.type:
			"granulos":
				draw_circle(f.pos, 4.0, c.darkened(0.25))
				draw_circle(f.pos + Vector2(-1, -1), 2.6, c)
			"artemia":
				var d := Vector2.from_angle(f.rot) * 3.5
				draw_line(f.pos - d, f.pos + d, c, 2.4, true)
				draw_circle(f.pos + d, 1.6, c.lightened(0.2))
			_:
				var pts := PackedVector2Array()
				for k in 4:
					pts.append(f.pos + Vector2.from_angle(f.rot + k * PI * 0.5 + (0.3 if k % 2 == 0 else 0.0)) * (4.5 if k % 2 == 0 else 3.0))
				draw_colored_polygon(pts, c)
