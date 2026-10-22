class_name Skills
extends RefCounted
## Skill tree definition. Three branches, four skills each. `col`/`row` place a node inside its branch,
## `req` is the parent skill that needs at least one rank first.

const BRANCHES := [
	{"id": "woodcraft", "name": "Woodcraft", "color": Color(0.55, 0.8, 0.45)},
	{"id": "hunter", "name": "Hunter", "color": Color(0.95, 0.55, 0.4)},
	{"id": "survival", "name": "Survivalist", "color": Color(0.55, 0.78, 1.0)},
]

const DATA := {
	# --- Woodcraft
	"lumberjack": {"branch": "woodcraft", "name": "Lumberjack", "icon": "axe", "max": 3, "col": 0.5, "row": 0, "req": "",
		"desc": "+25% chopping damage per rank."},
	"stonebreaker": {"branch": "woodcraft", "name": "Stonebreaker", "icon": "pickaxe", "max": 3, "col": 0.0, "row": 1, "req": "lumberjack",
		"desc": "+25% mining damage per rank."},
	"firekeeper": {"branch": "woodcraft", "name": "Firekeeper", "icon": "campfire", "max": 2, "col": 1.0, "row": 1, "req": "lumberjack",
		"desc": "Campfires burn 30% longer per rank."},
	"bountiful": {"branch": "woodcraft", "name": "Bountiful", "icon": "wood", "max": 2, "col": 0.5, "row": 2, "req": "stonebreaker",
		"desc": "25% chance per rank of an extra wood, stone or berry."},
	# --- Hunter
	"keen_edge": {"branch": "hunter", "name": "Keen Edge", "icon": "spear", "max": 3, "col": 0.5, "row": 0, "req": "",
		"desc": "+15% melee damage to animals per rank."},
	"marksman": {"branch": "hunter", "name": "Marksman", "icon": "bow", "max": 3, "col": 0.0, "row": 1, "req": "keen_edge",
		"desc": "+20% arrow damage per rank."},
	"butcher": {"branch": "hunter", "name": "Butcher", "icon": "raw_meat", "max": 1, "col": 1.0, "row": 1, "req": "keen_edge",
		"desc": "Animals drop one extra raw meat."},
	"wolfbane": {"branch": "hunter", "name": "Wolfbane", "icon": "paw", "max": 2, "col": 0.5, "row": 2, "req": "marksman",
		"desc": "Take 20% less damage from wolves per rank."},
	# --- Survivalist
	"thick_blood": {"branch": "survival", "name": "Thick Blood", "icon": "snow", "max": 3, "col": 0.5, "row": 0, "req": "",
		"desc": "Lose warmth 15% slower per rank."},
	"iron_stomach": {"branch": "survival", "name": "Iron Stomach", "icon": "cooked_meat", "max": 2, "col": 0.0, "row": 1, "req": "thick_blood",
		"desc": "Hunger drains 15% slower per rank. Rank 2: raw meat no longer makes you sick."},
	"endurance": {"branch": "survival", "name": "Endurance", "icon": "bolt", "max": 2, "col": 1.0, "row": 1, "req": "thick_blood",
		"desc": "Sprinting costs 20% less stamina and stamina recovers 25% faster per rank."},
	"vitality": {"branch": "survival", "name": "Vitality", "icon": "heart", "max": 2, "col": 0.5, "row": 2, "req": "endurance",
		"desc": "+20 maximum health per rank."},
}

## XP rewards.
const XP := {
	"chop": 1, "fell": 6, "mine": 1, "break": 5, "forage": 2, "craft": 4, "cook": 2, "build": 3, "dawn": 40,
	"hare": 5, "deer": 12, "wolf": 25,
}


static func xp_to_next(level: int) -> int:
	var l := level - 1
	return 40 + 30 * l + 5 * l * l
