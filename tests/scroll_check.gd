extends SceneTree
## Arrastrar sobre una tarjeta (o un botón) de la tienda debe desplazar la lista y no comprar nada.
##   (necesita pantalla: en headless Godot no enruta el ratón a la interfaz)
##   xvfb-run godot --resolution 720x1280 -s tests/scroll_check.gd -- demo=1

var main: Node
var step := 0
var sc: ScrollContainer
var coins := 0
var start := Vector2.ZERO
var t0 := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_dt: float) -> bool:
	var game: Node = root.get_node("Game")
	if step >= 5 and step < 39 and Time.get_ticks_msec() - t0 < 1200:
		return false
	step += 1
	if step == 5:
		game.coins = 99999
		game.level = 10
		main.hud.open_shop(1)
		t0 = Time.get_ticks_msec()
	elif step == 40:
		sc = main.hud._sheet.find_children("*", "ScrollContainer", true, false)[0]
		coins = game.coins
		# Empieza encima del primer botón de compra que haya dentro de la lista.
		var b: Control = sc.find_children("*", "Button", true, false)[0]
		start = b.get_global_rect().get_center()
		_touch(start, true)
	elif step > 40 and step < 60:
		var d := InputEventMouseMotion.new()
		d.position = start + Vector2(0, -(step - 40) * 20.0)
		d.global_position = d.position
		d.relative = Vector2(0, -20)
		d.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(d)
	elif step == 60:
		_touch(start + Vector2(0, -400), false)
	elif step == 70:
		var ok: bool = sc.scroll_vertical > 50 and game.coins == coins
		print("SCROLL: %s  scroll=%d  gasto=%d" % ["OK" if ok else "FALLO", sc.scroll_vertical, coins - game.coins])
		quit(0 if ok else 1)
	return false


func _touch(p: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.position = p
	e.global_position = p
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	root.push_input(e)
