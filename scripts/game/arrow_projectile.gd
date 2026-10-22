class_name ArrowProjectile
extends Node2D
## A flying arrow. Raycasts each frame against trees, rocks and animals.

var velocity := Vector2.ZERO
var damage := 30.0
var _life := 1.3
var _stuck := -1.0
var _exclude: Array[RID] = []
var _height := 16.0
var _angle := 0.0


func launch(from: Vector2, dir: Vector2, dmg: float, shooter: CollisionObject2D) -> void:
	global_position = from
	velocity = dir * 720.0
	damage = dmg
	_angle = dir.angle()
	_exclude = [shooter.get_rid()]


func _physics_process(delta: float) -> void:
	if _stuck >= 0:
		_stuck += delta
		modulate.a = clampf(1.0 - (_stuck - 1.5), 0, 1)
		if _stuck > 2.5:
			queue_free()
		return
	_life -= delta
	if _life <= 0:
		queue_free()
		return
	var step := velocity * delta
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1 | 4, _exclude)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		global_position = hit.position
		var col: Object = hit.collider
		if col.get("kind") == "animal":
			col.hit(damage, "bow", self)
			queue_free()
			return
		Audio.play_at("arrow_hit", global_position, -4)
		_stuck = 0.0
		return
	global_position += step


func _draw() -> void:
	draw_set_transform(Vector2(0, -_height), _angle, Vector2.ONE)
	draw_line(Vector2(-16, 0), Vector2(8, 0), Color(0.7, 0.55, 0.35), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(13, 0), Vector2(6, -3), Vector2(6, 3)]), Color(0.45, 0.48, 0.53))
	draw_line(Vector2(-16, 0), Vector2(-11, -3), Color(0.92, 0.92, 0.92), 2.0)
	draw_line(Vector2(-16, 0), Vector2(-11, 3), Color(0.92, 0.92, 0.92), 2.0)
