class_name DeathScreen
extends CanvasLayer
## Shown when the survivor perishes.

var _root: Control
var _title: Label
var _info: Label
var _load_btn: Button


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.get_theme()
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.07, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	center.add_child(v)
	_title = UITheme.heading("You Perished", 64, Color(0.92, 0.42, 0.4))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_constant_override("outline_size", 10)
	v.add_child(_title)
	v.add_child(UITheme.ornament(420))
	_info = UITheme.label("", 22, UITheme.TEXT)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	_load_btn = UITheme.button("Load Last Save", 240)
	_load_btn.pressed.connect(func():
		if SaveManager.start_load(SaveManager.current_slot):
			Fader.change_scene("res://scenes/game.tscn", 0.6))
	h.add_child(_load_btn)
	var again := UITheme.button("New Game", 240)
	again.pressed.connect(func():
		SaveManager.start_new(SaveManager.current_slot)
		Fader.change_scene("res://scenes/game.tscn", 0.6))
	h.add_child(again)
	var menu := UITheme.button("Main Menu", 240)
	menu.pressed.connect(func():
		Audio.stop_all_ambience(0.6)
		Fader.change_scene("res://scenes/main_menu.tscn", 0.6))
	h.add_child(menu)
	Audio.hook_buttons(_root)
	hide()


func show_death(cause: String, days: int, record: bool, lvl := 1) -> void:
	var causes := {
		"cold": "The cold took you.",
		"starvation": "You starved in the wilderness.",
		"wolves": "The wolves caught your scent.",
		"bear": "A brown bear defended its ground.",
		"food poisoning": "Raw meat was your undoing.",
	}
	_info.text = "%s\n\nYou survived %d day%s and reached level %d.%s" % [causes.get(cause, "The forest claimed you."), days, "" if days == 1 else "s", lvl,
		"\nA new record!" if record else "\nLongest survival: %d" % Settings.best_days]
	_load_btn.visible = SaveManager.exists(SaveManager.current_slot)
	if _load_btn.visible:
		var sm := SaveManager.summary(SaveManager.current_slot)
		_load_btn.text = "Load Save (Day %d)" % sm.day
	show()
	_root.modulate.a = 0
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(_root, "modulate:a", 1.0, 1.5)
	Input.set_custom_mouse_cursor(null)
