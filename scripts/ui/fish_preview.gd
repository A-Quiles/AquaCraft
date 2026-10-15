class_name FishPreview
extends Control
## Pez 3D para la interfaz (tarjetas de tienda, fichas...). Cada miniatura tiene su propio escenario;
## solo las animadas se vuelven a dibujar cada fotograma (las demás se dibujan una vez: ahorra batería).

var genes: Dictionary
var animate := false
var _stage: FishStage
var _model: MeshInstance3D
var _tex: TextureRect


static func make(g: Dictionary, zoom := 1.0, anim := false) -> FishPreview:
	var p := FishPreview.new()
	p.genes = g
	p.animate = anim
	p.custom_minimum_size = FishArt.size_px(g) * zoom
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _ready() -> void:
	_stage = FishStage.new()
	add_child(_stage)
	_model = FishArt.model(genes)
	FishArt.set_param(_model, "auto_wag", 5.0)
	FishArt.set_param(_model, "wag_amp", 0.7)
	_model.rotation.y = -0.22                    # un poco de tres cuartos: se ve el volumen
	_stage.add_child(_model)
	_tex = TextureRect.new()
	_tex.texture = _stage.get_texture()
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	_tex.material = mat
	_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_tex)
	resized.connect(_fit)
	_fit()


func _fit() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	var want := FishArt.size_px(genes)
	var k := minf(size.x / want.x, size.y / want.y)
	var px := get_viewport().get_final_transform().get_scale().x if is_inside_tree() else 1.0
	_stage.frame(size, clampf(px, 1.0, 2.5))
	_model.position = FishStage.to3d(size * 0.5)
	_model.scale = Vector3.ONE * want.x * k * 0.5
	_stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS if animate else SubViewport.UPDATE_ONCE
