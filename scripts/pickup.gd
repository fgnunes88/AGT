extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Coletáveis: peças da Corporação ("part") e gravações do pai ("log").

var kind := "part"
var zone := 0
var text := ""
var t := 0.0


func setup(k: String, pos: Vector2, z: int, txt := "") -> void:
	kind = k
	position = pos
	zone = z
	text = txt
	t = randf() * 5.0


func _process(delta: float) -> void:
	t += delta
	if Cull.near(self, 150.0) and Cull.tick(self, 3):
		queue_redraw()


func _draw() -> void:
	var bob := Vector2(0, sin(t * 2.0) * 6.0)
	if kind == "part":
		draw_circle(bob, 30 + sin(t * 4.0) * 3.0, Color(0.4, 0.8, 1.0, 0.25))
		var hexa := PackedVector2Array()
		for i in range(6):
			var a := TAU * i / 6.0 + t * 0.8
			hexa.append(bob + Vector2(cos(a), sin(a)) * 18.0)
		draw_colored_polygon(hexa, Color(0.96, 0.98, 1.0))
		draw_circle(bob, 7, Color(0.2, 0.7, 1.0))
	else:
		# fita cassete dourada com a voz de Philip Blake
		draw_circle(bob, 32 + sin(t * 3.0) * 3.0, Color(1.0, 0.85, 0.3, 0.25))
		draw_rect(Rect2(bob + Vector2(-22, -14), Vector2(44, 28)), Color(0.95, 0.75, 0.25))
		draw_rect(Rect2(bob + Vector2(-16, -8), Vector2(32, 12)), Color(0.35, 0.22, 0.1))
		draw_circle(bob + Vector2(-8, -2), 4, Color(0.95, 0.9, 0.8))
		draw_circle(bob + Vector2(8, -2), 4, Color(0.95, 0.9, 0.8))
