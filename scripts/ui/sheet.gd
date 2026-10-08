class_name Sheet
extends Control
## Hoja inferior que sube desde abajo (tienda, peces, misiones). Fondo oscurecido: tocar fuera cierra.

signal closed

var panel: PanelContainer
var body: VBoxContainer              ## aquí van los contenidos
var header: HBoxContainer
var title_label: Label
var _dim: ColorRect


func _init(title_text: String, height_frac := 0.8) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0.03, 0.08, 0.13, 0.0)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(func(e: InputEvent):
		if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.pressed:
			close())
	add_child(_dim)
	panel = PanelContainer.new()
	var st := UI.box(UI.CREAM, 36)
	st.corner_radius_bottom_left = 0
	st.corner_radius_bottom_right = 0
	st.content_margin_left = 26
	st.content_margin_right = 26
	st.content_margin_top = 16
	st.content_margin_bottom = 20 + Hud.safe_margins().y
	st.shadow_color = Color(0, 0, 0, 0.3)
	st.shadow_size = 22
	panel.add_theme_stylebox_override("panel", st)
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0 - height_frac
	panel.anchor_bottom = 1.0
	add_child(panel)
	var v := UI.vbox(14)
	panel.add_child(v)
	var grip := ColorRect.new()
	grip.color = Color(0, 0, 0, 0.12)
	grip.custom_minimum_size = Vector2(70, 7)
	grip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grip)
	header = UI.hbox(12)
	title_label = UI.title(title_text, 38)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	var x := Button.new()
	x.flat = true
	x.custom_minimum_size = Vector2(64, 64)
	x.focus_mode = Control.FOCUS_NONE
	for k in ["normal", "hover", "pressed"]:
		x.add_theme_stylebox_override(k, UI.box(UI.SAND, 32))
	var xi := VIcon.make("close", 26)
	xi.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	x.add_child(xi)
	x.pressed.connect(close)
	header.add_child(x)
	v.add_child(header)
	body = UI.vbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)


func _ready() -> void:
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	panel.position.y = get_viewport_rect().size.y
	tw.tween_property(_dim, "color:a", 0.42, 0.25)
	tw.tween_property(panel, "position:y", get_viewport_rect().size.y * panel.anchor_top, 0.3).from(get_viewport_rect().size.y)


func close() -> void:
	if is_queued_for_deletion():
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(_dim, "color:a", 0.0, 0.2)
	tw.tween_property(panel, "position:y", get_viewport_rect().size.y, 0.22)
	tw.chain().tween_callback(queue_free)
	closed.emit()


## Contenedor con scroll que ocupa el resto de la hoja.
func scroll_area() -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.scroll_deadzone = 12
	body.add_child(sc)
	var v := UI.vbox(14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	return v


## Fila de pestañas. Devuelve los botones; on_pick recibe el índice.
func tabs(names: Array, current: int, on_pick: Callable) -> Array:
	var row := UI.hbox(8)
	var out: Array = []
	for i in names.size():
		var b := UI.button(names[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 21)
		b.custom_minimum_size.y = 58
		if i != current:
			for k in ["normal", "hover"]:
				b.add_theme_stylebox_override(k, UI.box(UI.SAND, 22, 6, Color("e2d3bd")))
			b.add_theme_color_override("font_color", UI.MUTED)
			b.add_theme_color_override("font_hover_color", UI.MUTED)
		b.pressed.connect(on_pick.bind(i))
		row.add_child(b)
		out.append(b)
	body.add_child(row)
	return out


func clear_body() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
