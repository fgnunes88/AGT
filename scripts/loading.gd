extends Control
## Tela de carregamento: aparece depois de "Novo Jogo" enquanto o oceano é preparado
## (desenhos viram imagens prontas, efeitos sonoros são carregados e cada zona é
## mostrada uma vez para a placa de vídeo). O jogo só começa quando tudo estiver pronto.

const Art = preload("res://scripts/shark_art.gd")

const TIPS := [
	"Dica: chegue devagar! Movimentos rápidos assustam os tubarões.",
	"Dica: nas algas, os drones não conseguem te ver.",
	"Dica: o Pulso EMP desliga drones, barcos e boias por alguns segundos.",
	"Dica: você tem 3 chances. Cuidado com os drones e com a garra do barco!",
	"Dica: catalogue a espécie primeiro, depois proteja cada tubarão com um chip.",
]

var progress := 0.0      # 0..1 (valor real)
var shown_progress := 0.0  # valor animado na barra
var t := 0.0
var tip := 0
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func begin() -> void:
	progress = 0.0
	shown_progress = 0.0
	t = 0.0
	tip = randi() % TIPS.size()
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	shown_progress = move_toward(shown_progress, progress, delta * 1.5)
	if int(t / 4.0) != int((t - delta) / 4.0):
		tip = (tip + 1) % TIPS.size()
	queue_redraw()


func _text(pos: Vector2, s: String, size: int, col: Color, width: float) -> void:
	draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, width, size, 8, Color(0, 0, 0, 0.85))
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


func _draw() -> void:
	var vs := get_viewport_rect().size
	# fundo: degradê do mar
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0), vs, Vector2(0, vs.y)]),
		PackedColorArray([Color(0.05, 0.35, 0.6), Color(0.05, 0.35, 0.6), Color(0.01, 0.06, 0.16), Color(0.01, 0.06, 0.16)]))
	# bolhas subindo
	for i in 24:
		var bx := fposmod(i * 211.0 + sin(t + i) * 20.0, vs.x)
		var by := vs.y - fposmod(t * (40.0 + (i % 5) * 18.0) + i * 97.0, vs.y + 40.0)
		draw_circle(Vector2(bx, by), 3.0 + (i % 4), Color(1, 1, 1, 0.18))
	_text(Vector2(0, vs.y * 0.24), "ARTHUR,", 54, Color(1.0, 0.88, 0.35), vs.x)
	_text(Vector2(0, vs.y * 0.24 + 52), "O Guardião dos Tubarões", 34, Color(0.75, 0.95, 1.0), vs.x)

	# barra de progresso com um tubarão nadando por cima
	var bw := minf(vs.x - 160.0, 760.0)
	var bar := Rect2(vs.x / 2 - bw / 2, vs.y * 0.6, bw, 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.45)
	sb.set_corner_radius_all(15)
	sb.border_color = Color(0.4, 0.85, 1.0, 0.8)
	sb.set_border_width_all(3)
	draw_style_box(sb, bar)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.9, 1.0)
	fill.set_corner_radius_all(12)
	var fw := maxf(24.0, (bw - 8.0) * shown_progress)
	draw_style_box(fill, Rect2(bar.position + Vector2(4, 4), Vector2(fw, bar.size.y - 8)))
	var sx := bar.position.x + 4.0 + fw
	Art.draw(self, Vector2(sx, bar.position.y - 34 + sin(t * 3.0) * 4.0), 110, 38, 1.0, "blacktip",
		Color(0.58, 0.64, 0.70), Color(0.95, 0.95, 0.92), t * 1.5)
	_text(Vector2(0, bar.end.y + 44), "Preparando o oceano...  %d%%" % int(round(shown_progress * 100.0)), 28, Color.WHITE, vs.x)
	_text(Vector2(0, vs.y * 0.86), TIPS[tip], 24, Color(1.0, 0.92, 0.6), vs.x)
