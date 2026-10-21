extends Node2D
## O Megalodon: a lenda das histórias de Philip Blake.

const Data = preload("res://scripts/data.gd")
const Art = preload("res://scripts/shark_art.gd")

enum State { HIDDEN, APPROACH, CHARGE, RECOIL, CALM }

var main
var base  # megabase.gd
var state := State.HIDDEN
var species_id := Data.MEGALODON_ID
var sp: Dictionary = Data.SPECIES[Data.MEGALODON_ID]
var dir := 1.0
var t := 0.0
var velocity := Vector2.ZERO
var target := Vector2.ZERO
var catalogued := false
var wander := Rect2(3300, 3200, 3200, 600)


func setup(m, b: Node2D) -> void:
	main = m
	base = b
	visible = false
	position = Vector2(2600, 3700)


func can_scan() -> bool:
	return state == State.CALM


func scan_time() -> float:
	return 3.5


func awaken() -> void:
	visible = true
	state = State.APPROACH
	target = base.position + Vector2(-900, -150)


func _process(delta: float) -> void:
	t += delta * 0.6
	match state:
		State.HIDDEN:
			return
		State.APPROACH:
			_move_to(target, 160.0, delta)
			if position.distance_to(target) < 60.0:
				state = State.CHARGE
		State.CHARGE:
			var goal: Vector2 = base.position + Vector2(-330, -120)
			_move_to(goal, 520.0, delta)
			if position.distance_to(goal) < 80.0:
				base.hit()
				main.sfx_at("impacto", position, 2500.0)
				main.shake(22.0)
				state = State.RECOIL
				target = base.position + Vector2(-950, -250 + randf_range(-80, 80))
		State.RECOIL:
			_move_to(target, 220.0, delta)
			if position.distance_to(target) < 80.0:
				if base.state == 2:  # destruída
					state = State.CALM
					target = position
					main.on_base_destroyed()
				else:
					state = State.CHARGE
		State.CALM:
			if position.distance_to(target) < 80.0:
				target = Vector2(randf_range(wander.position.x, wander.end.x), randf_range(wander.position.y, wander.end.y))
			_move_to(target, 70.0, delta)
	queue_redraw()


func _move_to(p: Vector2, speed: float, delta: float) -> void:
	var to := p - position
	velocity = velocity.lerp(to.normalized() * speed, clampf(delta * 2.0, 0.0, 1.0))
	position += velocity * delta
	if absf(velocity.x) > 8.0:
		dir = signf(velocity.x)
	rotation = clampf(velocity.y / maxf(speed, 1.0), -0.3, 0.3) * dir


func _draw() -> void:
	if not visible:
		return
	Art.draw(self, Vector2.ZERO, sp["len"], sp["h"], dir, "mega", sp["body"], sp["belly"], t)
	if catalogued:
		draw_circle(Vector2(0, -sp["h"] * 0.7), 14, Color(0.1, 0.9, 0.4))
