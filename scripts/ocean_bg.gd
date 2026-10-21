extends Node2D
## Cenário estático (desenhado uma vez só, para ficar leve):
##   layer "water": céu, ilhas, água em camadas.
##   layer "decor": pináculos de rocha com corais, instalações, fundo da fossa e do santuário.
## As partes que se mexem ficam em bg_anim.gd, parallax.gd e ambient.gd.

const Data = preload("res://scripts/data.gd")
const Art = preload("res://scripts/shark_art.gd")

const ROCK_COLORS := [Color(0.80, 0.64, 0.48), Color(0.56, 0.50, 0.58), Color(0.36, 0.32, 0.48), Color(0.24, 0.21, 0.30)]

var layer := "water"
var rocks: Array = []     # [Vector2 topo, largura, zona, pontos do contorno]
var corals: Array = []    # [pos, tipo, cor, escala, zona]


func setup(which: String) -> void:
	layer = which


func _ready() -> void:
	if layer != "decor":
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for z in range(4):
		for i in range(9):
			var x := rng.randf_range(200, Data.WORLD_W - 200)
			var y := z * Data.ZONE_H + rng.randf_range(300, 900)
			var w := rng.randf_range(90, 210)
			rocks.append([Vector2(x, y), w, z, _make_rock(rng, Vector2(x, y), w, (z + 1) * Data.ZONE_H + 40.0)])
			# decoração no topo de cada pináculo
			var n := rng.randi_range(2, 5)
			for k in range(n):
				var cx := x + rng.randf_range(-w * 0.35, w * 0.35)
				var kind := rng.randi() % 6
				if z >= 2:
					kind = 6 + rng.randi() % 2  # vermes-tubo / lírios-do-mar
				corals.append([Vector2(cx, y - 6 + absf(cx - x) * 0.12), kind,
					Color.from_hsv(fposmod(rng.randf_range(0.85, 1.15), 1.0), rng.randf_range(0.55, 0.8), 1.0),
					rng.randf_range(0.7, 1.25), z])


## Contorno de um pináculo de rocha: topo irregular e base que desce até o fim da zona
func _make_rock(rng: RandomNumberGenerator, top: Vector2, w: float, bottom: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var base_w := w * 1.5
	pts.append(Vector2(top.x - base_w, bottom))
	var steps := 9
	for i in range(steps + 1):
		var f := float(i) / steps
		var x := top.x - w * 0.62 + f * w * 1.24
		var bump := sin(f * PI) * w * 0.12 + rng.randf_range(-w * 0.05, w * 0.05)
		pts.append(Vector2(x, top.y - bump))
	# lado direito com degraus
	pts.append(Vector2(top.x + w * 0.75, top.y + (bottom - top.y) * 0.3))
	pts.append(Vector2(top.x + w * 0.95, top.y + (bottom - top.y) * 0.65))
	pts.append(Vector2(top.x + base_w, bottom))
	return pts


func _grad_rect(r: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _draw() -> void:
	if layer == "water":
		_draw_water()
	else:
		_draw_decor()


func _draw_water() -> void:
	var W := Data.WORLD_W
	# céu
	_grad_rect(Rect2(-400, -900, W + 800, 900), Color(0.40, 0.70, 1.0), Color(1.0, 0.86, 0.66))
	draw_circle(Vector2(5200, -520), 120, Color(1.0, 0.95, 0.7, 0.35))
	draw_circle(Vector2(5200, -520), 90, Color(1.0, 0.95, 0.6))
	# nuvens fofas
	for c in [Vector2(900, -700), Vector2(2600, -620), Vector2(4300, -740), Vector2(6300, -660)]:
		for k in range(5):
			draw_circle(c + Vector2(k * 55 - 110, -sin(k * 0.9) * 22), 46 - absf(k - 2) * 7, Color(1, 1, 1, 0.9))
	# ilhas vulcânicas do arquipélago (com praia e coqueiros)
	for i in range(5):
		var x := 900.0 + i * 1400.0
		var peak := Vector2(x + 40, -280 - i * 25)
		var island := PackedVector2Array([Vector2(x - 420, 0), Vector2(x - 300, -60), Vector2(x - 120, -240 - i * 20), peak, Vector2(x + 160, -200), Vector2(x + 420, 0)])
		draw_colored_polygon(PackedVector2Array([Vector2(x - 460, 4), Vector2(x - 420, -14), Vector2(x + 420, -14), Vector2(x + 460, 4)]), Color(0.98, 0.88, 0.62))
		draw_colored_polygon(island, Color(0.22, 0.58, 0.36))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 120, -240 - i * 20), peak, Vector2(x + 90, -200), Vector2(x - 20, -170)]), Color(0.48, 0.42, 0.38))
		for k in range(3):
			var tx := x - 250 + k * 230
			var tb := Vector2(tx, -40 - k * 12)
			draw_line(tb, tb + Vector2(14, -70), Color(0.5, 0.35, 0.2), 6)
			var tt := tb + Vector2(14, -70)
			for a in [-2.6, -2.0, -1.2, -0.5]:
				draw_line(tt, tt + Vector2(cos(a), sin(a) + 0.6) * 42, Color(0.15, 0.55, 0.25), 7)
	# água por zona
	for z in range(5):
		var zd: Dictionary = Data.ZONES[z]
		var bottom := Data.SANCTUARY_BOTTOM if z == 4 else (z + 1) * Data.ZONE_H
		_grad_rect(Rect2(-400, z * Data.ZONE_H, W + 800, bottom - z * Data.ZONE_H), zd["top"], zd["bottom"])


