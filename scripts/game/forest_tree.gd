class_name ForestTree
extends StaticBody2D
## A choppable Scots pine or Norway spruce. Origin is at the base of the trunk.

var kind := "tree"
var species := "spruce"
var scale_f := 1.0
var hp := 40.0
var height := 140.0
var canopy_w := 60.0
var felled := false
var faded := false

var _shake := 0.0
var _fall_t := -1.0
var _fall_dir := 1.0
var _alpha := 1.0
var _shapes: Array = []  # [PackedVector2Array, Color]
var _trunk_col: Color
var _branches: Array = []
var _mesh: ArrayMesh
var _game: Node


func setup(game: Node, sp: String, sc: float) -> void:
	_game = game
	species = sp
	scale_f = sc
	hp = 38.0 * sc
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 9.0 * sc
	shape.shape = circ
	shape.position = Vector2(0, -3)
	add_child(shape)
	_build()
	_bake()
	add_to_group("hittable")
	add_to_group("trees")
	set_process(false)


func _build() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(Vector2i(position))
	_shapes.clear()
	if species == "spruce":
		height = 150.0 * scale_f
		canopy_w = 64.0 * scale_f
		_trunk_col = Color(0.32, 0.23, 0.18)
		var base_col := Color(0.09, 0.24, 0.21).lerp(Color(0.12, 0.28, 0.27), r.randf())
		var tiers := 6
		for i in tiers:
			var f := float(i) / tiers
			var y0 := -height * (0.12 + f * 0.78)
			var tier_h := height * 0.26
			var half := canopy_w * 0.5 * (1.0 - f * 0.8) + r.randf_range(-2, 2)
			var col := base_col.darkened(0.12 * (1.0 - f)).lightened(0.04 * f)
			var pts := PackedVector2Array()
			pts.append(Vector2(0, y0 - tier_h))
			# drooping right edge
			pts.append(Vector2(half * 0.55, y0 - tier_h * 0.35))
			pts.append(Vector2(half, y0 + 3))
			for k in 5:
				var x := lerpf(half, -half, (k + 0.5) / 5.0)
				pts.append(Vector2(x, y0 + (4.0 if k % 2 == 0 else -1.0)))
			pts.append(Vector2(-half, y0 + 3))
			pts.append(Vector2(-half * 0.55, y0 - tier_h * 0.35))
			_shapes.append([pts, col])
			# shadow side
			_shapes.append([PackedVector2Array([Vector2(0, y0 - tier_h), Vector2(half * 0.55, y0 - tier_h * 0.35), Vector2(half, y0 + 3), Vector2(0, y0 + 2)]), Color(0, 0, 0, 0.16)])
			# snow on tier
			var sn := PackedVector2Array([Vector2(-half * 0.85, y0 - 1), Vector2(-half * 0.45, y0 - tier_h * 0.42), Vector2(0, y0 - tier_h + 2),
				Vector2(half * 0.3, y0 - tier_h * 0.6), Vector2(half * 0.15, y0 - tier_h * 0.45), Vector2(-half * 0.3, y0 - tier_h * 0.25), Vector2(-half * 0.55, y0 - 2)])
			_shapes.append([sn, Color(0.9, 0.94, 0.98, 0.92)])
	else:
		height = 165.0 * scale_f
		canopy_w = 84.0 * scale_f
		_trunk_col = Color(0.62, 0.34, 0.2)
		var base_col := Color(0.16, 0.3, 0.17).lerp(Color(0.2, 0.33, 0.18), r.randf())
		var top := -height * 0.6
		var blobs := []
		# a few flat cloud-like clumps spread sideways, typical of an old Scots pine
		var clumps := [Vector2(0, -0.32), Vector2(-0.34, -0.12), Vector2(0.36, -0.08), Vector2(-0.1, 0.02), Vector2(0.18, -0.24)]
		for cl in clumps:
			var cc := Vector2(cl.x * canopy_w, top + cl.y * height * 0.45)
			for k in 3:
				blobs.append([cc + Vector2(r.randf_range(-12, 12), r.randf_range(-4, 4)) * scale_f, r.randf_range(9, 14) * scale_f])
		_branches.clear()
		for cl in clumps:
			_branches.append(Vector2(cl.x * canopy_w * 0.8, top + cl.y * height * 0.45 + 6))
		blobs.sort_custom(func(a, b): return a[0].y > b[0].y)
		# canopy blobs drawn as circles (stored as polygons)
		for b in blobs:
			_shapes.append([_circle(b[0] + Vector2(2, 3), b[1], 10), base_col.darkened(0.3)])
		for b in blobs:
			_shapes.append([_circle(b[0], b[1], 12), base_col])
			_shapes.append([_circle(b[0] + Vector2(-b[1] * 0.25, -b[1] * 0.3), b[1] * 0.55, 10), base_col.lightened(0.12)])
			# snow cap
			var sp := PackedVector2Array()
			for k in 9:
				var ang := lerpf(PI * 1.05, PI * 1.95, k / 8.0)
				sp.append(b[0] + Vector2(cos(ang), sin(ang)) * b[1] * 0.92)
			sp.append(b[0] + Vector2(b[1] * 0.4, -b[1] * 0.35))
			sp.append(b[0] + Vector2(-b[1] * 0.4, -b[1] * 0.4))
			_shapes.append([sp, Color(0.92, 0.95, 0.99, 0.85)])


