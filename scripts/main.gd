extends Control
## Main game scene controller

@onready var money_label: Label = $UI/TopBar/MoneyLabel
@onready var reputation_label: Label = $UI/TopBar/ReputationLabel
@onready var dialogue_panel: Panel = $UI/DialoguePanel
@onready var queue_label: Label = $UI/QueueIndicator/QueueLabel
@onready var customer_avatar: Control = $ShopView/CustomerArea/CustomerAvatar
@onready var drink_station: Control = $UI/DrinkStation
@onready var background: Control = $Background
@onready var background_image: TextureRect = $BackgroundImage
@onready var theme_button: Button = $UI/TopBar/ThemeButton
@onready var debug_button: Button = $UI/TopBar/DebugButton
@onready var window_viewport: Control = $WindowViewport
@onready var window_clouds: Node2D = $WindowViewport/WindowClouds
@onready var weather_effects: Node2D = $WindowViewport/WeatherEffects
@onready var passerby_spawner: Node2D = $WindowViewport/PasserbySpawner
@onready var window_debug: Control = $WindowDebugOverlay

var current_customer: Dictionary = {}
var dialogue_state: String = "idle"
var _awaiting_order: bool = false


func _ready() -> void:
	# Connect signals
	GameManager.customer_served.connect(_on_customer_served)
	CustomerManager.customer_arrived.connect(_on_customer_arrived)
	CustomerManager.queue_updated.connect(_update_queue_display)
	TimeManager.time_of_day_changed.connect(_on_time_changed)
	drink_station.drink_made.connect(_on_drink_made)

	# Connect to DialogueManager signals
	DialogueManager.conversation_ended.connect(_on_dialogue_ended)

	# Connect theme button
	if theme_button:
		theme_button.pressed.connect(_on_theme_button_pressed)

	# Connect debug button
	if debug_button:
		debug_button.pressed.connect(_on_debug_button_pressed)

	# Connect background theme changes
	if background_image:
		background_image.shop_theme_changed.connect(_on_background_theme_changed)

	# Setup window viewport after first frame
	await get_tree().process_frame
	_setup_window_viewport()

	# Connect debug overlay to background manager
	if window_debug and background_image:
		window_debug.set_background_manager(background_image)

	# Connect resize and time signals
	resized.connect(_on_resized)
	if background_image:
		background_image.resized.connect(_on_background_resized)
	TimeManager.time_of_day_changed.connect(_on_time_of_day_changed_for_effects)

	_update_ui()
	_show_welcome_message()


func _on_resized() -> void:
	await get_tree().process_frame
	_setup_window_viewport()


func _on_background_resized() -> void:
	# Background image size changed, update window viewport
	_setup_window_viewport()


func _on_time_of_day_changed_for_effects(period: String) -> void:
	if window_clouds:
		window_clouds.set_night_mode(period == "night")


func _setup_window_viewport() -> void:
	if not background_image:
		return

	# Get the combined window bounds from the background manager
	var window_rect: Rect2 = background_image.get_combined_window_bounds()

	# Position and size the clipping viewport to match the window area
	if window_viewport:
		window_viewport.position = window_rect.position
		window_viewport.size = window_rect.size

	# Pass local bounds (relative to viewport) to children
	var local_rect := Rect2(Vector2.ZERO, window_rect.size)

	if window_clouds:
		window_clouds.set_window_size(window_rect.size)
		window_clouds.set_night_mode(TimeManager.get_period_name() == "night")

	if weather_effects:
		weather_effects.set_window_bounds(local_rect)

	if passerby_spawner:
		passerby_spawner.set_window_bounds(local_rect)


func _on_theme_button_pressed() -> void:
	if background_image:
		background_image.cycle_theme()


func _on_debug_button_pressed() -> void:
	print("Debug button pressed, window_debug=", window_debug)
	if window_debug:
		window_debug.toggle_debug()
	else:
		print("ERROR: window_debug is null!")


