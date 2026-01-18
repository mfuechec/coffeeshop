extends Control
## Visual display of the cup being filled

var ingredients: Array[String] = []
var has_cup: bool = false

# Ingredient colors for visual representation
const INGREDIENT_COLORS := {
	"espresso": Color(0.25, 0.15, 0.1),      # Dark brown
	"water": Color(0.7, 0.85, 0.95, 0.6),    # Light blue transparent
	"milk": Color(0.95, 0.93, 0.88),         # Creamy white
	"chocolate": Color(0.35, 0.2, 0.12),     # Chocolate brown
	"ice": Color(0.85, 0.95, 1.0, 0.8),      # Ice blue
	"chai": Color(0.6, 0.45, 0.3),           # Chai brown
	"green_tea": Color(0.6, 0.75, 0.5),      # Green tea color
}

const CUP_COLOR := Color(0.95, 0.95, 0.92)
const CUP_SHADOW := Color(0.85, 0.85, 0.82)


func set_ingredients(new_ingredients: Array) -> void:
	ingredients.clear()
	for ing in new_ingredients:
		ingredients.append(str(ing))
	has_cup = not ingredients.is_empty() or get_parent().has_cup if get_parent() else false
	queue_redraw()


func _draw() -> void:
	if not get_parent():
		return

	has_cup = get_parent().has_cup if get_parent().has_method("reset_station") else false

	if not has_cup:
		return

	var center := size / 2
	var cup_width := size.x * 0.7
	var cup_height := size.y * 0.8
	var cup_top := size.y * 0.15

	# Cup body (trapezoid shape)
	var cup_points := PackedVector2Array([
		Vector2(center.x - cup_width * 0.4, cup_top),
		Vector2(center.x - cup_width * 0.35, cup_top + cup_height),
		Vector2(center.x + cup_width * 0.35, cup_top + cup_height),
		Vector2(center.x + cup_width * 0.4, cup_top),
	])
	draw_polygon(cup_points, [CUP_COLOR])

	# Cup rim
	draw_line(
		Vector2(center.x - cup_width * 0.45, cup_top),
		Vector2(center.x + cup_width * 0.45, cup_top),
		CUP_SHADOW,
		3.0
	)

	# Draw ingredients as layers in the cup
	if not ingredients.is_empty():
		var liquid_top := cup_top + cup_height * 0.15
		var liquid_bottom := cup_top + cup_height * 0.9
		var liquid_height := liquid_bottom - liquid_top
		var layer_height := liquid_height / maxf(ingredients.size(), 1)

		for i in range(ingredients.size()):
			var ing: String = ingredients[i]
			var color: Color = INGREDIENT_COLORS.get(ing, Color(0.5, 0.4, 0.3))

			var layer_y := liquid_bottom - (i + 1) * layer_height
			var layer_bottom_y := liquid_bottom - i * layer_height

			# Calculate cup width at this height (it tapers)
			var t_top := (layer_y - cup_top) / cup_height
			var t_bottom := (layer_bottom_y - cup_top) / cup_height
			var width_top := lerpf(cup_width * 0.38, cup_width * 0.33, t_top)
			var width_bottom := lerpf(cup_width * 0.38, cup_width * 0.33, t_bottom)

			var layer_points := PackedVector2Array([
				Vector2(center.x - width_top, layer_y),
				Vector2(center.x - width_bottom, layer_bottom_y),
				Vector2(center.x + width_bottom, layer_bottom_y),
				Vector2(center.x + width_top, layer_y),
			])
			draw_polygon(layer_points, [color])

			# Add foam effect for milk on top
			if ing == "milk" and i == ingredients.size() - 1:
				_draw_foam(center, width_top, layer_y)

	# Cup handle
	var handle_y := cup_top + cup_height * 0.3
	draw_arc(
		Vector2(center.x + cup_width * 0.4, handle_y + cup_height * 0.2),
		cup_width * 0.15,
		-PI * 0.4,
		PI * 0.4,
		8,
		CUP_SHADOW,
		3.0
	)


func _draw_foam(center: Vector2, width: float, y: float) -> void:
	# Draw little foam bubbles
	var foam_color := Color(1.0, 0.99, 0.97)
	for i in range(5):
		var bubble_x := center.x + (randf() - 0.5) * width * 1.5
		var bubble_y := y + randf() * 8
		var bubble_size := 3 + randf() * 4
		draw_circle(Vector2(bubble_x, bubble_y), bubble_size, foam_color)
