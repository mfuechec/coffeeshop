extends Node2D
## Manages the cozy seating area with tables and seated customers
## Customers appear based on reputation and time of day

signal seating_updated

# Customer activity types
enum Activity { LAPTOP, READING, SIPPING, CHATTING, PHONE }

# Appearance configuration
const SKIN_TONES := [
	Color(0.96, 0.87, 0.78),  # Light
	Color(0.90, 0.75, 0.62),  # Medium light
	Color(0.78, 0.60, 0.48),  # Medium
	Color(0.60, 0.42, 0.32),  # Medium dark
	Color(0.42, 0.30, 0.22)   # Dark
]

const HAIR_COLORS := [
	Color(0.12, 0.10, 0.08),  # Black
	Color(0.30, 0.20, 0.12),  # Dark brown
	Color(0.50, 0.35, 0.22),  # Brown
	Color(0.70, 0.52, 0.32),  # Light brown
	Color(0.88, 0.78, 0.58),  # Blonde
	Color(0.62, 0.22, 0.18),  # Auburn
	Color(0.45, 0.45, 0.50)   # Gray
]

const SHIRT_COLORS := [
	Color(0.92, 0.90, 0.88),  # Cream
	Color(0.22, 0.28, 0.38),  # Navy
	Color(0.58, 0.32, 0.28),  # Rust
	Color(0.32, 0.48, 0.38),  # Forest green
	Color(0.82, 0.72, 0.58),  # Tan
	Color(0.62, 0.52, 0.72),  # Lavender
	Color(0.75, 0.42, 0.45),  # Rose
	Color(0.38, 0.52, 0.62)   # Steel blue
]

# Table/furniture colors
const TABLE_COLOR := Color(0.52, 0.38, 0.28)
const TABLE_DARK := Color(0.38, 0.28, 0.20)
const CHAIR_COLOR := Color(0.45, 0.35, 0.28)
const CUP_COLOR := Color(0.96, 0.94, 0.92)

# Customer data
var seated_customers: Array[Dictionary] = []
var table_data: Array[Dictionary] = []
var shop_rect: Rect2 = Rect2()

# Animation
var animation_time: float = 0.0

# Spawn configuration
var spawn_timer: Timer
const SPAWN_CHECK_INTERVAL := 12.0


func _ready() -> void:
	_setup_timer()


func set_shop_area(rect: Rect2) -> void:
	shop_rect = rect
	_calculate_table_positions()
	_check_spawn()


func _setup_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = SPAWN_CHECK_INTERVAL
	spawn_timer.timeout.connect(_check_spawn)
	add_child(spawn_timer)
	spawn_timer.start()

	# Initial spawn after short delay
	await get_tree().create_timer(1.0).timeout
	_check_spawn()


func _calculate_table_positions() -> void:
	table_data.clear()

	if shop_rect.size == Vector2.ZERO:
		return

	var w := shop_rect.size.x
	var h := shop_rect.size.y

	# Scale factor based on screen size
	var scale_factor := minf(w / 1280.0, h / 720.0)
	scale_factor = clampf(scale_factor, 0.5, 1.5)

	# Table dimensions (scaled)
	var table_w := 80.0 * scale_factor
	var table_h := 55.0 * scale_factor

	# NEW LAYOUT: Wall is 35% of shop height, floor is 65%
	# Shop area is 70% of total height (workstation is 30%)
	# So floor starts at: 0.35 * 0.70 = 24.5% of total height
	var wall_portion := 0.35
	var shop_portion := 0.70  # Shop area is 70% of total, workstation is 30%
	var floor_start_y := h * shop_portion * wall_portion  # Where floor begins

	# Tables should be in the floor area, leaving room for:
	# - Some space from the wall
	# - The counter at the bottom
	# - The customer avatar area (center-right)
	var seating_start_y := floor_start_y + 20 * scale_factor
	var seating_end_y := h * shop_portion - 60 * scale_factor  # Leave room for counter items

	# Table 1: Near the window (cozy corner spot) - left side
	table_data.append({
		"position": Vector2(w * 0.04, seating_start_y + 15 * scale_factor),
		"size": Vector2(table_w * 0.95, table_h),
		"scale": scale_factor,
		"has_plant": true
	})

	# Table 2: Center area (but left of where customer avatar appears)
	table_data.append({
		"position": Vector2(w * 0.18, seating_start_y + 45 * scale_factor),
		"size": Vector2(table_w, table_h),
		"scale": scale_factor,
		"has_plant": false
	})

	# Table 3: Additional seating further back (smaller, near wall)
	table_data.append({
		"position": Vector2(w * 0.08, seating_start_y + 90 * scale_factor),
		"size": Vector2(table_w * 0.85, table_h * 0.9),
		"scale": scale_factor * 0.9,
		"has_plant": true
	})


