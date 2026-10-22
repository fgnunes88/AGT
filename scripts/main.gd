extends Node2D
## Arthur, O Guardião dos Tubarões
## Controlador principal: monta o mundo, a interface e conduz a história
## (início no recife -> meio nas zonas profundas -> fim no santuário).

const Data = preload("res://scripts/data.gd")
const SharkScript = preload("res://scripts/shark.gd")
const DroneScript = preload("res://scripts/drone.gd")
const PlayerScript = preload("res://scripts/player.gd")
const NetScript = preload("res://scripts/net_trap.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const KelpScript = preload("res://scripts/kelp.gd")
const BgScript = preload("res://scripts/ocean_bg.gd")
const BgAnimScript = preload("res://scripts/bg_anim.gd")
const ParallaxScript = preload("res://scripts/parallax.gd")
const AmbientScript = preload("res://scripts/ambient.gd")
const FxScript = preload("res://scripts/fx.gd")
const BaseScript = preload("res://scripts/megabase.gd")
const MegaScript = preload("res://scripts/megalodon.gd")
const PlesioScript = preload("res://scripts/plesio.gd")
const HudScript = preload("res://scripts/hud.gd")
const TitleScript = preload("res://scripts/title.gd")
const CatalogScript = preload("res://scripts/catalog.gd")
const EndingScript = preload("res://scripts/ending.gd")
const MusicScript = preload("res://scripts/music.gd")
const TouchScript = preload("res://scripts/touch.gd")
const ArtScript = preload("res://scripts/shark_art.gd")
const CullScript = preload("res://scripts/cull.gd")
const BakerScript = preload("res://scripts/baker.gd")
const BoatScript = preload("res://scripts/boat.gd")
const DartScript = preload("res://scripts/dart.gd")
const BuoyScript = preload("res://scripts/sonar_buoy.gd")

# música de cada zona (nomes dos arquivos em res://music/)
const ZONE_MUSIC := ["recife", "mar_aberto", "penumbra", "fossa", "santuario"]

enum GameState { TITLE, PLAY, CATALOG, PAUSE, CUTSCENE, ENDING }

const SCAN_RANGE := 260.0
const NET_RANGE := 160.0
const EMP_RANGE := 380.0

var state := GameState.TITLE
var lite := false            # modo leve (navegador/celular): menos luzes e detalhes
var fps_timer := 0.0
var baker = null             # transforma desenhos complexos em imagens prontas (modo leve)
var light_tex: GradientTexture2D
var music: Node
var danger_hold := 0.0      # mantém a música de perigo uns segundos após o alerta

# --- nós do mundo ---
var world: Node2D
var player: Node2D
var camera: Camera2D
var fx: Node2D
var modulate_node: CanvasModulate
var sharks_node: Node2D
var drones: Array = []
var enemies: Array = []      # todos os inimigos: drones, barcos e boias-sonar
var nets: Array = []
var pickups: Array = []
var kelps: Array = []
var megabase: Node2D
var megalodon: Node2D

# --- interface ---
var ui: CanvasLayer
var hud: Control
var title: Control
var catalog_ui: Control
var ending_ui: Control
var pause_ui: Control
var touch: Control
var start_gate: Control

# --- progresso do jogador ---
var catalog := {}            # id da espécie -> true
var saved := 0
var parts := [0, 0, 0]
var chips := [0, 0, 0, 0]    # chips de proteção implantados por zona
var chip_cooldown := 0.0
var chip_aim = null          # para onde o braço aponta ao disparar
var chip_aim_t := 0.0
var unlocked := 0            # zona mais funda que o casco aguenta
var logs_found := 0
var visited := {}
var crack_open := false
var final_started := false
var ending_started := false

# --- estado do momento ---
var player_hidden := false
var scan_target = null
var scan_progress := 0.0
var emp_cooldown := 0.0
var emp_max := 6.0
var invuln := 0.0
var context_hint := ""
var shake_amount := 0.0
var throttle := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	lite = OS.has_feature("web") or OS.has_feature("mobile") or "--lite" in OS.get_cmdline_user_args()
	if lite:
		Engine.max_fps = 60
		ArtScript.segments = 14
		CullScript.lite = true
		baker = BakerScript.new()
		add_child(baker)
		# desenha sempre em 1280x720 e só amplia na tela (em tela cheia isso é bem mais leve)
		get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	randomize()
	_setup_input()
	_make_light_texture()
	music = MusicScript.new()
	add_child(music)
	_build_ui()
	_show_title()


# ------------------------------------------------------------------ entrada

func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"scan": [KEY_SPACE], "interact": [KEY_E], "emp": [KEY_Q], "chip": [KEY_F],
		"catalog": [KEY_C, KEY_TAB], "pause": [KEY_ESCAPE, KEY_P],
		"accept": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], "menu": [KEY_M],
		"toggle_music": [KEY_N],
	}
	var pads := {
		"scan": [JOY_BUTTON_A], "interact": [JOY_BUTTON_X], "emp": [JOY_BUTTON_B], "chip": [JOY_BUTTON_RIGHT_SHOULDER],
		"catalog": [JOY_BUTTON_Y], "pause": [JOY_BUTTON_START], "accept": [JOY_BUTTON_A],
		"move_left": [JOY_BUTTON_DPAD_LEFT], "move_right": [JOY_BUTTON_DPAD_RIGHT],
		"move_up": [JOY_BUTTON_DPAD_UP], "move_down": [JOY_BUTTON_DPAD_DOWN],
	}
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	for action in pads:
		for b in pads[action]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = b
			InputMap.action_add_event(action, ev)
	for action in axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axes[action][0]
		ev.axis_value = axes[action][1]
		InputMap.action_add_event(action, ev)


