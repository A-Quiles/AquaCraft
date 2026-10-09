class_name Tutorial
extends Control
## Tutorial guiado de la primera partida. Oscurece todo menos lo que hay que tocar y avanza
## solo cuando el jugador lo hace (no bloquea los toques: el foco es solo visual).

const STEPS := [
	{"text": "¡Hola! Te enseño lo básico en un minuto: alimentar, limpiar, mantener el equipo, criar y decorar.", "wait": "button", "button": "¡Vamos!"},
	{"text": "Tus peces tienen hambre: el bocadillo dice qué comida quieren. Coge el bote de escamas de la estantería.", "target": "prop:food:escamas", "wait": "mode_feed"},
	{"text": "Toca el agua para echar escamas. Ojo: algunos peces solo comen un alimento, y lo que sobra se pudre y ensucia.", "target": "tank", "wait": "fed"},
	{"text": "Con el tiempo salen algas en el cristal, poco a poco. Coge el limpiacristales de la estantería…", "target": "prop:sponge", "wait": "mode_clean", "care": true},
	{"text": "…y frota el cristal con el dedo hasta que brille.", "target": "tank", "wait": "cleaned", "care": true},
	{"text": "Cada aparato se desgasta y necesita mantenimiento. Tu filtro está sucio: tócalo y mantén pulsado el botón.", "target": "equip:filter", "wait": "maint", "care": true},
	{"text": "En la estantería también tienes reguladores de pH y antialgas. Ahora, para criar, abre «Peces», elige un adulto y pulsa «Criar».", "target": "bar:fish", "wait": "fish_sheet"},
	{"text": "Dos adultos de la misma especie, sanos y felices, ponen un huevo. Las crías heredan colores, patrón y mutaciones: ¡los raros valen mucho más!", "wait": "button", "button": "Entendido"},
	{"text": "Por último, pulsa «Decorar»: arrastra plantas, adornos y también los aparatos (filtro, termómetro…) donde quieras.", "target": "bar:edit", "wait": "mode_edit"},
	{"text": "¡Listo! Las misiones te irán guiando. Disfruta de tu acuario.", "wait": "button", "button": "¡A bucear!"},
]

var hud: Node
var main: Node
var step := -1
var _hole := Rect2()
var _base := 0.0
var _card: PanelContainer
var _text: Label
var _next: Button
var _blockers: Array[Control] = []
var _modal_open := false   ## 4 franjas que bloquean los toques fuera del hueco


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 4:
		var b := Control.new()
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(b)
		_blockers.append(b)
	_card = UI.card(UI.CREAM, 30)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := UI.vbox(12)
	_text = UI.wrap(UI.label("", 25, UI.NAVY, UI.bold))
	v.add_child(_text)
	var row := UI.hbox(10)
	var skip := UI.button("Saltar tutorial", UI.SAND, Color("e2d3bd"))
	skip.add_theme_color_override("font_color", UI.MUTED)
	skip.add_theme_font_size_override("font_size", 20)
	skip.pressed.connect(_finish)
	row.add_child(skip)
	row.add_child(UI.spacer())
	_next = UI.button("", UI.CORAL, UI.CORAL_D)
	_next.pressed.connect(_advance)
	row.add_child(_next)
	v.add_child(row)
	_card.add_child(v)
	add_child(_card)
	_advance()


func _advance() -> void:
	step += 1
	# En modo Relax no hay algas ni desgaste: esos pasos sobran.
	while step < STEPS.size() and STEPS[step].get("care", false) and Game.mode == "basico":
		step += 1
	if step >= STEPS.size():
		_finish()
		return
	var s: Dictionary = STEPS[step]
	_tidy(s)
	_text.text = s.text
	_next.visible = s.wait == "button"
	_next.text = s.get("button", "")
	_base = _progress(s.wait)


## Deja la pantalla lista para el paso: sin modos activos que no tocan y sin hojas tapando el objetivo.
func _tidy(s: Dictionary) -> void:
	if not s.wait in ["fed", "cleaned"] and main.mode != main.Mode.NORMAL:
		main.set_mode(main.mode)
	if s.has("target"):
		while hud.back():
			pass


