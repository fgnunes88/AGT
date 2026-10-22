extends Node
## "Assa" desenhos complexos em imagens prontas (texturas), uma vez só.
## Depois o jogo mostra só a imagem: no navegador isso é MUITO mais leve do que
## redesenhar dezenas de polígonos e círculos a cada quadro.
##
## request(chave, área, escala, quadros, desenhista) devolve uma lista de texturas
## (uma por quadro de animação). O desenhista é chamado como desenhista.call(ci, quadro).

var cache := {}
var pending: Array = []     # viewports que ainda vão renderizar
const PER_FRAME := 8        # quantas imagens criar por quadro (evita engasgos)


class BakeNode extends Node2D:
	var drawer: Callable
	var frame := 0

	func _draw() -> void:
		drawer.call(self, frame)


func has(key: String) -> bool:
	return cache.has(key)


func get_frames(key: String) -> Array:
	return cache.get(key, [])


## Cria (ou reaproveita) as texturas. A área está nas coordenadas do desenho.
func request(key: String, area: Rect2, scale: float, frames: int, drawer: Callable) -> Array:
	if cache.has(key):
		return cache[key]
	var texs: Array = []
	for f in frames:
		var vp := SubViewport.new()
		vp.size = Vector2i(maxi(1, ceili(area.size.x * scale)), maxi(1, ceili(area.size.y * scale)))
		vp.transparent_bg = true
		vp.disable_3d = true
		vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		var n := BakeNode.new()
		n.drawer = drawer
		n.frame = f
		n.scale = Vector2(scale, scale)
		n.position = -area.position * scale
		vp.add_child(n)
		add_child(vp)
		pending.append(vp)
		texs.append(vp.get_texture())
	cache[key] = texs
	return texs


func _process(_delta: float) -> void:
	# libera alguns viewports por quadro para renderizarem uma única vez
	var n := 0
	while pending.size() > 0 and n < PER_FRAME:
		var vp: SubViewport = pending.pop_front()
		if is_instance_valid(vp):
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		n += 1


## Mostra uma textura assada no lugar certo (a área original do desenho).
static func make_sprite(tex: Texture2D, area: Rect2, scale: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = area.position
	s.scale = Vector2(1.0 / scale, 1.0 / scale)
	s.material = CanvasItemMaterial.new()
	(s.material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	return s