func _make_light_texture() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	light_tex = GradientTexture2D.new()
	light_tex.gradient = g
	light_tex.fill = GradientTexture2D.FILL_RADIAL
	light_tex.fill_from = Vector2(0.5, 0.5)
	light_tex.fill_to = Vector2(1.0, 0.5)
	light_tex.width = 256
	light_tex.height = 256


# ------------------------------------------------------------------ interface

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	hud = HudScript.new()
	hud.main = self
	ui.add_child(hud)
	catalog_ui = CatalogScript.new()
	catalog_ui.main = self
	catalog_ui.closed.connect(_close_catalog)
	ui.add_child(catalog_ui)
	pause_ui = _make_pause_ui()
	ui.add_child(pause_ui)
	ending_ui = EndingScript.new()
	ending_ui.finished.connect(_show_title)
	ui.add_child(ending_ui)
	title = TitleScript.new()
	title.music = music
	title.chosen.connect(_on_title_choice)
	ui.add_child(title)
	touch = TouchScript.new()
	touch.main = self
	ui.add_child(touch)
	# na web, os navegadores só liberam o som depois do primeiro toque/clique
	if OS.has_feature("web"):
		start_gate = _make_start_gate()
		ui.add_child(start_gate)


func _make_pause_ui() -> Control:
	var c := ColorRect.new()
	c.color = Color(0, 0, 0, 0.6)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.visible = false
	var l := Label.new()
	l.text = "PAUSA\n\nENTER, ESC ou toque na tela: continuar\nM: voltar ao menu principal\nN: ligar/desligar a música"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	c.add_child(l)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and state == GameState.PAUSE:
			_set_paused(false))
	return c


func _make_start_gate() -> Control:
	var c := ColorRect.new()
	c.color = Color(0.02, 0.12, 0.25, 0.96)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	var l := Label.new()
	l.text = "ARTHUR, O Guardião dos Tubarões\n\nToque na tela ou clique para começar"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.add_theme_font_size_override("font_size", 40)
	l.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 10)
	c.add_child(l)
	c.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_dismiss_gate())
	return c


func _dismiss_gate() -> void:
	if start_gate == null:
		return
	start_gate.queue_free()
	start_gate = null
	title.shown = 0.0
	music.current = ""
	music.play("tema")


func _show_title() -> void:
	get_tree().paused = false
	_clear_world()
	hud.clear()
	ending_ui.visible = false
	pause_ui.visible = false
	catalog_ui.visible = false
	title.visible = true
	state = GameState.TITLE
	music.play("tema")


func _on_title_choice(option: String) -> void:
	if option == "Sair":
		get_tree().quit()
	elif option == "Novo Jogo":
		title.visible = false
		_start_game()


func playing() -> bool:
	return state == GameState.PLAY or state == GameState.CUTSCENE


# ------------------------------------------------------------------ mundo

