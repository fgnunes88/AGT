extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Drone de patrulha (inimigo). Sistema de alerta inspirado em Metal Gear Solid:
## PATRULHA -> SUSPEITO (?) -> ALERTA (!) -> BUSCA -> volta a patrulhar.
## Não machuca: se apanhar o Manta, Arthur volta ao último ponto seguro.

enum State { PATROL, SUSPICIOUS, ALERT, SEARCH, STUNNED }

const VIEW_LEN := 320.0
const VIEW_HALF := deg_to_rad(28.0)

var main  # referência ao main.gd (sem tipo para acesso dinâmico)
var x_a := 0.0
var x_b := 0.0
var home_y := 0.0
var corp := false            # false = Sindicato (laranja), true = Corporação (branco)
var state := State.PATROL
var alert := 0.0             # 0..1
var facing := 1.0
var look_angle := 0.0        # ângulo do cone de visão
var timer := 0.0
var t := 0.0
var last_seen := Vector2.ZERO


func setup(m, a: float, b: float, y: float, is_corp: bool) -> void:
	main = m
	x_a = a
	x_b = b
	home_y = y
	corp = is_corp
	position = Vector2(randf_range(a, b), y)
	facing = 1.0 if randf() < 0.5 else -1.0
	t = randf() * 5.0


func reset_alert() -> void:
	alert = 0.0
	if state != State.STUNNED:
		state = State.PATROL


func stun(seconds: float) -> void:
	state = State.STUNNED
	timer = seconds
	alert = 0.0


func _sees(p: Vector2, hidden: bool) -> bool:
	var to := p - position
	var d := to.length()
	if d > VIEW_LEN:
		return false
	if hidden and d > 70.0:
		return false
	var view_dir := Vector2(facing, 0).rotated(look_angle * facing)
	return absf(view_dir.angle_to(to)) < VIEW_HALF


func _process(delta: float) -> void:
	t += delta
	var player: Node2D = main.player
	if player == null:
		return
	var pp := player.global_position
	var d := pp.distance_to(position)
	var hidden: bool = main.player_hidden
	var sees: bool = _sees(pp, hidden) and not main.player_invulnerable()

	if state == State.STUNNED:
		timer -= delta
		position.y += sin(t * 3.0) * 0.3
		if timer <= 0.0:
			state = State.PATROL
		if Cull.near(self, 420.0):
			queue_redraw()
		return

	# --- sentido de proximidade e visão ---
	if sees:
		last_seen = pp
		if d < 130.0:
			alert = 1.0  # passou bem na frente: alerta máximo na hora
		else:
			alert += delta * lerpf(1.8, 0.55, d / VIEW_LEN)
	elif d < 110.0 and not hidden and not main.player_invulnerable():
		alert += delta * 0.6  # "sente" Arthur por perto
		last_seen = pp
	else:
		var decay := 0.12 if state in [State.ALERT, State.SEARCH] else 0.3
		alert -= delta * decay
	alert = clampf(alert, 0.0, 1.0)

	# --- máquina de estados ---
	match state:
		State.PATROL:
			if alert >= 1.0:
				_go_alert()
			elif alert > 0.3:
				state = State.SUSPICIOUS
				main.sfx_at("suspeita", position)
		State.SUSPICIOUS:
			if alert >= 1.0:
				_go_alert()
			elif alert <= 0.05:
				state = State.PATROL
		State.ALERT:
			if not sees:
				timer -= delta
				if timer <= 0.0:
					state = State.SEARCH
					timer = 5.0
			else:
				timer = 3.0
		State.SEARCH:
			timer -= delta
			if sees and d < 220.0:
				_go_alert()
			elif alert <= 0.05 or timer <= 0.0:
				state = State.PATROL
				alert = minf(alert, 0.2)

	# --- movimento ---
	match state:
		State.PATROL:
			position.x += facing * 85.0 * delta
			if position.x > x_b:
				facing = -1.0
			elif position.x < x_a:
				facing = 1.0
			position.y = lerpf(position.y, home_y + sin(t * 1.2) * 20.0, delta * 2.0)
			look_angle = sin(t * 1.3) * deg_to_rad(18.0)
		State.SUSPICIOUS:
			_look_at_point(last_seen, delta)
			position = position.move_toward(last_seen, 40.0 * delta)
		State.ALERT:
			_look_at_point(pp, delta)
			position = position.move_toward(pp, 210.0 * delta)
			if d < 48.0:
				main.player_caught()
		State.SEARCH:
			position = position.move_toward(last_seen, 90.0 * delta)
			look_angle = sin(t * 3.0) * deg_to_rad(45.0)
			if position.distance_to(last_seen) < 10.0 and fmod(t, 2.0) < delta:
				facing = -facing
	if Cull.near(self, 420.0):
		queue_redraw()


func _go_alert() -> void:
	if state != State.ALERT:
		main.sfx_at("alerta", position)
	state = State.ALERT
	timer = 3.0
	alert = 1.0
	main.on_drone_alert(self)


func _look_at_point(p: Vector2, delta: float) -> void:
	var to := p - position
	if absf(to.x) > 4.0:
		facing = signf(to.x)
	var target_angle := clampf(atan2(to.y, absf(to.x)), -1.2, 1.2)
	look_angle = lerpf(look_angle, target_angle, clampf(delta * 5.0, 0.0, 1.0))


