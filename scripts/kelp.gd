extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Floresta de algas: Arthur fica escondido dos drones quando está aqui dentro.
## Desenhada em duas camadas (fundo mais escuro e frente mais clara) com folhas e bolinhas de ar.

var rect := Rect2()
var color := Color(0.2, 0.8, 0.35)
var t := 0.0
var stalks: Array = []   # [x, altura, fase, camada]


var lite := false


var sprite: Sprite2D
var frames: Array = []
const PERIOD := TAU / 1.2     # tempo de um balanço completo das algas
const FRAMES := 8


func setup(r: Rect2, zone: int, is_lite := false, baker = null) -> void:
	lite = is_lite
	rect = r
	match zone:
		0: color = Color(0.30, 0.82, 0.32)
		1: color = Color(0.18, 0.66, 0.46)
		2: color = Color(0.72, 0.35, 1.0)      # algas neon da penumbra
		_: color = Color(0.2, 0.9, 0.9)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x * 7 + r.position.y * 13)
	var n := int(r.size.x / 26.0)
	for layer in range(2):
		for i in range(n):
			stalks.append([r.position.x + 12 + i * 26 + rng.randf_range(-8, 8) + layer * 13, r.size.y * rng.randf_range(0.75, 1.02), rng.randf() * TAU, layer])
	if baker != null:
		# no navegador: as algas viram uma pequena animação de imagens prontas
		var area := Rect2(r.position.x - 70, r.position.y - 40, r.size.x + 140, r.size.y + 90)
		frames = baker.request("kelp_%d_%d" % [int(r.position.x), int(r.position.y)], area, 0.6, FRAMES, _make_drawer(r, color, stalks))
		sprite = baker.make_sprite(frames[0], area, 0.6)
		add_child(sprite)


static func _make_drawer(r: Rect2, c: Color, st: Array) -> Callable:
	return func(ci: CanvasItem, f: int) -> void:
		paint(ci, r, c, st, f * PERIOD / FRAMES)


func contains(p: Vector2) -> bool:
	return rect.has_point(p)


func _process(delta: float) -> void:
	t += delta
	# só anima quando está perto da câmera (economiza processamento)
	var cam := get_viewport().get_camera_2d()
	if sprite != null:
		sprite.texture = frames[int(fposmod(t, PERIOD) / PERIOD * FRAMES) % FRAMES]
		return
	if not Cull.tick(self, 3):
		return
	if cam == null or rect.grow(900).has_point(cam.get_screen_center_position()):
		queue_redraw()


static func _leaf(ci: CanvasItem, base: Vector2, dirx: float, size: float, col: Color, line: Color) -> void:
	var tip := base + Vector2(dirx * size, -size * 0.45)
	var mid1 := base + Vector2(dirx * size * 0.5, -size * 0.45)
	var mid2 := base + Vector2(dirx * size * 0.55, size * 0.05)
	var pts := PackedVector2Array([base, mid1, tip, mid2])
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(PackedVector2Array([base, mid1, tip, mid2, base]), line, 1.5, true)
	ci.draw_line(base, tip, col.lightened(0.25), 1.2)


func _draw() -> void:
	if sprite == null:
		paint(self, rect, color, stalks, t)


static func paint(ci: CanvasItem, rect: Rect2, color: Color, stalks: Array, tt: float) -> void:
	var bottom := rect.end.y
	# rocha na base
	var rock := PackedVector2Array([Vector2(rect.position.x - 50, bottom + 34), Vector2(rect.position.x - 10, bottom - 14),
		Vector2(rect.position.x + rect.size.x * 0.4, bottom - 24), Vector2(rect.end.x + 10, bottom - 12), Vector2(rect.end.x + 50, bottom + 34)])
	ci.draw_polygon(rock, PackedColorArray([Color(0.2, 0.18, 0.25), Color(0.36, 0.32, 0.4), Color(0.4, 0.36, 0.44), Color(0.36, 0.32, 0.4), Color(0.2, 0.18, 0.25)]))
	ci.draw_polyline(rock, Color(0.12, 0.1, 0.15), 3, true)
	for s in stalks:
		var x: float = s[0]
		var h: float = s[1]
		var ph: float = s[2]
		var layer: int = s[3]
		var col := color.darkened(0.35) if layer == 0 else color
		var line := color.darkened(0.65)
		var pts := PackedVector2Array()
		for k in range(11):
			var f := k / 10.0
			pts.append(Vector2(x + sin(tt * 1.2 + ph + f * 3.0) * 16.0 * f, bottom - h * f))
		ci.draw_polyline(pts, line, 9.0, true)
		ci.draw_polyline(pts, col, 6.0, true)
		for k in range(2, 11, 2):
			var p := pts[k]
			var side := 1.0 if (k / 2) % 2 == 0 else -1.0
			var size := 26.0 - k * 1.0
			_leaf(ci, p, side, size, col, line)
			if k % 4 == 0:
				ci.draw_circle(p + Vector2(-side * 6, 4), 4.0, col.lightened(0.3))  # bolinha de ar
		ci.draw_circle(pts[10], 5, col.lightened(0.2))
