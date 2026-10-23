extends Control
## Title screen: Continue, New Game, Load Game, How to Play, Settings, Credits, Quit.

var _menu: VBoxContainer
var _buttons: VBoxContainer
var _settings: SettingsMenu
var _info_panel: PanelContainer
var _info_text: RichTextLabel
var _info_title: Label
var _slots_panel: PanelContainer
var _slots_title: Label
var _slots_list: VBoxContainer
var _confirm_panel: PanelContainer
var _confirm_text: Label
var _confirm_ok: Button
var _confirm_cb: Callable
var _title: Label
var _t := 0.0
var _mode := "new"


func _ready() -> void:
	theme = UITheme.get_theme()
	Input.set_custom_mouse_cursor(null)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg := MenuBackground.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_menu = VBoxContainer.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_theme_constant_override("separation", 4)
	add_child(_menu)

	_title = UITheme.heading("FROSTWOOD", 100, Color(0.93, 0.96, 1.0))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_constant_override("outline_size", 12)
	_title.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.13, 0.95))
	_title.add_theme_color_override("font_shadow_color", Color(0.3, 0.9, 0.7, 0.35))
	_title.add_theme_constant_override("shadow_offset_y", 6)
	_title.add_theme_constant_override("shadow_outline_size", 22)
	_menu.add_child(_title)
	_menu.add_child(UITheme.ornament(420))
	var sub := UITheme.label("A Nordic Survival", 24, UITheme.GOLD)
	sub.add_theme_font_override("font", UITheme.font_head())
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 26
	_menu.add_child(spacer)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 10)
	_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu.add_child(_buttons)
	var latest := SaveManager.latest_slot()
	if latest >= 0:
		var sm := SaveManager.summary(latest)
		_add_button("Continue  ·  Day %d" % sm.day, _on_continue.bind(latest))
	_add_button("New Game", _open_slots.bind("new"))
	if SaveManager.any_saves():
		_add_button("Load Game", _open_slots.bind("load"))
	_add_button("How to Play", _show_info.bind("How to Play", UITheme.how_to_play_text()))
	_add_button("Settings", _on_settings)
	_add_button("Credits", _show_info.bind("Credits", _credits_text()))
	if OS.get_name() != "Web":
		_add_button("Quit", func(): get_tree().quit())

	if Settings.best_days > 0:
		var best := UITheme.label("Longest survival: %d day%s" % [Settings.best_days, "" if Settings.best_days == 1 else "s"], 18, UITheme.WARM)
		best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_menu.add_child(best)

	var ver := UITheme.label("v1.2  •  Made with Godot 4", 15, UITheme.MUTED)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.anchor_left = 1
	ver.anchor_right = 1
	ver.anchor_top = 1
	ver.anchor_bottom = 1
	ver.offset_left = -320
	ver.offset_right = -16
	ver.offset_top = -34
	ver.offset_bottom = -10
	add_child(ver)

	_build_info_panel()
	_build_slots_panel()
	_build_confirm_panel()
	_settings = SettingsMenu.new()
	_settings.hide()
	_settings.closed.connect(_back_to_menu)
	add_child(_settings)

	Audio.hook_buttons(self)
	Audio.play_music("music_menu", 1.5)
	Audio.stop_all_ambience()
	Audio.set_ambience("amb_wind", -14, 2.0)

	_menu.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(_menu, "modulate:a", 1.0, 1.2)


func _process(delta: float) -> void:
	_t += delta
	_title.add_theme_color_override("font_shadow_color", Color(0.3, 0.9, 0.7, 0.25 + 0.15 * sin(_t * 1.3)))


func _add_button(text: String, cb: Callable) -> void:
	var b := UITheme.button(text, 320)
	b.pressed.connect(cb)
	_buttons.add_child(b)


func _centered_panel(min_size: Vector2) -> PanelContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var p := PanelContainer.new()
	p.custom_minimum_size = min_size
	p.hide()
	center.add_child(p)
	return p


func _build_info_panel() -> void:
	_info_panel = _centered_panel(Vector2(780, 560))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_info_panel.add_child(v)
	_info_title = UITheme.heading("", 34)
	_info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info_title)
	v.add_child(UITheme.ornament(360))
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_text.add_theme_font_size_override("normal_font_size", 20)
	_info_text.add_theme_font_size_override("bold_font_size", 20)
	v.add_child(_info_text)
	var back := UITheme.button("Back", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_back_to_menu)
	v.add_child(back)


