extends Node2D
## Boia-sonar da Corporação (inimigo parado, zonas profundas).
## A cada poucos segundos solta uma onda de sonar. Se a onda acertar o Manta fora
## das algas, a boia chama os drones próximos. A luz pisca mais rápido antes de cada onda,
## para a criança aprender o ritmo. O EMP desliga a boia por um tempo.

const PERIOD := 4.0
const RING_MAX := 430.0
const RING_TIME := 1.3
const CALL_RADIUS := 900.0

var main
var t := 0.0
var cycle := 0.0
var ring := -1.0          # raio atual da onda (-1 = sem onda)
var ring_hit := false
var alarm := 0.0          # tempo mostrando "!"
var stunned := 0.0
var anchor_len := 260.0


func setup(m, pos: Vector2) -> void:
	main = m
	position = pos
	cycle = randf() * PERIOD
	t = randf() * 5.0


func threat() -> int:
	if alarm > 0.0:
		return 2
	return 0


func emp_point() -> Vector2:
	return global_position


func stun(seconds: float) -> void:
	stunned = maxf(seconds * 1.8, 8.0)
	ring = -1.0
	alarm = 0.0


func reset_alert() -> void:
	alarm = 0.0
	ring = -1.0


func _process(delta: float) -> void:
	t += delta
	alarm = maxf(0.0, alarm - delta)
	if stunned > 0.0:
		stunned -= delta
		queue_redraw()
		return
	cycle += delta
	if cycle >= PERIOD:
		cycle = 0.0
		ring = 0.0
		ring_hit = false
		main.sfx_at("sonar_onda", position, 900.0)
	if ring >= 0.0 and main.player != null:
		var prev := ring
		ring += RING_MAX / RING_TIME * delta
		var d: float = main.player.global_position.distance_to(position)
		# a frente da onda passou pelo Manta neste quadro?
		if not ring_hit and d >= prev and d < ring and not main.player_hidden and not main.player_invulnerable():
			ring_hit = true
			alarm = 3.0
			main.sonar_alarm(main.player.global_position, CALL_RADIUS)
		if ring > RING_MAX:
			ring = -1.0
	queue_redraw()


func _draw() -> void:
	# corrente até o fundo
	var chain := Color(0.7, 0.75, 0.8, 0.7)
	for i in range(int(anchor_len / 16.0)):
		draw_circle(Vector2(0, 30 + i * 16), 3, chain)
	draw_rect(Rect2(-18, anchor_len + 22, 36, 14), Color(0.35, 0.38, 0.42))
	# corpo branco e limpo da Corporação
	var white := Color(0.95, 0.97, 1.0) if stunned <= 0.0 else Color(0.55, 0.58, 0.62)
	draw_circle(Vector2.ZERO, 26, white)
	draw_rect(Rect2(-26, -4, 52, 8), Color(0.75, 0.8, 0.88))
	draw_line(Vector2(0, -26), Vector2(0, -48), white, 4.0)
	# luz: pisca mais rápido quando a próxima onda está perto
	var lamp := Color(0.3, 0.85, 1.0)
	if stunned > 0.0:
		lamp = Color(0.3, 0.3, 0.35)
	else:
		var left := PERIOD - cycle
		var speed := 2.0 if left > 1.5 else 8.0
		if left <= 1.5:
			lamp = Color(1.0, 0.75, 0.1)
		if int(t * speed) % 2 == 1:
			lamp = lamp.darkened(0.6)
	if alarm > 0.0:
		lamp = Color(1.0, 0.2, 0.2)
	draw_circle(Vector2(0, -52), 8, lamp)
	draw_circle(Vector2(0, 0), 10, Color(0.15, 0.2, 0.3))
	# onda de sonar
	if ring >= 0.0:
		var a := 1.0 - ring / RING_MAX
		draw_arc(Vector2.ZERO, ring, 0, TAU, 64, Color(0.4, 0.9, 1.0, 0.7 * a), 6.0)
		draw_arc(Vector2.ZERO, maxf(ring - 18.0, 1.0), 0, TAU, 64, Color(0.4, 0.9, 1.0, 0.3 * a), 3.0)
	else:
		# mostra o alcance de leve para a criança saber até onde vai
		draw_arc(Vector2.ZERO, RING_MAX, 0, TAU, 64, Color(0.4, 0.9, 1.0, 0.08), 2.0)
	var font := ThemeDB.fallback_font
	var icon := ""
	var icol := Color.WHITE
	if alarm > 0.0:
		icon = "!"
		icol = Color(1.0, 0.2, 0.2)
	elif stunned > 0.0:
		icon = "zZ"
		icol = Color(0.6, 0.8, 1.0)
	if icon != "":
		draw_string_outline(font, Vector2(-12, -64), icon, HORIZONTAL_ALIGNMENT_CENTER, 24, 34, 6, Color.BLACK)
		draw_string(font, Vector2(-12, -64), icon, HORIZONTAL_ALIGNMENT_CENTER, 24, 34, icol)
