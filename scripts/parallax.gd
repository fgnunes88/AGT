extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Camada de fundo distante que anda mais devagar que a câmera (parallax horizontal).
## Mostra a história do mundo: ruínas afundadas, um navio naufragado,
## o esqueleto de uma baleia com marcas de mordida gigante (pista do Megalodon!).

const Data = preload("res://scripts/data.gd")
const FACTOR := 0.45

var main
var items: Array = []   # [tipo, x local, y do mundo, escala]
var ridges: Array = []  # por zona: lista de pontos


func setup(m) -> void:
	main = m


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	# cordilheiras distantes no fundo de cada zona
	for z in range(4):
		var pts := PackedVector2Array()
		var bottom := (z + 1) * Data.ZONE_H
		pts.append(Vector2(-800, bottom))
		var x := -800.0
		while x < 4600:
			pts.append(Vector2(x, bottom - rng.randf_range(120, 380)))
			x += rng.randf_range(160, 320)
		pts.append(Vector2(4600, bottom))
		ridges.append(pts)
	items = [
		["ruins", 600.0, 820.0, 1.0], ["ruins", 2700.0, 880.0, 0.8], ["arch", 1700.0, 900.0, 1.1],
		["wreck", 1200.0, 1880.0, 1.0], ["ruins", 3300.0, 1900.0, 1.2],
		["arch", 2300.0, 2880.0, 1.3], ["wreck", 3800.0, 2900.0, 0.8],
		["skeleton", 1500.0, 3900.0, 1.2], ["skeleton", 3600.0, 3920.0, 0.9],
	]


func _process(_delta: float) -> void:
	if main == null or main.camera == null:
		return
	var cam: Vector2 = main.camera.get_screen_center_position()
	position.x = cam.x * FACTOR
	if Cull.tick(self, 8):
		queue_redraw()


## cor de "neblina" da água naquela profundidade (objetos distantes quase somem na água)
func _haze(y: float, amount := 0.35) -> Color:
	var z := Data.zone_of(clampf(y, 0.0, 3999.0))
	var zd: Dictionary = Data.ZONES[z]
	var f := clampf((y - z * Data.ZONE_H) / Data.ZONE_H, 0.0, 1.0)
	var water: Color = (zd["top"] as Color).lerp(zd["bottom"], f)
	return water.darkened(amount)


func _draw() -> void:
	if main == null or main.camera == null:
		return
	var cam: Vector2 = main.camera.get_screen_center_position()
	var lx := cam.x - position.x
	var view := Rect2(Vector2(lx - 800, cam.y - 500), Vector2(1600, 1000))
	for z in range(4):
		var bottom := (z + 1) * Data.ZONE_H
		if bottom < view.position.y or bottom - 500 > view.end.y:
			continue
		var pts: PackedVector2Array = ridges[z]
		var cols := PackedColorArray()
		for p in pts:
			cols.append(_haze(p.y, 0.18).lerp(_haze(bottom, 0.45), clampf((p.y - (bottom - 380)) / 380.0, 0.0, 1.0)))
		draw_polygon(pts, cols)
	for it in items:
		var x: float = it[1]
		var y: float = it[2]
		var s: float = it[3]
		if absf(x - lx) > 1000 or absf(y - cam.y) > 800:
			continue
		var c := _haze(y - 150, 0.28)
		match it[0]:
			"ruins": _ruins(Vector2(x, y), s, c)
			"arch": _arch(Vector2(x, y), s, c)
			"wreck": _wreck(Vector2(x, y), s, c)
			"skeleton": _skeleton(Vector2(x, y), s, c)


func _ruins(p: Vector2, s: float, c: Color) -> void:
	# templo submerso: colunas (algumas quebradas) e um frontão caído
	for i in range(5):
		var h := (220.0 if i % 2 == 0 else 150.0) * s
		var x := p.x + (i - 2) * 70 * s
		draw_rect(Rect2(x - 16 * s, p.y - h, 32 * s, h), c)
		draw_rect(Rect2(x - 22 * s, p.y - h - 12 * s, 44 * s, 12 * s), c.lightened(0.05))
		for k in range(3):
			draw_line(Vector2(x - 8 * s + k * 8 * s, p.y - h + 10), Vector2(x - 8 * s + k * 8 * s, p.y - 6), c.darkened(0.12), 2)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-190, -232) * s, p + Vector2(40, -260) * s, p + Vector2(-60, -330) * s]), c.lightened(0.04))


func _arch(p: Vector2, s: float, c: Color) -> void:
	# arco natural de rocha
	var pts := PackedVector2Array()
	for i in range(13):
		var a := PI + i * PI / 12.0
		pts.append(p + Vector2(cos(a) * 230, sin(a) * 260) * s)
	for i in range(12, -1, -1):
		var a := PI + i * PI / 12.0
		pts.append(p + Vector2(cos(a) * 150, sin(a) * 180) * s + Vector2(0, 2))
	draw_colored_polygon(pts, c)


func _wreck(p: Vector2, s: float, c: Color) -> void:
	# casco de navio antigo inclinado, com mastro partido
	var hull := PackedVector2Array([p + Vector2(-260, -60) * s, p + Vector2(240, -130) * s, p + Vector2(200, -20) * s, p + Vector2(-200, 10) * s])
	draw_colored_polygon(hull, c)
	draw_line(p + Vector2(-40, -90) * s, p + Vector2(10, -330) * s, c, 14 * s)
	draw_line(p + Vector2(110, -110) * s, p + Vector2(170, -260) * s, c, 10 * s)
	draw_line(p + Vector2(10, -300) * s, p + Vector2(-90, -250) * s, c, 6 * s)
	for i in range(4):
		draw_circle(p + Vector2(-150 + i * 80, -45 - i * 14) * s, 10 * s, c.darkened(0.2))


func _skeleton(p: Vector2, s: float, c: Color) -> void:
	# esqueleto de baleia com uma mordida enorme: pista do Megalodon
	var bone := c.lightened(0.18)
	var spine := PackedVector2Array()
	for i in range(16):
		spine.append(p + Vector2(-320 + i * 42, -60 - sin(i * 0.35) * 30) * s)
	draw_polyline(spine, bone, 12 * s, true)
	for i in range(2, 11):
		if i == 6 or i == 7:
			continue  # costelas arrancadas pela mordida
		var b := spine[i]
		draw_arc(b + Vector2(0, 60 * s), 60 * s, -PI * 0.95, -PI * 0.05, 10, bone, 7 * s)
	# crânio
	draw_colored_polygon(PackedVector2Array([spine[15], spine[15] + Vector2(120, -10) * s, spine[15] + Vector2(110, 40) * s, spine[15] + Vector2(0, 40) * s]), bone)
	# marca da mordida (semicírculo)
	draw_arc(spine[6] + Vector2(20, 40) * s, 70 * s, -PI, 0, 14, c.darkened(0.3), 5 * s)
