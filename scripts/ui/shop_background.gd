extends Control
## Procedurally drawn coffee shop background with clear workstation layout

# Color palette
const WALL_COLOR := Color(0.95, 0.91, 0.84)
const WALL_ACCENT := Color(0.85, 0.78, 0.65)
const COUNTER_TOP := Color(0.35, 0.28, 0.22)
const COUNTER_FRONT := Color(0.50, 0.40, 0.32)
const WORKSTATION_BG := Color(0.28, 0.24, 0.20)
const SHELF_COLOR := Color(0.42, 0.32, 0.25)
const WINDOW_FRAME := Color(0.30, 0.24, 0.18)
const WINDOW_GLASS := Color(0.75, 0.88, 0.95, 0.5)
const METAL_DARK := Color(0.25, 0.25, 0.28)
const METAL_LIGHT := Color(0.55, 0.55, 0.58)
const CUP_WHITE := Color(0.96, 0.96, 0.94)
const WOOD_LIGHT := Color(0.72, 0.58, 0.42)

# Sky colors for different times of day
const SKY_COLORS := {
	"morning": {
		"top": Color(0.55, 0.72, 0.90),      # Soft blue
		"bottom": Color(0.95, 0.85, 0.75)    # Peachy horizon
	},
	"afternoon": {
		"top": Color(0.45, 0.65, 0.92),      # Bright blue
		"bottom": Color(0.70, 0.82, 0.95)    # Light blue
	},
	"evening": {
		"top": Color(0.25, 0.30, 0.55),      # Deep purple-blue
		"bottom": Color(0.95, 0.60, 0.40)    # Sunset orange
	},
	"night": {
		"top": Color(0.08, 0.10, 0.18),      # Dark night sky
		"bottom": Color(0.15, 0.18, 0.28)    # Slightly lighter horizon
	}
}

# Cached window rect for weather particles
var _window_rect: Rect2 = Rect2()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Connect to time changes for redraw
	if TimeManager:
		TimeManager.time_of_day_changed.connect(_on_time_changed)


func _process(_delta: float) -> void:
	# Redraw for time-based sky changes
	queue_redraw()


func _on_time_changed(_period: String) -> void:
	queue_redraw()


func get_window_rect() -> Rect2:
	return _window_rect


func _draw() -> void:
	var w := size.x
	var h := size.y

	# Define zones - workstation is bottom 30%
	var workstation_height := h * 0.30
	var workstation_y := h - workstation_height

	# Shop area is now handled by BackgroundImage (AI-generated backgrounds)
	# We only draw the workstation

	# === WORKSTATION (bottom portion - where you make drinks) ===
	_draw_workstation(w, h, workstation_y, workstation_height)


