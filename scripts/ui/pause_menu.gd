class_name PauseMenu
extends CanvasLayer
## Esc menu: resume, settings, how to play, quit to main menu.

signal resumed

var _dim: ColorRect
var _panel: PanelContainer
var _settings: SettingsMenu
var _help: PanelContainer
var _save_btn: Button
var game: Node


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.get_theme()
	add_child(root)
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.04, 0.07, 0.6)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_panel.add_child(v)
	var t := UITheme.heading("Paused", 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(UITheme.ornament(300))
	for pair in [["Resume", resume], ["Save Game", _save], ["Settings", _open_settings], ["How to Play", _open_help], ["Save & Quit to Menu", _quit]]:
		var b := UITheme.button(pair[0], 320)
		b.pressed.connect(pair[1])
		v.add_child(b)
		if pair[0] == "Save Game":
			_save_btn = b

	_help = PanelContainer.new()
	_help.custom_minimum_size = Vector2(760, 520)
	_help.hide()
	center.add_child(_help)
	var hv := VBoxContainer.new()
	_help.add_child(hv)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_size_override("normal_font_size", 18)
	rt.add_theme_font_size_override("bold_font_size", 18)
	rt.text = UITheme.how_to_play_text()
	rt.set_meta("help", true)
	hv.add_child(rt)
	var back := UITheme.button("Back", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_back)
	hv.add_child(back)

	_settings = SettingsMenu.new()
	_settings.hide()
	_settings.closed.connect(_back)
	root.add_child(_settings)
	Audio.hook_buttons(root)
	hide()


func open() -> void:
	show()
	_panel.show()
	_save_btn.text = "Save Game"
	_help.hide()
	_settings.hide()
	get_tree().paused = true
	Input.set_custom_mouse_cursor(null)
	Settings.set_muffled(true)


func resume() -> void:
	hide()
	get_tree().paused = false
	Settings.set_muffled(false)
	resumed.emit()


func _open_settings() -> void:
	_panel.hide()
	_settings.open()


func _open_help() -> void:
	_panel.hide()
	(_help.get_child(0).get_child(0) as RichTextLabel).text = UITheme.how_to_play_text()
	_help.show()


func _back() -> void:
	_settings.hide()
	_help.hide()
	_panel.show()


func _save() -> void:
	if game and game.save_game(false):
		_save_btn.text = "Saved to slot %d" % (SaveManager.current_slot + 1)
		Audio.play("craft", -8)
	else:
		_save_btn.text = "Saving failed"


func _quit() -> void:
	if game:
		game.save_game(false)
	Settings.set_muffled(false)
	Audio.stop_music(0.8)
	Audio.stop_all_ambience(0.8)
	Fader.change_scene("res://scenes/main_menu.tscn", 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if _help.visible:
		_back()
	elif _panel.visible:
		resume()
