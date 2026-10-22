extends Node2D
## O mini-submarino Manta, pilotado por Arthur Blake.

const Data = preload("res://scripts/data.gd")

const ACCEL := 900.0
const MAX_SPEED := 300.0
const DRAG := 2.2

var main  # referência ao main.gd
var velocity := Vector2.ZERO
var facing := 1.0
var t := 0.0
var locked := false          # controles bloqueados (cenas)
var auto_move := Vector2.ZERO
var bubbles: Array = []      # [pos, vida]
var light: PointLight2D
var blink := 0.0
var arm_target = null         # ponto do mundo para onde o braço mecânico aponta (scanner / cortar rede)
var arm := 0.0                # 0 = braço recolhido, 1 = esticado
var tip_local := Vector2.ZERO  # ponta do braço (o feixe do scanner sai daqui)
var glow: PointLight2D


func setup(m, light_tex: Texture2D) -> void:
	main = m
	light = PointLight2D.new()
	light.texture = light_tex
	light.texture_scale = 3.2
	light.energy = 0.0
	light.color = Color(1.0, 0.97, 0.85)
	add_child(light)
	# brilho ciano dos propulsores (aparece no escuro)
	glow = PointLight2D.new()
	glow.texture = light_tex
	glow.texture_scale = 0.9
	glow.energy = 0.0
	glow.color = Color(0.3, 0.95, 1.0)
	add_child(glow)


func _process(delta: float) -> void:
	t += delta
	blink = maxf(0.0, blink - delta)
	var input := Vector2.ZERO
	if not locked:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		input = auto_move
	if input.length() > 0.1:
		velocity += input * ACCEL * delta
		if absf(input.x) > 0.2:
			facing = signf(input.x)
	velocity -= velocity * DRAG * delta
	velocity = velocity.limit_length(MAX_SPEED)
	position += velocity * delta

	# limites do mundo e da pressão do casco
	position.x = clampf(position.x, 60.0, Data.WORLD_W - 60.0)
	var max_y: float = main.max_depth_for(position)
	if position.y > max_y:
		position.y = max_y
		velocity.y = minf(velocity.y, 0.0)
		main.on_pressure_limit()
	if position.y < 40.0:
		position.y = 40.0
		velocity.y = maxf(velocity.y, 0.0)

	rotation = lerp_angle(rotation, clampf(velocity.y / MAX_SPEED, -0.5, 0.5) * 0.5 * facing, delta * 6.0)

	# luz dos faróis aumenta com a profundidade
	var target_energy := clampf((position.y - 1300.0) / 1500.0, 0.0, 1.0) * 1.3
	if position.y > 4000.0:
		target_energy = 0.4
	light.energy = lerpf(light.energy, target_energy, delta * 2.0)
	glow.energy = lerpf(glow.energy, clampf((position.y - 1200.0) / 1500.0, 0.0, 1.0) * 1.1, delta * 2.0)
	glow.position = Vector2(-50 * facing, 8)
	# luz apagada não deve custar nada (luzes 2D pesam muito no navegador)
	light.enabled = light.energy > 0.03
	glow.enabled = glow.energy > 0.03 and not main.lite

	# bolhas do propulsor
	if velocity.length() > 40.0 and randf() < 0.5:
		bubbles.append([position + Vector2(-64 * facing, 4 + randf_range(-5, 5)), 1.0])
	for b in bubbles:
		b[1] -= delta * 1.2
		b[0] += Vector2(randf_range(-10, 10), -40) * delta
	bubbles = bubbles.filter(func(b): return b[1] > 0.0)
	arm = move_toward(arm, 1.0 if arm_target != null else 0.0, delta * 4.0)
	queue_redraw()


func _draw() -> void:
	# bolhas (em coordenadas do mundo -> locais)
	var inv := global_transform.affine_inverse()
	for b in bubbles:
		draw_circle(inv * b[0], 3.0 + (1.0 - b[1]) * 3.0, Color(1, 1, 1, 0.35 * b[1]))
	if blink > 0.0 and int(blink * 10.0) % 2 == 0:
		return
	_draw_sub(facing)


