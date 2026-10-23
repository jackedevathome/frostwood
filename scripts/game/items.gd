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
	"berries": {"name": "Lingonberries", "kind": "food", "hunger": 9.0, "heal": 2.0, "warm": 0.0},
	"raw_meat": {"name": "Raw Meat", "kind": "food", "hunger": 12.0, "heal": -8.0, "warm": 0.0},
	"cooked_meat": {"name": "Cooked Meat", "kind": "food", "hunger": 34.0, "heal": 12.0, "warm": 10.0},
	"wood": {"name": "Wood", "kind": "material"},
	"stone": {"name": "Stone", "kind": "material"},
	"hide": {"name": "Hide", "kind": "material"},
	"arrow": {"name": "Arrows", "kind": "ammo"},
	"fur_cloak": {"name": "Fur Cloak", "kind": "wear", "cold": 0.5, "desc": "Halves the bite of the cold. Worn automatically."},
	# --- content update
	"iron_axe": {"name": "Iron Axe", "kind": "melee", "damage": 15.0, "tree": 2.1, "rock": 0.4, "range": 64.0, "cooldown": 0.38,
		"desc": "A forged iron head bites deep. Fells trees in half the swings."},
	"iron_pickaxe": {"name": "Iron Pickaxe", "kind": "melee", "damage": 12.0, "tree": 0.3, "rock": 2.4, "range": 62.0, "cooldown": 0.44,
		"desc": "Cracks boulders and ore veins with ease."},
	"fishing_rod": {"name": "Fishing Rod", "kind": "rod",
		"desc": "Use it on a frozen lake. When the bobber dips and you see \"!\", click to reel in."},
	"shelter": {"name": "Shelter", "kind": "place",
		"desc": "A hide lavvu tent. Place it near a campfire, then press E at night to sleep until dawn."},
	"raw_fish": {"name": "Raw Fish", "kind": "food", "hunger": 9.0, "heal": -5.0, "warm": 0.0},
	"cooked_fish": {"name": "Grilled Fish", "kind": "food", "hunger": 26.0, "heal": 14.0, "warm": 8.0},
	"spruce_tea": {"name": "Spruce-tip Tea", "kind": "consumable", "buff": "warm", "time": 120.0, "warm": 35.0,
		"desc": "Hot tea brewed from spruce tips. Keeps the cold away for two minutes."},
	"bandage": {"name": "Birch Bandage", "kind": "consumable", "buff": "regen", "time": 10.0,
		"desc": "Hide and birch bark. Heals 35 health over 10 seconds."},
	"birch_bark": {"name": "Birch Bark", "kind": "material"},
	"spruce_tips": {"name": "Spruce Tips", "kind": "material"},
	"iron_ore": {"name": "Iron Ore", "kind": "material"},
	"bear_pelt": {"name": "Bear Pelt", "kind": "material"},
	"fox_fur": {"name": "Fox Fur", "kind": "material"},
	"bear_cloak": {"name": "Bear Pelt Cloak", "kind": "wear", "cold": 0.35, "desc": "Heavy and warm. The cold barely reaches you."},
	"fox_hat": {"name": "Fox Fur Hat", "kind": "wear", "cold": 0.85, "desc": "Keeps your ears warm: 15% less cold. Stacks with a cloak."},
}

## Item kinds that can be put in one of the 3 hotbar slots and used with the mouse.
const EQUIP_KINDS := ["melee", "ranged", "light", "rod", "place", "food", "consumable"]
const KIND_ORDER := ["melee", "ranged", "light", "rod", "place", "food", "consumable", "ammo", "material", "wear"]
const FOOD_PRIORITY := ["cooked_meat", "cooked_fish", "berries", "raw_fish", "raw_meat"]
const UNIQUE := ["spear", "bow", "torch", "fur_cloak", "iron_axe", "iron_pickaxe", "fishing_rod", "bear_cloak", "fox_hat"]
## Raw food that a campfire turns into cooked food.
const COOKS := {"raw_meat": "cooked_meat", "raw_fish": "cooked_fish"}