func _draw_shop_area(w: float, shop_height: float) -> void:
	# NEW LAYOUT: Wall is shorter, more floor space for seating
	# Wall takes up ~35% of shop area, floor/seating takes ~65%
	var wall_height := shop_height * 0.35
	var floor_y := wall_height

	# === BACK WALL (upper portion) ===
	draw_rect(Rect2(0, 0, w, wall_height), WALL_COLOR)

	# Decorative crown molding at top
	draw_rect(Rect2(0, 0, w, 4), WALL_COLOR.darkened(0.08))

	# Chair rail / wainscoting line on wall
	var chair_rail_y := wall_height * 0.7
	draw_rect(Rect2(0, chair_rail_y, w, 4), SHELF_COLOR)

	# === FLOOR AREA (lower portion - wood floor) ===
	var floor_color := Color(0.62, 0.48, 0.35)  # Warm wood floor
	draw_rect(Rect2(0, floor_y, w, shop_height - floor_y), floor_color)

	# Floor boards (subtle lines)
	var board_width := w / 12.0
	for i in range(13):
		var board_x := i * board_width
		draw_line(Vector2(board_x, floor_y), Vector2(board_x, shop_height), floor_color.darkened(0.1), 1)

	# === WINDOW (left side, cozy size) ===
	var window_pos := Vector2(w * 0.03, wall_height * 0.12)
	var window_size := Vector2(w * 0.18, wall_height * 0.78)
	_window_rect = Rect2(window_pos, window_size)
	_draw_window(window_pos, window_size)

	# Cozy curtains on window
	_draw_curtains(window_pos, window_size)

	# === WALL DECORATIONS ===
	var time_ms := Time.get_ticks_msec()

	# Framed coffee art (left of center)
	_draw_framed_art(Vector2(w * 0.26, wall_height * 0.15), Vector2(w * 0.08, wall_height * 0.45))

	# Clock (center)
	_draw_wall_clock(Vector2(w * 0.42, wall_height * 0.35), wall_height * 0.22, time_ms)

	# Another framed picture (right of center)
	_draw_framed_art(Vector2(w * 0.52, wall_height * 0.18), Vector2(w * 0.07, wall_height * 0.38))

	# Decorative shelf with plants (right side)
	_draw_wall_shelf_with_plants(Vector2(w * 0.66, wall_height * 0.25), Vector2(w * 0.14, wall_height * 0.20))

	# Cozy string lights across the top
	_draw_string_lights(w, wall_height * 0.08, time_ms)

	# Bookshelf/cabinet on far right
	_draw_cozy_cabinet(Vector2(w * 0.82, wall_height * 0.10), Vector2(w * 0.15, wall_height * 0.85))

	# === HANGING PENDANT LIGHTS ===
	_draw_hanging_light(Vector2(w * 0.15, 0), wall_height * 0.15, time_ms, 0)
	_draw_hanging_light(Vector2(w * 0.45, 0), wall_height * 0.12, time_ms, 1)
	_draw_hanging_light(Vector2(w * 0.75, 0), wall_height * 0.15, time_ms, 2)

	# === COUNTER (at the bottom of shop area) ===
	var counter_height := 12.0
	draw_rect(Rect2(0, shop_height - counter_height, w, counter_height), COUNTER_TOP)
	draw_rect(Rect2(0, shop_height - counter_height, w, 3), COUNTER_TOP.lightened(0.15))  # Highlight

	# Small menu sign on counter (right side)
	_draw_counter_menu_sign(Vector2(w * 0.78, shop_height - counter_height - 45), 70, 40)

	# Tip jar on counter
	_draw_tip_jar(Vector2(w * 0.68, shop_height - counter_height - 28), 20)

	# Small plant on counter
	_draw_counter_plant(Vector2(w * 0.58, shop_height - counter_height - 35), 0.8)


func _draw_workstation(w: float, h: float, y: float, height: float) -> void:
	# Workstation background
	draw_rect(Rect2(0, y, w, height), WORKSTATION_BG)

	# Counter surface
	draw_rect(Rect2(0, y, w, 6), COUNTER_TOP.lightened(0.1))

	# Equipment areas with clear visual boundaries
	var equip_y := y + 15
	var equip_height := height - 25
	var padding := w * 0.01

	# Calculate equipment widths
	var total_width := w - padding * 2
	var cups_w := total_width * 0.10
	var espresso_w := total_width * 0.15
	var milk_w := total_width * 0.12
	var ingredients_w := total_width * 0.32
	var serve_w := total_width * 0.15
	var trash_w := total_width * 0.10

	var x := padding

	# 1. CUPS
	_draw_cup_station(Vector2(x, equip_y), Vector2(cups_w, equip_height))
	x += cups_w + padding

	# 2. ESPRESSO MACHINE
	_draw_espresso_machine(Vector2(x, equip_y), Vector2(espresso_w, equip_height))
	x += espresso_w + padding

	# 3. MILK STEAMER
	_draw_milk_steamer(Vector2(x, equip_y), Vector2(milk_w, equip_height))
	x += milk_w + padding

	# 4. INGREDIENTS ROW
	_draw_ingredients(Vector2(x, equip_y), Vector2(ingredients_w, equip_height))
	x += ingredients_w + padding

	# 5. SERVE AREA
	_draw_serve_station(Vector2(x, equip_y), Vector2(serve_w, equip_height))
	x += serve_w + padding

	# 6. TRASH
	_draw_trash_station(Vector2(x, equip_y), Vector2(trash_w, equip_height))


func _draw_cup_station(pos: Vector2, area_size: Vector2) -> void:
	# Background panel
	_draw_station_panel(pos, area_size, "CUPS")

	# Stack of cups
	var cup_w := 22.0
	var cup_h := 28.0
	var stack_x := pos.x + (area_size.x - cup_w) / 2
	var base_y := pos.y + area_size.y - 35

	for i in range(3):
		var offset := i * 4
		draw_rect(Rect2(stack_x - offset/2, base_y - i * 8, cup_w + offset, cup_h), CUP_WHITE)
		draw_rect(Rect2(stack_x - offset/2 - 2, base_y - i * 8, cup_w + offset + 4, 4), CUP_WHITE.darkened(0.05))


