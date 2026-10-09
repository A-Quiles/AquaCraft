class_name Modal
extends Control
## Tarjeta centrada con fondo oscurecido (bienvenida, subida de nivel, termostato...).

signal closed

var box: VBoxContainer
var _card: PanelContainer
var _dim: ColorRect


func _init(dismiss_on_tap := true) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0.03, 0.08, 0.13, 0.0)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if dismiss_on_tap:
		_dim.gui_input.connect(func(e: InputEvent):
			if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.pressed:
				close())
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_card = UI.card(UI.CREAM, 36)
	_card.custom_minimum_size = Vector2(600, 0)
	center.add_child(_card)
	var m := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(k, 18)
	_card.add_child(m)
	box = UI.vbox(18)
	m.add_child(box)


func _ready() -> void:
	_card.pivot_offset = _card.size * 0.5
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_dim, "color:a", 0.5, 0.2)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.32).from(Vector2(0.8, 0.8))
	_card.resized.connect(func(): _card.pivot_offset = _card.size * 0.5)


var closing := false


func close() -> void:
	if is_queued_for_deletion() or closing:
		return
	closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween().set_parallel()
	tw.tween_property(_dim, "color:a", 0.0, 0.15)
	tw.tween_property(_card, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(queue_free)
	closed.emit()


func centered(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(c)
	return c
