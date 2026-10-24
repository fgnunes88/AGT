extends Node
## Gerenciador de música e vinhetas.
## Coloque os arquivos nas pastas res://music/ e res://sfx/ com os nomes abaixo
## (extensão .ogg, .mp3 ou .wav). Arquivo que não existir é simplesmente ignorado.

const MUSIC_DIR := "res://music/"
const SFX_DIR := "res://sfx/"
const EXTENSIONS := ["ogg", "mp3", "wav"]

# Se a música não existir, tenta a próxima da lista (economiza faixas)
const FALLBACK := {
	"mar_aberto": "recife",
	"fossa": "penumbra",
	"santuario": "tema",
	"megalodon": "perigo",
}

# nomes alternativos aceitos (ex.: arquivo salvo como "escaneado.wav")
const ALIASES := {"escaneando": "escaneado"}

const FADE_TIME := 1.5
const FAST_FADE := 0.25   # troca rápida (entrada e saída da música de perigo)
const MUSIC_DB := -6.0
const SFX_DB := -2.0

# No navegador a música toca num elemento <audio> do HTML: assim ela não depende
# do ritmo do jogo e não sai picotada quando um quadro demora.
const JS_INIT := """
(function(){
if (window.agtMusic) return;
var a = new Audio(); a.loop = true; a.preload = 'auto'; a.volume = 0;
var M = {a:a, vol:0.5, muted:false, want:null, timer:null, unlocked:false};
function fade(to, ms, done){
  clearInterval(M.timer); var from = a.volume, t0 = Date.now();
  M.timer = setInterval(function(){
    var k = Math.min(1, (Date.now()-t0)/ms);
    a.volume = Math.max(0, Math.min(1, from + (to-from)*k));
    if (k >= 1){ clearInterval(M.timer); if (done) done(); }
  }, 40);
}
function start(urls, i){
  if (i >= urls.length) return;
  a.onerror = function(){ start(urls, i+1); };
  a.src = urls[i]; a.currentTime = 0; a.volume = 0;
  var pr = a.play();
  if (pr && pr.catch) pr.catch(function(){});
  fade(M.muted ? 0 : M.vol, M.inMs || 800);
}
M.play = function(urls, fast){
  M.want = urls; M.inMs = fast ? 200 : 800;
  if (!a.paused && a.volume > 0.01){ fade(0, fast ? 120 : 400, function(){ a.pause(); start(urls, 0); }); }
  else { a.pause(); start(urls, 0); }
};
M.stop = function(){ M.want = null; fade(0, 600, function(){ a.pause(); }); };
M.mute = function(x){ M.muted = x; fade(x ? 0 : M.vol, 300); };
function unlock(){
  if (M.unlocked) return; M.unlocked = true;
  if (M.want && a.paused){ start(M.want, 0); }
}
['pointerdown','touchstart','keydown','mousedown'].forEach(function(e){
  document.addEventListener(e, unlock, true);
});
window.agtMusic = M;
})();
"""
var web := false

var players: Array[AudioStreamPlayer] = []
var active := 0
var current := ""
var music_on := true
var cache := {}
var sfx_players: Array[AudioStreamPlayer] = []
var tweens: Array = [null, null]
var loops := {}            # nome -> AudioStreamPlayer de efeitos contínuos (motor, scanner)
var last_played := {}      # nome -> tempo da última vez (evita repetir demais)
var clock := 0.0

# intervalo mínimo entre repetições do mesmo efeito (segundos)
const MIN_GAP := {"alerta": 1.5, "suspeita": 1.5, "sonar_onda": 0.5, "menu_mover": 0.05}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	web = OS.has_feature("web")
	if web:
		JavaScriptBridge.eval(JS_INIT, true)
	# No navegador NÃO criamos canais de áudio extras: o Godot 4.3 os liga em círculo
	# (Master -> SFX -> Music -> Master) e o navegador silencia todos os efeitos.
	# Lá a música já toca pelo HTML, então os efeitos vão direto para o Master.
	if not web:
		_ensure_bus("Music")
		_ensure_bus("SFX")
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Master" if web else "Music"
		p.volume_db = -80.0
		# No navegador, "sample" decodifica a música inteira de uma vez (lento e pesado).
		# Em modo "stream" ela é lida aos poucos, como no PC.
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(p)
		players.append(p)
	for i in 4:
		var s := AudioStreamPlayer.new()
		s.bus = sfx_bus()
		s.volume_db = SFX_DB
		add_child(s)
		sfx_players.append(s)


func _process(delta: float) -> void:
	clock += delta


