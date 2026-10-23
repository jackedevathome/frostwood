class_name RuneStone
extends StaticBody2D
## An old carved standing stone. Reading it (E) tells a piece of lore and grants XP once.

const LORE := [
	["The Stone of Gunnhild", "Ulf raised this stone for Gunnhild, who walked into the white and did not return. Keep your fire fed, and you will see the dawn she did not."],
	["The Bear's Warning", "Wolves fear the flame, but the bear fears little. Walk wide around the old ones, or meet them with iron and a long spear."],
	["The Patient Ice", "The lakes sleep under ice, yet the fish do not. Cut, wait, and pull only when the line trembles."],
	["The White Tree", "Birch gives bark that binds wounds and catches flame. Thank the white tree when you take from it."],
	["Iron in the Stone", "Iron sleeps in the red-veined rocks of the far woods. Wake it with fire, and it will serve you."],
	["The Long Night", "The sky-fires dance for those who outlast the dark. Count your dawns, survivor. Each one is a victory."],
]

var kind := "rune"
var index := 0
var read := false
var _t := 0.0


func setup(i: int) -> void:
	index = i
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12
	cs.shape = c
	cs.position = Vector2(0, -4)
	add_child(cs)
	add_to_group("runes")


func title() -> String:
	return LORE[index][0]


func text() -> String:
	return LORE[index][1]


func _process(delta: float) -> void:
	_t += delta
	if not read:
		queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(8, 1), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 22, Color(0.1, 0.15, 0.25, 0.25))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var stone := PackedVector2Array([Vector2(-15, 0), Vector2(-17, -40), Vector2(-11, -62), Vector2(0, -70), Vector2(12, -63),
		Vector2(17, -38), Vector2(15, 0)])
	draw_colored_polygon(stone, Color(0.44, 0.46, 0.5))
	draw_colored_polygon(PackedVector2Array([Vector2(4, -68), Vector2(12, -63), Vector2(17, -38), Vector2(15, 0), Vector2(6, 0)]), Color(0.36, 0.38, 0.42))
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -62), Vector2(0, -70), Vector2(12, -63), Vector2(4, -60), Vector2(-6, -58)]), Color(0.92, 0.95, 0.99))
	# carved serpent band and runes
	var glow := 0.55 + 0.45 * sin(_t * 2.2) if not read else 0.0
	var col := Color(0.45, 0.85, 1.0).lerp(Color(0.25, 0.27, 0.3), 1.0 - glow) if not read else Color(0.26, 0.28, 0.32)
	draw_arc(Vector2(0, -32), 11, PI * 0.6, PI * 2.4, 20, col, 2.0, true)
	var runes := [[Vector2(-4, -48), Vector2(-4, -36)], [Vector2(-4, -48), Vector2(1, -43)], [Vector2(3, -46), Vector2(3, -34)],
		[Vector2(3, -40), Vector2(7, -44)], [Vector2(-4, -28), Vector2(-4, -18)], [Vector2(-4, -28), Vector2(1, -24)], [Vector2(1, -24), Vector2(-4, -21)],
		[Vector2(4, -28), Vector2(4, -17)], [Vector2(4, -23), Vector2(8, -27)], [Vector2(4, -23), Vector2(8, -19)]]
	for seg in runes:
		draw_line(seg[0], seg[1], col, 1.6)
	if not read:
		draw_circle(Vector2(0, -36), 22, Color(0.45, 0.85, 1.0, 0.06 * glow))