## "fire": true means you must stand near a burning campfire to craft it.
const RECIPES := [
	{"id": "arrow", "amount": 4, "cost": {"wood": 1, "stone": 1}},
	{"id": "torch", "amount": 1, "cost": {"wood": 2}},
	{"id": "campfire", "amount": 1, "cost": {"wood": 5, "stone": 3}},
	{"id": "spear", "amount": 1, "cost": {"wood": 3, "stone": 2}},
	{"id": "bow", "amount": 1, "cost": {"wood": 4, "hide": 1}},
	{"id": "fishing_rod", "amount": 1, "cost": {"wood": 2, "birch_bark": 2}},
	{"id": "bandage", "amount": 2, "cost": {"birch_bark": 1, "hide": 1}},
	{"id": "spruce_tea", "amount": 1, "cost": {"spruce_tips": 2}, "fire": true},
	{"id": "fur_cloak", "amount": 1, "cost": {"hide": 3}},
	{"id": "fox_hat", "amount": 1, "cost": {"fox_fur": 2}},
	{"id": "shelter", "amount": 1, "cost": {"wood": 10, "hide": 2, "birch_bark": 3}},
	{"id": "iron_axe", "amount": 1, "cost": {"wood": 2, "iron_ore": 3}, "fire": true},
	{"id": "iron_pickaxe", "amount": 1, "cost": {"wood": 2, "iron_ore": 3}, "fire": true},
	{"id": "bear_cloak", "amount": 1, "cost": {"bear_pelt": 1, "hide": 2}},
]


static func is_equippable(id: String) -> bool:
	return DATA.get(id, {}).get("kind", "") in EQUIP_KINDS


static func sort_key(id: String) -> int:
	return KIND_ORDER.find(DATA.get(id, {}).get("kind", "material")) * 100 + DATA.keys().find(id)


