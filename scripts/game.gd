extends Node
## Autoload "Game": estado, simulación (también offline), economía, misiones y guardado.
## La parte visual solo lee este estado y le avisa de acciones (comer, limpiar...).

signal changed                       ## refresco general del HUD (1 vez por segundo y tras acciones)
signal toast(text: String, icon: String)
signal fish_added(fish: Dictionary)
signal fish_removed(id: int)
signal eggs_changed
signal tank_changed                  ## pecera, decoración, sustrato o equipo
signal algae_changed
signal level_up(level: int)

var save_path := "user://save.json"   ## demo usa otro fichero para no pisar la partida
const SAVE_VERSION := 1
const GW := 40                       ## rejilla de algas del cristal
const GH := 60
const ROOM_TEMP := 23.0
const HUNGER_PER_MIN := 0.21         ## 0 → 100 en ~8 h
const MAX_OFFLINE := 48.0 * 3600.0
const OFFLINE_STEP := 300.0

var coins := 250
var pearls := 5
var level := 1
var xp := 0
var tank_tier := 0
var equipment := {"filter": "", "heater": "", "pump": "", "light": ""}
var heater_target := 25.0
var water_temp := ROOM_TEMP
var substrate := "grava"
var owned_substrates: Array = ["grava"]
var decor: Array = []
var food := {"granulos": 5, "artemia": 3}
var fish: Array = []
var eggs: Array = []
var algae := PackedByteArray()
var stats := {}
var discovered := {}
var daily := {}
var story_idx := 0
var next_id := 1
var last_sim := 0.0
var started := false                 ## false hasta cerrar la bienvenida

var rng := RandomNumberGenerator.new()
var _weights := PackedFloat32Array()
var _acc := 0.0
var _dirty := false
var _save_acc := 0.0
var _offline_floor := false
var _cache := {}                     ## parámetros del agua del último tick


func _ready() -> void:
	rng.randomize()
	_build_weights()
	var demo := _arg("demo")
	if demo != "":
		save_path = "user://demo.json"
		_demo(int(demo))
	elif not load_game():
		new_game()
	_refresh_water()


## Argumentos tras "--" (p. ej. `-- demo=2 shot=out.png`).
func _arg(key: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return ""


## Pecera de exposición para capturas de la ficha de Google Play (no toca la partida real).
func _demo(tier: int) -> void:
	new_game()
	tank_tier = clampi(tier, 0, 3)
	level = [3, 5, 7, 10][tank_tier]
	coins = 4820
	pearls = 37
	xp = int(xp_need(level) * 0.6)
	equipment = {"filter": "canister", "heater": "calentador", "pump": "bomba", "light": "led_pro"}
	heater_target = 26.0
	water_temp = 26.0
	substrate = ["arena", "grava", "arena", "negra"][tank_tier]
	decor = [["vallisneria", "cofre", "rocas"], ["vallisneria", "rotala", "castillo", "helecho", "rocas"],
		["vallisneria", "rotala", "barco", "anubias", "cofre", "musgo", "helecho"],
		["vallisneria", "rotala", "barco", "anubias", "coral", "helecho", "tronco", "castillo", "musgo"]][tank_tier]
	fish = []
	var r := RandomNumberGenerator.new()
	r.seed = 11 + tier
	var pool := [["guppy", 0], ["guppy", 1], ["neon", 0], ["neon", 0], ["betta", 1], ["goldfish", 0],
		["rainbow", 0], ["angelfish", 0], ["discus", 1], ["molly", 0], ["corydoras", 0], ["discus", 0],
		["rainbow", 1], ["betta", 2], ["goldfish", 1], ["angelfish", 1]]
	for i in [5, 9, 14, 16][tank_tier]:
		var f := _add_fish(Genetics.random_genes(pool[i][0], r, pool[i][1]), 1.0, i % 3 == 0)
		f.hunger = 20.0 if i != 2 else 75.0
	for i in algae.size():
		algae[i] = int(_weights[i] * 10.0)
	daily = {}
	_check_daily()
	started = true
	last_sim = Time.get_unix_time_from_system()


func _process(delta: float) -> void:
	_acc += delta
	if _acc < 1.0:
		return
	_acc = 0.0
	var now := Time.get_unix_time_from_system()
	var gap := now - last_sim
	if gap > 60.0:
		_catch_up(gap)                 # volvió de segundo plano
	elif gap > 0.0:
		_sim(gap, now)
		_grow_algae(gap)
	last_sim = now
	_check_daily()
	_safety_net()
	changed.emit()
	_save_acc += 1.0
	if _dirty and _save_acc >= 20.0:
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


# ───────────────────────── Partida nueva / guardado ─────────────────────────

func new_game() -> void:
	coins = 250
	pearls = 5
	level = 1
	xp = 0
	tank_tier = 0
	equipment = {"filter": "", "heater": "", "pump": "", "light": ""}
	substrate = "grava"
	owned_substrates = ["grava"]
	decor = ["vallisneria", "rocas"]
	food = {"granulos": 5, "artemia": 3}
	fish = []
	eggs = []
	stats = {}
	discovered = {}
	story_idx = 0
	started = false
	algae = PackedByteArray()
	algae.resize(GW * GH)
	for i in algae.size():
		algae[i] = int(clampf(_weights[i] * 40.0, 0.0, 255.0))
	for sp in ["guppy", "guppy", "neon"]:
		_add_fish(Genetics.random_genes(sp, rng), 1.0, false)
	last_sim = Time.get_unix_time_from_system()
	daily = {}
	_check_daily()
	_dirty = true


func save_game() -> void:
	_save_acc = 0.0
	var data := {
		"v": SAVE_VERSION, "coins": coins, "pearls": pearls, "level": level, "xp": xp,
		"tank_tier": tank_tier, "equipment": equipment, "heater_target": heater_target,
		"water_temp": water_temp, "substrate": substrate, "owned_substrates": owned_substrates,
		"decor": decor, "food": food, "fish": fish, "eggs": eggs,
		"algae": Marshalls.raw_to_base64(algae), "stats": stats, "discovered": discovered,
		"daily": daily, "story_idx": story_idx, "next_id": next_id, "last_sim": last_sim,
		"started": started,
	}
	# Escritura atómica: si la app muere a mitad, el guardado anterior sigue intacto.
	var tmp := save_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo guardar: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data))
	f.close()
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(save_path))
	if err != OK:
		push_error("No se pudo renombrar el guardado: %s" % err)
		return
	_dirty = false


