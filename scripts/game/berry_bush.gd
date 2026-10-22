class_name BerryBush
extends Node2D
## Lingonberry bush. Pick with any click or the interact key; regrows over time.

var kind := "bush"
var ripe := true
var _regrow := 0.0
var _leaves: Array = []
var _berries: Array = []
var _game: Node


func setup(game: Node) -> void:
	_game = game
	var r := RandomNumberGenerator.new()
	r.seed = hash(Vector2i(position))
	for i in 9:
		_leaves.append([Vector2(r.randf_range(-16, 16), r.randf_range(-14, -2)), r.randf_range(7, 11)])
	_leaves.sort_custom(func(a, b): return a[0].y < b[0].y)
	for i in 7:
		_berries.append(Vector2(r.randf_range(-13, 13), r.randf_range(-16, -4)))
	add_to_group("hittable")
	add_to_group("bushes")


func _draw() -> void:
	draw_set_transform(Vector2(4, 0), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 20, Color(0.1, 0.15, 0.25, 0.2))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for l in _leaves:
		draw_circle(l[0], l[1], Color(0.13, 0.3, 0.2))
	for l in _leaves:
		draw_circle(l[0] + Vector2(-2, -2), l[1] * 0.6, Color(0.18, 0.38, 0.24))
	for l in _leaves.slice(0, 4):
		draw_circle(l[0] + Vector2(0, -l[1] * 0.4), l[1] * 0.55, Color(0.92, 0.95, 0.99, 0.8))
	if ripe:
		for b in _berries:
			draw_circle(b, 3.2, Color(0.78, 0.06, 0.12))
			draw_circle(b + Vector2(-1, -1), 1.1, Color(1, 0.6, 0.6))


func hit(_damage: float, _tool: String, _source: Node2D) -> void:
	harvest()


func harvest() -> bool:
	if not ripe:
		_game.message("These berries are not ripe yet.")
		return false
	ripe = false
	_regrow = 150.0
	Audio.play_at("pickup", global_position, -4)
	_game.snow_puff(global_position + Vector2(0, -10), 6)
	for i in randi_range(2, 4):
		_game.spawn_drop("berries", 1, global_position + Vector2(randf_range(-14, 14), randf_range(4, 12)), global_position)
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if not ripe:
		_regrow -= delta
		if _regrow <= 0:
			ripe = true
			queue_redraw()
