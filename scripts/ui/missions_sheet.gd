class_name MissionsSheet
extends Sheet
## Nivel, misión principal (historia/tutorial), diarias y colección.


var tab := 0


func _init(start_tab := 0) -> void:
	super("Misiones", 0.84)
	tab = start_tab
	_build()


func _build() -> void:
	clear_body()
	tabs(["Misiones", "Pedidos %d" % Game.orders.size(), "Colección"], tab, func(i: int):
		tab = i
		_build())
	var v := scroll_area()
	match tab:
		1:
			_orders(v)
			return
		2:
			_album(v)
			return

	var lv := UI.card(Color("1d3557"))
	var lh := UI.hbox(16)
	lh.add_child(VIcon.make("star", 64))
	var lv_box := UI.vbox(6)
	lv_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv_box.add_child(UI.label("Nivel %d de acuarista" % Game.level, 28, Color.WHITE, UI.heading))
	var need := Game.xp_need(Game.level)
	lv_box.add_child(UI.bar(100.0 * Game.xp / need, UI.SUN, 16))
	lv_box.add_child(UI.label("%d / %d XP · %d variantes descubiertas" % [Game.xp, need, Game.discovered.size()], 20, Color(1, 1, 1, 0.75), UI.bold))
	lh.add_child(lv_box)
	lv.add_child(lh)
	v.add_child(lv)

	v.add_child(UI.title("Misión principal", 30))
	var s := Game.story()
	if s.is_empty():
		v.add_child(UI.label("¡Has completado la historia! Sigue criando leyendas.", 24, UI.MUTED, UI.bold))
	else:
		var prog := mini(Game.story_progress(), int(s.target))
		v.add_child(_mission_card(s.text, prog, s.target, s.coins, s.pearls, false, Game.claim_story))

	var dh := UI.hbox(10)
	dh.add_child(UI.title("Diarias", 30))
	var sub := UI.label("se renuevan cada día", 21, UI.MUTED, UI.bold)
	sub.size_flags_vertical = Control.SIZE_SHRINK_END
	dh.add_child(sub)
	v.add_child(dh)
	var missions: Array = Game.daily.get("missions", [])
	for i in missions.size():
		var m: Dictionary = missions[i]
		v.add_child(_mission_card(m.text, m.progress, m.target, m.coins, 0, m.claimed, Game.claim_daily.bind(i)))
	var bonus := UI.hbox(10)
	bonus.add_child(VIcon.make("pearl", 34))
	var bl := UI.label("Completa las 3 diarias: +3 perlas" + (" (cobrado)" if Game.daily.get("bonus", false) else ""), 22, UI.LAV_D, UI.bold)
	bonus.add_child(bl)
	v.add_child(bonus)


func _mission_card(text: String, prog: int, target: int, coins: int, pearls: int, claimed: bool, on_claim: Callable) -> Control:
	var c := UI.card()
	var h := UI.hbox(14)
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.wrap(UI.label(text, 24, UI.NAVY, UI.bold)))
	var pr := UI.hbox(10)
	var b := UI.bar(100.0 * prog / maxf(1.0, target), UI.TEAL, 14)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pr.add_child(b)
	pr.add_child(UI.label("%d/%d" % [prog, target], 20, UI.MUTED, UI.bold))
	v.add_child(pr)
	var rw := UI.hbox(6)
	if coins > 0:
		rw.add_child(VIcon.make("coin", 26))
		rw.add_child(UI.label(str(coins), 21, UI.NAVY, UI.bold))
	if pearls > 0:
		rw.add_child(VIcon.make("pearl", 26))
		rw.add_child(UI.label(str(pearls), 21, UI.NAVY, UI.bold))
	v.add_child(rw)
	h.add_child(v)
	var btn: Button
	if claimed:
		btn = UI.button("Hecho")
		btn.disabled = true
	elif prog >= target:
		btn = UI.button("¡Cobrar!", UI.CORAL, UI.CORAL_D)
		btn.pressed.connect(func():
			on_claim.call()
			_build())
	else:
		btn = UI.button("En curso")
		btn.disabled = true
	btn.custom_minimum_size = Vector2(150, 64)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btn)
	c.add_child(h)
	return c


# ───────────────────────── Pedidos ─────────────────────────

