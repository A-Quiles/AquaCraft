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
signal floor_changed
signal level_up(level: int)

var save_path := "user://save.json"   ## demo usa otro fichero para no pisar la partida
const SAVE_VERSION := 3              ## 2: pecera redonda al principio (tier +1) · 3: varias peceras
## Lo que es propio de cada pecera (el resto —dinero, nivel, inventario...— es común).
const TANK_FIELDS := ["tank_name", "tank_tier", "water_kind", "salinity", "equipment", "equip_cond", "equip_pos", "heater_target",
	"water_temp", "substrate", "decor", "terrain", "floor_dirt", "fish", "eggs", "algae", "ph_adjust", "algae_block_until",
	"o2_until", "last_sim"]
const GW := 40                       ## rejilla de algas del cristal
const GH := 60
const ROOM_TEMP := 23.0
const HUNGER_PER_MIN := 0.05         ## 0 → 100 en ~33 h (un pez aguanta días sin comer)
const MAX_OFFLINE := 48.0 * 3600.0
const OFFLINE_STEP := 300.0

var coins := 250
var pearls := 5
var level := 1
var xp := 0
var tank_tier := 0
var mode := "normal"                 ## basico / normal / realista (Catalog.MODES)
var water_kind := "dulce"                 ## dulce / salada
var salinity := 1.0245               ## densidad (solo agua salada)
var equipment := {"filter": "", "heater": "", "pump": "", "light": "", "thermo": "", "ato": ""}
var equip_cond := {}                 ## hueco → estado 0..100 (baja con el uso, sube con mantenimiento)
var equip_pos := {}                  ## hueco → x (0..1) elegida en modo Decorar
var heater_target := 25.0
var water_temp := ROOM_TEMP
var substrate := "grava"
var owned_substrates: Array = ["grava"]
var decor: Array = []                ## colocadas: {id, x (0..1), layer (0 fondo, 1 medio, 2 delante), flip}
var decor_inv := {}                  ## guardadas: id → cantidad
var terrain: Array = []              ## alturas del sustrato (Catalog.TERRAIN_N valores, fracción del alto)
var floor_dirt: Array = []           ## suciedad del fondo por columnas (Catalog.FLOOR_N, 0..1)
var equip_inv := {}                  ## aparatos retirados y guardados: id → cantidad
var o2_until := 0.0                  ## pastillas de oxígeno: hasta cuándo actúan
var show_names := false              ## nombres encima de los peces
var food := {"granulos": 5, "artemia": 3}
var products := {"ph_up": 1, "ph_down": 1, "antialgas": 1}
var ph_adjust := 0.0                 ## efecto de los reguladores de pH (se disipa con el tiempo)
var algae_block_until := 0.0         ## antialgas: hasta cuándo crecen a la mitad
var fish: Array = []
var eggs: Array = []
var algae := PackedByteArray()
var stats := {}
var discovered := {}
var daily := {}
var story_idx := 0
var next_id := 1
var last_sim := 0.0
var started := false                 ## false hasta terminar o saltar el tutorial
var tank_name := "Pecera 1"
var tanks: Array = []                ## una entrada (TANK_FIELDS) por pecera; la activa se vuelca al guardar/cambiar
var active := 0
var orders: Array = []               ## pedidos de clientes
var next_order_at := 0.0
var streak := {}                     ## racha diaria: last (fecha), n (días), pending (premio sin cobrar)
var settings := {"music": true, "sfx": true, "vibration": true, "notify": true}

var rng := RandomNumberGenerator.new()
var _weights := PackedFloat32Array()
var _weights_round := PackedFloat32Array()   ## igual, pero a 0 fuera del cristal de la pecera redonda
var _round_cells := 1
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
	var marine := _arg("water") == "salada"
	new_game(_arg("mode") if _arg("mode") != "" else "normal", "salada" if marine else "dulce")
	tank_tier = clampi(tier, 0, 4)
	level = [2, 3, 5, 7, 10][tank_tier]
	coins = 4820
	pearls = 37
	xp = int(xp_need(level) * 0.6)
	equipment = {"filter": "canister", "heater": "calentador", "pump": "bomba", "light": "led_pro", "thermo": "digital", "ato": ""}
	if tank_tier == 1:
		equipment.filter = "mochila"
	if tank_tier == 0:
		equipment = {"filter": "esponja", "heater": "calentador_mini", "pump": "", "light": "", "thermo": "tira", "ato": ""}
	for k in equipment:
		equip_cond[k] = 90.0
	heater_target = 26.0
	water_temp = 26.0
	substrate = ["pastel", "arena", "grava", "arena", "negra"][tank_tier]
	var ids: Array = [["vallisneria", "rocas"], ["vallisneria", "cofre", "rocas"], ["vallisneria", "rotala", "castillo", "helecho", "rocas"],
		["vallisneria", "rotala", "barco", "anubias", "cofre", "musgo", "helecho"],
		["vallisneria", "rotala", "barco", "anubias", "coral", "helecho", "tronco", "castillo", "musgo"]][tank_tier]
	if marine:
		substrate = "aragonita"
		if tank_tier > 0:
			equipment.filter = "skimmer"
			equipment.ato = "ato"
		ids = [["roca_viva", "anemona"], ["roca_viva", "anemona", "caulerpa"], ["caulerpa", "roca_viva", "anemona", "coral_cerebro", "coral_blando"],
			["caulerpa", "coral_blando", "roca_viva", "anemona", "coral_cerebro", "cofre", "coral"],
			["caulerpa", "coral_blando", "barco", "roca_viva", "anemona", "coral_cerebro", "coral", "roca_viva", "coral_blando"]][tank_tier]
	decor = []
	for i in ids.size():
		decor.append(_decor_entry(ids[i], 0.12 + 0.76 * i / maxf(1.0, ids.size() - 1.0)))
	fish = []
	var r := RandomNumberGenerator.new()
	r.seed = 10 + tier
	var pool := [["guppy", 0], ["platy", 1], ["neon", 0], ["neon", 0], ["neon", 0], ["gurami", 1], ["ramirezi", 0],
		["pleco", 0], ["discus", 1], ["danio", 0], ["danio", 0], ["danio", 0], ["betta", 2], ["angelfish", 0], ["goldfish", 0], ["rasbora", 0]]
	if marine:
		pool = [["payaso", 0], ["payaso", 0], ["banggai", 0], ["cirujano_azul", 0], ["mandarin", 0], ["pez_cofre", 0],
			["emperador", 0], ["limpiador", 0], ["gramma", 1], ["cirujano_amarillo", 0], ["gobio_fuego", 0], ["angel_llama", 1],
			["payaso", 2], ["banggai", 1], ["gramma", 0], ["damisela", 0]]
	for i in [3, 5, 9, 14, 16][tank_tier]:
		var f := _add_fish(Genetics.random_genes(pool[i][0], r, pool[i][1]), 1.0, i % 3 == 0)
		f.hunger = 20.0 if i != 2 else 75.0
	var wts := algae_weights()
	for i in algae.size():
		algae[i] = int(wts[i] * 10.0)
	daily = {}
	_check_daily()
	streak.pending = false
	started = true
	last_sim = Time.get_unix_time_from_system()
	tanks = [_snapshot()]


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
		_grow_floor(gap)
	last_sim = now
	_check_daily()
	_refresh_orders(now)
	_safety_net()
	changed.emit()
	_save_acc += 1.0
	if _dirty and _save_acc >= 20.0:
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		_schedule_notifications()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		var n := _notifier()
		if n:
			n.cancelAll()


# ───────────────────────── Partida nueva / guardado ─────────────────────────