func _clear_world() -> void:
	if world:
		world.queue_free()
	if fx:
		fx.get_parent().queue_free()
	world = null
	fx = null
	player = null
	drones.clear()
	enemies.clear()
	nets.clear()
	pickups.clear()
	kelps.clear()


func _start_game() -> void:
	_clear_world()
	catalog = {}
	saved = 0
	parts = [0, 0, 0]
	chips = [0, 0, 0, 0]
	chip_cooldown = 0.0
	chip_aim_t = 0.0
	unlocked = 0
	logs_found = 0
	visited = {}
	crack_open = false
	final_started = false
	ending_started = false
	scan_target = null
	scan_progress = 0.0
	emp_cooldown = 0.0
	invuln = 0.0
	throttle = {}
	hud.clear()
	_build_world()
	state = GameState.PLAY
	hud.say("Albatroz: Movimento suspeito detectado no recife. Redes ilegais à vista.", 5.0, Color(0.6, 0.9, 1.0))
	hud.say("Arthur: Hora de trabalhar. Vou catalogar cada tubarão e soltar os que estiverem presos!", 5.0, Color(1.0, 0.9, 0.5))


func _build_world() -> void:
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	modulate_node = CanvasModulate.new()
	world.add_child(modulate_node)
	# camadas do cenário, de trás para a frente
	var water := BgScript.new()
	water.setup("water")
	world.add_child(water)
	var para := ParallaxScript.new()
	para.setup(self)
	world.add_child(para)
	var decor := BgScript.new()
	decor.setup("decor", baker)
	world.add_child(decor)
	var anim := BgAnimScript.new()
	anim.setup(self, light_tex)
	world.add_child(anim)
	var life := AmbientScript.new()
	life.setup(self, light_tex)
	world.add_child(life)

	for r in Data.KELP:
		var k := KelpScript.new()
		k.setup(r, Data.zone_of(r.position.y + 10), lite, baker)
		world.add_child(k)
		kelps.append(k)

	megabase = BaseScript.new()
	megabase.setup(Data.MEGABASE_POS, light_tex)
	world.add_child(megabase)

	for i in Data.PARTS.size():
		for p in Data.PARTS[i]:
			var pk := PickupScript.new()
			pk.setup("part", p, i)
			world.add_child(pk)
			pickups.append(pk)
	for i in Data.LOGS.size():
		var lg := PickupScript.new()
		lg.setup("log", Data.LOGS[i][0], i, Data.LOGS[i][1])
		world.add_child(lg)
		pickups.append(lg)

	sharks_node = Node2D.new()
	world.add_child(sharks_node)
	for id in Data.SPAWNS:
		var sp: Dictionary = Data.SPECIES[id]
		var z: int = sp["zone"]
		for n in Data.SPAWNS[id]:
			var s := SharkScript.new()
			s.setup(id, Vector2(randf_range(400, Data.WORLD_W - 400), randf_range(z * Data.ZONE_H + 150, (z + 1) * Data.ZONE_H - 150)), null if lite else light_tex, self)
			sharks_node.add_child(s)

	for n in Data.NETS:
		var s := SharkScript.new()
		s.setup(n[1], n[0], null if lite else light_tex, self)
		s.trapped = true
		sharks_node.add_child(s)
		var net := NetScript.new()
		net.setup(n[0], s, n[2])
		world.add_child(net)
		nets.append(net)

	for i in range(3):
		var pl := PlesioScript.new()
		pl.setup(Vector2(4700 + i * 700, 4300 + i * 110), 150 + i * 40, Color.from_hsv(0.42 + i * 0.05, 0.5, 0.65))
		world.add_child(pl)

	megalodon = MegaScript.new()
	megalodon.setup(self, megabase)
	world.add_child(megalodon)

	for d in Data.DRONES:
		var dr := DroneScript.new()
		dr.setup(self, d[0], d[1], d[2], Data.zone_of(d[2]) >= 2)
		world.add_child(dr)
		drones.append(dr)
		enemies.append(dr)

	for b in Data.BOATS:
		var boat := BoatScript.new()
		boat.setup(self, b[0], b[1])
		world.add_child(boat)
		enemies.append(boat)

	for p in Data.BUOYS:
		var buoy := BuoyScript.new()
		buoy.setup(self, p)
		world.add_child(buoy)
		enemies.append(buoy)

	player = PlayerScript.new()
	player.setup(self, light_tex)
	player.position = Data.CHECKPOINTS[0]
	world.add_child(player)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = -200
	camera.limit_right = int(Data.WORLD_W) + 200
	camera.limit_top = -700
	camera.limit_bottom = int(Data.SANCTUARY_BOTTOM) + 300
	world.add_child(camera)
	camera.position = player.position
	camera.make_current()

	# efeitos numa camada própria para não escurecerem no fundo do mar
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 1
	fx_layer.follow_viewport_enabled = true
	fx_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fx_layer)
	fx = FxScript.new()
	fx.main = self
	fx_layer.add_child(fx)


