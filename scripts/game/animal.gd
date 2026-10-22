class_name Animal
extends CharacterBody2D
## Wildlife: wolves (hunt the player, fear fire and torches), deer and hares (flee, drop meat and hide).

const STATS := {
	"wolf": {"hp": 45.0, "walk": 70.0, "run": 168.0, "radius": 11.0, "damage": 9.0},
	"deer": {"hp": 32.0, "walk": 55.0, "run": 190.0, "radius": 13.0, "damage": 0.0},
	"hare": {"hp": 10.0, "walk": 45.0, "run": 205.0, "radius": 7.0, "damage": 0.0},
}

var kind := "animal"
var species := "deer"
var hp := 30.0
var max_hp := 30.0
var state := "wander"

var _game: Node
var _st: Dictionary
var _dir := Vector2.RIGHT
var _timer := 0.0
var _bite_cd := 0.0
var _retreat := 0.0
var _fear := 0.0
var _flash := 0.0
var _walk := 0.0
var _facing := 1.0
var _knock := Vector2.ZERO
var _stuck := 0.0
var _growl_cd := 0.0
var _orbit := 1.0
var _moving := false


func setup(game: Node, sp: String) -> void:
	_game = game
	species = sp
	_st = STATS[sp]
	hp = _st.hp
	max_hp = hp
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = _st.radius
	cs.shape = c
	cs.position = Vector2(0, -4)
	add_child(cs)
	_dir = Vector2.from_angle(randf() * TAU)
	_orbit = 1.0 if randf() < 0.5 else -1.0
	add_to_group("hittable")
	add_to_group("animals")
	add_to_group(sp)


func _physics_process(delta: float) -> void:
	var player: Node2D = _game.player
	var to_p: Vector2 = player.global_position - global_position
	var dist := to_p.length()
	_timer -= delta
	_bite_cd -= delta
	_retreat -= delta
	_fear -= delta
	_flash -= delta
	_growl_cd -= delta

	var desired := Vector2.ZERO
	if species == "wolf":
		desired = _wolf_ai(player, to_p, dist)
	else:
		desired = _prey_ai(player, to_p, dist)

	# keep inside the world
	var lim: float = Game.WORLD_HALF - 80.0
	if absf(global_position.x) > lim or absf(global_position.y) > lim:
		desired = -global_position.normalized() * maxf(desired.length(), _st.walk)

	velocity = desired + _knock
	_knock = _knock.move_toward(Vector2.ZERO, delta * 700.0)
	move_and_slide()

	# unstick from trees by turning
	if desired.length() > 20 and get_real_velocity().length() < desired.length() * 0.35:
		_stuck += delta
		if _stuck > 0.3:
			_dir = desired.normalized().rotated(PI * 0.5 * (1 if randf() < 0.5 else -1))
			_timer = 0.6
			state = "dodge"
			_stuck = 0.0
	else:
		_stuck = maxf(0.0, _stuck - delta)

	_moving = velocity.length() > 8
	if absf(velocity.x) > 5:
		_facing = signf(velocity.x)
	if _moving:
		_walk += delta * velocity.length() * 0.09
	if dist > 1900:
		queue_free()
	queue_redraw()


func _prey_ai(player: Node2D, to_p: Vector2, dist: float) -> Vector2:
	if state == "dodge" and _timer > 0:
		return _dir * _st.run
	var flee_r := 200.0 if species == "deer" else 150.0
	if player.get("sprinting"):
		flee_r *= 1.5
	if _fear > 0 or (dist < flee_r and not player.dead):
		state = "flee"
		return -to_p.normalized() * _st.run
	state = "wander"
	if _timer <= 0:
		_timer = randf_range(1.5, 4.0)
		_dir = Vector2.ZERO if randf() < 0.4 else Vector2.from_angle(randf() * TAU)
	return _dir * _st.walk


