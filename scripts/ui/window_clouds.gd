extends Node2D
## Draws animated clouds inside the window viewport (gets clipped automatically)

var cloud_offset: float = 0.0
const CLOUD_SPEED := 8.0

var window_size: Vector2 = Vector2.ZERO
var is_night: bool = false


func _process(delta: float) -> void:
	if GameManager and GameManager.idle_mode:
		return

	cloud_offset += CLOUD_SPEED * delta
	if cloud_offset > window_size.x + 100:
		cloud_offset = 0.0
	queue_redraw()


func set_window_size(size: Vector2) -> void:
	window_size = size


func set_night_mode(night: bool) -> void:
	is_night = night


func _draw() -> void:
	if window_size == Vector2.ZERO:
		return

	var cloud_alpha := 1.0 if not is_night else 0.3
	var cloud_color := Color(1.0, 1.0, 1.0, cloud_alpha)

	# Cloud cluster 1
	var base_x1 := fmod(cloud_offset * 0.5, window_size.x + 60) - 30
	var cloud_y1 := window_size.y * 0.3
	_draw_cloud(Vector2(base_x1, cloud_y1), 1.0, cloud_color)

	# Cloud cluster 2 (slower, different height)
	var base_x2 := fmod(cloud_offset * 0.3 + window_size.x * 0.5, window_size.x + 80) - 40
	var cloud_y2 := window_size.y * 0.45
	_draw_cloud(Vector2(base_x2, cloud_y2), 0.7, cloud_color)

	# Cloud cluster 3 (fastest, top)
	var base_x3 := fmod(cloud_offset * 0.7 + window_size.x * 0.25, window_size.x + 50) - 25
	var cloud_y3 := window_size.y * 0.2
	_draw_cloud(Vector2(base_x3, cloud_y3), 0.5, cloud_color)


func _draw_cloud(center: Vector2, scale_factor: float, color: Color) -> void:
	var base_radius := 12.0 * scale_factor
	draw_circle(center, base_radius, color)
	draw_circle(center + Vector2(-10, 2) * scale_factor, base_radius * 0.8, color)
	draw_circle(center + Vector2(10, 2) * scale_factor, base_radius * 0.85, color)
	draw_circle(center + Vector2(5, -4) * scale_factor, base_radius * 1.1, color)
	draw_circle(center + Vector2(-5, -3) * scale_factor, base_radius * 0.9, color)
