extends SceneTree
## Lámina con todos los iconos sobre el fondo de la interfaz: godot -s tests/icon_sheet.gd -- out.png

const KINDS := ["coin", "pearl", "food", "sponge", "shop", "fish", "egg", "missions", "thermo", "ph", "o2", "sparkle", "star",
	"heart", "health", "close", "plus", "minus", "back", "check", "lock", "clock", "dna", "tank", "gear", "plant", "happy"]


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://icons.png"
	await process_frame
	var bg := ColorRect.new()
	bg.color = Color("0e1a2b")
	bg.size = root.get_visible_rect().size
	root.add_child(bg)
	for i in KINDS.size():
		var ic := VIcon.make(KINDS[i], 64)
		ic.position = Vector2(30 + (i % 6) * 115, 30 + (i / 6) * 120)
		ic.size = Vector2(64, 64)
		root.add_child(ic)
		var l := Label.new()
		l.text = KINDS[i]
		l.position = ic.position + Vector2(0, 70)
		root.add_child(l)
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(out)
	quit()