func _draw_decor() -> void:
	var W := Data.WORLD_W
	# pináculos de rocha (degradê, contorno, estratos e pintinhas)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for r in rocks:
		var top: Vector2 = r[0]
		var w: float = r[1]
		var z: int = r[2]
		var pts: PackedVector2Array = r[3]
		var base_col: Color = ROCK_COLORS[z]
		var bottom := pts[0].y
		var cols := PackedColorArray()
		for p in pts:
			var f := clampf((p.y - top.y) / maxf(bottom - top.y, 1.0), 0.0, 1.0)
			cols.append(base_col.lightened(0.12).lerp(base_col.darkened(0.45), f))
		draw_polygon(pts, cols)
		var ol := pts.duplicate()
		ol.append(pts[0])
		draw_polyline(ol, base_col.darkened(0.6), 3.0, true)
		# luz no topo
		var lit := PackedVector2Array()
		for i in range(2, 10):
			lit.append(pts[i] + Vector2(0, 5))
		draw_polyline(lit, base_col.lightened(0.35), 4.0, true)
		# estratos
		for k in range(3):
			var yy := top.y + 50 + k * 70
			if yy > bottom - 20:
				break
			var half := w * (0.55 + k * 0.12)
			draw_polyline(PackedVector2Array([Vector2(top.x - half, yy), Vector2(top.x - half * 0.3, yy + 8), Vector2(top.x + half * 0.4, yy - 4), Vector2(top.x + half * 0.9, yy + 6)]),
				base_col.darkened(0.35), 2.5, true)
		# pintinhas e furinhos
		for k in range(10):
			var sp := top + Vector2(rng.randf_range(-w * 0.55, w * 0.55), rng.randf_range(20, minf(260.0, bottom - top.y - 20)))
			draw_circle(sp, rng.randf_range(2.5, 6.0), base_col.darkened(0.3))
		# musgo nas duas primeiras zonas
		if z < 2:
			for i in range(2, 10):
				draw_circle(pts[i] + Vector2(0, 3), rng.randf_range(6, 11), Color(0.35, 0.7, 0.35, 0.8))
	# corais e companhia
	for c in corals:
		Art.draw_coral(self, c[0], c[1], c[2], c[3])
	# instalações da Corporação nas zonas 1 e 2 (painéis, rebites e luzes)
	for b in [Vector2(2600, 1960), Vector2(5500, 1960), Vector2(3900, 2960), Vector2(2600, 2960)]:
		_draw_facility(b)
	# fundo da fossa com a fenda secreta
	var floor_y := 4.0 * Data.ZONE_H
	var crack := Data.CRACK_X
	_draw_floor(Rect2(-400, floor_y - 10, crack.x + 400, 130), Color(0.1, 0.08, 0.13))
	_draw_floor(Rect2(crack.y, floor_y - 10, W - crack.y + 400, 130), Color(0.1, 0.08, 0.13))
	# bordas da fenda
	for side in [crack.x, crack.y]:
		draw_colored_polygon(PackedVector2Array([Vector2(side - 30, floor_y - 10), Vector2(side + 30, floor_y - 10), Vector2(side, floor_y + 120)]), Color(0.06, 0.05, 0.08))
	# fundo do santuário: areia clara com ondinhas e conchas
	_grad_rect(Rect2(-400, Data.SANCTUARY_BOTTOM, W + 800, 400), Color(0.85, 0.78, 0.55), Color(0.55, 0.5, 0.35))
	for i in range(0, int(W) + 400, 90):
		var y := Data.SANCTUARY_BOTTOM + 30 + (i % 270) * 0.3
		draw_arc(Vector2(i, y), 30, PI * 1.15, PI * 1.85, 8, Color(0.7, 0.63, 0.42), 3)
	for i in range(40):
		var sx := 120.0 + i * 173.0
		draw_circle(Vector2(sx, Data.SANCTUARY_BOTTOM + 18 + (i % 4) * 9), 6, Color(1.0, 0.85, 0.85))


