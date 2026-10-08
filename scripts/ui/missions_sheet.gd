class_name MissionsSheet
extends Sheet
## Nivel, misión principal (historia/tutorial), diarias y colección.


func _init() -> void:
	super("Misiones", 0.8)
	_build()


func _build() -> void:
	clear_body()
	var v := scroll_area()

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
