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
const SKY_COLOR := Color(0.6, 0.78, 0.92)
const METAL_DARK := Color(0.25, 0.25, 0.28)
const METAL_LIGHT := Color(0.55, 0.55, 0.58)
const CUP_WHITE := Color(0.96, 0.96, 0.94)
const WOOD_LIGHT := Color(0.72, 0.58, 0.42)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	var w := size.x
	var h := size.y

	# Define zones
	var workstation_height := h * 0.30
	var workstation_y := h - workstation_height
	var shop_height := h - workstation_height

	# === SHOP AREA (top portion - where customer appears) ===
	_draw_shop_area(w, shop_height)

	# === WORKSTATION (bottom portion - where you make drinks) ===
	_draw_workstation(w, h, workstation_y, workstation_height)


func _draw_shop_area(w: float, shop_height: float) -> void:
	# Background wall
	draw_rect(Rect2(0, 0, w, shop_height), WALL_COLOR)

	# Decorative wainscoting on lower wall
	var wainscot_y := shop_height * 0.55
	draw_rect(Rect2(0, wainscot_y, w, shop_height - wainscot_y), WALL_ACCENT)
	draw_rect(Rect2(0, wainscot_y - 3, w, 6), COUNTER_TOP)

	# Window (left side)
	_draw_window(Vector2(w * 0.05, shop_height * 0.08), Vector2(w * 0.25, shop_height * 0.50))

	# Menu board (center)
	_draw_menu_board(Vector2(w * 0.38, shop_height * 0.05), Vector2(w * 0.24, shop_height * 0.35))

	# Decorative shelf (right side)
	_draw_deco_shelf(Vector2(w * 0.70, shop_height * 0.08), Vector2(w * 0.25, shop_height * 0.45))

	# Hanging lights
	_draw_hanging_light(Vector2(w * 0.20, 0), shop_height * 0.12)
	_draw_hanging_light(Vector2(w * 0.50, 0), shop_height * 0.10)
	_draw_hanging_light(Vector2(w * 0.80, 0), shop_height * 0.12)

	# Counter top edge (where customer stands)
	draw_rect(Rect2(0, shop_height - 8, w, 8), COUNTER_TOP)


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

	# Glass/sky
	var inner := 6.0
	draw_rect(Rect2(pos.x + inner, pos.y + inner, window_size.x - inner * 2, window_size.y - inner * 2), SKY_COLOR)

	# Clouds
	var cloud_y := pos.y + window_size.y * 0.35
	draw_circle(Vector2(pos.x + window_size.x * 0.3, cloud_y), 12, Color.WHITE)
	draw_circle(Vector2(pos.x + window_size.x * 0.42, cloud_y - 4), 15, Color.WHITE)
	draw_circle(Vector2(pos.x + window_size.x * 0.55, cloud_y), 11, Color.WHITE)

	# Window tint
	draw_rect(Rect2(pos.x + inner, pos.y + inner, window_size.x - inner * 2, window_size.y - inner * 2), WINDOW_GLASS)

	# Cross frame
	draw_rect(Rect2(pos.x + window_size.x / 2 - 3, pos.y, 6, window_size.y), WINDOW_FRAME)
	draw_rect(Rect2(pos.x, pos.y + window_size.y / 2 - 3, window_size.x, 6), WINDOW_FRAME)

	# Sill
	draw_rect(Rect2(pos.x - 4, pos.y + window_size.y, window_size.x + 8, 8), SHELF_COLOR)


func _draw_menu_board(pos: Vector2, board_size: Vector2) -> void:
	# Board
	draw_rect(Rect2(pos, board_size), Color(0.12, 0.10, 0.08))
	draw_rect(Rect2(pos, board_size), SHELF_COLOR, false, 4)

	var font := ThemeDB.fallback_font
	var chalk := Color(0.95, 0.95, 0.90)

	draw_string(font, pos + Vector2(board_size.x * 0.32, 24), "MENU", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, chalk)
	draw_string(font, pos + Vector2(15, 48), "Espresso........$3", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, chalk)
	draw_string(font, pos + Vector2(15, 65), "Americano......$4", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, chalk)
	draw_string(font, pos + Vector2(15, 82), "Latte.............$5", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, chalk)
	draw_string(font, pos + Vector2(15, 99), "Mocha............$6", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, chalk)


func _draw_deco_shelf(pos: Vector2, area_size: Vector2) -> void:
	var shelf_h := 8.0
	var num_shelves := 3
	var spacing := area_size.y / num_shelves

	for i in range(num_shelves):
		var shelf_y := pos.y + spacing * (i + 1) - shelf_h
		draw_rect(Rect2(pos.x, shelf_y, area_size.x, shelf_h), SHELF_COLOR)

		# Items on shelf
		match i:
			0:  # Top - jars
				for j in range(3):
					var jar_x := pos.x + 15 + j * (area_size.x / 3.5)
					var jar_colors: Array[Color] = [Color(0.6, 0.45, 0.35), Color(0.45, 0.35, 0.28), Color(0.7, 0.55, 0.38)]
					draw_rect(Rect2(jar_x, shelf_y - 28, 22, 28), jar_colors[j])
					draw_rect(Rect2(jar_x - 2, shelf_y - 32, 26, 6), COUNTER_TOP)
			1:  # Middle - bags
				for j in range(2):
					var bag_x := pos.x + 20 + j * (area_size.x / 2.5)
					var bag_color := Color(0.78, 0.70, 0.55) if j == 0 else Color(0.65, 0.52, 0.40)
					var bag_pts := PackedVector2Array([
						Vector2(bag_x, shelf_y),
						Vector2(bag_x, shelf_y - 32),
						Vector2(bag_x + 12, shelf_y - 38),
						Vector2(bag_x + 24, shelf_y - 38),
						Vector2(bag_x + 36, shelf_y - 32),
						Vector2(bag_x + 36, shelf_y)
					])
					draw_polygon(bag_pts, [bag_color])
			2:  # Bottom - mugs
				for j in range(4):
					var mug_x := pos.x + 12 + j * (area_size.x / 4.5)
					var mug_colors: Array[Color] = [CUP_WHITE, Color(0.85, 0.65, 0.55), Color(0.65, 0.75, 0.85), CUP_WHITE]
					draw_rect(Rect2(mug_x, shelf_y - 20, 16, 20), mug_colors[j])
					draw_arc(Vector2(mug_x + 16, shelf_y - 10), 6, -PI/2, PI/2, 6, mug_colors[j].darkened(0.1), 2)


func _draw_hanging_light(pos: Vector2, cord_length: float) -> void:
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

	# Glow
	draw_circle(Vector2(pos.x, lamp_y + 22), 25, Color(1.0, 0.92, 0.75, 0.2))
