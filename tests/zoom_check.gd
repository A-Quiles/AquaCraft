extends SceneTree
## Pellizcar con dos dedos acerca la pecera (con límite), un dedo la mueve y nada de eso abre fichas.
##   godot --headless --resolution 720x1280 -s tests/zoom_check.gd -- demo=1

var main: Node
var step := 0
var fails := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_dt: float) -> bool:
	step += 1
	var c: Vector2 = main.tank.global_position + main.tank.size * 0.5
	match step:
		5:
			_touch(0, c + Vector2(-40, 0), true)
			_touch(1, c + Vector2(40, 0), true)
			for i in 10:
				_drag(0, c + Vector2(-40 - i * 20, 0))
				_drag(1, c + Vector2(40 + i * 20, 0))
		6:
			_check(main.cam.zoom.x > 2.0, "pellizcar acerca (%.2f)" % main.cam.zoom.x)
			for i in 40:
				_drag(0, c + Vector2(-600 - i * 40, 0))
				_drag(1, c + Vector2(600 + i * 40, 0))
		7:
			_check(main.cam.zoom.x <= main.ZOOM_MAX + 0.001, "el zoom tiene límite (%.2f)" % main.cam.zoom.x)
			_touch(1, c, false)
			_touch(0, c, false)
		8:
			_check(main.hud._sheet == null, "soltar tras pellizcar no abre nada")
			set_meta("before", main.cam.position)
			_touch(0, c, true)
			for i in 10:
				_drag(0, c + Vector2(i * 15, 0))
			_touch(0, c + Vector2(150, 0), false)
		9:
			_check(main.cam.position.x < (get_meta("before") as Vector2).x - 20.0, "un dedo mueve la pecera acercada")
			_check(main.hud._sheet == null, "arrastrar no abre fichas")
			var vp: Vector2 = main.get_viewport_rect().size
			var half: Vector2 = vp * 0.5 / main.cam.zoom.x
			_check(main.cam.position.x >= half.x - 0.01 and main.cam.position.x <= vp.x - half.x + 0.01, "la cámara no se sale de la pantalla")
			_touch(0, c, true)
			_touch(1, c + Vector2(400, 0), true)
			for i in 20:
				_drag(1, c + Vector2(400 - i * 20, 0))
			_touch(1, c, false)
			_touch(0, c, false)
		10:
			_check(is_equal_approx(main.cam.zoom.x, 1.0), "alejar vuelve al tamaño normal")
			print("ZOOM: %s" % ("OK" if fails == 0 else "%d FALLOS" % fails))
			quit(1 if fails > 0 else 0)
	return false


func _touch(i: int, p: Vector2, pressed: bool) -> void:
	_last[i] = p
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = p
	e.pressed = pressed
	Input.parse_input_event(e)


var _last := {}


func _drag(i: int, p: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = i
	e.relative = p - _last.get(i, p)   # los eventos se procesan al final del frame: llevamos la cuenta aquí
	_last[i] = p
	e.position = p
	Input.parse_input_event(e)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		printerr("FALLO: " + what)