func _draw_floor(r: Rect2, col: Color) -> void:
	_grad_rect(r, col.lightened(0.15), col.darkened(0.3))
	var x := r.position.x
	var pts := PackedVector2Array()
	while x < r.end.x:
		pts.append(Vector2(x, r.position.y + sin(x * 0.02) * 6))
		x += 40
	draw_polyline(pts, col.lightened(0.3), 3)
	for i in range(int(r.size.x / 120)):
		draw_circle(Vector2(r.position.x + 60 + i * 120, r.position.y + 30 + (i % 3) * 25), 12 + (i % 4) * 4, col.lightened(0.08))


func _draw_facility(b: Vector2) -> void:
	var white := Color(0.93, 0.96, 1.0)
	var shade := Color(0.72, 0.78, 0.88)
	var line := Color(0.35, 0.45, 0.6)
	draw_line(b + Vector2(0, -150), b + Vector2(0, -1000), Color(0.8, 0.85, 0.9, 0.55), 12)  # duto até a superfície
	draw_rect(Rect2(b + Vector2(-150, -94), Vector2(300, 94)), white)
	draw_rect(Rect2(b + Vector2(-150, -30), Vector2(300, 30)), shade)
	draw_rect(Rect2(b + Vector2(-150, -94), Vector2(300, 94)), line, false, 3)
	draw_rect(Rect2(b + Vector2(-65, -156), Vector2(130, 62)), shade)
	draw_rect(Rect2(b + Vector2(-65, -156), Vector2(130, 62)), line, false, 3)
	for i in range(6):
		draw_line(b + Vector2(-150 + i * 60, -94), b + Vector2(-150 + i * 60, 0), Color(line.r, line.g, line.b, 0.35), 2)
	for i in range(5):
		draw_rect(Rect2(b + Vector2(-128 + i * 52, -66), Vector2(30, 12)), Color(0.3, 0.85, 1.0))
		draw_circle(b + Vector2(-136 + i * 60, -86), 3, line)
	draw_rect(Rect2(b + Vector2(-40, -140), Vector2(80, 20)), Color(0.2, 0.3, 0.45))
