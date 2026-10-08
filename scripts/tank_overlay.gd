class_name TankOverlay
extends Node2D
## Efectos ligeros dibujados a mano: ondas, burbujitas, corazones, destellos,
## bocadillos de hambre/enfermedad, la esponja de limpieza y el pez seleccionado.

var tank: TankView
var parts: Array = []                ## [pos, vel, life, max_life, kind, size]
var ripples: Array = []              ## [pos, age]
var sponge_pos := Vector2(-999, -999)
var sponge_t := 0.0
var selected_id := -1


func ripple(p: Vector2) -> void:
	ripples.append([p, 0.0])


func burst(p: Vector2, kind: String, n: int) -> void:
	for i in n:
		var v := Vector2(randf_range(-14, 14), randf_range(-40, -20))
		if kind == "sparkle":
			v = Vector2.from_angle(randf() * TAU) * randf_range(20, 60)
		parts.append([p + Vector2(randf_range(-6, 6), randf_range(-4, 4)), v, 0.0, randf_range(0.7, 1.3), kind, randf_range(2.0, 4.5)])


func _process(dt: float) -> void:
	for i in range(parts.size() - 1, -1, -1):
		var p: Array = parts[i]
		p[2] += dt
		if p[2] >= p[3]:
			parts.remove_at(i)
			continue
		p[0] += p[1] * dt
		if p[4] == "bubble":
			p[1].x = sin(p[2] * 8.0) * 10.0
		else:
			p[1] *= 1.0 - dt * 2.0
	for i in range(ripples.size() - 1, -1, -1):
		ripples[i][1] += dt
		if ripples[i][1] > 0.8:
			ripples.remove_at(i)
	sponge_t = maxf(0.0, sponge_t - dt)
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for a in tank.actors.values():
		var f: Dictionary = a.data
		var top: Vector2 = a.position + Vector2(0, -a.size_px().y * 0.75 - 14)
		if f.id == selected_id:
			draw_arc(a.position, a.size_px().x * 0.62, 0, TAU, 40, Color(1, 1, 1, 0.55 + 0.25 * sin(t * 4.0)), 2.5, true)
		if a.heart > 0.0:
			_heart(top + Vector2(0, -6 * (1.6 - a.heart)), 7.0, Color(1.0, 0.4, 0.55, minf(1.0, a.heart)))
		elif f.hunger > 60.0:
			_bubble(top + Vector2(0, sin(t * 2.0 + f.id) * 2.0), "food")
		elif f.health < 40.0:
			_bubble(top + Vector2(0, sin(t * 2.0 + f.id) * 2.0), "sick")
	for r in ripples:
		var k: float = r[1] / 0.8
		draw_arc(r[0], 6.0 + k * 34.0, PI * 0.05, PI * 0.95, 20, Color(1, 1, 1, 0.6 * (1.0 - k)), 2.0, true)
	for p in parts:
		var life: float = 1.0 - p[2] / p[3]
		match p[4]:
			"bubble":
				draw_arc(p[0], p[5], 0, TAU, 16, Color(0.9, 1, 1, 0.75 * life), 1.2, true)
				draw_circle(p[0] + Vector2(-p[5] * 0.35, -p[5] * 0.35), p[5] * 0.28, Color(1, 1, 1, 0.8 * life))
			"heart":
				_heart(p[0], p[5] * 1.6, Color(1.0, 0.45, 0.6, life))
			"sparkle":
				_star(p[0], p[5] * 1.8 * life + 1.0, Color(1, 1, 0.9, life))
	if sponge_t > 0.0:
		_sponge(sponge_pos, minf(1.0, sponge_t * 3.0))


func _bubble(p: Vector2, kind: String) -> void:
	draw_circle(p, 12.0, Color(1, 1, 1, 0.92))
	draw_circle(p + Vector2(-7, 11), 3.0, Color(1, 1, 1, 0.92))
	if kind == "food":
		for k in 3:
			draw_circle(p + Vector2(-5 + k * 5, 1 - (k % 2) * 3), 2.4, Color(1.0, 0.55, 0.2))
	else:
		draw_rect(Rect2(p + Vector2(-2, -7), Vector2(4, 14)), Color(0.95, 0.3, 0.35))
		draw_rect(Rect2(p + Vector2(-7, -2), Vector2(14, 4)), Color(0.95, 0.3, 0.35))


func _heart(p: Vector2, s: float, c: Color) -> void:
	draw_circle(p + Vector2(-s * 0.5, 0), s * 0.55, c)
	draw_circle(p + Vector2(s * 0.5, 0), s * 0.55, c)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 1.02, s * 0.15), p + Vector2(s * 1.02, s * 0.15), p + Vector2(0, s * 1.2)]), c)


func _star(p: Vector2, s: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		pts.append(p + Vector2.from_angle(i * PI / 4.0) * (s if i % 2 == 0 else s * 0.3))
	draw_colored_polygon(pts, c)


func _sponge(p: Vector2, a: float) -> void:
	var r := Rect2(p - Vector2(30, 20), Vector2(60, 40))
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.2 * a))
	draw_rect(r, Color(1.0, 0.84, 0.3, a))
	draw_rect(Rect2(r.position, Vector2(60, 12)), Color(0.35, 0.75, 0.45, a))
	for h in [Vector2(-14, 4), Vector2(4, 10), Vector2(16, 2), Vector2(-4, 14)]:
		draw_circle(p + h, 3.0, Color(0.85, 0.65, 0.2, a))