func sfx_bus() -> String:
	return "Master" if web else "SFX"


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _find(dir: String, track: String) -> AudioStream:
	var key := dir + track
	if cache.has(key):
		return cache[key]
	var stream: AudioStream = null
	for ext in EXTENSIONS:
		var path: String = dir + track + "." + ext
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream == null and ALIASES.has(track):
		var alt: String = ALIASES[track]
		for ext in EXTENSIONS:
			var path2: String = dir + alt + "." + ext
			if ResourceLoader.exists(path2):
				stream = load(path2)
				break
	cache[key] = stream
	return stream


func _music_stream(track: String) -> AudioStream:
	var tname := track
	var tries := 0
	while tname != "" and tries < 4:
		var s := _find(MUSIC_DIR, tname)
		if s != null:
			return s
		tname = FALLBACK.get(tname, "")
		tries += 1
	return null


func _set_loop(s: AudioStream) -> void:
	if s is AudioStreamMP3 or s is AudioStreamOggVorbis:
		s.set("loop", true)
	elif s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		if w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.get_length() * w.mix_rate)


## Troca a música com transição suave. Chamar várias vezes com a mesma faixa não faz nada.
func play(track: String, fast := false) -> void:
	if track == current:
		return
	current = track
	if web:
		_web_play(track, fast)
		return
	var ft := FAST_FADE if fast else FADE_TIME
	var s := _music_stream(track)
	var old := players[active]
	if s != null and old.stream == s and old.playing:
		return  # a faixa reserva é a mesma que já está tocando
	_fade(old, -80.0, true, ft)
	if s == null:
		return
	_set_loop(s)
	active = 1 - active
	var p := players[active]
	p.stream = s
	p.volume_db = -20.0 if fast else -40.0
	p.play()
	_fade(p, MUSIC_DB, false, ft)


func _web_play(track: String, fast := false) -> void:
	var urls: Array = []
	var tname := track
	var tries := 0
	while tname != "" and tries < 4:
		urls.append("music/" + tname + ".mp3")
		urls.append("music/" + tname + ".ogg")
		tname = FALLBACK.get(tname, "")
		tries += 1
	JavaScriptBridge.eval("window.agtMusic && window.agtMusic.play(" + JSON.stringify(urls) + ", " + ("true" if fast else "false") + ");", true)


func stop() -> void:
	current = ""
	if web:
		JavaScriptBridge.eval("window.agtMusic && window.agtMusic.stop();", true)
		return
	for p in players:
		_fade(p, -80.0, true)


func _fade(p: AudioStreamPlayer, to_db: float, stop_after: bool, time := FADE_TIME) -> void:
	var i := players.find(p)
	if tweens[i] != null and tweens[i].is_valid():
		tweens[i].kill()
	var tw := create_tween()
	tweens[i] = tw
	tw.tween_property(p, "volume_db", to_db, time)
	if stop_after:
		tw.tween_callback(p.stop)


## Efeito ou vinheta curta. volume_offset em dB (negativo = mais baixo)
func sfx(sfx_name: String, volume_offset := 0.0) -> void:
	var s := _find(SFX_DIR, sfx_name)
	if s == null:
		return
	var gap: float = MIN_GAP.get(sfx_name, 0.08)
	if clock - float(last_played.get(sfx_name, -99.0)) < gap:
		return
	last_played[sfx_name] = clock
	var chosen: AudioStreamPlayer = null
	for p in sfx_players:
		if not p.playing:
			chosen = p
			break
	if chosen == null:
		chosen = sfx_players[0]
	chosen.stream = s
	chosen.volume_db = SFX_DB + volume_offset
	chosen.play()


## Efeito contínuo em loop (motor, scanner). Chame todo quadro com on = true/false.
func loop_sfx(sfx_name: String, on: bool, volume_db := 0.0) -> void:
	var p: AudioStreamPlayer = loops.get(sfx_name)
	if p == null:
		if not on:
			return
		var s := _find(SFX_DIR, sfx_name)
		if s == null:
			return
		s = s.duplicate() as AudioStream
		_set_loop(s)
		p = AudioStreamPlayer.new()
		p.bus = sfx_bus()
		p.stream = s
		add_child(p)
		loops[sfx_name] = p
	if on:
		p.volume_db = volume_db
		if not p.playing:
			p.play()
	elif p.playing:
		p.stop()


func stop_loops() -> void:
	for k in loops:
		loops[k].stop()


## Liga/desliga só a música (as vinhetas continuam)
func toggle_music() -> bool:
	music_on = not music_on
	if web:
		JavaScriptBridge.eval("window.agtMusic && window.agtMusic.mute(%s);" % ("false" if music_on else "true"), true)
	if not web:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not music_on)
	return music_on
