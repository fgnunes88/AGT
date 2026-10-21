extends Control
## Catálogo de espécies (o painel de Arthur, ao lado dos esboços de Philip).

const Data = preload("res://scripts/data.gd")
const Art = preload("res://scripts/shark_art.gd")

signal closed

const COLS := 5
var main
var sel := 0
var t := 0.0
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _process(delta: float) -> void:
	if visible:
		t += delta
		queue_redraw()


func _card_rect(i: int) -> Rect2:
	var vs := get_viewport_rect().size
	var cw := minf(220.0, (vs.x - 120) / COLS)
	var ch := 130.0
	var x0 := vs.x / 2 - (cw * COLS + 12 * (COLS - 1)) / 2
	return Rect2(x0 + (i % COLS) * (cw + 12), 100 + (i / COLS) * (ch + 12), cw, ch)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var n := Data.SPECIES.size()
	if event.is_action_pressed("catalog") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		closed.emit()
	elif event.is_action_pressed("move_right"):
		sel = (sel + 1) % n
	elif event.is_action_pressed("move_left"):
		sel = (sel + n - 1) % n
	elif event.is_action_pressed("move_down"):
		sel = mini(sel + COLS, n - 1)
	elif event.is_action_pressed("move_up"):
		sel = maxi(sel - COLS, 0)
	elif event is InputEventMouseButton and event.pressed:
		if _close_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
			closed.emit()
			return
		for i in n:
			if _card_rect(i).has_point(event.position):
				sel = i


func _close_rect() -> Rect2:
	var vs := get_viewport_rect().size
	return Rect2(vs.x - 84, 20, 60, 60)


func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.06, 0.12, 0.94))
	# botão de fechar (para mouse e toque)
	var cr := _close_rect()
	var sbx := StyleBoxFlat.new()
	sbx.set_corner_radius_all(30)
	sbx.bg_color = Color(0.8, 0.25, 0.2, 0.9)
	draw_style_box(sbx, cr)
	draw_line(cr.position + Vector2(18, 18), cr.end - Vector2(18, 18), Color.WHITE, 5)
	draw_line(cr.position + Vector2(42, 18), cr.position + Vector2(18, 42), Color.WHITE, 5)
	draw_string_outline(font, Vector2(0, 60), "CATÁLOGO DE TUBARÕES DE ARTHUR BLAKE", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 32, 6, Color.BLACK)
	draw_string(font, Vector2(0, 60), "CATÁLOGO DE TUBARÕES DE ARTHUR BLAKE", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 32, Color(1.0, 0.85, 0.3))
	for i in Data.SPECIES.size():
		var sp: Dictionary = Data.SPECIES[i]
		var known: bool = main.catalog.has(i)
		var r := _card_rect(i)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(12)
		sb.bg_color = Color(0.92, 0.88, 0.75) if known else Color(0.12, 0.16, 0.24)  # papel de esboço
		sb.border_color = Color(1.0, 0.85, 0.3) if i == sel else Color(0.3, 0.5, 0.7)
		sb.set_border_width_all(4 if i == sel else 2)
		draw_style_box(sb, r)
		var L: float = sp["len"]
		var H: float = sp["h"]
		var sc := minf((r.size.x - 50) / (L * 1.5), 55.0 / (H * 1.8))
		draw_set_transform(r.position + Vector2(r.size.x / 2 + L * sc * 0.1, 58), 0, Vector2(sc, sc))
		Art.draw(self, Vector2.ZERO, L, H, 1.0, sp["pattern"], sp["body"], sp["belly"], t if known else 0.0, not known)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		var name_txt: String = sp["name"] if known else "???"
		draw_string(font, r.position + Vector2(6, r.size.y - 14), name_txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12, 15,
			Color(0.15, 0.12, 0.08) if known else Color(0.6, 0.7, 0.8))
	# detalhes da espécie escolhida
	var sp: Dictionary = Data.SPECIES[sel]
	var known_sel: bool = main.catalog.has(sel)
	var zone_name: String = Data.ZONES[sp["zone"]]["name"]
	var dy := _card_rect(Data.SPECIES.size() - 1).end.y + 30
	var box := Rect2(vs.x / 2 - 520, dy, 1040, 120)
	var sb2 := StyleBoxFlat.new()
	sb2.set_corner_radius_all(14)
	sb2.bg_color = Color(0.05, 0.15, 0.28)
	draw_style_box(sb2, box)
	if known_sel:
		var total := 0
		var prot := 0
		for sh in main.sharks_node.get_children():
			if sh.species_id == sel:
				total += 1
				if sh.chipped:
					prot += 1
		var extra := "" if sel == 13 else "   |   Protegidos com chip: %d de %d" % [prot, total]
		draw_string(font, box.position + Vector2(20, 36), "%s  -  vive em: %s%s" % [sp["name"], zone_name, extra], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.9, 0.5))
		draw_multiline_string(font, box.position + Vector2(20, 70), sp["fact"], HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 40, 20, 3, Color.WHITE)
	else:
		draw_string(font, box.position + Vector2(20, 36), "Espécie ainda não encontrada", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.7, 0.8, 0.9))
		draw_string(font, box.position + Vector2(20, 72), "Pista: procure na zona \"%s\"." % zone_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.8, 0.9, 1.0))
	draw_string(font, Vector2(0, vs.y - 20), "Setas: escolher     C ou ESC: fechar", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 18, Color(1, 1, 1, 0.7))
