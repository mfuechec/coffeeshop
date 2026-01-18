extends Node
## Manages in-game time and syncs with real-world time
## The coffee shop operates on real time - customers come throughout the day

signal hour_changed(hour: int)
signal day_changed(day: int)
signal time_of_day_changed(period: String)

enum TimePeriod { MORNING, AFTERNOON, EVENING, NIGHT }

var current_hour: int = 0
var current_day: int = 1
var current_period: TimePeriod = TimePeriod.MORNING

var check_timer: Timer
const CHECK_INTERVAL := 60.0  # Check time every minute


func _ready() -> void:
	_update_time()
	_setup_timer()


func _setup_timer() -> void:
	check_timer = Timer.new()
	check_timer.wait_time = CHECK_INTERVAL
	check_timer.timeout.connect(_update_time)
	add_child(check_timer)
	check_timer.start()


func _update_time() -> void:
	var time_dict := Time.get_time_dict_from_system()
	var old_hour := current_hour
	current_hour = time_dict.hour

	if current_hour != old_hour:
		hour_changed.emit(current_hour)
		_update_period()


func _update_period() -> void:
	var old_period := current_period

	if current_hour >= 6 and current_hour < 12:
		current_period = TimePeriod.MORNING
	elif current_hour >= 12 and current_hour < 17:
		current_period = TimePeriod.AFTERNOON
	elif current_hour >= 17 and current_hour < 21:
		current_period = TimePeriod.EVENING
	else:
		current_period = TimePeriod.NIGHT

	if current_period != old_period:
		time_of_day_changed.emit(get_period_name())


func get_period_name() -> String:
	match current_period:
		TimePeriod.MORNING:
			return "morning"
		TimePeriod.AFTERNOON:
			return "afternoon"
		TimePeriod.EVENING:
			return "evening"
		TimePeriod.NIGHT:
			return "night"
	return "day"


func get_greeting() -> String:
	match current_period:
		TimePeriod.MORNING:
			return "Good morning"
		TimePeriod.AFTERNOON:
			return "Good afternoon"
		TimePeriod.EVENING:
			return "Good evening"
		TimePeriod.NIGHT:
			return "Hello, night owl"
	return "Hello"


func is_busy_hour() -> bool:
	# Morning rush (7-9) and afternoon pick-me-up (14-16)
	return current_hour in [7, 8, 9, 14, 15, 16]


func get_ambient_modifier() -> float:
	# Returns a modifier for ambient lighting/mood based on time
	match current_period:
		TimePeriod.MORNING:
			return 1.0  # Bright
		TimePeriod.AFTERNOON:
			return 0.95
		TimePeriod.EVENING:
			return 0.7  # Warm, dimmer
		TimePeriod.NIGHT:
			return 0.4  # Cozy, dark
	return 1.0
