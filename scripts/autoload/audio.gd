extends Node
## Sound manager: one-shot SFX (flat or positional), cross-faded music and looping ambience.

const SFX_NAMES := [
	"chop", "mine", "swing", "bow", "arrow_hit", "pickup", "eat", "craft", "hurt", "howl",
	"growl", "animal_die", "tree_fall", "place", "ui_hover", "ui_click", "dawn", "game_over",
	"ignite", "step0", "step1", "step2", "step3",
]
const LOOPS := ["music_menu", "music_day", "music_night", "amb_wind", "amb_forest", "amb_fire"]

var streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_music := ""
var _music_tween: Tween
var _music_b_active := false
var _ambience := {}  # name -> AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX_NAMES:
		streams[n] = load("res://assets/audio/%s.wav" % n)
	for n in LOOPS:
		var s: AudioStream = load("res://assets/audio/%s.ogg" % n)
		if s is AudioStreamOggVorbis:
			s.loop = true
		streams[n] = s
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music_a = _make_music_player()
	_music_b = _make_music_player()


func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.volume_db = -80
	add_child(p)
	return p


## Plays a non-positional sound effect.
func play(sfx: String, volume_db := 0.0, pitch_var := 0.08) -> void:
	if not streams.has(sfx):
		return
	var player: AudioStreamPlayer = null
	for p in _pool:
		if not p.playing:
			player = p
			break
	if player == null:
		player = _pool[0]
	player.stream = streams[sfx]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	player.play()


## Plays a sound in the world; volume falls off with distance from the camera.
func play_at(sfx: String, pos: Vector2, volume_db := 0.0, pitch_var := 0.08, max_dist := 1400.0) -> void:
	if not streams.has(sfx):
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := AudioStreamPlayer2D.new()
	p.stream = streams[sfx]
	p.bus = "SFX"
	p.volume_db = volume_db
	p.max_distance = max_dist
	p.attenuation = 1.4
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.global_position = pos
	scene.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func play_music(track: String, fade := 2.5) -> void:
	if track == _current_music:
		return
	_current_music = track
	if _music_tween:
		_music_tween.kill()
	var old := _music_b if _music_b_active else _music_a
	var incoming := _music_a if _music_b_active else _music_b
	_music_b_active = not _music_b_active
	incoming.stream = streams.get(track)
	incoming.volume_db = -40
	incoming.play()
	_music_tween = create_tween().set_parallel()
	_music_tween.tween_property(incoming, "volume_db", 0.0, fade)
	_music_tween.tween_property(old, "volume_db", -80.0, fade)
	_music_tween.chain().tween_callback(old.stop)


func stop_music(fade := 1.5) -> void:
	_current_music = ""
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel()
	for p in [_music_a, _music_b]:
		_music_tween.tween_property(p, "volume_db", -80.0, fade)
	_music_tween.chain().tween_callback(func():
		_music_a.stop()
		_music_b.stop())


## Fades a looping ambience track to a target volume (use -80 to silence it).
func set_ambience(track: String, volume_db: float, fade := 2.0) -> void:
	var p: AudioStreamPlayer = _ambience.get(track)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = "Ambience"
		p.stream = streams.get(track)
		p.volume_db = -80
		add_child(p)
		_ambience[track] = p
	if volume_db > -79 and not p.playing:
		p.play()
	if p.has_meta("tw"):
		var old: Tween = p.get_meta("tw")
		if old and old.is_valid():
			old.kill()
	var tw := create_tween()
	p.set_meta("tw", tw)
	tw.tween_property(p, "volume_db", volume_db, fade)
	if volume_db <= -79:
		tw.tween_callback(p.stop)


func stop_all_ambience(fade := 1.0) -> void:
	for track in _ambience:
		set_ambience(track, -80, fade)


## Makes every Button under `root` click/hover with UI sounds.
func hook_buttons(root: Node) -> void:
	for child in root.get_children():
		if child is BaseButton and not child.has_meta("snd"):
			child.set_meta("snd", true)
			child.mouse_entered.connect(_on_hover.bind(child))
			child.pressed.connect(func(): play("ui_click", -4, 0.03))
		hook_buttons(child)


func _on_hover(button: BaseButton) -> void:
	if not button.disabled:
		play("ui_hover", -10, 0.05)