func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var text := FileAccess.get_file_as_string(save_path)
	var d = JSON.parse_string(text)
	if typeof(d) != TYPE_DICTIONARY or not d.has("fish"):
		# Guardado corrupto: lo apartamos en vez de borrarlo.
		DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(save_path + ".bad"))
		return false
	coins = int(d.coins)
	pearls = int(d.pearls)
	level = int(d.level)
	xp = int(d.xp)
	tank_tier = int(d.tank_tier)
	equipment = d.equipment
	heater_target = float(d.heater_target)
	water_temp = float(d.water_temp)
	substrate = d.substrate
	owned_substrates = d.owned_substrates
	decor = d.decor
	food = d.food
	for k in food:
		food[k] = int(food[k])
	stats = d.stats
	discovered = d.discovered
	daily = d.daily
	story_idx = int(d.story_idx)
	next_id = int(d.next_id)
	last_sim = float(d.last_sim)
	started = bool(d.get("started", true))
	algae = Marshalls.base64_to_raw(d.algae)
	if algae.size() != GW * GH:
		algae.resize(GW * GH)
	fish = d.fish
	for f in fish:
		f.id = int(f.id)
		Genetics.normalize(f.genes)
	eggs = d.eggs
	for e in eggs:
		e.id = int(e.id)
		Genetics.normalize(e.genes)
	_refresh_water()
	var gap := Time.get_unix_time_from_system() - last_sim
	if gap > 5.0:
		_catch_up(gap)
	last_sim = Time.get_unix_time_from_system()
	return true


func reset_game() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	new_game()
	_refresh_water()
	tank_changed.emit()
	eggs_changed.emit()
	algae_changed.emit()
	changed.emit()


# ───────────────────────── Simulación ─────────────────────────