func _draw_espresso_machine(pos: Vector2, area_size: Vector2) -> void:
	# Background panel
	_draw_station_panel(pos, area_size, "ESPRESSO")

	var machine_margin := 8.0
	var machine_x := pos.x + machine_margin
	var machine_w := area_size.x - machine_margin * 2
	var machine_h := area_size.y - 35
	var machine_y := pos.y + 15

	# Machine body
	draw_rect(Rect2(machine_x, machine_y, machine_w, machine_h), METAL_DARK)

	# Top section (lighter)
	draw_rect(Rect2(machine_x, machine_y, machine_w, machine_h * 0.25), METAL_DARK.lightened(0.15))

	# Group head (where coffee comes out)
	var group_y := machine_y + machine_h * 0.4
	draw_rect(Rect2(machine_x + machine_w * 0.2, group_y, machine_w * 0.6, machine_h * 0.35), Color(0.15, 0.15, 0.15))

	# Portafilter handles
	draw_circle(Vector2(machine_x + machine_w * 0.35, group_y + machine_h * 0.15), 6, WOOD_LIGHT)
	draw_circle(Vector2(machine_x + machine_w * 0.65, group_y + machine_h * 0.15), 6, WOOD_LIGHT)

	# Steam wand
	draw_line(
		Vector2(machine_x + machine_w - 8, machine_y + machine_h * 0.3),
		Vector2(machine_x + machine_w + 5, machine_y + machine_h * 0.6),
		METAL_LIGHT, 4
	)

	# Indicator lights
	draw_circle(Vector2(machine_x + 12, machine_y + 12), 4, Color(0.2, 0.8, 0.3))
	draw_circle(Vector2(machine_x + 26, machine_y + 12), 4, Color(0.9, 0.6, 0.2))


func _draw_milk_steamer(pos: Vector2, area_size: Vector2) -> void:
	# Background panel
	_draw_station_panel(pos, area_size, "MILK")

	var center_x := pos.x + area_size.x / 2
	var pitcher_w := 35.0
	var pitcher_h := 45.0
	var pitcher_y := pos.y + area_size.y - 40

	# Milk pitcher
	var pitcher_color := Color(0.78, 0.78, 0.80)
	draw_rect(Rect2(center_x - pitcher_w/2, pitcher_y, pitcher_w, pitcher_h), pitcher_color)

	# Pitcher spout
	var spout := PackedVector2Array([
		Vector2(center_x + pitcher_w/2, pitcher_y + 5),
		Vector2(center_x + pitcher_w/2 + 10, pitcher_y),
		Vector2(center_x + pitcher_w/2, pitcher_y + 15)
	])
	draw_polygon(spout, [pitcher_color])

	# Handle
	draw_arc(Vector2(center_x - pitcher_w/2, pitcher_y + pitcher_h * 0.4), 10, PI * 0.5, PI * 1.5, 8, pitcher_color.darkened(0.1), 4)

	# Milk inside
	draw_rect(Rect2(center_x - pitcher_w/2 + 3, pitcher_y + 10, pitcher_w - 6, pitcher_h - 15), Color(0.98, 0.97, 0.95))


func _draw_ingredients(pos: Vector2, area_size: Vector2) -> void:
	var ingredients: Array[Dictionary] = [
		{"id": "water", "color": Color(0.65, 0.82, 0.95), "label": "WATER"},
		{"id": "chocolate", "color": Color(0.40, 0.28, 0.18), "label": "CHOC"},
		{"id": "ice", "color": Color(0.88, 0.95, 1.0), "label": "ICE"},
		{"id": "chai", "color": Color(0.72, 0.55, 0.38), "label": "CHAI"},
		{"id": "green_tea", "color": Color(0.60, 0.75, 0.50), "label": "TEA"},
	]

	var bottle_count := ingredients.size()
	var bottle_w := area_size.x / bottle_count
	var font := ThemeDB.fallback_font

	for i in range(bottle_count):
		var ing: Dictionary = ingredients[i]
		var bottle_x := pos.x + i * bottle_w

		# Individual station panel
		_draw_station_panel(Vector2(bottle_x, pos.y), Vector2(bottle_w - 2, area_size.y), ing.label)

		# Bottle
		var b_margin := 10.0
		var b_w := bottle_w - b_margin * 2 - 2
		var b_h := area_size.y - 45
		var b_x := bottle_x + b_margin
		var b_y := pos.y + 18

		# Bottle body
		draw_rect(Rect2(b_x, b_y, b_w, b_h), ing.color)

		# Bottle neck
		var neck_w := b_w * 0.5
		draw_rect(Rect2(b_x + (b_w - neck_w)/2, b_y - 8, neck_w, 10), ing.color.darkened(0.1))

		# Cap
		draw_rect(Rect2(b_x + (b_w - neck_w)/2 - 2, b_y - 14, neck_w + 4, 8), METAL_DARK)