func _check_spawn() -> void:
	if table_data.is_empty():
		return

	var target_count := _get_target_customer_count()

	# Spawn new customers if needed
	while seated_customers.size() < target_count:
		_spawn_customer()

	# Remove customers if too many (gracefully)
	while seated_customers.size() > target_count:
		seated_customers.pop_back()

	queue_redraw()


func _get_target_customer_count() -> int:
	var base_count := 1  # Start with 1 customer for coziness

	# Based on reputation
	if GameManager:
		var rep := GameManager.reputation
		if rep >= 20:
			base_count = 3
		elif rep >= 10:
			base_count = 2
		elif rep >= 3:
			base_count = 1
		else:
			base_count = 0

	# Adjust by time of day
	if TimeManager:
		match TimeManager.current_period:
			TimeManager.TimePeriod.MORNING:
				base_count = mini(base_count + 1, table_data.size())  # Busy morning
			TimeManager.TimePeriod.AFTERNOON:
				pass  # Normal
			TimeManager.TimePeriod.EVENING:
				base_count = maxi(base_count - 1, 1) if base_count > 0 else 0  # Quieter evening
			TimeManager.TimePeriod.NIGHT:
				base_count = 0  # Closed

	return mini(base_count, table_data.size())


func _spawn_customer() -> void:
	# Find an unoccupied table
	var occupied_tables: Array[int] = []
	for c in seated_customers:
		occupied_tables.append(c.table_index)

	var available: Array[int] = []
	for i in range(table_data.size()):
		if i not in occupied_tables:
			available.append(i)

	if available.is_empty():
		return

	var table_index: int = available.pick_random()
	var table: Dictionary = table_data[table_index]

	var customer := {
		"table_index": table_index,
		"activity": _get_random_activity(),
		"skin_tone": SKIN_TONES.pick_random(),
		"hair_color": HAIR_COLORS.pick_random(),
		"shirt_color": SHIRT_COLORS.pick_random(),
		"has_glasses": randf() > 0.7,
		"hair_style": randi() % 4,  # 0=short, 1=medium, 2=long, 3=bun
		"animation_offset": randf() * TAU
	}

	seated_customers.append(customer)


func _get_random_activity() -> Activity:
	var roll := randf()
	if roll < 0.35:
		return Activity.LAPTOP
	elif roll < 0.55:
		return Activity.READING
	elif roll < 0.75:
		return Activity.SIPPING
	elif roll < 0.90:
		return Activity.PHONE
	else:
		return Activity.CHATTING


func _process(delta: float) -> void:
	if GameManager and GameManager.idle_mode:
		return

	animation_time += delta
	queue_redraw()


func _draw() -> void:
	if shop_rect.size == Vector2.ZERO:
		return

	# Draw tables (with customers if occupied)
	for i in range(table_data.size()):
		var table: Dictionary = table_data[i]
		var customer: Dictionary = _get_customer_at_table(i)
		_draw_table_with_customer(table, customer)


func _get_customer_at_table(table_index: int) -> Dictionary:
	for c in seated_customers:
		if c.table_index == table_index:
			return c
	return {}


func _draw_table_with_customer(table: Dictionary, customer: Dictionary) -> void:
	var pos: Vector2 = table.position
	var table_size: Vector2 = table.size
	var scale: float = table.scale

	# Draw chair first (behind table)
	_draw_chair(pos, table_size, scale)

	# Draw customer if present (sitting in chair)
	if not customer.is_empty():
		_draw_seated_customer(pos, table_size, scale, customer)

	# Draw table (in front of customer's lower body)
	_draw_table(pos, table_size, scale, table.has_plant, not customer.is_empty())


func _draw_chair(pos: Vector2, table_size: Vector2, scale: float) -> void:
	var chair_w := 40.0 * scale
	var chair_h := 55.0 * scale
	var chair_x := pos.x + table_size.x * 0.5 - chair_w * 0.5
	var chair_y := pos.y - chair_h * 0.3

	# Chair back
	var back_color := CHAIR_COLOR
	draw_rect(Rect2(chair_x + 2, chair_y, chair_w - 4, chair_h * 0.6), back_color)
	draw_rect(Rect2(chair_x, chair_y, chair_w, 4 * scale), back_color.darkened(0.1))  # Top rail

	# Chair seat (will be partially covered by table)
	var seat_y := chair_y + chair_h * 0.55
	draw_rect(Rect2(chair_x, seat_y, chair_w, 6 * scale), back_color.lightened(0.05))


