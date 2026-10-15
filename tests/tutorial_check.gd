extends SceneTree
## El pedido guiado del tutorial se puede hacer de principio a fin y los avisos quedan por encima de todo.
##   godot --headless --resolution 720x1280 -s tests/tutorial_check.gd -- demo=0

var main: Node
var hud: Node
var game: Node
var step := 0
var fails := 0
var order_step := -1


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_dt: float) -> bool:
	step += 1
	match step:
		5:
			hud = main.hud
			game = root.get_node("Game")
			var steps: Array = load("res://scripts/ui/tutorial.gd").STEPS
			for i in steps.size():
				if steps[i].wait == "orders_open":
					order_step = i
			hud.start_tutorial()
		6:
			var t = hud._tutorial
			while t.step < order_step:
				t._advance()
			_check(t.step == order_step, "el tutorial llega al paso del primer pedido")
			_check(t._text.text.contains("Sra. Pilar"), "el paso nombra al cliente")
			_check(hud._toast_box.get_parent().layer > t.get_parent().layer, "los avisos van por encima del tutorial")
			hud.open_missions()
		8:
			var t = hud._tutorial
			_check(hud._sheet.tab == 1, "abrir Misiones lleva a la pestaña de pedidos")
			_check(t.STEPS[t.step].wait == "order_done", "el tutorial pide entregar el pez")
			var o: Dictionary = game.tutorial_order()
			var cands: Array = game.fish.filter(func(f): return game.order_matches(o, f))
			_check(cands.size() == 1, "hay justo un pez que encaja (el que está solo)")
			hud._sheet._pick_for_order(o, cands)
		9:
			_check(not hud._tutorial._card.visible, "la tarjeta del tutorial se aparta mientras hay una ventana")
			hud._modal.close()
			var o: Dictionary = game.tutorial_order()
			game.deliver_order(int(o.id), int(game.fish.filter(func(f): return game.order_matches(o, f))[0].id))
		11:
			var t = hud._tutorial
			_check(t.STEPS[t.step].wait != "order_done", "entregar el pedido avanza el tutorial")
			_check(game.tutorial_order().is_empty(), "el pedido guiado ya no está")
			print("TUTORIAL: %s" % ("OK" if fails == 0 else "%d FALLOS" % fails))
			quit(1 if fails > 0 else 0)
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		printerr("FALLO: " + what)
