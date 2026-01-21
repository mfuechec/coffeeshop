extends Control
## Debug overlay to visualize window regions - helps align weather effects
## Toggle with Debug button or F3 key

var background_manager: TextureRect
var show_debug: bool = false  # Start hidden


func _ready() -> void:
	# Make this overlay cover the full screen but not block input
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_background_manager(manager: TextureRect) -> void:
	background_manager = manager
	queue_redraw()


func toggle_debug() -> void:
	show_debug = not show_debug
	visible = show_debug
	queue_redraw()
	print("Debug overlay toggled: ", show_debug)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		toggle_debug()


func _process(_delta: float) -> void:
	if show_debug and visible:
		queue_redraw()


func _draw() -> void:
	if not show_debug:
		return

	# Always draw a corner marker so we know the overlay is working
	draw_rect(Rect2(10, 10, 200, 50), Color(0, 1, 0, 0.9))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(15, 35), "DEBUG ON", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

	if not background_manager:
		draw_string(font, Vector2(15, 70), "No background_manager!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.RED)
		return

	var window_rects: Array[Rect2] = background_manager.get_all_window_rects()

	if window_rects.is_empty():
		draw_string(font, Vector2(15, 70), "No window rects found!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.RED)
		return

	for i in range(window_rects.size()):
		var rect: Rect2 = window_rects[i]

		# Draw semi-transparent fill
		draw_rect(rect, Color(1, 0, 0, 0.3))

		# Draw thick border
		draw_rect(rect, Color(1, 0, 0, 1.0), false, 3.0)

		# Draw label
		var label := "Window %d" % (i + 1)
		draw_string(font, rect.position + Vector2(5, 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.RED)

		# Draw coordinates
		var coords := "x:%.0f y:%.0f w:%.0f h:%.0f" % [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
		draw_string(font, rect.position + Vector2(5, 40), coords, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.RED)

	# Draw actual image bounds (shows letterboxing)
	var img_rect: Rect2 = background_manager.get_actual_image_rect()
	draw_rect(img_rect, Color(0, 1, 1, 0.3), false, 2.0)  # Cyan border for image bounds

	# Draw background manager info
	var info := "BG size: %.0f x %.0f | Image: %.0f x %.0f at (%.0f, %.0f)" % [
		background_manager.size.x, background_manager.size.y,
		img_rect.size.x, img_rect.size.y, img_rect.position.x, img_rect.position.y
	]
	draw_string(font, Vector2(15, 80), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)