func _draw_table(pos: Vector2, table_size: Vector2, scale: float, has_plant: bool, has_customer: bool) -> void:
	var table_top_y := pos.y + table_size.y * 0.4

	# Table shadow
	draw_rect(Rect2(pos.x + 3, table_top_y + 3, table_size.x, 6 * scale), Color(0, 0, 0, 0.15))

	# Table top
	draw_rect(Rect2(pos.x, table_top_y, table_size.x, 6 * scale), TABLE_COLOR)
	draw_rect(Rect2(pos.x, table_top_y, table_size.x, 2 * scale), TABLE_COLOR.lightened(0.15))  # Highlight

	# Table legs
	var leg_w := 5 * scale
	var leg_h := table_size.y * 0.55
	draw_rect(Rect2(pos.x + table_size.x * 0.15, table_top_y + 6 * scale, leg_w, leg_h), TABLE_DARK)
	draw_rect(Rect2(pos.x + table_size.x * 0.85 - leg_w, table_top_y + 6 * scale, leg_w, leg_h), TABLE_DARK)

	# Items on table
	var item_y := table_top_y - 2 * scale

	# Coffee cup (always present for ambiance)
	var cup_x := pos.x + table_size.x * 0.7
	_draw_coffee_cup(Vector2(cup_x, item_y), scale)

	# Plant in pot (cozy touch)
	if has_plant:
		var plant_x := pos.x + table_size.x * 0.2
		_draw_small_plant(Vector2(plant_x, item_y), scale)


func _draw_coffee_cup(pos: Vector2, scale: float) -> void:
	var cup_w := 12 * scale
	var cup_h := 14 * scale

	# Cup body
	draw_rect(Rect2(pos.x - cup_w/2, pos.y - cup_h, cup_w, cup_h), CUP_COLOR)
	draw_rect(Rect2(pos.x - cup_w/2, pos.y - cup_h, cup_w, 3 * scale), CUP_COLOR.darkened(0.05))

	# Handle
	draw_arc(Vector2(pos.x + cup_w/2, pos.y - cup_h * 0.5), 4 * scale, -PI/2, PI/2, 6, CUP_COLOR.darkened(0.1), 2 * scale)

	# Steam wisps
	var steam_alpha := (sin(animation_time * 2) + 1) * 0.2 + 0.1
	var steam_color := Color(1, 1, 1, steam_alpha)
	for i in range(2):
		var wisp_x := pos.x - 2 + i * 4
		var wisp_y := pos.y - cup_h - 5 * scale - sin(animation_time * 3 + i) * 3
		draw_circle(Vector2(wisp_x, wisp_y), 2 * scale, steam_color)


func _draw_small_plant(pos: Vector2, scale: float) -> void:
	var pot_w := 14 * scale
	var pot_h := 12 * scale

	# Pot
	var pot_color := Color(0.72, 0.45, 0.35)
	draw_rect(Rect2(pos.x - pot_w/2, pos.y - pot_h, pot_w, pot_h), pot_color)
	draw_rect(Rect2(pos.x - pot_w/2 - 2, pos.y - pot_h, pot_w + 4, 3 * scale), pot_color.darkened(0.1))

	# Plant leaves
	var leaf_color := Color(0.35, 0.55, 0.35)
	var leaf_y := pos.y - pot_h - 2
	draw_circle(Vector2(pos.x, leaf_y - 8 * scale), 6 * scale, leaf_color)
	draw_circle(Vector2(pos.x - 5 * scale, leaf_y - 4 * scale), 5 * scale, leaf_color.lightened(0.1))
	draw_circle(Vector2(pos.x + 5 * scale, leaf_y - 5 * scale), 5 * scale, leaf_color.darkened(0.05))


