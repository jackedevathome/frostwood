class_name MenuBackground
extends Control
## Animated night-time Nordic forest: aurora, stars, moon, mountains, parallax spruce layers, snowfall.

var _t := 0.0
var _stars: Array = []
var _flakes: Array = []
var _layers: Array = []  # each: {"trees": [[x, h, w]], "color": Color, "base": float, "par": float}
var _mouse_off := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for i in 160:
		_stars.append([r.randf(), r.randf() * 0.6, r.randf_range(0.6, 1.8), r.randf() * TAU])
	for i in 220:
		_flakes.append([r.randf(), r.randf(), r.randf_range(1.0, 3.2), r.randf() * TAU])
	var cols := [Color(0.13, 0.19, 0.27), Color(0.08, 0.13, 0.18), Color(0.04, 0.07, 0.09)]
	var bases := [0.70, 0.80, 0.93]
	var heights := [90.0, 150.0, 260.0]
	for li in 3:
		var trees := []
		var x := -0.1
		while x < 1.2:
			trees.append([x, heights[li] * r.randf_range(0.7, 1.3), r.randf_range(0.35, 0.5)])
			x += r.randf_range(0.018, 0.05) * (1.0 + li * 0.8)
		_layers.append({"trees": trees, "color": cols[li], "base": bases[li], "par": 8.0 + li * 18.0})


func _process(delta: float) -> void:
	_t += delta
	var vp := get_viewport_rect().size
	var m := get_viewport().get_mouse_position() / vp - Vector2(0.5, 0.5)
	_mouse_off = _mouse_off.lerp(m, 1.0 - exp(-delta * 3.0))
	for f in _flakes:
		f[1] += delta * (0.03 + f[2] * 0.02)
		f[0] += delta * (0.01 + sin(_t * 0.7 + f[3]) * 0.01)
		if f[1] > 1.05:
			f[1] = -0.05
			f[0] = randf()
		if f[0] > 1.05:
			f[0] = -0.05
	queue_redraw()


func _draw() -> void:
	var s := get_viewport_rect().size
	# Sky gradient
	var top := Color(0.02, 0.03, 0.08)
	var mid := Color(0.06, 0.12, 0.22)
	var bot := Color(0.17, 0.25, 0.36)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(s.x, 0), Vector2(s.x, s.y * 0.5), Vector2(0, s.y * 0.5)]),
		PackedColorArray([top, top, mid, mid]))
	draw_polygon(PackedVector2Array([Vector2(0, s.y * 0.5), Vector2(s.x, s.y * 0.5), Vector2(s.x, s.y), Vector2(0, s.y)]),
		PackedColorArray([mid, mid, bot, bot]))

	# Stars
	for st in _stars:
		var a: float = 0.4 + 0.6 * (0.5 + 0.5 * sin(_t * 1.5 + st[3]))
		draw_circle(Vector2(st[0] * s.x, st[1] * s.y), st[2], Color(0.9, 0.95, 1.0, a * 0.8))

	# Moon
	var mp := Vector2(s.x * 0.8, s.y * 0.17) - _mouse_off * 4
	for i in 6:
		draw_circle(mp, 40 + i * 14, Color(0.7, 0.8, 1.0, 0.035))
	draw_circle(mp, 34, Color(0.93, 0.95, 0.98))
	draw_circle(mp + Vector2(-9, -6), 7, Color(0.84, 0.87, 0.92))
	draw_circle(mp + Vector2(10, 8), 5, Color(0.86, 0.88, 0.93))

	_draw_aurora(s)

	# Distant mountains
	var mpts := PackedVector2Array()
	var off := -_mouse_off.x * 5
	mpts.append(Vector2(0, s.y))
	var n := 24
	for i in n + 1:
		var x := float(i) / n
		var h := 0.52 + 0.08 * sin(x * 9.0 + 1.3) + 0.05 * sin(x * 23.0) + 0.03 * cos(x * 41.0)
		mpts.append(Vector2(x * s.x + off, h * s.y))
	mpts.append(Vector2(s.x, s.y))
	draw_colored_polygon(mpts, Color(0.16, 0.22, 0.31))
	# snowy peaks highlight
	for i in n:
		var x := (float(i) + 0.5) / n
		var h := 0.52 + 0.08 * sin(x * 9.0 + 1.3) + 0.05 * sin(x * 23.0) + 0.03 * cos(x * 41.0)
		if h < 0.5:
			var p := Vector2(x * s.x + off, h * s.y)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-14, 10), p + Vector2(0, -2), p + Vector2(14, 10)]), Color(0.75, 0.82, 0.9, 0.6))

	# Tree layers (back to front)
	for li in _layers.size():
		var L: Dictionary = _layers[li]
		var base: float = L.base * s.y
		var px: float = -_mouse_off.x * L.par + sin(_t * 0.05) * L.par * 0.3
		draw_rect(Rect2(0, base - 2, s.x, s.y - base + 2), L.color)
		for tr in L.trees:
			_spruce(Vector2(tr[0] * s.x + px, base + 4), tr[1], tr[1] * tr[2], L.color, li)
		# snow ground on front layer
		if li == 2:
			var g := PackedVector2Array()
			g.append(Vector2(0, s.y))
			for i in 33:
				var x := float(i) / 32.0
				g.append(Vector2(x * s.x, base + 30 + 10 * sin(x * 12.0 + 0.5)))
			g.append(Vector2(s.x, s.y))
			draw_colored_polygon(g, Color(0.62, 0.70, 0.80))

	# Snow
	for f in _flakes:
		var p := Vector2(f[0] * s.x + sin(_t + f[3]) * 6.0, f[1] * s.y)
		draw_circle(p, f[2], Color(1, 1, 1, 0.35 + f[2] * 0.15))

	# Vignette
	var v := Color(0, 0, 0, 0.45)
	var c := Color(0, 0, 0, 0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(s.x * 0.18, 0), Vector2(s.x * 0.18, s.y), Vector2(0, s.y)]), PackedColorArray([v, c, c, v]))
	draw_polygon(PackedVector2Array([Vector2(s.x * 0.82, 0), Vector2(s.x, 0), Vector2(s.x, s.y), Vector2(s.x * 0.82, s.y)]), PackedColorArray([c, v, v, c]))


