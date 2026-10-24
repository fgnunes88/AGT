extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Barco pesqueiro ilegal do Sindicato (inimigo da superfície).
## Navega de um lado para o outro e varre o mar com um holofote.
## Se o holofote encontrar o Manta por tempo demais, baixa uma GARRA para apanhá-lo.
## A garra não machuca: como nos drones, o Manta só volta ao último ponto seguro.

enum State { PATROL, SUSPICIOUS, CLAW, RETURN, STUNNED }

const LIGHT_LEN := 700.0
const LIGHT_HALF := deg_to_rad(20.0)
const CLAW_SPEED := 210.0
const CLAW_TIME := 7.0
const HOOK := Vector2(70, -40)   # ponta do guindaste

var main
var x_a := 0.0
var x_b := 0.0
var state := State.PATROL
var alert := 0.0
var facing := 1.0
var sweep := 0.0
var t := 0.0
var timer := 0.0
var claw := Vector2.ZERO        # posição da garra (local)
var claw_closed := false
var sensing := false


func setup(m, a: float, b: float) -> void:
	main = m
	x_a = a
	x_b = b
	position = Vector2(randf_range(a, b), 0)
	t = randf() * 5.0
	claw = _hook()


func _hook() -> Vector2:
	return Vector2(HOOK.x * facing, HOOK.y)


func threat() -> int:
	if state == State.CLAW:
		return 2
	if state == State.SUSPICIOUS:
		return 1
	return 0


func danger() -> bool:
	if state == State.CLAW:
		return true
	return sensing and alert > 0.2 and state != State.STUNNED


func emp_point() -> Vector2:
	return global_position + claw


func stun(seconds: float) -> void:
	state = State.STUNNED
	timer = seconds
	alert = 0.0


func reset_alert() -> void:
	alert = 0.0
	if state == State.CLAW or state == State.SUSPICIOUS:
		state = State.RETURN


func _light_dir() -> Vector2:
	return Vector2(0, 1).rotated(sweep)


func _sees(p: Vector2, hidden: bool) -> bool:
	if hidden:
		return false
	var to := p - position
	if to.length() > LIGHT_LEN or to.y < 0:
		return false
	return absf(_light_dir().angle_to(to)) < LIGHT_HALF


func _process(delta: float) -> void:
	t += delta
	if main.player == null:
		return
	var pp: Vector2 = main.player.global_position
	var hidden: bool = main.player_hidden
	var sees: bool = _sees(pp, hidden) and not main.player_invulnerable()
	sensing = sees
	position.y = sin(t * 1.5) * 4.0

	match state:
		State.PATROL, State.SUSPICIOUS:
			if sees:
				alert += delta * 0.75
			else:
				alert -= delta * 0.35
			alert = clampf(alert, 0.0, 1.0)
			if alert >= 1.0:
				state = State.CLAW
				timer = CLAW_TIME
				claw_closed = false
				main.sfx_at("alerta", pp)
				main.sfx_at("garra", pp)
				main.on_enemy_alert("O barco do Sindicato te viu! Fuja da garra ou esconda-se nas algas!")
			elif alert > 0.3:
				if state == State.PATROL:
					main.sfx_at("suspeita", pp)
				state = State.SUSPICIOUS
			elif state == State.SUSPICIOUS and alert <= 0.05:
				state = State.PATROL
			if state == State.PATROL:
				position.x += facing * 70.0 * delta
				if position.x > x_b:
					facing = -1.0
				elif position.x < x_a:
					facing = 1.0
				sweep = sin(t * 0.9) * deg_to_rad(35.0)
			else:
				# para o barco e aponta o holofote para o Manta
				var to := pp - position
				sweep = lerp_angle(sweep, clampf(Vector2(0, 1).angle_to(to), -1.0, 1.0), delta * 3.0)
			claw = claw.move_toward(_hook(), CLAW_SPEED * delta)
		State.CLAW:
			timer -= delta
			var to := pp - position
			sweep = lerp_angle(sweep, clampf(Vector2(0, 1).angle_to(to), -1.0, 1.0), delta * 3.0)
			var target := Vector2(to.x, minf(to.y, 980.0))
			claw = claw.move_toward(target, CLAW_SPEED * delta)
			if (global_position + claw).distance_to(pp) < 46.0:
				claw_closed = true
				main.player_caught()
				state = State.RETURN
			elif timer <= 0.0 or hidden:
				state = State.RETURN
		State.RETURN:
			claw = claw.move_toward(_hook(), CLAW_SPEED * 1.5 * delta)
			if claw.distance_to(_hook()) < 4.0:
				state = State.PATROL
				alert = 0.2
				claw_closed = false
		State.STUNNED:
			timer -= delta
			claw = claw.move_toward(_hook(), CLAW_SPEED * delta)
			if timer <= 0.0:
				state = State.PATROL
	if Cull.near(self, 800.0) and Cull.tick(self, 2):
		queue_redraw()


