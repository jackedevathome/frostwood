class_name Game
extends Node2D
## Main gameplay scene: builds the forest, runs the day/night cycle, spawns wildlife and ties systems together.

const WORLD_HALF := 2400.0
const DAY_LENGTH := 360.0  # seconds for a full day/night cycle

static var _light_tex: Texture2D

var player: Player
var entities: Node2D
var fx: Node2D
var hud: HUD
var camera: Camera2D
var lakes: Array = []
var time_of_day := 0.3
var day := 1

var _canvas_mod: CanvasModulate
var _pause: PauseMenu
var _death: DeathScreen
var _snow: CPUParticles2D
var _ghost: Node2D
var _ghost_ok := false
var _night := false
var _shake := 0.0
var _spawn_t := 2.0
var _howl_t := 25.0
var _fade_t := 0.0
var _faded: Array = []
var _rng := RandomNumberGenerator.new()
var world_map: WorldMap
var _map_screen: MapScreen
var _reveal_t := 0.0
var _flags: Array = []  # world flag nodes, parallel to world_map.waypoints
var world_seed := 0
var play_time := 0.0
var _by_uid := {}  # generation index -> tree / rock / bush node
var _next_uid := 0


static func light_texture() -> Texture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(0.5, 0.0)
		gt.width = 256
		gt.height = 256
		_light_tex = gt
	return _light_tex


func _ready() -> void:
	var save: Dictionary = SaveManager.pending
	SaveManager.pending = {}
	if SaveManager.current_slot < 0:
		var free := SaveManager.first_empty_slot()
		SaveManager.current_slot = free if free >= 0 else 0
	if save.has("seed"):
		world_seed = int(save.seed)
	else:
		_rng.randomize()
		world_seed = _rng.randi()
	_rng.seed = world_seed
	var seed_v := _rng.randi()
	_canvas_mod = CanvasModulate.new()
	add_child(_canvas_mod)

	var ground := Ground.new()
	add_child(ground)
	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	fx = Node2D.new()
	fx.z_index = 10
	add_child(fx)

	_gen_lakes()
	ground.setup(WORLD_HALF, lakes, seed_v)

	player = Player.new()
	player.setup(self)
	entities.add_child(player)
	player.died.connect(_on_player_died)
	camera = Camera2D.new()
	camera.zoom = Vector2(1.35, 1.35)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = int(-WORLD_HALF - 300)
	camera.limit_right = int(WORLD_HALF + 300)
	camera.limit_top = int(-WORLD_HALF - 300)
	camera.limit_bottom = int(WORLD_HALF + 300)
	player.add_child(camera)
	camera.make_current()

	_gen_world()
	world_map = WorldMap.new(WORLD_HALF)
	world_map.build(lakes, entities.get_children())
	world_map.reveal(player.global_position)
	camera.reset_smoothing()
	_make_bounds()
	_make_snow()
	_make_ghost()

	hud = HUD.new()
	add_child(hud)
	hud.setup(self)
	_pause = PauseMenu.new()
	_pause.game = self
	add_child(_pause)
	_pause.resumed.connect(restore_cursor)
	_death = DeathScreen.new()
	add_child(_death)
	_map_screen = MapScreen.new()
	_map_screen.setup(self)
	add_child(_map_screen)
	player.leveled_up.connect(_on_level_up)

	if not save.is_empty():
		_apply_save(save)
	_night = is_night()
	_apply_lighting()
	Audio.play_music("music_day", 3.0)
	Audio.stop_all_ambience(0.5)
	Audio.set_ambience("amb_wind", -13, 3.0)
	Audio.set_ambience("amb_forest", -9, 3.0)
	_set_crosshair()
	if not save.is_empty():
		hud.show_banner("Day %d" % day)
		message("Welcome back. Your game was loaded from slot %d." % (SaveManager.current_slot + 1), UITheme.ACCENT)
		return
	hud.show_banner("Day 1")
	message("Chop trees with your axe (Left Mouse) to gather wood.", UITheme.ACCENT)
	message("Press %s for your inventory and crafting. Build a campfire before night falls!" % Settings.key_name("inventory"), UITheme.ACCENT)


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)


