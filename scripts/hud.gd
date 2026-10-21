extends Control
## Interface na tela (HUD): profundidade, contadores, alerta, mensagens e fichas.

const Data = preload("res://scripts/data.gd")
const Art = preload("res://scripts/shark_art.gd")

var main
var t := 0.0
var messages: Array = []   # [texto, tempo restante, cor]
var card_id := -1
var card_time := 0.0
var flash := 0.0
var flash_col := Color.WHITE
var font: Font
var steady := false   # cena final: não acelerar as falas


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func say(text: String, seconds := 4.5, col := Color.WHITE, keep_all := false) -> void:
	# evita repetir a mesma mensagem em seguida
	if messages.size() > 0 and messages[messages.size() - 1][0] == text:
		return
	if keep_all:
		steady = true
	messages.append([text, seconds, col])
	# fila curta: crianças leem melhor poucas mensagens de cada vez
	while messages.size() > 3 and not keep_all:
		messages.remove_at(1)


func show_card(id: int) -> void:
	card_id = id
	card_time = 7.0


func do_flash(col: Color) -> void:
	flash = 1.0
	flash_col = col


func clear() -> void:
	messages.clear()
	steady = false
	card_id = -1
	flash = 0.0


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 1.5)
	if messages.size() > 0:
		messages[0][1] -= delta * (1.0 if messages.size() == 1 or steady else 1.6)
		if messages[0][1] <= 0.0:
			messages.pop_front()
	if card_id >= 0:
		card_time -= delta
		if card_time <= 0.0:
			card_id = -1
	queue_redraw()


