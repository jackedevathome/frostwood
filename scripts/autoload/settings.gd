extends Node
## Global settings: audio buses, video options, gameplay options and key bindings.
## Everything is persisted to user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"
const BUSES := ["Music", "SFX", "Ambience"]
const DIFFICULTY_NAMES := ["Easy", "Normal", "Hard"]

# Rebindable keyboard actions -> default physical keycode.
const KEY_ACTIONS := {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"sprint": KEY_SHIFT,
	"interact": KEY_E,
	"inventory": KEY_I,
	"craft": KEY_C,
	"skills": KEY_K,
	"map": KEY_M,
}
const ACTION_LABELS := {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"sprint": "Sprint",
	"interact": "Interact / Cook / Fuel fire",
	"inventory": "Inventory",
	"craft": "Crafting",
	"skills": "Skill Tree",
	"map": "World Map",
}

var master_volume := 0.8
var music_volume := 0.7
var sfx_volume := 0.8
var ambience_volume := 0.7
var fullscreen := false
var vsync := true
var show_fps := false
var screen_shake := true
var night_brightness := 0.35
var difficulty := 1
var damage_numbers := true
var best_days := 0
var bindings := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_buses()
	bindings = KEY_ACTIONS.duplicate()
	load_settings()
	_build_input_map()
	apply()


func _create_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	# A gentle limiter on master keeps stacked sounds from clipping.
	if AudioServer.get_bus_effect_count(0) == 0:
		var lim := AudioEffectLimiter.new()
		lim.ceiling_db = -0.5
		AudioServer.add_bus_effect(0, lim)
	# Music + ambience get muffled while the game is paused.
	for bus_name in ["Music", "Ambience"]:
		var bi := AudioServer.get_bus_index(bus_name)
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 800
		AudioServer.add_bus_effect(bi, lp, 0)
		AudioServer.set_bus_effect_enabled(bi, 0, false)
	# Ambience gets a bit of reverb for space.
	var amb := AudioServer.get_bus_index("Ambience")
	if AudioServer.get_bus_effect_count(amb) == 1:
		var rev := AudioEffectReverb.new()
		rev.room_size = 0.7
		rev.wet = 0.15
		AudioServer.add_bus_effect(amb, rev)


func _build_input_map() -> void:
	for action in KEY_ACTIONS:
		_set_key(action, bindings[action])
	_ensure_action("pause", [_key(KEY_ESCAPE)])
	_ensure_action("use", [_mouse(MOUSE_BUTTON_LEFT)])
	_ensure_action("alt_use", [_mouse(MOUSE_BUTTON_RIGHT)])
	for i in range(1, 4):
		_ensure_action("slot_%d" % i, [_key(KEY_0 + i)])
	# Arrow keys as permanent secondary movement keys.
	InputMap.action_add_event("move_up", _key(KEY_UP))
	InputMap.action_add_event("move_down", _key(KEY_DOWN))
	InputMap.action_add_event("move_left", _key(KEY_LEFT))
	InputMap.action_add_event("move_right", _key(KEY_RIGHT))


func _key(code: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	return ev


func _mouse(button: int) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	return ev


func _ensure_action(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for ev in events:
		InputMap.action_add_event(action, ev)


func _set_key(action: String, code: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	# Remove only the primary (rebindable) key, keep arrow-key fallbacks.
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and not (ev.physical_keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]):
			InputMap.action_erase_event(action, ev)
	InputMap.action_add_event(action, _key(code))


func rebind(action: String, code: int) -> void:
	bindings[action] = code
	_set_key(action, code)
	save_settings()
	changed.emit()


func reset_bindings() -> void:
	for action in KEY_ACTIONS:
		rebind(action, KEY_ACTIONS[action])


func key_name(action: String) -> String:
	return OS.get_keycode_string(bindings.get(action, KEY_NONE))


func set_muffled(on: bool) -> void:
	for bus_name in ["Music", "Ambience"]:
		AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(bus_name), 0, on)


func difficulty_mult() -> float:
	return [0.7, 1.0, 1.35][difficulty]


func apply() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	_set_bus("Ambience", ambience_volume)
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	changed.emit()


func _set_bus(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.001)))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "ambience", ambience_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "vsync", vsync)
	cfg.set_value("video", "show_fps", show_fps)
	cfg.set_value("video", "screen_shake", screen_shake)
	cfg.set_value("video", "night_brightness", night_brightness)
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("game", "damage_numbers", damage_numbers)
	cfg.set_value("stats", "best_days", best_days)
	for action in bindings:
		cfg.set_value("controls", action, bindings[action])
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	ambience_volume = cfg.get_value("audio", "ambience", ambience_volume)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	vsync = cfg.get_value("video", "vsync", vsync)
	show_fps = cfg.get_value("video", "show_fps", show_fps)
	screen_shake = cfg.get_value("video", "screen_shake", screen_shake)
	night_brightness = cfg.get_value("video", "night_brightness", night_brightness)
	difficulty = clampi(cfg.get_value("game", "difficulty", difficulty), 0, 2)
	damage_numbers = cfg.get_value("game", "damage_numbers", damage_numbers)
	best_days = cfg.get_value("stats", "best_days", best_days)
	for action in KEY_ACTIONS:
		bindings[action] = cfg.get_value("controls", action, KEY_ACTIONS[action])


func record_days(days: int) -> bool:
	if days > best_days:
		best_days = days
		save_settings()
		return true
	return false