func _orders(v: VBoxContainer) -> void:
	v.add_child(UI.wrap(UI.label("Los clientes buscan peces concretos y pagan mucho más que la tienda. Llegan pedidos nuevos cada pocas horas.", 21, UI.MUTED, UI.bold)))
	if Game.orders.is_empty():
		v.add_child(UI.label("No hay pedidos ahora mismo. Vuelve en un rato.", 23, UI.MUTED, UI.bold))
		return
	var now := Time.get_unix_time_from_system()
	for o in Game.orders:
		var c := UI.card()
		var h := UI.hbox(12)
		var r := RandomNumberGenerator.new()
		r.seed = hash(o.sp)
		var bg := PanelContainer.new()
		bg.add_theme_stylebox_override("panel", UI.box(Color("dff3f5"), 18))
		var pv := Previews.fish(Genetics.random_genes(o.sp, r), 110, 170)
		pv.custom_minimum_size.x = 170
		bg.add_child(pv)
		h.add_child(bg)
		var col := UI.vbox(4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UI.label(o.who, 23, UI.NAVY, UI.heading))
		col.add_child(UI.wrap(UI.label("Busca: " + Game.order_text(o), 20, UI.NAVY, UI.bold)))
		var rw := UI.hbox(6)
		rw.add_child(VIcon.make("coin", 24))
		rw.add_child(UI.label(str(o.coins), 20, UI.NAVY, UI.bold))
		if int(o.get("pearls", 0)) > 0:
			rw.add_child(VIcon.make("pearl", 24))
			rw.add_child(UI.label(str(o.pearls), 20, UI.NAVY, UI.bold))
		rw.add_child(UI.label("  · quedan %s" % Game.fmt_duration(float(o.expires) - now), 18, UI.MUTED, UI.bold))
		col.add_child(rw)
		h.add_child(col)
		var cands: Array = Game.fish.filter(func(f): return Game.order_matches(o, f))
		var b := UI.button("Entregar" if not cands.is_empty() else "Sin pez", UI.CORAL if not cands.is_empty() else UI.TEAL, UI.CORAL_D if not cands.is_empty() else UI.TEAL_D)
		b.disabled = cands.is_empty()
		b.custom_minimum_size = Vector2(130, 60)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(_pick_for_order.bind(o, cands))
		h.add_child(b)
		c.add_child(h)
		v.add_child(c)


func _pick_for_order(o: Dictionary, cands: Array) -> void:
	var m := Modal.new()
	m.centered(UI.title("¿Cuál entregas?", 36))
	m.box.add_child(UI.wrap(UI.label("%s paga %d monedas. El pez se va con su nuevo dueño." % [o.who, o.coins], 21, UI.MUTED)))
	var list := m.scroll_box(minf(520.0, get_viewport_rect().size.y * 0.45))
	for f in cands:
		var b := UI.button("%s · %s" % [f.name, Catalog.RARITY_NAMES[Genetics.rarity(f.genes)]], UI.CORAL, UI.CORAL_D)
		b.pressed.connect(func():
			Game.deliver_order(int(o.id), int(f.id))
			m.close()
			_build())
		list.add_child(b)
	get_parent()._show_modal(m)


# ───────────────────────── Colección ─────────────────────────

func _album(v: VBoxContainer) -> void:
	var have := 0
	for sp in Catalog.SPECIES_ORDER:
		have += int(Game.variants_of(sp) > 0)
	v.add_child(UI.label("%d de %d especies · %d variantes" % [have, Catalog.SPECIES_ORDER.size(), Game.discovered.size()], 23, UI.NAVY, UI.bold))
	v.add_child(UI.wrap(UI.label("Consigue 5 variantes de una especie (colores, patrones, mutaciones) para ganar 3 perlas.", 20, UI.MUTED)))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	v.add_child(g)
	var claimed: Dictionary = Game.stats.get("album", {})
	for sp in Catalog.SPECIES_ORDER:
		var s: Dictionary = Catalog.SPECIES[sp]
		var n := Game.variants_of(sp)
		var c := UI.card(Color.WHITE if n > 0 else Color("eef1f4"))
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col := UI.vbox(4)
		var r := RandomNumberGenerator.new()
		r.seed = hash(sp)
		var genes := Genetics.random_genes(sp, r)
		if n == 0:
			# Silueta: aún no la tienes (el shader ignora modulate, así que se pinta oscura).
			for k in ["a", "b", "f"]:
				genes[k] = [0.55, 0.3, 0.16]
		var pv := Previews.fish(genes, 90, 200)
		col.add_child(pv)
		col.add_child(UI.label(s.name if n > 0 else "???", 22, UI.NAVY, UI.heading))
		col.add_child(UI.label("%s · %d variantes" % ["Dulce" if s.water == "dulce" else "Salada", n], 18, UI.MUTED, UI.bold))
		if claimed.has(sp):
			col.add_child(UI.label("Álbum completo", 18, UI.GOOD, UI.bold))
		elif n >= 5:
			var b := UI.button("+3 perlas", UI.LAV, UI.LAV_D)
			b.pressed.connect(func():
				Game.claim_album(sp)
				_build())
			col.add_child(b)
		else:
			col.add_child(UI.bar(100.0 * n / 5.0, UI.TEAL, 10))
		c.add_child(col)
		g.add_child(c)
