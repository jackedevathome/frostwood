class_name WorldMap
extends RefCounted
## Map data: a terrain image of the whole forest, a fog-of-war image revealed by exploring, and waypoints.

const SCALE := 8.0       # world units per terrain pixel
const FOG_SCALE := 32.0  # world units per fog pixel
const REVEAL := 520.0    # reveal radius around the player (world units)
const MAX_WAYPOINTS := 12
const COLORS := [Color(1.0, 0.82, 0.3), Color(0.45, 0.85, 1.0), Color(1.0, 0.45, 0.45), Color(0.6, 1.0, 0.5),
	Color(0.85, 0.6, 1.0), Color(1.0, 0.6, 0.25)]

const SNOW := Color(0.86, 0.9, 0.95)

var half: float
var terrain: Image
var terrain_tex: ImageTexture
var fog: Image
var fog_tex: ImageTexture
var waypoints: Array = []  # {pos: Vector2, name: String, color: Color}
var _wp_counter := 0
var _dirty := false


func _init(world_half: float) -> void:
	half = world_half
	var n := int(half * 2.0 / SCALE)
	terrain = Image.create(n, n, false, Image.FORMAT_RGBA8)
	terrain.fill(SNOW)
	var fn := int(half * 2.0 / FOG_SCALE)
	fog = Image.create(fn, fn, false, Image.FORMAT_RGBA8)
	fog.fill(Color(0.04, 0.06, 0.1, 1.0))


func size_px() -> Vector2:
	return Vector2(terrain.get_width(), terrain.get_height())


func to_map(p: Vector2) -> Vector2:
	return (p + Vector2(half, half)) / SCALE


func to_world(m: Vector2) -> Vector2:
	return m * SCALE - Vector2(half, half)


## Draws the static world. Called once after world generation.
func build(lakes: Array, nodes: Array) -> void:
	for L in lakes:
		var c: Vector2 = to_map(L[0])
		var r: Vector2 = L[1] / SCALE
		for y in range(int(c.y - r.y) - 2, int(c.y + r.y) + 3):
			for x in range(int(c.x - r.x) - 2, int(c.x + r.x) + 3):
				var d := (Vector2(x, y) - c) / r
				var l2 := d.length_squared()
				if l2 < 1.0:
					_px(x, y, Color(0.5, 0.68, 0.82) if l2 < 0.8 else Color(0.62, 0.78, 0.9))
				elif l2 < 1.18:
					_px(x, y, Color(0.95, 0.97, 1.0))
	for n in nodes:
		match n.get("kind"):
			"cabin":
				var c := to_map(n.global_position)
				for y in range(int(c.y - 6), int(c.y + 1)):
					for x in range(int(c.x - 8), int(c.x + 9)):
						_px(x, y, Color(0.45, 0.32, 0.22))
			"tree":
				var col: Color = {"spruce": Color(0.11, 0.3, 0.27), "pine": Color(0.2, 0.36, 0.2), "birch": Color(0.78, 0.78, 0.74)}[n.species]
				_dot(to_map(n.global_position), 2.2 * n.scale_f, col)
			"rock":
				_dot(to_map(n.global_position), 1.6, Color(0.5, 0.52, 0.56))
			"bush":
				_dot(to_map(n.global_position), 1.0, Color(0.6, 0.2, 0.25))
	terrain_tex = ImageTexture.create_from_image(terrain)
	fog_tex = ImageTexture.create_from_image(fog)


func _px(x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < terrain.get_width() and y < terrain.get_height():
		terrain.set_pixel(x, y, col)


func _dot(c: Vector2, r: float, col: Color) -> void:
	for y in range(int(c.y - r), int(c.y + r) + 1):
		for x in range(int(c.x - r), int(c.x + r) + 1):
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				_px(x, y, col)


## A felled tree or broken rock leaves a small mark on the map.
func clear_at(p: Vector2, stump := true) -> void:
	_dot(to_map(p), 2.6, SNOW)
	if stump:
		_dot(to_map(p), 0.8, Color(0.5, 0.38, 0.28))
	_dirty = true


func reveal(p: Vector2) -> void:
	var c := (p + Vector2(half, half)) / FOG_SCALE
	var r := REVEAL / FOG_SCALE
	var changed := false
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			if x < 0 or y < 0 or x >= fog.get_width() or y >= fog.get_height():
				continue
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c) / r
			var a := clampf((d - 0.65) / 0.35, 0.0, 1.0)
			var cur := fog.get_pixel(x, y)
			if a < cur.a - 0.01:
				cur.a = a
				fog.set_pixel(x, y, cur)
				changed = true
	if changed:
		fog_tex.update(fog)
	if _dirty:
		_dirty = false
		terrain_tex.update(terrain)


func explored(p: Vector2) -> bool:
	var c := (p + Vector2(half, half)) / FOG_SCALE
	if c.x < 0 or c.y < 0 or c.x >= fog.get_width() or c.y >= fog.get_height():
		return false
	return fog.get_pixel(int(c.x), int(c.y)).a < 0.5


func add_waypoint(p: Vector2) -> Dictionary:
	if waypoints.size() >= MAX_WAYPOINTS:
		return {}
	_wp_counter += 1
	var wp := {"pos": p, "name": "Waypoint %d" % _wp_counter, "color": COLORS[(_wp_counter - 1) % COLORS.size()]}
	waypoints.append(wp)
	return wp


func nearest_waypoint(p: Vector2, max_dist: float) -> int:
	var best := -1
	var bd := max_dist
	for i in waypoints.size():
		var d: float = waypoints[i].pos.distance_to(p)
		if d < bd:
			bd = d
			best = i
	return best
