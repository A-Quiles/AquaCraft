extends SceneTree
## Galería de especies para revisar el shader de peces (necesita pantalla, no headless):
##   godot -s tests/fish_gallery.gd -- out.png

const FISH_SHADER := preload("res://shaders/fish.gdshader")


func _init() -> void:
	var out := "user://fish_gallery.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	root.size = Vector2i(900, 1100)
	var bg := ColorRect.new()
	bg.color = Color("0b4a63")
	bg.size = Vector2(900, 1100)
	root.add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var y := 70.0
	for sp in Catalog.SPECIES_ORDER:
		var x := 90.0
		for v in 4:
			var g := Genetics.random_genes(sp, rng, [0, 0, 1, 2][v])
			var node := FishPreview.make(g, 1.6)
			node.position = Vector2(x, y)
			root.add_child(node)
			x += 210.0
		y += 118.0
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