func _notification(what: int) -> void:
	# save when the window is closed mid-game
	if what == NOTIFICATION_WM_CLOSE_REQUEST and player and not player.dead:
		save_game(false)


# ---------------------------------------------------------------- world generation
func _gen_lakes() -> void:
	var tries := 0
	while lakes.size() < 4 and tries < 100:
		tries += 1
		var c := Vector2(_rng.randf_range(-1900, 1900), _rng.randf_range(-1900, 1900))
		if c.length() < 600:
			continue
		var ok := true
		for L in lakes:
			if L[0].distance_to(c) < 700:
				ok = false
		if ok:
			lakes.append([c, Vector2(_rng.randf_range(170, 320), _rng.randf_range(110, 200))])


func _in_lake(p: Vector2, margin := 1.0) -> bool:
	for L in lakes:
		var d: Vector2 = (p - L[0]) / (L[1] * margin)
		if d.length_squared() < 1.0:
			return true
	return false


func _gen_world() -> void:
	var dens := FastNoiseLite.new()
	dens.seed = _rng.randi()
	dens.frequency = 0.0016
	var spec := FastNoiseLite.new()
	spec.seed = _rng.randi()
	spec.frequency = 0.0009
	var grid := {}
	var cell := 48.0

	var occupied := func(p: Vector2, min_d: float) -> bool:
		var k := Vector2i(floori(p.x / cell), floori(p.y / cell))
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				for q in grid.get(k + Vector2i(dx, dy), []):
					if q.distance_to(p) < min_d:
						return true
		return false
	var mark := func(p: Vector2) -> void:
		var k := Vector2i(floori(p.x / cell), floori(p.y / cell))
		if not grid.has(k):
			grid[k] = []
		grid[k].append(p)

	# trees inside the world
	var count := 0
	for i in 14000:
		var p := Vector2(_rng.randf_range(-WORLD_HALF + 30, WORLD_HALF - 30), _rng.randf_range(-WORLD_HALF + 30, WORLD_HALF - 30))
		if p.length() < 190 or _in_lake(p, 1.12):
			continue
		var d := (dens.get_noise_2dv(p) + 1.0) * 0.5
		if _rng.randf() > pow(d, 1.6) * 1.5:
			continue
		if occupied.call(p, 44.0):
			continue
		mark.call(p)
		var sp := "spruce" if spec.get_noise_2dv(p) + _rng.randf_range(-0.25, 0.25) > -0.1 else "pine"
		_add_tree(p, sp, _rng.randf_range(0.8, 1.25))
		count += 1
		if count > 950:
			break
	# dense forest wall around the border
	for i in 700:
		var side := _rng.randi() % 4
		var along := _rng.randf_range(-WORLD_HALF - 400, WORLD_HALF + 400)
		var out := _rng.randf_range(WORLD_HALF + 20, WORLD_HALF + 420)
		var p: Vector2 = [Vector2(along, -out), Vector2(along, out), Vector2(-out, along), Vector2(out, along)][side]
		if occupied.call(p, 36.0):
			continue
		mark.call(p)
		_add_tree(p, "spruce" if _rng.randf() < 0.7 else "pine", _rng.randf_range(0.95, 1.35))
	# boulders
	var rocks := 0
	for i in 600:
		var p := Vector2(_rng.randf_range(-WORLD_HALF + 60, WORLD_HALF - 60), _rng.randf_range(-WORLD_HALF + 60, WORLD_HALF - 60))
		if p.length() < 150 or _in_lake(p, 1.2) or occupied.call(p, 56.0):
			continue
		mark.call(p)
		var b := Boulder.new()
		b.position = p
		b.setup(self, _rng.randf_range(0.8, 1.4))
		_register(b)
		entities.add_child(b)
		rocks += 1
		if rocks >= 120:
			break
	# a few guaranteed rocks and bushes near spawn
	for p in [Vector2(-130, 90), Vector2(160, -60), Vector2(60, 170)]:
		if not occupied.call(p, 40.0):
			mark.call(p)
			var b := Boulder.new()
			b.position = p
			b.setup(self, 1.0)
			_register(b)
			entities.add_child(b)
	for p in [Vector2(110, 110), Vector2(-150, -40)]:
		mark.call(p)
		_add_bush(p)
	# lingonberry bushes
	var bushes := 0
	for i in 2000:
		var p := Vector2(_rng.randf_range(-WORLD_HALF + 60, WORLD_HALF - 60), _rng.randf_range(-WORLD_HALF + 60, WORLD_HALF - 60))
		if _in_lake(p, 1.1) or occupied.call(p, 34.0):
			continue
		mark.call(p)
		_add_bush(p)
		bushes += 1
		if bushes >= 150:
			break
	# starting wildlife
	for i in 8:
		_spawn_animal("deer", 400, 2200)
	for i in 10:
		_spawn_animal("hare", 300, 2200)
	_spawn_animal("wolf", 1300, 2200)