func _spruce(base: Vector2, h: float, w: float, col: Color, layer: int) -> void:
	var tiers := 5
	for i in tiers:
		var f0 := float(i) / tiers
		var y0 := base.y - h * (0.15 + f0 * 0.8)
		var y1 := y0 - h * 0.32
		var half := w * 0.5 * (1.0 - f0 * 0.75)
		var pts := PackedVector2Array([Vector2(base.x - half, y0), Vector2(base.x, y1), Vector2(base.x + half, y0)])
		draw_colored_polygon(pts, col)
		if layer >= 1:
			var snow := Color(0.55 + layer * 0.08, 0.63 + layer * 0.07, 0.74 + layer * 0.05, 0.55)
			draw_colored_polygon(PackedVector2Array([Vector2(base.x - half * 0.5, y0 - (y0 - y1) * 0.45), Vector2(base.x, y1), Vector2(base.x + half * 0.35, y0 - (y0 - y1) * 0.55)]), snow)
	draw_rect(Rect2(base.x - w * 0.04, base.y - h * 0.15, w * 0.08, h * 0.15), col.darkened(0.2))


func _draw_aurora(s: Vector2) -> void:
	var bands := [[Color(0.3, 1.0, 0.6), 0.18, 0.0], [Color(0.3, 0.9, 0.85), 0.24, 1.7], [Color(0.6, 0.4, 1.0), 0.13, 3.1]]
	for b in bands:
		var col: Color = b[0]
		var y0: float = b[1] * s.y
		var ph: float = b[2]
		var seg := 48
		for i in seg:
			var x0 := float(i) / seg
			var x1 := float(i + 1) / seg
			var ya := y0 + sin(x0 * 6.0 + _t * 0.25 + ph) * 40 + sin(x0 * 13.0 - _t * 0.4) * 14
			var yb := y0 + sin(x1 * 6.0 + _t * 0.25 + ph) * 40 + sin(x1 * 13.0 - _t * 0.4) * 14
			var ia := 0.5 + 0.5 * sin(x0 * 9.0 + _t * 0.6 + ph)
			var ib := 0.5 + 0.5 * sin(x1 * 9.0 + _t * 0.6 + ph)
			var ha := 70.0 + 50.0 * ia
			var hb := 70.0 + 50.0 * ib
			var ca := Color(col, 0.22 * ia)
			var cb := Color(col, 0.22 * ib)
			var z := Color(col, 0.0)
			draw_polygon(PackedVector2Array([Vector2(x0 * s.x, ya - ha), Vector2(x1 * s.x, yb - hb), Vector2(x1 * s.x, yb), Vector2(x0 * s.x, ya)]),
				PackedColorArray([z, z, cb, ca]))
			draw_polygon(PackedVector2Array([Vector2(x0 * s.x, ya), Vector2(x1 * s.x, yb), Vector2(x1 * s.x, yb + 12), Vector2(x0 * s.x, ya + 12)]),
				PackedColorArray([ca, cb, z, z]))
