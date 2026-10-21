extends RefCounted
## Desenho procedural dos tubarões (sem arquivos de imagem), estilo cartoon.
## Coordenadas em unidades do comprimento (x: -0.5 cauda .. 0.5 focinho) e altura (y) do corpo.
## O corpo dobra suavemente enquanto nada (onda que vai do meio até a cauda).
## Sempre chamar dentro do _draw() do CanvasItem "ci".

static var _t := 0.0
static var _swim := 1.0


## deslocamento vertical da "onda" de natação num ponto x do corpo
static func _bend(x: float) -> float:
	var k := clampf((0.2 - x) / 0.85, 0.0, 1.0)
	return sin(_t * 6.0 + x * 5.0) * 0.16 * k * k * _swim


static func _pt(o: Vector2, L: float, H: float, dir: float, x: float, y: float) -> Vector2:
	return o + Vector2(x * L * dir, (y + _bend(x)) * H)


static func _pts(o: Vector2, L: float, H: float, dir: float, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_pt(o, L, H, dir, p[0], p[1]))
	return out


static func _poly(ci: CanvasItem, o: Vector2, L: float, H: float, dir: float, pts: Array, col: Color) -> PackedVector2Array:
	var out := _pts(o, L, H, dir, pts)
	ci.draw_colored_polygon(out, col)
	return out


static func _outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, width: float) -> void:
	var ol := pts.duplicate()
	ol.append(pts[0])
	ci.draw_polyline(ol, col, width, true)


## Barbatana com contorno cartoon
static func _fin(ci: CanvasItem, o: Vector2, L: float, H: float, dir: float, pts: Array, col: Color, line: Color, lw: float) -> void:
	var p := _poly(ci, o, L, H, dir, pts, col)
	_outline(ci, p, line, lw)


## espessura do corpo ao longo do comprimento (u: 0 = base da cauda, 1 = focinho)
static func _thick(u: float) -> float:
	return sin(PI * pow(clampf(u, 0.0, 1.0), 1.1)) + 0.1 * (1.0 - u)