func _register(n: Node) -> void:
	n.set_meta("uid", _next_uid)
	_by_uid[_next_uid] = n
	_next_uid += 1


func _count_kind(k: String) -> int:
	var n := 0
	for c in entities.get_children():
		if c.get("kind") == k:
			n += 1
	return n


func _add_tree(p: Vector2, sp: String, sc: float) -> void:
	var t := ForestTree.new()
	t.position = p
	t.setup(self, sp, sc)
	_register(t)
	entities.add_child(t)


func _add_bush(p: Vector2) -> void:
	var b := BerryBush.new()
	b.position = p
	b.setup(self)
	_register(b)
	entities.add_child(b)


func _make_bounds() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var t := 400.0
	for r in [Rect2(-WORLD_HALF - t, -WORLD_HALF - t, WORLD_HALF * 2 + t * 2, t), Rect2(-WORLD_HALF - t, WORLD_HALF, WORLD_HALF * 2 + t * 2, t),
			Rect2(-WORLD_HALF - t, -WORLD_HALF, t, WORLD_HALF * 2), Rect2(WORLD_HALF, -WORLD_HALF, t, WORLD_HALF * 2)]:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.position = r.get_center()
		body.add_child(cs)


func _make_snow() -> void:
	_snow = CPUParticles2D.new()
	_snow.amount = 420
	_snow.lifetime = 7.0
	_snow.preprocess = 7.0
	_snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_snow.emission_rect_extents = Vector2(800, 30)
	_snow.direction = Vector2(0.25, 1)
	_snow.spread = 15
	_snow.gravity = Vector2(10, 18)
	_snow.initial_velocity_min = 35
	_snow.initial_velocity_max = 70
	_snow.scale_amount_min = 1.5
	_snow.scale_amount_max = 3.5
	_snow.color = Color(1, 1, 1, 0.85)
	_snow.local_coords = false
	_snow.z_index = 20
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.1, 1))
	curve.add_point(Vector2(0.85, 1))
	curve.add_point(Vector2(1, 0))
	_snow.scale_amount_curve = curve
	add_child(_snow)


func _make_ghost() -> void:
	_ghost = Node2D.new()
	_ghost.z_index = 5
	_ghost.draw.connect(func():
		var col := Color(0.6, 1.0, 0.6, 0.5) if _ghost_ok else Color(1.0, 0.4, 0.4, 0.5)
		_ghost.draw_arc(Vector2.ZERO, 22, 0, TAU, 24, col, 2.0)
		Items.draw_icon(_ghost, "campfire", Vector2(0, -8), 16, 0.6))
	add_child(_ghost)


