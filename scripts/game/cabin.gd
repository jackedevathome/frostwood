class_name Cabin
extends StaticBody2D
## An abandoned trapper's cabin with a chest of supplies out front.

const LOOT := [
	["arrow", 4, 8], ["iron_ore", 2, 3], ["cooked_meat", 1, 2], ["cooked_fish", 1, 2], ["spruce_tea", 1, 1],
	["bandage", 1, 2], ["hide", 1, 2], ["birch_bark", 2, 3], ["fox_fur", 1, 1], ["berries", 3, 5], ["spruce_tips", 2, 3],
]
const CHEST_OFFSET := Vector2(48, 18)

var kind := "cabin"
var index := 0
var looted := false
var _lid := 0.0


func setup(i: int) -> void:
	index = i
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(118, 40)
	cs.shape = r
	cs.position = Vector2(0, -18)
	add_child(cs)
	add_to_group("cabins")


func chest_position() -> Vector2:
	return global_position + CHEST_OFFSET


## Rolls the chest's contents. The same chest always gives the same kind of haul for a world.
func roll_loot(rng: RandomNumberGenerator, has_rod: bool) -> Dictionary:
	var out := {}
	var picks := LOOT.duplicate()
	for k in 4:
		var e: Array = picks.pop_at(rng.randi() % picks.size())
		out[e[0]] = rng.randi_range(e[1], e[2])
	if not has_rod and rng.randf() < 0.5:
		out["fishing_rod"] = 1
	return out


func open_chest() -> void:
	looted = true
	var tw := create_tween()
	tw.tween_property(self, "_lid", 1.0, 0.35)
	tw.parallel().tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.35)


func _draw() -> void:
	# shadow
	draw_set_transform(Vector2(14, 4), 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 82, Color(0.1, 0.15, 0.25, 0.25))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var log := Color(0.46, 0.31, 0.2)
	var log_dark := Color(0.33, 0.22, 0.14)
	# roof (seen from the front, slanting back) with snow
	draw_colored_polygon(PackedVector2Array([Vector2(-72, -44), Vector2(-56, -96), Vector2(56, -96), Vector2(72, -44)]), Color(0.35, 0.25, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(-68, -50), Vector2(-54, -94), Vector2(54, -94), Vector2(68, -50)]), Color(0.9, 0.93, 0.98))
	draw_line(Vector2(-56, -96), Vector2(56, -96), Color(0.78, 0.84, 0.92), 3)
	# chimney
	draw_rect(Rect2(28, -112, 14, 30), Color(0.45, 0.46, 0.5))
	draw_rect(Rect2(26, -114, 18, 5), Color(0.9, 0.93, 0.98))
	# front wall of stacked logs
	draw_rect(Rect2(-60, -46, 120, 46), log)
	for k in 5:
		var y := -42.0 + k * 9.0
		draw_line(Vector2(-60, y), Vector2(60, y), log_dark, 1.5)
	for side in [-1.0, 1.0]:
		for k in 5:
			draw_circle(Vector2(side * 62, -41.0 + k * 9.0), 4.5, Color(0.62, 0.46, 0.3))
			draw_circle(Vector2(side * 62, -41.0 + k * 9.0), 2.0, log_dark)
	# door and window
	draw_rect(Rect2(-12, -36, 24, 36), Color(0.22, 0.14, 0.09))
	draw_line(Vector2(-12, -18), Vector2(12, -18), Color(0.15, 0.1, 0.06), 2)
	draw_circle(Vector2(7, -17), 1.6, Color(0.6, 0.6, 0.62))
	draw_rect(Rect2(-46, -34, 20, 16), Color(0.12, 0.15, 0.2))
	draw_line(Vector2(-36, -34), Vector2(-36, -18), log_dark, 2)
	draw_line(Vector2(-46, -26), Vector2(-26, -26), log_dark, 2)
	draw_rect(Rect2(-48, -36, 24, 20), log_dark, false, 2)
	# chest
	var c := CHEST_OFFSET
	draw_rect(Rect2(c + Vector2(-14, -16), Vector2(28, 16)), Color(0.5, 0.33, 0.18))
	draw_rect(Rect2(c + Vector2(-14, -16), Vector2(28, 16)), Color(0.3, 0.2, 0.1), false, 1.5)
	draw_line(c + Vector2(-14, -9), c + Vector2(14, -9), Color(0.55, 0.57, 0.6), 2)
	if looted:
		var lid_h := 10.0 * _lid
		draw_rect(Rect2(c + Vector2(-14, -16 - lid_h), Vector2(28, lid_h + 1)), Color(0.42, 0.27, 0.14))
		draw_rect(Rect2(c + Vector2(-12, -15), Vector2(24, 4)), Color(0.12, 0.08, 0.05))
	else:
		draw_rect(Rect2(c + Vector2(-15, -20), Vector2(30, 6)), Color(0.45, 0.29, 0.15))
		draw_rect(Rect2(c + Vector2(-15, -21), Vector2(30, 3)), Color(0.9, 0.93, 0.98))
		draw_rect(Rect2(c + Vector2(-2, -14), Vector2(4, 5)), Color(0.85, 0.7, 0.3))
