extends Control
## Tela inicial "Linha d'água": metade céu com o navio, metade mar com um tubarão.

const Art = preload("res://scripts/shark_art.gd")

signal chosen(option: String)

const OPTIONS := ["Novo Jogo", "Como Jogar", "Sair"]

var sel := 0
var t := 0.0
var show_help := false
var font: Font
var music  # gerenciador de som (main.gd entrega)
var shown := 0.0  # tempo desde que a tela apareceu (evita cliques acidentais)


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visibility_changed.connect(func(): shown = 0.0)


func _process(delta: float) -> void:
	t += delta
	shown += delta
	queue_redraw()


func _option_rect(i: int) -> Rect2:
	var vs := get_viewport_rect().size
	return Rect2(70, vs.y * 0.5 + 40 + i * 64, 300, 52)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or shown < 0.4:
		return
	if show_help:
		if event.is_action_pressed("accept") or event.is_action_pressed("pause") or (event is InputEventMouseButton and event.pressed):
			show_help = false
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_up"):
		sel = (sel + OPTIONS.size() - 1) % OPTIONS.size()
		_click()
	elif event.is_action_pressed("move_down"):
		sel = (sel + 1) % OPTIONS.size()
		_click()
	elif event.is_action_pressed("accept"):
		_choose()
	elif event is InputEventMouseMotion:
		for i in OPTIONS.size():
			if _option_rect(i).has_point(event.position) and sel != i:
				sel = i
				_click()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in OPTIONS.size():
			if _option_rect(i).has_point(event.position):
				sel = i
				_choose()


func _click() -> void:
	if music:
		music.sfx("menu_mover", -4.0)


func _choose() -> void:
	get_viewport().set_input_as_handled()
	if music:
		music.sfx("menu_ok")
	if OPTIONS[sel] == "Como Jogar":
		show_help = true
	else:
		chosen.emit(OPTIONS[sel])


