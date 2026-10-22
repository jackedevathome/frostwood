class_name HUD
extends CanvasLayer
## In-game interface: stats, clock, hotbar, materials, crafting panel, messages, overlays, crosshair.

var game: Node
var player: Player
var _root: Control
var _stats: Control
var _hotbar: Control
var _clock: Control
var _mats: Control
var _messages: VBoxContainer
var _hint: Label
var _banner: Label
var _fps: Label
var _craft: PanelContainer
var _craft_rows: VBoxContainer
var _cold_overlay: TextureRect
var _hurt_overlay: TextureRect
var _hurt := 0.0
var crafting_open := false


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

	_stats = _draw_control(_draw_stats, Vector2(16, 16), Vector2(270, 130))
	_clock = _draw_control(_draw_clock, Vector2(0, 16), Vector2(170, 110))
	_place(_clock, Vector2(1, 0), Vector2(-186, 16))
	_mats = _draw_control(_draw_mats, Vector2(0, 0), Vector2(150, 150))
	_place(_mats, Vector2(1, 0), Vector2(-166, 136))

	_hotbar = _draw_control(_draw_hotbar, Vector2.ZERO, Vector2(7 * 64 + 6 * 6, 92))
	_place(_hotbar, Vector2(0.5, 1), Vector2(-(7 * 64 + 36) / 2.0, -104))
	_hotbar.mouse_filter = Control.MOUSE_FILTER_STOP
	_hotbar.gui_input.connect(_hotbar_input)

	_messages = VBoxContainer.new()
	_messages.custom_minimum_size = Vector2(420, 240)
	_messages.size = Vector2(420, 240)
	_place(_messages, Vector2(0, 1), Vector2(16, -380))
	_messages.alignment = BoxContainer.ALIGNMENT_END
	_messages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_messages)

	_hint = UITheme.label("", 19, UITheme.WARM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.size = Vector2(600, 30)
	_place(_hint, Vector2(0.5, 1), Vector2(-300, -146))
	_root.add_child(_hint)

	_banner = UITheme.label("", 54, Color(0.95, 0.97, 1.0))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.size = Vector2(800, 80)
	_place(_banner, Vector2(0.5, 0), Vector2(-400, 140))
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.modulate.a = 0
	_root.add_child(_banner)

	_fps = UITheme.label("", 16, UITheme.MUTED)
	_fps.size = Vector2(80, 24)
	_place(_fps, Vector2(1, 1), Vector2(-90, -30))
	_root.add_child(_fps)

	_build_craft_panel()


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


func _font() -> Font:
	return ThemeDB.fallback_font


func _text(c: Control, pos: Vector2, s: String, size := 16, col := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	c.draw_string_outline(_font(), pos, s, align, width, size, 4, Color(0.02, 0.03, 0.05, 0.85))
	c.draw_string(_font(), pos, s, align, width, size, col)


func _process(delta: float) -> void:
	_stats.queue_redraw()
	_clock.queue_redraw()
	_hotbar.queue_redraw()
	_mats.queue_redraw()
	_fps.visible = Settings.show_fps
	if _fps.visible:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()
	var cold := clampf(1.0 - player.warmth / 35.0, 0.0, 1.0)
	_cold_overlay.modulate.a = lerpf(_cold_overlay.modulate.a, cold * 0.75, 1.0 - exp(-delta * 3))
	_hurt = maxf(0.0, _hurt - delta * 2.0)
	var low := clampf(1.0 - player.health / 30.0, 0.0, 1.0) * (0.25 + 0.15 * sin(Time.get_ticks_msec() * 0.006))
	_hurt_overlay.modulate.a = maxf(_hurt, low)
	_hint.text = game.interaction_hint()
	if crafting_open:
		_refresh_craft()


func flash_damage() -> void:
	_hurt = 0.7


func show_banner(text: String, col := Color(0.95, 0.97, 1.0)) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", col)
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.8)
	tw.tween_interval(2.2)
	tw.tween_property(_banner, "modulate:a", 0.0, 1.2)


func message(text: String, col := Color(0.92, 0.95, 0.98)) -> void:
	# merge repeated pickups ("+1 Wood" x3 -> "+3 Wood")
	if text.begins_with("+") and _messages.get_child_count() > 0:
		var last: Label = _messages.get_child(_messages.get_child_count() - 1)
		var parts := text.split(" ", false, 1)
		var lparts := last.text.split(" ", false, 1)
		if parts.size() == 2 and lparts.size() == 2 and parts[1] == lparts[1] and last.modulate.a > 0.5:
			last.text = "+%d %s" % [int(lparts[0].substr(1)) + int(parts[0].substr(1)), parts[1]]
			last.set_meta("t", 0.0)
			_restart_fade(last)
			return
	var l := UITheme.label(text, 18, col)
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


# ---------------------------------------------------------------- stat bars
func _draw_stats(c: Control) -> void:
	var bars := [
		["Health", player.health, Color(0.86, 0.22, 0.24), "heart"],
		["Hunger", player.hunger, Color(0.92, 0.6, 0.25), "food"],
		["Warmth", player.warmth, Color(0.45, 0.78, 1.0) if player.heat <= 0 else Color(1.0, 0.55, 0.25), "flame"],
		["Stamina", player.stamina, Color(0.9, 0.86, 0.35), "bolt"],
	]
	c.draw_style_box(UITheme.box(Color(0.04, 0.06, 0.09, 0.82), Color(0.5, 0.65, 0.78, 0.35), 1, 8, 0), Rect2(Vector2.ZERO, c.size))
	for i in bars.size():
		var b: Array = bars[i]
		var y := 14.0 + i * 28.0
		_stat_icon(c, b[3], Vector2(22, y + 8), b[2])
		var r := Rect2(40, y, 210, 16)
		c.draw_rect(r, Color(0.08, 0.1, 0.13, 0.9))
		var v: float = b[1]
		var col: Color = b[2]
		if v < 25 and int(Time.get_ticks_msec() / 300) % 2 == 0:
			col = col.lightened(0.35)
		c.draw_rect(Rect2(r.position, Vector2(r.size.x * v / 100.0, r.size.y)), col)
		c.draw_rect(Rect2(r.position, Vector2(r.size.x * v / 100.0, 4)), Color(1, 1, 1, 0.18))
		c.draw_rect(r, Color(0, 0, 0, 0.6), false, 1.0)
		_text(c, Vector2(46, y + 13), "%s  %d" % [b[0], roundi(v)], 13, Color(1, 1, 1, 0.92))


func _stat_icon(c: Control, icon: String, p: Vector2, col: Color) -> void:
	match icon:
		"heart":
			c.draw_circle(p + Vector2(-3.5, -2), 4.5, col)
			c.draw_circle(p + Vector2(3.5, -2), 4.5, col)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -1), p + Vector2(8, -1), p + Vector2(0, 8)]), col)
		"food":
			Items.draw_icon(c, "cooked_meat", p, 9)
		"flame":
			if player.heat > 0 or player.warmth > 40:
				c.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 6), p + Vector2(-4, -2), p + Vector2(0, -9), p + Vector2(4, -2), p + Vector2(6, 6)]), col)
				c.draw_circle(p + Vector2(0, 3), 3, Color(1, 0.95, 0.7))
			else:
				for k in 3:
					var a := PI * k / 3.0
					var d := Vector2.from_angle(a) * 8
					c.draw_line(p - d, p + d, col, 2)
		"bolt":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(2, -9), p + Vector2(-5, 1), p + Vector2(0, 1), p + Vector2(-2, 9), p + Vector2(5, -1), p + Vector2(0, -1)]), col)