func _draw_serve_station(pos: Vector2, area_size: Vector2) -> void:
	# Background panel - green tint for "go"
	var panel_rect := Rect2(pos.x + 2, pos.y + 2, area_size.x - 4, area_size.y - 4)
	draw_rect(panel_rect, Color(0.18, 0.25, 0.18))
	draw_rect(panel_rect, Color(0.3, 0.5, 0.3), false, 2)

	# Label
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(pos.x + 8, pos.y + area_size.y - 8), "SERVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.9, 0.5))

	# Service bell
	var bell_x := pos.x + area_size.x / 2
	var bell_y := pos.y + area_size.y * 0.5

	# Bell base
	draw_rect(Rect2(bell_x - 25, bell_y + 15, 50, 8), Color(0.75, 0.68, 0.45))

	# Bell dome
	var bell_color := Color(0.90, 0.82, 0.50)
	draw_circle(Vector2(bell_x, bell_y), 22, bell_color)

	# Bell button
	draw_circle(Vector2(bell_x, bell_y - 18), 6, bell_color.darkened(0.15))

	# Highlight
	draw_arc(Vector2(bell_x - 5, bell_y - 5), 12, PI * 1.1, PI * 1.6, 6, Color(1, 1, 0.9, 0.4), 3)


func _draw_trash_station(pos: Vector2, area_size: Vector2) -> void:
	# Background panel - red tint for "discard"
	var panel_rect := Rect2(pos.x + 2, pos.y + 2, area_size.x - 4, area_size.y - 4)
	draw_rect(panel_rect, Color(0.25, 0.18, 0.18))
	draw_rect(panel_rect, Color(0.5, 0.3, 0.3), false, 2)

	# Label
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(pos.x + 6, pos.y + area_size.y - 8), "TRASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.5, 0.5))

	# Trash bin
	var bin_x := pos.x + area_size.x / 2
	var bin_y := pos.y + 20
	var bin_w := 35.0
	var bin_h := area_size.y - 50

	# Bin body (trapezoid)
	var bin_points := PackedVector2Array([
		Vector2(bin_x - bin_w * 0.35, bin_y),
		Vector2(bin_x - bin_w * 0.45, bin_y + bin_h),
		Vector2(bin_x + bin_w * 0.45, bin_y + bin_h),
		Vector2(bin_x + bin_w * 0.35, bin_y)
	])
	draw_polygon(bin_points, [Color(0.50, 0.50, 0.52)])

	# Bin rim
	draw_rect(Rect2(bin_x - bin_w * 0.4, bin_y - 5, bin_w * 0.8, 7), Color(0.58, 0.58, 0.60))

	# X mark
	var x_center := Vector2(bin_x, bin_y + bin_h * 0.45)
	draw_line(x_center + Vector2(-10, -10), x_center + Vector2(10, 10), Color(0.8, 0.3, 0.3), 3)
	draw_line(x_center + Vector2(10, -10), x_center + Vector2(-10, 10), Color(0.8, 0.3, 0.3), 3)


func _draw_station_panel(pos: Vector2, area_size: Vector2, label: String) -> void:
	# Panel background
	var panel_rect := Rect2(pos.x + 2, pos.y + 2, area_size.x - 4, area_size.y - 4)
	draw_rect(panel_rect, Color(0.22, 0.20, 0.18))
	draw_rect(panel_rect, Color(0.35, 0.32, 0.28), false, 2)

	# Label at bottom
	var font := ThemeDB.fallback_font
	var label_y := pos.y + area_size.y - 8
	draw_string(font, Vector2(pos.x + 6, label_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.65, 0.55))


