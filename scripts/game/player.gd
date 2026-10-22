class_name Player
extends CharacterBody2D
## The survivor. WASD to move, mouse to aim, left click to use the item in the selected hotbar slot.

signal died(cause: String)
signal leveled_up(level: int)

const WALK := 135.0
const SPRINT := 215.0
const SLOTS := 3

var health := 100.0
var max_health := 100.0
var hunger := 100.0
var warmth := 100.0
var stamina := 100.0
var inventory := {"axe": 1, "pickaxe": 1, "berries": 2}
var hotbar: Array[String] = ["axe", "pickaxe", "berries"]
var selected := 0
var aim := Vector2.RIGHT
var sprinting := false
var dead := false
var heat := 0.0
var placing := false  # campfire placement mode

var level := 1
var xp := 0
var skill_points := 0
var skills := {}

var _game: Node
var _cooldown := 0.0
var _swing := 0.0
var _swing_dur := 0.3
var _walk := 0.0
var _step_dist := 0.0
var _hurt := 0.0
var _use_held := false
var _exhausted := false
var _torch_light: PointLight2D
var _self_light: PointLight2D
var _starve_msg := 0.0
var _eat_cd := 0.0


func setup(game: Node) -> void:
	_game = game
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9.0
	cs.shape = c
	cs.position = Vector2(0, -4)
	add_child(cs)
	# Faint personal light so the player is never fully lost in darkness.
	_self_light = PointLight2D.new()
	_self_light.texture = Game.light_texture()
	_self_light.texture_scale = 1.1
	_self_light.energy = 0.35
	_self_light.color = Color(0.75, 0.82, 1.0)
	add_child(_self_light)
	_torch_light = PointLight2D.new()
	_torch_light.texture = Game.light_texture()
	_torch_light.texture_scale = 2.1
	_torch_light.energy = 1.1
	_torch_light.color = Color(1.0, 0.68, 0.35)
	_torch_light.visible = false
	add_child(_torch_light)


# ---------------------------------------------------------------- inventory & hotbar
## The item currently in hand ("" for an empty slot).
func current_item() -> String:
	if placing:
		return "campfire"
	return hotbar[selected]


func holding(id: String) -> bool:
	return current_item() == id and count(id) > 0


func count(id: String) -> int:
	return inventory.get(id, 0)


func add_item(id: String, n: int) -> void:
	inventory[id] = inventory.get(id, 0) + n


func remove_item(id: String, n: int) -> bool:
	if count(id) < n:
		return false
	inventory[id] -= n
	if inventory[id] <= 0:
		inventory.erase(id)
	return true


func best_food() -> String:
	for f in Items.FOOD_PRIORITY:
		if count(f) > 0:
			return f
	return ""


## Puts `id` into hotbar slot `slot`. If it is already in another slot the two slots swap.
func assign_slot(slot: int, id: String) -> void:
	if slot < 0 or slot >= SLOTS or (id != "" and not Items.is_equippable(id)):
		return
	var old := hotbar.find(id)
	if old >= 0 and id != "":
		hotbar[old] = hotbar[slot]
	hotbar[slot] = id
	Audio.play("ui_click", -8, 0.05)


## Equips a freshly crafted item into an empty slot, if there is one.
func auto_equip(id: String) -> bool:
	if not Items.is_equippable(id) or id in hotbar:
		return id in hotbar
	var empty := hotbar.find("")
	if empty >= 0:
		hotbar[empty] = id
		return true
	return false


func select(i: int) -> void:
	placing = false
	i = posmod(i, SLOTS)
	if i == selected:
		return
	selected = i
	Audio.play("ui_hover", -6, 0.1)


func start_placing() -> void:
	if count("campfire") <= 0:
		return
	placing = true
	_game.message("Place the campfire: Left click to build, Right click to cancel.", UITheme.WARM)


func cancel_placing() -> void:
	if placing:
		placing = false
		_game.message("Placement cancelled. The campfire is in your inventory.")


# ---------------------------------------------------------------- xp & skills
func skill(id: String) -> int:
	return skills.get(id, 0)


func can_learn(id: String) -> bool:
	var d: Dictionary = Skills.DATA[id]
	if skill_points <= 0 or skill(id) >= d.max:
		return false
	return d.req == "" or skill(d.req) > 0


func learn(id: String) -> bool:
	if not can_learn(id):
		return false
	skills[id] = skill(id) + 1
	skill_points -= 1
	if id == "vitality":
		max_health = 100.0 + 20.0 * skill("vitality")
		health += 20.0
	return true


func add_xp(amount: int) -> void:
	if dead or amount <= 0:
		return
	xp += amount
	if amount >= 4:
		_game.xp_text(global_position + Vector2(0, -44), amount)
	while xp >= Skills.xp_to_next(level):
		xp -= Skills.xp_to_next(level)
		level += 1
		skill_points += 1
		leveled_up.emit(level)