# ------------------------------------------------------------------ ciclo de jogo

func _unhandled_input(event: InputEvent) -> void:
	if start_gate != null:
		if event is InputEventKey and event.pressed:
			_dismiss_gate()
			get_viewport().set_input_as_handled()
		return
	match state:
		GameState.PLAY:
			if event.is_action_pressed("pause"):
				_set_paused(true)
			elif event.is_action_pressed("catalog"):
				_open_catalog()
			elif event.is_action_pressed("emp"):
				_fire_emp()
			elif event.is_action_pressed("chip"):
				_fire_chip()
		GameState.PAUSE:
			if event.is_action_pressed("pause") or event.is_action_pressed("accept"):
				_set_paused(false)
			elif event.is_action_pressed("menu"):
				_show_title()
	if event.is_action_pressed("toggle_music") and state != GameState.TITLE:
		var on: bool = music.toggle_music()
		if state == GameState.PLAY:
			hud.say("Música ligada" if on else "Música desligada", 1.5)


func _set_paused(p: bool) -> void:
	get_tree().paused = p
	pause_ui.visible = p
	state = GameState.PAUSE if p else GameState.PLAY


var state_before_catalog := GameState.PLAY


func _open_catalog() -> void:
	music.sfx("catalogo")
	state_before_catalog = state
	get_tree().paused = true
	catalog_ui.visible = true
	state = GameState.CATALOG


func _close_catalog() -> void:
	catalog_ui.visible = false
	get_tree().paused = false
	state = state_before_catalog


func _process(delta: float) -> void:
	if lite:
		fps_timer += delta
		if fps_timer > 5.0:
			fps_timer = 0.0
			print("FPS: ", Engine.get_frames_per_second())
	if state != GameState.PLAY and state != GameState.CUTSCENE or player == null:
		music.stop_loops()
	if not playing() or player == null:
		return
	# ronco do motor do Manta: mais alto quanto mais rápido
	var spd: float = clampf(player.velocity.length() / 300.0, 0.0, 1.0)
	music.loop_sfx("motor", spd > 0.05, lerpf(-26.0, -10.0, spd))
	emp_cooldown = maxf(0.0, emp_cooldown - delta)
	invuln = maxf(0.0, invuln - delta)
	chip_cooldown = maxf(0.0, chip_cooldown - delta)
	chip_aim_t = maxf(0.0, chip_aim_t - delta)
	for k in throttle.keys():
		throttle[k] -= delta

	var pp := player.position
	player_hidden = false
	for k in kelps:
		if k.contains(pp):
			player_hidden = true

	context_hint = ""
	player.arm_target = chip_aim if chip_aim_t > 0.0 else null
	if state == GameState.PLAY:
		_update_nets(delta)
		_update_scan(delta)
		_update_pickups()
		_update_zone()
		if not final_started and unlocked >= 3 and pp.distance_to(megabase.antenna_global()) < EMP_RANGE and context_hint == "":
			if chips[3] >= Data.CHIP_GOAL[3]:
				context_hint = "Aperte Q para sobrecarregar a antena da Corporação!"
			else:
				context_hint = "Antes, proteja %d tubarões da Fossa com chips (F)!" % Data.CHIP_GOAL[3]
		if crack_open and not ending_started and pp.y > 4.0 * Data.ZONE_H + 180.0:
			_start_ending()

	# câmera e luz
	shake_amount = maxf(0.0, shake_amount - delta * 30.0)
	camera.position = pp
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
	_update_light()
	_update_music(delta)