func _draw_window(pos: Vector2, window_size: Vector2) -> void:
	# Frame
	draw_rect(Rect2(pos, window_size), WINDOW_FRAME)

	# Get current time-based sky colors
	var period := "afternoon"
	if TimeManager:
		period = TimeManager.get_period_name()
	var sky_palette: Dictionary = SKY_COLORS.get(period, SKY_COLORS["afternoon"])

	# Glass area dimensions
	var inner := 6.0
	var glass_rect := Rect2(pos.x + inner, pos.y + inner, window_size.x - inner * 2, window_size.y - inner * 2)

	# Draw sky gradient
	_draw_sky_gradient(glass_rect, sky_palette.top, sky_palette.bottom)

	# Draw stars at night
	if period == "night":
		_draw_stars(glass_rect)

	# Note: Clouds are now drawn by WindowClouds node (inside clipping viewport)

	# Window tint
	draw_rect(glass_rect, WINDOW_GLASS)

	# Cross frame
	draw_rect(Rect2(pos.x + window_size.x / 2 - 3, pos.y, 6, window_size.y), WINDOW_FRAME)
	draw_rect(Rect2(pos.x, pos.y + window_size.y / 2 - 3, window_size.x, 6), WINDOW_FRAME)

	# Sill
	draw_rect(Rect2(pos.x - 4, pos.y + window_size.y, window_size.x + 8, 8), SHELF_COLOR)


func _draw_sky_gradient(rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	# Draw vertical gradient using multiple horizontal lines
	var steps := int(rect.size.y)
	for i in range(steps):
		var t := float(i) / float(steps)
		var color := top_color.lerp(bottom_color, t)
		var y := rect.position.y + i
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), color)


func _draw_stars(rect: Rect2) -> void:
	# Draw twinkling stars at night
	var star_positions := [
		Vector2(0.15, 0.2), Vector2(0.35, 0.15), Vector2(0.55, 0.25),
		Vector2(0.75, 0.18), Vector2(0.25, 0.35), Vector2(0.65, 0.38),
		Vector2(0.45, 0.12), Vector2(0.85, 0.30)
	]

	for i in range(star_positions.size()):
		var star_pos: Vector2 = star_positions[i]
		var x: float = rect.position.x + rect.size.x * star_pos.x
		var y: float = rect.position.y + rect.size.y * star_pos.y
		# Twinkle effect based on time
		var twinkle: float = sin(Time.get_ticks_msec() * 0.003 + star_pos.x * 10.0) * 0.3 + 0.7
		var star_color := Color(1.0, 1.0, 0.9, twinkle)
		draw_circle(Vector2(x, y), 1.5, star_color)


# === NEW COZY DECORATION FUNCTIONS ===

func _draw_curtains(window_pos: Vector2, window_size: Vector2) -> void:
	var curtain_color := Color(0.85, 0.78, 0.72)  # Warm linen color
	var curtain_width := window_size.x * 0.18
	var curtain_height := window_size.y + 10

	# Left curtain
	var left_x := window_pos.x - 5
	draw_rect(Rect2(left_x, window_pos.y - 5, curtain_width, curtain_height), curtain_color)
	# Curtain folds
	for i in range(3):
		var fold_x := left_x + i * (curtain_width / 3)
		draw_line(Vector2(fold_x, window_pos.y), Vector2(fold_x, window_pos.y + curtain_height - 10), curtain_color.darkened(0.08), 1)

	# Right curtain
	var right_x := window_pos.x + window_size.x - curtain_width + 5
	draw_rect(Rect2(right_x, window_pos.y - 5, curtain_width, curtain_height), curtain_color)
	for i in range(3):
		var fold_x := right_x + i * (curtain_width / 3)
		draw_line(Vector2(fold_x, window_pos.y), Vector2(fold_x, window_pos.y + curtain_height - 10), curtain_color.darkened(0.08), 1)

	# Curtain rod
	draw_rect(Rect2(window_pos.x - 10, window_pos.y - 10, window_size.x + 20, 5), SHELF_COLOR)
	# Rod ends
	draw_circle(Vector2(window_pos.x - 10, window_pos.y - 7), 5, SHELF_COLOR.darkened(0.1))
	draw_circle(Vector2(window_pos.x + window_size.x + 10, window_pos.y - 7), 5, SHELF_COLOR.darkened(0.1))