func _wolf_ai(player: Node2D, to_p: Vector2, dist: float) -> Vector2:
	if state == "dodge" and _timer > 0:
		return _dir * _st.run
	var night: bool = _game.is_night()
	var aggro := 560.0 if night else 260.0
	if state == "chase":
		aggro *= 1.6
	if hp < max_hp * 0.3 or _fear > 0:
		state = "flee"
		return -to_p.normalized() * _st.run
	if player.dead or dist > aggro:
		state = "wander"
		if _timer <= 0:
			_timer = randf_range(2.0, 5.0)
			_dir = Vector2.ZERO if randf() < 0.3 else Vector2.from_angle(randf() * TAU)
		return _dir * _st.walk
	var fire: Node2D = _game.fire_near(player.global_position, 60.0)
	if fire:
		# Too afraid to approach the fire: circle it at a distance.
		state = "circle"
		var from_fire: Vector2 = global_position - fire.global_position
		var fd := from_fire.length()
		var keep := 250.0
		var radial := from_fire.normalized() * clampf((keep - fd) / 40.0, -1.0, 1.0)
		var tangent := from_fire.normalized().orthogonal() * _orbit * 0.7
		if _growl_cd <= 0 and fd < 340:
			_growl_cd = randf_range(4, 8)
			Audio.play_at("growl", global_position, -4)
		return (radial + tangent).normalized() * _st.walk * 1.3
	state = "chase"
	var torch: bool = player.holding("torch")
	if _retreat > 0:
		return -to_p.normalized() * _st.run * 0.8
	if torch and dist < 95 and _bite_cd > -1.2:
		# Hesitate around a torch, circling the player before lunging.
		return to_p.normalized().orthogonal() * _orbit * _st.walk * 1.4 - to_p.normalized() * 30.0
	if dist < 30 and _bite_cd <= 0:
		_bite()
	return to_p.normalized() * _st.run


func _bite() -> void:
	_bite_cd = 1.4
	_retreat = 0.55
	var dmg: float = _st.damage * Settings.difficulty_mult()
	Audio.play_at("growl", global_position, 0)
	_game.player.take_damage(dmg, "wolves", global_position)


func hit(damage: float, tool_id: String, source: Node2D) -> void:
	hp -= damage
	_flash = 0.15
	var away := (global_position - source.global_position).normalized()
	_knock = away * (320.0 if tool_id != "bow" else 160.0)
	_game.damage_number(global_position + Vector2(0, -30), damage)
	_game.blood(global_position + Vector2(0, -10))
	Audio.play_at("arrow_hit", global_position, -6)
	if tool_id == "torch":
		_fear = 3.5
	if species != "wolf":
		_fear = 6.0
	else:
		_growl_cd = 0
		state = "chase"
	if hp <= 0:
		_die()


func _die() -> void:
	Audio.play_at("animal_die", global_position, -2)
	var drops: Dictionary = {"wolf": {"raw_meat": 1, "hide": 1}, "deer": {"raw_meat": 2, "hide": randi_range(1, 2)}, "hare": {"raw_meat": 1}}[species]
	drops.raw_meat += _game.player.skill("butcher")
	_game.player.add_xp(Skills.XP[species])
	for id in drops:
		for i in drops[id]:
			_game.spawn_drop(id, 1, global_position + Vector2(randf_range(-22, 22), randf_range(-8, 14)), global_position)
	_game.blood(global_position, 18)
	if species == "wolf":
		_game.message("A wolf falls.")
	queue_free()


# ---------------------------------------------------------------- drawing
func _p(v: Vector2) -> Vector2:
	return Vector2(v.x * _facing, v.y)


func _ell(c: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		pts.append(_p(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot)))
	draw_colored_polygon(pts, col)


func _leg(top: Vector2, length: float, phase: float, col: Color, w: float) -> void:
	var swing := sin(_walk + phase) * 4.0 if _moving else 0.0
	draw_line(_p(top), _p(top + Vector2(swing, length)), col, w)


func _draw() -> void:
	var tint := Color(1, 0.45, 0.45) if _flash > 0 else Color.WHITE
	var r: float = _st.radius
	draw_set_transform(Vector2(3, 0), 0, Vector2(1, 0.38))
	draw_circle(Vector2.ZERO, r * 1.5, Color(0.1, 0.15, 0.25, 0.25))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	match species:
		"wolf":
			_draw_wolf(tint)
		"deer":
			_draw_deer(tint)
		"hare":
			_draw_hare(tint)


