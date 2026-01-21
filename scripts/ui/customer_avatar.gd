extends Control
## Procedurally drawn customer avatar

signal arrived
signal left

var customer_data: Dictionary = {}
var current_tween: Tween
var idle_tween: Tween
var base_position: Vector2 = Vector2.ZERO

# Color palettes based on personality
const PERSONALITY_COLORS := {
	"shy": Color(0.7, 0.8, 0.9),       # Soft blue
	"chatty": Color(1.0, 0.8, 0.4),    # Warm yellow
	"grumpy": Color(0.6, 0.5, 0.6),    # Muted purple
	"cheerful": Color(1.0, 0.6, 0.7),  # Pink
	"mysterious": Color(0.4, 0.3, 0.5),# Dark purple
	"tired": Color(0.6, 0.7, 0.6),     # Sage green
	"anxious": Color(0.9, 0.7, 0.5),   # Peach
	"chill": Color(0.5, 0.8, 0.8)      # Teal
}

const HAIR_COLORS := [
	Color(0.15, 0.1, 0.05),   # Dark brown
	Color(0.3, 0.2, 0.1),     # Brown
	Color(0.6, 0.4, 0.2),     # Light brown
	Color(0.9, 0.7, 0.4),     # Blonde
	Color(0.1, 0.1, 0.1),     # Black
	Color(0.5, 0.25, 0.1),    # Auburn
	Color(0.8, 0.4, 0.3),     # Red
	Color(0.4, 0.4, 0.5),     # Gray
]

const SKIN_TONES := [
	Color(0.96, 0.87, 0.78),  # Light
	Color(0.92, 0.78, 0.65),  # Fair
	Color(0.85, 0.68, 0.52),  # Medium
	Color(0.72, 0.54, 0.39),  # Tan
	Color(0.55, 0.38, 0.26),  # Brown
	Color(0.40, 0.27, 0.18),  # Dark
]

var shirt_color: Color
var hair_color: Color
var skin_tone: Color
var hair_style: int
var has_glasses: bool
var has_earrings: bool
var has_hat: bool
var has_bowtie: bool
var expression: int


func _ready() -> void:
	custom_minimum_size = Vector2(200, 250)
	modulate.a = 0.0  # Start invisible


func set_customer(data: Dictionary) -> void:
	customer_data = data
	_generate_appearance()
	queue_redraw()
	_animate_arrive()


func _generate_appearance() -> void:
	if customer_data.is_empty():
		return

	# Use customer ID as seed for consistent appearance
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(customer_data.get("id", "default"))

	# Get shirt color based on personality
	var personality: String = customer_data.get("personality", "chill")
	shirt_color = PERSONALITY_COLORS.get(personality, Color.GRAY)

	# Random but consistent features
	hair_color = HAIR_COLORS[rng.randi() % HAIR_COLORS.size()]
	skin_tone = SKIN_TONES[rng.randi() % SKIN_TONES.size()]
	hair_style = rng.randi() % 8  # 8 hairstyles: short, long, spiky, bald, ponytail, curly, undercut, braided
	has_glasses = rng.randf() < 0.3
	has_earrings = rng.randf() < 0.3
	has_hat = rng.randf() < 0.2  # Slightly less common
	has_bowtie = rng.randf() < 0.15  # Rarer accessory
	expression = rng.randi() % 5  # 5 expressions: happy, neutral, slight smile, tired, excited


func clear_customer() -> void:
	_animate_leave()


func _animate_arrive() -> void:
	# Kill any existing tweens
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()

	current_tween = create_tween()
	current_tween.set_ease(Tween.EASE_OUT)
	current_tween.set_trans(Tween.TRANS_BACK)

	# Start position (from below and invisible)
	modulate.a = 0.0
	position.y = 50
	base_position = Vector2.ZERO

	# Animate in
	current_tween.set_parallel(true)
	current_tween.tween_property(self, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUAD)
	current_tween.tween_property(self, "position:y", 0.0, 0.5)

	current_tween.set_parallel(false)
	current_tween.tween_callback(_on_arrive_complete)


func _on_arrive_complete() -> void:
	arrived.emit()
	_start_idle_animation()


func _start_idle_animation() -> void:
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()

	idle_tween = create_tween()
	idle_tween.set_loops()  # Loop forever
	idle_tween.set_ease(Tween.EASE_IN_OUT)
	idle_tween.set_trans(Tween.TRANS_SINE)

	# Gentle bobbing motion
	idle_tween.tween_property(self, "position:y", -4.0, 1.2)
	idle_tween.tween_property(self, "position:y", 0.0, 1.2)


