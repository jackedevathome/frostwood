class_name Journal
extends RefCounted
## Survival goals. Each one listens for an event counted by Game.track() and pays out XP when reached.

const GOALS := [
	{"id": "wood", "text": "Gather 10 wood", "event": "gather_wood", "target": 10, "xp": 15},
	{"id": "fire", "text": "Build a campfire", "event": "build_campfire", "target": 1, "xp": 20},
	{"id": "cook", "text": "Cook a meal over the fire", "event": "cook", "target": 1, "xp": 15},
	{"id": "night", "text": "Survive your first night", "event": "dawn", "target": 1, "xp": 30},
	{"id": "bow", "text": "Craft a bow", "event": "craft_bow", "target": 1, "xp": 20},
	{"id": "rune", "text": "Read a rune stone", "event": "rune", "target": 1, "xp": 20},
	{"id": "fish", "text": "Catch a fish through the ice", "event": "fish", "target": 1, "xp": 25},
	{"id": "cabin", "text": "Loot an abandoned cabin", "event": "cabin", "target": 1, "xp": 25},
	{"id": "iron", "text": "Forge an iron tool", "event": "craft_iron", "target": 1, "xp": 40},
	{"id": "wolf", "text": "Hunt a wolf", "event": "kill_wolf", "target": 1, "xp": 30},
	{"id": "sleep", "text": "Sleep in a shelter until dawn", "event": "sleep", "target": 1, "xp": 40},
	{"id": "bear", "text": "Slay a brown bear", "event": "kill_bear", "target": 1, "xp": 100},
	{"id": "runes", "text": "Read all six rune stones", "event": "rune", "target": 6, "xp": 120},
	{"id": "week", "text": "Survive seven days", "event": "dawn", "target": 7, "xp": 150},
]