# ---------------------------------------------------------------- clock
func _draw_clock(c: Control) -> void:
	c.draw_style_box(UITheme.box(Color(0.04, 0.06, 0.09, 0.82), Color(0.5, 0.65, 0.78, 0.35), 1, 8, 0), Rect2(Vector2.ZERO, c.size))
	var center := Vector2(c.size.x / 2, 66)
	var rad := 48.0
	# sky dial
	var light: float = 1.0 - game.darkness()
	var sky := Color(0.1, 0.13, 0.25).lerp(Color(0.45, 0.65, 0.85), light)
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI + PI * i / 20.0
		pts.append(center + Vector2(cos(a), sin(a)) * rad)
	c.draw_colored_polygon(pts, sky)
	c.draw_line(center + Vector2(-rad - 4, 0), center + Vector2(rad + 4, 0), Color(0.85, 0.9, 0.95), 2)
	# sun & moon orbit: sun angle from time of day (0.25 sunrise -> 0.75 sunset)
	var tod: float = game.time_of_day
	var sa := PI + (tod - 0.25) * TAU
	var sun := center + Vector2(cos(sa), sin(sa)) * (rad - 10)
	var moon := center + Vector2(cos(sa + PI), sin(sa + PI)) * (rad - 10)
	if sun.y <= center.y + 2:
		c.draw_circle(sun, 8, Color(1.0, 0.85, 0.4))
	if moon.y <= center.y + 2:
		c.draw_circle(moon, 7, Color(0.9, 0.93, 1.0))
		c.draw_circle(moon + Vector2(3, -2), 6, sky)
	_text(c, Vector2(0, 92), "Day %d" % game.day, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, c.size.x)
	var hours := int(tod * 24.0)
	var mins := int(fmod(tod * 24.0 * 60.0, 60.0))
	_text(c, Vector2(0, 18), "%02d:%02d" % [hours, mins], 14, UITheme.MUTED, HORIZONTAL_ALIGNMENT_CENTER, c.size.x)


# ---------------------------------------------------------------- materials
func _draw_mats(c: Control) -> void:
	var mats := ["wood", "stone", "hide", "arrow"]
	c.draw_style_box(UITheme.box(Color(0.04, 0.06, 0.09, 0.82), Color(0.5, 0.65, 0.78, 0.35), 1, 8, 0), Rect2(Vector2.ZERO, Vector2(c.size.x, 14 + mats.size() * 30 + (24 if player.count("fur_cloak") > 0 else 0))))
	for i in mats.size():
		var y := 22.0 + i * 30.0
		Items.draw_icon(c, mats[i], Vector2(24, y), 11)
		_text(c, Vector2(44, y + 6), "%s  %d" % [Items.item_name(mats[i]), player.count(mats[i])], 16)
	if player.count("fur_cloak") > 0:
		_text(c, Vector2(14, 22 + mats.size() * 30 + 2), "Wearing fur cloak", 13, UITheme.WARM)