func _animate_leave() -> void:
	if customer_data.is_empty():
		return

	# Kill any existing tweens
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()

	current_tween = create_tween()
	current_tween.set_ease(Tween.EASE_IN)
	current_tween.set_trans(Tween.TRANS_QUAD)

	# Animate out (slide up and fade)
	current_tween.set_parallel(true)
	current_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	current_tween.tween_property(self, "position:y", -40.0, 0.4).set_trans(Tween.TRANS_BACK)

	current_tween.set_parallel(false)
	current_tween.tween_callback(_on_leave_complete)


func _on_leave_complete() -> void:
	customer_data = {}
	position.y = 0
	queue_redraw()
	left.emit()


func _draw() -> void:
	if customer_data.is_empty():
		return

	var center := size / 2
	var scale_factor := minf(size.x / 200.0, size.y / 250.0)

	# Body / Shirt
	var body_rect := Rect2(
		center.x - 50 * scale_factor,
		center.y + 20 * scale_factor,
		100 * scale_factor,
		120 * scale_factor
	)
	draw_rect(body_rect, shirt_color, true)
	# Shirt collar
	var collar_points := PackedVector2Array([
		Vector2(center.x - 15 * scale_factor, center.y + 20 * scale_factor),
		Vector2(center.x, center.y + 45 * scale_factor),
		Vector2(center.x + 15 * scale_factor, center.y + 20 * scale_factor)
	])
	draw_polygon(collar_points, [skin_tone])

	# Head
	var head_center := Vector2(center.x, center.y - 20 * scale_factor)
	var head_radius := 55 * scale_factor
	draw_circle(head_center, head_radius, skin_tone)

	# Hair based on style
	_draw_hair(head_center, head_radius, scale_factor)

	# Face
	_draw_face(head_center, scale_factor)

	# Glasses if applicable
	if has_glasses:
		_draw_glasses(head_center, scale_factor)

	# Earrings if applicable (draw after face so they appear at ear level)
	if has_earrings and not has_hat:  # Hat covers ears
		_draw_earrings(head_center, head_radius, scale_factor)

	# Hat if applicable (draw last to cover hair)
	if has_hat:
		_draw_hat(head_center, head_radius, scale_factor)

	# Bowtie if applicable
	if has_bowtie:
		_draw_bowtie(center, scale_factor)

	# Name tag
	var name_text: String = customer_data.get("name", "")
	if not name_text.is_empty():
		var font := ThemeDB.fallback_font
		var font_size := int(14 * scale_factor)
		var text_size := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(
			font,
			Vector2(center.x - text_size.x / 2, size.y - 10 * scale_factor),
			name_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			font_size,
			Color.WHITE
		)


