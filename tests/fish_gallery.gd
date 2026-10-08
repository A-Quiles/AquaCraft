extends SceneTree
## Galería de especies para revisar el shader de peces (necesita pantalla, no headless):
##   godot -s tests/fish_gallery.gd -- out.png

const FISH_SHADER := preload("res://shaders/fish.gdshader")


func _init() -> void:
	var out := "user://fish_gallery.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	root.size = Vector2i(960, 1440)
	var bg := ColorRect.new()
	bg.color = Color("0b4a63")
	bg.size = Vector2(960, 1440)
	root.add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var i := 0
	for sp in Catalog.SPECIES_ORDER:
		for v in 1:
			var g := Genetics.random_genes(sp, rng, 0)
			var node := FishPreview.make(g, 1.6)
			var c := Vector2(160 + (i % 3) * 320, 90 + (i / 3) * 270)
			node.position = c - node.custom_minimum_size * 0.5 + Vector2(0, 40)
			root.add_child(node)
			i += 1
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