# ---------------------------------------------------------------- hotbar
func _slot_rect(i: int) -> Rect2:
	return Rect2(i * 70.0, 24.0, 64.0, 64.0)


func _draw_hotbar(c: Control) -> void:
	var sel_id: String = Items.HOTBAR[player.selected]
	var name_text := Items.item_name(sel_id)
	if sel_id == "food":
		var f := player.best_food()
		name_text = ("Eat: " + Items.item_name(f)) if f != "" else "No food"
	elif player.count(sel_id) <= 0:
		name_text += "  (craft it with %s)" % Settings.key_name("craft")
	_text(c, Vector2(0, 16), name_text, 18, UITheme.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, c.size.x)
	for i in Items.HOTBAR.size():
		var id: String = Items.HOTBAR[i]
		var r := _slot_rect(i)
		var selected := i == player.selected
		var bg := Color(0.12, 0.18, 0.25, 0.95) if selected else Color(0.05, 0.07, 0.1, 0.9)
		var border := UITheme.ACCENT if selected else Color(0.45, 0.58, 0.7, 0.45)
		c.draw_style_box(UITheme.box(bg, border, 3 if selected else 2, 8, 0), r)
		var n := player.food_count() if id == "food" else player.count(id)
		var icon_id := id
		if id == "food":
			icon_id = player.best_food() if player.best_food() != "" else "berries"
		Items.draw_icon(c, icon_id, r.get_center() + Vector2(0, 2), 20.0, 1.0 if n > 0 else 0.25)
		_text(c, r.position + Vector2(5, 15), str(i + 1), 13, Color(1, 1, 1, 0.7))
		if n > 1 or (id == "food" and n > 0) or id == "campfire" and n > 0:
			_text(c, r.position + Vector2(0, 60), str(n), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 5)
		if id == "bow" and n > 0:
			_text(c, r.position + Vector2(0, 60), "%d" % player.count("arrow"), 13, Color(0.85, 0.85, 0.8), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 5)


func _hotbar_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for i in Items.HOTBAR.size():
			if _slot_rect(i).has_point(ev.position):
				player.select(i)
				_hotbar.accept_event()


# ---------------------------------------------------------------- crafting
func _build_craft_panel() -> void:
	_craft = PanelContainer.new()
	_craft.custom_minimum_size = Vector2(330, 0)
	_craft.hide()
	_root.add_child(_craft)
	_place(_craft, Vector2(0, 0), Vector2(16, 160))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_craft.add_child(v)
	var title := UITheme.label("Crafting", 26, UITheme.ACCENT)
	v.add_child(title)
	_craft_rows = VBoxContainer.new()
	_craft_rows.add_theme_constant_override("separation", 6)
	v.add_child(_craft_rows)
	for rec in Items.RECIPES:
		var b := Button.new()
		b.custom_minimum_size = Vector2(300, 50)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.set_meta("rec", rec)
		b.pressed.connect(_craft_pressed.bind(rec))
		b.draw.connect(_draw_recipe_icon.bind(b))
		b.add_theme_font_size_override("font_size", 16)
		_craft_rows.add_child(b)
	var close := UITheme.label("Press %s to close" % Settings.key_name("craft"), 14, UITheme.MUTED)
	v.add_child(close)
	Audio.hook_buttons(_craft)


func _draw_recipe_icon(b: Button) -> void:
	var rec: Dictionary = b.get_meta("rec")
	Items.draw_icon(b, rec.id, Vector2(30, b.size.y / 2), 16, 1.0 if not b.disabled else 0.4)


func _refresh_craft() -> void:
	for b in _craft_rows.get_children():
		var rec: Dictionary = b.get_meta("rec")
		var owned: bool = rec.id in Items.UNIQUE and player.count(rec.id) > 0
		var amt := ("  x%d" % rec.amount) if rec.amount > 1 else ""
		b.text = "          %s%s\n          %s" % [Items.item_name(rec.id), amt, "Owned" if owned else Items.cost_text(rec.cost)]
		b.disabled = owned or not game.can_afford(rec.cost)
		b.tooltip_text = Items.DATA[rec.id].get("desc", "")


func _craft_pressed(rec: Dictionary) -> void:
	game.craft(rec)


func toggle_crafting() -> void:
	crafting_open = not crafting_open
	_craft.visible = crafting_open
	if crafting_open:
		_refresh_craft()
		Audio.play("ui_click", -6)


func is_mouse_over_ui() -> bool:
	var m := _root.get_global_mouse_position()
	return (_craft.visible and _craft.get_global_rect().has_point(m)) or _hotbar.get_global_rect().has_point(m)