func _draw() -> void:
	# Cone de visão
	if state != State.STUNNED:
		var c := Color(1.0, 0.95, 0.3, 0.16)
		if state == State.SUSPICIOUS or state == State.SEARCH:
			c = Color(1.0, 0.6, 0.1, 0.22)
		elif state == State.ALERT:
			c = Color(1.0, 0.15, 0.15, 0.28)
		var pts := PackedVector2Array([Vector2.ZERO])
		for i in range(9):
			var a := -VIEW_HALF + 2.0 * VIEW_HALF * i / 8.0
			pts.append(Vector2(facing, 0).rotated(look_angle * facing + a) * VIEW_LEN)
		draw_colored_polygon(pts, c)

	# Corpo do drone
	var body := Color(0.95, 0.97, 1.0) if corp else Color(0.95, 0.5, 0.15)
	var trim := Color(0.2, 0.7, 1.0) if corp else Color(0.3, 0.25, 0.2)
	var shell := PackedVector2Array([Vector2(-34, -10), Vector2(-20, -22), Vector2(24, -22), Vector2(36, -6), Vector2(36, 8), Vector2(22, 18), Vector2(-22, 18), Vector2(-34, 8)])
	var scols := PackedColorArray()
	for v in shell:
		scols.append(body.lightened(0.2).lerp(body.darkened(0.3), clampf((v.y + 22.0) / 40.0, 0.0, 1.0)))
	draw_polygon(shell, scols)
	var outline := shell.duplicate()
	outline.append(shell[0])
	draw_polyline(outline, body.darkened(0.65), 3.0, true)
	draw_polyline(PackedVector2Array([Vector2(-18, -18), Vector2(20, -18)]), Color(1, 1, 1, 0.6), 2.5)
	# antena
	draw_line(Vector2(-10, -22), Vector2(-14, -34), body.darkened(0.5), 2.0)
	draw_circle(Vector2(-14, -35), 3, Color(1.0, 0.3, 0.2) if state == State.ALERT else trim)
	draw_rect(Rect2(-24, -4, 48, 6), trim)
	# hélices
	var spin := sin(t * 30.0) * 10.0
	draw_line(Vector2(-30, 20), Vector2(-30 + spin, 28), Color(0.2, 0.2, 0.25), 3.0)
	draw_line(Vector2(30, 20), Vector2(30 - spin, 28), Color(0.2, 0.2, 0.25), 3.0)
	# "olho" (câmera)
	var eye_col := Color(0.3, 0.9, 1.0)
	if state == State.ALERT:
		eye_col = Color(1.0, 0.2, 0.2)
	elif state == State.SUSPICIOUS or state == State.SEARCH:
		eye_col = Color(1.0, 0.75, 0.1)
	elif state == State.STUNNED:
		eye_col = Color(0.3, 0.3, 0.35)
	draw_circle(Vector2(22 * facing, -6), 12, Color(eye_col.r, eye_col.g, eye_col.b, 0.25))
	draw_circle(Vector2(22 * facing, -6), 9, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(22 * facing, -6), 6, eye_col)
	draw_circle(Vector2(20 * facing, -8), 2, Color(1, 1, 1, 0.8))

	# Ícone de alerta sobre a cabeça
	var font := ThemeDB.fallback_font
	var icon := ""
	var icol := Color.WHITE
	match state:
		State.SUSPICIOUS:
			icon = "?"
			icol = Color(1.0, 0.85, 0.1)
		State.SEARCH:
			icon = "?"
			icol = Color(1.0, 0.55, 0.1)
		State.ALERT:
			icon = "!"
			icol = Color(1.0, 0.2, 0.2)
		State.STUNNED:
			icon = "zZ"
			icol = Color(0.6, 0.8, 1.0)
	if icon != "":
		draw_string_outline(font, Vector2(-12, -34), icon, HORIZONTAL_ALIGNMENT_CENTER, 24, 34, 6, Color.BLACK)
		draw_string(font, Vector2(-12, -34), icon, HORIZONTAL_ALIGNMENT_CENTER, 24, 34, icol)
	# barra de alerta
	if alert > 0.01 and state != State.ALERT:
		draw_rect(Rect2(-25, -30, 50, 5), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-25, -30, 50 * alert, 5), Color(1.0, lerpf(0.9, 0.2, alert), 0.1))
	if state == State.STUNNED:
		for i in range(3):
			var a := t * 4.0 + i * TAU / 3.0
			draw_line(Vector2(cos(a), sin(a)) * 30, Vector2(cos(a + 0.5), sin(a + 0.5)) * 38, Color(0.5, 0.8, 1.0), 2.0)


## Nível de ameaça para o HUD e a música (0 tranquilo, 1 suspeita, 2 alerta)
func threat() -> int:
	if state == State.ALERT:
		return 2
	if state == State.SUSPICIOUS or state == State.SEARCH:
		return 1
	return 0


func emp_point() -> Vector2:
	return global_position


## Chamado pela boia-sonar: vem direto para onde o Manta foi detectado
func alarm(p: Vector2) -> void:
	if state == State.STUNNED:
		return
	last_seen = p
	_go_alert()