func _draw_framed_art(pos: Vector2, frame_size: Vector2) -> void:
	var frame_color := SHELF_COLOR
	var frame_width := 4.0

	# Frame shadow
	draw_rect(Rect2(pos.x + 2, pos.y + 2, frame_size.x, frame_size.y), Color(0, 0, 0, 0.15))

	# Frame
	draw_rect(Rect2(pos, frame_size), frame_color)

	# Inner mat
	var mat_margin := frame_width + 3
	draw_rect(Rect2(pos.x + mat_margin, pos.y + mat_margin, frame_size.x - mat_margin * 2, frame_size.y - mat_margin * 2), Color(0.95, 0.93, 0.88))

	# Art content (coffee-themed abstract)
	var art_margin := mat_margin + 4
	var art_rect := Rect2(pos.x + art_margin, pos.y + art_margin, frame_size.x - art_margin * 2, frame_size.y - art_margin * 2)
	draw_rect(art_rect, Color(0.92, 0.88, 0.82))

	# Simple coffee cup silhouette
	var cup_cx := art_rect.position.x + art_rect.size.x / 2
	var cup_cy := art_rect.position.y + art_rect.size.y * 0.6
	var cup_w := art_rect.size.x * 0.4
	var cup_h := art_rect.size.y * 0.35
	draw_rect(Rect2(cup_cx - cup_w/2, cup_cy - cup_h/2, cup_w, cup_h), Color(0.45, 0.32, 0.25))
	# Cup handle
	draw_arc(Vector2(cup_cx + cup_w/2, cup_cy), cup_h * 0.25, -PI/2, PI/2, 6, Color(0.45, 0.32, 0.25), 3)
	# Steam swirl
	draw_arc(Vector2(cup_cx, cup_cy - cup_h/2 - 8), 6, PI * 0.3, PI * 0.8, 5, Color(0.65, 0.55, 0.48), 2)


func _draw_wall_clock(center: Vector2, radius: float, time_ms: int) -> void:
	# Clock face
	draw_circle(center, radius, Color(0.95, 0.93, 0.88))
	draw_arc(center, radius, 0, TAU, 24, SHELF_COLOR, 3)

	# Hour markers
	for i in range(12):
		var angle := i * (TAU / 12) - PI/2
		var inner_r := radius * 0.8
		var outer_r := radius * 0.9
		var start := center + Vector2(cos(angle) * inner_r, sin(angle) * inner_r)
		var end := center + Vector2(cos(angle) * outer_r, sin(angle) * outer_r)
		draw_line(start, end, SHELF_COLOR, 2)

	# Clock hands (animated based on game time if available, else real time)
	var hour_angle := float(time_ms % 43200000) / 43200000.0 * TAU - PI/2
	var minute_angle := float(time_ms % 3600000) / 3600000.0 * TAU - PI/2

	# Hour hand
	var hour_end := center + Vector2(cos(hour_angle) * radius * 0.5, sin(hour_angle) * radius * 0.5)
	draw_line(center, hour_end, Color(0.2, 0.18, 0.15), 3)

	# Minute hand
	var minute_end := center + Vector2(cos(minute_angle) * radius * 0.7, sin(minute_angle) * radius * 0.7)
	draw_line(center, minute_end, Color(0.2, 0.18, 0.15), 2)

	# Center dot
	draw_circle(center, 3, SHELF_COLOR)


func _draw_wall_shelf_with_plants(pos: Vector2, shelf_size: Vector2) -> void:
	# Shelf bracket
	draw_rect(Rect2(pos.x, pos.y + shelf_size.y - 5, shelf_size.x, 5), SHELF_COLOR)

	# Small plants on shelf
	var plant_x := pos.x + shelf_size.x * 0.2
	_draw_small_potted_plant(Vector2(plant_x, pos.y + shelf_size.y - 5), 0.6)

	plant_x = pos.x + shelf_size.x * 0.6
	_draw_small_potted_plant(Vector2(plant_x, pos.y + shelf_size.y - 5), 0.5)

	# Small jar
	var jar_x := pos.x + shelf_size.x * 0.85
	var jar_h := 18.0
	draw_rect(Rect2(jar_x - 8, pos.y + shelf_size.y - 5 - jar_h, 16, jar_h), Color(0.75, 0.65, 0.52))
	draw_rect(Rect2(jar_x - 9, pos.y + shelf_size.y - 5 - jar_h - 3, 18, 4), COUNTER_TOP)