func _text(pos: Vector2, s: String, size := 20, col := Color.WHITE, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string_outline(font, pos, s, align, width, size, 6, Color(0, 0, 0, 0.85))
	draw_string(font, pos, s, align, width, size, col)


func _panel(r: Rect2, col := Color(0.02, 0.08, 0.16, 0.72)) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(14)
	sb.border_color = Color(0.4, 0.85, 1.0, 0.6)
	sb.set_border_width_all(2)
	draw_style_box(sb, r)


func _draw() -> void:
	var vs := get_viewport_rect().size
	if main == null or not main.playing():
		_draw_flash(vs)
		return
	var p: Vector2 = main.player.global_position
	var z := Data.zone_of(p.y)
	var zd: Dictionary = Data.ZONES[z]
	_draw_vignette(vs, p.y)

	# painel esquerdo
	_panel(Rect2(14, 14, 340, 206))
	_text(Vector2(30, 46), zd["name"], 24, Color(0.6, 0.95, 1.0))
	_text(Vector2(30, 76), "Profundidade: %d m" % Data.depth_meters(p.y), 20)
	_text(Vector2(30, 104), "Espécies catalogadas: %d / %d" % [main.catalog.size(), Data.SPECIES.size()], 20, Color(0.5, 1.0, 0.6))
	var zc := mini(z, 3)
	var goal: int = Data.CHIP_GOAL[zc]
	var cdone: int = main.chips[zc]
	_text(Vector2(30, 132), "Chips de proteção: %d / %d" % [mini(cdone, goal), goal], 20, Color(0.4, 1.0, 0.85) if cdone >= goal else Color(0.75, 1.0, 0.9))
	if z < 3:
		var pc: int = main.parts[z]
		_text(Vector2(30, 160), "Peças da Corporação: %d / 3" % pc, 20, Color(0.6, 0.85, 1.0) if pc >= 3 else Color(0.85, 0.9, 1.0))
	else:
		_text(Vector2(30, 160), "Gravações do pai: %d / %d" % [main.logs_found, Data.LOGS.size()], 20, Color(1.0, 0.8, 0.4))
	_text(Vector2(30, 188), "Tubarões salvos: %d / %d" % [main.saved, Data.NETS.size()], 20, Color(1.0, 0.85, 0.4))

	# painel direito: alerta e EMP
	var level: int = main.alert_level()
	var atxt := "TRANQUILO"
	var acol := Color(0.4, 1.0, 0.5)
	if level == 1:
		atxt = "SUSPEITA  ?"
		acol = Color(1.0, 0.85, 0.2)
	elif level == 2:
		atxt = "ALERTA  !  Fuja ou se esconda!"
		acol = Color(1.0, 0.3, 0.3)
	var rw := 360.0
	_panel(Rect2(vs.x - rw - 14, 14, rw, 104))
	_text(Vector2(vs.x - rw, 46), atxt, 22, acol)
	if main.player_hidden:
		_text(Vector2(vs.x - rw, 74), "Escondido nas algas", 20, Color(0.5, 1.0, 0.5))
	var cd: float = main.emp_cooldown
	var emp_ok := cd <= 0.0
	_text(Vector2(vs.x - rw, 104), ("Pulso EMP" if (main.touch and main.touch.active) else "Q  Pulso EMP"), 20, Color(0.5, 0.85, 1.0) if emp_ok else Color(0.6, 0.6, 0.7))
	draw_rect(Rect2(vs.x - rw + 150, 90, 180, 14), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(vs.x - rw + 150, 90, 180 * (1.0 - cd / main.emp_max), 14), Color(0.4, 0.8, 1.0))

	# dica contextual
	var hint: String = main.context_hint
	if hint != "":
		var hw := 620.0
		if main.touch and main.touch.active:
			hw = 560.0
		hint = _touchify(hint)
		_panel(Rect2(vs.x / 2 - hw / 2, vs.y - 190, hw, 46), Color(0.05, 0.25, 0.15, 0.8))
		_text(Vector2(vs.x / 2 - hw / 2, vs.y - 158), hint, 22, Color(0.7, 1.0, 0.75), hw, HORIZONTAL_ALIGNMENT_CENTER)

	# mensagem atual
	if messages.size() > 0:
		var m: Array = messages[0]
		var mw := minf(vs.x - 80, 980.0)
		if main.touch and main.touch.active:
			mw = minf(vs.x - 640, 640.0)  # deixa espaço para o joystick e os botões
		_panel(Rect2(vs.x / 2 - mw / 2, vs.y - 130, mw, 100))
		draw_multiline_string(font, Vector2(vs.x / 2 - mw / 2 + 20, vs.y - 96), _touchify(m[0]), HORIZONTAL_ALIGNMENT_CENTER, mw - 40, 22, 3, m[2])

	# legenda de controles (só com teclado)
	if not (main.touch and main.touch.active):
		_text(Vector2(18, vs.y - 14), "Setas/WASD: mover   ESPAÇO: catalogar   F: chip   E: soltar   Q: EMP   C: catálogo   ESC: pausa", 16, Color(1, 1, 1, 0.7))

	# ficha de nova espécie
	if card_id >= 0:
		_draw_card(vs)
	_draw_flash(vs)


## No celular/tablet troca os nomes das teclas pelos nomes dos botões da tela
func _touchify(text: String) -> String:
	if not (main.touch and main.touch.active):
		return text
	var pairs := [["Segure ESPAÇO", "Segure CATALOGAR"], ["(ESPAÇO)", "(botão CATALOGAR)"], ["segure ESPAÇO", "segure CATALOGAR"], ["segure ESPAÇO", "segure CATALOGAR"], ["(tecla F)", "(botão CHIP)"],
		["chips (F)", "chips (botão CHIP)"], ["Segure E ", "Segure SOLTAR "], ["(Q)", "(botão EMP)"], ["Aperte Q", "Toque em EMP"]]
	for p in pairs:
		text = text.replace(p[0], p[1])
	return text


## escurece levemente as bordas da tela (mais forte nas profundezas)
func _draw_vignette(vs: Vector2, depth_y: float) -> void:
	var a := 0.18 + clampf(depth_y / 4000.0, 0.0, 1.0) * 0.32
	if depth_y > 4000.0:
		a = 0.15
	var edge := Color(0.0, 0.02, 0.06, a)
	var clear := Color(0.0, 0.02, 0.06, 0.0)
	var m := minf(vs.x, vs.y) * 0.22
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0), Vector2(vs.x - m, m), Vector2(m, m)]), PackedColorArray([edge, edge, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, vs.y), Vector2(m, vs.y - m), Vector2(vs.x - m, vs.y - m), vs]), PackedColorArray([edge, clear, clear, edge]))
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(m, m), Vector2(m, vs.y - m), Vector2(0, vs.y)]), PackedColorArray([edge, clear, clear, edge]))
	draw_polygon(PackedVector2Array([Vector2(vs.x, 0), Vector2(vs.x, vs.y), Vector2(vs.x - m, vs.y - m), Vector2(vs.x - m, m)]), PackedColorArray([edge, edge, clear, clear]))


func _draw_card(vs: Vector2) -> void:
	var sp: Dictionary = Data.SPECIES[card_id]
	var w := 520.0
	var r := Rect2(vs.x / 2 - w / 2, 14, w, 230)
	var a := clampf(card_time * 2.0, 0.0, 1.0)
	_panel(r, Color(0.03, 0.12, 0.22, 0.92 * a))
	_text(r.position + Vector2(0, 34), "NOVA ESPÉCIE CATALOGADA!", 20, Color(0.4, 1.0, 0.6), w, HORIZONTAL_ALIGNMENT_CENTER)
	var L: float = sp["len"]
	var H: float = sp["h"]
	var sc := minf(170.0 / L, 60.0 / H)
	draw_set_transform(r.position + Vector2(115, 125), 0, Vector2(sc, sc))
	Art.draw(self, Vector2.ZERO, L, H, 1.0, sp["pattern"], sp["body"], sp["belly"], t)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	_text(r.position + Vector2(225, 76), sp["name"], 23, Color(1.0, 0.95, 0.6))
	draw_multiline_string(font, r.position + Vector2(225, 106), sp["fact"], HORIZONTAL_ALIGNMENT_LEFT, w - 240, 17, 6, Color(0.92, 0.96, 1.0))


func _draw_flash(vs: Vector2) -> void:
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(flash_col.r, flash_col.g, flash_col.b, flash * 0.5))