func _draw_seated_customer(table_pos: Vector2, table_size: Vector2, scale: float, data: Dictionary) -> void:
	var anim_phase: float = animation_time * 2.0 + data.animation_offset

	# Customer position (centered on chair, above table)
	var cx := table_pos.x + table_size.x * 0.5
	var table_top_y := table_pos.y + table_size.y * 0.4

	# Body dimensions (much larger than before)
	var head_r := 14.0 * scale
	var body_w := 28.0 * scale
	var body_h := 35.0 * scale
	var neck_h := 6.0 * scale

	# Position from table top
	var body_y := table_top_y - body_h * 0.7
	var head_y := body_y - neck_h - head_r

	var skin: Color = data.skin_tone
	var hair: Color = data.hair_color
	var shirt: Color = data.shirt_color

	# Draw based on activity
	match data.activity:
		Activity.LAPTOP:
			_draw_person_laptop(cx, head_y, body_y, head_r, body_w, body_h, table_top_y, scale, anim_phase, data)
		Activity.READING:
			_draw_person_reading(cx, head_y, body_y, head_r, body_w, body_h, table_top_y, scale, anim_phase, data)
		Activity.SIPPING:
			_draw_person_sipping(cx, head_y, body_y, head_r, body_w, body_h, table_top_y, scale, anim_phase, data)
		Activity.PHONE:
			_draw_person_phone(cx, head_y, body_y, head_r, body_w, body_h, table_top_y, scale, anim_phase, data)
		Activity.CHATTING:
			_draw_person_relaxed(cx, head_y, body_y, head_r, body_w, body_h, table_top_y, scale, anim_phase, data)


func _draw_person_base(cx: float, head_y: float, body_y: float, head_r: float, body_w: float, body_h: float, scale: float, data: Dictionary, head_tilt: float = 0) -> void:
	var skin: Color = data.skin_tone
	var hair: Color = data.hair_color
	var shirt: Color = data.shirt_color

	# Neck
	draw_rect(Rect2(cx - 5 * scale, head_y + head_r - 2, 10 * scale, 8 * scale), skin)

	# Body/torso
	var body_points := PackedVector2Array([
		Vector2(cx - body_w * 0.5, body_y),
		Vector2(cx - body_w * 0.45, body_y + body_h),
		Vector2(cx + body_w * 0.45, body_y + body_h),
		Vector2(cx + body_w * 0.5, body_y)
	])
	draw_polygon(body_points, [shirt])

	# Collar/neckline
	draw_arc(Vector2(cx, body_y + 2 * scale), 6 * scale, 0, PI, 6, shirt.darkened(0.15), 2 * scale)

	# Head
	draw_circle(Vector2(cx, head_y + head_tilt), head_r, skin)

	# Face details
	_draw_face(cx, head_y + head_tilt, head_r, scale, data)

	# Hair
	_draw_hair(cx, head_y + head_tilt, head_r, scale, hair, data.hair_style)


func _draw_face(cx: float, head_y: float, head_r: float, scale: float, data: Dictionary) -> void:
	var skin: Color = data.skin_tone

	# Eyes
	var eye_y := head_y - head_r * 0.1
	var eye_spacing := head_r * 0.4
	draw_circle(Vector2(cx - eye_spacing, eye_y), 2 * scale, skin.darkened(0.5))
	draw_circle(Vector2(cx + eye_spacing, eye_y), 2 * scale, skin.darkened(0.5))

	# Eyebrows
	draw_line(
		Vector2(cx - eye_spacing - 3 * scale, eye_y - 4 * scale),
		Vector2(cx - eye_spacing + 3 * scale, eye_y - 4 * scale),
		data.hair_color.darkened(0.2), 1.5 * scale
	)
	draw_line(
		Vector2(cx + eye_spacing - 3 * scale, eye_y - 4 * scale),
		Vector2(cx + eye_spacing + 3 * scale, eye_y - 4 * scale),
		data.hair_color.darkened(0.2), 1.5 * scale
	)

	# Nose (subtle)
	draw_line(
		Vector2(cx, eye_y + 2 * scale),
		Vector2(cx, eye_y + 6 * scale),
		skin.darkened(0.1), 1 * scale
	)

	# Mouth (slight smile)
	draw_arc(Vector2(cx, head_y + head_r * 0.4), 4 * scale, 0.2, PI - 0.2, 5, skin.darkened(0.25), 1.5 * scale)

	# Glasses if applicable
	if data.has_glasses:
		var glass_color := Color(0.2, 0.2, 0.25, 0.7)
		draw_circle(Vector2(cx - eye_spacing, eye_y), 5 * scale, Color.TRANSPARENT)
		draw_arc(Vector2(cx - eye_spacing, eye_y), 5 * scale, 0, TAU, 8, glass_color, 1 * scale)
		draw_arc(Vector2(cx + eye_spacing, eye_y), 5 * scale, 0, TAU, 8, glass_color, 1 * scale)
		draw_line(Vector2(cx - eye_spacing + 5 * scale, eye_y), Vector2(cx + eye_spacing - 5 * scale, eye_y), glass_color, 1 * scale)