func new_game(game_mode := "normal", water_type := "dulce") -> void:
	mode = game_mode
	coins = 250
	pearls = 5
	level = 1
	xp = 0
	owned_substrates = []
	decor_inv = {}
	equip_inv = {}
	food = {"granulos": 5, "artemia": 6, "nori": 4 if water_type == "salada" else 0}
	products = {"ph_up": 1, "ph_down": 1, "oxigeno": 1, "sal": 1 if water_type == "salada" else 0, "antialgas": 1}
	stats = {}
	discovered = {}
	story_idx = 0
	started = false
	orders = []
	next_order_at = 0.0
	streak = {}
	_init_tank(water_type, "Pecera 1", true)
	for sp in (["payaso", "payaso", "gramma"] if water_type == "salada" else ["guppy", "guppy", "platy"]):
		_add_fish(Genetics.random_genes(sp, rng), 1.0, false)
	tanks = [_snapshot()]
	active = 0
	daily = {}
	_check_daily()
	_dirty = true


## Pecera nueva: redonda, sin aparatos. starter = con la decoración de bienvenida.
func _init_tank(water_type: String, nm: String, starter: bool) -> void:
	tank_name = nm
	water_kind = water_type
	salinity = 1.0245
	tank_tier = 0
	var marine := water_kind == "salada"
	# Se empieza con una pecera redonda y sin ningún aparato: hay que ir comprándolos.
	equipment = {"filter": "", "heater": "", "pump": "", "light": "", "thermo": "", "ato": ""}
	equip_cond = {}
	equip_pos = {}
	terrain = []
	floor_dirt = []
	o2_until = 0.0
	heater_target = 25.0
	substrate = "aragonita" if marine else "grava"
	if not substrate in owned_substrates:
		owned_substrates.append(substrate)
	decor = []
	if starter:
		decor = [_decor_entry("roca_viva", 0.25), _decor_entry("anemona", 0.7)] if marine \
			else [_decor_entry("vallisneria", 0.2), _decor_entry("rocas", 0.68)]
	ph_adjust = 0.0
	algae_block_until = 0.0
	fish = []
	eggs = []
	algae = PackedByteArray()
	algae.resize(GW * GH)
	var wts := algae_weights()
	for i in algae.size():
		algae[i] = int(clampf(wts[i] * 55.0 * float(mk("algae") > 0.0), 0.0, 255.0))
	water_temp = _temp_target()
	last_sim = Time.get_unix_time_from_system()


func _snapshot() -> Dictionary:
	var d := {}
	for k in TANK_FIELDS:
		d[k] = get(k)
	return d


func _apply(d: Dictionary) -> void:
	for k in TANK_FIELDS:
		set(k, d[k])


## Valor del modo de juego actual (Catalog.MODES).
func mk(key: String) -> Variant:
	return Catalog.MODES[mode][key]


func set_game_mode(m: String) -> void:
	mode = m
	if mode == "basico":
		for slot in equipment:
			equip_cond[slot] = 100.0
	_refresh_water()
	tank_changed.emit()
	changed.emit()
	_dirty = true
	toast.emit("Modo %s activado" % Catalog.MODES[m].name, "star")


## Habitación: fija a 23 °C; en realista se enfría de noche (19,5–22,5 °C).
func room_temp() -> float:
	if not mk("room_var"):
		return ROOM_TEMP
	var t := Time.get_time_dict_from_system()
	var h: float = t.hour + t.minute / 60.0
	return 21.0 + 1.5 * sin((h - 10.0) / 24.0 * TAU)


## Reponer agua dulce: baja la salinidad 2 milésimas (pasarse también es malo: se corrige con sal).
func top_up() -> void:
	salinity = maxf(1.014, salinity - 0.002)
	_bump("maint", 1)
	add_xp(3)
	toast.emit("Agua dulce repuesta: salinidad %.3f" % salinity, "ph")
	changed.emit()
	_dirty = true


## Convertir la pecera (vacía) al otro tipo de agua. Lo incompatible se guarda o se retira.
func convert_water() -> bool:
	if not fish.is_empty() or not eggs.is_empty():
		toast.emit("Vacía la pecera primero: vende o espera a que no quede ningún pez", "tank")
		return false
	if not spend(400, "coins"):
		return false
	water_kind = "salada" if water_kind == "dulce" else "dulce"
	salinity = 1.0245
	for i in range(decor.size() - 1, -1, -1):
		if not Catalog.fits(Catalog.DECOR[decor[i].id], water_kind):
			decor_inv[decor[i].id] = int(decor_inv.get(decor[i].id, 0)) + 1
			decor.remove_at(i)
	if not Catalog.fits(Catalog.SUBSTRATES[substrate], water_kind):
		substrate = "aragonita" if water_kind == "salada" else "grava"
		if not substrate in owned_substrates:
			owned_substrates.append(substrate)
	for slot in equipment:
		if equipment[slot] != "" and not Catalog.fits(Catalog.EQUIPMENT[equipment[slot]], water_kind):
			equipment[slot] = ""
	_refresh_water()
	tank_changed.emit()
	changed.emit()
	toast.emit("¡Tu pecera ahora es de %s!" % Catalog.WATER_NAMES[water_kind].to_lower(), "tank")
	return true


func save_game() -> void:
	_save_acc = 0.0
	if tanks.is_empty():
		tanks = [_snapshot()]
	tanks[active] = _snapshot()
	var enc: Array = []
	for t in tanks:
		var c: Dictionary = t.duplicate()
		c.algae = Marshalls.raw_to_base64(t.algae)
		enc.append(c)
	var data := {
		"v": SAVE_VERSION, "mode": mode, "coins": coins, "pearls": pearls, "level": level, "xp": xp,
		"owned_substrates": owned_substrates, "decor_inv": decor_inv, "equip_inv": equip_inv, "show_names": show_names,
		"food": food, "products": products, "stats": stats, "discovered": discovered, "daily": daily,
		"story_idx": story_idx, "next_id": next_id, "started": started, "tanks": enc, "active": active,
		"orders": orders, "next_order_at": next_order_at, "streak": streak, "settings": settings,
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
	if typeof(d) != TYPE_DICTIONARY or not (d.has("fish") or d.has("tanks")):
		# Guardado corrupto: lo apartamos en vez de borrarlo.
		DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(save_path + ".bad"))
		return false
	var v := int(d.get("v", 1))
	mode = d.get("mode", "normal")
	coins = int(d.coins)
	pearls = int(d.pearls)
	level = int(d.level)
	xp = int(d.xp)
	equip_inv = d.get("equip_inv", {})
	for k in equip_inv:
		equip_inv[k] = int(equip_inv[k])
	show_names = bool(d.get("show_names", false))
	owned_substrates = d.owned_substrates
	products = d.get("products", {"ph_up": 1, "ph_down": 1, "antialgas": 1})
	for k in products:
		products[k] = int(products[k])
	decor_inv = d.get("decor_inv", {})
	for k in decor_inv:
		decor_inv[k] = int(decor_inv[k])
	food = d.food
	for k in food:
		food[k] = int(food[k])
	stats = d.stats
	discovered = d.discovered
	daily = d.daily
	story_idx = int(d.story_idx)
	next_id = int(d.next_id)
	started = bool(d.get("started", true))
	orders = d.get("orders", [])
	next_order_at = float(d.get("next_order_at", 0.0))
	streak = d.get("streak", {})
	settings.merge(d.get("settings", {}), true)
	# Partidas de una sola pecera guardaban sus datos sueltos en la raíz.
	var list: Array = d.tanks if d.has("tanks") else [d]
	tanks = []
	for i in list.size():
		_read_tank(list[i], v, i)
		tanks.append(_snapshot())
	active = clampi(int(d.get("active", 0)), 0, tanks.size() - 1)
	_apply(tanks[active])
	_refresh_water()
	var gap := Time.get_unix_time_from_system() - last_sim
	if gap > 5.0:
		_catch_up(gap)
	last_sim = Time.get_unix_time_from_system()
	return true