func _draw_wolf(tint: Color) -> void:
	var fur := Color(0.47, 0.49, 0.52) * tint
	var dark := Color(0.3, 0.31, 0.34) * tint
	var light := Color(0.78, 0.79, 0.8) * tint
	var lunge := -3.0 if state == "chase" and _bite_cd > 1.1 else 0.0
	for l in [[-10, 0.0], [-5, PI], [7, PI * 0.5], [12, PI * 1.5]]:
		_leg(Vector2(l[0], -11), 11, l[1], dark, 3.0)
	# tail
	var tw := sin(_walk * 0.5) * 2.0
	draw_polyline(PackedVector2Array([_p(Vector2(-15, -16)), _p(Vector2(-22, -14 + tw)), _p(Vector2(-27, -9 + tw))]), dark, 4.0, true)
	_ell(Vector2(0, -15), 17, 7.5, fur)
	_ell(Vector2(-1, -19), 14, 3.5, dark)
	_ell(Vector2(2, -11), 11, 3, light)
	# head
	var hp_ := Vector2(17 + lunge * -1, -21)
	_ell(hp_, 7, 6, fur)
	_ell(hp_ + Vector2(7, 2), 5.5, 3.2, light)
	draw_circle(_p(hp_ + Vector2(12, 1.5)), 1.6, Color(0.1, 0.1, 0.1))
	draw_colored_polygon(PackedVector2Array([_p(hp_ + Vector2(-5, -3)), _p(hp_ + Vector2(-3, -11)), _p(hp_ + Vector2(0, -4))]), dark)
	draw_colored_polygon(PackedVector2Array([_p(hp_ + Vector2(0, -4)), _p(hp_ + Vector2(2, -11)), _p(hp_ + Vector2(4, -3))]), dark)
	var eye := Color(1.0, 0.85, 0.2) if _game.is_night() else Color(0.85, 0.65, 0.2)
	draw_circle(_p(hp_ + Vector2(3, -1.5)), 1.5, eye)


func _draw_deer(tint: Color) -> void:
	var fur := Color(0.52, 0.36, 0.22) * tint
	var dark := Color(0.36, 0.24, 0.14) * tint
	var belly := Color(0.82, 0.72, 0.58) * tint
	for l in [[-11, 0.0], [-6, PI], [8, PI * 0.5], [13, PI * 1.5]]:
		_leg(Vector2(l[0], -15), 15, l[1], dark, 2.6)
	_ell(Vector2(0, -21), 17, 8.5, fur)
	_ell(Vector2(1, -16), 12, 3, belly)
	_ell(Vector2(-17, -24), 3, 3.5, Color(0.95, 0.93, 0.9) * tint)
	# neck + head
	draw_line(_p(Vector2(12, -24)), _p(Vector2(17, -34)), fur, 7.0)
	var h := Vector2(19, -36)
	_ell(h, 5.5, 4.5, fur)
	_ell(h + Vector2(5, 1.5), 3.5, 2.5, dark)
	draw_circle(_p(h + Vector2(1, -1)), 1.2, Color(0.05, 0.05, 0.05))
	_ell(h + Vector2(-4, -4), 2.5, 1.5, dark, -0.5)
	# antlers
	var ant := Color(0.85, 0.78, 0.62) * tint
	for side in [-1.5, 1.5]:
		var b := h + Vector2(side, -4)
		draw_polyline(PackedVector2Array([_p(b), _p(b + Vector2(-2, -8)), _p(b + Vector2(-6, -14))]), ant, 1.6)
		draw_line(_p(b + Vector2(-2, -8)), _p(b + Vector2(3, -12)), ant, 1.4)
		draw_line(_p(b + Vector2(-4, -11)), _p(b + Vector2(-9, -12)), ant, 1.2)


func _draw_hare(tint: Color) -> void:
	var fur := Color(0.95, 0.95, 0.97) * tint
	var shade := Color(0.78, 0.8, 0.85) * tint
	var hop := -absf(sin(_walk * 0.8)) * 6.0 if _moving else 0.0
	var o := Vector2(0, hop)
	_ell(o + Vector2(-1, -6), 8, 5.5, fur)
	_ell(o + Vector2(-2, -3), 6, 2.5, shade)
	_ell(o + Vector2(6, -10), 4.5, 4, fur)
	_ell(o + Vector2(4, -18), 1.6, 6, fur, -0.25)
	_ell(o + Vector2(7, -18), 1.6, 6, shade, 0.15)
	draw_circle(_p(o + Vector2(8, -11)), 1.1, Color(0.1, 0.1, 0.1))
	_ell(o + Vector2(-8, -7), 2.5, 2.5, Color.WHITE * tint)
