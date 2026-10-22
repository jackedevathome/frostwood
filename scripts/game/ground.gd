class_name Ground
extends Node2D
## Static snowy ground: drifts, moss, heather, twigs, animal tracks and frozen lakes. Drawn once.

var half := 2400.0
var lakes: Array = []  # [center: Vector2, radii: Vector2]
var _rng := RandomNumberGenerator.new()
var _chunks := {}  # Vector2i -> GroundChunk
const CHUNK := 512.0


## One square of ground. Only chunks near the camera get drawn.
class GroundChunk extends Node2D:
	var ops: Array[Callable] = []

	func _draw() -> void:
		for op in ops:
			op.call(self)


var _force: GroundChunk = null  # when set, ops go here (keeps lake layers in order)


func _add(at: Vector2, op: Callable) -> void:
	if _force:
		_force.ops.append(op)
		return
	var k := Vector2i(floori(at.x / CHUNK), floori(at.y / CHUNK))
	var c: GroundChunk = _chunks.get(k)
	if c == null:
		c = GroundChunk.new()
		_chunks[k] = c
		add_child(c)
	c.ops.append(op)


func setup(world_half: float, lake_list: Array, seed_v: int) -> void:
	half = world_half
	lakes = lake_list
	_rng.seed = seed_v
	z_index = -10
	_generate()


func _ell(c: Vector2, r: Vector2, col: Color, n := 20, wobble := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var w := 1.0 + wobble * sin(a * 3.0 + c.x) * 0.5 + wobble * cos(a * 5.0 + c.y) * 0.3
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y) * w)
	_add(c, func(ci: CanvasItem): ci.draw_colored_polygon(pts, col))


func _draw() -> void:
	var ext := half + 900.0
	draw_rect(Rect2(-ext, -ext, ext * 2, ext * 2), Color(0.86, 0.9, 0.95))


func _generate() -> void:
	var ext := half + 900.0
	var r := _rng
	# soft blue drift shadows
	for i in 900:
		var p := Vector2(r.randf_range(-ext, ext), r.randf_range(-ext, ext))
		var s := r.randf_range(30, 120)
		_ell(p, Vector2(s, s * 0.45), Color(0.72, 0.79, 0.88, r.randf_range(0.12, 0.3)), 16, 0.3)
	# bright drift tops
	for i in 600:
		var p := Vector2(r.randf_range(-ext, ext), r.randf_range(-ext, ext))
		var s := r.randf_range(20, 70)
		_ell(p, Vector2(s, s * 0.35), Color(0.97, 0.98, 1.0, r.randf_range(0.3, 0.6)), 14, 0.2)
	# moss / heather patches where snow is thin
	for i in 260:
		var p := Vector2(r.randf_range(-half, half), r.randf_range(-half, half))
		var s := r.randf_range(14, 50)
		var col: Color = [Color(0.36, 0.5, 0.36, 0.3), Color(0.5, 0.42, 0.46, 0.2), Color(0.45, 0.55, 0.38, 0.28)][r.randi() % 3]
		_ell(p, Vector2(s, s * 0.5), col, 14, 0.5)
		for k in 6:
			var q := p + Vector2(r.randf_range(-s, s), r.randf_range(-s * 0.4, s * 0.4))
			var rr := r.randf_range(2, 4)
			var dc := col.darkened(0.2)
			_add(q, func(ci: CanvasItem): ci.draw_circle(q, rr, dc))
	# twigs, pine needles and pebbles
	for i in 1400:
		var p := Vector2(r.randf_range(-half, half), r.randf_range(-half, half))
		match r.randi() % 3:
			0:
				var d := Vector2.from_angle(r.randf() * TAU) * r.randf_range(5, 14)
				_add(p, func(ci: CanvasItem):
					ci.draw_line(p, p + d, Color(0.4, 0.3, 0.22, 0.7), 1.5)
					ci.draw_line(p + d * 0.5, p + d * 0.5 + d.rotated(0.8) * 0.4, Color(0.4, 0.3, 0.22, 0.6), 1.0))
			1:
				var rr := r.randf_range(1.5, 3.5)
				_add(p, func(ci: CanvasItem): ci.draw_circle(p, rr, Color(0.5, 0.52, 0.56, 0.8)))
			2:
				var needles := PackedVector2Array()
				for k in 3:
					needles.append(p)
					needles.append(p + Vector2.from_angle(r.randf() * TAU) * 4)
				_add(p, func(ci: CanvasItem): ci.draw_multiline(needles, Color(0.25, 0.35, 0.25, 0.6), 1.0))
	# animal tracks
	for i in 30:
		var p := Vector2(r.randf_range(-half, half), r.randf_range(-half, half))
		var dir := Vector2.from_angle(r.randf() * TAU)
		for k in 14:
			var q := p + dir * k * 14 + dir.orthogonal() * (4 if k % 2 == 0 else -4)
			_ell(q, Vector2(2.2, 1.6), Color(0.62, 0.69, 0.8, 0.6), 8)
			dir = dir.rotated(r.randf_range(-0.15, 0.15))
	# frozen lakes (own node so their layers stay in order)
	_force = GroundChunk.new()
	add_child(_force)
	for L in lakes:
		var c: Vector2 = L[0]
		var rad: Vector2 = L[1]
		_ell(c, rad * 1.08, Color(0.95, 0.97, 1.0), 40, 0.08)
		_ell(c, rad, Color(0.55, 0.72, 0.85), 40, 0.08)
		_ell(c + Vector2(-rad.x * 0.1, -rad.y * 0.1), rad * 0.8, Color(0.62, 0.79, 0.9), 36, 0.1)
		for k in 8:
			var q := c + Vector2(r.randf_range(-0.6, 0.6) * rad.x, r.randf_range(-0.6, 0.6) * rad.y)
			_ell(q, Vector2(r.randf_range(20, 60), r.randf_range(6, 14)), Color(0.85, 0.92, 0.98, 0.45), 12)
		# cracks
		for k in 10:
			var q := c + Vector2(r.randf_range(-0.7, 0.7) * rad.x, r.randf_range(-0.7, 0.7) * rad.y)
			var pts := PackedVector2Array([q])
			var d := Vector2.from_angle(r.randf() * TAU)
			for m in 5:
				q += d * r.randf_range(8, 22)
				d = d.rotated(r.randf_range(-0.7, 0.7))
				pts.append(q)
			_add(c, func(ci: CanvasItem): ci.draw_polyline(pts, Color(0.92, 0.97, 1.0, 0.7), 1.2))
	_force = null
	var border := GroundChunk.new()
	border.ops.append(func(ci: CanvasItem): _draw_border(ci, ext))
	add_child(border)


func _draw_border(ci: CanvasItem, ext: float) -> void:
	# world border: darker snow beyond the edge
	var b := Color(0.6, 0.66, 0.75, 0.55)
	ci.draw_rect(Rect2(-ext, -ext, ext * 2, ext - half), b)
	ci.draw_rect(Rect2(-ext, half, ext * 2, ext - half), b)
	ci.draw_rect(Rect2(-ext, -half, ext - half, half * 2), b)
	ci.draw_rect(Rect2(half, -half, ext - half, half * 2), b)
