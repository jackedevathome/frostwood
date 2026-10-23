class_name JournalWindow
extends Control
## Journal: survival goals with progress and XP rewards, plus a few run statistics.

var game: Node
var _list: Control


func setup(g: Node) -> void:
	game = g
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var title := UITheme.heading("Journal", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	v.add_child(UITheme.ornament(360))
	_list = Control.new()
	_list.custom_minimum_size = Vector2(820, Journal.GOALS.size() / 2.0 * 50 + 70)
	_list.draw.connect(_draw_list)
	v.add_child(_list)
	var hint := UITheme.label("", 15, UITheme.MUTED)
	hint.name = "Hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	hide()


func open() -> void:
	show()
	(find_child("Hint", true, false) as Label).text = "%s / Esc to close" % Settings.key_name("journal")


func _process(_delta: float) -> void:
	if visible:
		_list.queue_redraw()


func _draw_list() -> void:
	var c := _list
	var done: int = game.goals_done.size()
	HUD.text(c, Vector2(0, 20), "Goals completed: %d / %d" % [done, Journal.GOALS.size()], 17, UITheme.GOLD)
	HUD.text(c, Vector2(0, 20), "Day %d  ·  Wolves %d  ·  Bears %d  ·  Fish %d" % [game.day, game.stats.get("kill_wolf", 0),
		game.stats.get("kill_bear", 0), game.stats.get("fish", 0)], 15, UITheme.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, c.size.x)
	var col_w := (c.size.x - 16) / 2.0
	for i in Journal.GOALS.size():
		var g: Dictionary = Journal.GOALS[i]
		var r := Rect2((i % 2) * (col_w + 16), 34 + (i / 2) * 50, col_w, 44)
		var is_done: bool = g.id in game.goals_done
		var sb := UITheme.box(Color(0.1, 0.16, 0.12, 0.85) if is_done else Color(0.06, 0.08, 0.11, 0.85),
			Color(0.5, 0.8, 0.5, 0.5) if is_done else Color(0.42, 0.55, 0.66, 0.35), 1, 8, 0)
		c.draw_style_box(sb, r)
		var box_c := r.position + Vector2(20, 22)
		c.draw_rect(Rect2(box_c - Vector2(8, 8), Vector2(16, 16)), Color(0.03, 0.04, 0.06), true)
		c.draw_rect(Rect2(box_c - Vector2(8, 8), Vector2(16, 16)), Color(0.6, 0.7, 0.8, 0.6), false, 1.5)
		if is_done:
			c.draw_polyline(PackedVector2Array([box_c + Vector2(-5, 0), box_c + Vector2(-1, 4), box_c + Vector2(6, -5)]), Color(0.6, 1.0, 0.6), 2.5, true)
		HUD.text(c, r.position + Vector2(38, 27), g.text, 16, Color(0.75, 0.85, 0.75) if is_done else UITheme.TEXT)
		var right := "+%d XP" % g.xp
		if not is_done and g.target > 1:
			right = "%d/%d   %s" % [game.goal_progress(g), g.target, right]
		HUD.text(c, r.position + Vector2(0, 27), right, 14, UITheme.GOLD if not is_done else Color(0.55, 0.7, 0.55), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 12)