func _draw_hair(cx: float, head_y: float, head_r: float, scale: float, color: Color, style: int) -> void:
	match style:
		0:  # Short hair
			draw_arc(Vector2(cx, head_y), head_r + 1, PI * 0.75, PI * 2.25, 12, color, 4 * scale)
		1:  # Medium hair
			draw_arc(Vector2(cx, head_y), head_r + 2, PI * 0.6, PI * 2.4, 12, color, 5 * scale)
			# Side hair
			draw_circle(Vector2(cx - head_r * 0.8, head_y + head_r * 0.3), 5 * scale, color)
			draw_circle(Vector2(cx + head_r * 0.8, head_y + head_r * 0.3), 5 * scale, color)
		2:  # Long hair
			draw_arc(Vector2(cx, head_y), head_r + 2, PI * 0.5, PI * 2.5, 12, color, 6 * scale)
			# Hair falling down
			draw_rect(Rect2(cx - head_r - 3 * scale, head_y, 6 * scale, head_r * 1.8), color)
			draw_rect(Rect2(cx + head_r - 3 * scale, head_y, 6 * scale, head_r * 1.8), color)
		3:  # Bun
			draw_arc(Vector2(cx, head_y), head_r + 1, PI * 0.7, PI * 2.3, 12, color, 4 * scale)
			draw_circle(Vector2(cx, head_y - head_r - 4 * scale), 7 * scale, color)


func _draw_person_laptop(cx: float, head_y: float, body_y: float, head_r: float, body_w: float, body_h: float, table_y: float, scale: float, anim: float, data: Dictionary) -> void:
	var skin: Color = data.skin_tone
	var shirt: Color = data.shirt_color

	# Looking down slightly
	_draw_person_base(cx, head_y, body_y, head_r, body_w, body_h, scale, data, 2 * scale)

	# Arms on table (typing)
	var arm_y := body_y + body_h * 0.3
	var typing := sin(anim * 4) * 2 * scale

	# Left arm
	draw_line(Vector2(cx - body_w * 0.45, arm_y), Vector2(cx - 15 * scale + typing, table_y - 8 * scale), skin, 4 * scale)
	# Right arm
	draw_line(Vector2(cx + body_w * 0.45, arm_y), Vector2(cx + 15 * scale - typing, table_y - 8 * scale), skin, 4 * scale)

	# Hands
	draw_circle(Vector2(cx - 15 * scale + typing, table_y - 8 * scale), 4 * scale, skin)
	draw_circle(Vector2(cx + 15 * scale - typing, table_y - 8 * scale), 4 * scale, skin)

	# Laptop
	var laptop_color := Color(0.28, 0.28, 0.32)
	var laptop_w := 35 * scale
	var laptop_x := cx - laptop_w / 2

	# Laptop base
	draw_rect(Rect2(laptop_x, table_y - 6 * scale, laptop_w, 4 * scale), laptop_color)

	# Laptop screen
	var screen_h := 22 * scale
	draw_rect(Rect2(laptop_x + 2 * scale, table_y - 6 * scale - screen_h, laptop_w - 4 * scale, screen_h), laptop_color)
	draw_rect(Rect2(laptop_x + 4 * scale, table_y - 4 * scale - screen_h, laptop_w - 8 * scale, screen_h - 4 * scale), Color(0.7, 0.8, 0.9))  # Screen glow


func _draw_person_reading(cx: float, head_y: float, body_y: float, head_r: float, body_w: float, body_h: float, table_y: float, scale: float, anim: float, data: Dictionary) -> void:
	var skin: Color = data.skin_tone

	_draw_person_base(cx, head_y, body_y, head_r, body_w, body_h, scale, data, 3 * scale)

	# Arms holding book up
	var arm_y := body_y + body_h * 0.35
	var book_y := table_y - 20 * scale

	draw_line(Vector2(cx - body_w * 0.4, arm_y), Vector2(cx - 12 * scale, book_y), skin, 4 * scale)
	draw_line(Vector2(cx + body_w * 0.4, arm_y), Vector2(cx + 12 * scale, book_y), skin, 4 * scale)

	# Hands
	draw_circle(Vector2(cx - 12 * scale, book_y), 4 * scale, skin)
	draw_circle(Vector2(cx + 12 * scale, book_y), 4 * scale, skin)

	# Book
	var book_w := 28 * scale
	var book_h := 20 * scale
	var book_color := Color(0.65, 0.45, 0.32)
	draw_rect(Rect2(cx - book_w/2, book_y - book_h/2, book_w, book_h), book_color)
	draw_line(Vector2(cx, book_y - book_h/2), Vector2(cx, book_y + book_h/2), Color(0.95, 0.93, 0.9), 2 * scale)  # Pages


