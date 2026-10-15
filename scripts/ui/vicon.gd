class_name VIcon
extends Control
## Iconos de la interfaz: siluetas de game-icons.net (CC BY 3.0, ver assets/icons/LICENSE.txt) tintadas
## con el color de cada uno, con sombra y un brillo arriba para darles relieve de videojuego.
## Unos pocos de trazo (más, menos, atrás) se dibujan en código.

const COLORS := {
	"coin": Color("f7c03e"), "pearl": Color("d9ccff"), "food": Color("ff9a52"), "sponge": Color("b8e05a"),
	"shop": Color("4fe3d2"), "fish": Color("ffa94d"), "egg": Color("ffd27a"), "missions": Color("8fe6ff"),
	"thermo": Color("ff7a6b"), "ph": Color("5ad0ff"), "o2": Color("7fe0ff"), "sparkle": Color("8ff5e4"),
	"star": Color("ffd23f"), "heart": Color("ff7a9a"), "health": Color("ff6b6b"), "lock": Color("9fb3c8"),
	"clock": Color("e8f1f7"), "dna": Color("b49cff"), "tank": Color("6fd8ff"), "gear": Color("d6e4f0"),
	"plant": Color("6fe39b"), "happy": Color("ffd23f"), "close": Color("e8f1f7"), "check": Color("ffffff"),
}
static var _tex := {}

var kind := "coin"
var tint := Color(0, 0, 0, 0)        ## si a > 0, el icono se pinta de ese color


static func make(k: String, px := 32.0, t := Color(0, 0, 0, 0)) -> VIcon:
	var i := VIcon.new()
	i.kind = k
	i.tint = t
	i.custom_minimum_size = Vector2(px, px)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


func set_kind(k: String) -> void:
	kind = k
	queue_redraw()


static func texture(k: String) -> Texture2D:
	if not _tex.has(k):
		var path := "res://assets/icons/%s.svg" % k
		_tex[k] = load(path) if ResourceLoader.exists(path) else null
	return _tex[k]


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := size * 0.5
	var col: Color = tint if tint.a > 0.0 else COLORS.get(kind, Color.WHITE)
	var t := texture(kind)
	if t:
		var rect := Rect2(c - Vector2(r, r) * 0.92, Vector2(r, r) * 1.84)
		draw_texture_rect(t, Rect2(rect.position + Vector2(0, r * 0.09), rect.size), false, Color(0.0, 0.03, 0.08, 0.45))
		draw_texture_rect(t, rect, false, col.darkened(0.12))
		# Brillo superior: la misma silueta un pelo más arriba y más clara, recortada por la de abajo.
		draw_texture_rect(t, Rect2(rect.position - Vector2(0, r * 0.035), rect.size), false, Color(col.lightened(0.35), 0.55))
		draw_texture_rect(t, Rect2(rect.position + Vector2(0, r * 0.02), rect.size), false, col)
		return
	var w := maxf(2.0, r * 0.2)
	var ink := tint if tint.a > 0.0 else Color.WHITE
	match kind:
		"plus", "minus":
			draw_line(c + Vector2(-r * 0.55, 0), c + Vector2(r * 0.55, 0), ink, w * 1.3, true)
			if kind == "plus":
				draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, r * 0.55), ink, w * 1.3, true)
		"back":
			draw_polyline(PackedVector2Array([c + Vector2(r * 0.25, -r * 0.6), c + Vector2(-r * 0.35, 0), c + Vector2(r * 0.25, r * 0.6)]), ink, w, true)
		_:
			draw_circle(c, r * 0.6, ink)
