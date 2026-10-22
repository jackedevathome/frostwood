class_name MapScreen
extends CanvasLayer
## Fullscreen world map. Left click places a waypoint, right click removes one, wheel zooms, drag pans.
## The game is paused while the map is open.

var game: Node
var _root: Control
var _view: Control
var _info: Label
var _zoom := 1.6
var _center := Vector2.ZERO  # map-pixel coordinate at the middle of the view
var _press := Vector2.INF
var _dragging := false
var _hover := -1


static func draw_waypoint(c: CanvasItem, p: Vector2, col: Color, s: float) -> void:
	c.draw_line(p, p + Vector2(0, -s * 2.2), Color(0.15, 0.12, 0.1), 2.0)
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 2.2), p + Vector2(s * 1.6, -s * 1.7), p + Vector2(0, -s * 1.2)]), col)
	c.draw_circle(p, s * 0.45, col.darkened(0.3))


static func draw_player(c: CanvasItem, p: Vector2, dir: Vector2, s: float) -> void:
	var f := dir.normalized() if dir.length() > 0.1 else Vector2.UP
	var side := f.orthogonal()
	var pts := PackedVector2Array([p + f * s * 1.3, p - f * s * 0.8 + side * s * 0.9, p - f * s * 0.3, p - f * s * 0.8 - side * s * 0.9])
	var outline := PackedVector2Array(pts)
	outline.append(pts[0])
	c.draw_colored_polygon(pts, Color(1, 1, 1))
	c.draw_polyline(outline, Color(0.05, 0.08, 0.12), 2.0, true)


func setup(g: Node) -> void:
	game = g
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.get_theme()
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 30
	v.offset_right = -30
	v.offset_top = 20
	v.offset_bottom = -20
	v.add_theme_constant_override("separation", 10)
	_root.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	var title := UITheme.label("Map of Frostwood", 30, UITheme.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	for pair in [["Center on me", _recenter], ["Clear waypoints", _clear], ["Close", close]]:
		var b := UITheme.button(pair[0], 170)
		b.custom_minimum_size.y = 40
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(pair[1])
		top.add_child(b)

	_view = Control.new()
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.clip_contents = true
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_draw_view)
	_view.gui_input.connect(_view_input)
	v.add_child(_view)

	_info = UITheme.label("", 16, UITheme.MUTED)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info)
	Audio.hook_buttons(_root)
	hide()


func open() -> void:
	show()
	get_tree().paused = true
	_center = game.world_map.to_map(game.player.global_position)
	_zoom = 1.6
	Input.set_custom_mouse_cursor(null)
	Audio.play("page", -3)


func close() -> void:
	hide()
	get_tree().paused = false
	Audio.play("page", -6)
	game.restore_cursor()


func _recenter() -> void:
	_center = game.world_map.to_map(game.player.global_position)
	_view.queue_redraw()


func _clear() -> void:
	while not game.world_map.waypoints.is_empty():
		game.remove_waypoint(0)
	_view.queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		_view.queue_redraw()


func _scale() -> float:
	var map_px: Vector2 = game.world_map.size_px()
	return minf(_view.size.x / map_px.x, _view.size.y / map_px.y) * _zoom


func _to_screen(m: Vector2) -> Vector2:
	return _view.size / 2 + (m - _center) * _scale()


func _to_map(s: Vector2) -> Vector2:
	return _center + (s - _view.size / 2) / _scale()