## Datos de una pecera desde el JSON (con valores por defecto para guardados antiguos).
func _read_tank(td: Dictionary, v: int, i: int) -> void:
	tank_name = td.get("tank_name", "Pecera %d" % (i + 1))
	water_kind = td.get("water_kind", td.get("water", "dulce"))
	salinity = float(td.get("salinity", 1.0245))
	tank_tier = int(td.tank_tier)
	if v < 2:
		tank_tier += 1                     # la pecera redonda se añadió delante de la Nano
	terrain = td.get("terrain", [])
	floor_dirt = td.get("floor_dirt", [])
	o2_until = float(td.get("o2_until", 0.0))
	equipment = {"filter": "", "heater": "", "pump": "", "light": "", "thermo": "", "ato": ""}
	equipment.merge(td.equipment, true)
	equip_cond = td.get("equip_cond", {})
	equip_pos = td.get("equip_pos", {})
	heater_target = float(td.heater_target)
	water_temp = float(td.water_temp)
	substrate = td.substrate
	decor = []
	var old: Array = td.decor
	for k in old.size():
		# Partidas antiguas guardaban solo el id.
		decor.append(old[k] if old[k] is Dictionary else _decor_entry(old[k], 0.12 + 0.76 * k / maxf(1.0, old.size() - 1.0)))
	ph_adjust = float(td.get("ph_adjust", 0.0))
	algae_block_until = float(td.get("algae_block_until", 0.0))
	last_sim = float(td.last_sim)
	algae = Marshalls.base64_to_raw(td.algae) if td.algae is String else td.algae
	if algae.size() != GW * GH:
		algae.resize(GW * GH)
	fish = td.fish
	var now := Time.get_unix_time_from_system()
	for f in fish:
		f.id = int(f.id)
		Genetics.normalize(f.genes)
		if not f.has("born"):
			f.born = now - life_days(f.genes.sp) * 0.2 * 86400.0 * f.grow
	eggs = td.eggs
	for e in eggs:
		e.id = int(e.id)
		Genetics.normalize(e.genes)


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
			_grow_floor(pending_algae)
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
	water_temp = move_toward(water_temp, _temp_target(), heat_rate() * m)
	ph_adjust = move_toward(ph_adjust, 0.0, 0.3 / 1440.0 * m)  # se disipa en ~1 día
	_wear(dt)
	var w: Dictionary = _cache
	_evaporate(dt)
	var death: bool = mk("death")
	# Estando fuera nadie muere (en Realista vuelven muy débiles); jugando, en Realista sí pueden morir.
	var floor_hp := (10.0 if death else 25.0) if _offline_floor else (0.0 if death else 5.0)
	var dead: Array = []
	var dis_mult := float(mk("disease"))
	var cleaner := fish.any(func(o): return Catalog.SPECIES[o.genes.sp].get("cleaner", false))
	for f in fish:
		var sp: Dictionary = Catalog.SPECIES[f.genes.sp]
		var problems := fish_problems(f).size()
		f.hunger = minf(100.0, f.hunger + HUNGER_PER_MIN * float(mk("hunger")) * m)
		f.problems = problems
		var hp_delta := 0.15 if problems == 0 else -0.04 * problems * (1.5 if death else 1.0)
		var dis: String = f.get("dis", "")
		if dis != "" and float(f.get("cure_at", 0.0)) <= 0.0:
			hp_delta -= 0.04                       # una enfermedad sin tratar pesa el doble
		f.health = clampf(f.health + hp_delta * m, minf(floor_hp, f.health), 100.0)
		if death and f.health <= 0.0:
			dead.append(f)
		var happy_target := clampf(45.0 + w.decor_happy + (10.0 if f.hunger < 40.0 else 0.0) - 12.0 * problems, 0.0, 100.0)
		f.happy = move_toward(f.happy, happy_target, 1.5 * m)
		if f.grow < 1.0:
			var speed := 1.0 if f.health > 40.0 else 0.3
			f.grow = minf(1.0, f.grow + dt / float(sp.grow) * speed)
		# Enfermedades: más riesgo con agua sucia, parámetros malos o estrés. Se curan con su tratamiento.
		if dis == "":
			var risk := (0.001 + 0.004 * problems + (0.004 if maxf(w.dirt, w.waste) > 55.0 else 0.0)) * dis_mult
			if rng.randf() < risk * m / 60.0:
				var pick: String = ["ich", "ich", "hongos", "aletas"][rng.randi() % 4]
				if pick == "ich" and cleaner:
					pick = "hongos" if rng.randf() < 0.3 else ""
				if pick != "":
					f.dis = pick
					f.erase("cure_at")
					toast.emit("%s tiene %s. Mira su ficha." % [f.name, Catalog.DISEASES[pick].name.to_lower()], "health")
		elif float(f.get("cure_at", 0.0)) > 0.0:
			if now >= float(f.cure_at):
				f.dis = ""
				f.erase("cure_at")
				toast.emit("%s se ha curado" % f.name, "sparkle")
		elif Catalog.DISEASES[dis].spread and rng.randf() < 0.06 * m / 60.0:
			var healthy := fish.filter(func(o): return o.get("dis", "") == "")
			if not healthy.is_empty():
				healthy[rng.randi() % healthy.size()].dis = dis
		# Vejez: después del 80% de su vida es anciano; en Realista puede morir de viejo (solo jugando).
		var age := age_days(f)
		f.old = age > life_days(f.genes.sp) * 0.8
		if death and not _offline_floor and age > life_days(f.genes.sp) and rng.randf() < 0.1 * m / 60.0 and not f in dead:
			dead.append(f)
			f.old_death = true
	for f in dead:
		fish.erase(f)
		stats.deaths = int(stats.get("deaths", 0)) + 1
		fish_removed.emit(f.id)
		if f.get("old_death", false):
			toast.emit("%s ha muerto de viejo tras %d días. Fue una vida larga." % [f.name, age_days(f)], "health")
		else:
			toast.emit("%s ha muerto. Revisa los parámetros del agua." % f.name, "health")
	_grow_plants(m)
	var hatched := false
	for e in eggs.duplicate():
		if now >= e.hatch_at:
			_hatch(e)
			hatched = true
	if hatched:
		eggs_changed.emit()
	_dirty = true


func diet_text(sp: String) -> String:
	var names := PackedStringArray()
	for f in Catalog.SPECIES[sp].diet:
		names.append(Catalog.FOODS[f].name.to_lower())
	return ("Solo come " if names.size() == 1 else "Come ") + ", ".join(names)


## Qué le molesta a un pez (vacío = está a gusto). El margen depende del modo de juego.
func fish_problems(f: Dictionary) -> Array:
	var out: Array = []
	var s: Dictionary = Catalog.SPECIES[f.genes.sp]
	var w: Dictionary = _cache
	var tol: float = mk("tol")
	if mk("hunger_hurts") and f.hunger > 70.0: out.append("Hambre")
	if tol >= 99.0:
		return out
	if water_temp < s.temp[0] - 0.5 * tol or water_temp > s.temp[1] + 0.5 * tol: out.append("Temperatura")
	if w.ph < s.ph[0] - 0.2 * tol or w.ph > s.ph[1] + 0.2 * tol: out.append("pH")
	if w.o2 < (60.0 if mode == "realista" else 55.0): out.append("Oxígeno")
	if maxf(w.dirt, w.waste) > (60.0 if mode == "realista" else 70.0): out.append("Suciedad")
	if s.water == "salada" and (salinity < Catalog.SALINITY[0] - 0.001 * tol or salinity > Catalog.SALINITY[1] + 0.001 * tol):
		out.append("Salinidad")
	if f.get("dis", "") != "" and float(f.get("cure_at", 0.0)) <= 0.0:
		out.append("Enfermedad")
	if s.has("school") and same_species(f) < int(s.school):
		out.append("Soledad")
	if stress_by(f) != "":
		out.append("Estrés")
	return out


func same_species(f: Dictionary) -> int:
	var n := 0
	for o in fish:
		n += int(o.genes.sp == f.genes.sp)
	return n