## Tiempo transcurrido con la app cerrada: se simula en bloques de 5 min.
## Los peces nunca bajan del 25% de salud estando fuera (juego cozy, sin muertes).
func _catch_up(gap: float) -> void:
	gap = clampf(gap, 0.0, MAX_OFFLINE)
	var hatched_before := int(stats.get("hatched", 0))
	_offline_floor = true
	var t := last_sim
	var remaining := gap
	var pending_algae := 0.0
	while remaining > 0.0:
		var step := minf(OFFLINE_STEP, remaining)
		t += step
		remaining -= step
		pending_algae += step
		if pending_algae >= 3600.0 or remaining <= 0.0:
			_grow_algae(pending_algae)          # las algas cuestan más: por horas
			pending_algae = 0.0
			_refresh_water()
		_sim(step, t)
	_offline_floor = false
	var hatched := int(stats.get("hatched", 0)) - hatched_before
	if gap > 600.0:
		var msg := "Volviste tras %s." % fmt_duration(gap)
		if hatched > 0:
			msg += " ¡%d huevo%s eclosionaron!" % [hatched, "s" if hatched > 1 else ""]
		toast.emit.call_deferred(msg, "clock")


func _sim(dt: float, now: float) -> void:
	var m := dt / 60.0
	if not _offline_floor:
		_refresh_water()
	var temp_target := heater_target if equipment.heater != "" else ROOM_TEMP
	water_temp = move_toward(water_temp, temp_target, 0.6 * m)
	var w: Dictionary = _cache
	var floor_hp := 25.0 if _offline_floor else 5.0
	for f in fish:
		var s: Dictionary = Catalog.SPECIES[f.genes.sp]
		f.hunger = minf(100.0, f.hunger + HUNGER_PER_MIN * m)
		var problems := 0
		if f.hunger > 70.0: problems += 1
		if water_temp < s.temp[0] - 0.5 or water_temp > s.temp[1] + 0.5: problems += 1
		if w.ph < s.ph[0] - 0.2 or w.ph > s.ph[1] + 0.2: problems += 1
		if w.o2 < 55.0: problems += 1
		if w.dirt > 70.0: problems += 1
		f.problems = problems
		var hp_delta := 0.6 if problems == 0 else -0.3 * problems
		f.health = clampf(f.health + hp_delta * m, minf(floor_hp, f.health), 100.0)
		var happy_target := clampf(45.0 + w.decor_happy + (10.0 if f.hunger < 40.0 else 0.0) - 12.0 * problems, 0.0, 100.0)
		f.happy = move_toward(f.happy, happy_target, 1.5 * m)
		if f.grow < 1.0:
			var speed := 1.0 if f.health > 40.0 else 0.3
			f.grow = minf(1.0, f.grow + dt / float(s.grow) * speed)
	var hatched := false
	for e in eggs.duplicate():
		if now >= e.hatch_at:
			_hatch(e)
			hatched = true
	if hatched:
		eggs_changed.emit()
	_dirty = true


func _grow_algae(dt: float) -> void:
	var w: Dictionary = _cache
	var per_min: float = (0.15 + 0.25 * w.load) * (1.0 - w.filter) * (1.0 - w.plant_clean)
	var add := per_min * dt / 60.0 * 2.55          # bytes por celda (peso medio 1)
	if add <= 0.0:
		return
	for i in algae.size():
		var v := add * _weights[i]
		# Redondeo estocástico para que el crecimiento lento no se pierda.
		var n := int(v) + (1 if rng.randf() < v - floorf(v) else 0)
		algae[i] = mini(255, algae[i] + n)
	algae_changed.emit()


func _build_weights() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.09
	_weights.resize(GW * GH)
	for y in GH:
		for x in GW:
			var edge := 1.0 - minf(minf(x, GW - 1 - x), 8.0) / 8.0
			var bottom := float(y) / GH
			var n := noise.get_noise_2d(x, y) * 0.5 + 0.5
			_weights[y * GW + x] = clampf(0.35 + n * 1.0 + edge * 0.45 + bottom * 0.35, 0.15, 2.0)


