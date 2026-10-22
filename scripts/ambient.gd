extends Node2D
## Vida marinha de enfeite (não interage com o jogo, só deixa o mar mais vivo):
## cardumes de peixinhos, tartarugas, águas-vivas brilhantes e peixes-diabo com lanterna.
## Os cardumes fogem quando o Manta chega perto.

const Data = preload("res://scripts/data.gd")

var main
var t := 0.0
var schools: Array = []   # {pos, vel, target, n, col, col2, zone, offsets}
var jellies: Array = []   # {pos, phase, col, light}
var anglers: Array = []   # {pos, dir, light, x0, x1}
var turtles: Array = []   # {pos, dir, x0, x1}


func setup(m, light_tex: Texture2D) -> void:
	main = m
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var palettes := [[Color(1.0, 0.85, 0.2), Color(0.2, 0.4, 0.9)], [Color(1.0, 0.55, 0.15), Color(1, 1, 1)],
		[Color(0.25, 0.5, 1.0), Color(1.0, 0.9, 0.2)], [Color(0.75, 0.85, 0.95), Color(0.4, 0.55, 0.7)]]
	var lite: bool = m.lite
	for i in range(8 if lite else 14):
		var z := i % 3
		var pal: Array = palettes[rng.randi() % palettes.size()] if z < 2 else [Color(0.6, 0.7, 0.9), Color(0.3, 0.9, 1.0)]
		var offs: Array = []
		var n := rng.randi_range(5, 8) if lite else rng.randi_range(7, 13)
		for k in range(n):
			offs.append(Vector3(rng.randf_range(-70, 70), rng.randf_range(-40, 40), rng.randf() * TAU))
		var p := Vector2(rng.randf_range(300, Data.WORLD_W - 300), z * Data.ZONE_H + rng.randf_range(150, 850))
		schools.append({"pos": p, "vel": Vector2.ZERO, "target": p, "zone": z, "col": pal[0], "col2": pal[1], "offs": offs})
	for i in range(14):
		var z := 1 + i % 3
		var col := Color.from_hsv(rng.randf_range(0.5, 0.95), 0.5, 1.0)
		var l := PointLight2D.new()
		l.texture = light_tex
		l.texture_scale = 0.7
		l.color = col
		l.energy = 0.0 if z == 1 else 0.8
		l.enabled = z != 1 and not lite   # luzes 2D pesam no navegador
		add_child(l)
		jellies.append({"pos": Vector2(rng.randf_range(300, Data.WORLD_W - 300), z * Data.ZONE_H + rng.randf_range(150, 850)),
			"phase": rng.randf() * TAU, "col": col, "light": l, "zone": z})
	for i in range(4):
		var l := PointLight2D.new()
		l.texture = light_tex
		l.texture_scale = 0.8
		l.color = Color(0.6, 1.0, 0.8)
		l.energy = 1.0
		l.enabled = not lite
		add_child(l)
		var x0 := 600.0 + i * 1500.0
		anglers.append({"pos": Vector2(x0 + 300, 3300 + i * 130), "dir": 1.0, "light": l, "x0": x0, "x1": x0 + 900})
	for i in range(2):
		var x0 := 1800.0 + i * 2600.0
		turtles.append({"pos": Vector2(x0, 350 + i * 250), "dir": 1.0, "x0": x0, "x1": x0 + 1400})