func _finish() -> void:
	if main.mode != main.Mode.NORMAL:
		main.set_mode(main.mode)
	Game.started = true
	Game.save_game()
	queue_free()


## Contador que debe subir para dar el paso por hecho.
func _progress(wait: String) -> float:
	match wait:
		"fed": return float(Game.stats.get("feed", 0))
		"cleaned": return float(Game.stats.get("cleaned", 0)) + float(Game.stats.get("clean_acc", 0.0))
		"maint": return float(Game.stats.get("maint", 0))
	return 0.0


func _done(wait: String) -> bool:
	match wait:
		"mode_feed": return main.mode == main.Mode.FEED
		"mode_clean": return main.mode == main.Mode.CLEAN
		"mode_edit": return main.mode == main.Mode.EDIT
		"fed": return _progress(wait) > _base
		"cleaned": return _progress(wait) >= _base + 3.0
		"maint": return _progress(wait) > _base or Game.equipment.filter == ""
		"fish_sheet": return hud._sheet is FishSheet and is_instance_valid(hud._sheet)
	return false


func _process(_dt: float) -> void:
	if step < 0 or step >= STEPS.size():
		return
	var s: Dictionary = STEPS[step]
	if s.wait != "button" and _done(s.wait):
		_advance()
		return
	_hole = _target_rect(s.get("target", ""))
	var vp := get_viewport_rect().size
	_card.custom_minimum_size.x = minf(vp.x - 40.0, 660.0)
	_card.reset_size()
	var y := 230.0 if _hole.size == Vector2.ZERO or _hole.get_center().y > vp.y * 0.5 else vp.y - _card.size.y - 330.0
	_card.position = Vector2((vp.x - _card.size.x) * 0.5, y + Hud.safe_margins().x)
	# Si el jugador está usando una ventana (p. ej. el mantenimiento), le dejamos hacerlo.
	_modal_open = hud._modal != null and is_instance_valid(hud._modal) and not hud._modal.closing
	var rects: Array = [Rect2(Vector2.ZERO, vp), Rect2(), Rect2(), Rect2()]
	if _modal_open:
		rects[0] = Rect2()
	elif _hole.size != Vector2.ZERO:
		var h := _hole.grow(6.0)
		rects = [Rect2(0, 0, vp.x, h.position.y), Rect2(0, h.end.y, vp.x, vp.y - h.end.y),
			Rect2(0, h.position.y, h.position.x, h.size.y), Rect2(h.end.x, h.position.y, vp.x - h.end.x, h.size.y)]
	for i in 4:
		_blockers[i].position = rects[i].position
		_blockers[i].size = rects[i].size
	queue_redraw()


func _target_rect(t: String) -> Rect2:
	if t.begins_with("prop:") and main.prop_rects.has(t.substr(5)):
		return main.prop_rects[t.substr(5)]
	if t.begins_with("bar:"):
		return (hud._bar[t.substr(4)] as Control).get_global_rect()
	var tank: TankView = main.tank
	if t == "tank":
		return Rect2(tank.global_position, tank.size)
	if t.begins_with("equip:") and tank.equip_rects.has(t.substr(6)):
		var r: Rect2 = tank.equip_rects[t.substr(6)]
		return Rect2(tank.global_position + r.position, r.size).grow(12.0)
	return Rect2()


func _draw() -> void:
	if _modal_open:
		return
	var vp := get_viewport_rect().size
	var dim := Color(0.02, 0.06, 0.1, 0.55)
	if _hole.size == Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, vp), dim)
		return
	var h := _hole.grow(6.0)
	draw_rect(Rect2(0, 0, vp.x, h.position.y), dim)
	draw_rect(Rect2(0, h.end.y, vp.x, vp.y - h.end.y), dim)
	draw_rect(Rect2(0, h.position.y, h.position.x, h.size.y), dim)
	draw_rect(Rect2(h.end.x, h.position.y, vp.x - h.end.x, h.size.y), dim)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
	draw_rect(h.grow(pulse * 6.0), Color(1.0, 0.85, 0.35, 0.9), false, 5.0)
