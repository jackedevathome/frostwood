class_name Campfire
extends Node2D
## Placeable campfire: burns wood for fuel, gives heat and light, cooks meat, repels wolves.

const HEAT_RADIUS := 150.0
const MAX_FUEL := 300.0

var kind := "campfire"
var game: Node
var fuel := 120.0
var burning := true
var _t := 0.0
var _light: PointLight2D
var _sound: AudioStreamPlayer2D
var _embers: CPUParticles2D


func _ready() -> void:
	add_to_group("campfires")
	_light = PointLight2D.new()
	_light.texture = Game.light_texture()
	_light.color = Color(1.0, 0.62, 0.3)
	_light.energy = 1.2
	_light.texture_scale = 2.4
	_light.position = Vector2(0, -10)
	add_child(_light)
	_sound = AudioStreamPlayer2D.new()
	_sound.stream = Audio.streams["amb_fire"]
	_sound.bus = "Ambience"
	_sound.max_distance = 520
	_sound.volume_db = -2
	_sound.autoplay = true
	add_child(_sound)
	_embers = CPUParticles2D.new()
	_embers.amount = 18
	_embers.lifetime = 1.4
	_embers.position = Vector2(0, -14)
	_embers.direction = Vector2(0, -1)
	_embers.spread = 25
	_embers.gravity = Vector2(0, -25)
	_embers.initial_velocity_min = 20
	_embers.initial_velocity_max = 50
	_embers.scale_amount_min = 1.5
	_embers.scale_amount_max = 2.5
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_embers.emission_sphere_radius = 6
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 0.8, 0.3, 1))
	grad.set_color(1, Color(1, 0.3, 0.1, 0))
	_embers.color_ramp = grad
	add_child(_embers)
	_sound.play()


func _process(delta: float) -> void:
	_t += delta
	if burning:
		var keeper: int = game.player.skill("firekeeper") if game else 0
		fuel -= delta / (1.0 + 0.3 * keeper)
		if fuel <= 0:
			fuel = 0
			_set_burning(false)
		var flick := 0.85 + 0.1 * sin(_t * 13.0) + 0.08 * sin(_t * 31.0 + 1.0) + randf() * 0.05
		var strength := clampf(fuel / 40.0, 0.35, 1.0)
		var dark: float = game.darkness() if game else 1.0
		_light.energy = 1.25 * flick * strength * (0.3 + 0.7 * dark)
		_light.texture_scale = (2.1 + 0.25 * sin(_t * 2.3)) * (0.6 + 0.4 * strength)
	queue_redraw()


func _set_burning(b: bool) -> void:
	burning = b
	_light.visible = b
	_embers.emitting = b
	if b:
		_sound.play()
		Audio.play_at("ignite", global_position, -2)
	else:
		_sound.stop()


func add_fuel(amount: float) -> void:
	fuel = minf(fuel + amount, MAX_FUEL)
	if not burning:
		_set_burning(true)


func heat_at(p: Vector2) -> float:
	if not burning:
		return 0.0
	return clampf(1.0 - global_position.distance_to(p) / HEAT_RADIUS, 0.0, 1.0)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 24, Color(0.25, 0.2, 0.18, 0.6))
	if burning:
		draw_circle(Vector2.ZERO, 14, Color(1.0, 0.45, 0.1, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# ring of stones
	for i in 9:
		var a := TAU * i / 9.0
		var p := Vector2(cos(a) * 20, sin(a) * 10)
		draw_circle(p, 5, Color(0.45, 0.47, 0.5))
		draw_circle(p + Vector2(-1, -2), 3, Color(0.62, 0.64, 0.68))
	# logs
	draw_line(Vector2(-14, 2), Vector2(14, -6), Color(0.36, 0.22, 0.12), 6)
	draw_line(Vector2(-14, -6), Vector2(14, 2), Color(0.45, 0.28, 0.15), 6)
	if not burning:
		draw_circle(Vector2(0, -2), 6, Color(0.2, 0.2, 0.22))
		return
	var s := clampf(fuel / 40.0, 0.4, 1.0)
	var flames := [[Color(1.0, 0.35, 0.08, 0.9), 15.0, 34.0], [Color(1.0, 0.62, 0.15, 0.95), 10.0, 25.0], [Color(1.0, 0.92, 0.55, 1.0), 5.0, 14.0]]
	for f in flames:
		var w: float = f[1] * s
		var h: float = f[2] * s
		var pts := PackedVector2Array()
		pts.append(Vector2(-w, -2))
		for k in 5:
			var x := lerpf(-w * 0.8, w * 0.8, k / 4.0)
			var hh := h * (0.55 + 0.45 * sin(_t * (9.0 + k * 2.3) + k * 1.7)) * (1.0 - absf(x) / (w * 1.4))
			pts.append(Vector2(x + sin(_t * 7.0 + k) * w * 0.12, -2 - hh))
		pts.append(Vector2(w, -2))
		draw_colored_polygon(pts, f[0])
