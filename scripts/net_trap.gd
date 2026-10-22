extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Rede ou gaiola ilegal com um tubarão preso. Segure E perto dela para soltar.

var shark: Node2D
var style := "net"
var progress := 0.0
var freed := false
var t := 0.0


func setup(pos: Vector2, s: Node2D, st: String) -> void:
	position = pos
	shark = s
	style = st


func _process(delta: float) -> void:
	t += delta
	if shark and not freed:
		shark.position = position + Vector2(sin(t * 3.0) * 6.0, cos(t * 2.0) * 3.0)
	if Cull.near(self, 300.0) and Cull.tick(self, 3):
		queue_redraw()


func _draw() -> void:
	if freed:
		return
	var r := Rect2(-110, -60, 220, 120)
	if style == "net":
		var c := Color(0.9, 0.85, 0.6, 0.85)
		# corda até a boia na superfície
		draw_line(Vector2(0, -60), Vector2(0, -position.y + 10), Color(0.8, 0.75, 0.5, 0.6), 2.0)
		draw_circle(Vector2(0, -position.y + 10), 12, Color(1.0, 0.3, 0.2))
		for i in range(12):
			var x := r.position.x + i * r.size.x / 11.0
			draw_line(Vector2(x, r.position.y + sin(t + i) * 4), Vector2(x + 10, r.end.y), c, 2.0)
		for j in range(7):
			var y := r.position.y + j * r.size.y / 6.0
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y + sin(t + j) * 3), c, 2.0)
	else:
		var c := Color(0.9, 0.95, 1.0)
		draw_rect(r, Color(0.8, 0.9, 1.0, 0.08))
		for i in range(10):
			var x := r.position.x + i * r.size.x / 9.0
			draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), c, 3.0)
		draw_rect(r, c, false, 5.0)
		draw_circle(Vector2(0, r.position.y - 6), 6, Color(1.0, 0.2, 0.2) if int(t * 2) % 2 == 0 else Color(0.4, 0.1, 0.1))
	if progress > 0.0:
		draw_arc(Vector2(0, r.position.y - 30), 18, -PI / 2, -PI / 2 + TAU * progress, 32, Color(0.3, 1.0, 0.5), 6.0)
