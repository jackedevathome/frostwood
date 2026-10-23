class_name UITheme
extends RefCounted
## Builds the shared frosty UI theme in code.

const TEXT := Color(0.93, 0.95, 0.97)
const MUTED := Color(0.63, 0.7, 0.77)
const ACCENT := Color(0.62, 0.84, 0.96)
const WARM := Color(0.98, 0.74, 0.42)
const GOLD := Color(0.88, 0.74, 0.46)
const PANEL := Color(0.065, 0.085, 0.115, 0.96)
const BORDER := Color(0.42, 0.55, 0.66, 0.5)

static var _theme: Theme
static var _body: Font
static var _bold: Font
static var _head: Font


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## Body text font (Alegreya Sans Medium).
static func font() -> Font:
	if _body == null:
		_body = _load_font("res://assets/fonts/AlegreyaSans-Medium.ttf")
	return _body


static func font_bold() -> Font:
	if _bold == null:
		_bold = _load_font("res://assets/fonts/AlegreyaSans-Bold.ttf")
	return _bold


## Heading font (Cinzel, bold weight).
static func font_head() -> Font:
	if _head == null:
		var base := _load_font("res://assets/fonts/Cinzel-Variable.ttf")
		var fv := FontVariation.new()
		fv.base_font = base
		fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
		_head = fv
	return _head


static func _load_font(path: String) -> Font:
	var f = load(path)
	return f if f is Font else ThemeDB.fallback_font


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


## Big framed panel with a soft drop shadow.
static func panel_box(pad := 22) -> StyleBoxFlat:
	var sb := box(PANEL, BORDER, 1, 14, pad)
	sb.border_width_top = 2
	sb.border_color = Color(0.5, 0.64, 0.75, 0.55)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 6)
	return sb


## Button styles with a darker bottom edge, so they look pressable.
static func button_box(state: String) -> StyleBoxFlat:
	var bg := Color(0.115, 0.15, 0.2, 0.96)
	var border := Color(0.36, 0.47, 0.57, 0.65)
	match state:
		"hover":
			bg = Color(0.16, 0.22, 0.29, 0.98)
			border = ACCENT
		"pressed":
			bg = Color(0.09, 0.12, 0.16, 1.0)
			border = ACCENT.darkened(0.2)
		"disabled":
			bg = Color(0.08, 0.1, 0.13, 0.75)
			border = Color(0.28, 0.32, 0.37, 0.45)
	var sb := box(bg, border, 1, 9, 9)
	sb.border_width_bottom = 1 if state == "pressed" else 4
	sb.border_width_top = 3 if state == "pressed" else 1
	if state != "pressed":
		sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.25 if state != "pressed" else 0.0)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 21

	# Buttons
	for st in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(st, "Button", button_box(st))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", font_bold())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", Color(0.48, 0.52, 0.57))
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.5))
	t.set_constant("outline_size", "Button", 2)

	# Panels
	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_stylebox("panel", "Panel", panel_box())

	# Labels
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0.02, 0.03, 0.05, 0.9))
	t.set_constant("outline_size", "Label", 4)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	t.set_constant("shadow_offset_y", "Label", 2)
	t.set_constant("shadow_offset_x", "Label", 0)

	# Rich text
	t.set_font("normal_font", "RichTextLabel", font())
	t.set_font("bold_font", "RichTextLabel", font_bold())
	t.set_color("default_color", "RichTextLabel", TEXT)

	# Tabs
	t.set_font("font", "TabContainer", font_bold())
	t.set_stylebox("panel", "TabContainer", box(Color(0.04, 0.055, 0.08, 0.7), Color(0.4, 0.55, 0.65, 0.3), 1, 10, 18))
	var tab_sel := box(Color(0.16, 0.22, 0.29, 1), ACCENT, 0, 8, 10)
	tab_sel.border_width_bottom = 3
	tab_sel.corner_radius_bottom_left = 0
	tab_sel.corner_radius_bottom_right = 0
	t.set_stylebox("tab_selected", "TabContainer", tab_sel)
	var tab_un := box(Color(0.08, 0.105, 0.14, 0.9), Color(0, 0, 0, 0), 0, 8, 10)
	tab_un.corner_radius_bottom_left = 0
	tab_un.corner_radius_bottom_right = 0
	t.set_stylebox("tab_unselected", "TabContainer", tab_un)
	var tab_h := tab_un.duplicate()
	tab_h.bg_color = Color(0.12, 0.17, 0.23, 1)
	t.set_stylebox("tab_hovered", "TabContainer", tab_h)
	t.set_color("font_selected_color", "TabContainer", Color.WHITE)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	t.set_color("font_hovered_color", "TabContainer", TEXT)
	t.set_constant("side_margin", "TabContainer", 0)

	# Sliders
	var track := box(Color(0.1, 0.13, 0.18), Color(0.3, 0.4, 0.5, 0.6), 1, 5, 0)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	var fill := box(Color(0.42, 0.66, 0.84), Color(0, 0, 0, 0), 0, 5, 0)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _circle_texture(20, Color(0.9, 0.96, 1.0)))
	t.set_icon("grabber_highlight", "HSlider", _circle_texture(22, Color.WHITE))

	# Check buttons / option buttons
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", Color.WHITE)
	t.set_color("font_pressed_color", "CheckButton", TEXT)
	t.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	for st in ["normal", "hover", "pressed"]:
		var b := button_box(st)
		b.content_margin_top = 6
		b.content_margin_bottom = 6
		t.set_stylebox(st, "OptionButton", b)
	t.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	t.set_font("font", "OptionButton", font_bold())
	t.set_stylebox("panel", "PopupMenu", box(PANEL, BORDER, 1, 8, 6))
	t.set_stylebox("hover", "PopupMenu", box(Color(0.2, 0.3, 0.4), Color(0, 0, 0, 0), 0, 5, 4))
	t.set_font("font", "PopupMenu", font())

	# Tooltips
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.05, 0.07, 0.1, 0.97), BORDER, 1, 6, 8))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font("font", "TooltipLabel", font())

	# Scroll
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	return t


## A thin decorative divider: lines fading out from a gold diamond.
static func draw_ornament(ci: CanvasItem, center: Vector2, half_width: float, col := GOLD) -> void:
	var seg := 16
	for side in [-1.0, 1.0]:
		for i in seg:
			var a := float(i) / seg
			var b := float(i + 1) / seg
			var c := Color(col, (1.0 - a) * 0.85)
			ci.draw_line(center + Vector2(side * (10 + a * half_width), 0), center + Vector2(side * (10 + b * half_width), 0), c, 1.5)
		ci.draw_circle(center + Vector2(side * (half_width * 0.35 + 10), 0), 2.0, Color(col, 0.7))
	ci.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -6), center + Vector2(6, 0), center + Vector2(0, 6), center + Vector2(-6, 0)]), col)
	ci.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -2.5), center + Vector2(2.5, 0), center + Vector2(0, 2.5), center + Vector2(-2.5, 0)]), PANEL)


static func ornament(width := 320.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 16)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func(): draw_ornament(c, c.size / 2, minf(width, c.size.x) / 2 - 12))
	return c


## A heading in the Cinzel font.
static func heading(text: String, size := 30, color := ACCENT) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", font_head())
	return l


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
	b.custom_minimum_size = Vector2(min_width, 50)
	b.add_theme_font_size_override("font_size", 22)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
