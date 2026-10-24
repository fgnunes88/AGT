extends Node2D
const Cull = preload("res://scripts/cull.gd")
## Um tubarão que nada livremente dentro da sua zona.
## Cada espécie tem a sua velocidade de cruzeiro e de fuga (o Mako é o mais rápido de todos).
## Se o Manta chegar perto depressa demais, o tubarão se assusta e foge.

const Data = preload("res://scripts/data.gd")
const Art = preload("res://scripts/shark_art.gd")

const SCARE_DIST := 330.0     # distância em que o tubarão percebe o Manta
const SCARE_SPEED := 105.0    # acima desta velocidade do Manta, ele se assusta
const SPACING := 260.0        # distância que cada tubarão tenta manter dos outros

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
var stuck_t := 0.0          # tempo tentando chegar ao alvo atual
var push := Vector2.ZERO    # empurrãozinho para longe de outros tubarões
var push_t := 0.0
var glow: PointLight2D
var anim_t := 0.0
var holder: Node2D          # no navegador: imagem pronta do tubarão (vira para os dois lados)
var sprite: Sprite2D
var frames: Array = []
const SWIM_PERIOD := TAU / 6.0   # um ciclo completo do nado
const FRAMES := 6


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
	if m != null and m.baker != null:
		var L: float = sp["len"]
		var H: float = sp["h"]
		var area_d := Rect2(-L * 1.25, -H * 1.2, L * 2.2, H * 2.3)
		frames = m.baker.request("shark_%d" % id, area_d, 1.0, FRAMES, _make_drawer(sp))
		holder = Node2D.new()
		holder.show_behind_parent = true   # a etiqueta do chip fica por cima
		add_child(holder)
		sprite = m.baker.make_sprite(frames[0], area_d, 1.0)
		holder.add_child(sprite)


static func _make_drawer(spd: Dictionary) -> Callable:
	return func(ci: CanvasItem, f: int) -> void:
		Art.draw(ci, Vector2.ZERO, spd["len"], spd["h"], 1.0, spd["pattern"], spd["body"], spd["belly"], f * SWIM_PERIOD / FRAMES)


func _clamp_area(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, area.position.x, area.end.x), clampf(p.y, area.position.y, area.end.y))


func _one_target() -> Vector2:
	# tubarões rápidos fazem percursos longos e retos; os lentos passeiam por perto
	var cruise: float = sp["speed"]
	var cx := area.get_center().x
	if cruise > 120.0:
		var x := randf_range(area.position.x, cx - 300.0) if position.x > cx else randf_range(cx + 300.0, area.end.x)
		return Vector2(x, randf_range(area.position.y, area.end.y))
	return _clamp_area(position + Vector2(randf_range(-700, 700), randf_range(-300, 300)))


## Sorteia alguns destinos e escolhe o que tem menos tubarões por perto
## (assim eles se espalham pelo cenário em vez de se juntarem nos cantos).
func _random_target() -> Vector2:
	stuck_t = 0.0
	var best := _one_target()
	if main == null or main.sharks_node == null:
		return best
	var best_score := INF
	for i in 4:
		var c := best if i == 0 else _one_target()
		var score := 0.0
		for o in main.sharks_node.get_children():
			if o == self or o.trapped:
				continue
			var d: float = o.position.distance_to(c)
			if d < 700.0:
				score += 1.0 - d / 700.0
		# evita os cantos e as bordas
		var edge := minf(minf(c.x - area.position.x, area.end.x - c.x) / 400.0, 1.0)
		score += (1.0 - edge) * 0.6
		if score < best_score:
			best_score = score
			best = c
	return best


func _update_push() -> void:
	push = Vector2.ZERO
	if main == null or main.sharks_node == null:
		return
	for o in main.sharks_node.get_children():
		if o == self or o.trapped:
			continue
		var off: Vector2 = position - o.position
		var d := off.length()
		if d < SPACING and d > 0.01:
			push += off / d * (1.0 - d / SPACING)


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
	target = _clamp_area(position + Vector2(randf_range(-600, 600), randf_range(-150, 150)))
	velocity = Vector2(0, -60)


func scare(from: Vector2) -> void:
	if flee_t > 0.0:
		return
	flee_t = 1.6
	var away := (position - from).normalized()
	if away == Vector2.ZERO:
		away = Vector2(1, 0)
	# foge para longe do Manta; se a fuga bater num canto, desvia para um lado
	target = _clamp_area(position + away * 600.0)
	for ang in [0.9, -0.9, 1.6, -1.6]:
		if target.distance_to(position) > 380.0:
			break
		target = _clamp_area(position + away.rotated(ang) * 600.0)
	if main:
		main.on_shark_scared()


func _update_sprite(delta: float) -> void:
	anim_t += delta * (1.6 if flee_t > 0.0 else 1.0) * (3.0 if trapped else 1.0)
	holder.scale.x = dir
	sprite.texture = frames[int(fposmod(anim_t, SWIM_PERIOD) / SWIM_PERIOD * FRAMES) % FRAMES]


func _process(delta: float) -> void:
	t += delta
	if sprite != null:
		_update_sprite(delta)
	if trapped:
		t += delta * 2.0  # se debate mais rápido
		if Cull.near(self, 300.0) and Cull.tick(self, 3):
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
	stuck_t += delta
	if to.length() < 50.0 or (stuck_t > 9.0 and flee_t <= 0.0):
		target = _random_target()
		to = target - position
	push_t -= delta
	if push_t <= 0.0:
		push_t = 0.3
		_update_push()
	var want := to.normalized() * speed
	if flee_t <= 0.0:
		want = (to.normalized() + push * 1.2).normalized() * speed
	var turn := 3.0 if flee_t > 0.0 else 1.5
	velocity = velocity.lerp(want, clampf(delta * turn, 0.0, 1.0))
	position += velocity * delta
	position.x = clampf(position.x, 100, Data.WORLD_W - 100)
	position.y = clampf(position.y, area.position.y - 40, area.end.y + 40)
	if absf(velocity.x) > 5.0:
		dir = signf(velocity.x)
	rotation = clampf(velocity.y / maxf(speed, 1.0), -0.4, 0.4) * dir
	if Cull.near(self, 300.0) and Cull.tick(self, 3):
		queue_redraw()


func _draw() -> void:
	if sprite == null:
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