func _draw_hair(head_center: Vector2, head_radius: float, scale_factor: float) -> void:
	match hair_style:
		0:  # Short hair
			var hair_rect := Rect2(
				head_center.x - head_radius,
				head_center.y - head_radius,
				head_radius * 2,
				head_radius * 0.8
			)
			draw_rect(hair_rect, hair_color, true)
			# Round top
			draw_circle(Vector2(head_center.x, head_center.y - head_radius * 0.6), head_radius * 0.7, hair_color)
		1:  # Long hair
			draw_circle(Vector2(head_center.x, head_center.y - head_radius * 0.3), head_radius * 1.1, hair_color)
			var hair_sides := Rect2(
				head_center.x - head_radius * 1.1,
				head_center.y - head_radius * 0.5,
				head_radius * 2.2,
				head_radius * 2.0
			)
			draw_rect(hair_sides, hair_color, true)
		2:  # Spiky / messy
			for i in range(7):
				var angle := -PI * 0.8 + (PI * 0.6 / 6.0) * i
				var spike_base := head_center + Vector2(cos(angle), sin(angle)) * head_radius * 0.7
				var spike_tip := head_center + Vector2(cos(angle), sin(angle)) * head_radius * 1.3
				var spike_width := 15 * scale_factor
				var perp := Vector2(-sin(angle), cos(angle)) * spike_width
				var spike_points := PackedVector2Array([
					spike_base - perp,
					spike_tip,
					spike_base + perp
				])
				draw_polygon(spike_points, [hair_color])
			draw_circle(Vector2(head_center.x, head_center.y - head_radius * 0.5), head_radius * 0.8, hair_color)
		3:  # Bald / very short
			draw_circle(Vector2(head_center.x, head_center.y - head_radius * 0.7), head_radius * 0.5, hair_color.lerp(skin_tone, 0.7))
		4:  # Ponytail
			# Base hair on head
			var hair_rect := Rect2(
				head_center.x - head_radius,
				head_center.y - head_radius,
				head_radius * 2,
				head_radius * 0.7
			)
			draw_rect(hair_rect, hair_color, true)
			draw_circle(Vector2(head_center.x, head_center.y - head_radius * 0.6), head_radius * 0.65, hair_color)
			# Ponytail extending to the side
			var tail_start := Vector2(head_center.x + head_radius * 0.6, head_center.y - head_radius * 0.3)
			var tail_mid := Vector2(head_center.x + head_radius * 1.2, head_center.y)
			var tail_end := Vector2(head_center.x + head_radius * 1.0, head_center.y + head_radius * 0.8)
			# Draw ponytail as overlapping circles
			draw_circle(tail_start, head_radius * 0.25, hair_color)
			draw_circle(tail_mid, head_radius * 0.22, hair_color)
			draw_circle(tail_end, head_radius * 0.18, hair_color)
			# Hair tie
			draw_circle(tail_start, head_radius * 0.12, hair_color.darkened(0.3))
		5:  # Curly
			# Multiple overlapping circles for volume
			draw_circle(Vector2(head_center.x, head_center.y - head_radius * 0.5), head_radius * 0.9, hair_color)
			for i in range(8):
				var angle := -PI * 0.9 + (PI * 0.8 / 7.0) * i
				var curl_pos := head_center + Vector2(cos(angle), sin(angle)) * head_radius * 0.75
				draw_circle(curl_pos, head_radius * 0.35, hair_color)
			# Extra curls on sides
			draw_circle(Vector2(head_center.x - head_radius * 0.9, head_center.y - head_radius * 0.1), head_radius * 0.3, hair_color)
			draw_circle(Vector2(head_center.x + head_radius * 0.9, head_center.y - head_radius * 0.1), head_radius * 0.3, hair_color)
		6:  # Undercut
			# Short sides
			var side_color := hair_color.lerp(skin_tone, 0.5)
			draw_rect(Rect2(head_center.x - head_radius, head_center.y - head_radius * 0.3, head_radius * 0.4, head_radius * 0.8), side_color, true)
			draw_rect(Rect2(head_center.x + head_radius * 0.6, head_center.y - head_radius * 0.3, head_radius * 0.4, head_radius * 0.8), side_color, true)
			# Longer top swept to one side
			var top_points := PackedVector2Array([
				Vector2(head_center.x - head_radius * 0.6, head_center.y - head_radius * 0.3),
				Vector2(head_center.x - head_radius * 0.3, head_center.y - head_radius * 1.1),
				Vector2(head_center.x + head_radius * 0.5, head_center.y - head_radius * 0.9),
				Vector2(head_center.x + head_radius * 0.6, head_center.y - head_radius * 0.3)
			])
			draw_polygon(top_points, [hair_color])
		7:  # Braided
			# Base hair
			draw_circle(Vector2(head_center.x, head_center.y - head_radius * 0.4), head_radius * 0.95, hair_color)
			# Braid going down one side
			var braid_x := head_center.x - head_radius * 0.8
			var braid_start_y := head_center.y
			for i in range(5):
				var y_offset := i * head_radius * 0.25
				var x_wiggle := sin(i * PI) * head_radius * 0.1
				draw_circle(Vector2(braid_x + x_wiggle, braid_start_y + y_offset), head_radius * 0.15, hair_color)
				draw_circle(Vector2(braid_x - x_wiggle + head_radius * 0.15, braid_start_y + y_offset + head_radius * 0.12), head_radius * 0.13, hair_color.darkened(0.1))


