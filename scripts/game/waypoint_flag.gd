class_name WaypointFlag
extends Node2D
## A small flag planted in the snow where a waypoint is set on the map.

var color := Color.WHITE
var label := ""
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(2, 0), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 8, Color(0.1, 0.15, 0.25, 0.3))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_line(Vector2(0, 0), Vector2(0, -42), Color(0.35, 0.25, 0.18), 3)
	var wave := sin(_t * 3.0) * 3.0
	draw_colored_polygon(PackedVector2Array([Vector2(1, -42), Vector2(24, -36 + wave), Vector2(1, -28)]), color)
	draw_circle(Vector2(0, -43), 2.5, Color(0.9, 0.85, 0.6))
	HUD.text(self, Vector2(-60, -50), label, 12, Color(color, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 120)
