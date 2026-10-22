class_name DeathScreen
extends CanvasLayer
## Shown when the survivor perishes.

var _root: Control
var _title: Label
var _info: Label


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
	_title = UITheme.label("You Perished", 64, Color(0.92, 0.4, 0.38))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_constant_override("outline_size", 10)
	v.add_child(_title)
	_info = UITheme.label("", 22, UITheme.TEXT)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	var again := UITheme.button("Try Again", 240)
	again.pressed.connect(func(): Fader.change_scene("res://scenes/game.tscn", 0.6))
	h.add_child(again)
	var menu := UITheme.button("Main Menu", 240)
	menu.pressed.connect(func():
		Audio.stop_all_ambience(0.6)
		Fader.change_scene("res://scenes/main_menu.tscn", 0.6))
	h.add_child(menu)
	Audio.hook_buttons(_root)
	hide()


func show_death(cause: String, days: int, record: bool) -> void:
	var causes := {
		"cold": "The cold took you.",
		"starvation": "You starved in the wilderness.",
		"wolves": "The wolves caught your scent.",
		"food poisoning": "Raw meat was your undoing.",
	}
	_info.text = "%s\n\nYou survived %d day%s.%s" % [causes.get(cause, "The forest claimed you."), days, "" if days == 1 else "s",
		"\nA new record!" if record else "\nLongest survival: %d" % Settings.best_days]
	show()
	_root.modulate.a = 0
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(_root, "modulate:a", 1.0, 1.5)
	Input.set_custom_mouse_cursor(null)
