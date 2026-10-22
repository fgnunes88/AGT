extends Node2D
## Cenário animado, desenhado só perto da câmera:
## navio de Arthur, ondas, superfície vista de baixo, luz cáustica,
## fontes hidrotermais da fossa e algas douradas do santuário.

const Data = preload("res://scripts/data.gd")

const VENTS := [Vector2(1500, 3990), Vector2(3300, 3990), Vector2(4400, 3990), Vector2(6400, 3990)]

var main
var t := 0.0
var bubbles: Array = []   # [pos, velocidade, raio]


func setup(m, light_tex: Texture2D) -> void:
	main = m
	for v in VENTS:
		var l := PointLight2D.new()
		l.texture = light_tex
		l.texture_scale = 1.6
		l.color = Color(1.0, 0.55, 0.2)
		l.energy = 0.9
		l.position = v + Vector2(0, -60)
		l.enabled = not m.lite
		add_child(l)


func _process(delta: float) -> void:
	t += delta
	# bolhas das fontes hidrotermais
	if randf() < 0.5:
		var v: Vector2 = VENTS[randi() % VENTS.size()]
		bubbles.append([v + Vector2(randf_range(-10, 10), -80), randf_range(60, 120), randf_range(3, 8)])
	for b in bubbles:
		b[0] += Vector2(sin(t * 3.0 + b[2]) * 20.0, -b[1]) * delta
	bubbles = bubbles.filter(func(b): return b[0].y > 3100.0)
	queue_redraw()


func _draw() -> void:
	if main == null or main.camera == null:
		return
	var cam: Vector2 = main.camera.get_screen_center_position()
	var view := Rect2(cam - Vector2(760, 460), Vector2(1520, 920))
	if view.position.y < 950:
		_draw_caustics(view)
	if view.position.y < 80:
		_draw_surface(view)
	if view.end.y > 3300 and view.position.y < 4100:
		_draw_vents(view)
	if view.end.y > 4000:
		_draw_sanctuary(view)


func _draw_surface(view: Rect2) -> void:
	# faixa brilhante da superfície vista de baixo
	var x0 := floorf(view.position.x / 30.0) * 30.0
	var top := PackedVector2Array()
	var x := x0
	while x < view.end.x + 30:
		top.append(Vector2(x, sin(t * 2.0 + x * 0.02) * 6.0))
		x += 30
	var band := top.duplicate()
	for i in range(top.size() - 1, -1, -1):
		band.append(top[i] + Vector2(0, 16 + sin(t * 3.0 + i) * 3))
	draw_colored_polygon(band, Color(0.75, 0.95, 1.0, 0.55))
	draw_polyline(top, Color(1, 1, 1, 0.95), 4)
	# brilhinhos
	for i in range(14):
		var gx := x0 + fposmod(i * 137.0 + t * 25.0, view.size.x + 60)
		draw_circle(Vector2(gx, 22 + sin(t * 4 + i) * 6), 2.5, Color(1, 1, 1, 0.6 + sin(t * 5 + i) * 0.3))
	_draw_ship(Data.SHIP_POS + Vector2(0, sin(t * 1.5) * 4.0))


func _draw_caustics(view: Rect2) -> void:
	# rede de luz ondulante (cáusticas) que some com a profundidade
	var x0 := floorf(view.position.x / 110.0) * 110.0
	var y0 := maxf(20.0, floorf(view.position.y / 90.0) * 90.0)
	var y1 := minf(view.end.y, 950.0)
	var y := y0
	while y < y1:
		var a := 0.16 * (1.0 - y / 950.0)
		var pts := PackedVector2Array()
		var x := x0
		while x < view.end.x + 110:
			pts.append(Vector2(x, y + sin(x * 0.03 + t * 1.6 + y) * 14.0 + sin(x * 0.011 - t) * 10.0))
			x += 28
		draw_polyline(pts, Color(1, 1, 0.9, a), 3)
		y += 90
	var xx := x0
	while xx < view.end.x + 110:
		var pts2 := PackedVector2Array()
		var yy := y0
		while yy < y1:
			pts2.append(Vector2(xx + sin(yy * 0.03 + t * 1.3 + xx) * 16.0, yy))
			yy += 30
		if pts2.size() > 1:
			draw_polyline(pts2, Color(1, 1, 0.9, 0.08), 3)
		xx += 110