## Quién le hace la vida imposible a este pez ("" si nadie): rivales, matones, mordedores o depredadores.
func stress_by(f: Dictionary) -> String:
	var s: Dictionary = Catalog.SPECIES[f.genes.sp]
	for o in fish:
		if o.id == f.id:
			continue
		var os: Dictionary = Catalog.SPECIES[o.genes.sp]
		if o.genes.sp == f.genes.sp:
			if s.get("solo", false):
				return "otro %s" % s.name.to_lower()
			continue
		if os.get("aggr", false) and not s.get("aggr", false):
			return os.name
		if os.get("nipper", false) and (s.shape.tail in [3, 5] or f.genes.veil or s.shape.get("thr", 0.0) > 0.3):
			return os.name
		if os.get("predator", false) and float(s.shape.px) <= 62.0:
			return os.name
	return ""


## Aviso antes de comprar una especie: con quién no se llevaría bien en esta pecera ("" si con nadie).
func compat_warning(sp: String) -> String:
	var s: Dictionary = Catalog.SPECIES[sp]
	var probe := {"id": -1, "genes": {"sp": sp, "veil": false}}
	fish.append(probe)
	var out := ""
	if s.get("solo", false) and same_species(probe) > 1:
		out = "Ya tienes un %s: se pelearán." % s.name.to_lower()
	else:
		for o in fish:
			if o.id != -1 and stress_by(o) == s.name:
				out = "Molestará a tu %s." % Catalog.SPECIES[o.genes.sp].name.to_lower()
				break
		if out == "":
			var by := stress_by(probe)
			if by != "":
				out = "Lo molestará: %s." % by.to_lower()
	fish.erase(probe)
	if out == "" and s.has("school") and same_species({"genes": {"sp": sp}}) + 1 < int(s.school):
		out = "Va en grupo: compra al menos %d." % int(s.school)
	return out


## Qué hacer con cada molestia (se enseña en la ficha del pez).
func problem_fix(f: Dictionary, p: String) -> String:
	var s: Dictionary = Catalog.SPECIES[f.genes.sp]
	var w: Dictionary = _cache
	match p:
		"Hambre": return "Hambre: coge el bote de comida (%s)." % diet_text(f.genes.sp).to_lower()
		"Temperatura":
			if water_temp < s.temp[0]:
				return "Frío: instala o mejora el calentador."
			return "Calor: baja el termostato o retira el calentador."
		"pH": return "pH bajo: echa pH+ (bote de Agua)." if w.ph < s.ph[0] else "pH alto: echa pH− (bote de Agua)."
		"Oxígeno": return "Oxígeno: pastillas de oxígeno, un aireador o menos peces."
		"Suciedad": return "Suciedad: limpia el cristal y aspira el fondo con el sifón."
		"Salinidad":
			if salinity > Catalog.SALINITY[1]:
				return "Salinidad alta: repón agua dulce (bote de Agua)."
			return "Salinidad baja: añade sal marina (bote de Agua)."
		"Enfermedad":
			var d: Dictionary = Catalog.DISEASES[f.dis]
			return "%s: %s Usa %s (bote de Agua)." % [d.name, d.desc, Catalog.PRODUCTS[d.med].name.to_lower()]
		"Soledad": return "Soledad: es pez de banco, quiere al menos %d de su especie." % int(s.school)
		"Estrés": return "Estrés: le molesta %s. Sepáralos en otra pecera o vende uno." % stress_by(f).to_lower()
	return p


## En agua salada se evapora agua dulce y la sal se concentra (salvo con reposición automática).
func _evaporate(dt: float) -> void:
	if water_kind != "salada" or float(mk("evap")) <= 0.0:
		return
	if equipment.ato != "" and efficiency("ato") > 0.5:
		return
	salinity = minf(1.035, salinity + 0.00004 * float(mk("evap")) * dt / 3600.0)   # ~1 milésima al día


func _grow_algae(dt: float) -> void:
	var w: Dictionary = _cache
	if float(mk("algae")) <= 0.0:
		return
	# Lento a propósito: sin filtro, 2-3 peces ensucian ~1/6 del cristal al día.
	var per_min: float = (0.004 + 0.004 * w.load) * (1.0 - w.filter) * (1.0 - w.plant_clean) * float(mk("algae"))
	if Time.get_unix_time_from_system() < algae_block_until:
		per_min *= 0.5
	var add := per_min * dt / 60.0 * 2.55          # bytes por celda (peso medio 1)
	if add <= 0.0:
		return
	var wts := algae_weights()
	for i in algae.size():
		var v := add * wts[i]
		# Redondeo estocástico para que el crecimiento lento no se pierda.
		var n := int(v) + (1 if rng.randf() < v - floorf(v) else 0)
		algae[i] = mini(255, algae[i] + n)
	algae_changed.emit()


## El fondo se va ensuciando (restos, excrementos): ~1/4 al día con 2-3 peces. El filtro lo frena a la mitad.
func _grow_floor(dt: float) -> void:
	var mult := float(mk("waste"))
	if mult <= 0.0:
		return
	_ensure_floor()
	var w: Dictionary = _cache
	var add := (0.00004 + 0.00006 * float(w.get("load", 1.0))) * (1.0 - float(w.get("filter", 0.0)) * 0.5) * mult * dt / 60.0
	for i in floor_dirt.size():
		floor_dirt[i] = minf(1.0, float(floor_dirt[i]) + add * (0.6 + 0.8 * fposmod(sin(i * 12.9898) * 43758.5453, 1.0)))
	floor_changed.emit()


func _ensure_floor() -> void:
	if floor_dirt.size() != Catalog.FLOOR_N:
		floor_dirt = []
		floor_dirt.resize(Catalog.FLOOR_N)
		floor_dirt.fill(0.0)


func floor_level() -> float:
	if floor_dirt.is_empty():
		return 0.0
	var t := 0.0
	for v in floor_dirt:
		t += float(v)
	return t / floor_dirt.size()


## Sifón: aspira la suciedad del fondo alrededor de u (0..1). Devuelve lo aspirado.
func vacuum_at(u: float) -> float:
	_ensure_floor()
	var c := u * Catalog.FLOOR_N - 0.5
	var got := 0.0
	for i in range(maxi(0, int(c - 2)), mini(Catalog.FLOOR_N, int(c + 3))):
		var k := 1.0 - absf(i - c) / 2.0
		if k <= 0.0:
			continue
		var take := minf(float(floor_dirt[i]), 0.05 * k)
		floor_dirt[i] = float(floor_dirt[i]) - take
		got += take
	if got <= 0.0:
		return 0.0
	stats.vac_acc = float(stats.get("vac_acc", 0.0)) + got
	if stats.vac_acc >= 0.25:
		stats.vac_acc -= 0.25
		_bump("vacuumed", 1)
		add_xp(1)
	floor_changed.emit()
	_dirty = true
	return got


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
			# Mucha varianza: unas manchas aparecen pronto y se van extendiendo.
			_weights[y * GW + x] = clampf(0.1 + pow(n, 2.2) * 2.6 + edge * 0.5 + bottom * 0.3, 0.08, 2.6)
	# Pecera redonda: solo hay cristal dentro del círculo (mismas proporciones que TankView.bowl()).
	_weights_round = _weights.duplicate()
	_round_cells = 0
	for y in GH:
		for x in GW:
			var u := (x + 0.5) / GW
			var v := (y + 0.5) / GH
			if pow((u - 0.5) / 0.5, 2.0) + pow((v - BOWL_CY) / BOWL_RY, 2.0) > 1.0:
				_weights_round[y * GW + x] = 0.0
			else:
				_round_cells += 1


## Pecera redonda con base plana: alto = 0,87 × ancho; el centro del círculo está 0,449 × ancho
## por encima del fondo (así la base plana mide 0,44 del ancho). Centro y radio vertical en uv.
const BOWL_H := 0.87
const BOWL_DROP := 0.449
const BOWL_CY := (BOWL_H - BOWL_DROP) / BOWL_H
const BOWL_RY := 0.5 / BOWL_H


func is_round() -> bool:
	return Catalog.TANKS[tank_tier].get("round", false)


