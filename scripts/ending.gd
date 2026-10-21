extends Control
## Cena final: o Manta sobe e um vulto colossal passa nas profundezas.

signal finished

var t := -1.0
var stats := ""
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func play(stats_text: String) -> void:
	stats = stats_text
	t = 0.0
	visible = true


func _process(delta: float) -> void:
	if t < 0.0:
		return
	t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var tapped: bool = event is InputEventMouseButton and event.pressed
	if visible and t > 16.0 and (event.is_action_pressed("accept") or tapped):
		get_viewport().set_input_as_handled()
		visible = false
		t = -1.0
		finished.emit.call_deferred()


func _center_text(y: float, s: String, size: int, col: Color) -> void:
	var w := get_viewport_rect().size.x
	draw_string_outline(font, Vector2(0, y), s, HORIZONTAL_ALIGNMENT_CENTER, w, size, 8, Color(0, 0, 0, col.a))
	draw_string(font, Vector2(0, y), s, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)


func _draw() -> void:
	var vs := get_viewport_rect().size
	# fundo: do breu do abismo até a luz dourada da superfície
	var up := clampf(t / 15.0, 0.0, 1.0)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0), vs, Vector2(0, vs.y)]),
		PackedColorArray([Color(0.02, 0.05, 0.12).lerp(Color(0.2, 0.55, 0.8), up * up), Color(0.02, 0.05, 0.12).lerp(Color(0.2, 0.55, 0.8), up * up), Color.BLACK, Color.BLACK]))
	# o vulto colossal (passa por trás, lá no fundo)
	if t > 4.0 and t < 15.0:
		var k := (t - 4.0) / 11.0
		var cx := lerpf(vs.x * 1.6, -vs.x * 0.6, k)
		var cy := vs.y * 0.9
		var L := vs.x * 1.3
		var H := vs.y * 0.45
		var shadow := Color(0.0, 0.0, 0.02, 0.9)
		var body := PackedVector2Array()
		for i in range(28):
			var a := TAU * i / 28.0
			body.append(Vector2(cx + cos(a) * L * 0.5, cy + sin(a) * H * 0.5))
		draw_colored_polygon(body, shadow)
		draw_colored_polygon(PackedVector2Array([Vector2(cx + L * 0.45, cy), Vector2(cx + L * 0.9, cy - H * 0.6 + sin(t * 2.0) * 30.0), Vector2(cx + L * 0.8, cy), Vector2(cx + L * 0.9, cy + H * 0.6)]), shadow)
		var glow := 0.6 + sin(t * 3.0) * 0.3
		draw_circle(Vector2(cx - L * 0.38, cy - H * 0.12), 14, Color(1.0, 0.85, 0.3, glow))
		draw_circle(Vector2(cx - L * 0.38, cy - H * 0.12), 6, Color(1.0, 1.0, 0.8, glow))
	# o Manta subindo, com sua luzinha
	var my := lerpf(vs.y * 0.75, vs.y * 0.15, clampf(t / 15.0, 0.0, 1.0))
	var mp := Vector2(vs.x / 2, my)
	draw_circle(mp, 90, Color(1.0, 0.95, 0.7, 0.12))
	draw_circle(mp, 40, Color(1.0, 0.95, 0.7, 0.2))
	draw_colored_polygon(PackedVector2Array([mp + Vector2(-26, 0), mp + Vector2(0, -12), mp + Vector2(26, 0), mp + Vector2(0, 10)]), Color(1.0, 0.78, 0.15))
	# textos
	if t > 9.0 and t < 15.5:
		var a := clampf((t - 9.0), 0.0, 1.0) * clampf(15.5 - t, 0.0, 1.0)
		_center_text(vs.y * 0.45, "O mar sempre terá novos mistérios...", 34, Color(1, 1, 1, a))
	if t > 15.0:
		var a := clampf(t - 15.0, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, a * 0.75))
		_center_text(vs.y * 0.3, "FIM", 80, Color(1.0, 0.85, 0.3, a))
		_center_text(vs.y * 0.42, "Obrigado por proteger os oceanos, Guardião!", 30, Color(1, 1, 1, a))
		var lines := stats.split("\n")
		for i in lines.size():
			_center_text(vs.y * 0.55 + i * 36, lines[i], 24, Color(0.7, 1.0, 0.8, a))
		if t > 16.0:
			_center_text(vs.y - 40, "ENTER ou toque: voltar ao menu", 20, Color(1, 1, 1, 0.6 + sin(t * 3.0) * 0.3))
