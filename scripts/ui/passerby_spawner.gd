extends Node2D
## Spawns and animates procedural silhouettes walking past the window
## More foot traffic during busy hours, fewer at night

signal passerby_passed

# Spawn configuration
const BASE_SPAWN_INTERVAL := 8.0  # Base seconds between spawns
const MIN_SPAWN_INTERVAL := 3.0   # Minimum interval during rush hour
const WALK_SPEED_MIN := 30.0
const WALK_SPEED_MAX := 60.0

# Silhouette configuration
const SILHOUETTE_COLOR := Color(0.15, 0.12, 0.1, 0.85)
const SILHOUETTE_HEIGHT_MIN := 40.0
const SILHOUETTE_HEIGHT_MAX := 55.0

# Different silhouette types for variety
enum SilhouetteType { PERSON, PERSON_WITH_BAG, PERSON_WITH_PHONE, PERSON_TALL, PERSON_CHILD }

var window_rect: Rect2
var spawn_timer: Timer
var active_silhouettes: Array[Dictionary] = []


func _ready() -> void:
	_setup_timer()


func set_window_bounds(rect: Rect2) -> void:
	window_rect = rect


func _setup_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_passerby)
	add_child(spawn_timer)
	_schedule_next_spawn()


func _schedule_next_spawn() -> void:
	var interval := _get_spawn_interval()
	spawn_timer.wait_time = interval
	spawn_timer.start()


func _get_spawn_interval() -> float:
	var base := BASE_SPAWN_INTERVAL

	# Adjust based on time of day
	if TimeManager:
		if TimeManager.is_busy_hour():
			base = MIN_SPAWN_INTERVAL
		elif TimeManager.current_period == TimeManager.TimePeriod.NIGHT:
			base = BASE_SPAWN_INTERVAL * 2.5  # Much fewer at night

	# Add some randomness
	return base + randf_range(-1.0, 2.0)


func _spawn_passerby() -> void:
	if window_rect.size == Vector2.ZERO:
		_schedule_next_spawn()
		return

	# Create new silhouette data
	var silhouette := {
		"type": _get_random_type(),
		"height": randf_range(SILHOUETTE_HEIGHT_MIN, SILHOUETTE_HEIGHT_MAX),
		"speed": randf_range(WALK_SPEED_MIN, WALK_SPEED_MAX),
		"direction": 1 if randf() > 0.5 else -1,
		"x": 0.0,
		"walk_cycle": 0.0,
		"has_umbrella": false
	}

	# Start position based on direction
	if silhouette.direction > 0:
		silhouette.x = -30.0
	else:
		silhouette.x = window_rect.size.x + 30.0

	# Check if raining - some people have umbrellas
	if _is_raining():
		silhouette.has_umbrella = randf() > 0.4  # 60% have umbrella in rain

	active_silhouettes.append(silhouette)
	_schedule_next_spawn()


func _get_random_type() -> SilhouetteType:
	var roll := randf()
	if roll < 0.4:
		return SilhouetteType.PERSON
	elif roll < 0.6:
		return SilhouetteType.PERSON_WITH_BAG
	elif roll < 0.75:
		return SilhouetteType.PERSON_WITH_PHONE
	elif roll < 0.9:
		return SilhouetteType.PERSON_TALL
	else:
		return SilhouetteType.PERSON_CHILD


func _is_raining() -> bool:
	var weather := get_parent().get_node_or_null("WeatherEffects")
	if weather and weather.has_method("is_raining"):
		return weather.is_raining()
	return false


func _process(delta: float) -> void:
	if window_rect.size == Vector2.ZERO:
		return

	# Reduce processing when idle
	if GameManager and GameManager.idle_mode:
		return

	# Update all active silhouettes
	var to_remove: Array[int] = []

	for i in range(active_silhouettes.size()):
		var s: Dictionary = active_silhouettes[i]
		s.x += s.speed * s.direction * delta
		s.walk_cycle += delta * s.speed * 0.1

		# Check if out of view
		if s.direction > 0 and s.x > window_rect.size.x + 40:
			to_remove.append(i)
			passerby_passed.emit()
		elif s.direction < 0 and s.x < -40:
			to_remove.append(i)
			passerby_passed.emit()

	# Remove finished silhouettes (reverse order)
	for i in range(to_remove.size() - 1, -1, -1):
		active_silhouettes.remove_at(to_remove[i])

	queue_redraw()


func _draw() -> void:
	if window_rect.size == Vector2.ZERO:
		return

	# Clip to window area
	for s in active_silhouettes:
		var x: float = window_rect.position.x + float(s.x)
		var ground_y: float = window_rect.position.y + window_rect.size.y - 6  # Just above window sill

		# Only draw if within window bounds
		if x >= window_rect.position.x - 20 and x <= window_rect.position.x + window_rect.size.x + 20:
			_draw_silhouette(Vector2(x, ground_y), s)


