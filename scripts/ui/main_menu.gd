extends Control
## Title screen: New Game, How to Play, Settings, Credits, Quit.

var _buttons: VBoxContainer
var _settings: SettingsMenu
var _info_panel: PanelContainer
var _info_text: RichTextLabel
var _info_title: Label
var _title: Label
var _t := 0.0


func _ready() -> void:
	theme = UITheme.get_theme()
	Input.set_custom_mouse_cursor(null)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg := MenuBackground.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 6)
	add_child(center)

	_title = UITheme.label("FROSTWOOD", 104, Color(0.92, 0.96, 1.0))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_constant_override("outline_size", 14)
	_title.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.16, 0.95))
	_title.add_theme_color_override("font_shadow_color", Color(0.3, 0.9, 0.7, 0.35))
	_title.add_theme_constant_override("shadow_offset_y", 6)
	_title.add_theme_constant_override("shadow_outline_size", 22)
	center.add_child(_title)
	var sub := UITheme.label("~  a Nordic survival  ~", 26, UITheme.ACCENT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	center.add_child(spacer)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 12)
	_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(_buttons)
	_add_button("New Game", _on_new_game)
	_add_button("How to Play", _show_info.bind("How to Play", UITheme.how_to_play_text()))
	_add_button("Settings", _on_settings)
	_add_button("Credits", _show_info.bind("Credits", _credits_text()))
	if OS.get_name() != "Web":
		_add_button("Quit", func(): get_tree().quit())

	if Settings.best_days > 0:
		var best := UITheme.label("Longest survival: %d day%s" % [Settings.best_days, "" if Settings.best_days == 1 else "s"], 18, UITheme.WARM)
		best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		center.add_child(best)

	var ver := UITheme.label("v1.0  •  Godot 4", 14, UITheme.MUTED)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.position = Vector2(-150, -32)
	add_child(ver)

	_build_info_panel()
	_settings = SettingsMenu.new()
	_settings.hide()
	_settings.closed.connect(_on_sub_closed)
	add_child(_settings)

	Audio.hook_buttons(self)
	Audio.play_music("music_menu", 1.5)
	Audio.stop_all_ambience()
	Audio.set_ambience("amb_wind", -14, 2.0)
	(_buttons.get_child(0) as Button).grab_focus()

	# Entrance animation
	center.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(center, "modulate:a", 1.0, 1.2)


func _process(delta: float) -> void:
	_t += delta
	_title.add_theme_color_override("font_shadow_color", Color(0.3, 0.9, 0.7, 0.25 + 0.15 * sin(_t * 1.3)))


func _add_button(text: String, cb: Callable) -> void:
	var b := UITheme.button(text, 300)
	b.pressed.connect(cb)
	_buttons.add_child(b)


func _build_info_panel() -> void:
	_info_panel = PanelContainer.new()
	_info_panel.custom_minimum_size = Vector2(760, 540)
	_info_panel.hide()
	add_child(_info_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_info_panel.add_child(v)
	_info_title = UITheme.label("", 34, UITheme.ACCENT)
	_info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info_title)
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_text.add_theme_font_size_override("normal_font_size", 19)
	_info_text.add_theme_font_size_override("bold_font_size", 19)
	v.add_child(_info_text)
	var back := UITheme.button("Back", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_on_sub_closed)
	v.add_child(back)


func _show_info(title: String, text: String) -> void:
	_info_title.text = title
	_info_text.text = text
	_buttons.get_parent().hide()
	_info_panel.show()
	await get_tree().process_frame
	_info_panel.position = (size - _info_panel.size) / 2.0


func _on_settings() -> void:
	_buttons.get_parent().hide()
	_settings.open()


func _on_sub_closed() -> void:
	_info_panel.hide()
	_settings.hide()
	_buttons.get_parent().show()
	(_buttons.get_child(0) as Button).grab_focus()


func _on_new_game() -> void:
	Audio.stop_music(1.0)
	Fader.change_scene("res://scenes/game.tscn", 0.8)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _info_panel.visible:
		_on_sub_closed()


func _credits_text() -> String:
	return "[center][b]FROSTWOOD[/b]\n\nA small survival game set in the snowy pine and spruce forests of the North.\n\n" + \
		"[color=#94d1f5]Design, code & procedural art[/color]\nMade with Godot Engine 4\n\n" + \
		"[color=#94d1f5]Music & sound[/color]\nAll audio is synthesised from scratch by tools/generate_audio.py:\nkantele-style plucked strings, drones, birch-bark horn, frame drum,\nwind, birdsong, fire crackle and snow footsteps.\n\n" + \
		"[color=#f8b862]Thanks for playing — stay warm.[/color][/center]"