func _update_music(delta: float) -> void:
	if state == GameState.CUTSCENE:
		music.play("santuario")
		return
	if alert_level() == 2:
		danger_hold = 4.0
	else:
		danger_hold = maxf(0.0, danger_hold - delta)
	var z := Data.zone_of(player.position.y)
	if final_started and not catalog.has(Data.MEGALODON_ID):
		music.play("megalodon")
	elif danger_hold > 0.0:
		music.play("perigo")
	else:
		music.play(ZONE_MUSIC[z])


func _update_light() -> void:
	var y := camera.get_screen_center_position().y
	if y > 4.0 * Data.ZONE_H:
		modulate_node.color = Color(0.8, 1.0, 0.95)
		return
	var z := Data.zone_of(maxf(y, 0.0))
	var f := clampf((y - z * Data.ZONE_H) / Data.ZONE_H, 0.0, 1.0)
	var l0: float = Data.ZONES[z]["light"]
	var l1: float = Data.ZONES[mini(z + 1, 3)]["light"]
	var l := lerpf(l0, l1, f)
	modulate_node.color = Color(l, l, minf(1.0, l * 1.08))


func _update_nets(delta: float) -> void:
	for net in nets:
		if net.freed:
			continue
		var d: float = net.position.distance_to(player.position)
		if d < NET_RANGE:
			context_hint = "Segure E para soltar o tubarão preso!"
			if Input.is_action_pressed("interact"):
				net.progress += delta / 1.3
				player.arm_target = net.position
			else:
				net.progress = maxf(0.0, net.progress - delta)
			if net.progress >= 1.0:
				net.freed = true
				net.shark.free_from_trap()
				saved += 1
				music.sfx("tubarao_solto")
				var sp_name: String = Data.SPECIES[net.shark.species_id]["name"]
				hud.say("Tubarão livre! Você salvou um %s. Agora pode escaneá-lo." % sp_name, 4.5, Color(1.0, 0.9, 0.4))
				hud.do_flash(Color(0.4, 1.0, 0.5))
		else:
			net.progress = maxf(0.0, net.progress - delta)


func _update_scan(delta: float) -> void:
	var best = null
	var best_d := SCAN_RANGE
	var candidates: Array = sharks_node.get_children()
	candidates.append(megalodon)
	for s in candidates:
		if not s.can_scan() or catalog.has(s.species_id):
			continue
		var d: float = s.position.distance_to(player.position)
		if s == megalodon:
			d -= 380.0
		if d < best_d:
			best_d = d
			best = s
	if best != scan_target:
		scan_progress = 0.0
	scan_target = best
	music.loop_sfx("escaneando", best != null and Input.is_action_pressed("scan") and state == GameState.PLAY, -6.0)
	if best == null:
		return
	if context_hint == "":
		context_hint = "Segure ESPAÇO para escanear o tubarão!"
	if Input.is_action_pressed("scan"):
		scan_progress += delta / best.scan_time()
		player.arm_target = best.global_position
	else:
		scan_progress = maxf(0.0, scan_progress - delta * 0.7)
	if scan_progress >= 1.0:
		_catalog_species(best.species_id)
		scan_progress = 0.0
		scan_target = null


func _catalog_species(id: int) -> void:
	catalog[id] = true
	for s in sharks_node.get_children():
		if s.species_id == id:
			s.catalogued = true
	hud.show_card(id)
	music.sfx("nova_especie")
	if id != Data.MEGALODON_ID and not throttle.has("chip_tip"):
		throttle["chip_tip"] = 9999.0
		hud.say("Espécie catalogada! Agora dispare chips de proteção (tecla F) em cada tubarão desta espécie.", 6.0, Color(0.5, 1.0, 0.7))
	hud.do_flash(Color(0.4, 1.0, 0.6))
	if id == Data.MEGALODON_ID:
		megalodon.catalogued = true
		crack_open = true
		hud.say("Arthur: Pai... você estava certo. O Megalodon é real!", 5.0, Color(1.0, 0.9, 0.5))
		hud.say("Olhe! Uma fenda brilhante se abriu no fundo da fossa... vamos ver o que tem lá embaixo.", 6.0, Color(0.5, 1.0, 0.9))
	elif catalog.size() == Data.SPECIES.size() - 1:
		hud.say("Todas as espécies conhecidas catalogadas! Só falta a lenda...", 5.0, Color(1.0, 0.9, 0.5))


