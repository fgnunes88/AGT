extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Um tubarão que nada livremente dentro da sua zona.
## Cada espécie tem a sua velocidade de cruzeiro e de fuga (o Mako é o mais rápido de todos).
## Se o Manta chegar perto depressa demais, o tubarão se assusta e foge.

const Data = preload("res://scripts/data.gd")
const Art = preload("res://scripts/shark_art.gd")

const SCARE_DIST := 240.0     # distância em que o tubarão percebe o Manta
const SCARE_SPEED := 150.0    # acima desta velocidade do Manta, ele se assusta

var main
var species_id := 0
var sp: Dictionary
var trapped := false
var area := Rect2()
var target := Vector2.ZERO
var velocity := Vector2.ZERO
var dir := 1.0
var t := 0.0
var catalogued := false   # a espécie já está no catálogo
var chipped := false      # ESTE tubarão já recebeu o chip de proteção
var flee_t := 0.0
var glow: PointLight2D


func setup(id: int, pos: Vector2, light_tex: Texture2D, m = null) -> void:
	main = m
	species_id = id
	sp = Data.SPECIES[id]
	position = pos
	var z: int = sp["zone"]
	area = Rect2(150, z * Data.ZONE_H + 90, Data.WORLD_W - 300, Data.ZONE_H - 180)
	target = _random_target()
	t = randf() * 10.0
	if sp["pattern"] == "lantern" and light_tex != null:
		glow = PointLight2D.new()
		glow.texture = light_tex
		glow.texture_scale = 0.6
		glow.color = Color(0.4, 1.0, 1.0)
		glow.energy = 0.9
		add_child(glow)


func _random_target() -> Vector2:
	# tubarões rápidos fazem percursos longos e retos; os lentos passeiam por perto
	var cruise: float = sp["speed"]
	if cruise > 120.0:
		var x := area.position.x if position.x > area.get_center().x else area.end.x
		return Vector2(x + randf_range(-300, 300), randf_range(area.position.y, area.end.y))
	var near := position + Vector2(randf_range(-700, 700), randf_range(-300, 300))
	return Vector2(clampf(near.x, area.position.x, area.end.x), clampf(near.y, area.position.y, area.end.y))


func can_scan() -> bool:
	return not trapped


func can_chip() -> bool:
	return not trapped and not chipped


func scan_time() -> float:
	return 1.6


func hit_radius() -> float:
	return maxf(28.0, float(sp["len"]) * 0.32)


func free_from_trap() -> void:
	trapped = false
	target = position + Vector2(randf_range(-600, 600), randf_range(-150, 150))
	velocity = Vector2(0, -60)


func scare(from: Vector2) -> void:
	if flee_t > 0.0:
		return
	flee_t = 1.6
	var away := (position - from).normalized()
	if away == Vector2.ZERO:
		away = Vector2(1, 0)
	var p := position + away * 600.0
	target = Vector2(clampf(p.x, area.position.x, area.end.x), clampf(p.y, area.position.y, area.end.y))
	if main:
		main.on_shark_scared()


func _process(delta: float) -> void:
	t += delta
	if trapped:
		t += delta * 2.0  # se debate mais rápido
		if Cull.near(self, 300.0):
			queue_redraw()
		return
	# percebe o Manta chegando depressa
	if main and main.player != null and flee_t <= 0.0:
		var pp: Vector2 = main.player.global_position
		var pv: Vector2 = main.player.velocity
		if pp.distance_to(position) < SCARE_DIST and pv.length() > SCARE_SPEED:
			scare(pp)
	flee_t = maxf(0.0, flee_t - delta)
	var speed: float = sp["flee"] if flee_t > 0.0 else sp["speed"]
	var to := target - position
	if to.length() < 50.0:
		target = _random_target()
	var turn := 3.0 if flee_t > 0.0 else 1.5
	velocity = velocity.lerp(to.normalized() * speed, clampf(delta * turn, 0.0, 1.0))
	position += velocity * delta
	position.x = clampf(position.x, 100, Data.WORLD_W - 100)
	position.y = clampf(position.y, area.position.y - 40, area.end.y + 40)
	if absf(velocity.x) > 5.0:
		dir = signf(velocity.x)
	rotation = clampf(velocity.y / maxf(speed, 1.0), -0.4, 0.4) * dir
	if Cull.near(self, 300.0):
		queue_redraw()


func _draw() -> void:
	Art.draw(self, Vector2.ZERO, sp["len"], sp["h"], dir, sp["pattern"], sp["body"], sp["belly"], t * (1.6 if flee_t > 0.0 else 1.0))
	if chipped:
		# etiqueta verde do chip de proteção presa na barbatana
		var p := Vector2(-float(sp["len"]) * 0.05 * dir, -float(sp["h"]) * 0.8)
		draw_circle(p, 8, Color(0.05, 0.25, 0.12))
		draw_circle(p, 6, Color(0.2, 1.0, 0.5))
		draw_circle(p, 2.5, Color.WHITE)
	elif flee_t > 0.0:
		# sinal de susto
		var font := ThemeDB.fallback_font
		var p2 := Vector2(-6, -float(sp["h"]) * 0.9)
		draw_string_outline(font, p2, "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 5, Color.BLACK)
		draw_string(font, p2, "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.85, 0.2))