func _text(pos: Vector2, s: String, size: int, col: Color, outline := 8, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string_outline(font, pos, s, align, width, size, outline, Color(0.02, 0.1, 0.2, 0.9))
	draw_string(font, pos, s, align, width, size, col)


func _draw() -> void:
	var vs := get_viewport_rect().size
	var wl := vs.y * 0.45 + sin(t * 1.3) * 4.0
	var line := Color(0.12, 0.16, 0.28)
	# céu do fim de tarde
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0), Vector2(vs.x, wl), Vector2(0, wl)]),
		PackedColorArray([Color(0.33, 0.58, 0.95), Color(0.33, 0.58, 0.95), Color(1.0, 0.76, 0.52), Color(1.0, 0.76, 0.52)]))
	var sun := Vector2(vs.x * 0.78, wl - 70)
	draw_circle(sun, 95, Color(1.0, 0.9, 0.55, 0.25))
	draw_circle(sun, 62, Color(1.0, 0.92, 0.6))
	# nuvens fofas
	for c in [Vector2(vs.x * 0.55, 90), Vector2(vs.x * 0.9, 150), Vector2(vs.x * 0.42, 40)]:
		var cx: float = c.x + fmod(t * 6.0, 80.0) - 40.0
		for k in range(5):
			draw_circle(Vector2(cx + k * 34 - 68, c.y - sin(k * 0.9) * 14), 28 - absf(k - 2) * 4, Color(1, 1, 1, 0.85))
	# ilha com coqueiro ao longe
	var ix := vs.x * 0.92
	draw_colored_polygon(PackedVector2Array([Vector2(ix - 140, wl), Vector2(ix - 40, wl - 70), Vector2(ix + 30, wl - 90), Vector2(ix + 160, wl)]), Color(0.3, 0.55, 0.4))
	draw_line(Vector2(ix - 10, wl - 80), Vector2(ix + 4, wl - 150), Color(0.45, 0.32, 0.2), 6)
	for a in [-2.6, -2.0, -1.2, -0.5]:
		draw_line(Vector2(ix + 4, wl - 150), Vector2(ix + 4, wl - 150) + Vector2(cos(a), sin(a) + 0.6) * 40, Color(0.15, 0.5, 0.25), 7)
	# plataforma do Sindicato no horizonte
	var px := vs.x * 0.6
	var plat := Color(0.32, 0.3, 0.36)
	draw_rect(Rect2(px, wl - 92, 124, 16), plat)
	draw_rect(Rect2(px + 20, wl - 120, 50, 28), plat.lightened(0.1))
	for i in range(4):
		draw_line(Vector2(px + 10 + i * 34, wl - 76), Vector2(px + 10 + i * 34, wl), plat, 6)
	draw_line(Vector2(px + 96, wl - 92), Vector2(px + 108, wl - 160), plat, 4)
	draw_circle(Vector2(px + 108, wl - 162), 4, Color(1.0, 0.3, 0.2) if int(t * 2) % 2 == 0 else Color(0.5, 0.1, 0.1))
	# mar com degradê
	draw_polygon(PackedVector2Array([Vector2(0, wl), Vector2(vs.x, wl), Vector2(vs.x, vs.y), Vector2(0, vs.y)]),
		PackedColorArray([Color(0.22, 0.78, 0.94), Color(0.22, 0.78, 0.94), Color(0.03, 0.27, 0.52), Color(0.03, 0.27, 0.52)]))
	# raios de sol
	for i in range(7):
		var x := fmod(i * 230.0 + t * 15.0, vs.x + 200.0) - 100.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, wl), Vector2(x + 70, wl), Vector2(x + 220, vs.y), Vector2(x + 120, vs.y)]), Color(1, 1, 0.85, 0.07))
	# luz cáustica ondulante
	for row in range(5):
		var yy := wl + 40 + row * 55
		var pts := PackedVector2Array()
		var xx := 0.0
		while xx <= vs.x + 30:
			pts.append(Vector2(xx, yy + sin(xx * 0.03 + t * 1.6 + row) * 10.0))
			xx += 30
		draw_polyline(pts, Color(1, 1, 0.9, 0.12 - row * 0.02), 3)
	# cardume de peixinhos
	for k in range(12):
		var fx := fmod(t * 60.0 + k * 37.0, vs.x + 300.0) - 150.0
		var fy := vs.y * 0.62 + sin(k * 1.7) * 40 + sin(t * 2 + k) * 6
		var fp := Vector2(vs.x - fx, fy)
		draw_colored_polygon(PackedVector2Array([fp + Vector2(9, 0), fp + Vector2(17, -6), fp + Vector2(17, 6)]), Color(0.2, 0.4, 0.9))
		var fb := PackedVector2Array()
		for i in range(10):
			var a := TAU * i / 10.0
			fb.append(fp + Vector2(cos(a) * 11, sin(a) * 5.5))
		draw_colored_polygon(fb, Color(1.0, 0.85, 0.2))
		draw_circle(fp + Vector2(-6, -1), 1.8, Color.BLACK)
	# tubarão-branco nadando
	var sx := fmod(t * 90.0, vs.x + 600.0) - 300.0
	Art.draw(self, Vector2(sx, vs.y * 0.74 + sin(t) * 10.0), 260, 75, 1.0, "white", Color(0.5, 0.56, 0.64), Color(0.97, 0.97, 0.97), t)
	# recife no fundo: areia, rochas e corais
	draw_polygon(PackedVector2Array([Vector2(0, vs.y - 40), Vector2(vs.x, vs.y - 55), Vector2(vs.x, vs.y), Vector2(0, vs.y)]),
		PackedColorArray([Color(0.95, 0.85, 0.6), Color(0.95, 0.85, 0.6), Color(0.8, 0.68, 0.45), Color(0.8, 0.68, 0.45)]))
	for i in range(8):
		var rx := i * vs.x / 7.0
		var rock := PackedVector2Array([Vector2(rx - 70, vs.y), Vector2(rx - 50, vs.y - 50 - (i % 3) * 15), Vector2(rx + 10, vs.y - 70 - (i % 2) * 20), Vector2(rx + 60, vs.y - 40), Vector2(rx + 80, vs.y)])
		draw_colored_polygon(rock, Color(0.72, 0.58, 0.45))
		var ro := rock.duplicate()
		draw_polyline(ro, Color(0.4, 0.3, 0.22), 3)
	for i in range(16):
		var cx := 30.0 + i * (vs.x - 60) / 15.0
		var kind: int = i % 6
		var col := Color.from_hsv(fmod(0.9 + i * 0.07, 1.0), 0.7, 1.0)
		Art.draw_coral(self, Vector2(cx, vs.y - 50 - (i % 3) * 12), kind, col, 1.1)
	# bolhas subindo
	for k in range(10):
		var by := vs.y - fmod(t * 50.0 + k * 61.0, vs.y - wl)
		draw_arc(Vector2(140 + k * 113 + sin(t + k) * 8, by), 4 + (k % 3), 0, TAU, 10, Color(1, 1, 1, 0.5), 1.5)
	# linha da água
	var waves := PackedVector2Array()
	for i in range(0, int(vs.x) + 41, 20):
		waves.append(Vector2(i, wl + sin(t * 2.0 + i * 0.03) * 5.0))
	draw_polyline(waves, Color(1, 1, 1, 0.9), 4)
	# navio de pesquisa de Arthur (com contornos)
	var sp := Vector2(vs.x * 0.3, wl + sin(t * 1.5) * 4.0)
	draw_line(sp + Vector2(-20, -96), sp + Vector2(-20, -140), Color(0.3, 0.3, 0.35), 4)
	draw_circle(sp + Vector2(-20, -144), 8, Color(0.9, 0.35, 0.15))
	draw_line(sp + Vector2(100, -36), sp + Vector2(135, -120), Color(0.3, 0.3, 0.35), 6)
	var hull := PackedVector2Array([sp + Vector2(-145, -38), sp + Vector2(168, -38), sp + Vector2(124, 18), sp + Vector2(-128, 18)])
	draw_polygon(hull, PackedColorArray([Color(1, 1, 1), Color(1, 1, 1), Color(0.78, 0.82, 0.88), Color(0.78, 0.82, 0.88)]))
	draw_rect(Rect2(sp + Vector2(-136, -12), Vector2(292, 10)), Color(0.9, 0.35, 0.15))
	var ho := hull.duplicate()
	ho.append(hull[0])
	draw_polyline(ho, line, 3)
	for i in range(4):
		draw_circle(sp + Vector2(-90 + i * 50, -26), 5, Color(0.35, 0.65, 0.9))
		draw_arc(sp + Vector2(-90 + i * 50, -26), 5, 0, TAU, 10, line, 2)
	draw_rect(Rect2(sp + Vector2(-80, -98), Vector2(120, 60)), Color(0.97, 0.97, 0.99))
	draw_rect(Rect2(sp + Vector2(-80, -98), Vector2(120, 60)), line, false, 3)
	draw_rect(Rect2(sp + Vector2(-72, -88), Vector2(104, 22)), Color(0.45, 0.78, 0.98))
	draw_line(sp + Vector2(-62, -86), sp + Vector2(-46, -68), Color(1, 1, 1, 0.7), 3)

	# título
	_text(Vector2(70, 110), "ARTHUR,", 72, Color(1.0, 0.85, 0.3), 12)
	_text(Vector2(74, 162), "O Guardião dos Tubarões", 38, Color(1, 1, 1), 8)
	# menu
	for i in OPTIONS.size():
		var r := _option_rect(i)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(14)
		sb.bg_color = Color(1.0, 0.8, 0.2, 0.95) if i == sel else Color(0.02, 0.15, 0.3, 0.7)
		draw_style_box(sb, r)
		_text(r.position + Vector2(24, 36), OPTIONS[i], 28, Color(0.05, 0.1, 0.2) if i == sel else Color.WHITE, 0 if i == sel else 6)
	_text(Vector2(vs.x - 380, vs.y - 20), "Setas + ENTER  ou  clique com o mouse", 18, Color(1, 1, 1, 0.85), 5)

	if show_help:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.6))
		var r := Rect2(vs.x / 2 - 440, vs.y / 2 - 300, 880, 600)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(20)
		sb.bg_color = Color(0.03, 0.15, 0.3, 0.97)
		sb.border_color = Color(1.0, 0.85, 0.3)
		sb.set_border_width_all(3)
		draw_style_box(sb, r)
		var lines := [
			"COMO JOGAR",
			"",
			"Setas ou WASD: pilotar o Manta",
			"ESPAÇO (segurar): escanear e catalogar uma espécie nova",
			"F: disparar o chip de proteção em cada tubarão (mire bem!)",
			"E (segurar): soltar tubarões presos em redes e gaiolas",
			"Q: Pulso EMP - desliga os drones por alguns segundos",
			"C: abrir o catálogo de espécies      ESC: pausa",
			"",
			"Fuja dos cones de luz dos drones. Esconda-se nas algas!",
			"Para descer mais fundo: 3 peças da Corporação + 6 chips em cada zona.",
			"Chegue devagar: tubarões fogem de movimentos rápidos!",
			"Seu grande objetivo: encontrar o Megalodon na Fossa das Marianas.",
		]
		for i in lines.size():
			var c := Color(1.0, 0.85, 0.3) if i == 0 else Color.WHITE
			_text(r.position + Vector2(40, 56 + i * 37), lines[i], 30 if i == 0 else 21, c, 5)
		_text(r.position + Vector2(40, r.size.y - 24), "ENTER para voltar", 18, Color(0.7, 0.9, 1.0), 4)