func _draw_person_sipping(cx: float, head_y: float, body_y: float, head_r: float, body_w: float, body_h: float, table_y: float, scale: float, anim: float, data: Dictionary) -> void:
	var skin: Color = data.skin_tone

	var sip_cycle := sin(anim * 0.5)
	var is_sipping := sip_cycle > 0.6
	var head_tilt := 3 * scale if is_sipping else 0.0

	_draw_person_base(cx, head_y, body_y, head_r, body_w, body_h, scale, data, head_tilt)

	# Cup position
	var cup_y := table_y - 8 * scale if not is_sipping else head_y + head_r
	var cup_x := cx + 18 * scale

	# Right arm holding cup
	var arm_y := body_y + body_h * 0.3
	draw_line(Vector2(cx + body_w * 0.4, arm_y), Vector2(cup_x, cup_y + 6 * scale), skin, 4 * scale)
	draw_circle(Vector2(cup_x, cup_y + 6 * scale), 4 * scale, skin)

	# Left arm resting
	draw_line(Vector2(cx - body_w * 0.4, arm_y), Vector2(cx - 18 * scale, table_y - 4 * scale), skin, 4 * scale)
	draw_circle(Vector2(cx - 18 * scale, table_y - 4 * scale), 4 * scale, skin)

	# Cup in hand
	var held_cup_h := 16 * scale
	draw_rect(Rect2(cup_x - 6 * scale, cup_y - held_cup_h + 6 * scale, 12 * scale, held_cup_h), CUP_COLOR)


func _draw_person_phone(cx: float, head_y: float, body_y: float, head_r: float, body_w: float, body_h: float, table_y: float, scale: float, anim: float, data: Dictionary) -> void:
	var skin: Color = data.skin_tone

	_draw_person_base(cx, head_y, body_y, head_r, body_w, body_h, scale, data, 2 * scale)

	# Phone position
	var phone_x := cx + 10 * scale
	var phone_y := head_y + head_r * 1.2

	# Right arm holding phone
	var arm_y := body_y + body_h * 0.3
	draw_line(Vector2(cx + body_w * 0.4, arm_y), Vector2(phone_x, phone_y + 10 * scale), skin, 4 * scale)
	draw_circle(Vector2(phone_x, phone_y + 10 * scale), 4 * scale, skin)

	# Left arm on table
	draw_line(Vector2(cx - body_w * 0.4, arm_y), Vector2(cx - 18 * scale, table_y - 4 * scale), skin, 4 * scale)
	draw_circle(Vector2(cx - 18 * scale, table_y - 4 * scale), 4 * scale, skin)

	# Phone
	draw_rect(Rect2(phone_x - 5 * scale, phone_y, 10 * scale, 18 * scale), Color(0.15, 0.15, 0.18))
	draw_rect(Rect2(phone_x - 4 * scale, phone_y + 2 * scale, 8 * scale, 14 * scale), Color(0.5, 0.6, 0.8))  # Screen


func _draw_person_relaxed(cx: float, head_y: float, body_y: float, head_r: float, body_w: float, body_h: float, table_y: float, scale: float, anim: float, data: Dictionary) -> void:
	var skin: Color = data.skin_tone

	var nod := sin(anim * 1.5) * 1.5 * scale
	_draw_person_base(cx, head_y, body_y, head_r, body_w, body_h, scale, data, nod)

	# Arms resting on table
	var arm_y := body_y + body_h * 0.35
	draw_line(Vector2(cx - body_w * 0.4, arm_y), Vector2(cx - 20 * scale, table_y - 4 * scale), skin, 4 * scale)
	draw_line(Vector2(cx + body_w * 0.4, arm_y), Vector2(cx + 20 * scale, table_y - 4 * scale), skin, 4 * scale)

	# Hands
	draw_circle(Vector2(cx - 20 * scale, table_y - 4 * scale), 4 * scale, skin)
	draw_circle(Vector2(cx + 20 * scale, table_y - 4 * scale), 4 * scale, skin)
