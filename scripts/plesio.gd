extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Dinossauros marinhos pacíficos do Santuário Perdido.

const Art = preload("res://scripts/shark_art.gd")

var t := 0.0
var dir := 1.0
var speed := 50.0
var size := 160.0
var col := Color(0.35, 0.6, 0.55)
var x_range := Vector2(4600, 6800)


func setup(pos: Vector2, s: float, c: Color) -> void:
	position = pos
	size = s
	col = c
	t = randf() * 10.0
	dir = 1.0 if randf() < 0.5 else -1.0


func _process(delta: float) -> void:
	t += delta
	position.x += dir * speed * delta
	position.y += sin(t * 0.7) * 10.0 * delta
	if position.x > x_range.y:
		dir = -1.0
	elif position.x < x_range.x:
		dir = 1.0
	if Cull.near(self, 400.0):
		queue_redraw()


func _draw() -> void:
	Art.draw_plesio(self, Vector2.ZERO, size, dir, t, col)
