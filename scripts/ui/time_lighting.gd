extends CanvasModulate
## Controls ambient lighting based on time of day
## Creates warm morning light, bright afternoon, golden evening, and cozy night

# Lighting color palettes for each time period
const LIGHTING_COLORS := {
	"morning": Color(1.0, 0.95, 0.88),      # Warm golden morning light
	"afternoon": Color(1.0, 1.0, 1.0),       # Neutral daylight
	"evening": Color(1.0, 0.85, 0.7),        # Warm sunset orange
	"night": Color(0.7, 0.75, 0.9)           # Cool blue night with warm interior
}

# Transition duration in seconds
const TRANSITION_DURATION := 3.0

var current_target_color: Color = Color.WHITE
var tween: Tween


func _ready() -> void:
	# Initialize to current time period
	_update_lighting_for_period(TimeManager.get_period_name())

	# Connect to time changes
	TimeManager.time_of_day_changed.connect(_on_time_of_day_changed)
	TimeManager.hour_changed.connect(_on_hour_changed)


func _on_time_of_day_changed(period: String) -> void:
	_update_lighting_for_period(period)


func _on_hour_changed(_hour: int) -> void:
	# Subtle adjustments within the same period
	_apply_hour_variation()


func _update_lighting_for_period(period: String) -> void:
	var target: Color = LIGHTING_COLORS.get(period, Color.WHITE)
	_transition_to_color(target)


func _transition_to_color(target: Color) -> void:
	current_target_color = target

	# Kill any existing tween
	if tween and tween.is_valid():
		tween.kill()

	# Create smooth transition
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "color", target, TRANSITION_DURATION)


func _apply_hour_variation() -> void:
	# Add subtle variations based on exact hour within a period
	var hour := TimeManager.get_hour()
	var base_color := current_target_color
	var variation := Color.WHITE

	match TimeManager.current_period:
		TimeManager.TimePeriod.MORNING:
			# Early morning is dimmer, gets brighter
			if hour < 8:
				variation = Color(0.95, 0.9, 0.85)
			elif hour < 10:
				variation = Color(1.0, 0.98, 0.95)
		TimeManager.TimePeriod.EVENING:
			# Sunset progression
			if hour == 17:
				variation = Color(1.0, 0.9, 0.8)
			elif hour == 18:
				variation = Color(1.0, 0.85, 0.7)
			elif hour >= 19:
				variation = Color(0.95, 0.8, 0.7)
		TimeManager.TimePeriod.NIGHT:
			# Late night gets darker
			if hour >= 22 or hour < 2:
				variation = Color(0.6, 0.65, 0.8)
			elif hour >= 2 and hour < 5:
				variation = Color(0.55, 0.6, 0.75)

	var final_color := base_color * variation
	_transition_to_color(final_color)


# Manual override for testing or special events
func set_lighting_override(override_color: Color, duration: float = 1.0) -> void:
	if tween and tween.is_valid():
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "color", override_color, duration)


func clear_lighting_override() -> void:
	_update_lighting_for_period(TimeManager.get_period_name())