## Recalcula los parámetros del agua (pH, O₂, suciedad...) a partir del estado.
func _refresh_water() -> void:
	var total := 0
	for b in algae:
		total += b
	var dirt := float(total) / maxf(1.0, algae.size() * 2.55)
	var tank: Dictionary = Catalog.TANKS[tank_tier]
	var plants := 0
	var decor_happy := 0.0
	var ph_fx := 0.0
	var plant_clean := 0.0
	for id in decor:
		var d: Dictionary = Catalog.DECOR[id]
		decor_happy += d.fx.get("happy", 0.0)
		ph_fx += d.fx.get("ph", 0.0)
		plant_clean += d.fx.get("clean", 0.0)
		if d.kind == "plant":
			plants += 1
	var sub: Dictionary = Catalog.SUBSTRATES[substrate]
	decor_happy += sub.happy
	if sub.has("plants"):
		decor_happy += plants * 1.0
		plant_clean *= 1.5
	if equipment.light != "":
		decor_happy += Catalog.EQUIPMENT[equipment.light].happy
	var load := 0.0
	for f in fish:
		load += Catalog.SPECIES[f.genes.sp].load * f.genes.size * (0.4 + 0.6 * f.grow)
	var cap: float = tank.o2 + plants * 0.6
	if equipment.pump != "":
		cap += Catalog.EQUIPMENT[equipment.pump].o2
	var o2 := 100.0 - maxf(0.0, load - cap) / cap * 120.0 - maxf(0.0, water_temp - 27.0) * 3.0
	_cache = {
		"dirt": dirt,
		"ph": clampf(7.6 - dirt * 0.014 + ph_fx - (0.15 if substrate == "tierra" else 0.0), 5.6, 8.4),
		"o2": clampf(o2, 10.0, 100.0),
		"load": load,
		"o2_cap": cap,
		"decor_happy": minf(decor_happy, 30.0),
		"filter": Catalog.EQUIPMENT[equipment.filter].eff if equipment.filter != "" else 0.0,
		"plant_clean": minf(plant_clean, 0.35),
	}


func water() -> Dictionary:
	return _cache


# ───────────────────────── Peces ─────────────────────────

func _add_fish(genes: Dictionary, grow: float, bred: bool) -> Dictionary:
	var f := {
		"id": next_id, "name": Catalog.NAMES[rng.randi() % Catalog.NAMES.size()],
		"genes": genes, "grow": grow, "hunger": 25.0, "health": 95.0, "happy": 70.0,
		"cd": 0.0, "bred": bred, "problems": 0,
	}
	next_id += 1
	fish.append(f)
	var key := Genetics.variant_key(genes)
	var r := Genetics.rarity(genes)
	stats.max_rarity = maxi(int(stats.get("max_rarity", 0)), r)
	if not discovered.has(key):
		discovered[key] = true
		if started:
			add_xp(10)
			toast.emit("¡Nueva variante descubierta! (%d)" % discovered.size(), "dna")
	fish_added.emit(f)
	_dirty = true
	return f


func get_fish(id: int) -> Dictionary:
	for f in fish:
		if f.id == id:
			return f
	return {}


func capacity() -> int:
	return Catalog.TANKS[tank_tier].cap


func space_left() -> int:
	return capacity() - fish.size() - eggs.size()


func stage_name(f: Dictionary) -> String:
	return "Alevín" if f.grow < 0.35 else ("Joven" if f.grow < 1.0 else "Adulto")


## Devuelve "" si puede criar, o el motivo por el que no.
func breed_block(f: Dictionary) -> String:
	if f.grow < 1.0: return "Aún no es adulto"
	if f.health < 60.0: return "Salud baja"
	if f.happy < 50.0: return "No está feliz"
	if Time.get_unix_time_from_system() < f.cd: return "Descansando %s" % fmt_duration(f.cd - Time.get_unix_time_from_system())
	return ""


func breed_partners(f: Dictionary) -> Array:
	var out: Array = []
	for o in fish:
		if o.id != f.id and o.genes.sp == f.genes.sp and breed_block(o) == "":
			out.append(o)
	return out


func breed(id_a: int, id_b: int) -> bool:
	var a := get_fish(id_a)
	var b := get_fish(id_b)
	if a.is_empty() or b.is_empty() or breed_block(a) != "" or breed_block(b) != "":
		return false
	if space_left() <= 0:
		toast.emit("No queda espacio en la pecera", "tank")
		return false
	var sp: String = a.genes.sp
	var mut := Genetics.BASE_MUTATION
	var speed := 1.0
	for id in decor:
		var fx: Dictionary = Catalog.DECOR[id].fx
		mut += fx.get("mutation", 0.0)
		speed = maxf(speed, fx.get("breed", {}).get(sp, 1.0))
	var genes := Genetics.breed(a.genes, b.genes, rng, mut)
	var now := Time.get_unix_time_from_system()
	var secs: float = Catalog.SPECIES[sp].incubate / speed
	eggs.append({"id": next_id, "genes": genes, "hatch_at": now + secs, "total": secs, "x": rng.randf_range(0.15, 0.85),
		"parents": "%s × %s" % [a.name, b.name]})
	next_id += 1
	a.cd = now + 600.0
	b.cd = now + 600.0
	_bump("bred", 1)
	add_xp(15)
	toast.emit("¡%s y %s han puesto un huevo!" % [a.name, b.name], "egg")
	eggs_changed.emit()
	changed.emit()
	return true