# ---------------------------------------------------------------- main loop
func _process(delta: float) -> void:
	play_time += delta
	var prev := time_of_day
	time_of_day = fmod(time_of_day + delta / DAY_LENGTH, 1.0)
	if prev < 0.25 and time_of_day >= 0.25:
		day += 1
		hud.show_banner("Day %d" % day, Color(1.0, 0.9, 0.7))
		Audio.play("dawn", -4, 0.0)
		message("Dawn breaks. You survived the night!", UITheme.WARM)
		if day > 1:
			player.add_xp(Skills.XP.dawn)
		save_game(false)
		message("Game autosaved.", UITheme.MUTED)
	var n := is_night()
	if n != _night:
		_night = n
		_on_night_changed()
	_apply_lighting()

	_spawn_t -= delta
	if _spawn_t <= 0:
		_spawn_t = 3.0
		_manage_population()
	if _night:
		_howl_t -= delta
		if _howl_t <= 0:
			_howl_t = randf_range(18, 40)
			var wolves := get_tree().get_nodes_in_group("wolf")
			var at := player.global_position + Vector2.from_angle(randf() * TAU) * 700
			if wolves.size() > 0:
				at = wolves[randi() % wolves.size()].global_position
			Audio.play_at("howl", at, 2, 0.1, 2200)

	_fade_t -= delta
	if _fade_t <= 0:
		_fade_t = 0.1
		_update_tree_fade()

	if _shake > 0:
		_shake = maxf(0.0, _shake - delta * 18.0)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	else:
		camera.offset = Vector2.ZERO

	_snow.global_position = camera.get_screen_center_position() + Vector2(-120, -420)

	_reveal_t -= delta
	if _reveal_t <= 0:
		_reveal_t = 0.4
		world_map.reveal(player.global_position)
	camera.reset_smoothing()

	var show_ghost := player.holding("campfire") and not player.dead and not hud.any_window_open()
	_ghost.visible = show_ghost
	if show_ghost:
		var p := placement_point()
		_ghost.global_position = p
		_ghost_ok = _can_place(p)
		_ghost.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if player.dead:
		return
	if event.is_action_pressed("pause"):
		if player.placing:
			player.cancel_placing()
		elif hud.any_window_open():
			hud.close_windows()
		else:
			_pause.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		hud.toggle_window("inventory")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("craft"):
		hud.toggle_window("craft")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("skills"):
		hud.toggle_window("skills")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map"):
		hud.close_windows()
		player.cancel_placing()
		_map_screen.open()
		get_viewport().set_input_as_handled()


func _on_night_changed() -> void:
	if _night:
		hud.show_banner("Night falls. Wolves are hunting...", Color(0.7, 0.8, 1.0))
		Audio.play_music("music_night", 4.0)
		Audio.set_ambience("amb_wind", -6, 5.0)
		Audio.set_ambience("amb_forest", -80, 5.0)
		Audio.play_at("howl", player.global_position + Vector2(800, -300), 3, 0.05, 2400)
		if get_tree().get_nodes_in_group("campfires").is_empty():
			message("It's getting cold. Build a campfire!", Color(0.7, 0.85, 1.0))
	else:
		Audio.play_music("music_day", 4.0)
		Audio.set_ambience("amb_wind", -13, 5.0)
		Audio.set_ambience("amb_forest", -9, 5.0)


func is_night() -> bool:
	return time_of_day < 0.22 or time_of_day > 0.8


func _sun() -> float:
	return -cos(time_of_day * TAU)


## 0 at full day, 1 at deepest night.
func darkness() -> float:
	return 1.0 - smoothstep(-0.3, 0.3, _sun())


func _apply_lighting() -> void:
	var light := 1.0 - darkness()
	var night_col := Color(0.08, 0.1, 0.21).lerp(Color(0.34, 0.38, 0.55), Settings.night_brightness)
	var day_col := Color(0.98, 0.99, 1.0)
	var col := night_col.lerp(day_col, light)
	var dusk := clampf(1.0 - absf(_sun()) / 0.32, 0.0, 1.0)
	col = col.lerp(Color(1.0, 0.68, 0.5) * maxf(light, 0.45), dusk * 0.35)
	col.a = 1.0
	_canvas_mod.color = col


func _manage_population() -> void:
	var wolves := get_tree().get_nodes_in_group("wolf")
	var target := mini(2 + day / 2, 7) if _night else 1
	if Settings.difficulty == 0:
		target = maxi(1, target - 1)
	elif Settings.difficulty == 2:
		target += 1
	if wolves.size() < target:
		_spawn_animal("wolf", 800, 1100)
	elif not _night and wolves.size() > target:
		for w in wolves:
			if w.global_position.distance_to(player.global_position) > 900:
				w.queue_free()
				break
	var prey := get_tree().get_nodes_in_group("deer").size() + get_tree().get_nodes_in_group("hare").size()
	if prey < 16:
		_spawn_animal("deer" if randf() < 0.45 else "hare", 900, 1500)


