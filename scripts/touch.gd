extends Control
## Controles de toque para celular e tablet.
## Joystick virtual à esquerda e botões de ação à direita.
## Aparece sozinho em aparelhos com tela de toque (ou no primeiro toque na tela).

const JOY_RADIUS := 95.0

var main
var active := false
var joy_index := -1
var joy_center := Vector2.ZERO
var joy_vec := Vector2.ZERO
var held := {}            # índice do toque -> nome do botão
var font: Font

# estados do main.gd (GameState)
const S_PLAY := 1
const S_CATALOG := 2
const S_PAUSE := 3

# nome: [ação, tipo ("hold" ou "tap"), rótulo, cor]
const BUTTONS := {
	"scan": ["scan", "hold", "CATALOGAR", Color(0.3, 0.95, 0.6)],
	"chip": ["chip", "tap", "CHIP", Color(0.35, 1.0, 0.85)],
	"interact": ["interact", "hold", "SOLTAR", Color(1.0, 0.85, 0.35)],
	"emp": ["emp", "tap", "EMP", Color(0.5, 0.8, 1.0)],
	"catalog": ["catalog", "tap", "CATÁLOGO", Color(1.0, 1.0, 1.0)],
	"pause": ["pause", "tap", "II", Color(1.0, 1.0, 1.0)],
}


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	active = DisplayServer.is_touchscreen_available() and (OS.has_feature("web") or OS.has_feature("mobile"))


func _button_rects() -> Dictionary:
	var vs := get_viewport_rect().size
	var r := 64.0
	var cx := vs.x - 110.0
	var cy := vs.y - 215.0
	return {
		"scan": Rect2(cx - r, cy - r, r * 2, r * 2),
		"chip": Rect2(cx - 175 - 50, cy - 20 - 50, 100, 100),
		"interact": Rect2(cx - 50, cy - 210 - 50, 100, 100),
		"emp": Rect2(cx - 175 - 45, cy - 170 - 45, 90, 90),
		"catalog": Rect2(vs.x - 380, 130, 170, 56),
		"pause": Rect2(vs.x - 190, 130, 70, 56),
	}


func _visible_buttons() -> Array:
	if main == null:
		return []
	match main.state:
		S_PLAY:
			return BUTTONS.keys()
		S_PAUSE:
			return ["pause"]
	return []


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if not active:
			active = true
	if not active:
		return
	if event is InputEventScreenTouch:
		var vs := get_viewport_rect().size
		if event.pressed:
			# botões
			var rects := _button_rects()
			for bname in _visible_buttons():
				if rects[bname].grow(10).has_point(event.position):
					_press(bname, event.index)
					get_viewport().set_input_as_handled()
					return
			# joystick: metade esquerda da tela
			if main and main.state == S_PLAY and event.position.x < vs.x * 0.45 and joy_index == -1:
				joy_index = event.index
				joy_center = event.position
				joy_vec = Vector2.ZERO
				get_viewport().set_input_as_handled()
		else:
			if event.index == joy_index:
				joy_index = -1
				joy_vec = Vector2.ZERO
				_apply_joy()
			if held.has(event.index):
				_release(held[event.index])
				held.erase(event.index)
	elif event is InputEventScreenDrag and event.index == joy_index:
		var d: Vector2 = event.position - joy_center
		if d.length() > JOY_RADIUS:
			joy_center += d - d.normalized() * JOY_RADIUS   # o joystick acompanha o dedo
			d = event.position - joy_center
		joy_vec = d / JOY_RADIUS
		_apply_joy()
		get_viewport().set_input_as_handled()


func _press(bname: String, index: int) -> void:
	var b: Array = BUTTONS[bname]
	if b[1] == "hold":
		Input.action_press(b[0])
		held[index] = bname
	else:
		var ev := InputEventAction.new()
		ev.action = b[0]
		ev.pressed = true
		Input.parse_input_event(ev)
		var up := InputEventAction.new()
		up.action = b[0]
		up.pressed = false
		Input.parse_input_event(up)


func _release(bname: String) -> void:
	var b: Array = BUTTONS[bname]
	if b[1] == "hold":
		Input.action_release(b[0])


func _apply_joy() -> void:
	var v := joy_vec
	_axis("move_right", maxf(v.x, 0.0))
	_axis("move_left", maxf(-v.x, 0.0))
	_axis("move_down", maxf(v.y, 0.0))
	_axis("move_up", maxf(-v.y, 0.0))


func _axis(action: String, strength: float) -> void:
	if strength > 0.15:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _process(_delta: float) -> void:
	if active:
		# se o jogo saiu do modo PLAY, solta tudo
		if main and main.state != S_PLAY and joy_index != -1:
			joy_index = -1
			joy_vec = Vector2.ZERO
			_apply_joy()
		queue_redraw()


func _draw() -> void:
	if not active or main == null:
		return
	var vis := _visible_buttons()
	if vis.is_empty():
		return
	var vs := get_viewport_rect().size
	# joystick
	if main.state == S_PLAY:
		var c := joy_center if joy_index != -1 else Vector2(150, vs.y - 170)
		draw_circle(c, JOY_RADIUS, Color(1, 1, 1, 0.12))
		draw_arc(c, JOY_RADIUS, 0, TAU, 40, Color(1, 1, 1, 0.45), 3.0)
		draw_circle(c + joy_vec * JOY_RADIUS, 40, Color(1, 1, 1, 0.35))
		draw_arc(c + joy_vec * JOY_RADIUS, 40, 0, TAU, 30, Color(1, 1, 1, 0.7), 3.0)
	var rects := _button_rects()
	var pressed_names := held.values()
	for bname in vis:
		var r: Rect2 = rects[bname]
		var b: Array = BUTTONS[bname]
		var col: Color = b[3]
		var down: bool = bname in pressed_names
		var fill := Color(col.r, col.g, col.b, 0.55 if down else 0.25)
		var edge := Color(col.r, col.g, col.b, 0.9)
		if is_equal_approx(r.size.x, r.size.y):
			draw_circle(r.get_center(), r.size.x / 2.0, fill)
			draw_arc(r.get_center(), r.size.x / 2.0, 0, TAU, 40, edge, 3.0, true)
		else:
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(int(r.size.y / 2.0))
			sb.bg_color = fill
			sb.border_color = edge
			sb.set_border_width_all(3)
			draw_style_box(sb, r)
		# letra que cabe no botão
		var fs := 22
		while fs > 12 and font.get_string_size(b[2], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 16:
			fs -= 1
		draw_string_outline(font, Vector2(r.position.x, r.get_center().y + fs * 0.35), b[2], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(r.position.x, r.get_center().y + fs * 0.35), b[2], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, Color.WHITE)