func _process(delta: float) -> void:
	t += delta
	if main == null or main.player == null:
		return
	var pp: Vector2 = main.player.global_position
	for s in schools:
		var z: int = s["zone"]
		var p: Vector2 = s["pos"]
		if p.distance_to(s["target"]) < 60:
			s["target"] = Vector2(randf_range(300, Data.WORLD_W - 300), z * Data.ZONE_H + randf_range(150, 850))
		var desired: Vector2 = (s["target"] - p).normalized() * 70.0
		var away := p - pp
		if away.length() < 260:
			desired = away.normalized() * 230.0  # foge do Manta
		s["vel"] = (s["vel"] as Vector2).lerp(desired, clampf(delta * 2.0, 0.0, 1.0))
		var np: Vector2 = p + s["vel"] * delta
		np.y = clampf(np.y, z * Data.ZONE_H + 70.0, (z + 1) * Data.ZONE_H - 70.0)
		np.x = clampf(np.x, 100.0, Data.WORLD_W - 100.0)
		s["pos"] = np
	for j in jellies:
		var ph: float = j["phase"]
		var push := maxf(0.0, sin(t * 1.6 + ph)) * 26.0
		var jp: Vector2 = j["pos"]
		var z: int = j["zone"]
		jp.y -= push * delta
		jp.y += 6.0 * delta
		jp.x += sin(t * 0.3 + ph) * 8.0 * delta
		if jp.y < z * Data.ZONE_H + 100:
			jp.y = (z + 1) * Data.ZONE_H - 100
		j["pos"] = jp
		(j["light"] as PointLight2D).position = jp
	for a in anglers:
		var ap: Vector2 = a["pos"]
		ap.x += a["dir"] * 30.0 * delta
		ap.y += sin(t + a["x0"]) * 10.0 * delta
		if ap.x > a["x1"]:
			a["dir"] = -1.0
		elif ap.x < a["x0"]:
			a["dir"] = 1.0
		a["pos"] = ap
		(a["light"] as PointLight2D).position = ap + Vector2(a["dir"] * 60.0, -42.0)
	for tu in turtles:
		var tp: Vector2 = tu["pos"]
		tp.x += tu["dir"] * 40.0 * delta
		tp.y += sin(t * 0.5) * 8.0 * delta
		if tp.x > tu["x1"]:
			tu["dir"] = -1.0
		elif tp.x < tu["x0"]:
			tu["dir"] = 1.0
		tu["pos"] = tp
	queue_redraw()


func _draw() -> void:
	if main == null or main.camera == null:
		return
	var cam: Vector2 = main.camera.get_screen_center_position()
	var view := Rect2(cam - Vector2(800, 500), Vector2(1600, 1000))
	for tu in turtles:
		if view.has_point(tu["pos"]):
			_turtle(tu["pos"], tu["dir"])
	for s in schools:
		var p: Vector2 = s["pos"]
		if not view.grow(100).has_point(p):
			continue
		var v: Vector2 = s["vel"]
		var d := 1.0 if v.x >= 0.0 else -1.0
		for o in s["offs"]:
			var fp := p + Vector2(o.x, o.y + sin(t * 3.0 + o.z) * 6.0)
			_fish(fp, d, s["col"], s["col2"], o.z)
	for j in jellies:
		if view.grow(80).has_point(j["pos"]):
			_jelly(j["pos"], j["col"], j["phase"])
	for a in anglers:
		if view.grow(120).has_point(a["pos"]):
			_angler(a["pos"], a["dir"])


func _fish(p: Vector2, d: float, c1: Color, c2: Color, ph: float) -> void:
	var wag := sin(t * 12.0 + ph) * 3.0
	draw_colored_polygon(PackedVector2Array([p + Vector2(-9 * d, 0), p + Vector2(-17 * d, -6 + wag), p + Vector2(-17 * d, 6 + wag)]), c2)
	var body := PackedVector2Array()
	for i in range(10):
		var a := TAU * i / 10.0
		body.append(p + Vector2(cos(a) * 11, sin(a) * 5.5))
	draw_colored_polygon(body, c1)
	draw_line(p + Vector2(-1 * d, -5), p + Vector2(-1 * d, 5), c2, 2.5)
	draw_circle(p + Vector2(6 * d, -1), 1.8, Color.BLACK)