func _on_background_theme_changed(theme_name: String) -> void:
	# Update window viewport for new theme's window positions
	_setup_window_viewport()
	dialogue_panel.show_message("Theme changed to: %s" % theme_name)


func _process(_delta: float) -> void:
	# Reduce processing when in idle mode
	if GameManager.idle_mode:
		return

	_update_ui()


func _update_ui() -> void:
	money_label.text = "$%d" % GameManager.money
	reputation_label.text = "★ %d" % GameManager.reputation


func _update_queue_display() -> void:
	queue_label.text = "Queue: %d" % CustomerManager.get_queue_size()


func _show_welcome_message() -> void:
	var greeting := TimeManager.get_greeting()
	dialogue_panel.show_message("%s! Your coffee shop is open.\nCustomers will drop by throughout the day." % greeting)


func _on_customer_arrived(customer: Dictionary) -> void:
	if current_customer.is_empty():
		_greet_customer(customer)


func _greet_customer(customer: Dictionary) -> void:
	current_customer = customer
	dialogue_state = "greeting"
	_awaiting_order = false

	# Hide drink station from any previous interaction
	drink_station.hide_station()

	# Show customer avatar
	customer_avatar.set_customer(customer)

	# Start conversation through DialogueManager
	DialogueManager.start_conversation(customer)


func _on_dialogue_ended(customer: Dictionary) -> void:
	print("main._on_dialogue_ended called, current_customer empty: %s, _awaiting_order: %s" % [current_customer.is_empty(), _awaiting_order])
	# Conversation ended, show the drink station for order
	if not current_customer.is_empty() and not _awaiting_order:
		_awaiting_order = true
		_show_order_phase()


func _show_order_phase() -> void:
	# Show the drink station for making drinks
	drink_station.show_station()


func _clear_choices() -> void:
	drink_station.hide_station()


func _on_drink_made(drink: String) -> void:
	if current_customer.is_empty():
		return

	var result: Dictionary = CustomerManager.serve_current_customer(drink)
	if result.is_empty():
		return

	var correct: bool = drink == result.order
	GameManager.serve_customer(result, correct)
	drink_station.hide_station()


func _on_customer_served(customer_data: Dictionary) -> void:
	current_customer = {}
	_awaiting_order = false
	customer_avatar.clear_customer()
	dialogue_state = "served"

	# Show result
	var message := ""
	if customer_data.order == customer_data.get("given_order", customer_data.order):
		message = "[b]%s[/b]: \"Perfect, thank you!\"\n[i]+$%d[/i]" % [customer_data.name, customer_data.order_price]
	else:
		message = "[b]%s[/b]: \"Um... this isn't what I ordered.\"\n[i]+$%d (no tip)[/i]" % [customer_data.name, customer_data.order_price]

	dialogue_panel.show_message(message)
	_clear_choices()

	# Check for next customer after a delay
	await get_tree().create_timer(2.0).timeout
	_check_next_customer()


func _check_next_customer() -> void:
	var next := CustomerManager.get_current_customer()
	if not next.is_empty():
		_greet_customer(next)
	else:
		_show_idle_message()


func _show_idle_message() -> void:
	var messages := [
		"The shop is quiet... a good time to tidy up.",
		"Soft music plays in the background.",
		"You wipe down the counter while waiting.",
		"The coffee machine hums gently.",
		"Sunlight streams through the window."
	]
	dialogue_panel.show_message(messages.pick_random())
	_clear_choices()


func _on_time_changed(period: String) -> void:
	var period_messages := {
		"morning": "The morning rush is starting. Time for coffee!",
		"afternoon": "The afternoon lull settles in.",
		"evening": "The evening crowd trickles in for their last cup.",
		"night": "Late night visitors are rare, but special."
	}

	if dialogue_state == "idle" and current_customer.is_empty():
		dialogue_panel.show_message(period_messages.get(period, ""))