## Arredonda um polígono de cápsula (corpo do submarino)
func _capsule(front: Vector2, rf: float, back: Vector2, rb: float, f: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(13):
		var a := -PI / 2 + PI * i / 12.0
		pts.append(Vector2((front.x + cos(a) * rf) * f, front.y + sin(a) * rf))
	for i in range(13):
		var a := PI / 2 + PI * i / 12.0
		pts.append(Vector2((back.x + cos(a) * rb) * f, back.y + sin(a) * rb))
	return pts


var _f := 1.0


func _p(x: float, y: float) -> Vector2:
	return Vector2(x * _f, y)


func _outline(pts: PackedVector2Array, col: Color, w: float) -> void:
	var o := pts.duplicate()
	o.append(pts[0])
	draw_polyline(o, col, w, true)


## Mini-submarino "Manta": casulo arredondado azul-marinho com dorso dourado,
## grande cúpula de vidro com o Arthur, asas largas de arraia varridas para trás,
## luzes ciano nos propulsores e braço mecânico do scanner embaixo.
func _bez(a: Vector2, c: Vector2, b: Vector2, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(n + 1):
		var k := float(i) / n
		out.append(a.lerp(c, k).lerp(c.lerp(b, k), k))
	return out


func _draw_sub(f: float) -> void:
	_f = f
	var line := Color(0.04, 0.06, 0.13)
	var navy := Color(0.11, 0.16, 0.28)
	var navy_hi := Color(0.22, 0.3, 0.47)
	var gold := Color(1.0, 0.74, 0.12)
	var gold_hi := Color(1.0, 0.9, 0.48)
	var gold_lo := Color(0.8, 0.52, 0.05)
	var cyan := Color(0.35, 0.95, 1.0)
	var steel := Color(0.55, 0.6, 0.7)
	var flap := sin(t * 3.0) * 3.0
	var pulse := 0.75 + sin(t * 6.0) * 0.25
	var depth_dark := clampf((position.y - 1500.0) / 1500.0, 0.0, 1.0)

	# feixe dos faróis (mais visível no escuro)
	var beam_a := depth_dark * 0.22
	if beam_a > 0.01 and position.y < 4000.0:
		draw_colored_polygon(PackedVector2Array([_p(50, 8), _p(360, -80), _p(360, 120)]), Color(1.0, 0.97, 0.8, beam_a))

	# asa do lado de lá (aparece atrás do corpo, inclinada para baixo)
	var far_top := _bez(_p(4, 10), _p(-40, 14), _p(-74, 26 + flap), 10)
	var far_bot := _bez(_p(-74, 26 + flap), _p(-48, 26), _p(-4, 18), 10)
	var wing_far := far_top.duplicate()
	wing_far.append_array(far_bot)
	draw_colored_polygon(wing_far, gold_lo.darkened(0.25))
	_outline(wing_far, line, 2.5)

	# barbatana da cauda
	var fin := _bez(_p(-30, -16), _p(-44, -24), _p(-58, -36), 6)
	fin.append_array(_bez(_p(-58, -36), _p(-56, -20), _p(-46, -6), 6))
	draw_colored_polygon(fin, navy_hi)
	_outline(fin, line, 2.0)
	draw_line(_p(-50, -30), _p(-40, -14), gold, 2.5)

	# corpo: casulo arredondado (frente cheia, traseira afinando)
	var body := PackedVector2Array()
	body.append_array(_bez(_p(-52, 0), _p(-40, -24), _p(6, -26), 10))
	body.append_array(_bez(_p(6, -26), _p(54, -26), _p(54, 2), 10))
	body.append_array(_bez(_p(54, 2), _p(52, 22), _p(10, 22), 10))
	body.append_array(_bez(_p(10, 22), _p(-38, 20), _p(-52, 0), 10))
	var cols := PackedColorArray()
	for v in body:
		cols.append(navy_hi.lerp(navy.darkened(0.35), clampf((v.y + 26.0) / 48.0, 0.0, 1.0)))
	draw_polygon(body, cols)
	# dorso dourado (faixa curva acima da linha do meio)
	var back := _bez(_p(-50, -2), _p(-36, -20), _p(4, -21), 10)
	back.append_array(_bez(_p(4, -21), _p(46, -21), _p(52, -2), 10))
	back.append_array(_bez(_p(52, -2), _p(30, 2), _p(4, 2), 8))
	back.append_array(_bez(_p(4, 2), _p(-30, 2), _p(-50, -2), 8))
	var bcols := PackedColorArray()
	for v in back:
		bcols.append(gold_hi.lerp(gold_lo, clampf((v.y + 21.0) / 23.0, 0.0, 1.0)))
	draw_polygon(back, bcols)
	# brilho e linhas de painel
	draw_polyline(_bez(_p(-36, -10), _p(-20, -18), _p(0, -19), 6), Color(1, 1, 1, 0.6), 3.0, true)
	for px in [-30.0, -14.0]:
		draw_line(_p(px, -14), _p(px - 2, 2), Color(line.r, line.g, line.b, 0.45), 1.2)
	draw_polyline(_bez(_p(-48, 8), _p(0, 14), _p(48, 8), 8), Color(line.r, line.g, line.b, 0.45), 1.5, true)
	_outline(body, line, 3.0)

	# propulsor traseiro com brilho ciano
	var thr := _p(-52, 2)
	draw_circle(thr, 14 * pulse, Color(cyan.r, cyan.g, cyan.b, 0.25))
	draw_circle(thr, 7.5, line)
	draw_circle(thr, 5.5, cyan)
	draw_circle(thr, 2.5, Color(0.9, 1.0, 1.0))

	# grande cúpula de vidro com o Arthur dentro
	var dome := _bez(_p(-10, -14), _p(-6, -44), _p(22, -44), 10)
	dome.append_array(_bez(_p(22, -44), _p(48, -42), _p(50, -8), 10))
	dome.append(_p(20, -6))
	var head := _p(16, -24)
	draw_colored_polygon(PackedVector2Array([_p(2, -10), _p(6, -18), _p(28, -18), _p(32, -10)]), Color(0.15, 0.32, 0.5))  # traje
	draw_circle(head, 8.0, Color(0.96, 0.76, 0.6))
	draw_colored_polygon(PackedVector2Array([head + Vector2(-8, -2), head + Vector2(8, -2), head + Vector2(6, -9), head + Vector2(-6, -9)]), Color(0.32, 0.22, 0.12))
	draw_circle(head + Vector2(3.5 * f, 0), 1.6, Color.BLACK)
	draw_arc(head + Vector2(2 * f, 3.5), 2.5, 0.2, 2.9, 6, Color(0.5, 0.2, 0.15), 1.3)
	draw_line(_p(34, -12), _p(44, -14), cyan, 2.0)   # painel iluminado
	draw_colored_polygon(dome, Color(0.4, 0.78, 1.0, 0.35))
	draw_polyline(_bez(_p(-2, -22), _p(2, -38), _p(18, -40), 6), Color(1, 1, 1, 0.8), 3.0, true)
	draw_polyline(_bez(_p(36, -36), _p(42, -32), _p(44, -24), 4), Color(1, 1, 1, 0.5), 2.0, true)
	var dl := dome.duplicate()
	draw_polyline(dl, line, 3.0, true)

	# asa do lado de cá: larga, curva e varrida para trás (como uma arraia)
	var w_top := _bez(_p(26, 4), _p(-20, -6), _p(-84, -16 - flap), 12)
	var w_bot := _bez(_p(-84, -16 - flap), _p(-60, 6), _p(-14, 14), 12)
	w_bot.append(_p(20, 12))
	var wing := w_top.duplicate()
	wing.append_array(w_bot)
	var wcols := PackedColorArray()
	for v in wing:
		var k := clampf((v.x * f + 84.0) / 110.0, 0.0, 1.0)
		wcols.append(gold_lo.lerp(gold_hi, k))
	draw_polygon(wing, wcols)
	draw_polyline(w_top, navy, 4.0, true)                                   # bordo de ataque azul
	draw_polyline(_bez(_p(14, 9), _p(-30, 4), _p(-74, -12 - flap), 8), Color(line.r, line.g, line.b, 0.4), 1.5, true)
	_outline(wing, line, 2.5)
	var tipw := _p(-82, -16 - flap)
	draw_circle(tipw, 7 * pulse, Color(cyan.r, cyan.g, cyan.b, 0.3))
	draw_circle(tipw, 2.8, cyan)

	# luzes ciano embaixo do nariz e faróis
	for lx in [22.0, -18.0]:
		var lp := _p(lx, 19)
		draw_circle(lp, 7 * pulse, Color(cyan.r, cyan.g, cyan.b, 0.28))
		draw_circle(lp, 3.0, cyan)
	draw_circle(_p(52, 6), 4.5, line)
	draw_circle(_p(52, 6), 3.2, Color(1.0, 1.0, 0.8))

	# braço mecânico do scanner (sai de baixo do casco)
	var shoulder := _p(34, 19)
	var hand := shoulder + Vector2(8 * f, 8)
	if arm > 0.01 and arm_target != null:
		var to: Vector2 = (to_local(arm_target) - shoulder).limit_length(46.0)
		hand = shoulder.lerp(shoulder + to, arm)
	var elbow := (shoulder + hand) * 0.5 + Vector2(0, 7)
	if arm > 0.02:
		draw_polyline(PackedVector2Array([shoulder, elbow, hand]), line, 6.0, true)
		draw_polyline(PackedVector2Array([shoulder, elbow, hand]), steel, 3.5, true)
		draw_circle(elbow, 3.2, line)
		var dir_v := (hand - elbow).normalized()
		var nrm := Vector2(-dir_v.y, dir_v.x)
		var claw_open := 4.0 + arm * 3.0
		draw_line(hand, hand + dir_v * 7 + nrm * claw_open, line, 3.0)
		draw_line(hand, hand + dir_v * 7 - nrm * claw_open, line, 3.0)
		tip_local = hand + dir_v * 4
		draw_circle(tip_local, 3.0, cyan)
	else:
		tip_local = shoulder
	draw_circle(shoulder, 4.0, line)
	draw_circle(shoulder, 2.5, steel)
