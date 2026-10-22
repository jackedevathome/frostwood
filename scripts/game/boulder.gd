class_name Boulder
extends StaticBody2D
## Snow-capped granite boulder. Mine it with the pickaxe for stone.

var kind := "rock"
var hp := 45.0
var radius := 20.0
var _poly := PackedVector2Array()
var _light := PackedVector2Array()
var _snow := PackedVector2Array()
var _shake := 0.0
var _game: Node


func setup(game: Node, sc: float) -> void:
	_game = game
	radius = 18.0 * sc
	hp = 40.0 * sc
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = radius * 0.85
	shape.shape = circ
	shape.position = Vector2(0, -radius * 0.35)
	add_child(shape)
	var r := RandomNumberGenerator.new()
	r.seed = hash(Vector2i(position))
	var n := 9
	for i in n:
		var a := PI + PI * i / (n - 1)
		var d := radius * r.randf_range(0.8, 1.1)
		_poly.append(Vector2(cos(a) * d * 1.25, sin(a) * d * 0.95))
	_poly.append(Vector2(radius * 1.2, 2))
	_poly.append(Vector2(-radius * 1.2, 2))
	for i in _poly.size() - 2:
		if i < 6:
			_light.append(_poly[i] * 0.85 + Vector2(-2, -2))
	_light.append(Vector2(-radius * 0.2, -radius * 0.3))
	for i in range(2, 7):
		_snow.append(_poly[i] + Vector2(0, 1))
	_snow.append(_poly[6] * 0.7 + Vector2(0, 4))
	_snow.append(_poly[2] * 0.7 + Vector2(0, 4))
	add_to_group("hittable")


func _draw() -> void:
	var off := Vector2(sin(_shake * 70.0) * 2.0 * _shake / 0.25, 0) if _shake > 0 else Vector2.ZERO
	draw_set_transform(Vector2(6, 1), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, radius * 1.3, Color(0.1, 0.15, 0.25, 0.22))
	draw_set_transform(off, 0, Vector2.ONE)
	draw_colored_polygon(_poly, Color(0.42, 0.45, 0.5))
	if _light.size() >= 3:
		draw_colored_polygon(_light, Color(0.55, 0.58, 0.63))
	draw_colored_polygon(_snow, Color(0.92, 0.95, 0.99))
	draw_line(_poly[3] * 0.5, _poly[5] * 0.4 + Vector2(0, 4), Color(0.3, 0.32, 0.36), 1.5)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func hit(damage: float, tool_id: String, _source: Node2D) -> void:
	var mult: float = Items.DATA.get(tool_id, {}).get("rock", 0.3)
	var dmg := damage * mult
	Audio.play_at("mine", global_position, -2 if mult > 1.0 else -8, 0.15)
	_game.debris(global_position + Vector2(0, -radius * 0.5), Color(0.55, 0.58, 0.62), 6)
	if dmg <= 0.0:
		return
	hp -= dmg
	_shake = 0.25
	if hp <= 0:
		var n := 2 + int(radius / 12.0)
		for i in n:
			_game.spawn_drop("stone", 1, global_position + Vector2(randf_range(-20, 20), randf_range(-10, 10)), global_position)
		_game.debris(global_position + Vector2(0, -radius * 0.4), Color(0.6, 0.62, 0.66), 16)
		_game.snow_puff(global_position, 12)
		queue_free()


func _process(delta: float) -> void:
	if _shake > 0:
		_shake -= delta
		queue_redraw()
