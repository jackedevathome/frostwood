class_name Items
extends RefCounted
## Item database, crafting recipes, and vector icon drawing shared by HUD and world.

const DATA := {
	"axe": {"name": "Axe", "kind": "melee", "damage": 10.0, "tree": 1.7, "rock": 0.3, "range": 62.0, "cooldown": 0.42,
		"desc": "Fells pines and spruces for wood. Also a decent weapon."},
	"pickaxe": {"name": "Pickaxe", "kind": "melee", "damage": 8.0, "tree": 0.3, "rock": 1.9, "range": 60.0, "cooldown": 0.5,
		"desc": "Breaks boulders for stone."},
	"spear": {"name": "Spear", "kind": "melee", "damage": 24.0, "tree": 0.2, "rock": 0.2, "range": 92.0, "cooldown": 0.6,
		"desc": "Long reach, hits hard. The wolf-hunter's friend."},
	"bow": {"name": "Bow", "kind": "ranged", "damage": 30.0, "cooldown": 0.7,
		"desc": "Fires arrows wherever you aim."},
	"torch": {"name": "Torch", "kind": "light", "damage": 6.0, "tree": 0.0, "rock": 0.0, "range": 58.0, "cooldown": 0.5,
		"desc": "Lights the dark, slows the cold and scares wolves away."},
	"campfire": {"name": "Campfire", "kind": "place",
		"desc": "Place with the mouse. Warmth, light, cooking and safety."},
	"food": {"name": "Food", "kind": "food"},
	"berries": {"name": "Lingonberries", "kind": "food", "hunger": 9.0, "heal": 2.0, "warm": 0.0},
	"raw_meat": {"name": "Raw Meat", "kind": "food", "hunger": 12.0, "heal": -8.0, "warm": 0.0},
	"cooked_meat": {"name": "Cooked Meat", "kind": "food", "hunger": 34.0, "heal": 12.0, "warm": 10.0},
	"wood": {"name": "Wood", "kind": "material"},
	"stone": {"name": "Stone", "kind": "material"},
	"hide": {"name": "Hide", "kind": "material"},
	"arrow": {"name": "Arrows", "kind": "ammo"},
	"fur_cloak": {"name": "Fur Cloak", "kind": "wear", "desc": "Halves the bite of the cold. Worn automatically."},
}

## Fixed hotbar layout. "food" always eats the best food you carry.
const HOTBAR := ["axe", "pickaxe", "spear", "bow", "torch", "campfire", "food"]
const FOOD_PRIORITY := ["cooked_meat", "berries", "raw_meat"]
const UNIQUE := ["spear", "bow", "torch", "fur_cloak"]

const RECIPES := [
	{"id": "arrow", "amount": 4, "cost": {"wood": 1, "stone": 1}},
	{"id": "torch", "amount": 1, "cost": {"wood": 2}},
	{"id": "campfire", "amount": 1, "cost": {"wood": 5, "stone": 3}},
	{"id": "spear", "amount": 1, "cost": {"wood": 3, "stone": 2}},
	{"id": "bow", "amount": 1, "cost": {"wood": 4, "hide": 1}},
	{"id": "fur_cloak", "amount": 1, "cost": {"hide": 3}},
]


static func item_name(id: String) -> String:
	return DATA.get(id, {}).get("name", id)


static func cost_text(cost: Dictionary) -> String:
	var parts := []
	for k in cost:
		parts.append("%d %s" % [cost[k], item_name(k)])
	return ", ".join(parts)