func _hatch(e: Dictionary) -> void:
	eggs.erase(e)
	var f := _add_fish(e.genes, 0.02, true)
	_bump("hatched", 1)
	add_xp(10)
	var r := Genetics.rarity(f.genes)
	stats.best_bred = maxi(int(stats.get("best_bred", 0)), r)
	toast.emit("¡Ha nacido %s! (%s)" % [f.name, Catalog.RARITY_NAMES[r]], "egg")


func hatch_cost(e: Dictionary) -> int:
	return maxi(1, ceili((e.hatch_at - Time.get_unix_time_from_system()) / 300.0))


func hatch_now(id: int) -> void:
	for e in eggs:
		if e.id == id:
			if not spend(hatch_cost(e), "pearls"):
				return
			_hatch(e)
			eggs_changed.emit()
			changed.emit()
			return


func sell_fish(id: int) -> void:
	var f := get_fish(id)
	if f.is_empty():
		return
	var v := Genetics.value(f)
	coins += v
	fish.erase(f)
	_bump("sold", 1)
	_bump("earned", v)
	add_xp(4 + Genetics.rarity(f.genes) * 6)
	toast.emit("Vendiste a %s por %d" % [f.name, v], "coin")
	fish_removed.emit(id)
	changed.emit()


## Llamado por la vista cuando un pez se come un trozo de comida.
func fish_ate(id: int, food_id: String) -> void:
	var f := get_fish(id)
	if f.is_empty():
		return
	var fd: Dictionary = Catalog.FOODS[food_id]
	f.hunger = maxf(0.0, f.hunger - fd.nutrition)
	f.happy = minf(100.0, f.happy + fd.happy)
	if f.grow < 1.0:
		f.grow = minf(1.0, f.grow + (fd.grow - 1.0) * 0.04)
	_dirty = true


## Comida que nadie se comió: ensucia un poco.
func food_rotted() -> void:
	for i in algae.size():
		algae[i] = mini(255, algae[i] + int(1.6 * _weights[i]))
	algae_changed.emit()


## Una pulsación de "dar de comer". Devuelve false si no queda de ese tipo.
func use_food(food_id: String) -> bool:
	if food_id != "escamas":
		if int(food.get(food_id, 0)) <= 0:
			toast.emit("No te queda %s" % Catalog.FOODS[food_id].name.to_lower(), "food")
			return false
		food[food_id] -= 1
	_bump("feed", 1)
	if food_id == "artemia":
		_bump("artemia", 1)
	for f in fish:
		if f.hunger > 15.0:
			add_xp(1)
			break
	changed.emit()
	return true


## Limpieza con el dedo: uv en 0..1 sobre el cristal. Devuelve lo limpiado.
func clean_at(uv: Vector2, radius := 3.2) -> float:
	var cx := uv.x * GW
	var cy := uv.y * GH
	var removed := 0
	for y in range(maxi(0, int(cy - radius)), mini(GH, int(cy + radius) + 1)):
		for x in range(maxi(0, int(cx - radius)), mini(GW, int(cx + radius) + 1)):
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length() / radius
			if d > 1.0:
				continue
			var i := y * GW + x
			var take := mini(algae[i], int(110.0 * (1.0 - d * d)))
			algae[i] -= take
			removed += take
	if removed == 0:
		return 0.0
	var units := removed / 255.0
	stats.clean_acc = float(stats.get("clean_acc", 0.0)) + units
	if stats.clean_acc >= 1.0:
		var whole := int(stats.clean_acc)
		stats.clean_acc -= whole
		_bump("clean", whole)
		stats.cleaned = int(stats.get("cleaned", 0)) + whole
		add_xp(whole)
	algae_changed.emit()
	_dirty = true
	return units


func set_heater_target(t: float) -> void:
	heater_target = clampf(t, 18.0, 31.0)
	_dirty = true
	changed.emit()


# ───────────────────────── Tienda ─────────────────────────

