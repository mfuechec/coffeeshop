extends Control
## Interactive coffee-making station - aligned with new workstation layout

signal drink_made(drink_name: String)

# Equipment states
var has_cup: bool = false
var current_ingredients: Array[String] = []

# Clickable equipment areas
var equipment_areas: Dictionary = {}
var hover_area: String = ""

# Workstation layout constants (must match shop_background.gd)
const WORKSTATION_START := 0.70  # Workstation starts at 70% down
const EQUIP_TOP_OFFSET := 0.025  # Offset from workstation top
const EQUIP_HEIGHT := 0.23       # Height of equipment area

# Equipment widths as fractions of total width (matching background)
const PADDING := 0.01
const CUPS_W := 0.098
const ESPRESSO_W := 0.147
const MILK_W := 0.118
const INGREDIENTS_W := 0.314     # Contains 5 bottles
const SERVE_W := 0.147
const TRASH_W := 0.098

# Recipes - what ingredients make what drink
const RECIPES := {
	"Espresso": ["espresso"],
	"Americano": ["espresso", "water"],
	"Latte": ["espresso", "milk"],
	"Cappuccino": ["espresso", "milk"],
	"Mocha": ["espresso", "chocolate", "milk"],
	"Hot Chocolate": ["chocolate", "milk"],
	"Chai Latte": ["chai", "milk"],
	"Green Tea": ["green_tea", "water"],
	"Iced Coffee": ["espresso", "ice"],
	"Flat White": ["espresso", "milk"],
}

# Visual colors
const COLOR_HOVER := Color(1, 1, 0.8, 0.3)
const COLOR_AVAILABLE := Color(0.8, 1, 0.8, 0.15)
const COLOR_UNAVAILABLE := Color(0.5, 0.5, 0.5, 0.1)

var status_label: Label
var cup_indicator: Control


func _ready() -> void:
	_create_equipment_areas()
	_create_status_display()
	_create_cup_indicator()
	mouse_filter = Control.MOUSE_FILTER_STOP


func _create_equipment_areas() -> void:
	# Calculate positions based on layout
	var equipment_list := _get_equipment_layout()

	for equip in equipment_list:
		var area := Panel.new()
		area.name = equip.id
		area.mouse_filter = Control.MOUSE_FILTER_STOP
		area.mouse_entered.connect(_on_area_mouse_entered.bind(equip.id))
		area.mouse_exited.connect(_on_area_mouse_exited.bind(equip.id))
		area.gui_input.connect(_on_area_gui_input.bind(equip.id))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		area.add_theme_stylebox_override("panel", style)

		add_child(area)
		equipment_areas[equip.id] = {"node": area, "rect": equip.rect, "label": equip.label}


func _get_equipment_layout() -> Array[Dictionary]:
	# Returns equipment with their relative rects (0-1 coordinates)
	var layout: Array[Dictionary] = []
	var x := PADDING
	var y := WORKSTATION_START + EQUIP_TOP_OFFSET
	var h := EQUIP_HEIGHT

	# 1. CUPS
	layout.append({"id": "cups", "rect": Rect2(x, y, CUPS_W, h), "label": "Grab Cup"})
	x += CUPS_W + PADDING

	# 2. ESPRESSO
	layout.append({"id": "espresso", "rect": Rect2(x, y, ESPRESSO_W, h), "label": "Espresso"})
	x += ESPRESSO_W + PADDING

	# 3. MILK
	layout.append({"id": "milk", "rect": Rect2(x, y, MILK_W, h), "label": "Milk"})
	x += MILK_W + PADDING

	# 4. INGREDIENTS (5 bottles)
	var bottle_w := INGREDIENTS_W / 5.0
	var ingredient_ids := ["water", "chocolate", "ice", "chai", "green_tea"]
	var ingredient_labels := ["Water", "Chocolate", "Ice", "Chai", "Green Tea"]
	for i in range(5):
		layout.append({
			"id": ingredient_ids[i],
			"rect": Rect2(x + i * bottle_w, y, bottle_w - 0.002, h),
			"label": ingredient_labels[i]
		})
	x += INGREDIENTS_W + PADDING

	# 5. SERVE
	layout.append({"id": "serve", "rect": Rect2(x, y, SERVE_W, h), "label": "Serve"})
	x += SERVE_W + PADDING

	# 6. TRASH
	layout.append({"id": "trash", "rect": Rect2(x, y, TRASH_W, h), "label": "Trash"})

	return layout


func _create_status_display() -> void:
	var label := Label.new()
	label.name = "StatusLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	status_label = label
	_update_status()


func _create_cup_indicator() -> void:
	var indicator := Control.new()
	indicator.name = "CupIndicator"
	indicator.custom_minimum_size = Vector2(50, 65)
	var script := load("res://scripts/ui/cup_display.gd")
	if script:
		indicator.set_script(script)
	add_child(indicator)
	cup_indicator = indicator


func _process(_delta: float) -> void:
	if not visible:
		return
	_position_elements()


