extends SceneTree
## Comprobaciones rápidas del núcleo (sin gráficos):
##   godot --headless -s tests/test_core.gd

var fails := 0


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# Genética: genes válidos, rareza coherente, herencia de mutaciones.
	for sp in Catalog.SPECIES_ORDER:
		var g := Genetics.random_genes(sp, rng)
		check(Genetics.rarity(g) == 0, "%s aleatorio debería ser común" % sp)
		var m := Genetics.random_genes(sp, rng, 2)
		check(Genetics.rarity(m) >= 2, "%s con 2 mutaciones debería ser raro+" % sp)
	var p := Genetics.random_genes("guppy", rng)
	var q := Genetics.random_genes("guppy", rng)
	p.neon = true
	q.neon = true
	var neon_kids := 0
	for i in 400:
		if Genetics.breed(p, q, rng, 0.0).neon:
			neon_kids += 1
	check(neon_kids > 280 and neon_kids < 360, "dos padres neón → ~80%% hijos neón (%d/400)" % neon_kids)
	var mixed := Genetics.breed(p, q, rng, 1.0)
	check(Genetics.rarity(mixed) >= 2, "mutación forzada suma rareza")
	var json_g = JSON.parse_string(JSON.stringify(mixed))
	check(Genetics.variant_key(Genetics.normalize(json_g)) == Genetics.variant_key(mixed), "genes sobreviven a JSON")

	# Valor: un adulto raro vale más que un alevín común.
	var common := {"genes": Genetics.random_genes("betta", rng), "grow": 0.1, "health": 100.0}
	var rare := {"genes": Genetics.random_genes("betta", rng, 3), "grow": 1.0, "health": 100.0}
	check(Genetics.value(rare) > Genetics.value(common) * 10, "precio escala con rareza y edad")

	# Simulación: partida nueva, 8 h fuera, sin muertes y con hambre.
	var game: Node = load("res://scripts/game.gd").new()
	game._build_weights()
	game.new_game()
	game._refresh_water()
	check(game.fish.size() == 3, "partida nueva con 3 peces")
	game.last_sim -= 8 * 3600.0
	var t0 := Time.get_ticks_msec()
	game._catch_up(8 * 3600.0)
	var ms := Time.get_ticks_msec() - t0
	check(ms < 1500, "8 h offline en %d ms" % ms)
	for f in game.fish:
		check(f.hunger > 90.0, "tras 8 h tienen hambre (%.0f)" % f.hunger)
		check(f.health >= 25.0, "nadie baja del 25%% offline (%.0f)" % f.health)
	check(game.water().dirt > 30.0 and game.water().dirt < 90.0, "las algas crecen poco a poco offline (%.0f%%)" % game.water().dirt)

	# Limpiar y alimentar.
	var before: float = game.water().dirt
	for x in 20:
		for y in 30:
			game.clean_at(Vector2(x / 20.0, y / 30.0))
	game._refresh_water()
	check(game.water().dirt < before * 0.3, "limpiar quita algas (%.0f → %.0f)" % [before, game.water().dirt])
	var f0: Dictionary = game.fish[0]
	var h: float = f0.hunger
	game.fish_ate(f0.id, "escamas")
	check(f0.hunger < h, "comer quita hambre")

	# Cría y eclosión.
	var a: Dictionary = game.fish[0]
	var b: Dictionary = game.fish[1]
	for f in [a, b]:
		f.health = 100.0
		f.happy = 90.0
	check(game.breed(a.id, b.id), "dos guppies adultos pueden criar")
	check(game.eggs.size() == 1, "hay un huevo")
	check(not game.breed(a.id, b.id), "cooldown impide criar de nuevo")
	game._sim(1.0, game.eggs[0].hatch_at + 1.0)
	check(game.eggs.is_empty() and game.fish.size() == 4, "el huevo eclosiona en un pez")

	# Tienda y guardado.
	game.coins = 10000
	game.buy_equipment("esponja")
	check(game.equipment.filter == "esponja", "filtro instalado")
	game.buy_tank(1)
	check(game.tank_tier == 1 and game.capacity() == 10, "pecera ampliada")
	game.buy_decor("cueva")
	check(game.decor.any(func(d): return d.id == "cueva"), "decoración colocada")
	var n: int = game.decor.size()
	game.store_decor(n - 1)
	check(game.decor.size() == n - 1 and game.decor_inv.get("cueva", 0) == 1, "guardar en inventario")
	check(game.place_decor("cueva") and game.decor_inv.is_empty(), "colocar desde inventario")
	game.move_decor(0, 2.0)
	check(game.decor[0].x <= 0.97, "mover se queda dentro del cristal")

	# Mantenimiento: el filtro se desgasta con el tiempo y rinde menos.
	game.equip_cond.filter = 100.0
	game._wear(30 * 3600.0)
	check(game.condition("filter") < 30.0, "el filtro se ensucia (%.0f%%)" % game.condition("filter"))
	check(game.efficiency("filter") < 0.5, "filtro sucio rinde menos")
	check(game.needs_maintenance().has("filter"), "aviso de mantenimiento")
	game.maintain("filter")
	check(game.condition("filter") == 100.0 and game.efficiency("filter") == 1.0, "mantenimiento lo deja nuevo")
	game.equipment.thermo = ""
	check(game.thermometer_text() == "", "sin termómetro no hay temperatura")
	check(game.daily.missions.size() == 3, "3 misiones diarias")
	game.free()

	print("TESTS: %s" % ("OK" if fails == 0 else "%d FALLOS" % fails))
	quit(1 if fails > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		printerr("FALLO: " + what)
