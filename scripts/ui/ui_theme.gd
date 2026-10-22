class_name UITheme
extends RefCounted
## Builds the shared frosty UI theme in code.

const TEXT := Color(0.92, 0.95, 0.98)
const MUTED := Color(0.62, 0.70, 0.78)
const ACCENT := Color(0.58, 0.82, 0.96)
const WARM := Color(0.98, 0.72, 0.38)
const PANEL := Color(0.06, 0.09, 0.13, 0.94)
const BORDER := Color(0.55, 0.72, 0.85, 0.55)

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func box(bg: Color, border: Color, bw := 2, radius := 6, pad := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad + 4
	sb.content_margin_right = pad + 4
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	sb.anti_aliasing = true
	return sb


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20

	# Buttons
	t.set_stylebox("normal", "Button", box(Color(0.10, 0.15, 0.21, 0.92), Color(0.45, 0.6, 0.72, 0.5)))
	t.set_stylebox("hover", "Button", box(Color(0.16, 0.24, 0.33, 0.96), ACCENT))
	t.set_stylebox("pressed", "Button", box(Color(0.22, 0.33, 0.44, 1.0), ACCENT.lightened(0.3)))
	t.set_stylebox("disabled", "Button", box(Color(0.08, 0.1, 0.13, 0.7), Color(0.3, 0.35, 0.4, 0.4)))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), Color(ACCENT, 0.8), 2))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.55, 0.6))
	t.set_color("font_focus_color", "Button", Color.WHITE)

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(PANEL, BORDER, 2, 10, 18))
	t.set_stylebox("panel", "Panel", box(PANEL, BORDER, 2, 10, 18))

	# Labels
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0.02, 0.03, 0.05, 0.9))
	t.set_constant("outline_size", "Label", 4)

	# Tabs
	t.set_stylebox("panel", "TabContainer", box(Color(0.05, 0.07, 0.1, 0.6), Color(0.4, 0.55, 0.65, 0.35), 1, 6, 16))
	t.set_stylebox("tab_selected", "TabContainer", box(Color(0.16, 0.24, 0.33, 1), ACCENT, 2, 6, 8))
	t.set_stylebox("tab_unselected", "TabContainer", box(Color(0.08, 0.11, 0.15, 0.9), Color(0.35, 0.45, 0.55, 0.4), 1, 6, 8))
	t.set_stylebox("tab_hovered", "TabContainer", box(Color(0.12, 0.18, 0.25, 1), Color(ACCENT, 0.7), 1, 6, 8))
	t.set_color("font_selected_color", "TabContainer", Color.WHITE)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	t.set_color("font_hovered_color", "TabContainer", TEXT)

	# Sliders
	var track := box(Color(0.12, 0.17, 0.23), Color(0.3, 0.4, 0.5, 0.6), 1, 4, 0)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	var fill := box(Color(0.38, 0.62, 0.8), Color(0, 0, 0, 0), 0, 4, 0)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var grab := _circle_texture(20, Color(0.9, 0.96, 1.0))
	t.set_icon("grabber", "HSlider", grab)
	t.set_icon("grabber_highlight", "HSlider", _circle_texture(22, Color.WHITE))

	# Check buttons / option buttons
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", Color.WHITE)
	t.set_color("font_pressed_color", "CheckButton", TEXT)
	t.set_stylebox("normal", "OptionButton", box(Color(0.10, 0.15, 0.21, 0.92), Color(0.45, 0.6, 0.72, 0.5), 2, 6, 6))
	t.set_stylebox("hover", "OptionButton", box(Color(0.16, 0.24, 0.33, 0.96), ACCENT, 2, 6, 6))
	t.set_stylebox("pressed", "OptionButton", box(Color(0.22, 0.33, 0.44, 1.0), ACCENT, 2, 6, 6))
	t.set_stylebox("focus", "OptionButton", box(Color(0, 0, 0, 0), Color(ACCENT, 0.8), 2, 6, 6))
	t.set_stylebox("panel", "PopupMenu", box(PANEL, BORDER, 2, 6, 6))
	t.set_stylebox("hover", "PopupMenu", box(Color(0.2, 0.3, 0.4), Color(0, 0, 0, 0), 0, 4, 4))

	# Scroll
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	return t


static func _circle_texture(size: int, col: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var a := clampf(size / 2.0 - d, 0.0, 1.0)
			var shade := col.darkened(0.25 * (d / (size / 2.0)))
			img.set_pixel(x, y, Color(shade, a))
	return ImageTexture.create_from_image(img)


static func label(text: String, size := 20, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, min_width := 260) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 48)
	b.add_theme_font_size_override("font_size", 22)
	return b


static func controls_text() -> String:
	var k := func(a): return Settings.key_name(a)
	return "[b]Move[/b]  %s %s %s %s   (or arrow keys)\n[b]Sprint[/b]  %s\n[b]Aim[/b]  Mouse\n[b]Use item / attack / chop / shoot[/b]  Left Mouse\n[b]Quick-eat best food[/b]  Right Mouse\n[b]Select hotbar slot[/b]  1 - 3 or Mouse Wheel\n[b]Interact[/b] (cook meat, fuel fire, pick berries)  %s\n[b]Inventory[/b]  %s   [b]Crafting[/b]  %s\n[b]Skill tree[/b]  %s   [b]World map[/b]  %s\n[b]Pause[/b]  Esc" % [
		k.call("move_up"), k.call("move_left"), k.call("move_down"), k.call("move_right"),
		k.call("sprint"), k.call("interact"), k.call("inventory"), k.call("craft"), k.call("skills"), k.call("map")]


static func how_to_play_text() -> String:
	return "[color=#94d1f5][b]Survive the Nordic winter for as many days as you can.[/b][/color]\n\n" + \
		"[b]Hunger[/b] drops over time. Pick lingonberries, hunt deer and hares, and cook meat at a fire — raw meat will make you sick.\n\n" + \
		"[b]Warmth[/b] drains in the cold, and much faster at night. Stand near a campfire to warm up. A torch and a fur cloak slow the chill.\n\n" + \
		"[b]Wolves[/b] hunt at night. They fear fire — keep your campfire fuelled with wood, and fight back with a spear or bow.\n\n" + \
		"[b]Gather[/b] wood by chopping pines and spruces with the axe, and stone by breaking boulders with the pickaxe. Then open the crafting menu to make arrows, torches, campfires, weapons and a fur cloak.\n\n" + \
		"[b]Inventory[/b] holds everything you carry. Drag items onto your 3 hotbar slots (or hover an item and press 1-3).\n\n" + \
		"[b]Experience[/b] comes from gathering, hunting, crafting and surviving nights. Each level gives a skill point to spend in the skill tree.\n\n" + \
		"[b]The map[/b] reveals the forest as you explore. Click on it to place waypoints; they show on the minimap and as flags in the world.\n\n" + \
		"[color=#f8b862][b]Controls[/b][/color]\n" + controls_text()