func _position_elements() -> void:
	# Position equipment areas
	for equip_id: String in equipment_areas:
		var equip: Dictionary = equipment_areas[equip_id]
		var rect: Rect2 = equip.rect
		var node: Panel = equip.node

		node.position = Vector2(rect.position.x * size.x, rect.position.y * size.y)
		node.size = Vector2(rect.size.x * size.x, rect.size.y * size.y)

	# Position status label (above workstation)
	status_label.position = Vector2(size.x * 0.30, size.y * 0.65)
	status_label.size = Vector2(size.x * 0.40, 24)

	# Position cup indicator (center of shop area, below customer)
	cup_indicator.position = Vector2(size.x * 0.45, size.y * 0.52)
	cup_indicator.size = Vector2(size.x * 0.10, size.y * 0.12)


func _on_area_mouse_entered(equip_id: String) -> void:
	hover_area = equip_id
	_update_area_visual(equip_id, true)


func _on_area_mouse_exited(equip_id: String) -> void:
	if hover_area == equip_id:
		hover_area = ""
	_update_area_visual(equip_id, false)


func _on_area_gui_input(event: InputEvent, equip_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_equipment_click(equip_id)


func _handle_equipment_click(equip_id: String) -> void:
	if not _is_equipment_available(equip_id):
		return

	match equip_id:
		"cups":
			has_cup = true
			current_ingredients.clear()
			_animate_click(equip_id)
		"serve":
			if has_cup and not current_ingredients.is_empty():
				_serve_drink()
				return
		"trash":
			if has_cup:
				_discard_drink()
				return
		_:
			# Ingredient
			if has_cup and equip_id not in current_ingredients:
				current_ingredients.append(equip_id)
				_animate_click(equip_id)

	_update_status()
	if cup_indicator:
		cup_indicator.queue_redraw()


func _update_area_visual(equip_id: String, is_hovered: bool) -> void:
	if equip_id not in equipment_areas:
		return

	var area: Panel = equipment_areas[equip_id].node
	var style: StyleBoxFlat = area.get_theme_stylebox("panel").duplicate()
	var is_available := _is_equipment_available(equip_id)

	if is_hovered and is_available:
		style.bg_color = COLOR_HOVER
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(1, 1, 0.7, 0.6)
	else:
		style.bg_color = Color(1, 1, 1, 0)
		style.border_color = Color(1, 1, 1, 0)

	area.add_theme_stylebox_override("panel", style)


func _is_equipment_available(equip_id: String) -> bool:
	match equip_id:
		"cups":
			return not has_cup
		"serve":
			return has_cup and not current_ingredients.is_empty()
		"trash":
			return has_cup
		_:
			return has_cup and equip_id not in current_ingredients


func _update_status() -> void:
	if not has_cup:
		status_label.text = "👆 Click CUPS to start"
	elif current_ingredients.is_empty():
		status_label.text = "☕ Add ingredients from the workstation"
	else:
		var drink := _identify_drink()
		if drink != "Mystery Drink":
			status_label.text = "✓ %s ready! Click SERVE" % drink
		else:
			status_label.text = "Making: %s..." % _get_ingredients_text()

	if cup_indicator and cup_indicator.has_method("set_ingredients"):
		cup_indicator.set_ingredients(current_ingredients if has_cup else [])


func _get_ingredients_text() -> String:
	var names: Array[String] = []
	for ing in current_ingredients:
		names.append(ing.capitalize())
	return " + ".join(names)


func _serve_drink() -> void:
	var drink := _identify_drink()
	_animate_serve()
	drink_made.emit(drink)
	reset_station()


func _discard_drink() -> void:
	_animate_discard()
	reset_station()


func _identify_drink() -> String:
	var sorted_current := current_ingredients.duplicate()
	sorted_current.sort()

	for drink_name: String in RECIPES:
		var recipe: Array = RECIPES[drink_name]
		var sorted_recipe := recipe.duplicate()
		sorted_recipe.sort()

		if _arrays_equal(sorted_current, sorted_recipe):
			return drink_name

	return "Mystery Drink"


func _arrays_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true


func _animate_click(equip_id: String) -> void:
	if equip_id not in equipment_areas:
		return
	var area: Panel = equipment_areas[equip_id].node
	var tween := create_tween()
	tween.tween_property(area, "modulate", Color(1.4, 1.4, 1.1), 0.08)
	tween.tween_property(area, "modulate", Color.WHITE, 0.12)


func _animate_serve() -> void:
	if not cup_indicator:
		return
	var tween := create_tween()
	tween.tween_property(cup_indicator, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func(): cup_indicator.modulate.a = 1.0)


func _animate_discard() -> void:
	if not cup_indicator:
		return
	var tween := create_tween()
	tween.tween_property(cup_indicator, "position:y", cup_indicator.position.y + 40, 0.2)
	tween.parallel().tween_property(cup_indicator, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		cup_indicator.modulate.a = 1.0
		_position_elements()
	)


func reset_station() -> void:
	has_cup = false
	current_ingredients.clear()
	_update_status()
	if cup_indicator:
		cup_indicator.queue_redraw()


func show_station() -> void:
	print("DrinkStation: show_station() called")
	visible = true
	reset_station()


func hide_station() -> void:
	print("DrinkStation: hide_station() called")
	visible = false