func _draw_small_potted_plant(base_pos: Vector2, scale: float) -> void:
	var pot_w := 20.0 * scale
	var pot_h := 16.0 * scale

	# Pot
	var pot_color := Color(0.72, 0.48, 0.38)
	draw_rect(Rect2(base_pos.x - pot_w/2, base_pos.y - pot_h, pot_w, pot_h), pot_color)
	draw_rect(Rect2(base_pos.x - pot_w/2 - 2, base_pos.y - pot_h, pot_w + 4, 4), pot_color.darkened(0.1))

	# Plant
	var leaf_color := Color(0.38, 0.58, 0.38)
	var leaf_y := base_pos.y - pot_h
	draw_circle(Vector2(base_pos.x, leaf_y - 12 * scale), 8 * scale, leaf_color)
	draw_circle(Vector2(base_pos.x - 6 * scale, leaf_y - 6 * scale), 6 * scale, leaf_color.lightened(0.1))
	draw_circle(Vector2(base_pos.x + 6 * scale, leaf_y - 8 * scale), 7 * scale, leaf_color.darkened(0.05))


func _draw_string_lights(width: float, y: float, time_ms: int) -> void:
	# String (slight curve)
	var string_color := Color(0.15, 0.12, 0.10)
	var num_lights := 12
	var spacing := width / (num_lights + 1)

	# Draw the string wire
	for i in range(num_lights):
		var x1 := spacing * (i + 1)
		var x2 := spacing * (i + 2)
		var sag1 := sin(float(i) / num_lights * PI) * 8
		var sag2 := sin(float(i + 1) / num_lights * PI) * 8
		draw_line(Vector2(x1, y + sag1), Vector2(x2, y + sag2), string_color, 1)

	# Draw light bulbs
	for i in range(num_lights):
		var x := spacing * (i + 1)
		var sag := sin(float(i) / num_lights * PI) * 8

		# Twinkle effect
		var twinkle := sin(float(time_ms) * 0.003 + i * 0.7) * 0.15 + 0.85
		var bulb_color := Color(1.0, 0.92, 0.7, twinkle)

		# Bulb
		draw_circle(Vector2(x, y + sag + 6), 4, bulb_color)
		# Glow
		draw_circle(Vector2(x, y + sag + 6), 8, Color(1.0, 0.95, 0.8, twinkle * 0.2))


func _draw_cozy_cabinet(pos: Vector2, cabinet_size: Vector2) -> void:
	var cabinet_color := SHELF_COLOR

	# Cabinet back
	draw_rect(Rect2(pos, cabinet_size), cabinet_color.darkened(0.15))

	# Shelves (3 levels)
	var num_shelves := 3
	var shelf_spacing := cabinet_size.y / (num_shelves + 1)

	for i in range(num_shelves):
		var shelf_y := pos.y + shelf_spacing * (i + 1)
		draw_rect(Rect2(pos.x, shelf_y, cabinet_size.x, 4), cabinet_color)

		# Items on each shelf
		match i:
			0:  # Top shelf - coffee bags
				var bag_w := cabinet_size.x * 0.35
				_draw_coffee_bag(Vector2(pos.x + 8, shelf_y - 28), bag_w, Color(0.72, 0.62, 0.48))
				_draw_coffee_bag(Vector2(pos.x + bag_w + 12, shelf_y - 25), bag_w * 0.9, Color(0.58, 0.45, 0.35))
			1:  # Middle shelf - jars
				for j in range(2):
					var jar_x := pos.x + 10 + j * (cabinet_size.x * 0.45)
					var jar_h := 22.0
					var jar_color := Color(0.82, 0.72, 0.58) if j == 0 else Color(0.68, 0.55, 0.42)
					draw_rect(Rect2(jar_x, shelf_y - jar_h, 20, jar_h), jar_color)
					draw_rect(Rect2(jar_x - 1, shelf_y - jar_h - 3, 22, 4), COUNTER_TOP)
			2:  # Bottom shelf - mugs
				for j in range(3):
					var mug_x := pos.x + 8 + j * (cabinet_size.x * 0.32)
					var mug_colors: Array[Color] = [CUP_WHITE, Color(0.78, 0.65, 0.55), Color(0.65, 0.72, 0.78)]
					draw_rect(Rect2(mug_x, shelf_y - 16, 14, 16), mug_colors[j])
					draw_arc(Vector2(mug_x + 14, shelf_y - 8), 5, -PI/2, PI/2, 5, mug_colors[j].darkened(0.1), 2)

	# Cabinet frame
	draw_rect(Rect2(pos, cabinet_size), cabinet_color, false, 3)


