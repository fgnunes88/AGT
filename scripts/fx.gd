extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Efeitos desenhados a cada quadro: raios de sol, neve marinha, limite de pressão,
## feixe do scanner e pulsos EMP.

const Data = preload("res://scripts/data.gd")

var main
var t := 0.0
var rings: Array = []   # [posição, raio, vida]
var snow: Array = []


func _ready() -> void:
	for i in range(140):
		snow.append(Vector2(randf_range(0, 1600), randf_range(0, 1000)))


func add_ring(p: Vector2) -> void:
	rings.append([p, 10.0, 1.0])


func _process(delta: float) -> void:
	t += delta
	for r in rings:
		r[1] += 700.0 * delta
		r[2] -= delta * 1.6
	rings = rings.filter(func(r): return r[2] > 0.0)
	if Cull.tick(self, 2):
		queue_redraw()


func _draw() -> void:
	var cam: Vector2 = main.camera.get_screen_center_position()
	var view := Rect2(cam - Vector2(900, 520), Vector2(1800, 1040))
	# raios de sol perto da superfície
	if view.position.y < 900:
		for i in range(8):
			var x := floorf(view.position.x / 400.0) * 400.0 + i * 260.0
			var a := 0.07 + sin(t * 0.7 + i) * 0.04
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 90, 0), Vector2(x + 340, 900), Vector2(x + 160, 900)]), Color(1, 1, 0.85, a))
	# neve marinha (partículas que flutuam)
	var deep := clampf((cam.y - 1200.0) / 1500.0, 0.0, 1.0)
	if deep > 0.0:
		for s in snow:
			var p := Vector2(fposmod(s.x - cam.x * 0.2 + t * 6.0, 1800.0), fposmod(s.y - cam.y * 0.2 + t * 12.0, 1040.0)) + view.position
			draw_rect(Rect2(p, Vector2(3, 3)), Color(0.8, 0.95, 1.0, 0.5 * deep))
	# limite de pressão do casco
	var limit: float = main.pressure_limit_line()
	if limit > 0.0 and absf(limit - cam.y) < 700:
		var col := Color(1.0, 0.3, 0.3, 0.55 + sin(t * 4.0) * 0.2)
		var x0 := floorf(view.position.x / 60.0) * 60.0
		for i in range(32):
			var x := x0 + i * 60.0
			draw_line(Vector2(x, limit), Vector2(x + 34, limit), col, 5.0)
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(cam.x - 300, limit + 40), "LIMITE DE PRESSÃO - reforce o casco com 3 peças", HORIZONTAL_ALIGNMENT_CENTER, 600, 20, 5, Color.BLACK)
		draw_string(font, Vector2(cam.x - 300, limit + 40), "LIMITE DE PRESSÃO - reforce o casco com 3 peças", HORIZONTAL_ALIGNMENT_CENTER, 600, 20, Color(1.0, 0.6, 0.6))
	# brilho da fenda aberta
	if main.crack_open:
		var cy := 4.0 * Data.ZONE_H
		var c := Data.CRACK_X
		draw_rect(Rect2(c.x, cy - 10, c.y - c.x, 130), Color(0.3, 1.0, 0.8, 0.25 + sin(t * 2.0) * 0.1))
	# feixe do scanner
	var target = main.scan_target
	if target != null and is_instance_valid(target):
		var pp: Vector2 = main.player.to_global(main.player.tip_local)
		var tp: Vector2 = target.global_position
		var prog: float = main.scan_progress
		var col := Color(0.3, 1.0, 0.6, 0.35 + prog * 0.5)
		draw_line(pp, tp, col, 3.0 + prog * 4.0)
		draw_arc(tp, 48, 0, TAU, 32, Color(0.3, 1.0, 0.6, 0.5), 2.0)
		draw_arc(tp, 48, -PI / 2, -PI / 2 + TAU * prog, 40, Color(0.3, 1.0, 0.6), 7.0)
	# pulsos EMP
	for r in rings:
		draw_arc(r[0], r[1], 0, TAU, 48, Color(0.4, 0.8, 1.0, r[2]), 6.0)
