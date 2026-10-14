extends SceneTree
## Galería de estilos para revisarlos de un vistazo (necesita pantalla):
##   godot --resolution 720x1280 -s tests/style_gallery.gd -- out.png wall|stand|backdrop|ambience|theme


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://style_gallery.png"
	var kind: String = args[1] if args.size() > 1 else "wall"
	var ids: Array = ([""] + Catalog.THEME_ORDER) if kind == "ambience" else (Catalog.THEME_ORDER if kind == "theme" else Catalog.style_items(kind).keys())
	await process_frame
	var vw := root.get_visible_rect().size.x
	var bg := ColorRect.new()
	bg.color = Color("fff7ee")
	bg.size = root.get_visible_rect().size
	root.add_child(bg)
	var cols := 2
	var w := (vw - 30.0) / cols - 10.0
	var h := w * 0.62
	for i in ids.size():
		var t := Previews.style(kind, ids[i], h)
		t.position = Vector2(15 + (i % cols) * (w + 10), 10 + (i / cols) * (h + 34))
		t.size = Vector2(w, h)
		root.add_child(t)
		var l := Label.new()
		l.text = str(ids[i])
		l.add_theme_color_override("font_color", Color.BLACK)
		l.position = t.position + Vector2(4, h + 2)
		root.add_child(l)
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(out)
	quit()
