class_name UI
extends RefCounted
## Tema oscuro tipo cristal y constructores de controles para que todas las pantallas se vean iguales.
## NAVY es el color del texto (claro sobre paneles azul noche); CREAM, el fondo de hojas y ventanas.

const NAVY := Color("e8f1f7")         ## texto principal
const MUTED := Color("8ea4b9")        ## texto secundario
const DARK := Color("0e1a2b")         ## texto sobre botones claros (dorado) y fondo base
const TEAL := Color("2ec4b6")         ## acento
const TEAL_D := Color("1f9488")
const CORAL := Color("ff6b5e")
const CORAL_D := Color("cf4a3f")
const SUN := Color("f2b53a")
const SUN_D := Color("c98c17")
const LAV := Color("8c7af0")
const LAV_D := Color("6550d0")
const CREAM := Color(0.055, 0.1, 0.17, 0.97)   ## hojas y ventanas
const CARD := Color(0.09, 0.15, 0.23, 0.92)    ## tarjetas dentro de las hojas
const SAND := Color("1c3048")         ## botones secundarios y pestañas
const SAND_D := Color("132235")
const LINE := Color(1, 1, 1, 0.08)    ## filo fino de paneles
const GOOD := Color("4fd18b")
const WARN := Color("f2b53a")
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
	var lilita: FontFile = load("res://assets/fonts/LilitaOne.ttf")
	body = _font(nunito, {ts.name_to_tag("wght"): 650})
	bold = _font(nunito, {ts.name_to_tag("wght"): 850})
	heading = FontVariation.new()                 # rótulos, botones y cifras: redonda y gruesa, con carácter
	heading.base_font = lilita
	heading.spacing_glyph = 1
	var t := Theme.new()
	t.default_font = body
	t.default_font_size = 26
	t.set_color("font_color", "Label", NAVY)
	for st in ["normal", "hover", "focus"]:
		t.set_stylebox(st, "Button", Glass.button(TEAL))
	t.set_stylebox("pressed", "Button", Glass.button(TEAL, true))
	t.set_stylebox("disabled", "Button", Glass.button(Color(SAND_D, 0.8)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", heading)
	t.set_font_size("font_size", "Button", 25)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(k, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_stylebox("panel", "PanelContainer", Glass.card())
	t.set_stylebox("background", "ProgressBar", box(Color(1, 1, 1, 0.08), 10))
	t.set_stylebox("fill", "ProgressBar", box(TEAL, 10))
	t.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	t.set_stylebox("grabber", "VScrollBar", box(Color(1, 1, 1, 0.12), 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(Color(1, 1, 1, 0.2), 4))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(Color(1, 1, 1, 0.25), 4))
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


## Botón de cristal con relieve (ver Glass).
static func btn_box(bg: Color) -> StyleBox:
	return Glass.button(bg)


static func button_colors(b: Button, bg: Color, dark: Color) -> Button:
	for st in ["normal", "hover"]:
		b.add_theme_stylebox_override(st, Glass.button(bg))
	b.add_theme_stylebox_override("pressed", Glass.button(bg, true))
	if bg.get_luminance() > 0.55:                  # botón claro (dorado): texto oscuro
		for k in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(k, DARK)
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
	b.pressed.connect(click)
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
		h.add_child(label(prefix, 24, DARK if cur == "coins" else Color.WHITE, bold))
	h.add_child(VIcon.make("coin" if cur == "coins" else "pearl", 30, Color("8a5200") if cur == "coins" else Color(0, 0, 0, 0)))
	h.add_child(label(_num(amount), 26, DARK if cur == "coins" else Color.WHITE, bold))
	b.add_child(h)
	return b


## Sonido de botón (UI es estático: busca el autoload por la ruta).
static func click() -> void:
	var s := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Sfx")
	if s:
		s.play("click", 40, -8.0)


## Tarjeta de cristal; con CREAM, panel grande con la superficie del agua ondulada (ventanas, avisos).
static func card(bg := CARD, _radius := 18) -> PanelContainer:
	var p := PanelContainer.new()
	var sb: StyleBox = Glass.panel() if bg == CREAM else Glass.card(Color(bg.r, bg.g, bg.b), bg.a)
	p.add_theme_stylebox_override("panel", sb)
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
	b.add_theme_stylebox_override("background", box(Color(1, 1, 1, 0.08), 8))
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