static func draw(ci: CanvasItem, o: Vector2, L: float, H: float, dir: float, pattern: String,
		body: Color, belly: Color, t: float, silhouette := false) -> void:
	_t = t
	_swim = 0.0 if silhouette else 1.0
	var col := body
	var bcol := belly
	var line := body.darkened(0.62)
	var top := body.darkened(0.28)
	if silhouette:
		col = Color(0.06, 0.08, 0.13)
		bcol = col
		line = col
		top = col
	var lw := maxf(1.6, H * 0.045)
	var w := sin(t * 6.0 - 1.2) * 0.12 * _swim
	var tail_len := 0.66
	if pattern == "thresher":
		tail_len = 1.15
	elif pattern == "spots":
		tail_len = 0.88
	elif pattern == "frilled":
		tail_len = 0.56

	# --- barbatanas de trás (ficam atrás do corpo) ---
	_fin(ci, o, L, H, dir, [[-0.40, 0.0], [-0.52, 0.0], [-0.64, 0.54 + w], [-0.56, 0.46 + w]], col.darkened(0.08), line, lw)
	_fin(ci, o, L, H, dir, [[-0.38, -0.06], [-tail_len, -0.92 + w], [-0.52, 0.04]], col, line, lw)
	_fin(ci, o, L, H, dir, [[0.16, 0.22], [0.02, 0.62], [-0.04, 0.88 + w * 0.5], [0.0, 0.62], [0.0, 0.25]], col.darkened(0.12), line, lw)
	var dx := -0.12 if pattern == "nurse" else 0.0
	_fin(ci, o, L, H, dir, [[0.10 + dx, -0.40], [0.0 + dx, -0.78], [-0.09 + dx, -1.02], [-0.11 + dx, -0.7], [-0.2 + dx, -0.32]], col, line, lw)
	_fin(ci, o, L, H, dir, [[-0.29, -0.2], [-0.35, -0.42], [-0.40, -0.13]], col, line, lw * 0.8)
	_fin(ci, o, L, H, dir, [[-0.27, 0.18], [-0.33, 0.36], [-0.37, 0.13]], col.darkened(0.12), line, lw * 0.8)

	# --- corpo suave com sombreado (dorso mais escuro, barriga clara) ---
	var n := 22
	var up := PackedVector2Array()
	var down := PackedVector2Array()
	for i in range(n + 1):
		var u := float(i) / n
		var x := -0.45 + u * 0.95
		var th := _thick(u)
		up.append(_pt(o, L, H, dir, x, -0.48 * th))
		down.append(_pt(o, L, H, dir, x, 0.38 * th))
	var outline_pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in range(up.size()):
		outline_pts.append(up[i])
		cols.append(top)
	for i in range(down.size() - 1, -1, -1):
		outline_pts.append(down[i])
		cols.append(col)
	if silhouette:
		ci.draw_colored_polygon(outline_pts, col)
		return
	ci.draw_polygon(outline_pts, cols)
	# faixa do meio na cor principal (suaviza o degradê)
	var mid := PackedVector2Array()
	var midc := PackedColorArray()
	for i in range(n + 1):
		var u := float(i) / n
		var x := -0.45 + u * 0.95
		var th := _thick(u)
		mid.append(_pt(o, L, H, dir, x, -0.2 * th))
		midc.append(col)
	for i in range(n, -1, -1):
		var u := float(i) / n
		var x := -0.45 + u * 0.95
		var th := _thick(u)
		mid.append(_pt(o, L, H, dir, x, 0.12 * th))
		midc.append(col)
	ci.draw_polygon(mid, midc)
	# barriga clara
	var bel := PackedVector2Array()
	for i in range(2, n):
		var u := float(i) / n
		var x := -0.45 + u * 0.95
		bel.append(_pt(o, L, H, dir, x, 0.38 * _thick(u) - 0.01))
	for i in range(n - 1, 1, -1):
		var u := float(i) / n
		var x := -0.45 + u * 0.95
		bel.append(_pt(o, L, H, dir, x, 0.13 * _thick(u) + 0.02 * sin(u * 9.0)))
	ci.draw_colored_polygon(bel, bcol)
	# brilho no dorso (reflexo cartoon)
	var shine := PackedVector2Array()
	for i in range(8, 18):
		var u := float(i) / n
		shine.append(_pt(o, L, H, dir, -0.45 + u * 0.95, -0.36 * _thick(u)))
	ci.draw_polyline(shine, Color(1, 1, 1, 0.35), maxf(1.5, H * 0.05), true)
	_outline(ci, outline_pts, line, lw)

	# --- detalhes de cada espécie ---
	match pattern:
		"blacktip", "whitetip":
			var tip := Color(0.08, 0.08, 0.1) if pattern == "blacktip" else Color(0.97, 0.97, 0.97)
			_poly(ci, o, L, H, dir, [[-0.06, -0.86], [-0.09, -1.0], [-0.11, -0.84]], tip)
			_poly(ci, o, L, H, dir, [[-tail_len + 0.06, -0.78 + w], [-tail_len, -0.92 + w], [-tail_len + 0.09, -0.74 + w]], tip)
			_poly(ci, o, L, H, dir, [[-0.01, 0.76 + w * 0.5], [-0.04, 0.88 + w * 0.5], [0.0, 0.74 + w * 0.5]], tip)
		"spots":
			for i in range(9):
				var p := _pt(o, L, H, dir, 0.32 - i * 0.09, -0.24 + (i % 3) * 0.12)
				ci.draw_circle(p, H * 0.065, line)
		"tiger":
			for i in range(8):
				var x := 0.22 - i * 0.075
				ci.draw_line(_pt(o, L, H, dir, x, -0.40 + i * 0.03), _pt(o, L, H, dir, x - 0.03, -0.08), line, H * 0.055)
		"whale":
			for i in range(10):
				for j in range(3):
					var p := _pt(o, L, H, dir, 0.34 - i * 0.075, -0.36 + j * 0.12)
					ci.draw_circle(p, H * 0.032, Color(0.97, 0.97, 1.0, 0.95))
			for j in range(3):
				ci.draw_line(_pt(o, L, H, dir, 0.3, -0.33 + j * 0.12), _pt(o, L, H, dir, -0.35, -0.2 + j * 0.08), Color(0.9, 0.95, 1.0, 0.35), H * 0.012)
			ci.draw_line(_pt(o, L, H, dir, 0.5, 0.04), _pt(o, L, H, dir, 0.34, 0.1), line, H * 0.04)
		"hammer":
			var hp := _poly(ci, o, L, H, dir, [[0.38, -0.6], [0.47, -0.66], [0.53, -0.6], [0.55, 0.28], [0.48, 0.34], [0.38, 0.3]], col)
			_outline(ci, hp, line, lw)
			for ey in [-0.56, 0.26]:
				var ep := _pt(o, L, H, dir, 0.49, ey)
				ci.draw_circle(ep, H * 0.08, Color.WHITE)
				ci.draw_circle(ep + Vector2(H * 0.02 * dir, 0), H * 0.045, Color(0.05, 0.05, 0.08))
		"goblin":
			var gp := _poly(ci, o, L, H, dir, [[0.4, -0.22], [0.82, -0.17], [0.84, -0.09], [0.42, 0.1]], col.lightened(0.12))
			_outline(ci, gp, line, lw)
			for i in range(5):
				var tp := _pt(o, L, H, dir, 0.44 - i * 0.03, 0.2)
				ci.draw_colored_polygon(PackedVector2Array([tp, tp + Vector2(H * 0.03 * dir, 0), tp + Vector2(H * 0.015 * dir, H * 0.08)]), Color.WHITE)
		"frilled":
			for i in range(6):
				var x := 0.31 - i * 0.025
				ci.draw_line(_pt(o, L, H, dir, x, -0.3), _pt(o, L, H, dir, x, 0.3), Color(0.85, 0.35, 0.35), maxf(1.5, H * 0.06))
		"lantern":
			for i in range(7):
				var gp := _pt(o, L, H, dir, 0.32 - i * 0.11, 0.24)
				ci.draw_circle(gp, H * 0.16, Color(0.4, 1.0, 1.0, 0.25))
				ci.draw_circle(gp, H * 0.08, Color(0.7, 1.0, 1.0))
		"white":
			# linha de contraste entre o dorso cinza e a barriga branca
			ci.draw_polyline(_pts(o, L, H, dir, [[0.44, 0.06], [0.3, 0.02], [0.18, 0.12], [0.0, 0.05], [-0.15, 0.12], [-0.38, 0.04]]), line, maxf(1.5, H * 0.03), true)
			for i in range(6):
				var tp := _pt(o, L, H, dir, 0.44 - i * 0.03, 0.17 + i * 0.005)
				ci.draw_colored_polygon(PackedVector2Array([tp, tp + Vector2(H * 0.04 * dir, 0), tp + Vector2(H * 0.02 * dir, H * 0.07)]), Color.WHITE)
		"nurse":
			ci.draw_line(_pt(o, L, H, dir, 0.47, 0.05), _pt(o, L, H, dir, 0.52, 0.28), line, maxf(2.0, H * 0.05))
		"mako":
			ci.draw_polyline(_pts(o, L, H, dir, [[0.45, 0.03], [0.2, 0.06], [-0.1, 0.03], [-0.4, 0.01]]), Color(0.75, 0.85, 1.0, 0.6), maxf(1.5, H * 0.03), true)
		"mega":
			var scar := Color(0.88, 0.88, 0.92)
			ci.draw_line(_pt(o, L, H, dir, 0.1, -0.35), _pt(o, L, H, dir, -0.05, -0.15), scar, H * 0.02)
			ci.draw_line(_pt(o, L, H, dir, -0.1, -0.3), _pt(o, L, H, dir, -0.2, -0.05), scar, H * 0.02)
			ci.draw_line(_pt(o, L, H, dir, 0.25, -0.38), _pt(o, L, H, dir, 0.18, -0.2), scar, H * 0.02)
			ci.draw_line(_pt(o, L, H, dir, -0.02, -0.4), _pt(o, L, H, dir, 0.05, -0.22), scar, H * 0.015)
			for i in range(9):
				var tp := _pt(o, L, H, dir, 0.45 - i * 0.025, 0.16 + i * 0.006)
				ci.draw_colored_polygon(PackedVector2Array([tp, tp + Vector2(H * 0.03 * dir, 0), tp + Vector2(H * 0.015 * dir, H * 0.065)]), Color.WHITE)

	# guelras
	for i in range(3):
		var gx := 0.22 - i * 0.035
		ci.draw_line(_pt(o, L, H, dir, gx, -0.14), _pt(o, L, H, dir, gx - 0.012, 0.12), line, maxf(1.0, H * 0.028))
	# boca (um sorrisinho discreto, menos no Megalodon)
	if pattern != "mega" and pattern != "whale":
		ci.draw_polyline(_pts(o, L, H, dir, [[0.46, 0.12], [0.41, 0.17], [0.36, 0.16]]), line, maxf(1.2, H * 0.03), true)
	# olho cartoon
	if pattern != "hammer":
		var ep := _pt(o, L, H, dir, 0.35, -0.13)
		if pattern == "mega":
			var er := H * 0.06
			ci.draw_circle(ep, er, Color(0.02, 0.02, 0.04))
			ci.draw_circle(ep + Vector2(-er * 0.3 * dir, -er * 0.3), er * 0.3, Color.WHITE)
		else:
			var big := pattern in ["mako", "lantern", "goblin", "white", "cookie"]
			var er := H * (0.13 if big else 0.105)
			ci.draw_circle(ep, er, Color.WHITE)
			ci.draw_arc(ep, er, 0, TAU, 20, line, maxf(1.0, H * 0.025), true)
			var iris := Color(0.3, 1.0, 0.7) if pattern == "lantern" else Color(0.06, 0.06, 0.1)
			var pp := ep + Vector2(er * 0.25 * dir, er * 0.05)
			ci.draw_circle(pp, er * 0.58, iris)
			ci.draw_circle(pp + Vector2(-er * 0.2 * dir, -er * 0.22), er * 0.22, Color.WHITE)


