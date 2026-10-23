class_name HUD
extends CanvasLayer
## In-game interface: stats + XP, minimap + clock, 3-slot hotbar, messages and overlays.
## Also owns the inventory and skill windows.

var game: Node
var player: Player
var inventory: InventoryWindow
var skills: SkillWindow
var _root: Control
var _stats: Control
var _hotbar: Control
var _minimap: Minimap
var _keys: Label
var _messages: VBoxContainer
var _hint: Label
var _banner: Label
var _fps: Label
var _cold_overlay: TextureRect
var _hurt_overlay: TextureRect
var _hurt := 0.0

const SLOT := 72.0
const GAP := 8.0


func setup(g: Node) -> void:
	game = g
	player = g.player
	layer = 5
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.get_theme()
	add_child(_root)

	_cold_overlay = _vignette(Color(0.6, 0.85, 1.0))
	_hurt_overlay = _vignette(Color(0.8, 0.05, 0.05))

	_stats = _draw_control(_draw_stats, Vector2(16, 16), Vector2(280, 168))

	_minimap = Minimap.new()
	_minimap.game = g
	_minimap.size = Vector2(200, 236)
	_root.add_child(_minimap)
	_place(_minimap, Vector2(1, 0), Vector2(-216, 16))

	_hotbar = _draw_control(_draw_hotbar, Vector2.ZERO, Vector2(SLOT * 3 + GAP * 2, 104))
	_place(_hotbar, Vector2(0.5, 1), Vector2(-(SLOT * 3 + GAP * 2) / 2.0, -116))
	_hotbar.mouse_filter = Control.MOUSE_FILTER_STOP
	_hotbar.gui_input.connect(_hotbar_input)

	_messages = VBoxContainer.new()
	_messages.custom_minimum_size = Vector2(420, 240)
	_messages.size = Vector2(420, 240)
	_place(_messages, Vector2(0, 1), Vector2(16, -260))
	_messages.alignment = BoxContainer.ALIGNMENT_END
	_messages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_messages)

	_hint = UITheme.label("", 19, UITheme.WARM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.size = Vector2(700, 30)
	_place(_hint, Vector2(0.5, 1), Vector2(-350, -152))
	_root.add_child(_hint)

	_banner = UITheme.label("", 54, Color(0.95, 0.97, 1.0))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.size = Vector2(900, 80)
	_place(_banner, Vector2(0.5, 0), Vector2(-450, 140))
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.modulate.a = 0
	_root.add_child(_banner)

	_keys = UITheme.label("", 15, UITheme.MUTED)
	_keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_keys.size = Vector2(420, 24)
	_place(_keys, Vector2(1, 1), Vector2(-436, -34))
	_root.add_child(_keys)

	_fps = UITheme.label("", 16, UITheme.MUTED)
	_fps.size = Vector2(80, 24)
	_place(_fps, Vector2(1, 1), Vector2(-90, -60))
	_root.add_child(_fps)

	inventory = InventoryWindow.new()
	inventory.setup(g)
	_root.add_child(inventory)
	skills = SkillWindow.new()
	skills.setup(g)
	_root.add_child(skills)


func _place(c: Control, anchor: Vector2, off: Vector2) -> void:
	var sz := c.size
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = off.x
	c.offset_top = off.y
	c.offset_right = off.x + sz.x
	c.offset_bottom = off.y + sz.y


func _vignette(col: Color) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(col, 0.0))
	g.set_color(1, Color(col, 0.85))
	g.add_point(0.55, Color(col, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 1.0)
	gt.width = 256
	gt.height = 256
	var tr := TextureRect.new()
	tr.texture = gt
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate.a = 0
	_root.add_child(tr)
	return tr


func _draw_control(fn: Callable, pos: Vector2, sz: Vector2) -> Control:
	var c := Control.new()
	c.position = pos
	c.size = sz
	c.custom_minimum_size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(fn.bind(c))
	_root.add_child(c)
	return c


static func text(c: CanvasItem, pos: Vector2, s: String, size := 16, col := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := UITheme.font_bold()
	c.draw_string_outline(f, pos, s, align, width, size, 4, Color(0.02, 0.03, 0.05, 0.85))
	c.draw_string(f, pos, s, align, width, size, col)


static func text_head(c: CanvasItem, pos: Vector2, s: String, size := 16, col := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := UITheme.font_head()
	c.draw_string_outline(f, pos, s, align, width, size, 4, Color(0.02, 0.03, 0.05, 0.85))
	c.draw_string(f, pos, s, align, width, size, col)


func _process(delta: float) -> void:
	_stats.queue_redraw()
	_hotbar.queue_redraw()
	_minimap.queue_redraw()
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()
	_keys.text = "[%s] Inventory    [%s] Skills    [%s] Map" % [Settings.key_name("inventory"), Settings.key_name("skills"), Settings.key_name("map")]
	var cold := clampf(1.0 - player.warmth / 35.0, 0.0, 1.0)
	_cold_overlay.modulate.a = lerpf(_cold_overlay.modulate.a, cold * 0.75, 1.0 - exp(-delta * 3))
	_hurt = maxf(0.0, _hurt - delta * 2.0)
	var low := clampf(1.0 - player.health / 30.0, 0.0, 1.0) * (0.25 + 0.15 * sin(Time.get_ticks_msec() * 0.006))
	_hurt_overlay.modulate.a = maxf(_hurt, low)
	_hint.text = game.interaction_hint()


# ---------------------------------------------------------------- windows
func any_window_open() -> bool:
	return inventory.visible or skills.visible


func toggle_window(which: String) -> void:
	var w: Control = inventory if which != "skills" else skills
	var other: Control = skills if w == inventory else inventory
	var opening := not w.visible
	other.hide()
	if opening:
		w.open()
		if which == "craft":
			inventory.focus_crafting()
		Audio.play("page", -4)
		Input.set_custom_mouse_cursor(null)
	else:
		close_windows()


func close_windows() -> void:
	if any_window_open():
		Audio.play("page", -6)
	inventory.hide()
	skills.hide()
	game.restore_cursor()


func flash_damage() -> void:
	_hurt = 0.7


func show_banner(t: String, col := Color(0.95, 0.97, 1.0)) -> void:
	_banner.text = t
	_banner.add_theme_color_override("font_color", col)
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.8)
	tw.tween_interval(2.2)
	tw.tween_property(_banner, "modulate:a", 0.0, 1.2)


func message(t: String, col := Color(0.92, 0.95, 0.98)) -> void:
	# merge repeated pickups ("+1 Wood" x3 -> "+3 Wood")
	if t.begins_with("+") and _messages.get_child_count() > 0:
		var last: Label = _messages.get_child(_messages.get_child_count() - 1)
		var parts := t.split(" ", false, 1)
		var lparts := last.text.split(" ", false, 1)
		if parts.size() == 2 and lparts.size() == 2 and parts[1] == lparts[1] and last.modulate.a > 0.5:
			last.text = "+%d %s" % [int(lparts[0].substr(1)) + int(parts[0].substr(1)), parts[1]]
			_restart_fade(last)
			return
	var l := UITheme.label(t, 18, col)
	var pill := UITheme.box(Color(0.03, 0.045, 0.065, 0.6), Color(0, 0, 0, 0), 0, 8, 2)
	pill.content_margin_left = 10
	pill.content_margin_right = 10
	l.add_theme_stylebox_override("normal", pill)
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_messages.add_child(l)
	_restart_fade(l)
	while _messages.get_child_count() > 7:
		var c := _messages.get_child(0)
		_messages.remove_child(c)
		c.queue_free()


func _restart_fade(l: Label) -> void:
	if l.has_meta("tw"):
		var old: Tween = l.get_meta("tw")
		if old and old.is_valid():
			old.kill()
	l.modulate.a = 1.0
	var tw := l.create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(l.queue_free)
	l.set_meta("tw", tw)


# ---------------------------------------------------------------- stat bars + xp
static var _hud_panel: StyleBoxFlat


## Shared style for the small HUD panels.
static func hud_panel() -> StyleBoxFlat:
	if _hud_panel == null:
		_hud_panel = UITheme.box(Color(0.045, 0.06, 0.085, 0.86), Color(0.5, 0.64, 0.76, 0.32), 1, 12, 0)
		_hud_panel.shadow_color = Color(0, 0, 0, 0.3)
		_hud_panel.shadow_size = 8
		_hud_panel.shadow_offset = Vector2(0, 3)
	return _hud_panel


## Rounded bar with a dark track, coloured fill and a soft highlight.
static func bar(c: CanvasItem, r: Rect2, frac: float, col: Color) -> void:
	var rad := int(r.size.y / 2)
	var track := UITheme.box(Color(0.03, 0.04, 0.06, 0.95), Color(0, 0, 0, 0.5), 1, rad, 0)
	c.draw_style_box(track, r)
	frac = clampf(frac, 0.0, 1.0)
	if frac <= 0.0:
		return
	var w := maxf(r.size.x * frac, r.size.y)
	var fill := UITheme.box(col.darkened(0.12), Color(0, 0, 0, 0), 0, rad, 0)
	c.draw_style_box(fill, Rect2(r.position, Vector2(w, r.size.y)))
	var hi := UITheme.box(Color(1, 1, 1, 0.16), Color(0, 0, 0, 0), 0, rad, 0)
	c.draw_style_box(hi, Rect2(r.position + Vector2(2, 1.5), Vector2(maxf(w - 4, 0), r.size.y * 0.4)))
func _draw_stats(c: Control) -> void:
	var bars := [
		["Health", player.health, player.max_health, Color(0.86, 0.22, 0.24), "heart"],
		["Hunger", player.hunger, 100.0, Color(0.92, 0.6, 0.25), "cooked_meat"],
		["Warmth", player.warmth, 100.0, Color(0.45, 0.78, 1.0) if player.heat <= 0 else Color(1.0, 0.55, 0.25), "flame" if player.warmth > 40 or player.heat > 0 else "snow"],
		["Stamina", player.stamina, 100.0, Color(0.9, 0.86, 0.35), "bolt"],
	]
	c.draw_style_box(hud_panel(), Rect2(Vector2.ZERO, c.size))
	for i in bars.size():
		var b: Array = bars[i]
		var y := 14.0 + i * 28.0
		var col: Color = b[3]
		# icon badge
		c.draw_circle(Vector2(22, y + 8), 11.5, Color(0.03, 0.045, 0.065))
		c.draw_arc(Vector2(22, y + 8), 11.5, 0, TAU, 24, Color(col, 0.55), 1.5, true)
		Items.draw_icon(c, b[4], Vector2(22, y + 8), 7.5)
		var r := Rect2(42, y + 1, 222, 15)
		var frac: float = clampf(b[1] / b[2], 0.0, 1.0)
		if frac < 0.25 and int(Time.get_ticks_msec() / 300) % 2 == 0:
			col = col.lightened(0.35)
		bar(c, r, frac, col)
		var label := "%s  %d" % [b[0], roundi(b[1])]
		if i == 0 and player.max_health > 100:
			label += " / %d" % roundi(player.max_health)
		text(c, Vector2(50, y + 13), label, 14, Color(1, 1, 1, 0.95))
	# XP
	var need := Skills.xp_to_next(player.level)
	bar(c, Rect2(42, 131, 222, 9), float(player.xp) / need, Color(0.72, 0.55, 1.0))
	c.draw_circle(Vector2(22, 134), 12, Color(0.3, 0.2, 0.5))
	c.draw_arc(Vector2(22, 134), 12, 0, TAU, 24, Color(0.82, 0.7, 1.0), 2, true)
	text(c, Vector2(12, 140), str(player.level), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 20)
	var line := "Level %d   %d / %d XP" % [player.level, player.xp, need]
	text(c, Vector2(40, 158), line, 13, Color(0.85, 0.8, 1.0))
	if player.skill_points > 0:
		var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.006)
		text(c, Vector2(0, 158), "+%d [%s]" % [player.skill_points, Settings.key_name("skills")], 13, Color(1.0, 0.85, 0.4, pulse), HORIZONTAL_ALIGNMENT_RIGHT, 264)


# ---------------------------------------------------------------- hotbar
func _slot_rect(i: int) -> Rect2:
	return Rect2(i * (SLOT + GAP), 28.0, SLOT, SLOT)


func _draw_hotbar(c: Control) -> void:
	var cur := player.current_item()
	var name_text := Items.item_name(cur) if cur != "" else "Empty slot"
	if player.placing:
		name_text = "Placing campfire  (Right click to cancel)"
	elif cur != "" and player.count(cur) <= 0:
		name_text += " (none left)"
	text(c, Vector2(-200, 18), name_text, 18, UITheme.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, c.size.x + 400)
	for i in Player.SLOTS:
		draw_slot(c, _slot_rect(i), player.hotbar[i], player, i == player.selected and not player.placing, str(i + 1))


## Shared slot renderer (also used by the inventory window).
static func draw_slot(c: CanvasItem, r: Rect2, id: String, p: Player, selected: bool, label := "", hovered := false) -> void:
	var bg := Color(0.11, 0.16, 0.22, 0.96) if selected else (Color(0.09, 0.12, 0.17, 0.95) if hovered else Color(0.05, 0.068, 0.095, 0.9))
	var border := UITheme.ACCENT if selected else (Color(0.65, 0.78, 0.88, 0.8) if hovered else Color(0.42, 0.55, 0.66, 0.4))
	if selected:
		for k in 3:
			var glow := UITheme.box(Color(0, 0, 0, 0), Color(UITheme.ACCENT, 0.16 - k * 0.05), 2, 12 + k * 2, 0)
			c.draw_style_box(glow, r.grow(2.0 + k * 2.0))
	var sb := UITheme.box(bg, border, 2, 10, 0)
	sb.border_width_bottom = 3
	c.draw_style_box(sb, r)
	c.draw_style_box(UITheme.box(Color(1, 1, 1, 0.035), Color(0, 0, 0, 0), 0, 8, 0), Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, r.size.y * 0.42)))
	if id != "":
		var n := p.count(id)
		Items.draw_icon(c, id, r.get_center() + Vector2(0, 2), r.size.x * 0.3, 1.0 if n > 0 else 0.3)
		if n > 1 or Items.DATA[id].kind in ["food", "place"]:
			text(c, r.position + Vector2(0, r.size.y - 6), str(n), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 6)
		if id == "bow":
			text(c, r.position + Vector2(0, r.size.y - 6), "%d" % p.count("arrow"), 13, Color(0.85, 0.85, 0.8), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 6)
	if label != "":
		c.draw_circle(r.position + Vector2(11, 11), 8, Color(0.02, 0.03, 0.05, 0.75))
		text(c, r.position + Vector2(3, 16), label, 13, UITheme.ACCENT if selected else Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 16)


func _hotbar_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for i in Player.SLOTS:
			if _slot_rect(i).has_point(ev.position):
				player.select(i)
				_hotbar.accept_event()
