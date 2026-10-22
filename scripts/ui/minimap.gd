class_name Minimap
extends Control
## Corner minimap (north up) with fog of war, campfires, animals, waypoints and the clock below it.

const VIEW := 1300.0  # world units shown across the minimap
const MAP_H := 200.0

var game: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _draw() -> void:
	var map: WorldMap = game.world_map
	var player: Player = game.player
	if map == null or map.terrain_tex == null:
		return
	draw_style_box(UITheme.box(Color(0.04, 0.06, 0.09, 0.85), Color(0.5, 0.65, 0.78, 0.5), 2, 8, 0), Rect2(Vector2.ZERO, Vector2(size.x, MAP_H)))
	var r := Rect2(6, 6, size.x - 12, MAP_H - 12)
	var pp := player.global_position
	var k := r.size.x / VIEW
	var src_size := Vector2.ONE * VIEW / WorldMap.SCALE
	draw_texture_rect_region(map.terrain_tex, r, Rect2(map.to_map(pp) - src_size / 2, src_size))
	var fsize := Vector2.ONE * VIEW / WorldMap.FOG_SCALE
	var fc := (pp + Vector2(map.half, map.half)) / WorldMap.FOG_SCALE
	draw_texture_rect_region(map.fog_tex, r, Rect2(fc - fsize / 2, fsize))
	# outside the world
	_shade_outside(r, pp, k, map.half)

	var center := r.get_center()
	var to_mini := func(p: Vector2) -> Vector2: return center + (p - pp) * k
	for f in get_tree().get_nodes_in_group("campfires"):
		var q: Vector2 = to_mini.call(f.global_position)
		if r.has_point(q):
			draw_circle(q, 4.5 if f.burning else 3.0, Color(1.0, 0.6, 0.2) if f.burning else Color(0.4, 0.4, 0.45))
	for a in get_tree().get_nodes_in_group("animals"):
		var q: Vector2 = to_mini.call(a.global_position)
		if r.grow(-2).has_point(q):
			var wolf: bool = a.species == "wolf"
			draw_circle(q, 3.0 if wolf else 2.2, Color(0.95, 0.25, 0.25) if wolf else Color(0.65, 0.48, 0.3))
	for wp in map.waypoints:
		var q: Vector2 = to_mini.call(wp.pos)
		var inner := r.grow(-7)
		if inner.has_point(q):
			MapScreen.draw_waypoint(self, q, wp.color, 6.0)
		else:
			# clamp to the edge and point towards it
			var dir: Vector2 = (q - center).normalized()
			var t := minf(absf((inner.size.x / 2) / dir.x) if dir.x != 0 else INF, absf((inner.size.y / 2) / dir.y) if dir.y != 0 else INF)
			var e := center + dir * t
			var side := dir.orthogonal()
			draw_colored_polygon(PackedVector2Array([e + dir * 6, e - dir * 4 + side * 5, e - dir * 4 - side * 5]), wp.color)
	MapScreen.draw_player(self, center, player.aim, 7.0)
	draw_rect(r, Color(0.02, 0.03, 0.05, 0.6), false, 1.5)
	HUD.text(self, Vector2(r.position.x, r.position.y + 15), "N", 13, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

	_draw_clock(Rect2(0, MAP_H + 4, size.x, size.y - MAP_H - 4))


func _shade_outside(r: Rect2, pp: Vector2, k: float, half: float) -> void:
	var world := Rect2((Vector2(-half, -half) - pp) * k + r.get_center(), Vector2(half, half) * 2 * k)
	var col := Color(0.1, 0.16, 0.14, 0.95)
	if world.position.x > r.position.x:
		draw_rect(Rect2(r.position, Vector2(world.position.x - r.position.x, r.size.y)), col)
	if world.end.x < r.end.x:
		draw_rect(Rect2(Vector2(world.end.x, r.position.y), Vector2(r.end.x - world.end.x, r.size.y)), col)
	if world.position.y > r.position.y:
		draw_rect(Rect2(r.position, Vector2(r.size.x, world.position.y - r.position.y)), col)
	if world.end.y < r.end.y:
		draw_rect(Rect2(Vector2(r.position.x, world.end.y), Vector2(r.size.x, r.end.y - world.end.y)), col)


func _draw_clock(r: Rect2) -> void:
	draw_style_box(UITheme.box(Color(0.04, 0.06, 0.09, 0.82), Color(0.5, 0.65, 0.78, 0.35), 1, 8, 0), r)
	var tod: float = game.time_of_day
	var night: bool = game.is_night()
	var ic := r.position + Vector2(20, r.size.y / 2)
	if night:
		draw_circle(ic, 8, Color(0.9, 0.93, 1.0))
		draw_circle(ic + Vector2(4, -3), 7, Color(0.06, 0.08, 0.12))
	else:
		draw_circle(ic, 8, Color(1.0, 0.85, 0.4))
	var hours := int(tod * 24.0)
	var mins := int(fmod(tod * 24.0 * 60.0, 60.0))
	HUD.text(self, r.position + Vector2(38, r.size.y / 2 + 7), "Day %d" % game.day, 19)
	HUD.text(self, r.position + Vector2(0, r.size.y / 2 + 6), "%02d:%02d" % [hours, mins], 16, UITheme.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 12)