func _draw_face(head_center: Vector2, scale_factor: float) -> void:
	var eye_y := head_center.y - 5 * scale_factor
	var eye_spacing := 20 * scale_factor
	var eye_radius := 6 * scale_factor

	# Eyes
	draw_circle(Vector2(head_center.x - eye_spacing, eye_y), eye_radius, Color.WHITE)
	draw_circle(Vector2(head_center.x + eye_spacing, eye_y), eye_radius, Color.WHITE)

	# Pupils
	var pupil_radius := 3 * scale_factor
	draw_circle(Vector2(head_center.x - eye_spacing, eye_y), pupil_radius, Color(0.2, 0.15, 0.1))
	draw_circle(Vector2(head_center.x + eye_spacing, eye_y), pupil_radius, Color(0.2, 0.15, 0.1))

	# Expression-based mouth
	var mouth_y := head_center.y + 25 * scale_factor
	match expression:
		0:  # Happy
			var mouth_points := PackedVector2Array()
			for i in range(11):
				var t := float(i) / 10.0
				var x := head_center.x + (t - 0.5) * 30 * scale_factor
				var y := mouth_y + sin(t * PI) * 8 * scale_factor
				mouth_points.append(Vector2(x, y))
			draw_polyline(mouth_points, Color(0.3, 0.2, 0.2), 2.0 * scale_factor)
		1:  # Neutral
			draw_line(
				Vector2(head_center.x - 12 * scale_factor, mouth_y),
				Vector2(head_center.x + 12 * scale_factor, mouth_y),
				Color(0.3, 0.2, 0.2),
				2.0 * scale_factor
			)
		2:  # Slight smile
			var mouth_points := PackedVector2Array()
			for i in range(11):
				var t := float(i) / 10.0
				var x := head_center.x + (t - 0.5) * 25 * scale_factor
				var y := mouth_y + sin(t * PI) * 5 * scale_factor
				mouth_points.append(Vector2(x, y))
			draw_polyline(mouth_points, Color(0.3, 0.2, 0.2), 2.0 * scale_factor)
		3:  # Tired - droopy eyes and slight frown
			# Redraw eyes as half-closed
			draw_circle(Vector2(head_center.x - eye_spacing, eye_y), eye_radius, Color.WHITE)
			draw_circle(Vector2(head_center.x + eye_spacing, eye_y), eye_radius, Color.WHITE)
			# Droopy eyelids
			var lid_color := skin_tone.darkened(0.1)
			draw_rect(Rect2(head_center.x - eye_spacing - eye_radius, eye_y - eye_radius, eye_radius * 2, eye_radius * 0.8), lid_color, true)
			draw_rect(Rect2(head_center.x + eye_spacing - eye_radius, eye_y - eye_radius, eye_radius * 2, eye_radius * 0.8), lid_color, true)
			# Pupils lower
			draw_circle(Vector2(head_center.x - eye_spacing, eye_y + 2 * scale_factor), pupil_radius, Color(0.2, 0.15, 0.1))
			draw_circle(Vector2(head_center.x + eye_spacing, eye_y + 2 * scale_factor), pupil_radius, Color(0.2, 0.15, 0.1))
			# Slight frown
			var frown_points := PackedVector2Array()
			for i in range(11):
				var t := float(i) / 10.0
				var x := head_center.x + (t - 0.5) * 20 * scale_factor
				var y := mouth_y - sin(t * PI) * 3 * scale_factor
				frown_points.append(Vector2(x, y))
			draw_polyline(frown_points, Color(0.3, 0.2, 0.2), 2.0 * scale_factor)
		4:  # Excited - wide eyes and big smile
			# Bigger eyes
			var big_eye_radius := eye_radius * 1.3
			draw_circle(Vector2(head_center.x - eye_spacing, eye_y), big_eye_radius, Color.WHITE)
			draw_circle(Vector2(head_center.x + eye_spacing, eye_y), big_eye_radius, Color.WHITE)
			# Bigger pupils with highlight
			draw_circle(Vector2(head_center.x - eye_spacing, eye_y), pupil_radius * 1.2, Color(0.2, 0.15, 0.1))
			draw_circle(Vector2(head_center.x + eye_spacing, eye_y), pupil_radius * 1.2, Color(0.2, 0.15, 0.1))
			# Eye sparkle
			draw_circle(Vector2(head_center.x - eye_spacing - 2 * scale_factor, eye_y - 2 * scale_factor), 2 * scale_factor, Color.WHITE)
			draw_circle(Vector2(head_center.x + eye_spacing - 2 * scale_factor, eye_y - 2 * scale_factor), 2 * scale_factor, Color.WHITE)
			# Big smile
			var big_smile := PackedVector2Array()
			for i in range(11):
				var t := float(i) / 10.0
				var x := head_center.x + (t - 0.5) * 35 * scale_factor
				var y := mouth_y + sin(t * PI) * 12 * scale_factor
				big_smile.append(Vector2(x, y))
			draw_polyline(big_smile, Color(0.3, 0.2, 0.2), 2.5 * scale_factor)


