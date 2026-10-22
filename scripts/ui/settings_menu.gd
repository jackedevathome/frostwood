class_name SettingsMenu
extends PanelContainer
## Tabbed settings panel (Audio / Video / Gameplay / Controls). Used by main menu and pause menu.

signal closed

var _rebinding := ""
var _bind_buttons := {}
var _tabs: TabContainer


func _ready() -> void:
	theme = UITheme.get_theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(720, 520)
	set_anchors_preset(Control.PRESET_CENTER)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var title := UITheme.label("Settings", 34, UITheme.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", 19)
	root.add_child(_tabs)

	_build_audio()
	_build_video()
	_build_gameplay()
	_build_controls()

	var back := UITheme.button("Back", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	root.add_child(back)
	Audio.hook_buttons(self)
	_tabs.tab_changed.connect(func(_i): Audio.play("ui_click", -8))


func open() -> void:
	show()
	_refresh_bindings()
	await get_tree().process_frame
	position = (get_viewport_rect().size - size) / 2.0


func close() -> void:
	_rebinding = ""
	Settings.save_settings()
	hide()
	closed.emit()


func _page(page_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = page_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 16)
	scroll.add_child(v)
	return v


func _row(parent: Control, text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := UITheme.label(text, 20)
	l.custom_minimum_size.x = 260
	h.add_child(l)
	parent.add_child(h)
	return h


func _slider(parent: Control, text: String, value: float, on_change: Callable, as_percent := true) -> HSlider:
	var h := _row(parent, text)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 1
	s.step = 0.01
	s.value = value
	s.custom_minimum_size = Vector2(300, 28)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(s)
	var val := UITheme.label("", 18, UITheme.MUTED)
	val.custom_minimum_size.x = 56
	h.add_child(val)
	var update := func(v: float):
		val.text = ("%d%%" % roundi(v * 100)) if as_percent else ("%.2f" % v)
	update.call(value)
	s.value_changed.connect(func(v: float):
		update.call(v)
		on_change.call(v)
		Settings.apply())
	return s


func _check(parent: Control, text: String, value: bool, on_change: Callable) -> CheckButton:
	var h := _row(parent, text)
	var c := CheckButton.new()
	c.button_pressed = value
	c.toggled.connect(func(on: bool):
		on_change.call(on)
		Settings.apply()
		Settings.save_settings())
	h.add_child(c)
	return c


func _build_audio() -> void:
	var p := _page("Audio")
	_slider(p, "Master Volume", Settings.master_volume, func(v): Settings.master_volume = v)
	var music := _slider(p, "Music", Settings.music_volume, func(v): Settings.music_volume = v)
	var sfx := _slider(p, "Sound Effects", Settings.sfx_volume, func(v): Settings.sfx_volume = v)
	_slider(p, "Ambience", Settings.ambience_volume, func(v): Settings.ambience_volume = v)
	# Preview the effects volume on release.
	sfx.drag_ended.connect(func(_c): Audio.play("chop"))
	music.drag_ended.connect(func(_c): Settings.save_settings())
	var note := UITheme.label("All music and sounds are generated for Frostwood.", 16, UITheme.MUTED)
	p.add_child(note)


func _build_video() -> void:
	var p := _page("Video")
	_check(p, "Fullscreen", Settings.fullscreen, func(on): Settings.fullscreen = on)
	_check(p, "VSync", Settings.vsync, func(on): Settings.vsync = on)
	_check(p, "Show FPS", Settings.show_fps, func(on): Settings.show_fps = on)
	_check(p, "Screen Shake", Settings.screen_shake, func(on): Settings.screen_shake = on)
	_slider(p, "Night Brightness", Settings.night_brightness, func(v): Settings.night_brightness = v)


func _build_gameplay() -> void:
	var p := _page("Gameplay")
	var h := _row(p, "Difficulty")
	var opt := OptionButton.new()
	for d in Settings.DIFFICULTY_NAMES:
		opt.add_item(d)
	opt.selected = Settings.difficulty
	opt.custom_minimum_size.x = 200
	opt.item_selected.connect(func(i):
		Settings.difficulty = i
		Settings.save_settings())
	h.add_child(opt)
	var desc := UITheme.label("Difficulty changes how fast hunger and cold drain,\nand how hard wolves bite.", 16, UITheme.MUTED)
	p.add_child(desc)
	_check(p, "Show Damage Numbers", Settings.damage_numbers, func(on): Settings.damage_numbers = on)
	var best := UITheme.label("Longest survival: %d day(s)" % Settings.best_days, 18, UITheme.WARM)
	p.add_child(best)


func _build_controls() -> void:
	var p := _page("Controls")
	var info := UITheme.label("Click a key to rebind it, then press the new key (Esc cancels).", 16, UITheme.MUTED)
	p.add_child(info)
	for action in Settings.KEY_ACTIONS:
		var h := _row(p, Settings.ACTION_LABELS[action])
		var b := Button.new()
		b.custom_minimum_size = Vector2(200, 40)
		b.pressed.connect(_start_rebind.bind(action))
		h.add_child(b)
		_bind_buttons[action] = b
	var fixed := UITheme.label("Mouse: aim  •  Left click: use item  •  Right click: quick-eat\n1-3 / wheel: select hotbar slot  •  Esc: pause", 16, UITheme.MUTED)
	p.add_child(fixed)
	var reset := UITheme.button("Reset to Defaults", 240)
	reset.pressed.connect(func():
		Settings.reset_bindings()
		_refresh_bindings())
	p.add_child(reset)
	_refresh_bindings()


func _refresh_bindings() -> void:
	for action in _bind_buttons:
		_bind_buttons[action].text = "..." if action == _rebinding else Settings.key_name(action)


func _start_rebind(action: String) -> void:
	_rebinding = action
	_refresh_bindings()


func _input(event: InputEvent) -> void:
	if _rebinding == "" or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.physical_keycode != KEY_ESCAPE:
			Settings.rebind(_rebinding, event.physical_keycode)
			Audio.play("ui_click")
		_rebinding = ""
		_refresh_bindings()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _rebinding == "" and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
