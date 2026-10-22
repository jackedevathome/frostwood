class_name SkillWindow
extends Control
## Skill tree: three branches of skills bought with points earned by levelling up.

var game: Node
var player: Player
var hovered := ""
var _header: Control
var _branches: Array = []
var _desc: RichTextLabel


## A clickable skill node.
class SkillNode extends Control:
	var win: SkillWindow
	var id := ""
	var color := Color.WHITE

	func _ready() -> void:
		custom_minimum_size = Vector2(70, 70)
		size = Vector2(70, 70)
		mouse_entered.connect(func(): win.hovered = id)
		mouse_exited.connect(_on_exit)

	func _on_exit() -> void:
		if win.hovered == id:
			win.hovered = ""

	func _draw() -> void:
		var p := win.player
		var d: Dictionary = Skills.DATA[id]
		var rank := p.skill(id)
		var c := size / 2
		var unlocked: bool = d.req == "" or p.skill(d.req) > 0
		var learnable := p.can_learn(id)
		var bg := Color(0.08, 0.1, 0.14)
		if rank > 0:
			bg = color.darkened(0.55)
		var border := Color(0.35, 0.4, 0.45)
		if rank >= d.max:
			border = color.lightened(0.2)
		elif learnable:
			border = Color(1.0, 0.85, 0.4, 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.006))
		elif rank > 0:
			border = color
		if win.hovered == id:
			draw_circle(c, 34, Color(1, 1, 1, 0.08))
		draw_circle(c, 29, bg)
		draw_arc(c, 29, 0, TAU, 36, border, 3.0, true)
		Items.draw_icon(self, d.icon, c, 16.0, 1.0 if unlocked else 0.35)
		# rank pips
		var n: int = d.max
		for i in n:
			var px := c + Vector2((i - (n - 1) / 2.0) * 11.0, 34)
			draw_circle(px, 4, Color(0.05, 0.07, 0.1))
			draw_circle(px, 3, color if i < rank else Color(0.3, 0.33, 0.38))

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			win.try_learn(id)


func setup(g: Node) -> void:
	game = g
	player = g.player
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.6)
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
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	_header = Control.new()
	_header.custom_minimum_size = Vector2(1000, 64)
	_header.draw.connect(_draw_header)
	v.add_child(_header)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	for br in Skills.BRANCHES:
		var col := Control.new()
		col.custom_minimum_size = Vector2(320, 330)
		col.set_meta("branch", br)
		col.draw.connect(_draw_branch.bind(col))
		h.add_child(col)
		_branches.append(col)
		for id in Skills.DATA:
			var d: Dictionary = Skills.DATA[id]
			if d.branch != br.id:
				continue
			var node := SkillNode.new()
			node.win = self
			node.id = id
			node.color = br.color
			node.position = _node_pos(d) - Vector2(35, 35)
			col.add_child(node)

	_desc = RichTextLabel.new()
	_desc.bbcode_enabled = true
	_desc.fit_content = true
	_desc.custom_minimum_size = Vector2(1000, 76)
	_desc.add_theme_font_size_override("normal_font_size", 17)
	_desc.add_theme_font_size_override("bold_font_size", 19)
	_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_desc)
	hide()


func _node_pos(d: Dictionary) -> Vector2:
	return Vector2(70 + d.col * 180.0, 90 + d.row * 100.0)


func open() -> void:
	show()


func _process(_delta: float) -> void:
	if not visible:
		return
	_header.queue_redraw()
	for b in _branches:
		b.queue_redraw()
		for n in b.get_children():
			n.queue_redraw()
	_update_desc()


func _draw_header() -> void:
	var c := _header
	HUD.text(c, Vector2(0, 30), "Skill Tree", 30, UITheme.ACCENT)
	HUD.text(c, Vector2(0, 30), "Level %d" % player.level, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, c.size.x)
	var pts_col := Color(1.0, 0.85, 0.4) if player.skill_points > 0 else UITheme.MUTED
	HUD.text(c, Vector2(0, 30), "Skill points: %d" % player.skill_points, 22, pts_col, HORIZONTAL_ALIGNMENT_RIGHT, c.size.x)
	var need := Skills.xp_to_next(player.level)
	var r := Rect2(0, 44, c.size.x, 12)
	c.draw_rect(r, Color(0.08, 0.1, 0.13))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x * float(player.xp) / need, r.size.y)), Color(0.72, 0.55, 1.0))
	c.draw_rect(r, Color(0, 0, 0, 0.6), false, 1.0)
	HUD.text(c, Vector2(0, 55), "%d / %d XP" % [player.xp, need], 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, c.size.x)


func _draw_branch(col: Control) -> void:
	var br: Dictionary = col.get_meta("branch")
	col.draw_style_box(UITheme.box(Color(0.05, 0.07, 0.1, 0.7), Color(br.color, 0.35), 1, 10, 0), Rect2(Vector2.ZERO, col.size))
	HUD.text(col, Vector2(0, 30), br.name, 22, br.color, HORIZONTAL_ALIGNMENT_CENTER, col.size.x)
	for id in Skills.DATA:
		var d: Dictionary = Skills.DATA[id]
		if d.branch != br.id or d.req == "":
			continue
		var a := _node_pos(Skills.DATA[d.req])
		var b := _node_pos(d)
		var lit := player.skill(d.req) > 0
		col.draw_line(a, b, Color(br.color, 0.8) if lit else Color(0.3, 0.34, 0.4), 4.0 if lit else 3.0, true)


func _update_desc() -> void:
	if hovered == "":
		_desc.text = "[color=#9fb2c4]Earn XP by gathering, hunting, crafting and surviving nights. Each level grants a skill point.\nHover a skill to read about it, click to learn it. Close with %s or Esc.[/color]" % Settings.key_name("skills")
		return
	var d: Dictionary = Skills.DATA[hovered]
	var rank := player.skill(hovered)
	var status := ""
	if rank >= d.max:
		status = "[color=#9be37f]Mastered[/color]"
	elif d.req != "" and player.skill(d.req) == 0:
		status = "[color=#e57373]Requires %s[/color]" % Skills.DATA[d.req].name
	elif player.skill_points == 0:
		status = "[color=#9fb2c4]No skill points — level up to learn[/color]"
	else:
		status = "[color=#f8d162]Click to learn[/color]"
	_desc.text = "[b]%s[/b]   rank %d / %d   %s\n%s" % [d.name, rank, d.max, status, d.desc]


func try_learn(id: String) -> void:
	if player.learn(id):
		Audio.play("craft", -4)
		Audio.play("level_up", -12, 0.0)
		game.message("Learned %s (rank %d)" % [Skills.DATA[id].name, player.skill(id)], Color(0.8, 0.7, 1.0))
	else:
		Audio.play("ui_hover", -2)