func _spawn_animal(sp: String, min_d: float, max_d: float) -> void:
	for attempt in 12:
		var p := player.global_position + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(min_d, max_d)
		if absf(p.x) > WORLD_HALF - 100 or absf(p.y) > WORLD_HALF - 100 or _in_lake(p, 1.1):
			continue
		var params := PhysicsPointQueryParameters2D.new()
		params.position = p
		params.collision_mask = 1
		if not get_world_2d().direct_space_state.intersect_point(params, 1).is_empty():
			continue
		var a := Animal.new()
		a.position = p
		a.setup(self, sp)
		entities.add_child(a)
		return


func _update_tree_fade() -> void:
	for t in _faded:
		if is_instance_valid(t):
			t.set_faded(false)
	_faded.clear()
	var pp := player.global_position
	for t in get_tree().get_nodes_in_group("trees"):
		var tp: Vector2 = t.global_position
		if absf(tp.x - pp.x) > 60 or tp.y < pp.y or tp.y - pp.y > 200:
			continue
		if t.felled:
			continue
		if pp.y > tp.y - t.height and absf(tp.x - pp.x) < t.canopy_w * 0.55 and pp.y < tp.y - 4:
			t.set_faded(true)
			_faded.append(t)


func _set_crosshair() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c := Vector2(15.5, 15.5)
	for y in 32:
		for x in 32:
			var d := Vector2(x, y).distance_to(c)
			var a := 0.0
			if absf(d - 9.0) < 1.2:
				a = 1.0
			elif d < 1.8:
				a = 1.0
			elif (absf(x - c.x) < 1.0 or absf(y - c.y) < 1.0) and d > 4.0 and d < 7.5:
				a = 0.9
			var outline := absf(d - 9.0) < 2.4 or d < 3.0
			if a > 0:
				img.set_pixel(x, y, Color(0.95, 0.98, 1.0, a))
			elif outline:
				img.set_pixel(x, y, Color(0.05, 0.08, 0.12, 0.6))
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), Input.CURSOR_ARROW, Vector2(16, 16))


# ---------------------------------------------------------------- queries used by entities
func find_target(origin: Vector2, dir: Vector2, reach: float) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	for n in get_tree().get_nodes_in_group("hittable"):
		var to: Vector2 = n.global_position - origin
		if n.get("kind") == "tree":
			to = n.global_position + Vector2(0, -8) - origin
		var d := to.length()
		if d > reach + 14.0:
			continue
		var dot := dir.dot(to / maxf(d, 0.001))
		if d > 22.0 and dot < 0.4:
			continue
		var score := d - dot * 25.0
		if n.get("kind") == "animal":
			score -= 30.0
		if score < best_score:
			best_score = score
			best = n
	return best


func heat_at(p: Vector2) -> float:
	var h := 0.0
	for f in get_tree().get_nodes_in_group("campfires"):
		h = maxf(h, f.heat_at(p))
	return h


func fire_near(p: Vector2, extra: float) -> Node2D:
	for f in get_tree().get_nodes_in_group("campfires"):
		if f.burning and f.global_position.distance_to(p) < Campfire.HEAT_RADIUS + extra:
			return f
	return null


func on_ice(p: Vector2) -> bool:
	return _in_lake(p, 0.95)


func _nearest(group: String, p: Vector2, max_d: float) -> Node2D:
	var best: Node2D = null
	var bd := max_d
	for n in get_tree().get_nodes_in_group(group):
		var d: float = n.global_position.distance_to(p)
		if d < bd:
			bd = d
			best = n
	return best