func spend(amount: int, cur: String) -> bool:
	if cur == "pearls":
		if pearls < amount:
			toast.emit("Te faltan perlas", "pearl")
			return false
		pearls -= amount
	else:
		if coins < amount:
			toast.emit("Te faltan monedas", "coin")
			return false
		coins -= amount
	_dirty = true
	return true


func _bought(text: String, icon: String) -> void:
	_bump("bought", 1)
	add_xp(5)
	toast.emit(text, icon)
	changed.emit()


func buy_fish(sp: String) -> void:
	if space_left() <= 0:
		toast.emit("Pecera llena: amplíala o vende algún pez", "tank")
		return
	if not spend(Catalog.SPECIES[sp].price, "coins"):
		return
	var f := _add_fish(Genetics.random_genes(sp, rng), 0.6, false)
	_bought("¡Bienvenido, %s!" % f.name, "fish")


## Dos ofertas exóticas al día (con mutación), iguales para todo el día.
func daily_offers() -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(daily.get("date", "")) + "offers")
	var pool: Array = []
	for sp in Catalog.SPECIES_ORDER:
		if Catalog.SPECIES[sp].level <= level + 2:
			pool.append(sp)
	var out: Array = []
	for i in 2:
		var g := Genetics.random_genes(pool[r.randi() % pool.size()], r, 1 + (1 if r.randf() < 0.25 else 0))
		var probe := {"genes": g, "grow": 1.0, "health": 100.0}
		out.append({"genes": g, "price": int(Genetics.value(probe) * 2.2), "sold": i in daily.get("offers_bought", [])})
	return out


func buy_offer(i: int) -> void:
	var o: Dictionary = daily_offers()[i]
	if o.sold:
		return
	if space_left() <= 0:
		toast.emit("Pecera llena: amplíala o vende algún pez", "tank")
		return
	if not spend(o.price, "coins"):
		return
	daily.offers_bought = daily.get("offers_bought", []) + [i]
	var f := _add_fish(o.genes, 0.6, false)
	_bought("¡%s llega a tu pecera!" % f.name, "fish")


func buy_tank(tier: int) -> void:
	if tier <= tank_tier or not spend(Catalog.TANKS[tier].price, "coins"):
		return
	tank_tier = tier
	_refresh_water()
	tank_changed.emit()
	_bought("¡Nueva pecera: %s!" % Catalog.TANKS[tier].name, "tank")


func buy_equipment(id: String) -> void:
	var e: Dictionary = Catalog.EQUIPMENT[id]
	if equipment[e.slot] == id or not spend(e.price, "coins"):
		return
	equipment[e.slot] = id
	_refresh_water()
	tank_changed.emit()
	_bought("%s instalado" % e.name, "gear")


func buy_decor(id: String) -> void:
	var d: Dictionary = Catalog.DECOR[id]
	if decor.size() >= Catalog.TANKS[tank_tier].slots:
		toast.emit("No queda sitio. Quita una decoración o amplía la pecera", "tank")
		return
	if not spend(d.price, d.cur):
		return
	decor.append(id)
	_refresh_water()
	tank_changed.emit()
	_bought("%s colocado" % d.name, "plant")


func remove_decor(index: int) -> void:
	if index < 0 or index >= decor.size():
		return
	var d: Dictionary = Catalog.DECOR[decor[index]]
	var refund := int(d.price / 2)
	if d.cur == "pearls":
		pearls += refund
	else:
		coins += refund
	decor.remove_at(index)
	_refresh_water()
	tank_changed.emit()
	toast.emit("Has quitado %s (+%d)" % [d.name, refund], "coin" if d.cur == "coins" else "pearl")
	changed.emit()


func buy_substrate(id: String) -> void:
	var s: Dictionary = Catalog.SUBSTRATES[id]
	if not (id in owned_substrates):
		if not spend(s.price, s.cur):
			return
		owned_substrates.append(id)
		_bump("bought", 1)
	substrate = id
	_refresh_water()
	tank_changed.emit()
	toast.emit("Sustrato: %s" % s.name, "plant")
	changed.emit()


func buy_food(id: String) -> void:
	var fd: Dictionary = Catalog.FOODS[id]
	if not spend(fd.price, "coins"):
		return
	food[id] = int(food.get(id, 0)) + fd.pack
	_bought("+%d %s" % [fd.pack, fd.name], "food")


