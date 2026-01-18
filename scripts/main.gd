extends Control
## Main game scene controller

@onready var money_label: Label = $UI/TopBar/MoneyLabel
@onready var reputation_label: Label = $UI/TopBar/ReputationLabel
@onready var dialogue_text: RichTextLabel = $UI/DialoguePanel/VBox/DialogueText
@onready var choices_container: HBoxContainer = $UI/DialoguePanel/VBox/ChoicesContainer
@onready var queue_label: Label = $UI/QueueIndicator/QueueLabel
@onready var customer_sprite: Sprite2D = $ShopView/CustomerArea/CustomerSprite

var current_customer: Dictionary = {}
var dialogue_state: String = "idle"


func _ready() -> void:
	# Connect signals
	GameManager.customer_served.connect(_on_customer_served)
	CustomerManager.customer_arrived.connect(_on_customer_arrived)
	CustomerManager.queue_updated.connect(_update_queue_display)
	TimeManager.time_of_day_changed.connect(_on_time_changed)

	_update_ui()
	_show_welcome_message()


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
	dialogue_text.text = "%s! Your coffee shop is open.\nCustomers will drop by throughout the day." % greeting
	_clear_choices()


func _on_customer_arrived(customer: Dictionary) -> void:
	if current_customer.is_empty():
		_greet_customer(customer)


func _greet_customer(customer: Dictionary) -> void:
	current_customer = customer
	dialogue_state = "greeting"

	# Show customer (placeholder - would be actual sprite)
	customer_sprite.modulate = Color.WHITE

	var greeting_text := ""
	if customer.is_returning:
		greeting_text = "[b]%s[/b] is back!\n" % customer.name
		if customer.relationship_level > 2:
			greeting_text += "\"Hey! The usual, please.\""
		else:
			greeting_text += "\"Hi again! Can I get a %s?\"" % customer.order
	else:
		greeting_text = "A new customer approaches!\n"
		greeting_text += "[b]%s[/b]: \"Hi! Could I get a %s, please?\"" % [customer.name, customer.order]

	dialogue_text.text = greeting_text
	_show_order_choices()


func _show_order_choices() -> void:
	_clear_choices()

	# Add drink buttons
	var drinks := ["Espresso", "Latte", "Cappuccino", "Americano", "Mocha"]
	for drink in drinks:
		var btn := Button.new()
		btn.text = drink
		btn.pressed.connect(_on_drink_selected.bind(drink))
		choices_container.add_child(btn)


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()


func _on_drink_selected(drink: String) -> void:
	var result := CustomerManager.serve_current_customer(drink)
	if result.is_empty():
		return

	var correct := drink == result.order
	GameManager.serve_customer(result, correct)


func _on_customer_served(customer_data: Dictionary) -> void:
	current_customer = {}
	customer_sprite.modulate = Color.TRANSPARENT
	dialogue_state = "served"

	# Show result
	var message := ""
	if customer_data.order == customer_data.get("given_order", customer_data.order):
		message = "[b]%s[/b]: \"Perfect, thank you!\"\n[i]+$%d[/i]" % [customer_data.name, customer_data.order_price]
	else:
		message = "[b]%s[/b]: \"Um... this isn't what I ordered.\"\n[i]+$%d (no tip)[/i]" % [customer_data.name, customer_data.order_price]

	dialogue_text.text = message
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
	dialogue_text.text = messages.pick_random()
	_clear_choices()


func _on_time_changed(period: String) -> void:
	var period_messages := {
		"morning": "The morning rush is starting. Time for coffee!",
		"afternoon": "The afternoon lull settles in.",
		"evening": "The evening crowd trickles in for their last cup.",
		"night": "Late night visitors are rare, but special."
	}

	if dialogue_state == "idle" and current_customer.is_empty():
		dialogue_text.text = period_messages.get(period, "")
