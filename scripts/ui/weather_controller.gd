extends Node2D
## Controls weather effects visible through the window
## Manages rain, snow, and clear weather with smooth transitions

signal weather_changed(weather_type: String)

enum WeatherType { CLEAR, RAIN, SNOW }

const WEATHER_CHANGE_INTERVAL := 300.0  # Check every 5 minutes (in seconds)
const TRANSITION_DURATION := 2.0

# Weather probabilities based on time of day
const WEATHER_CHANCES := {
	"morning": { "clear": 0.7, "rain": 0.25, "snow": 0.05 },
	"afternoon": { "clear": 0.8, "rain": 0.15, "snow": 0.05 },
	"evening": { "clear": 0.6, "rain": 0.3, "snow": 0.1 },
	"night": { "clear": 0.5, "rain": 0.35, "snow": 0.15 }
}

var current_weather: WeatherType = WeatherType.CLEAR
var rain_particles: GPUParticles2D
var snow_particles: GPUParticles2D
var weather_timer: Timer

# Window bounds for particles
var window_rect: Rect2


func _ready() -> void:
	_setup_particles()
	_setup_timer()

	# Initial random weather
	_roll_weather()


func set_window_bounds(rect: Rect2) -> void:
	window_rect = rect
	_update_particle_positions()


func _setup_timer() -> void:
	weather_timer = Timer.new()
	weather_timer.wait_time = WEATHER_CHANGE_INTERVAL
	weather_timer.timeout.connect(_roll_weather)
	add_child(weather_timer)
	weather_timer.start()


func _setup_particles() -> void:
	# Create rain particle system
	rain_particles = _create_rain_particles()
	add_child(rain_particles)

	# Create snow particle system
	snow_particles = _create_snow_particles()
	add_child(snow_particles)

	# Start with particles off
	rain_particles.emitting = false
	snow_particles.emitting = false


func _create_rain_particles() -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.amount = 100
	particles.lifetime = 0.8
	particles.preprocess = 0.5

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.1, 1, 0)  # Slight angle
	material.spread = 5.0
	material.initial_velocity_min = 400.0
	material.initial_velocity_max = 500.0
	material.gravity = Vector3(0, 300, 0)

	# Raindrop elongation effect
	material.scale_min = 0.8
	material.scale_max = 1.2

	# Blue-ish tint
	material.color = Color(0.7, 0.8, 1.0, 0.6)

	particles.process_material = material

	# Create simple raindrop texture
	particles.texture = _create_raindrop_texture()

	return particles


func _create_snow_particles() -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.amount = 60
	particles.lifetime = 3.0
	particles.preprocess = 1.0

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, 20, 0)

	# Gentle floating effect
	material.angular_velocity_min = -45.0
	material.angular_velocity_max = 45.0

	# Size variation
	material.scale_min = 0.5
	material.scale_max = 1.5

	# White with slight transparency
	material.color = Color(1.0, 1.0, 1.0, 0.8)

	particles.process_material = material

	# Create simple snowflake texture
	particles.texture = _create_snowflake_texture()

	return particles


func _create_raindrop_texture() -> ImageTexture:
	var img := Image.create(4, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Draw elongated raindrop shape
	for y in range(16):
		var width_factor := 1.0 - (float(y) / 16.0) * 0.5
		var x_start := int(2 - width_factor)
		var x_end := int(2 + width_factor)
		for x in range(max(0, x_start), min(4, x_end + 1)):
			var alpha := 0.8 - (float(y) / 16.0) * 0.3
			img.set_pixel(x, y, Color(0.8, 0.9, 1.0, alpha))

	return ImageTexture.create_from_image(img)


func _create_snowflake_texture() -> ImageTexture:
	var size := 8
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var center := size / 2.0

	# Draw simple circular snowflake
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x - center + 0.5, y - center + 0.5).length()
			if dist < center:
				var alpha := 1.0 - (dist / center) * 0.5
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	return ImageTexture.create_from_image(img)


func _update_particle_positions() -> void:
	if window_rect.size == Vector2.ZERO:
		return

	# Position particles to fall within window bounds
	rain_particles.position = Vector2(window_rect.position.x + window_rect.size.x / 2, window_rect.position.y)
	snow_particles.position = rain_particles.position

	# Update emission box to match window width
	var rain_mat := rain_particles.process_material as ParticleProcessMaterial
	if rain_mat:
		rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		rain_mat.emission_box_extents = Vector3(window_rect.size.x / 2, 1, 1)

	var snow_mat := snow_particles.process_material as ParticleProcessMaterial
	if snow_mat:
		snow_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		snow_mat.emission_box_extents = Vector3(window_rect.size.x / 2, 1, 1)


func _roll_weather() -> void:
	var period := "afternoon"
	if TimeManager:
		period = TimeManager.get_period_name()

	var chances: Dictionary = WEATHER_CHANCES.get(period, WEATHER_CHANCES["afternoon"])
	var roll := randf()

	var new_weather: WeatherType
	if roll < chances.clear:
		new_weather = WeatherType.CLEAR
	elif roll < chances.clear + chances.rain:
		new_weather = WeatherType.RAIN
	else:
		new_weather = WeatherType.SNOW

	if new_weather != current_weather:
		_transition_to_weather(new_weather)


func _transition_to_weather(new_weather: WeatherType) -> void:
	var old_weather := current_weather
	current_weather = new_weather

	# Fade out old weather
	match old_weather:
		WeatherType.RAIN:
			_fade_particles(rain_particles, false)
		WeatherType.SNOW:
			_fade_particles(snow_particles, false)

	# Fade in new weather
	match new_weather:
		WeatherType.RAIN:
			_fade_particles(rain_particles, true)
		WeatherType.SNOW:
			_fade_particles(snow_particles, true)

	weather_changed.emit(get_weather_name())


func _fade_particles(particles: GPUParticles2D, fade_in: bool) -> void:
	var tween := create_tween()

	if fade_in:
		particles.emitting = true
		particles.modulate.a = 0.0
		tween.tween_property(particles, "modulate:a", 1.0, TRANSITION_DURATION)
	else:
		tween.tween_property(particles, "modulate:a", 0.0, TRANSITION_DURATION)
		tween.tween_callback(func(): particles.emitting = false)


func get_weather_name() -> String:
	match current_weather:
		WeatherType.CLEAR:
			return "clear"
		WeatherType.RAIN:
			return "rain"
		WeatherType.SNOW:
			return "snow"
	return "clear"


func is_raining() -> bool:
	return current_weather == WeatherType.RAIN


func is_snowing() -> bool:
	return current_weather == WeatherType.SNOW


# Manual weather control for testing or special events
func set_weather(weather_type: String) -> void:
	match weather_type.to_lower():
		"clear":
			_transition_to_weather(WeatherType.CLEAR)
		"rain":
			_transition_to_weather(WeatherType.RAIN)
		"snow":
			_transition_to_weather(WeatherType.SNOW)


func force_weather_check() -> void:
	_roll_weather()