## Bakes all canopy polygons into one mesh so each tree costs a single draw call.
func _bake() -> void:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	for sh in _shapes:
		var pts: PackedVector2Array = sh[0]
		var idx := Geometry2D.triangulate_polygon(pts)
		for i in idx:
			verts.append(pts[i])
			cols.append(sh[1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_COLOR] = cols
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_shapes.clear()


func _circle(c: Vector2, rad: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(c + Vector2(cos(a), sin(a)) * rad)
	return p


func _draw() -> void:
	var sc := scale_f
	# ground shadow
	draw_set_transform(Vector2(10 * sc, 2), 0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, canopy_w * 0.45, Color(0.1, 0.15, 0.25, 0.22 * _alpha))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	if felled and _fall_t < 0:
		_draw_stump()
		return

	var rot := 0.0
	var off := Vector2.ZERO
	if _fall_t >= 0:
		rot = _fall_dir * ease(minf(_fall_t / 0.9, 1.0), 2.4) * PI * 0.5
	elif _shake > 0:
		off.x = sin(_shake * 60.0) * 3.0 * _shake / 0.35
	draw_set_transform(off, rot, Vector2.ONE)
	var a := _alpha
	# trunk
	var trunk_h := height * (0.62 if species == "pine" else 0.2)
	var tw := 5.0 * sc if species == "pine" else 4.5 * sc
	draw_colored_polygon(PackedVector2Array([Vector2(-tw, 0), Vector2(-tw * 0.6, -trunk_h), Vector2(tw * 0.6, -trunk_h), Vector2(tw, 0)]), Color(_trunk_col, a))
	draw_line(Vector2(tw * 0.3, -2), Vector2(tw * 0.2, -trunk_h), Color(_trunk_col.darkened(0.3), a), tw * 0.6)
	if species == "pine":
		draw_line(Vector2(-tw * 0.4, -trunk_h * 0.3), Vector2(-tw * 0.3, -trunk_h * 0.9), Color(_trunk_col.lightened(0.25), a), 1.5)
		for b in _branches:
			draw_line(Vector2(0, -trunk_h * 0.85), b, Color(_trunk_col.darkened(0.15), a), 2.5 * sc)
	var fade := a * (0.45 if faded else 1.0)
	draw_mesh(_mesh, null, Transform2D.IDENTITY, Color(1, 1, 1, fade))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_stump() -> void:
	var sc := scale_f
	var w := 6.0 * sc
	draw_rect(Rect2(-w, -8 * sc, w * 2, 8 * sc), _trunk_col)
	draw_set_transform(Vector2(0, -8 * sc), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, w, Color(0.85, 0.7, 0.5))
	draw_arc(Vector2.ZERO, w * 0.55, 0, TAU, 12, Color(0.6, 0.45, 0.3), 1.0)
	draw_set_transform(Vector2(0, -9 * sc), 0, Vector2(1, 0.45))
	draw_circle(Vector2(-1, -1), w * 0.7, Color(0.93, 0.96, 1.0, 0.9))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func set_faded(f: bool) -> void:
	if f != faded:
		faded = f
		queue_redraw()


func hit(damage: float, tool_id: String, source: Node2D) -> void:
	if felled:
		return
	var mult: float = Items.DATA.get(tool_id, {}).get("tree", 0.3)
	var dmg := damage * mult
	if dmg <= 0.0:
		Audio.play_at("swing", global_position, -6)
		return
	hp -= dmg
	_shake = 0.35
	set_process(true)
	Audio.play_at("chop", global_position, 0, 0.12)
	_game.snow_puff(global_position + Vector2(0, -height * 0.6), 10)
	_game.shake(2.0)
	if hp <= 0:
		_fell(source)


func _fell(source: Node2D) -> void:
	felled = true
	_fall_dir = 1.0 if source.global_position.x < global_position.x else -1.0
	_fall_t = 0.0
	remove_from_group("hittable")
	Audio.play_at("tree_fall", global_position, 2)
	var n := 3 + int(scale_f * 1.5)
	for i in n:
		var p := global_position + Vector2(_fall_dir * randf_range(20, height * 0.7), randf_range(-16, 16))
		_game.spawn_drop("wood", 1, p, global_position)


func _process(delta: float) -> void:
	if _fall_t >= 0:
		_fall_t += delta
		if _fall_t > 0.9 and _fall_t - delta <= 0.9:
			_game.snow_puff(global_position + Vector2(_fall_dir * height * 0.6, 0), 30)
			_game.shake(6.0)
		if _fall_t > 0.9:
			_alpha = maxf(0.0, 1.0 - (_fall_t - 0.9) / 0.6)
		if _fall_t > 1.5:
			_fall_t = -1.0
			_alpha = 1.0
			# shrink collision to a stump
			var cs: CollisionShape2D = get_child(0)
			(cs.shape as CircleShape2D).radius = 6.0 * scale_f
			set_process(false)
		queue_redraw()
		return
	_shake -= delta
	if _shake <= 0:
		_shake = 0
		set_process(false)
	queue_redraw()