func interact() -> void:
	var fire := _nearest("campfires", player.global_position, 75)
	if fire:
		if player.count("raw_meat") > 0 and fire.burning:
			var n := player.count("raw_meat")
			player.remove_item("raw_meat", n)
			player.add_item("cooked_meat", n)
			player.add_xp(Skills.XP.cook * n)
			Audio.play("ignite", -6)
			Audio.play("craft", -10)
			message("Cooked %d meat over the fire." % n, UITheme.WARM)
		elif player.count("wood") > 0 and fire.fuel < Campfire.MAX_FUEL - 20:
			player.remove_item("wood", 1)
			fire.add_fuel(45)
			Audio.play_at("place", fire.global_position, -4)
			message("Added wood to the fire.")
		elif player.count("wood") == 0:
			message("You need wood to fuel the fire.", Color(1, 0.7, 0.5))
		return
	var bush := _nearest("bushes", player.global_position, 52)
	if bush:
		bush.harvest()


func interaction_hint() -> String:
	if player.dead:
		return ""
	var key := Settings.key_name("interact")
	var fire := _nearest("campfires", player.global_position, 75)
	if fire:
		if player.count("raw_meat") > 0 and fire.burning:
			return "[%s] Cook raw meat (%d)" % [key, player.count("raw_meat")]
		if not fire.burning:
			return "[%s] Relight the fire with wood" % key
		return "[%s] Add wood   •   fuel %ds" % [key, int(fire.fuel)]
	var bush := _nearest("bushes", player.global_position, 52)
	if bush and bush.ripe:
		return "[%s] Pick lingonberries" % key
	return ""


func can_afford(cost: Dictionary) -> bool:
	for k in cost:
		if player.count(k) < cost[k]:
			return false
	return true


func craft(rec: Dictionary) -> void:
	if not can_afford(rec.cost) or (rec.id in Items.UNIQUE and player.count(rec.id) > 0):
		return
	for k in rec.cost:
		player.remove_item(k, rec.cost[k])
	player.add_item(rec.id, rec.amount)
	player.add_xp(Skills.XP.craft)
	Audio.play("craft", -2)
	message("Crafted %s%s" % [Items.item_name(rec.id), (" x%d" % rec.amount) if rec.amount > 1 else ""], UITheme.WARM)
	if rec.id == "campfire":
		# go straight to placing it
		hud.close_windows()
		player.start_placing()
	elif Items.is_equippable(rec.id) and not rec.id in player.hotbar:
		if player.auto_equip(rec.id):
			message("%s added to your hotbar." % Items.item_name(rec.id))
		else:
			message("Drag the %s onto a hotbar slot to use it." % Items.item_name(rec.id), UITheme.MUTED)


## Where a campfire would be placed: the mouse position, clamped to the player's reach.
func placement_point() -> Vector2:
	var p := get_global_mouse_position()
	if p.distance_to(player.global_position) > 140:
		p = player.global_position + (p - player.global_position).limit_length(140)
	return p


func _can_place(p: Vector2) -> bool:
	if _in_lake(p, 1.05) or absf(p.x) > WORLD_HALF - 40 or absf(p.y) > WORLD_HALF - 40:
		return false
	for n in get_tree().get_nodes_in_group("hittable"):
		var k = n.get("kind")
		if (k == "tree" or k == "rock") and n.global_position.distance_to(p) < 34:
			return false
	for f in get_tree().get_nodes_in_group("campfires"):
		if f.global_position.distance_to(p) < 60:
			return false
	return true


func place_campfire(p: Vector2) -> bool:
	if not _can_place(p):
		message("You can't build a fire there.", Color(1, 0.7, 0.5))
		return false
	var f := Campfire.new()
	f.game = self
	f.position = p
	entities.add_child(f)
	Audio.play_at("place", p)
	player.add_xp(Skills.XP.build)
	message("Campfire built. Press %s near it to add wood or cook." % Settings.key_name("interact"), UITheme.WARM)
	return true


func spawn_drop(id: String, n: int, target: Vector2, origin: Vector2) -> void:
	var d := ItemDrop.new()
	entities.add_child(d)
	d.setup(self, id, n, target, origin)


func spawn_arrow(from: Vector2, dir: Vector2, dmg: float, shooter: CollisionObject2D) -> void:
	var a := ArrowProjectile.new()
	entities.add_child(a)
	a.launch(from, dir, dmg, shooter)


