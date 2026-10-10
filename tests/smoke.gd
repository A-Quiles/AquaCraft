extends SceneTree
## Prueba de humo de la interfaz: abre todas las pantallas, compra, cría, vende y toca el agua.
##   godot --headless -s tests/smoke.gd -- demo=1
## Falla si aparece cualquier error de script (los muestra Godot por stderr).

var main: Node
var step := 0
var wait := 0.0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(delta: float) -> bool:
	wait -= delta
	if wait > 0.0:
		return false
	wait = 0.25
	var hud = main.hud
	var game: Node = root.get_node("Game")
	match step:
		0:
			game.coins = 99999
			game.pearls = 999
			game.level = 10
			for t in 5:
				hud.open_shop(t)
		1:
			var shop = hud._sheet
			game.buy_fish("guppy")
			game.buy_equipment("calentador")
			game.buy_decor("musgo")
			game.buy_substrate("pastel")
			game.buy_food("artemia")
			game.buy_offer(0)
			game.buy_tank(2)
			shop._build()
		2:
			hud.open_fish(-1)
			var fs = hud._sheet
			var a: Dictionary = game.fish[0]
			fs._show_detail(a.id)
			fs._show_partners(a.id)
			for f in game.fish:
				f.health = 100.0
				f.happy = 100.0
				f.grow = 1.0
				f.cd = 0.0
			var partners: Array = game.breed_partners(a)
			if not partners.is_empty():
				game.breed(a.id, partners[0].id)
			fs.tab = 1
			fs._show_list()
		3:
			if not game.eggs.is_empty():
				game.hatch_now(game.eggs[0].id)
			game.sell_fish(game.fish[-1].id)
			hud.open_missions()
			game.claim_story()
		4:
			hud.open_thermostat()
			hud.back()
			hud.back()
			_touch(main.tank.size * 0.5, true)
			_touch(main.tank.size * 0.5, false)
			main.set_mode(main.Mode.FEED)
			_touch(main.tank.size * 0.4, true)
			main.set_mode(main.Mode.CLEAN)
			_touch(main.tank.size * 0.3, true)
			var drag := InputEventScreenDrag.new()
			drag.position = main.tank.to_global(main.tank.size * 0.6)
			Input.parse_input_event(drag)
		5:
			main.set_mode(main.Mode.CLEAN)
			hud.open_equipment("filter")
			hud.open_equipment("light")
			main.set_mode(main.Mode.EDIT)
			var r: Rect2 = main.tank.decor_rect(0)
			_touch(r.get_center(), true)
			var drag := InputEventScreenDrag.new()
			drag.position = main.tank.to_global(r.get_center() + Vector2(60, 0))
			Input.parse_input_event(drag)
			_touch(r.get_center() + Vector2(60, 0), false)
		6:
			main.set_sculpt(true)
			_touch(main.tank.size * Vector2(0.4, 0.85), true)
			var sd := InputEventScreenDrag.new()
			sd.position = main.tank.to_global(main.tank.size * Vector2(0.4, 0.6))
			Input.parse_input_event(sd)
			_touch(main.tank.size * Vector2(0.4, 0.6), false)
			main.flatten_terrain()
			main.set_mode(main.Mode.EDIT)
			hud.open_decor_menu(0)
			game.flip_decor(0)
			game.cycle_decor_layer(0)
			hud.start_tutorial()
		7:
			hud.open_setup()
			hud.open_mode_picker()
			hud.open_water_panel()
			hud.open_food_picker()
			main.use_prop("food")
			main.pick_food("artemia")
			main.use_prop("food")
			main.use_prop("water")
			main.use_prop("sponge")
			main.use_prop("siphon")
			_touch(main.tank.size * Vector2(0.5, 0.9), true)
			var vd := InputEventScreenDrag.new()
			vd.position = main.tank.to_global(main.tank.size * Vector2(0.6, 0.9))
			Input.parse_input_event(vd)
			_touch(main.tank.size * Vector2(0.6, 0.9), false)
			main.set_mode(main.Mode.VACUUM)
			game.show_names = true
			game.rename_fish(game.fish[0].id, "  Nemo  ")
			assert(game.fish[0].name == "Nemo")
			hud.open_equipment("filter")
			game.remove_equipment("filter")
			hud.open_equipment("filter")
			hud.open_fish(game.fish[0].id)
			hud._sheet._rename(game.fish[0].id)
			game.set_game_mode("realista")
			hud.open_shop(1)
			for i in 4:
				hud._tutorial._advance()
			game.save_game()
			print("SMOKE: OK  peces=%d huevos=%d nivel=%d" % [game.fish.size(), game.eggs.size(), game.level])
			return true
	step += 1
	return false


func _touch(local: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = main.tank.to_global(local)
	e.pressed = pressed
	Input.parse_input_event(e)