func _jelly(p: Vector2, c: Color, ph: float) -> void:
	var pulse := 1.0 + maxf(0.0, sin(t * 1.6 + ph)) * 0.15
	for k in range(5):
		var x := -14.0 + k * 7.0
		var pts := PackedVector2Array()
		for i in range(7):
			pts.append(p + Vector2(x + sin(t * 2.0 + i * 0.7 + k) * 4.0, 6 + i * 9))
		draw_polyline(pts, Color(c.r, c.g, c.b, 0.55), 2)
	draw_circle(p, 24 * pulse, Color(c.r, c.g, c.b, 0.18))
	var bell := PackedVector2Array()
	for i in range(13):
		var a := PI + i * PI / 12.0
		bell.append(p + Vector2(cos(a) * 20 * pulse, sin(a) * 18 / pulse))
	draw_colored_polygon(bell, Color(c.r, c.g, c.b, 0.75))
	draw_arc(p + Vector2(-5, -8), 7, PI * 1.1, PI * 1.6, 6, Color(1, 1, 1, 0.7), 2)


func _angler(p: Vector2, d: float) -> void:
	var body_col := Color(0.32, 0.28, 0.36)
	# corpo redondo
	var body := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		body.append(p + Vector2(cos(a) * 34, sin(a) * 26))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-30 * d, 0), p + Vector2(-56 * d, -18), p + Vector2(-56 * d, 18)]), body_col)
	draw_colored_polygon(body, body_col)
	var ol := body.duplicate()
	ol.append(body[0])
	draw_polyline(ol, body_col.darkened(0.5), 2.5)
	# boca com dentinhos
	if d > 0:
		draw_arc(p + Vector2(22 * d, 8), 14, -0.3, 1.4, 8, Color(0.1, 0.05, 0.1), 4)
	else:
		draw_arc(p + Vector2(22 * d, 8), 14, PI - 1.4, PI + 0.3, 8, Color(0.1, 0.05, 0.1), 4)
	for k in range(4):
		var tp := p + Vector2((14 + k * 5) * d, 2 + k * 2)
		draw_colored_polygon(PackedVector2Array([tp, tp + Vector2(3 * d, 0), tp + Vector2(1.5 * d, 6)]), Color.WHITE)
	draw_circle(p + Vector2(12 * d, -10), 6, Color.WHITE)
	draw_circle(p + Vector2(14 * d, -10), 3, Color.BLACK)
	# antena com a lanterna
	var lure := p + Vector2(60 * d, -42 + sin(t * 2) * 4)
	draw_polyline(PackedVector2Array([p + Vector2(10 * d, -24), p + Vector2(34 * d, -56), lure]), body_col.lightened(0.2), 3)
	draw_circle(lure, 12, Color(0.6, 1.0, 0.8, 0.3))
	draw_circle(lure, 6, Color(0.8, 1.0, 0.9))


func _turtle(p: Vector2, d: float) -> void:
	var flip := sin(t * 2.0) * 10.0
	var skin := Color(0.55, 0.75, 0.45)
	draw_colored_polygon(PackedVector2Array([p + Vector2(10 * d, 10), p + Vector2(-6 * d, 40 + flip), p + Vector2(-20 * d, 12)]), skin)
	draw_colored_polygon(PackedVector2Array([p + Vector2(10 * d, -10), p + Vector2(-6 * d, -40 - flip), p + Vector2(-20 * d, -12)]), skin.darkened(0.1))
	draw_circle(p + Vector2(46 * d, -2), 13, skin)
	draw_circle(p + Vector2(52 * d, -6), 3, Color.BLACK)
	var shell := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		shell.append(p + Vector2(cos(a) * 40, sin(a) * 24))
	draw_colored_polygon(shell, Color(0.45, 0.35, 0.2))
	var so := shell.duplicate()
	so.append(shell[0])
	draw_polyline(so, Color(0.25, 0.18, 0.1), 3)
	for k in range(3):
		draw_circle(p + Vector2((k - 1) * 22, -2), 9, Color(0.6, 0.48, 0.28))