func _update_pickups() -> void:
	for pk in pickups.duplicate():
		if pk.position.distance_to(player.position) > 55.0:
			continue
		pickups.erase(pk)
		if pk.kind == "part":
			var z: int = pk.zone
			parts[z] += 1
			music.sfx("peca")
			hud.say("Peça da Corporação recolhida! (%d de 3 nesta zona)" % parts[z], 3.0, Color(0.8, 0.9, 1.0))
			_check_unlock(z)
		else:
			logs_found += 1
			music.sfx("gravacao")
			hud.say("Gravação de Philip Blake: \"%s\"" % pk.text, 7.0, Color(1.0, 0.85, 0.45))
		pk.queue_free()


func _update_zone() -> void:
	var z := Data.zone_of(player.position.y)
	if visited.has(z) or z > 3:
		return
	visited[z] = true
	var texts := [
		"Recife de Coral: catalogue as espécies (ESPAÇO), proteja 6 tubarões com chips (F) e ache 3 peças da Corporação.",
		"Mar Aberto! Aqui vivem tubarões grandes e rápidos. Cuidado com os drones laranja do Sindicato.",
		"Zona da Penumbra. Drones brancos da Corporação e boias-sonar: quando a luz da boia piscar rápido, esconda-se!",
		"Fossa das Marianas, o lugar mais fundo do oceano. Encontre a megabase da Corporação.",
	]
	hud.say(texts[z], 6.0, Color(0.6, 0.95, 1.0))


# ------------------------------------------------------------------ chamado por outros scripts

func max_depth_for(p: Vector2) -> float:
	if unlocked < 3:
		return (unlocked + 1) * Data.ZONE_H - 40.0
	if crack_open and ((p.x > Data.CRACK_X.x + 40.0 and p.x < Data.CRACK_X.y - 40.0) or p.y > 4.0 * Data.ZONE_H + 125.0):
		return Data.SANCTUARY_BOTTOM - 60.0
	return 4.0 * Data.ZONE_H - 50.0


func pressure_limit_line() -> float:
	return (unlocked + 1) * Data.ZONE_H if unlocked < 3 else -1.0


func on_pressure_limit() -> void:
	if throttle.get("pressure", 0.0) > 0.0:
		return
	throttle["pressure"] = 6.0
	if unlocked < 3:
		hud.say("O casco não aguenta mais pressão! Falta: %s." % _missing_text(unlocked), 4.5, Color(1.0, 0.6, 0.6))
	elif not crack_open:
		hud.say("Só rocha no fundo da fossa... por enquanto.", 3.0)


func player_invulnerable() -> bool:
	return invuln > 0.0 or state != GameState.PLAY


func player_caught() -> void:
	if invuln > 0.0:
		return
	invuln = 3.0
	hud.do_flash(Color(1.0, 0.3, 0.3))
	music.sfx("apanhado")
	hud.say("Ops! Um drone apanhou o Manta e te levou de volta. Esconda-se nas algas ou use o EMP (Q)!", 5.0, Color(1.0, 0.7, 0.7))
	var z := mini(Data.zone_of(player.position.y), 3)
	player.position = Data.CHECKPOINTS[z]
	player.velocity = Vector2.ZERO
	player.blink = 3.0
	camera.reset_smoothing()
	for e in enemies:
		if is_instance_valid(e):
			e.reset_alert()


func on_drone_alert(_d) -> void:
	on_enemy_alert("Um drone te viu! Fuja para longe, esconda-se nas algas ou use o Pulso EMP (Q).")


func on_enemy_alert(text: String) -> void:
	if throttle.get("alert", 0.0) > 0.0:
		return
	throttle["alert"] = 8.0
	hud.say(text, 3.5, Color(1.0, 0.5, 0.5))


## Boia-sonar detectou o Manta: chama os drones próximos para aquele ponto
func sonar_alarm(p: Vector2, radius: float) -> void:
	music.sfx("sonar_alarme")
	throttle["alert"] = 0.0
	on_enemy_alert("A boia-sonar te encontrou! Os drones estão vindo. Esconda-se ou use o EMP (Q)!")
	for d in drones:
		if is_instance_valid(d) and d.position.distance_to(p) < radius:
			d.alarm(p)