func algae_weights() -> PackedFloat32Array:
	return _weights_round if is_round() else _weights


## Recalcula los parámetros del agua (pH, O₂, suciedad...) a partir del estado.
func _refresh_water() -> void:
	var total := 0
	for b in algae:
		total += b
	var dirt := float(total) / maxf(1.0, (_round_cells if is_round() else algae.size()) * 2.55)
	var tank: Dictionary = Catalog.TANKS[tank_tier]
	var plants := 0
	var decor_happy := 0.0
	var ph_fx := 0.0
	var plant_clean := 0.0
	for it in decor:
		var d: Dictionary = Catalog.DECOR[it.id]
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
		decor_happy += Catalog.EQUIPMENT[equipment.light].happy * efficiency("light")
	var load := 0.0
	for f in fish:
		load += Catalog.SPECIES[f.genes.sp].load * f.genes.size * (0.4 + 0.6 * f.grow)
	var cap: float = tank.o2 + plants * 0.6 + (2.5 if Time.get_unix_time_from_system() < o2_until else 0.0)
	if equipment.pump != "":
		cap += Catalog.EQUIPMENT[equipment.pump].o2 * efficiency("pump")
	var o2 := 100.0 - maxf(0.0, load - cap) / cap * 120.0 - maxf(0.0, water_temp - 27.0) * 3.0
	var waste := floor_level() * 100.0
	_cache = {
		"dirt": dirt,
		"waste": waste,
		"ph": clampf((8.25 if water_kind == "salada" else 7.6) - dirt * 0.014 * (1.4 if mode == "realista" else 1.0) - waste * 0.005 + ph_fx
			- (0.15 if substrate == "tierra" else 0.0) + ph_adjust, 5.6, 8.6),
		"o2": clampf(o2, 10.0, 100.0),
		"load": load,
		"o2_cap": cap,
		"decor_happy": minf(decor_happy, 30.0),
		"filter": Catalog.EQUIPMENT[equipment.filter].eff * efficiency("filter") if equipment.filter != "" else 0.0,
		"plant_clean": minf(plant_clean, 0.35),
	}


func water() -> Dictionary:
	return _cache


# ───────────────────────── Equipo y mantenimiento ─────────────────────────

## 1 por encima del 60% de estado; baja hasta 0.15 cuando está muy descuidado.
func efficiency(slot: String) -> float:
	return clampf(float(equip_cond.get(slot, 100.0)) / 60.0, 0.15, 1.0)


## °C por minuto hacia la temperatura objetivo: sin calentador el agua se templa sola, despacio.
func heat_rate() -> float:
	if equipment.heater == "":
		return 0.15
	return float(Catalog.EQUIPMENT[equipment.heater].get("rate", 0.6)) * lerpf(0.4, 1.0, efficiency("heater"))


## "" si se puede instalar en la pecera actual; si no, el motivo.
func install_block(id: String) -> String:
	var e: Dictionary = Catalog.EQUIPMENT[id]
	var t: Dictionary = Catalog.TANKS[tank_tier]
	if not e.slot in t.equip:
		return "No cabe aquí"
	if int(e.q) > int(t.max_q):
		return "Pecera mayor"
	return ""


func condition(slot: String) -> float:
	return float(equip_cond.get(slot, 100.0))


func _temp_target() -> float:
	if equipment.heater == "":
		return room_temp()
	var e: Dictionary = Catalog.EQUIPMENT[equipment.heater]
	return lerpf(room_temp(), e.get("fixed", heater_target), efficiency("heater"))


func _wear(dt: float) -> void:
	for slot in equipment:
		var id: String = equipment[slot]
		if id == "":
			continue
		var rate: float = Catalog.EQUIPMENT[id].wear * float(mk("wear"))
		if slot == "filter":
			rate *= 0.5 + 0.35 * float(_cache.get("load", 1.0))
		var before := condition(slot)
		equip_cond[slot] = maxf(0.0, before - rate * dt / 3600.0)
		if before >= 30.0 and equip_cond[slot] < 30.0 and not _offline_floor:
			toast.emit("%s necesita mantenimiento" % Catalog.EQUIPMENT[id].name, "gear")
		# Los aparatos básicos no aguantan el abandono: al llegar a 0 se rompen y hay que comprar otro.
		if equip_cond[slot] <= 0.0 and int(Catalog.EQUIPMENT[id].q) == 1:
			equipment[slot] = ""
			equip_cond.erase(slot)
			_bump("broken", 1)
			toast.emit.call_deferred("Se ha roto tu %s. Compra otro en la tienda" % Catalog.EQUIPMENT[id].name.to_lower(), "gear")
			tank_changed.emit.call_deferred()


## Equipos por debajo del 30%: para avisos en la pecera.
func needs_maintenance() -> Array:
	var out: Array = []
	for slot in equipment:
		if equipment[slot] != "" and Catalog.EQUIPMENT[equipment[slot]].wear > 0.0 and condition(slot) < 30.0:
			out.append(slot)
	return out


func maintain(slot: String) -> void:
	if equipment.get(slot, "") == "":
		return
	equip_cond[slot] = 100.0
	_bump("maint", 1)
	add_xp(5)
	_refresh_water()
	tank_changed.emit()
	toast.emit("%s como nuevo" % Catalog.EQUIPMENT[equipment[slot]].name, "sparkle")
	changed.emit()


## Texto del termómetro: "" si no hay (o el digital no tiene pila).
func thermometer_text() -> String:
	match equipment.thermo:
		"tira": return "%.0f°C" % water_temp
		"digital": return "%.1f°C" % water_temp if condition("thermo") > 0.0 else ""
	return ""


# ───────────────────────── Decoración ─────────────────────────

func _decor_entry(id: String, x: float) -> Dictionary:
	return {"id": id, "x": x, "layer": 0 if Catalog.DECOR[id].kind == "plant" else 1, "flip": false}


func decor_slots() -> int:
	return Catalog.TANKS[tank_tier].slots


## Coloca una pieza del inventario en el hueco libre más amplio.
func place_decor(id: String) -> bool:
	if int(decor_inv.get(id, 0)) <= 0:
		return false
	if not Catalog.fits(Catalog.DECOR[id], water_kind):
		toast.emit("%s no sirve para %s" % [Catalog.DECOR[id].name, Catalog.WATER_NAMES[water_kind].to_lower()], "tank")
		return false
	if decor.size() >= decor_slots():
		toast.emit("No cabe más: guarda algo o amplía la pecera", "tank")
		return false
	var xs: Array = [0.04, 0.96]
	for it in decor:
		xs.append(it.x)
	xs.sort()
	var best := 0.5
	var gap := -1.0
	for i in xs.size() - 1:
		if xs[i + 1] - xs[i] > gap:
			gap = xs[i + 1] - xs[i]
			best = (xs[i] + xs[i + 1]) * 0.5
	decor_inv[id] = int(decor_inv[id]) - 1
	if decor_inv[id] == 0:
		decor_inv.erase(id)
	decor.append(_decor_entry(id, best))
	_decor_changed()
	return true


func store_decor(i: int) -> void:
	if i < 0 or i >= decor.size():
		return
	var id: String = decor[i].id
	decor_inv[id] = int(decor_inv.get(id, 0)) + 1
	decor.remove_at(i)
	_decor_changed()
	toast.emit("%s guardado en el inventario" % Catalog.DECOR[id].name, "plant")


func sell_decor_inv(id: String) -> void:
	if int(decor_inv.get(id, 0)) <= 0:
		return
	var d: Dictionary = Catalog.DECOR[id]
	var refund := int(d.price / 2)
	if d.cur == "pearls":
		pearls += refund
	else:
		coins += refund
	decor_inv[id] = int(decor_inv[id]) - 1
	if decor_inv[id] == 0:
		decor_inv.erase(id)
	toast.emit("Vendiste %s (+%d)" % [d.name, refund], "coin" if d.cur == "coins" else "pearl")
	changed.emit()