func _draw_glasses(head_center: Vector2, scale_factor: float) -> void:
	var glasses_y := head_center.y - 5 * scale_factor
	var eye_spacing := 20 * scale_factor
	var lens_size := 14 * scale_factor
	var glasses_color := Color(0.2, 0.2, 0.2)

	# Left lens
	draw_rect(
		Rect2(head_center.x - eye_spacing - lens_size, glasses_y - lens_size, lens_size * 2, lens_size * 2),
		glasses_color,
		false,
		2.0 * scale_factor
	)
	# Right lens
	draw_rect(
		Rect2(head_center.x + eye_spacing - lens_size, glasses_y - lens_size, lens_size * 2, lens_size * 2),
		glasses_color,
		false,
		2.0 * scale_factor
	)
	# Bridge
	draw_line(
		Vector2(head_center.x - eye_spacing + lens_size, glasses_y),
		Vector2(head_center.x + eye_spacing - lens_size, glasses_y),
		glasses_color,
		2.0 * scale_factor
	)


func _draw_earrings(head_center: Vector2, head_radius: float, scale_factor: float) -> void:
	var earring_color := Color(0.85, 0.75, 0.4)  # Gold color
	var ear_y := head_center.y + 5 * scale_factor
	var ear_x_offset := head_radius * 0.95

	# Simple drop earrings - small circle with dangling element
	# Left earring
	draw_circle(Vector2(head_center.x - ear_x_offset, ear_y), 3 * scale_factor, earring_color)
	draw_circle(Vector2(head_center.x - ear_x_offset, ear_y + 8 * scale_factor), 4 * scale_factor, earring_color)

	# Right earring
	draw_circle(Vector2(head_center.x + ear_x_offset, ear_y), 3 * scale_factor, earring_color)
	draw_circle(Vector2(head_center.x + ear_x_offset, ear_y + 8 * scale_factor), 4 * scale_factor, earring_color)


func _draw_hat(head_center: Vector2, head_radius: float, scale_factor: float) -> void:
	var hat_color := shirt_color.darkened(0.2)  # Match shirt but slightly darker

	# Beanie style hat
	var hat_top := head_center.y - head_radius * 1.2
	var hat_bottom := head_center.y - head_radius * 0.4

	# Main hat body (rounded rectangle effect with circles)
	draw_circle(Vector2(head_center.x, hat_top + head_radius * 0.3), head_radius * 0.8, hat_color)
	var hat_rect := Rect2(
		head_center.x - head_radius * 0.85,
		hat_top + head_radius * 0.2,
		head_radius * 1.7,
		hat_bottom - hat_top
	)
	draw_rect(hat_rect, hat_color, true)

	# Hat brim/fold
	var brim_color := hat_color.darkened(0.15)
	var brim_rect := Rect2(
		head_center.x - head_radius * 0.9,
		hat_bottom - head_radius * 0.15,
		head_radius * 1.8,
		head_radius * 0.2
	)
	draw_rect(brim_rect, brim_color, true)


func _draw_bowtie(center: Vector2, scale_factor: float) -> void:
	var bowtie_color := Color(0.7, 0.2, 0.2)  # Classic red
	var bowtie_y := center.y + 22 * scale_factor  # Just below collar
	var bowtie_x := center.x

	# Left wing
	var left_wing := PackedVector2Array([
		Vector2(bowtie_x - 5 * scale_factor, bowtie_y),
		Vector2(bowtie_x - 18 * scale_factor, bowtie_y - 8 * scale_factor),
		Vector2(bowtie_x - 18 * scale_factor, bowtie_y + 8 * scale_factor)
	])
	draw_polygon(left_wing, [bowtie_color])

	# Right wing
	var right_wing := PackedVector2Array([
		Vector2(bowtie_x + 5 * scale_factor, bowtie_y),
		Vector2(bowtie_x + 18 * scale_factor, bowtie_y - 8 * scale_factor),
		Vector2(bowtie_x + 18 * scale_factor, bowtie_y + 8 * scale_factor)
	])
	draw_polygon(right_wing, [bowtie_color])

	# Center knot
	draw_circle(Vector2(bowtie_x, bowtie_y), 5 * scale_factor, bowtie_color.darkened(0.2))