# ---------------------------------------------------------------- feedback
func message(text: String, col := Color(0.92, 0.95, 0.98)) -> void:
	if hud:
		hud.message(text, col)


func shake(amount: float) -> void:
	if Settings.screen_shake:
		_shake = maxf(_shake, amount)


func flash_damage() -> void:
	hud.flash_damage()


func _burst(pos: Vector2, col: Color, n: int, speed: float, grav: float, life: float, size_min: float, size_max: float) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = n
	p.lifetime = life
	p.direction = Vector2(0, -1)
	p.spread = 180
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, grav)
	p.damping_min = speed * 0.8
	p.damping_max = speed * 1.2
	p.scale_amount_min = size_min
	p.scale_amount_max = size_max
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col, 0))
	p.color_ramp = g
	p.global_position = pos
	fx.add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.2, false).timeout.connect(p.queue_free)


func snow_puff(pos: Vector2, n: int) -> void:
	_burst(pos, Color(0.97, 0.98, 1.0, 0.95), n, 90, 60, 0.9, 2, 4)


func debris(pos: Vector2, col: Color, n: int) -> void:
	_burst(pos, col, n, 140, 300, 0.6, 2, 3.5)


func blood(pos: Vector2, n := 8) -> void:
	_burst(pos, Color(0.7, 0.05, 0.08, 0.9), n, 110, 250, 0.6, 2, 3.5)


func damage_number(pos: Vector2, dmg: float) -> void:
	if not Settings.damage_numbers:
		return
	var l := Label.new()
	l.text = str(roundi(dmg))
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	l.add_theme_constant_override("outline_size", 5)
	l.position = pos + Vector2(randf_range(-10, 4), 0)
	fx.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 30, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


func _on_player_died(cause: String) -> void:
	var record := Settings.record_days(day)
	Audio.stop_music(1.5)
	Audio.set_ambience("amb_forest", -80, 2.0)
	Audio.play("game_over", -2, 0.0)
	hud.close_windows()
	_death.show_death(cause, day, record, player.level)


# ---------------------------------------------------------------- xp, skills, map
func _on_level_up(lvl: int) -> void:
	hud.show_banner("Level %d!" % lvl, Color(0.85, 0.75, 1.0))
	Audio.play("level_up", -2, 0.0)
	message("Level up! You have %d skill point%s. Press %s to spend." % [player.skill_points, "" if player.skill_points == 1 else "s", Settings.key_name("skills")], Color(0.85, 0.75, 1.0))


## Extra drops from the Bountiful skill: 25% chance per rank.
func bonus_drops() -> int:
	var n := 0
	for i in player.skill("bountiful"):
		if randf() < 0.25:
			n += 1
	return n


func xp_text(pos: Vector2, amount: int) -> void:
	var l := Label.new()
	l.text = "+%d XP" % amount
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.82, 0.7, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.12))
	l.add_theme_constant_override("outline_size", 5)
	l.position = pos + Vector2(-20, 0)
	fx.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 26, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


func add_waypoint(p: Vector2) -> bool:
	var wp := world_map.add_waypoint(p)
	if wp.is_empty():
		return false
	var flag := WaypointFlag.new()
	flag.position = p
	flag.color = wp.color
	flag.label = wp.name
	entities.add_child(flag)
	_flags.append(flag)
	Audio.play("waypoint", -4, 0.05)
	return true


func remove_waypoint(i: int) -> void:
	if i < 0 or i >= world_map.waypoints.size():
		return
	world_map.waypoints.remove_at(i)
	var flag: Node = _flags[i]
	_flags.remove_at(i)
	flag.queue_free()
	Audio.play("ui_click", -6)


func restore_cursor() -> void:
	if not player.dead and not hud.any_window_open():
		_set_crosshair()