func move_decor(i: int, x: float) -> void:
	decor[i].x = clampf(x, 0.03, 0.97)
	_dirty = true


func cycle_decor_layer(i: int) -> void:
	decor[i].layer = (int(decor[i].layer) + 1) % 3
	_decor_changed()


func flip_decor(i: int) -> void:
	decor[i].flip = not decor[i].flip
	_decor_changed()


func _decor_changed() -> void:
	_refresh_water()
	tank_changed.emit()
	changed.emit()
	_dirty = true


# ───────────────────────── Peces ─────────────────────────

func _add_fish(genes: Dictionary, grow: float, bred: bool) -> Dictionary:
	var f := {
		"id": next_id, "name": Catalog.NAMES[rng.randi() % Catalog.NAMES.size()],
		"genes": genes, "grow": grow, "hunger": 25.0, "health": 95.0, "happy": 70.0,
		"cd": 0.0, "bred": bred, "problems": 0,
		"born": Time.get_unix_time_from_system() - life_days(genes.sp) * 0.15 * 86400.0 * grow,
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


func life_days(sp: String) -> float:
	var s: Dictionary = Catalog.SPECIES[sp]
	return float(s.get("life", 40 + s.price / 3))


func age_days(f: Dictionary) -> int:
	return int((Time.get_unix_time_from_system() - float(f.get("born", Time.get_unix_time_from_system()))) / 86400.0)


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
	if f.get("old", false):
		return "Anciano"
	return "Alevín" if f.grow < 0.35 else ("Joven" if f.grow < 1.0 else "Adulto")


## Devuelve "" si puede criar, o el motivo por el que no.
func breed_block(f: Dictionary) -> String:
	if f.grow < 1.0: return "Aún no es adulto"
	if f.get("old", false): return "Es demasiado mayor"
	if f.get("dis", "") != "": return "Está enfermo"
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
	for it in decor:
		var fx: Dictionary = Catalog.DECOR[it.id].fx
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


## Comida que nadie se comió: ensucia un poco el cristal y, sobre todo, el fondo donde cayó (u 0..1).
func food_rotted(u := -1.0) -> void:
	var wts := algae_weights()
	for i in algae.size():
		algae[i] = mini(255, algae[i] + int(1.6 * wts[i]))
	algae_changed.emit()
	if u >= 0.0 and float(mk("waste")) > 0.0:
		_ensure_floor()
		var c := clampi(int(u * Catalog.FLOOR_N), 0, Catalog.FLOOR_N - 1)
		floor_dirt[c] = minf(1.0, float(floor_dirt[c]) + 0.04)
		floor_changed.emit()


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
	if not Catalog.fits(Catalog.SPECIES[sp], water_kind):
		return
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
	r.seed = hash(str(daily.get("date", "")) + "offers" + water_kind)
	var pool: Array = []
	for sp in Catalog.SPECIES_ORDER:
		if Catalog.SPECIES[sp].level <= level + 2 and Catalog.fits(Catalog.SPECIES[sp], water_kind):
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
	if not Catalog.fits(e, water_kind):
		return
	if install_block(id) != "":
		toast.emit("%s no cabe en tu %s: amplía la pecera" % [e.name, Catalog.TANKS[tank_tier].name], "tank")
		return
	if equipment[e.slot] == id or not spend(e.price, "coins"):
		return
	_install(id, 100.0)
	_bought("%s instalado" % e.name, "gear")


## Coloca un aparato; el que hubiera en ese hueco se guarda en el almacén.
func _install(id: String, cond: float) -> void:
	var slot: String = Catalog.EQUIPMENT[id].slot
	if equipment[slot] != "":
		equip_inv[equipment[slot]] = int(equip_inv.get(equipment[slot], 0)) + 1
	equipment[slot] = id
	equip_cond[slot] = cond
	_refresh_water()
	tank_changed.emit()
	changed.emit()
	_dirty = true


## Quita un aparato de la pecera y lo guarda para volver a ponerlo cuando quieras.
func remove_equipment(slot: String) -> void:
	var id: String = equipment.get(slot, "")
	if id == "":
		return
	equip_inv[id] = int(equip_inv.get(id, 0)) + 1
	equipment[slot] = ""
	equip_cond.erase(slot)
	equip_pos.erase(slot)
	_refresh_water()
	tank_changed.emit()
	changed.emit()
	_dirty = true
	toast.emit("%s retirado y guardado" % Catalog.EQUIPMENT[id].name, "gear")


func install_stored(id: String) -> void:
	if int(equip_inv.get(id, 0)) <= 0 or install_block(id) != "" or not Catalog.fits(Catalog.EQUIPMENT[id], water_kind):
		return
	equip_inv[id] = int(equip_inv[id]) - 1
	if equip_inv[id] == 0:
		equip_inv.erase(id)
	_install(id, 100.0)
	toast.emit("%s instalado" % Catalog.EQUIPMENT[id].name, "gear")


func rename_fish(id: int, new_name: String) -> void:
	var f := get_fish(id)
	new_name = new_name.strip_edges().left(16)
	if f.is_empty() or new_name == "":
		return
	f.name = new_name
	_dirty = true
	changed.emit()


## Compra al inventario y, si hay hueco, la coloca directamente.
func buy_decor(id: String) -> void:
	var d: Dictionary = Catalog.DECOR[id]
	if not Catalog.fits(d, water_kind):
		return
	if d.has("event") and current_event().get("id", "") != d.event:
		return
	if not spend(d.price, d.cur):
		return
	decor_inv[id] = int(decor_inv.get(id, 0)) + 1
	if decor.size() < decor_slots() and place_decor(id):
		_bought("%s colocado: arrástralo en modo Decorar" % d.name, "plant")
	else:
		_bought("%s guardado en el inventario" % d.name, "plant")


func buy_substrate(id: String) -> void:
	var s: Dictionary = Catalog.SUBSTRATES[id]
	if not Catalog.fits(s, water_kind):
		return
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


func buy_product(id: String) -> void:
	var pr: Dictionary = Catalog.PRODUCTS[id]
	if not spend(pr.price, "coins"):
		return
	products[id] = int(products.get(id, 0)) + pr.pack
	_bought("+%d %s" % [pr.pack, pr.name], "ph")


func use_product(id: String) -> bool:
	if int(products.get(id, 0)) <= 0:
		toast.emit("No te queda %s: cómpralo en la tienda" % Catalog.PRODUCTS[id].name, "ph")
		return false
	products[id] -= 1
	match id:
		"ph_up": ph_adjust = minf(ph_adjust + 0.3, 1.2)
		"ph_down": ph_adjust = maxf(ph_adjust - 0.3, -1.2)
		"oxigeno": o2_until = Time.get_unix_time_from_system() + 12.0 * 3600.0
		"sal": salinity = minf(1.035, salinity + 0.002)
		"med_ich", "med_hongos", "med_bact":
			var now := Time.get_unix_time_from_system()
			for f in fish:
				if f.get("dis", "") != "" and Catalog.DISEASES[f.dis].med == id:
					f.cure_at = now + 3.0 * 3600.0
		"antialgas":
			for i in algae.size():
				algae[i] = int(algae[i] * 0.6)
			algae_block_until = Time.get_unix_time_from_system() + 12.0 * 3600.0
			algae_changed.emit()
	_bump("maint", 1)
	_refresh_water()
	toast.emit("%s añadido al agua" % Catalog.PRODUCTS[id].name, "ph")
	changed.emit()
	_dirty = true
	return true


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
	# Racha: si ayer también jugaste, sube; si no, vuelve a 1. El premio se cobra desde el aviso.
	var yesterday := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
	streak.n = int(streak.get("n", 0)) + 1 if streak.get("last", "") == yesterday else 1
	streak.last = today
	streak.pending = true
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
			for it in decor:
				if Catalog.DECOR[it.id].kind == "plant":
					return 1
			return 0
		"maint": return int(stats.get("maint", 0))
		"vacuumed": return int(stats.get("vacuumed", 0))
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
	for o in orders:
		if fish.any(func(f): return order_matches(o, f)):
			return true
	return false


## Si alguien se queda sin peces ni dinero, un vecino le regala una pareja.
func _safety_net() -> void:
	var sp := "payaso" if water_kind == "salada" else "guppy"
	if fish.is_empty() and eggs.is_empty() and coins < Catalog.SPECIES[sp].price:
		for i in 2:
			_add_fish(Genetics.random_genes(sp, rng), 1.0, false)
		toast.emit("Un vecino te regala dos %s" % Catalog.SPECIES[sp].name.to_lower(), "fish")


func fmt_duration(s: float) -> String:
	s = maxf(0.0, s)
	if s < 60.0: return "%d s" % int(s)
	if s < 3600.0: return "%d min" % int(s / 60.0)
	if s < 86400.0: return "%d h %d min" % [int(s / 3600.0), int(fmod(s, 3600.0) / 60.0)]
	return "%d d %d h" % [int(s / 86400.0), int(fmod(s, 86400.0) / 3600.0)]



# ───────────────────────── Plantas que crecen ─────────────────────────

func plant_grows(id: String) -> bool:
	return Catalog.DECOR[id].kind == "plant" and not id in ["planta_rosa", "anemona"]


## Las plantas vivas crecen ~6% al día (más con luz y tierra nutritiva). Pasado el 130% piden poda.
func _grow_plants(m: float) -> void:
	var k := (1.0 if equipment.light != "" else 0.55) * (1.5 if substrate == "tierra" else 1.0)
	for it in decor:
		if plant_grows(it.id):
			it.g = minf(1.9, float(it.get("g", 1.0)) + 0.06 / 1440.0 * m * k)


func needs_prune(i: int) -> bool:
	return plant_grows(decor[i].id) and float(decor[i].get("g", 1.0)) >= 1.3


## Podar: la planta vuelve a un tamaño cómodo y el esqueje va al inventario (se planta o se vende).
func prune_decor(i: int) -> void:
	if i < 0 or i >= decor.size() or not needs_prune(i):
		return
	var id: String = decor[i].id
	decor[i].g = 0.9
	decor_inv[id] = int(decor_inv.get(id, 0)) + 1
	_bump("pruned", 1)
	add_xp(4)
	toast.emit("Podada. Tienes un esqueje de %s en el inventario" % Catalog.DECOR[id].name.to_lower(), "plant")
	_decor_changed()


# ───────────────────────── Pedidos de clientes ─────────────────────────

func _refresh_orders(now: float) -> void:
	var before := orders.size()
	orders = orders.filter(func(o): return float(o.expires) > now)
	if orders.size() < 3 and (now >= next_order_at or orders.is_empty()):
		var o := _new_order(now)
		if not o.is_empty():
			orders.append(o)
		next_order_at = now + 2.0 * 3600.0
	if orders.size() != before:
		_dirty = true


func _new_order(now: float) -> Dictionary:
	var waters := {}
	for t in tanks:
		waters[t.water_kind] = true
	waters[water_kind] = true
	var pool: Array = []
	for sp in Catalog.SPECIES_ORDER:
		var s: Dictionary = Catalog.SPECIES[sp]
		if s.level <= level + 1 and waters.has(s.water):
			pool.append(sp)
	if pool.is_empty():
		return {}
	var sp: String = pool[rng.randi() % pool.size()]
	var s: Dictionary = Catalog.SPECIES[sp]
	var kinds := ["adult"]
	if level >= 2: kinds += ["color", "pattern"]
	if level >= 4: kinds.append("mut")
	if level >= 5: kinds.append("rarity")
	var kind: String = kinds[rng.randi() % kinds.size()]
	var o := {"id": next_id, "who": Catalog.CUSTOMERS[rng.randi() % Catalog.CUSTOMERS.size()], "sp": sp, "kind": kind,
		"expires": now + 24.0 * 3600.0}
	next_id += 1
	var mult := 1.6
	match kind:
		"color":
			var fams: Array = []
			for pr in s.presets:
				var c := Color.html(pr[0])
				if c.s > 0.35 and not color_family(c.h) in fams:
					fams.append(color_family(c.h))
			if fams.is_empty():
				o.kind = "adult"
			else:
				o.color = fams[rng.randi() % fams.size()]
				mult = 2.0
		"pattern":
			o.pat = int(s.patterns[rng.randi() % s.patterns.size()])
			if s.patterns.size() < 2:
				o.kind = "adult"
			else:
				mult = 2.0
		"mut":
			o.mut = ["neon", "albino", "veil", "rare_col", "giant"][rng.randi() % 5]
			mult = 3.5
			o.pearls = 2
		"rarity":
			mult = 4.0
			o.pearls = 3
	o.coins = int(s.price * mult * (1.0 + level * 0.04))
	o.xp = int(10 + mult * 8)
	return o


static func color_family(h: float) -> int:
	if h < 0.03 or h >= 0.95: return 0
	if h < 0.11: return 1
	if h < 0.19: return 2
	if h < 0.45: return 3
	if h < 0.7: return 4
	if h < 0.83: return 5
	return 6


func order_text(o: Dictionary) -> String:
	var n: String = Catalog.SPECIES[o.sp].name
	match o.kind:
		"color": return "%s adulto de color %s" % [n, Catalog.COLOR_NAMES[o.color]]
		"pattern": return "%s adulto con patrón %s" % [n, Catalog.PATTERN_NAMES[o.pat].to_lower()]
		"mut": return "%s adulto con mutación %s" % [n, {"neon": "Neón", "albino": "Albino", "veil": "Velo", "rare_col": "Color raro", "giant": "Gigante"}[o.mut]]
		"rarity": return "%s adulto Raro o mejor" % n
	return "Un %s adulto y sano" % n.to_lower()


func order_matches(o: Dictionary, f: Dictionary) -> bool:
	var g: Dictionary = f.genes
	if g.sp != o.sp or f.grow < 1.0 or f.health < 50.0 or f.get("dis", "") != "":
		return false
	match o.kind:
		"color":
			var c := Color.from_hsv(g.a[0], g.a[1], g.a[2])
			return c.s > 0.3 and color_family(c.h) == int(o.color)
		"pattern": return int(g.pat) == int(o.pat)
		"mut":
			if o.mut == "giant": return g.size >= 1.22
			return bool(g[o.mut])
		"rarity": return Genetics.rarity(g) >= 2
	return true


func deliver_order(oid: int, fid: int) -> bool:
	var f := get_fish(fid)
	for o in orders:
		if int(o.id) == oid and order_matches(o, f):
			orders.erase(o)
			fish.erase(f)
			fish_removed.emit(fid)
			coins += int(o.coins)
			pearls += int(o.get("pearls", 0))
			add_xp(int(o.xp))
			_bump("orders", 1)
			toast.emit("%s está encantado con %s (+%d)" % [o.who, f.name, o.coins], "coin")
			changed.emit()
			return true
	return false


# ───────────────────────── Colección, racha y eventos ─────────────────────────

func variants_of(sp: String) -> int:
	var n := 0
	for k in discovered:
		n += int(String(k).begins_with(sp + "|"))
	return n


## Premio del álbum: 5 variantes de una especie = 3 perlas (una vez por especie).
func claim_album(sp: String) -> void:
	var done: Dictionary = stats.get("album", {})
	if done.has(sp) or variants_of(sp) < 5:
		return
	done[sp] = true
	stats.album = done
	pearls += 3
	toast.emit("¡Álbum de %s completo! +3 perlas" % Catalog.SPECIES[sp].name, "pearl")
	changed.emit()


func streak_day() -> int:
	return (int(streak.get("n", 1)) - 1) % Catalog.STREAK.size()


func claim_streak() -> void:
	if not streak.get("pending", false):
		return
	streak.pending = false
	var r: Dictionary = Catalog.STREAK[streak_day()]
	var k: String = r.kind
	if k == "coins":
		coins += int(r.n)
	elif k == "pearls":
		pearls += int(r.n)
	elif k.begins_with("food:"):
		food[k.substr(5)] = int(food.get(k.substr(5), 0)) + int(r.n)
	elif k == "egg":
		if space_left() > 0:
			var pool: Array = Catalog.SPECIES_ORDER.filter(func(sp): return Catalog.fits(Catalog.SPECIES[sp], water_kind) and Catalog.SPECIES[sp].level <= level + 2)
			var g := Genetics.random_genes(pool[rng.randi() % pool.size()], rng, 1)
			var now := Time.get_unix_time_from_system()
			eggs.append({"id": next_id, "genes": g, "hatch_at": now + 1800.0, "total": 1800.0, "x": rng.randf_range(0.25, 0.75), "parents": "Huevo misterioso"})
			next_id += 1
			eggs_changed.emit()
		else:
			pearls += 8
	toast.emit("Racha de %d días: %s" % [int(streak.get("n", 1)), r.text], "star")
	_dirty = true
	changed.emit()


## Evento de temporada activo ({} si no hay). `-- event=halloween` lo fuerza para probar.
func current_event() -> Dictionary:
	var forced := _arg("event")
	var d := Time.get_date_dict_from_system()
	var md: int = d.month * 100 + d.day
	for e in Catalog.EVENTS:
		if forced != "":
			if e.id == forced:
				return e
			continue
		var a: int = e.from[0] * 100 + e.from[1]
		var b: int = e.to[0] * 100 + e.to[1]
		if (a <= b and md >= a and md <= b) or (a > b and (md >= a or md <= b)):
			return e
	return {}


func event_days_left(e: Dictionary) -> int:
	var d := Time.get_date_dict_from_system()
	var end := {"year": d.year + (1 if e.to[0] < d.month else 0), "month": e.to[0], "day": e.to[1], "hour": 23, "minute": 59, "second": 0}
	return maxi(0, ceili((Time.get_unix_time_from_datetime_dict(end) - Time.get_unix_time_from_system()) / 86400.0))


func buy_event_fish() -> void:
	var e := current_event()
	if e.is_empty():
		return
	var info: Array = e.fish[water_kind]
	var s: Dictionary = Catalog.SPECIES[info[0]]
	if space_left() <= 0:
		toast.emit("Pecera llena: amplíala o vende algún pez", "tank")
		return
	if not spend(int(s.price * Catalog.EVENT_FISH_PRICE), "coins"):
		return
	var g := Genetics.random_genes(info[0], rng)
	for k in 3:
		g[["a", "b", "f"][k]] = Genetics._hsv(info[2][k])
	g.ev = e.id
	var f := _add_fish(g, 0.6, false)
	_bought("¡%s se une a tu pecera!" % info[1], "fish")
	f.name = info[1].get_slice(" ", 1)


# ───────────────────────── Varias peceras ─────────────────────────

func can_buy_tank_slot() -> String:
	if tanks.size() >= Catalog.TANK_SLOTS.size():
		return "Máximo de peceras"
	var slot: Dictionary = Catalog.TANK_SLOTS[tanks.size()]
	if level < slot.level:
		return "Nivel %d" % slot.level
	return ""


func buy_tank_slot(water_type: String) -> bool:
	if can_buy_tank_slot() != "":
		return false
	if not spend(int(Catalog.TANK_SLOTS[tanks.size()].price), "coins"):
		return false
	tanks[active] = _snapshot()
	_init_tank(water_type, "Pecera %d" % (tanks.size() + 1), false)
	tanks.append(_snapshot())
	active = tanks.size() - 1
	_refresh_water()
	_bought("¡Nueva pecera de %s!" % Catalog.WATER_NAMES[water_type].to_lower(), "tank")
	save_game()
	return true


## Cambia la pecera activa (la vista se recarga). Lo que pasó en la otra mientras no la mirabas se simula al volver.
func switch_tank(i: int) -> void:
	if i == active or i < 0 or i >= tanks.size():
		return
	tanks[active] = _snapshot()
	active = i
	_apply(tanks[i])
	_refresh_water()
	var gap := Time.get_unix_time_from_system() - last_sim
	if gap > 5.0:
		_catch_up(gap)
	last_sim = Time.get_unix_time_from_system()
	save_game()


func tank_space(i: int) -> int:
	var t: Dictionary = _snapshot() if i == active else tanks[i]
	return int(Catalog.TANKS[t.tank_tier].cap) - t.fish.size() - t.eggs.size()


## Muda un pez a otra pecera (mismo tipo de agua y con sitio).
func move_fish(id: int, to: int) -> String:
	var f := get_fish(id)
	if f.is_empty() or to == active or to < 0 or to >= tanks.size():
		return "No se puede"
	if tanks[to].water_kind != Catalog.SPECIES[f.genes.sp].water:
		return "Esa pecera es de %s" % Catalog.WATER_NAMES[tanks[to].water_kind].to_lower()
	if tank_space(to) <= 0:
		return "Esa pecera está llena"
	fish.erase(f)
	fish_removed.emit(id)
	tanks[to].fish.append(f)
	toast.emit("%s se ha mudado a %s" % [f.name, tanks[to].tank_name], "tank")
	changed.emit()
	_dirty = true
	return ""


# ───────────────────────── Notificaciones (Android) ─────────────────────────

func _notifier() -> Object:
	return Engine.get_singleton("AquaNotify") if Engine.has_singleton("AquaNotify") else null


## Pide permiso de notificaciones una sola vez (Android 13+), al acabar el tutorial o al arrancar.
func ask_notifications() -> void:
	var n := _notifier()
	if n and settings.notify and not stats.get("notif_asked", false):
		stats.notif_asked = true
		n.requestPermission()


func _schedule_notifications() -> void:
	var n := _notifier()
	if n == null:
		return
	n.cancelAll()
	if not settings.notify or not started:
		return
	for it in upcoming_notifications():
		n.schedule(it[0], it[1], it[2], it[3])


## Avisos que tocan mientras la app está cerrada: [id, título, texto, segundos hasta el aviso].
func upcoming_notifications() -> Array:
	var out: Array = []
	var now := Time.get_unix_time_from_system()
	var rate := HUNGER_PER_MIN * float(mk("hunger"))
	if not fish.is_empty() and rate > 0.0:
		var worst := 0.0
		for f in fish:
			worst = maxf(worst, float(f.hunger))
		var mins := (75.0 - worst) / rate
		if mins > 20.0:
			out.append([1, "Tus peces tienen hambre", "%s y compañía te esperan junto al cristal." % fish[0].name, int(mins * 60.0)])
	var first := INF
	for e in eggs:
		first = minf(first, float(e.hatch_at))
	if first < INF and first - now > 60.0:
		out.append([2, "¡Un huevo está a punto de eclosionar!", "Ven a conocer a la cría.", int(first - now)])
	var soonest := INF
	var what := ""
	for slot in equipment:
		var id: String = equipment[slot]
		if id == "":
			continue
		var w: float = Catalog.EQUIPMENT[id].wear * float(mk("wear"))
		if w <= 0.0 or condition(slot) <= 30.0:
			continue
		var hrs := (condition(slot) - 30.0) / w
		if hrs < soonest:
			soonest = hrs
			what = Catalog.EQUIPMENT[id].name
	if soonest < INF and soonest > 0.5:
		out.append([3, "%s necesita mantenimiento" % what, "Un aparato limpio es un acuario feliz.", int(soonest * 3600.0)])
	var d := Time.get_date_dict_from_system()
	var t19 := Time.get_unix_time_from_datetime_dict({"year": d.year, "month": d.month, "day": d.day, "hour": 19, "minute": 0, "second": 0}) + 86400
	out.append([4, "Tu racha de %d días te espera" % int(streak.get("n", 1)), "Entra hoy para no perderla y recoger tu premio.", int(t19 - now)])
	return out
