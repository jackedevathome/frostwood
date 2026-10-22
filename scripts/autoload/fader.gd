extends CanvasLayer
## Fades to black between scenes.

var _rect: ColorRect
var busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.02, 0.03, 0.05, 0.0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func change_scene(path: String, duration := 0.5) -> void:
	if busy:
		return
	busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, duration)
	await tw.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_rect, "color:a", 0.0, duration)
	await tw2.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false


func fade_in(duration := 1.0) -> void:
	_rect.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 0.0, duration)
