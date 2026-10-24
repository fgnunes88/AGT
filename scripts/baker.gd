extends Node
## "Assa" desenhos complexos em imagens prontas (texturas), uma vez só.
## Depois o jogo mostra só a imagem: no navegador isso é MUITO mais leve do que
## redesenhar dezenas de polígonos e círculos a cada quadro.
##
## request(chave, área, escala, quadros, desenhista) devolve uma lista de texturas
## (uma por quadro de animação). O desenhista é chamado como desenhista.call(ci, quadro).

var cache := {}
var pending: Array = []     # [viewport, lista de texturas, quadro] que ainda vão renderizar
var rendering: Array = []   # [viewport, lista, quadro, espera] já renderizando
var sprites := {}           # textura provisória -> sprites que a usam
const PER_FRAME := 8
var per_frame := PER_FRAME   # a tela de carregamento aumenta este valor
var queued := 0             # imagens pedidas desde o início
var done := 0               # imagens já prontas
var headless := DisplayServer.get_name() == "headless"   # testes automáticos (sem placa de vídeo)        # quantas imagens criar por quadro (evita engasgos)


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
		texs.append(vp.get_texture())
		pending.append([vp, texs, f])
		queued += 1
	cache[key] = texs
	return texs


func _process(_delta: float) -> void:
	# 1) imagens já desenhadas: copia para uma textura simples e apaga o viewport
	#    (cada viewport guarda buffers na placa de vídeo e o motor o visita todo quadro)
	var still: Array = []
	for r in rendering:
		r[3] -= 1
		if r[3] > 0:
			still.append(r)
			continue
		var vp: SubViewport = r[0]
		done += 1
		if headless:
			continue
		var img := vp.get_texture().get_image()
		if img != null and not img.is_empty():
			var old: Texture2D = r[1][r[2]]
			var tex := ImageTexture.create_from_image(img)
			r[1][r[2]] = tex
			for s in sprites.get(old, []):
				if is_instance_valid(s) and s.texture == old:
					s.texture = tex
			sprites.erase(old)
			vp.queue_free()
		# se a cópia falhar, o viewport continua servindo como imagem
	rendering = still
	# 2) libera alguns viewports por quadro para renderizarem uma única vez
	var n := 0
	while pending.size() > 0 and n < per_frame:
		var it: Array = pending.pop_front()
		var vp2: SubViewport = it[0]
		vp2.render_target_update_mode = SubViewport.UPDATE_ONCE
		rendering.append([vp2, it[1], it[2], 2])
		n += 1


## Ainda há imagens sendo preparadas?
func busy() -> bool:
	return pending.size() > 0 or rendering.size() > 0


## Mostra uma textura assada no lugar certo (a área original do desenho).
func make_sprite(tex: Texture2D, area: Rect2, scale: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	if tex is ViewportTexture:
		if not sprites.has(tex):
			sprites[tex] = []
		sprites[tex].append(s)
	s.centered = false
	s.position = area.position
	s.scale = Vector2(1.0 / scale, 1.0 / scale)
	s.material = CanvasItemMaterial.new()
	(s.material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	return s
