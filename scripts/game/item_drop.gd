class_name ItemDrop
extends Node2D
## A dropped item lying in the snow. Flies to the player when close.

var item_id := "wood"
var amount := 1
var _t := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _arc := 0.0
var _game: Node


func setup(game: Node, id: String, n: int, target: Vector2, origin: Vector2) -> void:
	_game = game
	item_id = id
	amount = n
	_to = target
	_from = origin
	global_position = origin
	_t = randf() * 0.2
	add_to_group("drops")


func _process(delta: float) -> void:
	_t += delta
	if _arc < 1.0:
		_arc = minf(_arc + delta * 2.5, 1.0)
		global_position = _from.lerp(_to, _arc)
	else:
		var player: Node2D = _game.player
		if player and not player.dead:
			var d := global_position.distance_to(player.global_position)
			if d < 70:
				global_position = global_position.move_toward(player.global_position, delta * (420 - d * 3))
				if d < 14:
					player.add_item(item_id, amount)
					Audio.play("pickup", -9, 0.15)
					_game.message("+%d %s" % [amount, Items.item_name(item_id)])
					queue_free()
					return
	queue_redraw()


func _draw() -> void:
	var hop := -sin(_arc * PI) * 26.0
	var bob := sin(_t * 3.0) * 2.0 if _arc >= 1.0 else 0.0
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 8, Color(0.1, 0.15, 0.25, 0.25))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	Items.draw_icon(self, item_id, Vector2(0, -9 + hop + bob), 10.0)