func _draw_coffee_bag(pos: Vector2, width: float, color: Color) -> void:
	var height := width * 1.1
	var bag_pts := PackedVector2Array([
		Vector2(pos.x, pos.y + height),
		Vector2(pos.x, pos.y + 8),
		Vector2(pos.x + 4, pos.y),
		Vector2(pos.x + width - 4, pos.y),
		Vector2(pos.x + width, pos.y + 8),
		Vector2(pos.x + width, pos.y + height)
	])
	draw_polygon(bag_pts, [color])
	# Fold line
	draw_line(Vector2(pos.x + 2, pos.y + 6), Vector2(pos.x + width - 2, pos.y + 6), color.darkened(0.15), 1)


func _draw_counter_menu_sign(pos: Vector2, width: float, height: float) -> void:
	# Small tent-style menu card
	var card_color := Color(0.95, 0.92, 0.85)

	# Card body (angled like a tent card)
	draw_rect(Rect2(pos.x, pos.y, width, height), card_color)
	draw_rect(Rect2(pos.x, pos.y, width, height), SHELF_COLOR, false, 2)

	# Text
	var font := ThemeDB.fallback_font
	var text_color := Color(0.25, 0.20, 0.18)
	draw_string(font, pos + Vector2(8, 14), "MENU", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_color)
	draw_string(font, pos + Vector2(5, 26), "Espresso $3", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, text_color)
	draw_string(font, pos + Vector2(5, 35), "Latte $5", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, text_color)


func _draw_tip_jar(pos: Vector2, height: float) -> void:
	var jar_w := height * 0.7
	var jar_color := Color(0.85, 0.90, 0.88, 0.8)

	# Glass jar
	draw_rect(Rect2(pos.x - jar_w/2, pos.y - height, jar_w, height), jar_color)
	draw_rect(Rect2(pos.x - jar_w/2, pos.y - height, jar_w, height), Color(0.7, 0.75, 0.72), false, 1)

	# Lid
	draw_rect(Rect2(pos.x - jar_w/2 - 2, pos.y - height - 4, jar_w + 4, 5), METAL_LIGHT)

	# Some coins/bills inside (abstract)
	draw_rect(Rect2(pos.x - 4, pos.y - height * 0.4, 8, 3), Color(0.3, 0.6, 0.3))  # Dollar
	draw_circle(Vector2(pos.x - 3, pos.y - height * 0.25), 3, Color(0.78, 0.55, 0.25))  # Coin
	draw_circle(Vector2(pos.x + 2, pos.y - height * 0.3), 2, Color(0.72, 0.72, 0.75))  # Coin


func _draw_counter_plant(pos: Vector2, scale: float) -> void:
	_draw_small_potted_plant(pos, scale)


func _draw_hanging_light(pos: Vector2, cord_length: float, time_ms: int = 0, light_index: int = 0) -> void:
	# Cord
	draw_line(pos, Vector2(pos.x, pos.y + cord_length), Color(0.2, 0.18, 0.15), 2)

	# Lamp shade
	var lamp_y := pos.y + cord_length
	var shade_pts := PackedVector2Array([
		Vector2(pos.x - 12, lamp_y),
		Vector2(pos.x - 18, lamp_y + 20),
		Vector2(pos.x + 18, lamp_y + 20),
		Vector2(pos.x + 12, lamp_y)
	])
	draw_polygon(shade_pts, [Color(0.22, 0.20, 0.18)])

	# Subtle light flickering based on time
	var flicker_phase := float(time_ms) * 0.002 + light_index * 2.1
	var flicker := sin(flicker_phase) * 0.03 + sin(flicker_phase * 2.7) * 0.02
	var glow_alpha := 0.2 + flicker
	var glow_radius := 25.0 + flicker * 30.0

	# Warm glow with variation
	var glow_color := Color(1.0, 0.92, 0.75, glow_alpha)

	# Inner bright glow
	draw_circle(Vector2(pos.x, lamp_y + 22), glow_radius * 0.5, glow_color.lightened(0.2))

	# Outer soft glow
	draw_circle(Vector2(pos.x, lamp_y + 22), glow_radius, glow_color)

	# Brightest center point (the bulb)
	draw_circle(Vector2(pos.x, lamp_y + 15), 4, Color(1.0, 0.98, 0.9, 0.6 + flicker))