# ---------------------------------------------------------------- save slots
func _build_slots_panel() -> void:
	_slots_panel = _centered_panel(Vector2(680, 0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_slots_panel.add_child(v)
	_slots_title = UITheme.heading("", 34)
	_slots_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_slots_title)
	v.add_child(UITheme.ornament(360))
	_slots_list = VBoxContainer.new()
	_slots_list.add_theme_constant_override("separation", 10)
	v.add_child(_slots_list)
	var back := UITheme.button("Back", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_back_to_menu)
	v.add_child(back)


func _open_slots(mode: String) -> void:
	_mode = mode
	_slots_title.text = "Choose a Save Slot" if mode == "new" else "Load Game"
	for c in _slots_list.get_children():
		c.queue_free()
	for i in SaveManager.SLOTS:
		var sm := SaveManager.summary(i)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_slots_list.add_child(row)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(520, 72)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if sm.is_empty():
			b.text = "   Slot %d   —   Empty" % (i + 1)
			b.disabled = mode == "load"
		else:
			b.text = "   Slot %d   —   Day %d  ·  Level %d  ·  %s\n   %s played  ·  saved %s" % [i + 1, sm.day, sm.level,
				Settings.DIFFICULTY_NAMES[clampi(sm.difficulty, 0, 2)], SaveManager.format_time(sm.play_time), SaveManager.format_date(sm.saved_at)]
		b.pressed.connect(_slot_pressed.bind(i))
		row.add_child(b)
		if not sm.is_empty():
			var del := UITheme.button("Delete", 110)
			del.custom_minimum_size.y = 72
			del.add_theme_font_size_override("font_size", 17)
			del.add_theme_color_override("font_color", Color(1.0, 0.65, 0.6))
			del.pressed.connect(_confirm.bind("Delete the save in slot %d?\nThis cannot be undone." % (i + 1), "Delete", _delete_slot.bind(i)))
			row.add_child(del)
	Audio.hook_buttons(_slots_list)
	_menu.hide()
	_slots_panel.show()


func _slot_pressed(i: int) -> void:
	if _mode == "load":
		if SaveManager.start_load(i):
			_launch()
	elif SaveManager.exists(i):
		var sm := SaveManager.summary(i)
		_confirm("Overwrite slot %d (Day %d, Level %d)?\nThat survivor's progress will be lost." % [i + 1, sm.day, sm.level], "Overwrite", _new_in_slot.bind(i))
	else:
		_new_in_slot(i)


func _new_in_slot(i: int) -> void:
	SaveManager.start_new(i)
	_launch()


func _delete_slot(i: int) -> void:
	SaveManager.delete(i)
	if not SaveManager.any_saves():
		get_tree().reload_current_scene()
		return
	_open_slots(_mode)


func _on_continue(slot: int) -> void:
	if SaveManager.start_load(slot):
		_launch()


func _launch() -> void:
	Audio.stop_music(1.0)
	Fader.change_scene("res://scenes/game.tscn", 0.8)


# ---------------------------------------------------------------- confirm dialog
func _build_confirm_panel() -> void:
	_confirm_panel = _centered_panel(Vector2(520, 0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	_confirm_panel.add_child(v)
	_confirm_text = UITheme.label("", 22)
	_confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_confirm_text)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 16)
	v.add_child(h)
	_confirm_ok = UITheme.button("OK", 180)
	_confirm_ok.add_theme_color_override("font_color", Color(1.0, 0.7, 0.62))
	_confirm_ok.pressed.connect(func():
		_confirm_panel.hide()
		_confirm_cb.call())
	h.add_child(_confirm_ok)
	var cancel := UITheme.button("Cancel", 180)
	cancel.pressed.connect(func():
		_confirm_panel.hide()
		_slots_panel.show())
	h.add_child(cancel)


func _confirm(text: String, ok_label: String, cb: Callable) -> void:
	_confirm_text.text = text
	_confirm_ok.text = ok_label
	_confirm_cb = cb
	_slots_panel.hide()
	_confirm_panel.show()


# ---------------------------------------------------------------- other panels
func _show_info(title: String, text: String) -> void:
	_info_title.text = title
	_info_text.text = text
	_menu.hide()
	_info_panel.show()


func _on_settings() -> void:
	_menu.hide()
	_settings.open()


func _back_to_menu() -> void:
	_info_panel.hide()
	_slots_panel.hide()
	_confirm_panel.hide()
	_settings.hide()
	_menu.show()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _menu.visible and not _settings.visible:
		_back_to_menu()


func _credits_text() -> String:
	return "[center][b]FROSTWOOD[/b]\n\nA small survival game set in the snowy pine and spruce forests of the North.\n\n" + \
		"[color=#94d1f5]Design, code & procedural art[/color]\nMade with Godot Engine 4\n\n" + \
		"[color=#94d1f5]Music & sound[/color]\nAll audio is synthesised from scratch by tools/generate_audio.py:\nkantele-style plucked strings, drones, birch-bark horn, frame drum,\nwind, birdsong, fire crackle and snow footsteps.\n\n" + \
		"[color=#94d1f5]Fonts[/color]\nCinzel and Alegreya Sans, SIL Open Font License\n\n" + \
		"[color=#f8b862]Thanks for playing — stay warm.[/color][/center]"