func _draw_vents(view: Rect2) -> void:
	for v in VENTS:
		if absf(v.x - view.get_center().x) > 1000:
			continue
		# chaminé
		var ch := PackedVector2Array([v + Vector2(-50, 0), v + Vector2(-26, -70), v + Vector2(-14, -84), v + Vector2(14, -84), v + Vector2(28, -66), v + Vector2(50, 0)])
		draw_colored_polygon(ch, Color(0.2, 0.17, 0.2))
		var ol := ch.duplicate()
		ol.append(ch[0])
		draw_polyline(ol, Color(0.08, 0.06, 0.08), 3)
		draw_line(v + Vector2(-12, -82), v + Vector2(12, -82), Color(1.0, 0.55, 0.15), 5)
		# "fumaça" quente
		for k in range(4):
			var fy := fposmod(t * 40.0 + k * 30.0, 120.0)
			draw_circle(v + Vector2(sin(t * 2 + k) * 10, -90 - fy), 10 + fy * 0.15, Color(0.25, 0.22, 0.25, 0.5 * (1.0 - fy / 120.0)))
	for b in bubbles:
		if view.has_point(b[0]):
			draw_arc(b[0], b[2], 0, TAU, 10, Color(0.85, 0.95, 1.0, 0.7), 1.5)


func _draw_sanctuary(view: Rect2) -> void:
	var base := Data.SANCTUARY_BOTTOM
	var i0 := maxi(0, int((view.position.x - 200) / 230.0))
	var i1 := mini(30, int((view.end.x) / 230.0) + 1)
	for i in range(i0, i1):
		var x := 200.0 + i * 230.0
		var h := 140.0 + fmod(i * 97.0, 180.0)
		var pts := PackedVector2Array()
		for k in range(10):
			var f := k / 9.0
			pts.append(Vector2(x + sin(t * 0.8 + i + f * 2.5) * 22.0 * f, base - h * f))
		draw_polyline(pts, Color(0.75, 0.6, 0.1), 13, true)
		draw_polyline(pts, Color(1.0, 0.85, 0.2), 8, true)
		for k in range(2, 10, 2):
			var p := pts[k]
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(24, -14), p + Vector2(6, -4)]), Color(1.0, 0.9, 0.35))
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(-22, -16), p + Vector2(-5, -5)]), Color(0.95, 0.8, 0.25))
		draw_circle(pts[9], 12, Color(1.0, 0.97, 0.6))
		draw_circle(pts[9], 6, Color(1, 1, 0.9))


func _draw_ship(p: Vector2) -> void:
	var line := Color(0.15, 0.2, 0.3)
	# guindaste do Manta e mastro (atrás)
	draw_line(p + Vector2(110, -40), p + Vector2(150, -140), Color(0.3, 0.3, 0.35), 7)
	draw_line(p + Vector2(150, -140), p + Vector2(160, -60), Color(0.2, 0.2, 0.22), 2)
	draw_line(p + Vector2(-30, -110), p + Vector2(-30, -200), Color(0.3, 0.3, 0.35), 5)
	draw_circle(p + Vector2(-30, -205), 10, Color(0.9, 0.35, 0.15))
	# casco com degradê
	var hull := PackedVector2Array([p + Vector2(-175, -42), p + Vector2(200, -42), p + Vector2(150, 22), p + Vector2(-152, 22)])
	draw_polygon(hull, PackedColorArray([Color(1, 1, 1), Color(1, 1, 1), Color(0.78, 0.82, 0.88), Color(0.78, 0.82, 0.88)]))
	draw_rect(Rect2(p + Vector2(-166, -14), Vector2(340, 12)), Color(0.9, 0.35, 0.15))
	var ho := hull.duplicate()
	ho.append(hull[0])
	draw_polyline(ho, line, 3)
	for i in range(5):
		draw_circle(p + Vector2(-110 + i * 55, -28), 6, Color(0.35, 0.65, 0.9))
		draw_arc(p + Vector2(-110 + i * 55, -28), 6, 0, TAU, 12, line, 2)
	# cabine
	draw_rect(Rect2(p + Vector2(-100, -112), Vector2(140, 70)), Color(0.97, 0.97, 0.99))
	draw_rect(Rect2(p + Vector2(-100, -112), Vector2(140, 70)), line, false, 3)
	draw_rect(Rect2(p + Vector2(-90, -100), Vector2(120, 26)), Color(0.45, 0.78, 0.98))
	draw_line(p + Vector2(-80, -98), p + Vector2(-60, -76), Color(1, 1, 1, 0.7), 3)
	var font := ThemeDB.fallback_font
	draw_string(font, p + Vector2(-60, -48), "PHILIP B.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.15, 0.25, 0.45))