static func describe(id: String) -> String:
	var d: Dictionary = DATA.get(id, {})
	var lines := []
	if d.has("desc"):
		lines.append(d.desc)
	match d.get("kind", ""):
		"melee", "light":
			lines.append("Damage %d  •  Reach %d" % [d.damage, d.range])
		"ranged":
			lines.append("Damage %d  •  Uses arrows" % d.damage)
		"food":
			var fx := "Restores %d hunger" % d.hunger
			if d.heal > 0:
				fx += ", heals %d" % d.heal
			elif d.heal < 0:
				fx += ", but hurts %d unless cooked" % -d.heal
			if d.warm > 0:
				fx += ", warms %d" % d.warm
			lines.append(fx + ".")
		"material":
			lines.append("Crafting material.")
		"consumable":
			lines.append("Use it from the hotbar or inventory.")
		"ammo":
			lines.append("Ammunition for the bow.")
	return "\n".join(lines)


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
		"iron_axe":
			ci.draw_line(c + Vector2(-0.6, 0.75) * s, c + Vector2(0.45, -0.6) * s, dark_wood, s * 0.18)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.05, -0.85) * s, c + Vector2(0.85, -0.6) * s,
				c + Vector2(0.75, 0.15) * s, c + Vector2(0.25, -0.3) * s]), Color(0.5, 0.53, 0.58, alpha))
			ci.draw_line(c + Vector2(0.85, -0.6) * s, c + Vector2(0.75, 0.15) * s, Color(0.85, 0.88, 0.92, alpha), s * 0.1)
			ci.draw_circle(c + Vector2(0.3, -0.45) * s, s * 0.08, Color(0.3, 0.3, 0.33, alpha))
		"iron_pickaxe":
			ci.draw_line(c + Vector2(-0.6, 0.75) * s, c + Vector2(0.35, -0.45) * s, dark_wood, s * 0.18)
			var pts := PackedVector2Array()
			for i in 9:
				var a := lerpf(-2.7, 0.0, i / 8.0)
				pts.append(c + Vector2(0.15, -0.15) * s + Vector2(cos(a), sin(a)) * s * 0.82)
			ci.draw_polyline(pts, Color(0.48, 0.5, 0.56, alpha), s * 0.24, true)
			ci.draw_polyline(pts, Color(0.75, 0.78, 0.82, alpha), s * 0.07, true)
		"fishing_rod":
			var rp := PackedVector2Array()
			for i in 9:
				var t := i / 8.0
				rp.append(c + Vector2(lerpf(-0.75, 0.7, t), lerpf(0.8, -0.8, t) + sin(t * PI) * -0.1) * s)
			ci.draw_polyline(rp, wood, maxf(1.5, s * 0.1), true)
			ci.draw_line(rp[rp.size() - 1], c + Vector2(0.75, 0.35) * s, Color(0.9, 0.9, 0.9, alpha * 0.8), 1.0)
			ci.draw_circle(c + Vector2(0.75, 0.42) * s, s * 0.14, Color(0.9, 0.2, 0.2, alpha))
			ci.draw_circle(c + Vector2(-0.45, 0.45) * s, s * 0.14, Color(0.5, 0.52, 0.56, alpha))
		"shelter":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.85, 0.7) * s, c + Vector2(0.2, -0.75) * s, c + Vector2(0.85, 0.7) * s]), Color(0.6, 0.45, 0.3, alpha))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.3, 0.7) * s, c + Vector2(0.2, -0.1) * s, c + Vector2(0.55, 0.7) * s]), Color(0.2, 0.15, 0.12, alpha))
			ci.draw_line(c + Vector2(0.2, -0.75) * s, c + Vector2(0.4, -0.95) * s, dark_wood, s * 0.1)
			ci.draw_line(c + Vector2(0.2, -0.75) * s, c + Vector2(0.0, -0.95) * s, dark_wood, s * 0.1)
		"raw_fish", "cooked_fish":
			var col := Color(0.6, 0.66, 0.72, alpha) if id == "raw_fish" else Color(0.72, 0.5, 0.28, alpha)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.75, 0) * s, c + Vector2(-0.3, -0.4) * s, c + Vector2(0.4, -0.35) * s,
				c + Vector2(0.6, 0) * s, c + Vector2(0.4, 0.35) * s, c + Vector2(-0.3, 0.4) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.5, 0) * s, c + Vector2(0.95, -0.4) * s, c + Vector2(0.95, 0.4) * s]), col.darkened(0.15))
			ci.draw_circle(c + Vector2(-0.48, -0.08) * s, s * 0.08, Color(0.1, 0.1, 0.1, alpha))
			if id == "cooked_fish":
				for k in 3:
					ci.draw_line(c + Vector2(-0.2 + k * 0.25, -0.3) * s, c + Vector2(-0.3 + k * 0.25, 0.3) * s, Color(0.4, 0.22, 0.1, alpha), 1.5)
		"spruce_tea":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.5, -0.2) * s, c + Vector2(0.5, -0.2) * s, c + Vector2(0.4, 0.75) * s, c + Vector2(-0.4, 0.75) * s]), Color(0.55, 0.38, 0.24, alpha))
			ci.draw_arc(c + Vector2(0.55, 0.2) * s, s * 0.2, -PI * 0.5, PI * 0.5, 8, Color(0.55, 0.38, 0.24, alpha), maxf(1.5, s * 0.1))
			ci.draw_rect(Rect2(c + Vector2(-0.45, -0.2) * s, Vector2(0.9, 0.18) * s), Color(0.45, 0.6, 0.3, alpha))
			for k in 2:
				ci.draw_arc(c + Vector2(-0.15 + k * 0.3, -0.55) * s, s * 0.15, PI * 0.5, PI * 1.5, 6, Color(0.9, 0.9, 0.9, alpha * 0.6), 1.2)
		"bandage":
			ci.draw_circle(c, s * 0.62, Color(0.9, 0.86, 0.78, alpha))
			ci.draw_arc(c, s * 0.35, 0, TAU, 14, Color(0.75, 0.7, 0.6, alpha), 1.5)
			ci.draw_rect(Rect2(c + Vector2(-0.1, -0.35) * s, Vector2(0.2, 0.7) * s), Color(0.8, 0.2, 0.2, alpha))
			ci.draw_rect(Rect2(c + Vector2(-0.35, -0.1) * s, Vector2(0.7, 0.2) * s), Color(0.8, 0.2, 0.2, alpha))
		"birch_bark":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.7, -0.5) * s, c + Vector2(0.7, -0.6) * s, c + Vector2(0.75, 0.5) * s, c + Vector2(-0.65, 0.6) * s]), Color(0.93, 0.92, 0.88, alpha))
			for v in [Vector2(-0.4, -0.2), Vector2(0.2, 0.1), Vector2(-0.1, 0.35), Vector2(0.4, -0.35)]:
				ci.draw_line(c + v * s, c + (v + Vector2(0.25, 0)) * s, Color(0.15, 0.13, 0.12, alpha), maxf(1.0, s * 0.08))
			ci.draw_arc(c + Vector2(0.72, 0) * s, s * 0.2, -PI * 0.5, PI * 0.5, 8, Color(0.7, 0.6, 0.5, alpha), 1.5)
		"spruce_tips":
			ci.draw_line(c + Vector2(-0.6, 0.7) * s, c + Vector2(0.5, -0.6) * s, Color(0.4, 0.3, 0.2, alpha), maxf(1.0, s * 0.08))
			for k in 6:
				var b := c + Vector2(-0.45 + k * 0.18, 0.5 - k * 0.2) * s
				ci.draw_line(b, b + Vector2(-0.35, -0.12) * s, Color(0.45, 0.72, 0.35, alpha), maxf(1.0, s * 0.1))
				ci.draw_line(b, b + Vector2(0.12, 0.3) * s, Color(0.45, 0.72, 0.35, alpha), maxf(1.0, s * 0.1))
		"iron_ore":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.75, 0.45) * s, c + Vector2(-0.5, -0.4) * s,
				c + Vector2(0.15, -0.65) * s, c + Vector2(0.7, -0.15) * s, c + Vector2(0.7, 0.55) * s]), Color(0.36, 0.33, 0.33, alpha))
			for v in [Vector2(-0.3, 0.0), Vector2(0.2, -0.3), Vector2(0.35, 0.25), Vector2(-0.1, 0.35)]:
				ci.draw_circle(c + v * s, s * 0.12, Color(0.75, 0.4, 0.2, alpha))
		"bear_pelt", "fox_fur":
			var col := Color(0.38, 0.25, 0.15, alpha) if id == "bear_pelt" else Color(0.88, 0.48, 0.2, alpha)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.85, -0.6) * s, c + Vector2(-0.3, -0.75) * s,
				c + Vector2(0.3, -0.65) * s, c + Vector2(0.85, -0.75) * s, c + Vector2(0.6, 0.0) * s, c + Vector2(0.85, 0.75) * s,
				c + Vector2(0.0, 0.55) * s, c + Vector2(-0.85, 0.75) * s, c + Vector2(-0.6, 0.0) * s]), col)
			if id == "fox_fur":
				ci.draw_circle(c + Vector2(0, 0.1) * s, s * 0.22, Color(0.95, 0.93, 0.9, alpha))
			else:
				ci.draw_circle(c + Vector2(0, 0) * s, s * 0.25, col.lightened(0.15))
		"bear_cloak":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.4, -0.6) * s, c + Vector2(0.4, -0.6) * s,
				c + Vector2(0.8, 0.8) * s, c + Vector2(-0.8, 0.8) * s]), Color(0.36, 0.24, 0.15, alpha))
			for i in 5:
				ci.draw_circle(c + Vector2(-0.45 + i * 0.22, -0.6) * s, s * 0.2, Color(0.28, 0.18, 0.11, alpha))
		"fox_hat":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.7, 0.3) * s, c + Vector2(-0.55, -0.4) * s, c + Vector2(0, -0.65) * s,
				c + Vector2(0.55, -0.4) * s, c + Vector2(0.7, 0.3) * s]), Color(0.88, 0.48, 0.2, alpha))
			ci.draw_rect(Rect2(c + Vector2(-0.75, 0.2) * s, Vector2(1.5, 0.3) * s), Color(0.95, 0.93, 0.9, alpha))
			ci.draw_line(c + Vector2(0.5, -0.2) * s, c + Vector2(0.95, 0.6) * s, Color(0.88, 0.48, 0.2, alpha), s * 0.25)
			ci.draw_circle(c + Vector2(0.95, 0.65) * s, s * 0.14, Color(0.95, 0.93, 0.9, alpha))
		"rune":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.45, 0.8) * s, c + Vector2(-0.5, -0.5) * s, c + Vector2(0, -0.9) * s,
				c + Vector2(0.5, -0.5) * s, c + Vector2(0.45, 0.8) * s]), Color(0.5, 0.53, 0.58, alpha))
			ci.draw_line(c + Vector2(-0.1, -0.45) * s, c + Vector2(-0.1, 0.5) * s, Color(0.55, 0.85, 1.0, alpha), maxf(1.0, s * 0.1))
			ci.draw_line(c + Vector2(-0.1, -0.45) * s, c + Vector2(0.2, -0.15) * s, Color(0.55, 0.85, 1.0, alpha), maxf(1.0, s * 0.1))
			ci.draw_line(c + Vector2(0.2, -0.15) * s, c + Vector2(-0.1, 0.1) * s, Color(0.55, 0.85, 1.0, alpha), maxf(1.0, s * 0.1))
		"cabin":
			ci.draw_rect(Rect2(c + Vector2(-0.7, -0.1) * s, Vector2(1.4, 0.85) * s), Color(0.5, 0.33, 0.2, alpha))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.9, -0.05) * s, c + Vector2(0, -0.85) * s, c + Vector2(0.9, -0.05) * s]), Color(0.88, 0.92, 0.97, alpha))
			ci.draw_rect(Rect2(c + Vector2(-0.15, 0.25) * s, Vector2(0.3, 0.5) * s), Color(0.25, 0.16, 0.1, alpha))
		"heart":
			var col := Color(0.86, 0.22, 0.24, alpha)
			ci.draw_circle(c + Vector2(-0.38, -0.22) * s, s * 0.45, col)
			ci.draw_circle(c + Vector2(0.38, -0.22) * s, s * 0.45, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.8, -0.05) * s, c + Vector2(0.8, -0.05) * s, c + Vector2(0, 0.85) * s]), col)
		"bolt":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.2, -0.9) * s, c + Vector2(-0.5, 0.1) * s, c + Vector2(0, 0.1) * s,
				c + Vector2(-0.2, 0.9) * s, c + Vector2(0.5, -0.1) * s, c + Vector2(0, -0.1) * s]), Color(0.95, 0.85, 0.3, alpha))
		"flame":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.6, 0.6) * s, c + Vector2(-0.4, -0.2) * s, c + Vector2(0, -0.9) * s,
				c + Vector2(0.4, -0.2) * s, c + Vector2(0.6, 0.6) * s]), Color(1.0, 0.5, 0.15, alpha))
			ci.draw_circle(c + Vector2(0, 0.3) * s, s * 0.3, Color(1, 0.9, 0.5, alpha))
		"snow":
			for k in 3:
				var d := Vector2.from_angle(PI * k / 3.0) * s * 0.85
				ci.draw_line(c - d, c + d, Color(0.6, 0.85, 1.0, alpha), maxf(1.5, s * 0.15))
		"paw":
			var col := Color(0.55, 0.57, 0.62, alpha)
			ci.draw_circle(c + Vector2(0, 0.3) * s, s * 0.4, col)
			for v in [Vector2(-0.55, -0.25), Vector2(-0.2, -0.6), Vector2(0.2, -0.6), Vector2(0.55, -0.25)]:
				ci.draw_circle(c + v * s, s * 0.18, col)
		_:
			ci.draw_circle(c, s * 0.5, Color(1, 0, 1, alpha))