func _draw() -> void:
	# holofote
	if state != State.STUNNED:
		var c := Color(1.0, 0.95, 0.4, 0.24)
		if state == State.SUSPICIOUS:
			c = Color(1.0, 0.6, 0.1, 0.2)
		elif state == State.CLAW:
			c = Color(1.0, 0.2, 0.15, 0.24)
		var pts := PackedVector2Array([Vector2(0, 12)])
		for i in range(9):
			var a := -LIGHT_HALF + 2.0 * LIGHT_HALF * i / 8.0
			pts.append(Vector2(0, 12) + _light_dir().rotated(a) * LIGHT_LEN)
		draw_colored_polygon(pts, c)
		var edge := Color(c.r, c.g, c.b, 0.6)
		draw_line(pts[0], pts[1], edge, 2.0)
		draw_line(pts[0], pts[pts.size() - 1], edge, 2.0)
	# cabo e garra
	var hook := _hook()
	draw_line(hook, claw, Color(0.2, 0.2, 0.22), 3.0)
	var open := 6.0 if claw_closed else 16.0
	var steel := Color(0.55, 0.55, 0.6)
	draw_circle(claw, 9, steel)
	draw_line(claw, claw + Vector2(-open, 18), steel, 5.0)
	draw_line(claw + Vector2(-open, 18), claw + Vector2(-open * 0.4, 28), steel, 5.0)
	draw_line(claw, claw + Vector2(open, 18), steel, 5.0)
	draw_line(claw + Vector2(open, 18), claw + Vector2(open * 0.4, 28), steel, 5.0)
	# casco enferrujado
	var f := facing
	var rust := Color(0.75, 0.32, 0.15)
	draw_colored_polygon(PackedVector2Array([Vector2(-130 * f, -30), Vector2(140 * f, -30), Vector2(100 * f, 16), Vector2(-110 * f, 16)]), Color(0.25, 0.22, 0.22))
	draw_rect(Rect2(Vector2(-125, -14), Vector2(250, 8)), rust)
	draw_rect(Rect2(Vector2(-80 * f - 30, -78), Vector2(60, 48)), Color(0.6, 0.55, 0.5))
	draw_rect(Rect2(Vector2(-80 * f - 22, -70), Vector2(44, 16)), Color(0.2, 0.3, 0.35))
	# guindaste
	draw_line(Vector2(20 * f, -30), hook, rust.darkened(0.2), 7.0)
	# luz de alerta
	var lamp := Color(0.3, 0.3, 0.3)
	if state == State.CLAW:
		lamp = Color(1.0, 0.15, 0.1) if int(t * 4.0) % 2 == 0 else Color(0.4, 0.05, 0.05)
	elif state == State.SUSPICIOUS:
		lamp = Color(1.0, 0.8, 0.1)
	draw_circle(Vector2(-80 * f, -86), 7, lamp)
	# ícone e barra de alerta
	var font := ThemeDB.fallback_font
	var icon := ""
	var icol := Color.WHITE
	if state == State.SUSPICIOUS:
		icon = "?"
		icol = Color(1.0, 0.85, 0.1)
	elif state == State.CLAW:
		icon = "!"
		icol = Color(1.0, 0.2, 0.2)
	elif state == State.STUNNED:
		icon = "zZ"
		icol = Color(0.6, 0.8, 1.0)
	if icon != "":
		draw_string_outline(font, Vector2(-12, -100), icon, HORIZONTAL_ALIGNMENT_CENTER, 24, 36, 6, Color.BLACK)
		draw_string(font, Vector2(-12, -100), icon, HORIZONTAL_ALIGNMENT_CENTER, 24, 36, icol)
	if alert > 0.01 and state != State.CLAW:
		draw_rect(Rect2(-30, -134, 60, 6), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-30, -134, 60 * alert, 6), Color(1.0, lerpf(0.9, 0.2, alert), 0.1))
