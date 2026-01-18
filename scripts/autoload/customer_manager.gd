extends Node
## Manages customer generation, queue, and relationship tracking

signal customer_arrived(customer: Dictionary)
signal customer_left(customer: Dictionary, satisfied: bool)
signal queue_updated

# Customer database - persisted customers the player has met
var known_customers: Dictionary = {}

# Current queue of waiting customers
var customer_queue: Array[Dictionary] = []
var max_queue_size: int = 3

# Customer generation
var spawn_timer: Timer
var min_spawn_time: float = 120.0  # 2 minutes minimum between customers
var max_spawn_time: float = 600.0  # 10 minutes maximum

# Name pools for generating customers
const FIRST_NAMES := [
	"Alex", "Sam", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Quinn",
	"Avery", "Charlie", "Blake", "Drew", "Elliot", "Finley", "Harper", "Hayden",
	"Jamie", "Kelly", "Lane", "Mackenzie", "Nico", "Parker", "Reese", "Sage"
]

const PERSONALITIES := ["shy", "chatty", "grumpy", "cheerful", "mysterious", "tired", "anxious", "chill"]

const DRINKS := [
	{"name": "Espresso", "price": 3},
	{"name": "Americano", "price": 4},
	{"name": "Latte", "price": 5},
	{"name": "Cappuccino", "price": 5},
	{"name": "Mocha", "price": 6},
	{"name": "Hot Chocolate", "price": 4},
	{"name": "Chai Latte", "price": 5},
	{"name": "Green Tea", "price": 3},
	{"name": "Iced Coffee", "price": 4},
	{"name": "Flat White", "price": 5}
]


func _ready() -> void:
	_setup_spawn_timer()


func _setup_spawn_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	_start_spawn_timer()


func _start_spawn_timer() -> void:
	var wait_time := randf_range(min_spawn_time, max_spawn_time)
	# Shorter waits when queue is empty
	if customer_queue.is_empty():
		wait_time *= 0.5
	spawn_timer.start(wait_time)


func _on_spawn_timer_timeout() -> void:
	if customer_queue.size() < max_queue_size:
		var customer := _generate_customer()
		customer_queue.append(customer)
		customer_arrived.emit(customer)
		queue_updated.emit()

		# Send notification if in idle mode
		if GameManager.idle_mode and GameManager.idle_notifications:
			_send_notification(customer)

	_start_spawn_timer()


func _generate_customer() -> Dictionary:
	# 30% chance to be a returning customer if we know some
	if not known_customers.is_empty() and randf() < 0.3:
		var returning_id: String = known_customers.keys().pick_random()
		var returning := known_customers[returning_id].duplicate(true)
		returning["is_returning"] = true
		return returning

	# Generate new customer
	var customer_id := str(randi())
	var drink: Dictionary = DRINKS.pick_random()

	var customer := {
		"id": customer_id,
		"name": FIRST_NAMES.pick_random(),
		"personality": PERSONALITIES.pick_random(),
		"favorite_drink": drink.name,
		"order": drink.name,
		"order_price": drink.price,
		"visits": 1,
		"relationship_level": 0,
		"remembered_facts": [],
		"is_returning": false,
		"arrival_time": Time.get_unix_time_from_system()
	}

	return customer


func _send_notification(customer: Dictionary) -> void:
	# Platform-specific notification
	var message := "%s is waiting at your coffee shop!" % customer.name
	OS.request_attention()
	# TODO: Implement proper system tray notifications


func get_current_customer() -> Dictionary:
	if customer_queue.is_empty():
		return {}
	return customer_queue[0]


func serve_current_customer(order_given: String) -> Dictionary:
	if customer_queue.is_empty():
		return {}

	var customer := customer_queue.pop_front()
	var satisfied := order_given == customer.order

	# Update relationship
	if satisfied:
		customer.relationship_level += 1

	# Remember this customer
	known_customers[customer.id] = customer

	customer_left.emit(customer, satisfied)
	queue_updated.emit()

	return customer


func add_customer_fact(customer_id: String, fact: String) -> void:
	if customer_id in known_customers:
		known_customers[customer_id].remembered_facts.append(fact)


func get_queue_size() -> int:
	return customer_queue.size()