func alert_level() -> int:
	var lvl := 0
	for e in enemies:
		if is_instance_valid(e):
			lvl = maxi(lvl, e.threat())
	return lvl


## Toca um efeito que vem de um ponto do mundo: mais baixo quanto mais longe do Manta
func sfx_at(sfx_name: String, p: Vector2, max_dist := 1100.0) -> void:
	if player == null:
		return
	var d := p.distance_to(player.position)
	if d > max_dist:
		return
	music.sfx(sfx_name, -18.0 * d / max_dist)


## Dispara um dardo com chip de proteção na direção do tubarão mais próximo (com um pouco de mira automática)
func _fire_chip() -> void:
	if chip_cooldown > 0.0:
		return
	var pp := player.position
	var best = null
	var best_d := 420.0
	var uncatalogued_near := false
	for s in sharks_node.get_children():
		if not s.can_chip():
			continue
		var d: float = s.position.distance_to(pp)
		if d > 420.0:
			continue
		if not catalog.has(s.species_id):
			uncatalogued_near = true
			continue
		if d < best_d:
			best_d = d
			best = s
	if best == null:
		if uncatalogued_near:
			hud.say("Primeiro catalogue esta espécie: segure ESPAÇO perto do tubarão.", 3.0, Color(1.0, 0.85, 0.5))
		else:
			hud.say("Nenhum tubarão sem chip por perto.", 2.0)
		return
	chip_cooldown = 0.7
	var from: Vector2 = player.to_global(player.tip_local)
	# mira só meio adiantada: tubarões rápidos exigem chegar alinhado com eles
	var lead: Vector2 = best.velocity * (best_d / DartScript.SPEED) * 0.5
	var aim: Vector2 = best.position + lead
	chip_aim = aim
	chip_aim_t = 0.35
	var dart := DartScript.new()
	dart.setup(self, from, aim)
	world.add_child(dart)
	music.sfx("chip_disparo")


func chip_shark(s) -> void:
	s.chipped = true
	var z: int = Data.SPECIES[s.species_id]["zone"]
	chips[z] += 1
	music.sfx("chip")
	hud.do_flash(Color(0.4, 1.0, 0.6))
	var goal: int = Data.CHIP_GOAL[z]
	var sp_name: String = Data.SPECIES[s.species_id]["name"]
	if chips[z] <= goal:
		hud.say("%s protegido com chip! (%d de %d nesta zona)" % [sp_name, chips[z], goal], 3.0, Color(0.5, 1.0, 0.7))
	else:
		hud.say("%s protegido com chip!" % sp_name, 2.5, Color(0.5, 1.0, 0.7))
	if z < 3:
		_check_unlock(z)
	elif chips[3] == Data.CHIP_GOAL[3]:
		hud.say("Tubarões da Fossa protegidos! Agora encontre a antena da megabase e use o EMP (Q).", 6.0, Color(0.6, 0.9, 1.0))


func on_dart_missed() -> void:
	if throttle.get("miss", 0.0) > 0.0:
		return
	throttle["miss"] = 6.0
	hud.say("Errou! Chegue mais perto e alinhado com o tubarão antes de disparar.", 3.0, Color(1.0, 0.85, 0.5))


func on_shark_scared() -> void:
	if throttle.get("scared", 0.0) > 0.0:
		return
	throttle["scared"] = 12.0
	hud.say("O tubarão se assustou! Chegue devagar: movimentos rápidos espantam os tubarões.", 4.0, Color(1.0, 0.85, 0.5))


func _missing_text(z: int) -> String:
	var miss: Array = []
	if parts[z] < 3:
		miss.append("%d peça(s) da Corporação" % (3 - parts[z]))
	var goal: int = Data.CHIP_GOAL[z]
	if chips[z] < goal:
		miss.append("%d chip(s) de proteção" % (goal - chips[z]))
	return " e ".join(miss)


## Libera a zona seguinte quando as peças E os chips da zona estiverem completos
func _check_unlock(z: int) -> void:
	if unlocked != z or z >= 3:
		return
	if parts[z] >= 3 and chips[z] >= Data.CHIP_GOAL[z]:
		unlocked = z + 1
		music.sfx("casco")
		hud.do_flash(Color(0.5, 0.8, 1.0))
		var next_name: String = Data.ZONES[unlocked]["name"]
		hud.say("Casco reforçado com tecnologia roubada da Corporação! Agora o Manta aguenta descer até: %s." % next_name, 6.0, Color(0.6, 0.9, 1.0))
	elif parts[z] >= 3 or chips[z] >= Data.CHIP_GOAL[z]:
		hud.say("Para reforçar o casco ainda falta: %s." % _missing_text(z), 4.0, Color(0.8, 0.9, 1.0))