func _draw_view() -> void:
	var map: WorldMap = game.world_map
	var sc := _scale()
	var origin := _to_screen(Vector2.ZERO)
	var world_rect := Rect2(origin, map.size_px() * sc)
	_view.draw_rect(Rect2(Vector2.ZERO, _view.size), Color(0.08, 0.12, 0.11))
	_view.draw_texture_rect(map.terrain_tex, world_rect, false)
	_view.draw_texture_rect(map.fog_tex, world_rect, false)
	# grid every 600 world units
	var step := 600.0 / WorldMap.SCALE
	var gx := 0.0
	while gx <= map.size_px().x + 0.1:
		var a := _to_screen(Vector2(gx, 0))
		var b := _to_screen(Vector2(gx, map.size_px().y))
		_view.draw_line(a, b, Color(0.3, 0.45, 0.6, 0.18), 1.0)
		var c := _to_screen(Vector2(0, gx))
		var d := _to_screen(Vector2(map.size_px().x, gx))
		_view.draw_line(c, d, Color(0.3, 0.45, 0.6, 0.18), 1.0)
		gx += step
	_view.draw_rect(world_rect, Color(0.6, 0.75, 0.88, 0.6), false, 2.0)

	for f in get_tree().get_nodes_in_group("campfires"):
		var q := _to_screen(map.to_map(f.global_position))
		_view.draw_circle(q, 6, Color(0.2, 0.1, 0.05, 0.8))
		_view.draw_circle(q, 4.5, Color(1.0, 0.6, 0.2) if f.burning else Color(0.45, 0.45, 0.5))
	var pp: Vector2 = game.player.global_position
	for i in map.waypoints.size():
		var wp: Dictionary = map.waypoints[i]
		var q := _to_screen(map.to_map(wp.pos))
		var s := 9.0 if i == _hover else 7.0
		draw_waypoint(_view, q, wp.color, s)
		var dist := int(wp.pos.distance_to(pp) / 10.0)
		HUD.text(_view, q + Vector2(10, 6), "%s  (%dm)" % [wp.name, dist], 14, wp.color.lightened(0.3) if i == _hover else Color(1, 1, 1, 0.85))
	draw_player(_view, _to_screen(map.to_map(pp)), game.player.aim, 9.0)
	HUD.text(_view, _to_screen(map.to_map(pp)) + Vector2(12, -10), "You", 14, Color.WHITE)
	# compass
	var cp := Vector2(_view.size.x - 50, 50)
	_view.draw_circle(cp, 28, Color(0.04, 0.06, 0.09, 0.8))
	_view.draw_arc(cp, 28, 0, TAU, 32, Color(0.6, 0.75, 0.88, 0.6), 1.5, true)
	_view.draw_colored_polygon(PackedVector2Array([cp + Vector2(0, -22), cp + Vector2(6, 0), cp + Vector2(-6, 0)]), Color(0.95, 0.4, 0.4))
	_view.draw_colored_polygon(PackedVector2Array([cp + Vector2(0, 22), cp + Vector2(6, 0), cp + Vector2(-6, 0)]), Color(0.85, 0.88, 0.92))
	HUD.text(_view, cp + Vector2(-30, -30), "N", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 60)
	# legend
	var lp := Vector2(16, _view.size.y - 110)
	_view.draw_style_box(UITheme.box(Color(0.04, 0.06, 0.09, 0.85), Color(0.5, 0.65, 0.78, 0.35), 1, 8, 0), Rect2(lp, Vector2(180, 96)))
	var items := [[Color(0.11, 0.3, 0.27), "Spruce"], [Color(0.2, 0.36, 0.2), "Pine"], [Color(0.5, 0.68, 0.82), "Frozen lake"], [Color(1.0, 0.6, 0.2), "Campfire"]]
	for i in items.size():
		_view.draw_circle(lp + Vector2(16, 16 + i * 21), 5, items[i][0])
		HUD.text(_view, lp + Vector2(30, 21 + i * 21), items[i][1], 14)
	_info.text = "Left click: place waypoint (%d/%d)   •   Right click: remove waypoint   •   Wheel: zoom   •   Drag: pan   •   %s / Esc: close" % [
		map.waypoints.size(), WorldMap.MAX_WAYPOINTS, Settings.key_name("map")]


func _waypoint_at(s: Vector2) -> int:
	var map: WorldMap = game.world_map
	for i in map.waypoints.size():
		var q := _to_screen(map.to_map(map.waypoints[i].pos))
		if s.distance_to(q) < 14 or s.distance_to(q + Vector2(5, -14)) < 12:
			return i
	return -1


func _view_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.pressed and (ev.button_index == MOUSE_BUTTON_WHEEL_UP or ev.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var before := _to_map(ev.position)
			_zoom = clampf(_zoom * (1.15 if ev.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), 0.8, 8.0)
			_center += before - _to_map(ev.position)
		elif ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_press = ev.position
				_dragging = false
			else:
				if not _dragging and _press != Vector2.INF:
					var m := _to_map(ev.position)
					var wpos: Vector2 = game.world_map.to_world(m)
					var h: float = game.world_map.half
					if absf(wpos.x) < h and absf(wpos.y) < h:
						if not game.add_waypoint(wpos):
							Audio.play("ui_hover", -2)
				_press = Vector2.INF
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			var i := _waypoint_at(ev.position)
			if i >= 0:
				game.remove_waypoint(i)
		_view.accept_event()
	elif ev is InputEventMouseMotion:
		_hover = _waypoint_at(ev.position)
		if _press != Vector2.INF and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT):
			if _dragging or ev.position.distance_to(_press) > 6:
				_dragging = true
				_center -= ev.relative / _scale()
	var map_px: Vector2 = game.world_map.size_px()
	_center = _center.clamp(Vector2.ZERO, map_px)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("map"):
		get_viewport().set_input_as_handled()
		close()
