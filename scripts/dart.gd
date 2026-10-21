extends Node2D
## Dardo com o chip de proteção, disparado pelo braço do Manta (tecla F).
## Voa em linha reta; se encostar num tubarão catalogado e sem chip, implanta o chip.
## Tubarões rápidos exigem boa mira: é preciso chegar alinhado com eles.

const SPEED := 720.0
const LIFE := 0.6

var main
var velocity := Vector2.ZERO
var life := LIFE
var trail: Array = []


func setup(m, from: Vector2, aim: Vector2) -> void:
	main = m
	position = from
	velocity = (aim - from).normalized() * SPEED
	rotation = velocity.angle()


func _process(delta: float) -> void:
	life -= delta
	trail.push_front(global_position)
	if trail.size() > 8:
		trail.pop_back()
	position += velocity * delta
	if main == null or main.sharks_node == null:
		queue_free()
		return
	for s in main.sharks_node.get_children():
		if s.can_chip() and main.catalog.has(s.species_id) and s.position.distance_to(position) < s.hit_radius():
			main.chip_shark(s)
			queue_free()
			return
	if life <= 0.0:
		main.on_dart_missed()
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var inv := global_transform.affine_inverse()
	for i in range(1, trail.size()):
		draw_line(inv * trail[i - 1], inv * trail[i], Color(0.4, 1.0, 0.7, 0.5 * (1.0 - float(i) / trail.size())), 3.0)
	draw_circle(Vector2.ZERO, 8, Color(0.3, 1.0, 0.6, 0.3))
	draw_line(Vector2(-9, 0), Vector2(7, 0), Color(0.05, 0.1, 0.15), 6.0)
	draw_line(Vector2(-8, 0), Vector2(6, 0), Color(0.75, 0.8, 0.9), 3.5)
	draw_circle(Vector2(7, 0), 3, Color(0.3, 1.0, 0.6))
