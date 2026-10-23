extends Node
## Save slots on disk (user://saves/slot_N.json). The game scene reads `pending` on start
## to know whether to load a save or begin a new world.

const SLOTS := 3
const VERSION := 1
const DIR := "user://saves"

var current_slot := -1
var pending: Dictionary = {}  # save data to restore when the next Game scene starts


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func path(slot: int) -> String:
	return "%s/slot_%d.json" % [DIR, slot + 1]


func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


func any_saves() -> bool:
	for i in SLOTS:
		if exists(i):
			return true
	return false


func read(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var f := FileAccess.open(path(slot), FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


func write(slot: int, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	data["version"] = VERSION
	data["saved_at"] = Time.get_unix_time_from_system()
	# write to a temp file first so a crash mid-save can't corrupt the slot
	var tmp := path(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return DirAccess.rename_absolute(tmp, path(slot)) == OK


func delete(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(path(slot))


## Small summary for slot lists (reads the whole file; saves are small).
func summary(slot: int) -> Dictionary:
	var d := read(slot)
	if d.is_empty():
		return {}
	return {
		"day": int(d.get("day", 1)),
		"level": int(d.get("player", {}).get("level", 1)),
		"play_time": float(d.get("play_time", 0.0)),
		"saved_at": float(d.get("saved_at", 0.0)),
		"difficulty": int(d.get("difficulty", 1)),
	}


func latest_slot() -> int:
	var best := -1
	var best_t := -1.0
	for i in SLOTS:
		var s := summary(i)
		if not s.is_empty() and s.saved_at > best_t:
			best_t = s.saved_at
			best = i
	return best


func first_empty_slot() -> int:
	for i in SLOTS:
		if not exists(i):
			return i
	return -1


## Prepare a fresh world in `slot` (an existing save there is overwritten).
func start_new(slot: int) -> void:
	current_slot = slot
	delete(slot)
	pending = {}


## Prepare to load `slot` when the game scene starts.
func start_load(slot: int) -> bool:
	var d := read(slot)
	if d.is_empty():
		return false
	current_slot = slot
	pending = d
	return true


static func format_time(seconds: float) -> String:
	var m := int(seconds / 60.0)
	if m < 60:
		return "%d min" % m
	return "%dh %02dm" % [m / 60, m % 60]


static func format_date(unix: float) -> String:
	var d := Time.get_datetime_dict_from_unix_time(int(unix + Time.get_time_zone_from_system().bias * 60))
	return "%04d-%02d-%02d %02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute]
