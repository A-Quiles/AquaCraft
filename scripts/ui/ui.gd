class_name UI
extends RefCounted
## Tema "cozy" y constructores de controles para que todas las pantallas se vean iguales.

const NAVY := Color("1d3557")
const MUTED := Color("6b7f95")
const TEAL := Color("1fb5ad")
const TEAL_D := Color("12857f")
const CORAL := Color("ff7a6b")
const CORAL_D := Color("d9554a")
const SUN := Color("ffb627")
const SUN_D := Color("d98a0b")
const LAV := Color("8f7bff")
const LAV_D := Color("6a55e0")
const CREAM := Color("fff8ee")
const SAND := Color("f3e9da")
const GOOD := Color("4fc27a")
const WARN := Color("ffb020")
const BAD := Color("ff5a5f")

static var body: FontVariation
static var bold: FontVariation
static var heading: FontVariation
static var theme: Theme


static func setup() -> Theme:
	if theme:
		return theme
	var ts := TextServerManager.get_primary_interface()
	var nunito: FontFile = load("res://assets/fonts/Nunito.ttf")
	var fredoka: FontFile = load("res://assets/fonts/Fredoka.ttf")
	body = _font(nunito, {ts.name_to_tag("wght"): 650})
	bold = _font(nunito, {ts.name_to_tag("wght"): 850})
	heading = _font(fredoka, {ts.name_to_tag("wght"): 600})
	var t := Theme.new()
	t.default_font = body
	t.default_font_size = 26
	t.set_color("font_color", "Label", NAVY)
	for st in ["normal", "hover", "focus"]:
		t.set_stylebox(st, "Button", box(TEAL, 22, 6, TEAL_D))
	t.set_stylebox("pressed", "Button", box(TEAL_D, 22, 2, TEAL_D, 4))
	t.set_stylebox("disabled", "Button", box(Color("c9d2db"), 22, 6, Color("aab6c2")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", bold)
	t.set_font_size("font_size", "Button", 25)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(k, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.9))
	t.set_stylebox("panel", "PanelContainer", box(Color.WHITE, 24))
	t.set_stylebox("background", "ProgressBar", box(Color("e3eaf0"), 10))
	t.set_stylebox("fill", "ProgressBar", box(TEAL, 10))
	t.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	t.set_stylebox("grabber", "VScrollBar", box(Color(0, 0, 0, 0.12), 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(Color(0, 0, 0, 0.2), 4))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(Color(0, 0, 0, 0.25), 4))
	theme = t
	return t


static func _font(f: FontFile, variation: Dictionary) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = f
	v.variation_opentype = variation
	return v


static func box(bg: Color, radius := 20, bottom := 0, border := Color.TRANSPARENT, top_pad := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 6
	s.border_width_bottom = bottom
	s.border_color = border
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 10 + top_pad
	s.content_margin_bottom = 10
	s.anti_aliasing = true
	return s


static func button_colors(b: Button, bg: Color, dark: Color) -> Button:
	for st in ["normal", "hover"]:
		b.add_theme_stylebox_override(st, box(bg, 22, 6, dark))
	b.add_theme_stylebox_override("pressed", box(dark, 22, 2, dark, 4))
	return b


static func label(text: String, size := 26, color := NAVY, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	return l


static func title(text: String, size := 36) -> Label:
	return label(text, size, NAVY, heading)


static func wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 10
	return l


static func button(text: String, bg := TEAL, dark := TEAL_D) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	if bg != TEAL:
		button_colors(b, bg, dark)
	return b


## Botón con icono + cantidad (precio). cur: "coins" / "pearls".
static func price_button(amount: int, cur: String, prefix := "") -> Button:
	var b := button("", SUN if cur == "coins" else LAV, SUN_D if cur == "coins" else LAV_D)
	b.custom_minimum_size = Vector2(0, 62)
	var h := hbox(8)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_bottom = -4
	if prefix != "":
		h.add_child(label(prefix, 24, Color.WHITE, bold))
	h.add_child(VIcon.make("coin" if cur == "coins" else "pearl", 30))
	h.add_child(label(_num(amount), 26, Color.WHITE, bold))
	b.add_child(h)
	return b


static func card(bg := Color.WHITE, radius := 24) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(bg, radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	s.shadow_color = Color(0.11, 0.2, 0.34, 0.1)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", s)
	return p


static func pill(text: String, bg: Color, fg := Color.WHITE, size := 20) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(bg, 14)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 2
	s.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", s)
	p.add_child(label(text, size, fg, bold))
	return p


static func bar(value: float, color: Color, h := 12.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = 100.0
	b.value = value
	b.show_percentage = false
	b.custom_minimum_size = Vector2(60, h)
	b.add_theme_stylebox_override("fill", box(color, 8))
	b.add_theme_stylebox_override("background", box(Color("e3eaf0"), 8))
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## Fila icono + barra (hambre, salud...)
static func stat_bar(icon: String, value: float, color: Color) -> HBoxContainer:
	var h := hbox(6)
	h.add_child(VIcon.make(icon, 22))
	var b := bar(value, color)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	return h


static func hbox(sep := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep := 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func rarity_pill(r: int) -> PanelContainer:
	return pill(Catalog.RARITY_NAMES[r], Catalog.color(Catalog.RARITY_COLORS[r]))


static func _num(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out


static func num(n: int) -> String:
	return _num(n)