## Draws an icon for `id` centred at `c`. `s` is roughly the half-size in pixels.
static func draw_icon(ci: CanvasItem, id: String, c: Vector2, s: float, alpha := 1.0) -> void:
	var wood := Color(0.55, 0.36, 0.2, alpha)
	var dark_wood := Color(0.38, 0.24, 0.13, alpha)
	var iron := Color(0.72, 0.76, 0.8, alpha)
	var iron_dark := Color(0.45, 0.48, 0.53, alpha)
	match id:
		"axe":
			ci.draw_line(c + Vector2(-0.6, 0.75) * s, c + Vector2(0.45, -0.6) * s, wood, s * 0.18)
			var blade := PackedVector2Array([c + Vector2(0.15, -0.75) * s, c + Vector2(0.75, -0.55) * s,
				c + Vector2(0.65, 0.05) * s, c + Vector2(0.3, -0.3) * s])
			ci.draw_colored_polygon(blade, iron)
			ci.draw_line(c + Vector2(0.75, -0.55) * s, c + Vector2(0.65, 0.05) * s, Color(0.95, 0.97, 1, alpha), s * 0.08)
		"pickaxe":
			ci.draw_line(c + Vector2(-0.6, 0.75) * s, c + Vector2(0.35, -0.45) * s, wood, s * 0.18)
			var pts := PackedVector2Array()
			for i in 9:
				var a := lerpf(-2.6, -0.1, i / 8.0)
				pts.append(c + Vector2(0.15, -0.15) * s + Vector2(cos(a), sin(a)) * s * 0.75)
			ci.draw_polyline(pts, iron, s * 0.2, true)
			ci.draw_circle(c + Vector2(0.4, -0.5) * s, s * 0.13, iron_dark)
		"spear":
			ci.draw_line(c + Vector2(-0.8, 0.8) * s, c + Vector2(0.45, -0.45) * s, wood, s * 0.13)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.9, -0.9) * s, c + Vector2(0.3, -0.5) * s,
				c + Vector2(0.5, -0.3) * s]), Color(0.6, 0.62, 0.66, alpha))
			ci.draw_line(c + Vector2(0.28, -0.28) * s, c + Vector2(0.46, -0.46) * s, Color(0.8, 0.75, 0.6, alpha), s * 0.2)
		"bow":
			var pts := PackedVector2Array()
			for i in 13:
				var a := lerpf(-PI * 0.42, PI * 0.42, i / 12.0) - PI * 0.25
				pts.append(c + Vector2(-0.35, 0.35) * s + Vector2(cos(a), sin(a)) * s * 1.05)
			ci.draw_polyline(pts, wood, s * 0.16, true)
			ci.draw_line(pts[0], pts[pts.size() - 1], Color(0.9, 0.9, 0.85, alpha), maxf(1.0, s * 0.05))
		"torch":
			ci.draw_line(c + Vector2(-0.45, 0.8) * s, c + Vector2(0.2, -0.2) * s, wood, s * 0.18)
			ci.draw_circle(c + Vector2(0.28, -0.32) * s, s * 0.38, Color(1.0, 0.45, 0.1, alpha * 0.9))
			ci.draw_circle(c + Vector2(0.3, -0.4) * s, s * 0.24, Color(1.0, 0.8, 0.3, alpha))
			ci.draw_circle(c + Vector2(0.32, -0.45) * s, s * 0.1, Color(1, 1, 0.85, alpha))
		"campfire":
			ci.draw_line(c + Vector2(-0.8, 0.6) * s, c + Vector2(0.8, 0.25) * s, dark_wood, s * 0.22)
			ci.draw_line(c + Vector2(-0.8, 0.25) * s, c + Vector2(0.8, 0.6) * s, wood, s * 0.22)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.45, 0.35) * s, c + Vector2(-0.1, -0.85) * s,
				c + Vector2(0.15, -0.2) * s, c + Vector2(0.3, -0.6) * s, c + Vector2(0.5, 0.35) * s]), Color(1.0, 0.45, 0.1, alpha))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.22, 0.35) * s, c + Vector2(0.0, -0.35) * s,
				c + Vector2(0.25, 0.35) * s]), Color(1.0, 0.85, 0.35, alpha))
		"berries":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.1, -0.6) * s, c + Vector2(0.6, -0.85) * s,
				c + Vector2(0.3, -0.35) * s]), Color(0.2, 0.5, 0.25, alpha))
			for p in [Vector2(-0.3, 0.1), Vector2(0.3, 0.15), Vector2(0.0, -0.3), Vector2(0.0, 0.5)]:
				ci.draw_circle(c + p * s, s * 0.3, Color(0.75, 0.08, 0.12, alpha))
				ci.draw_circle(c + (p + Vector2(-0.1, -0.1)) * s, s * 0.09, Color(1, 0.6, 0.6, alpha))
		"raw_meat", "cooked_meat", "food":
			var cooked := id != "raw_meat"
			ci.draw_line(c + Vector2(0.2, -0.2) * s, c + Vector2(0.75, -0.75) * s, Color(0.95, 0.92, 0.85, alpha), s * 0.2)
			ci.draw_circle(c + Vector2(0.75, -0.75) * s, s * 0.14, Color(0.95, 0.92, 0.85, alpha))
			ci.draw_circle(c + Vector2(0.62, -0.88) * s, s * 0.12, Color(0.95, 0.92, 0.85, alpha))
			var meat := Color(0.55, 0.28, 0.12, alpha) if cooked else Color(0.85, 0.3, 0.32, alpha)
			ci.draw_circle(c + Vector2(-0.15, 0.15) * s, s * 0.55, meat)
			ci.draw_circle(c + Vector2(-0.3, 0.0) * s, s * 0.2, meat.lightened(0.2))
		"wood":
			for o in [Vector2(0, 0.3), Vector2(0, -0.25)]:
				ci.draw_line(c + (o + Vector2(-0.7, 0.15)) * s, c + (o + Vector2(0.6, -0.15)) * s, wood, s * 0.42)
				ci.draw_circle(c + (o + Vector2(0.6, -0.15)) * s, s * 0.21, Color(0.82, 0.65, 0.42, alpha))
				ci.draw_circle(c + (o + Vector2(0.6, -0.15)) * s, s * 0.08, dark_wood)
		"stone":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.75, 0.45) * s, c + Vector2(-0.5, -0.35) * s,
				c + Vector2(0.1, -0.65) * s, c + Vector2(0.7, -0.2) * s, c + Vector2(0.75, 0.5) * s]), Color(0.55, 0.57, 0.6, alpha))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.5, -0.35) * s, c + Vector2(0.1, -0.65) * s,
				c + Vector2(0.2, -0.1) * s]), Color(0.72, 0.74, 0.77, alpha))
		"hide":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.8, -0.5) * s, c + Vector2(-0.3, -0.7) * s,
				c + Vector2(0.3, -0.6) * s, c + Vector2(0.8, -0.7) * s, c + Vector2(0.6, 0.0) * s, c + Vector2(0.8, 0.7) * s,
				c + Vector2(0.0, 0.5) * s, c + Vector2(-0.8, 0.7) * s, c + Vector2(-0.6, 0.0) * s]), Color(0.66, 0.5, 0.33, alpha))
			ci.draw_circle(c + Vector2(0.0, 0.0) * s, s * 0.25, Color(0.72, 0.57, 0.4, alpha))
		"arrow":
			ci.draw_line(c + Vector2(-0.75, 0.75) * s, c + Vector2(0.6, -0.6) * s, Color(0.7, 0.55, 0.35, alpha), s * 0.1)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.85, -0.85) * s, c + Vector2(0.45, -0.65) * s,
				c + Vector2(0.65, -0.45) * s]), iron_dark)
			ci.draw_line(c + Vector2(-0.75, 0.75) * s, c + Vector2(-0.75, 0.4) * s, Color(0.9, 0.9, 0.9, alpha), s * 0.15)
			ci.draw_line(c + Vector2(-0.75, 0.75) * s, c + Vector2(-0.4, 0.75) * s, Color(0.9, 0.9, 0.9, alpha), s * 0.15)
		"fur_cloak":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.4, -0.6) * s, c + Vector2(0.4, -0.6) * s,
				c + Vector2(0.75, 0.8) * s, c + Vector2(-0.75, 0.8) * s]), Color(0.5, 0.36, 0.24, alpha))
			for i in 5:
				ci.draw_circle(c + Vector2(-0.45 + i * 0.22, -0.6) * s, s * 0.18, Color(0.92, 0.9, 0.86, alpha))
		_:
			ci.draw_circle(c, s * 0.5, Color(1, 0, 1, alpha))