# ---------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if dead or get_tree().paused:
		return
	if event.is_action_pressed("use"):
		_use_held = true
		_try_use(true)
	elif event.is_action_pressed("alt_use"):
		if placing:
			cancel_placing()
		else:
			eat(best_food())
	elif event.is_action_pressed("interact"):
		_game.interact()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select(selected + 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select(selected - 1)
	for i in range(1, SLOTS + 1):
		if event.is_action_pressed("slot_%d" % i):
			select(i - 1)


func _input(event: InputEvent) -> void:
	if event.is_action_released("use"):
		_use_held = false


func _physics_process(delta: float) -> void:
	if dead:
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	sprinting = Input.is_action_pressed("sprint") and input != Vector2.ZERO and not _exhausted
	var spd := SPRINT if sprinting else WALK
	if hunger <= 0:
		spd *= 0.8
	var accel := 14.0
	if _game.on_ice(global_position):
		accel = 2.2
	velocity = velocity.lerp(input * spd, 1.0 - exp(-delta * accel))
	move_and_slide()

	var moved := get_real_velocity().length() * delta
	if moved > 0.05:
		_walk += moved * 0.16
		_step_dist += moved
		if _step_dist > (34.0 if sprinting else 28.0):
			_step_dist = 0
			Audio.play("step%d" % randi_range(0, 3), -15 if not sprinting else -11, 0.15)

	var hand := global_position + Vector2(0, -16)
	var to_mouse := get_global_mouse_position() - hand
	if to_mouse.length() > 4:
		aim = to_mouse.normalized()

	_cooldown -= delta
	_eat_cd -= delta
	if _swing > 0:
		_swing = maxf(0.0, _swing - delta / _swing_dur)
	if _use_held:
		_try_use(false)
	_hurt -= delta
	if placing and count("campfire") <= 0:
		placing = false
	_update_stats(delta)
	var dark: float = _game.darkness()
	_self_light.energy = 0.4 * dark
	_torch_light.visible = holding("torch")
	if _torch_light.visible:
		_torch_light.position = Vector2(0, -16) + aim * 14 + Vector2(0, -8)
		_torch_light.energy = (1.05 + 0.1 * sin(Time.get_ticks_msec() * 0.02) + randf() * 0.05) * (0.15 + 0.85 * dark)
	queue_redraw()


func _update_stats(delta: float) -> void:
	var diff := Settings.difficulty_mult()
	hunger -= 0.17 * diff * delta * (1.4 if sprinting else 1.0) * (1.0 - 0.15 * skill("iron_stomach"))
	var night: float = _game.darkness()
	heat = _game.heat_at(global_position)
	if heat > 0.0:
		warmth += (4.0 + 10.0 * heat) * delta
	else:
		var drain := (0.28 + 0.9 * night) * diff * (1.0 - 0.15 * skill("thick_blood"))
		if count("fur_cloak") > 0:
			drain *= 0.5
		if holding("torch"):
			drain *= 0.65
		warmth -= drain * delta
	var endurance := skill("endurance")
	if sprinting:
		stamina -= 22.0 * (1.0 - 0.2 * endurance) * delta
		if stamina <= 0:
			stamina = 0
			_exhausted = true
	else:
		stamina += (16.0 if velocity.length() < 10 else 11.0) * (1.0 + 0.25 * endurance) * delta
		if stamina > 30:
			_exhausted = false
	if hunger <= 0:
		_drain_health(0.9 * delta, "starvation")
	if warmth <= 0:
		_drain_health(1.4 * delta, "cold")
	if hunger > 45 and warmth > 30:
		health += 0.5 * delta
	hunger = clampf(hunger, 0, 100)
	warmth = clampf(warmth, 0, 100)
	stamina = clampf(stamina, 0, 100)
	health = clampf(health, 0, max_health)
	_starve_msg -= delta
	if _starve_msg <= 0 and (hunger <= 0 or warmth <= 0):
		_starve_msg = 12.0
		_game.message("You are starving!" if hunger <= 0 else "You are freezing! Find a fire.", Color(1, 0.55, 0.45))


func _drain_health(amount: float, cause: String) -> void:
	health -= amount
	if health <= 0:
		_die(cause)


func take_damage(amount: float, cause: String, from := Vector2.INF) -> void:
	if dead:
		return
	if cause == "wolves":
		amount *= 1.0 - 0.2 * skill("wolfbane")
	health -= amount
	_hurt = 0.25
	Audio.play("hurt", -2, 0.1)
	_game.shake(7.0)
	_game.flash_damage()
	if from != Vector2.INF:
		velocity += (global_position - from).normalized() * 260
	if health <= 0:
		health = 0
		_die(cause)


func _die(cause: String) -> void:
	if dead:
		return
	dead = true
	health = 0
	placing = false
	_use_held = false
	_torch_light.visible = false
	queue_redraw()
	died.emit(cause)


func eat(f: String) -> void:
	if f == "" or count(f) <= 0:
		_game.message("You have nothing to eat.", Color(1, 0.7, 0.5))
		return
	if _eat_cd > 0:
		return
	var d: Dictionary = Items.DATA[f]
	var heal: float = d.heal
	if heal < 0 and skill("iron_stomach") >= 2:
		heal = 0.0
	if hunger >= 99.5 and heal <= 0:
		_game.message("You are not hungry.")
		return
	remove_item(f, 1)
	hunger = minf(100, hunger + d.hunger)
	warmth = minf(100, warmth + d.warm)
	_eat_cd = 0.5
	Audio.play("eat", -3)
	if heal < 0:
		take_damage(-heal, "food poisoning")
		_game.message("Raw meat upsets your stomach. Cook it at a fire!", Color(1, 0.6, 0.5))
	else:
		health = minf(max_health, health + heal)
		_game.message("Ate %s" % Items.item_name(f))


func _try_use(just_pressed: bool) -> void:
	if _cooldown > 0 or dead:
		return
	var id := current_item()
	if id == "":
		if just_pressed:
			_game.message("This slot is empty. Open your inventory (%s) to fill it." % Settings.key_name("inventory"))
		return
	if count(id) <= 0:
		if just_pressed:
			_game.message("You have no %s left." % Items.item_name(id))
		return
	var d: Dictionary = Items.DATA[id]
	match d.kind:
		"food":
			if just_pressed:
				eat(id)
		"melee", "light":
			_cooldown = d.cooldown
			_swing_dur = d.cooldown * 0.75
			_swing = 1.0
			Audio.play("swing", -8, 0.15)
			var origin := global_position + Vector2(0, -6)
			var target: Node2D = _game.find_target(origin, aim, d.range)
			if target:
				var dmg: float = d.damage
				match target.get("kind"):
					"tree":
						dmg *= 1.0 + 0.25 * skill("lumberjack")
					"rock":
						dmg *= 1.0 + 0.25 * skill("stonebreaker")
					"animal":
						dmg *= 1.0 + 0.15 * skill("keen_edge")
				target.hit(dmg, id, self)
		"ranged":
			if count("arrow") <= 0:
				if just_pressed:
					_game.message("No arrows! Craft some from wood and stone.", Color(1, 0.7, 0.5))
				return
			remove_item("arrow", 1)
			_cooldown = d.cooldown
			_swing = 1.0
			_swing_dur = d.cooldown
			Audio.play("bow", -2, 0.08)
			_game.spawn_arrow(global_position + aim * 12, aim, d.damage * (1.0 + 0.2 * skill("marksman")), self)
		"place":
			if just_pressed:
				if _game.place_campfire(_game.placement_point()):
					remove_item(id, 1)
					_cooldown = 0.4
					placing = false


# ---------------------------------------------------------------- drawing
func _draw() -> void:
	var face := 1.0 if aim.x >= 0 else -1.0
	var moving := velocity.length() > 15
	var bob := absf(sin(_walk)) * 1.5 if moving else 0.0
	var body_y := -14.0 - bob
	var tint := Color(1, 0.5, 0.5) if _hurt > 0 else Color.WHITE
	if dead:
		draw_set_transform(Vector2(0, -6), PI * 0.5 * face, Vector2.ONE)
		tint = Color(0.7, 0.7, 0.75)
	# shadow
	if not dead:
		draw_set_transform(Vector2(2, 0), 0, Vector2(1, 0.4))
		draw_circle(Vector2.ZERO, 13, Color(0.1, 0.15, 0.25, 0.3))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	var behind := aim.y < -0.3
	if behind and not dead:
		_draw_item(face)

	# legs
	var leg := Color(0.25, 0.22, 0.2) * tint
	var sw := sin(_walk) * 4.0 if moving else 0.0
	draw_line(Vector2(-4, -8 - bob), Vector2(-4 + sw, 0), leg, 5)
	draw_line(Vector2(4, -8 - bob), Vector2(4 - sw, 0), leg, 5)
	draw_circle(Vector2(-4 + sw, 0), 3, Color(0.35, 0.25, 0.18) * tint)
	draw_circle(Vector2(4 - sw, 0), 3, Color(0.35, 0.25, 0.18) * tint)
	# body / tunic
	var cloak := count("fur_cloak") > 0
	var tunic := Color(0.58, 0.2, 0.17) * tint
	if cloak:
		draw_colored_polygon(PackedVector2Array([Vector2(-10, body_y - 7), Vector2(10, body_y - 7), Vector2(13, body_y + 9), Vector2(-13, body_y + 9)]), Color(0.48, 0.34, 0.22) * tint)
	draw_circle(Vector2(0, body_y), 10, tunic)
	draw_rect(Rect2(-9, body_y + 2, 18, 3), Color(0.3, 0.2, 0.12) * tint)
	draw_circle(Vector2(0, body_y + 3.5), 1.8, Color(0.85, 0.7, 0.3) * tint)
	if cloak:
		for i in 5:
			draw_circle(Vector2(-8 + i * 4, body_y - 7), 3.2, Color(0.93, 0.91, 0.87) * tint)
	# head
	var head := Vector2(0, body_y - 13)
	draw_circle(head, 7.5, Color(0.95, 0.8, 0.67) * tint)
	# beard
	var beard := [Vector2(-6, 1), Vector2(6, 1), Vector2(3, 9), Vector2(-2, 8)] if face > 0 else [Vector2(-6, 1), Vector2(6, 1), Vector2(2, 8), Vector2(-3, 9)]
	var bp := PackedVector2Array()
	for v in beard:
		bp.append(head + v)
	draw_colored_polygon(bp, Color(0.9, 0.72, 0.38) * tint)
	# eyes look toward aim
	var look := Vector2(aim.x * 2.5, minf(aim.y * 1.5, 1.0))
	if aim.y > -0.6:
		draw_circle(head + Vector2(-2.6, -1) + look, 1.2, Color(0.15, 0.2, 0.3))
		draw_circle(head + Vector2(2.6, -1) + look, 1.2, Color(0.15, 0.2, 0.3))
	# fur hat
	draw_colored_polygon(PackedVector2Array([head + Vector2(-8, -2), head + Vector2(-6, -9), head + Vector2(0, -11), head + Vector2(6, -9), head + Vector2(8, -2)]), Color(0.42, 0.3, 0.2) * tint)
	draw_rect(Rect2(head.x - 8.5, head.y - 4, 17, 4), Color(0.88, 0.86, 0.82) * tint)

	if not behind and not dead:
		_draw_item(face)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_item(face: float) -> void:
	var id := current_item()
	if id == "" or count(id) <= 0:
		return
	var shoulder := Vector2(0, -16)
	var ang := aim.angle()
	var kind: String = Items.DATA[id].kind
	if kind == "ranged":
		var pull := _swing * 6.0
		var hand := shoulder + aim * 13
		draw_line(shoulder, hand, Color(0.58, 0.2, 0.17), 4)
		draw_set_transform(hand, ang, Vector2.ONE)
		var pts := PackedVector2Array()
		for i in 11:
			var a := lerpf(-1.1, 1.1, i / 10.0)
			pts.append(Vector2(cos(a) * 12 - 8, sin(a) * 14))
		draw_polyline(pts, Color(0.55, 0.36, 0.2), 3, true)
		draw_line(pts[0], Vector2(-8 - pull - 4, 0), Color(0.9, 0.9, 0.85), 1)
		draw_line(pts[10], Vector2(-8 - pull - 4, 0), Color(0.9, 0.9, 0.85), 1)
		if count("arrow") > 0 and _cooldown < 0.25:
			draw_line(Vector2(-12, 0), Vector2(10, 0), Color(0.7, 0.55, 0.35), 1.5)
			draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(9, -2.5), Vector2(9, 2.5)]), Color(0.45, 0.48, 0.53))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
	if kind == "place" or kind == "food":
		var hand := shoulder + aim * 12
		draw_line(shoulder, hand, Color(0.58, 0.2, 0.17), 4)
		Items.draw_icon(self, id, hand, 8.0)
		return
	# Melee/torch swing: arc from behind to in front of the aim direction.
	var swing_off := 0.0
	if _swing > 0:
		var t := 1.0 - _swing
		swing_off = lerpf(-1.4, 1.1, ease(t, 0.4)) * face
	else:
		swing_off = -0.35 * face
	var dir := Vector2.from_angle(ang + swing_off)
	var hand := shoulder + dir * 12
	draw_line(shoulder, hand, Color(0.58, 0.2, 0.17), 4)
	draw_circle(hand, 3, Color(0.95, 0.8, 0.67))
	# icons are drawn diagonally (handle bottom-left -> head top-right), rotate so head points along dir
	var isz := 13.0 if id != "spear" else 18.0
	draw_set_transform(hand + dir * isz * 0.55, dir.angle() + PI * 0.25, Vector2.ONE)
	Items.draw_icon(self, id, Vector2.ZERO, isz)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
