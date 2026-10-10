extends Node
## Autoload "Sfx": música lo-fi, ambiente de burbujas y efectos (generados con tools/gen_audio.py).
## Respeta Game.settings (music / sfx / vibration).

const SOUNDS := ["plop", "bubble", "squeak", "slurp", "coin", "chime", "levelup", "hatch", "click", "error"]

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _last := {}                      ## nombre → ms del último disparo (evita ametrallar)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for s in SOUNDS:
		_streams[s] = load("res://assets/audio/%s.wav" % s)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = _loop("res://assets/audio/music.ogg", -9.0)
	_amb = _loop("res://assets/audio/ambience.ogg", -14.0)
	apply_settings.call_deferred()


func _loop(path: String, db: float) -> AudioStreamPlayer:
	var st: AudioStreamOggVorbis = load(path)
	st.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = db
	add_child(p)
	return p


func apply_settings() -> void:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	if game.settings.music and not _music.playing:
		_music.play()
	elif not game.settings.music:
		_music.stop()
	if game.settings.sfx and not _amb.playing:
		_amb.play()
	elif not game.settings.sfx:
		_amb.stop()


## Efecto con un poco de variación de tono. min_gap_ms: separación mínima entre repeticiones.
func play(name: String, min_gap_ms := 60, db := 0.0) -> void:
	var game := get_node_or_null("/root/Game")
	if game == null or not game.settings.sfx or not _streams.has(name):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, -100000)) < min_gap_ms:
		return
	_last[name] = now
	for p in _pool:
		if not p.playing:
			p.stream = _streams[name]
			p.pitch_scale = randf_range(0.94, 1.06)
			p.volume_db = db
			p.play()
			return


func vibrate(ms := 25) -> void:
	var game := get_node_or_null("/root/Game")
	if game and game.settings.vibration:
		Input.vibrate_handheld(ms)
