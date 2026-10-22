extends Node2D
const Cull = preload("res://scripts/cull.gd")
## A megabase branca e fria da Corporação, no fundo da Fossa das Marianas.

enum State { INTACT, ALARM, WRECKED }

var state := State.INTACT
var health := 3
var t := 0.0
var light: PointLight2D

const ANTENNA := Vector2(0, -330)


func setup(pos: Vector2, light_tex: Texture2D) -> void:
	position = pos
	light = PointLight2D.new()
	light.texture = light_tex
	light.texture_scale = 5.0
	light.color = Color(0.6, 0.85, 1.0)
	light.energy = 1.1
	light.position = Vector2(0, -120)
	add_child(light)


func antenna_global() -> Vector2:
	return global_position + ANTENNA


func start_alarm() -> void:
	state = State.ALARM


func hit() -> void:
	health -= 1
	if health <= 0:
		state = State.WRECKED


func _process(delta: float) -> void:
	t += delta
	match state:
		State.ALARM:
			var on := int(t * 3.0) % 2 == 0
			light.color = Color(1.0, 0.15, 0.1) if on else Color(0.4, 0.05, 0.05)
			light.energy = 1.4
		State.WRECKED:
			light.energy = lerpf(light.energy, 0.15, delta)
			light.color = Color(1.0, 0.3, 0.2)
			rotation = lerpf(rotation, 0.12, delta * 0.5)
	if Cull.near(self, 700.0):
		queue_redraw()


func _draw() -> void:
	var white := Color(0.95, 0.97, 1.0)
	var shade := Color(0.75, 0.8, 0.88)
	var led := Color(0.3, 0.85, 1.0)
	if state == State.ALARM:
		led = Color(1.0, 0.2, 0.2) if int(t * 3.0) % 2 == 0 else Color(0.5, 0.1, 0.1)
	elif state == State.WRECKED:
		white = Color(0.55, 0.58, 0.62)
		shade = Color(0.4, 0.42, 0.46)
		led = Color(0.4, 0.1, 0.1)
	# dutos gigantes cravados na rocha
	draw_rect(Rect2(-520, -40, 240, 30), shade)
	draw_rect(Rect2(280, -40, 260, 30), shade)
	# blocos principais (geometria fria e perfeita)
	draw_rect(Rect2(-300, -170, 600, 210), white)
	draw_rect(Rect2(-220, -260, 200, 90), white)
	draw_rect(Rect2(40, -230, 160, 60), shade)
	draw_rect(Rect2(-300, -170, 600, 210), shade.darkened(0.3), false, 3.0)
	for i in range(10):
		draw_rect(Rect2(-270 + i * 56, -120, 34, 16), led)
	draw_rect(Rect2(-280, -20, 560, 6), led)
	# antena
	draw_line(Vector2(0, -260), ANTENNA, white, 8.0)
	draw_circle(ANTENNA, 16, led)
	if state == State.INTACT:
		var r := 20.0 + fmod(t * 40.0, 60.0)
		draw_arc(ANTENNA, r, 0, TAU, 32, Color(0.4, 0.9, 1.0, 1.0 - (r - 20.0) / 60.0), 3.0)
	# rachaduras após as investidas do Megalodon
	var cracks := 3 - health
	for i in range(cracks):
		var x := -200.0 + i * 170.0
		draw_polyline(PackedVector2Array([Vector2(x, -170), Vector2(x + 30, -110), Vector2(x - 10, -60), Vector2(x + 25, 0)]), Color(0.1, 0.1, 0.12), 5.0)
	# logo da Corporação
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-120, -50), "NEXUS DEEP CORP.", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.3, 0.5, 0.75))
