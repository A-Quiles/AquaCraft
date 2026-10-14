extends SceneTree
## Galería ampliada para revisar detalles del pez: godot -s tests/fish_gallery_big.gd -- out.png [desde] [n] [zoom] [especies,separadas]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://fish_gallery_big.png"
	var from := int(args[1]) if args.size() > 1 else 0
	var n := int(args[2]) if args.size() > 2 else 9
	var zoom := float(args[3]) if args.size() > 3 else 2.4
	var list: Array = Catalog.SPECIES_ORDER.slice(from, from + n)
	if args.size() > 4:
		list = Array(args[4].split(","))
	var cols := 3 if zoom < 3.5 else 1
	await process_frame
	var cw := root.get_visible_rect().size.x / cols   # el proyecto escala el lienzo (720 de ancho)
	var rh := 140.0 * zoom if cols == 1 else 230.0
	var rows := ceili(list.size() / float(cols))
	var bg := ColorRect.new()
	bg.color = Color("0e5670")
	bg.size = Vector2(root.size)
	root.add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var i := 0
	for sp in list:
		var g := Genetics.random_genes(sp, rng, 0)
		var node := FishPreview.make(g, zoom)
		var c := Vector2(cw * 0.5 + (i % cols) * cw, rh * 0.5 + (i / cols) * rh)
		node.position = c - node.custom_minimum_size * 0.5
		root.add_child(node)
		var l := Label.new()
		l.text = sp
		l.position = c + Vector2(-60, rh * 0.36)
		root.add_child(l)
		i += 1
	await process_frame
	await process_frame
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png(out)
	quit()