## Plesiossauro do santuário (dinossauro marinho de pescoço comprido)
static func draw_plesio(ci: CanvasItem, o: Vector2, s: float, dir: float, t: float, col: Color) -> void:
	var f := sin(t * 2.5) * 0.25
	var belly := col.lightened(0.35)
	var line := col.darkened(0.55)
	var lw := maxf(2.0, s * 0.02)
	# nadadeiras
	for k in [-1.0, 1.0]:
		var base := o + Vector2(0.25 * s * dir * k, 0.15 * s)
		var tip := base + Vector2(-0.35 * s * dir, (0.45 + f * k) * s)
		var fin := PackedVector2Array([base + Vector2(-0.1 * s * dir, 0), tip, base + Vector2(0.1 * s * dir, 0)])
		ci.draw_colored_polygon(fin, col.darkened(0.2))
		var fo := fin.duplicate()
		fo.append(fin[0])
		ci.draw_polyline(fo, line, lw, true)
	# cauda
	var tail := PackedVector2Array([o + Vector2(-0.4 * s * dir, -0.1 * s), o + Vector2(-1.0 * s * dir, (0.05 + f * 0.3) * s), o + Vector2(-0.4 * s * dir, 0.12 * s)])
	ci.draw_colored_polygon(tail, col)
	# pescoço comprido em curva (atrás do corpo)
	var neck := PackedVector2Array()
	for i in range(14):
		var k := i / 13.0
		neck.append(o + Vector2((0.3 + k * 0.75) * s * dir, (-0.05 - sin(k * 2.2) * 0.55 + sin(t * 1.5 + k * 2.0) * 0.05) * s))
	ci.draw_polyline(neck, line, 0.12 * s + lw * 2.0, true)
	ci.draw_polyline(neck, col, 0.12 * s, true)
	# corpo com degradê
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(o + Vector2(cos(a) * 0.5 * s, sin(a) * 0.22 * s))
		cols.append(col.darkened(0.2) if sin(a) < 0 else col.lightened(0.05))
	ci.draw_polygon(pts, cols)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-0.38 * s, 0.09 * s), o + Vector2(0.38 * s, 0.09 * s), o + Vector2(0, 0.21 * s)]), belly)
	var po := pts.duplicate()
	po.append(pts[0])
	ci.draw_polyline(po, line, lw, true)
	# manchinhas
	for i in range(5):
		ci.draw_circle(o + Vector2((-0.25 + i * 0.12) * s, (-0.1 + (i % 2) * 0.05) * s), 0.025 * s, col.lightened(0.25))
	var head := neck[neck.size() - 1]
	ci.draw_circle(head, 0.1 * s + lw, line)
	ci.draw_circle(head, 0.1 * s, col)
	var ep := head + Vector2(0.03 * s * dir, -0.03 * s)
	ci.draw_circle(ep, 0.04 * s, Color.WHITE)
	ci.draw_circle(ep + Vector2(0.01 * s * dir, 0), 0.022 * s, Color.BLACK)
	ci.draw_arc(head + Vector2(0.05 * s * dir, 0.03 * s), 0.04 * s, 0.2, 1.4, 6, line, lw * 0.6)


