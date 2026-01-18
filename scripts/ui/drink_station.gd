extends Control
## Interactive drink-making station

signal drink_made(drink_name: String)

# Recipes: what ingredients make what drink
const RECIPES := {
	# drink_name: [required_ingredients]
	"Espresso": ["espresso"],
	"Americano": ["espresso", "water"],
	"Latte": ["espresso", "steamed_milk"],
	"Cappuccino": ["espresso", "foamed_milk"],
	"Mocha": ["espresso", "chocolate", "steamed_milk"],
	"Hot Chocolate": ["chocolate", "steamed_milk"],
	"Chai Latte": ["chai", "steamed_milk"],
	"Green Tea": ["green_tea", "water"],
	"Iced Coffee": ["espresso", "ice"],
	"Flat White": ["espresso", "flat_milk"],
}

# Current ingredients added to the cup
var current_ingredients: Array[String] = []
var cup_has_base: bool = false

# Equipment buttons
var equipment_buttons: Dictionary = {}

# Colors for visual feedback
const BUTTON_NORMAL := Color(0.25, 0.2, 0.18)
const BUTTON_HOVER := Color(0.35, 0.28, 0.24)
const BUTTON_PRESSED := Color(0.5, 0.4, 0.3)
const BUTTON_DISABLED := Color(0.15, 0.12, 0.1)


func _ready() -> void:
	_setup_station()


func _setup_station() -> void:
	# Main container
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	# Instructions label
	var instruction_label := Label.new()
	instruction_label.text = "Select ingredients to make the drink:"
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(instruction_label)

	# Cup display showing current ingredients
	var cup_display := _create_cup_display()
	main_vbox.add_child(cup_display)

	# Equipment grid
	var equipment_grid := GridContainer.new()
	equipment_grid.columns = 4
	equipment_grid.add_theme_constant_override("h_separation", 6)
	equipment_grid.add_theme_constant_override("v_separation", 6)
	equipment_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(equipment_grid)

	# Add equipment buttons
	_add_equipment_button(equipment_grid, "espresso", "☕ Espresso", "Pull a shot of espresso")
	_add_equipment_button(equipment_grid, "water", "💧 Water", "Add hot water")
	_add_equipment_button(equipment_grid, "steamed_milk", "🥛 Steam Milk", "Add steamed milk")
	_add_equipment_button(equipment_grid, "foamed_milk", "🫧 Foam Milk", "Add foamed milk")
	_add_equipment_button(equipment_grid, "flat_milk", "🥛 Flat Milk", "Add flat white milk")
	_add_equipment_button(equipment_grid, "chocolate", "🍫 Chocolate", "Add chocolate syrup")
	_add_equipment_button(equipment_grid, "chai", "🫖 Chai", "Brew chai tea")
	_add_equipment_button(equipment_grid, "green_tea", "🍵 Green Tea", "Brew green tea")
	_add_equipment_button(equipment_grid, "ice", "🧊 Ice", "Add ice cubes")

	# Action buttons row
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 20)
	main_vbox.add_child(action_row)

	# Serve button
	var serve_btn := Button.new()
	serve_btn.text = "🍵 Serve Drink"
	serve_btn.pressed.connect(_on_serve_pressed)
	serve_btn.custom_minimum_size = Vector2(120, 35)
	action_row.add_child(serve_btn)

	# Reset button
	var reset_btn := Button.new()
	reset_btn.text = "🗑️ Start Over"
	reset_btn.pressed.connect(_on_reset_pressed)
	reset_btn.custom_minimum_size = Vector2(120, 35)
	action_row.add_child(reset_btn)


func _create_cup_display() -> Control:
	var cup_container := HBoxContainer.new()
	cup_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cup_container.custom_minimum_size = Vector2(0, 50)

	var cup_panel := Panel.new()
	cup_panel.custom_minimum_size = Vector2(200, 45)
	cup_panel.name = "CupPanel"
	cup_container.add_child(cup_panel)

	var cup_label := Label.new()
	cup_label.name = "CupLabel"
	cup_label.text = "Empty cup..."
	cup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cup_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cup_label.add_theme_font_size_override("font_size", 13)
	cup_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))
	cup_panel.add_child(cup_label)

	return cup_container


func _add_equipment_button(parent: Control, ingredient_id: String, label_text: String, tooltip: String) -> void:
	var btn := Button.new()
	btn.text = label_text
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(95, 40)
	btn.pressed.connect(_on_ingredient_pressed.bind(ingredient_id))
	parent.add_child(btn)
	equipment_buttons[ingredient_id] = btn


func _on_ingredient_pressed(ingredient_id: String) -> void:
	# Add ingredient if not already added
	if ingredient_id not in current_ingredients:
		current_ingredients.append(ingredient_id)
		_update_cup_display()
		_animate_button_press(equipment_buttons[ingredient_id])


func _animate_button_press(btn: Button) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "modulate", Color(1.3, 1.3, 1.0), 0.1)
	tween.tween_property(btn, "modulate", Color.WHITE, 0.2)


func _update_cup_display() -> void:
	var cup_label: Label = find_child("CupLabel", true, false)
	if not cup_label:
		return

	if current_ingredients.is_empty():
		cup_label.text = "Empty cup..."
		cup_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))
	else:
		var ingredient_names: Array[String] = []
		for ing in current_ingredients:
			ingredient_names.append(_get_ingredient_display_name(ing))
		cup_label.text = " + ".join(ingredient_names)
		cup_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))


func _get_ingredient_display_name(ingredient_id: String) -> String:
	match ingredient_id:
		"espresso": return "Espresso"
		"water": return "Water"
		"steamed_milk": return "Steamed Milk"
		"foamed_milk": return "Foamed Milk"
		"flat_milk": return "Flat Milk"
		"chocolate": return "Chocolate"
		"chai": return "Chai"
		"green_tea": return "Green Tea"
		"ice": return "Ice"
		_: return ingredient_id


func _on_serve_pressed() -> void:
	if current_ingredients.is_empty():
		return

	var made_drink := _identify_drink()
	drink_made.emit(made_drink)
	reset_station()


func _on_reset_pressed() -> void:
	reset_station()


func reset_station() -> void:
	current_ingredients.clear()
	_update_cup_display()


func _identify_drink() -> String:
	# Sort current ingredients for comparison
	var sorted_current := current_ingredients.duplicate()
	sorted_current.sort()

	# Check against all recipes
	for drink_name: String in RECIPES:
		var recipe: Array = RECIPES[drink_name]
		var sorted_recipe := recipe.duplicate()
		sorted_recipe.sort()

		if _arrays_equal(sorted_current, sorted_recipe):
			return drink_name

	# No match - return description of what was made
	return "Mystery Drink"


func _arrays_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true


func show_station() -> void:
	visible = true
	reset_station()


func hide_station() -> void:
	visible = false
