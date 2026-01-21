extends TextureRect
## Manages the coffee shop background images and theme switching

signal shop_theme_changed(theme_name: String)

enum ShopTheme { WARM_MODERN, MOODY_CLASSIC, COZY_TRADITIONAL }

const THEME_PATHS := {
	ShopTheme.WARM_MODERN: "res://assets/backgrounds/warm_modern.png",
	ShopTheme.MOODY_CLASSIC: "res://assets/backgrounds/moody_classic.png",
	ShopTheme.COZY_TRADITIONAL: "res://assets/backgrounds/cozy_traditional.png"
}

const THEME_NAMES := {
	ShopTheme.WARM_MODERN: "Warm & Modern",
	ShopTheme.MOODY_CLASSIC: "Moody & Classic",
	ShopTheme.COZY_TRADITIONAL: "Cozy & Traditional"
}

# Window regions for each theme (normalized 0-1 coordinates)
# These define where weather effects should appear
# Format: Rect2(x, y, width, height) where all values are 0-1 proportions
const WINDOW_REGIONS := {
	ShopTheme.WARM_MODERN: [
		# Six window sections across the back wall (left to right)
		Rect2(0.010, 0.060, 0.140, 0.520),  # Window 1: far left (green trees)
		Rect2(0.160, 0.060, 0.130, 0.520),  # Window 2: left-center (autumn foliage)
		Rect2(0.310, 0.060, 0.110, 0.520),  # Window 3: center-left
		Rect2(0.440, 0.060, 0.120, 0.520),  # Window 4: center-right (city)
		Rect2(0.680, 0.060, 0.130, 0.520),  # Window 5: right (blue sky)
		Rect2(0.830, 0.060, 0.160, 0.520)   # Window 6: far right (partial)
	],
	ShopTheme.MOODY_CLASSIC: [
		# Large central window with city view
		Rect2(0.220, 0.060, 0.560, 0.720)
	],
	ShopTheme.COZY_TRADITIONAL: [
		# Windows showing snowy street
		Rect2(0.030, 0.060, 0.380, 0.680),  # Large left window
		Rect2(0.680, 0.060, 0.200, 0.500)   # Smaller right window
	]
}

var current_shop_theme: ShopTheme = ShopTheme.WARM_MODERN
var _textures: Dictionary = {}


func _ready() -> void:
	# Configure TextureRect
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT  # Keep entire image visible (letterbox if needed)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Preload all textures
	_preload_textures()

	# Load saved theme or default
	var saved_theme: int = _load_saved_theme()
	apply_shop_theme(saved_theme)


func get_actual_image_rect() -> Rect2:
	## Returns the actual displayed image bounds within the TextureRect
	## Accounts for letterboxing when using STRETCH_KEEP_ASPECT
	if not texture:
		return Rect2(Vector2.ZERO, size)

	var tex_size := texture.get_size()
	var container_size := size

	# Calculate aspect ratios
	var tex_aspect := tex_size.x / tex_size.y
	var container_aspect := container_size.x / container_size.y

	var image_size: Vector2
	var image_pos: Vector2

	if container_aspect > tex_aspect:
		# Container is wider - letterbox on sides (vertical bars)
		image_size.y = container_size.y
		image_size.x = container_size.y * tex_aspect
		image_pos.x = (container_size.x - image_size.x) / 2.0
		image_pos.y = 0.0
	else:
		# Container is taller - letterbox on top/bottom (horizontal bars)
		image_size.x = container_size.x
		image_size.y = container_size.x / tex_aspect
		image_pos.x = 0.0
		image_pos.y = (container_size.y - image_size.y) / 2.0

	return Rect2(image_pos, image_size)


func _preload_textures() -> void:
	for theme_id: int in THEME_PATHS:
		var path: String = THEME_PATHS[theme_id]
		var tex: Texture2D = load(path)
		if tex:
			_textures[theme_id] = tex
		else:
			push_warning("Failed to load background: " + path)


func apply_shop_theme(theme_id: int) -> void:
	if theme_id in _textures:
		current_shop_theme = theme_id as ShopTheme
		texture = _textures[theme_id]
		_save_theme(theme_id)
		shop_theme_changed.emit(THEME_NAMES[theme_id])


func cycle_theme() -> void:
	var next_theme: int = (current_shop_theme + 1) % ShopTheme.size()
	apply_shop_theme(next_theme)


func get_current_theme_name() -> String:
	return THEME_NAMES.get(current_shop_theme, "Unknown")


func get_window_regions() -> Array:
	return WINDOW_REGIONS.get(current_shop_theme, [])


func get_primary_window_rect() -> Rect2:
	var regions: Array = get_window_regions()
	if regions.is_empty():
		return Rect2(0.1, 0.1, 0.3, 0.5)

	# Get actual image bounds (accounts for letterboxing)
	var img_rect := get_actual_image_rect()

	# Return the first/primary window, scaled to actual image size
	var normalized: Rect2 = regions[0]
	return Rect2(
		img_rect.position.x + normalized.position.x * img_rect.size.x,
		img_rect.position.y + normalized.position.y * img_rect.size.y,
		normalized.size.x * img_rect.size.x,
		normalized.size.y * img_rect.size.y
	)


func get_all_window_rects() -> Array[Rect2]:
	## Returns all window regions scaled to actual pixel coordinates
	## Accounts for letterboxing when image doesn't fill the container
	var result: Array[Rect2] = []
	var regions: Array = get_window_regions()

	# Get actual image bounds (accounts for letterboxing)
	var img_rect := get_actual_image_rect()

	for region in regions:
		var normalized: Rect2 = region
		result.append(Rect2(
			img_rect.position.x + normalized.position.x * img_rect.size.x,
			img_rect.position.y + normalized.position.y * img_rect.size.y,
			normalized.size.x * img_rect.size.x,
			normalized.size.y * img_rect.size.y
		))

	return result


func get_combined_window_bounds() -> Rect2:
	## Returns a single bounding rectangle that encompasses all windows
	var rects := get_all_window_rects()
	if rects.is_empty():
		return Rect2(size.x * 0.1, size.y * 0.1, size.x * 0.3, size.y * 0.5)

	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	for rect in rects:
		min_x = minf(min_x, rect.position.x)
		min_y = minf(min_y, rect.position.y)
		max_x = maxf(max_x, rect.position.x + rect.size.x)
		max_y = maxf(max_y, rect.position.y + rect.size.y)

	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _save_theme(theme_id: int) -> void:
	var config := ConfigFile.new()
	config.set_value("display", "theme", theme_id)
	config.save("user://settings.cfg")


func _load_saved_theme() -> int:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		return config.get_value("display", "theme", ShopTheme.WARM_MODERN)
	return ShopTheme.WARM_MODERN