## Corais e companhia (usado no cenário e no menu)
static func draw_coral(ci: CanvasItem, p: Vector2, kind: int, col: Color, sc: float) -> void:
	var dark := col.darkened(0.45)
	match kind:
		0:  # coral-galho
			for k in range(5):
				var a := -PI / 2 + (k - 2) * 0.38
				var tip := p + Vector2(cos(a), sin(a)) * 46 * sc
				ci.draw_line(p, tip, dark, 9 * sc)
				ci.draw_line(p, tip, col, 6 * sc)
				var tw := tip + Vector2(cos(a - 0.6), sin(a - 0.6)) * 16 * sc
				ci.draw_line(tip, tw, col, 4 * sc)
				ci.draw_circle(tip, 4 * sc, col.lightened(0.35))
		1:  # coral-cérebro
			ci.draw_circle(p, 26 * sc, dark)
			ci.draw_circle(p, 23 * sc, col.darkened(0.1))
			for k in range(3):
				ci.draw_arc(p + Vector2(0, 4 * sc), (8 + k * 6) * sc, PI * 1.05, PI * 1.95, 10, col.lightened(0.35), 2.5)
		2:  # anêmona
			for k in range(9):
				var a := -PI + k * PI / 8.0
				var tip := p + Vector2(cos(a), sin(a) - 0.45) * 30 * sc
				ci.draw_line(p, tip, dark, 6 * sc)
				ci.draw_line(p, tip, col, 4 * sc)
				ci.draw_circle(tip, 3.5 * sc, col.lightened(0.4))
			ci.draw_circle(p, 8 * sc, col.darkened(0.2))
		3:  # leque-do-mar (gorgônia)
			var fan_col := Color.from_hsv(fposmod(col.h + 0.05, 1.0), 0.7, 0.95)
			for k in range(9):
				var a := -PI / 2 + (k - 4) * 0.17
				ci.draw_line(p, p + Vector2(cos(a), sin(a)) * 58 * sc, fan_col, 2.5)
			ci.draw_arc(p, 58 * sc, -PI / 2 - 0.72, -PI / 2 + 0.72, 12, fan_col, 3)
			ci.draw_arc(p, 38 * sc, -PI / 2 - 0.72, -PI / 2 + 0.72, 12, fan_col, 2)
		4:  # esponjas-tubo
			for k in range(3):
				var h := (34 + k * 12) * sc
				var bx := p + Vector2((k - 1) * 14 * sc, 0)
				ci.draw_rect(Rect2(bx + Vector2(-7 * sc, -h), Vector2(14 * sc, h)), col.darkened(0.15))
				ci.draw_rect(Rect2(bx + Vector2(-7 * sc, -h), Vector2(14 * sc, h)), dark, false, 2)
				ci.draw_circle(bx + Vector2(0, -h), 7 * sc, dark)
				ci.draw_circle(bx + Vector2(0, -h), 4 * sc, Color(0.1, 0.05, 0.1))
		5:  # estrela-do-mar
			var star := PackedVector2Array()
			for k in range(10):
				var a := -PI / 2 + k * PI / 5.0
				var rr := (16.0 if k % 2 == 0 else 7.0) * sc
				star.append(p + Vector2(cos(a), sin(a)) * rr + Vector2(0, -8 * sc))
			ci.draw_colored_polygon(star, Color(1.0, 0.55, 0.25))
			var so := star.duplicate()
			so.append(star[0])
			ci.draw_polyline(so, Color(0.6, 0.25, 0.1), 2)
		6:  # vermes-tubo (zonas profundas)
			for k in range(4):
				var bx := p + Vector2((k - 1.5) * 9 * sc, 0)
				var h := (30 + (k % 2) * 16) * sc
				ci.draw_line(bx, bx + Vector2(0, -h), Color(0.92, 0.92, 0.88), 6 * sc)
				ci.draw_circle(bx + Vector2(0, -h - 5 * sc), 7 * sc, Color(1.0, 0.25, 0.3))
		7:  # lírio-do-mar
			ci.draw_line(p, p + Vector2(0, -46 * sc), Color(0.85, 0.75, 0.95), 3)
			var c := p + Vector2(0, -46 * sc)
			for k in range(7):
				var a := -PI + k * PI / 6.0
				ci.draw_line(c, c + Vector2(cos(a), sin(a) * 0.8 - 0.3) * 22 * sc, Color(0.75, 0.55, 1.0), 3)