func _draw_silhouette(pos: Vector2, data: Dictionary) -> void:
	var height: float = data.height
	var walk_phase: float = sin(data.walk_cycle) * 3.0
	var facing_right: bool = data.direction > 0

	# Silhouette color - slightly lighter for people further away
	var color := SILHOUETTE_COLOR

	match data.type:
		SilhouetteType.PERSON:
			_draw_basic_person(pos, height, walk_phase, facing_right, color)
		SilhouetteType.PERSON_WITH_BAG:
			_draw_person_with_bag(pos, height, walk_phase, facing_right, color)
		SilhouetteType.PERSON_WITH_PHONE:
			_draw_person_with_phone(pos, height, walk_phase, facing_right, color)
		SilhouetteType.PERSON_TALL:
			_draw_basic_person(pos, height * 1.15, walk_phase, facing_right, color)
		SilhouetteType.PERSON_CHILD:
			_draw_basic_person(pos, height * 0.6, walk_phase * 1.3, facing_right, color)

	# Draw umbrella if raining
	if data.has_umbrella:
		_draw_umbrella(pos, height, facing_right, color)


func _draw_basic_person(pos: Vector2, height: float, walk_phase: float, facing_right: bool, color: Color) -> void:
	var head_radius := height * 0.12
	var body_height := height * 0.4
	var leg_length := height * 0.35

	# Head
	var head_y := pos.y - height + head_radius
	draw_circle(Vector2(pos.x, head_y), head_radius, color)

	# Body (rectangle)
	var body_width := height * 0.2
	var body_top := head_y + head_radius
	draw_rect(Rect2(pos.x - body_width/2, body_top, body_width, body_height), color)

	# Legs (with walking animation)
	var leg_top := body_top + body_height
	var leg_spread := walk_phase * 0.8

	# Left leg
	var left_foot := Vector2(pos.x - leg_spread - 3, pos.y)
	draw_line(Vector2(pos.x - 2, leg_top), left_foot, color, 4)

	# Right leg
	var right_foot := Vector2(pos.x + leg_spread + 3, pos.y)
	draw_line(Vector2(pos.x + 2, leg_top), right_foot, color, 4)

	# Arms (slight swing)
	var arm_y := body_top + body_height * 0.15
	var arm_length := height * 0.25
	var arm_swing := walk_phase * 0.5

	# Left arm
	draw_line(
		Vector2(pos.x - body_width/2, arm_y),
		Vector2(pos.x - body_width/2 - 5 + arm_swing, arm_y + arm_length),
		color, 3
	)

	# Right arm
	draw_line(
		Vector2(pos.x + body_width/2, arm_y),
		Vector2(pos.x + body_width/2 + 5 - arm_swing, arm_y + arm_length),
		color, 3
	)


func _draw_person_with_bag(pos: Vector2, height: float, walk_phase: float, facing_right: bool, color: Color) -> void:
	_draw_basic_person(pos, height, walk_phase, facing_right, color)

	# Add shoulder bag
	var bag_x := pos.x + (10 if facing_right else -10)
	var bag_y := pos.y - height * 0.4
	draw_rect(Rect2(bag_x - 6, bag_y, 12, 15), color)


func _draw_person_with_phone(pos: Vector2, height: float, walk_phase: float, facing_right: bool, color: Color) -> void:
	var head_radius := height * 0.12
	var body_height := height * 0.4

	# Head (looking down slightly)
	var head_y := pos.y - height + head_radius
	draw_circle(Vector2(pos.x, head_y + 2), head_radius, color)

	# Body
	var body_width := height * 0.2
	var body_top := head_y + head_radius + 2
	draw_rect(Rect2(pos.x - body_width/2, body_top, body_width, body_height), color)

	# Legs
	var leg_top := body_top + body_height
	var leg_spread := walk_phase * 0.6  # Slower walk when on phone
	draw_line(Vector2(pos.x - 2, leg_top), Vector2(pos.x - leg_spread - 3, pos.y), color, 4)
	draw_line(Vector2(pos.x + 2, leg_top), Vector2(pos.x + leg_spread + 3, pos.y), color, 4)

	# Phone held up
	var phone_side := 1 if facing_right else -1
	var phone_x := pos.x + phone_side * 12
	var phone_y := pos.y - height * 0.55
	draw_rect(Rect2(phone_x - 3, phone_y - 5, 6, 10), color)

	# Arm holding phone
	var arm_y := body_top + body_height * 0.15
	draw_line(Vector2(pos.x + phone_side * body_width/2, arm_y), Vector2(phone_x, phone_y), color, 3)


func _draw_umbrella(pos: Vector2, height: float, facing_right: bool, color: Color) -> void:
	var umbrella_top := pos.y - height - 15
	var umbrella_x := pos.x + (5 if facing_right else -5)

	# Umbrella handle (line from hand to top)
	var hand_y := pos.y - height * 0.5
	draw_line(Vector2(umbrella_x, hand_y), Vector2(umbrella_x, umbrella_top), color, 2)

	# Umbrella canopy (arc)
	var canopy_width := 25.0
	var canopy_height := 10.0
	var points := PackedVector2Array()

	for i in range(9):
		var t := float(i) / 8.0
		var x := umbrella_x - canopy_width/2 + canopy_width * t
		var y := umbrella_top + sin(t * PI) * canopy_height
		points.append(Vector2(x, y))

	# Close the canopy
	points.append(Vector2(umbrella_x + canopy_width/2, umbrella_top))
	points.append(Vector2(umbrella_x - canopy_width/2, umbrella_top))

	draw_polygon(points, [color])