# ---------------------------------------------------------------- save / load
func save_game(show_message := true) -> bool:
	if player.dead:
		return false
	var felled := []
	var rocks_gone := []
	var bushes := []
	for uid in _by_uid:
		var n = _by_uid[uid]
		if not is_instance_valid(n):
			rocks_gone.append(uid)
		elif n is ForestTree and n.felled:
			felled.append(uid)
		elif n is BerryBush and not n.ripe:
			bushes.append([uid, n.regrow_left()])
	var fires := []
	for f in get_tree().get_nodes_in_group("campfires"):
		fires.append([f.global_position.x, f.global_position.y, f.fuel])
	var drops := []
	for d in get_tree().get_nodes_in_group("drops"):
		if not d.is_queued_for_deletion():
			drops.append([d.item_id, d.amount, d.global_position.x, d.global_position.y])
	var animals := []
	for a in get_tree().get_nodes_in_group("animals"):
		if not a.is_queued_for_deletion():
			animals.append([a.species, a.global_position.x, a.global_position.y, a.hp])
	var wps := []
	for wp in world_map.waypoints:
		wps.append([wp.pos.x, wp.pos.y, wp.name, wp.color.to_html()])
	var data := {
		"seed": world_seed, "day": day, "time_of_day": time_of_day, "play_time": play_time,
		"difficulty": Settings.difficulty,
		"player": player.to_dict(),
		"felled": felled, "rocks_gone": rocks_gone, "bushes": bushes,
		"campfires": fires, "drops": drops, "animals": animals,
		"waypoints": wps, "wp_counter": world_map._wp_counter,
		"fog": Marshalls.raw_to_base64(world_map.fog.save_png_to_buffer()),
	}
	var ok := SaveManager.write(SaveManager.current_slot, data)
	if show_message:
		message("Game saved to slot %d." % (SaveManager.current_slot + 1) if ok else "Saving failed!", UITheme.ACCENT if ok else Color(1, 0.5, 0.5))
	return ok


func _apply_save(d: Dictionary) -> void:
	day = int(d.get("day", 1))
	time_of_day = float(d.get("time_of_day", 0.3))
	play_time = float(d.get("play_time", 0.0))
	player.from_dict(d.get("player", {}))
	for uid in d.get("felled", []):
		var t = _by_uid.get(int(uid))
		if t is ForestTree:
			t.make_stump()
			world_map.clear_at(t.global_position)
	for uid in d.get("rocks_gone", []):
		var r = _by_uid.get(int(uid))
		if r is Boulder:
			world_map.clear_at(r.global_position, false)
			_by_uid[int(uid)] = null
			r.free()
	for b in d.get("bushes", []):
		var bush = _by_uid.get(int(b[0]))
		if bush is BerryBush:
			bush.set_regrow(float(b[1]))
	for f in d.get("campfires", []):
		var c := Campfire.new()
		c.game = self
		c.position = Vector2(f[0], f[1])
		entities.add_child(c)
		c.fuel = float(f[2])
	for dr in d.get("drops", []):
		var p := Vector2(dr[2], dr[3])
		spawn_drop(str(dr[0]), int(dr[1]), p, p)
	# replace the freshly generated wildlife with the saved animals
	for a in get_tree().get_nodes_in_group("animals"):
		a.free()
	for a in d.get("animals", []):
		var an := Animal.new()
		an.position = Vector2(a[1], a[2])
		an.setup(self, str(a[0]))
		an.hp = float(a[3])
		entities.add_child(an)
	for w in d.get("waypoints", []):
		var wp := world_map.add_waypoint(Vector2(w[0], w[1]))
		if wp.is_empty():
			continue
		wp.name = str(w[2])
		wp.color = Color.html(str(w[3]))
		var flag := WaypointFlag.new()
		flag.position = wp.pos
		flag.color = wp.color
		flag.label = wp.name
		entities.add_child(flag)
		_flags.append(flag)
	world_map._wp_counter = int(d.get("wp_counter", world_map.waypoints.size()))
	if d.has("fog"):
		var img := Image.new()
		if img.load_png_from_buffer(Marshalls.base64_to_raw(str(d.fog))) == OK:
			img.convert(Image.FORMAT_RGBA8)
			world_map.fog = img
			world_map.fog_tex.set_image(img)
	world_map.reveal(player.global_position)
	camera.reset_smoothing()