func shake(amount: float) -> void:
	shake_amount = maxf(shake_amount, amount)


func _fire_emp() -> void:
	if emp_cooldown > 0.0:
		return
	emp_cooldown = emp_max
	var pp := player.position
	fx.add_ring(pp)
	music.sfx("emp")
	var hits := 0
	for e in enemies:
		if is_instance_valid(e) and e.emp_point().distance_to(pp) < EMP_RANGE:
			e.stun(4.5)
			hits += 1
	if hits > 0:
		hud.say("Pulso EMP! Inimigos desligados por alguns segundos. Passe agora!", 2.5, Color(0.6, 0.85, 1.0))
	if not final_started and unlocked >= 3 and chips[3] >= Data.CHIP_GOAL[3] and pp.distance_to(megabase.antenna_global()) < EMP_RANGE:
		_start_final_event()


# ------------------------------------------------------------------ clímax e final

func _start_final_event() -> void:
	final_started = true
	megabase.start_alarm()
	music.sfx("alarme_base")
	shake(12.0)
	hud.say("Arthur: Sobrecarreguei o sonar deles... as sirenes estão tocando alto demais!", 4.0, Color(1.0, 0.9, 0.5))
	await get_tree().create_timer(3.5, false).timeout
	if not is_instance_valid(megalodon):
		return
	hud.say("O chão está tremendo... algo ENORME acordou nas profundezas!", 4.5, Color(1.0, 0.6, 0.6))
	shake(18.0)
	megalodon.awaken()
	music.sfx("megalodon_rugido")


func on_base_destroyed() -> void:
	shake(25.0)
	for e in enemies:
		if is_instance_valid(e) and e.position.y > 3.0 * Data.ZONE_H:
			e.queue_free()
	hud.say("A megabase foi destruída e os drones fugiram! Os vilões escaparam em cápsulas, prometendo nunca mais voltar.", 6.0, Color(0.6, 1.0, 0.7))
	hud.say("O Megalodon está calmo agora. Chegue perto e segure ESPAÇO para escaneá-lo!", 6.0, Color(1.0, 0.9, 0.5))


func _start_ending() -> void:
	ending_started = true
	state = GameState.CUTSCENE
	player.locked = true
	player.auto_move = Vector2(0.25 * player.facing, 0.1)
	var gold := Color(1.0, 0.88, 0.5)
	hud.messages.clear()
	hud.say("Um mundo perdido! Dinossauros marinhos que todos pensavam extintos...", 4.5, Color(0.6, 1.0, 0.9), true)
	hud.say("COMPUTADOR: Descoberta histórica! Registrar e mostrar ao mundo inteiro?", 4.5, Color(0.6, 0.9, 1.0), true)
	hud.say("Arthur: É... a arte imitando a vida, mesmo sem perceber...", 5.0, gold, true)
	hud.say("Arthur: Pai, você tinha razão. Algumas lendas precisam continuar sendo lendas. Vocês estão a salvo.", 6.5, gold, true)
	hud.say("Registro desligado. O santuário continua em segredo.", 3.5, Color.WHITE, true)
	await get_tree().create_timer(4.5).timeout
	player.auto_move = Vector2.ZERO
	await get_tree().create_timer(20.0).timeout
	if state != GameState.CUTSCENE:
		return
	var total_chips: int = chips[0] + chips[1] + chips[2] + chips[3]
	var stats := "Espécies catalogadas: %d / %d\nTubarões protegidos com chip: %d\nTubarões salvos: %d / %d\nGravações do pai: %d / %d" % [
		catalog.size(), Data.SPECIES.size(), total_chips, saved, Data.NETS.size(), logs_found, Data.LOGS.size()]
	state = GameState.ENDING
	hud.clear()
	_clear_world()
	ending_ui.play(stats)
	await get_tree().create_timer(15.0).timeout
	if state == GameState.ENDING:
		music.sfx("fim")
		music.play("tema")