# ───────────────────────── Progresión y misiones ─────────────────────────

func xp_need(l: int) -> int:
	return int(80.0 * pow(l, 1.35))


func add_xp(n: int) -> void:
	xp += n
	while xp >= xp_need(level):
		xp -= xp_need(level)
		level += 1
		pearls += 2 + level / 2
		level_up.emit(level)
	_dirty = true


func _bump(stat: String, n: int) -> void:
	stats[stat] = int(stats.get(stat, 0)) + n
	for m in daily.get("missions", []):
		if m.id == stat:
			m.progress = mini(int(m.progress) + n, int(m.target))
	_dirty = true


func _check_daily() -> void:
	var today := Time.get_date_string_from_system()
	if daily.get("date", "") == today:
		return
	var r := RandomNumberGenerator.new()
	r.seed = hash(today)
	var pool := Catalog.DAILY.duplicate()
	var missions: Array = []
	for i in 3:
		var t: Dictionary = pool.pop_at(r.randi() % pool.size())
		var target := r.randi_range(t.min, t.max)
		missions.append({"id": t.id, "text": t.text % target, "target": target, "progress": 0,
			"claimed": false, "coins": t.coins + 10 * level, "xp": t.xp})
	daily = {"date": today, "missions": missions, "bonus": false, "offers_bought": []}
	_dirty = true


func claim_daily(i: int) -> void:
	var m: Dictionary = daily.missions[i]
	if m.claimed or m.progress < m.target:
		return
	m.claimed = true
	coins += int(m.coins)
	add_xp(int(m.xp))
	toast.emit("+%d monedas" % m.coins, "coin")
	var all := true
	for x in daily.missions:
		all = all and x.claimed
	if all and not daily.bonus:
		daily.bonus = true
		pearls += 3
		toast.emit("¡Todas las diarias! +3 perlas", "pearl")
	changed.emit()


func story() -> Dictionary:
	return Catalog.STORY[story_idx] if story_idx < Catalog.STORY.size() else {}


func story_progress() -> int:
	var s := story()
	if s.is_empty():
		return 0
	match s.type:
		"feeds": return int(stats.get("feed", 0))
		"cleaned": return int(stats.get("cleaned", 0))
		"filter": return int(equipment.filter != "")
		"heater": return int(equipment.heater != "")
		"bred": return int(stats.get("bred", 0))
		"sold": return int(stats.get("sold", 0))
		"level": return level
		"tank": return tank_tier
		"mutation": return int(stats.get("max_rarity", 0) > 0)
		"fishcount": return fish.size()
		"rarity": return int(stats.get("best_bred", 0))
		"variants": return discovered.size()
		"plant":
			for id in decor:
				if Catalog.DECOR[id].kind == "plant":
					return 1
			return 0
	return 0


func claim_story() -> void:
	var s := story()
	if s.is_empty() or story_progress() < s.target:
		return
	story_idx += 1
	coins += s.coins
	pearls += s.pearls
	add_xp(s.xp)
	var parts := PackedStringArray()
	if s.coins > 0: parts.append("+%d monedas" % s.coins)
	if s.pearls > 0: parts.append("+%d perlas" % s.pearls)
	toast.emit("Misión completada: " + ", ".join(parts), "star")
	changed.emit()


func has_claimable() -> bool:
	var s := story()
	if not s.is_empty() and story_progress() >= s.target:
		return true
	for m in daily.get("missions", []):
		if not m.claimed and m.progress >= m.target:
			return true
	return false


## Si alguien se queda sin peces ni dinero, un vecino le regala una pareja.
func _safety_net() -> void:
	if fish.is_empty() and eggs.is_empty() and coins < Catalog.SPECIES.guppy.price:
		for i in 2:
			_add_fish(Genetics.random_genes("guppy", rng), 1.0, false)
		toast.emit("Un vecino te regala dos guppies", "fish")


func fmt_duration(s: float) -> String:
	s = maxf(0.0, s)
	if s < 60.0: return "%d s" % int(s)
	if s < 3600.0: return "%d min" % int(s / 60.0)
	if s < 86400.0: return "%d h %d min" % [int(s / 3600.0), int(fmod(s, 3600.0) / 60.0)]
	return "%d d %d h" % [int(s / 86400.0), int(fmod(s, 86400.0) / 3600.0)]

