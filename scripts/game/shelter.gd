class_name Shelter
extends Node2D
## A hide lavvu (Sámi tent). Sleep in it (E) at night when a campfire burns nearby.

var kind := "shelter"


func _ready() -> void:
	add_to_group("shelters")


func _draw() -> void:
	draw_set_transform(Vector2(8, 2), 0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, 48, Color(0.1, 0.15, 0.25, 0.25))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var pole := Color(0.38, 0.26, 0.16)
	var hide := Color(0.62, 0.48, 0.33)
	var top := Vector2(0, -78)
	# poles poking out of the smoke hole
	for dx in [-9.0, -3.0, 4.0, 10.0]:
		draw_line(top + Vector2(dx * 0.3, 8), top + Vector2(dx, -12), pole, 2.5)
	# conical hide cover (lavvu)
	draw_colored_polygon(PackedVector2Array([top + Vector2(-5, 4), Vector2(-40, 0), Vector2(40, 0), top + Vector2(5, 4)]), hide)
	draw_colored_polygon(PackedVector2Array([top + Vector2(2, 4), Vector2(14, 0), Vector2(40, 0), top + Vector2(5, 4)]), hide.darkened(0.18))
	# woven decorative band
	draw_colored_polygon(PackedVector2Array([Vector2(-29, -22), Vector2(29, -22), Vector2(31.5, -16), Vector2(-31.5, -16)]), Color(0.58, 0.22, 0.17))
	for k in 7:
		var x := -24.0 + k * 8.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, -21), Vector2(x + 2.5, -19), Vector2(x, -17), Vector2(x - 2.5, -19)]), Color(0.9, 0.78, 0.4))
	# door opening with a glimpse of the bedroll
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -38), Vector2(-15, 0), Vector2(11, 0)]), Color(0.16, 0.11, 0.08))
	draw_rect(Rect2(-10, -8, 16, 7), Color(0.36, 0.42, 0.36))
	draw_line(Vector2(-4, -38), Vector2(-17, 1), Color(0.48, 0.36, 0.24), 2)
	# snow resting on the upper cover
	draw_colored_polygon(PackedVector2Array([top + Vector2(-5, 5), Vector2(-17, -44), Vector2(-9, -48), Vector2(4, -46), Vector2(14, -42), top + Vector2(5, 5)]), Color(0.92, 0.95, 0.99))
