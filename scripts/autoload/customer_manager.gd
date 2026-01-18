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

const JOBS := [
	"teacher", "artist", "office worker", "nurse", "student", "freelancer",
	"barista", "writer", "developer", "designer", "accountant", "chef",
	"musician", "librarian", "therapist", "retired", "between jobs"
]

const RELATIONSHIP_STATUSES := ["single", "dating", "married", "complicated", "divorced", "widowed"]

const MOODS := ["happy", "stressed", "excited", "sad", "neutral", "anxious", "tired", "hopeful"]

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


func _input(event: InputEvent) -> void:
	# Debug: Press F1 to spawn a customer immediately
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		spawn_customer_now()


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


func spawn_customer_now() -> void:
	## Debug function to spawn a customer immediately
	if customer_queue.size() < max_queue_size:
		var customer := _generate_customer()
		customer_queue.append(customer)
		customer_arrived.emit(customer)
		queue_updated.emit()
		print("Debug: Spawned customer - %s" % customer.name)


func _generate_customer() -> Dictionary:
	# 30% chance to be a returning customer if we know some
	if not known_customers.is_empty() and randf() < 0.3:
		var returning_id: String = known_customers.keys().pick_random()
		var returning: Dictionary = known_customers[returning_id].duplicate(true)
		returning["is_returning"] = true
		returning["visits"] += 1
		# Update mood occasionally
		if randf() < 0.3:
			returning["mood"] = MOODS.pick_random()
		return returning

	# Generate new customer
	var customer_id: String = str(randi())
	var drink: Dictionary = DRINKS.pick_random()

	var customer := {
		# === Identity ===
		"id": customer_id,
		"name": FIRST_NAMES.pick_random(),
		"personality": PERSONALITIES.pick_random(),

		# === Order ===
		"favorite_drink": drink.name,
		"order": drink.name,
		"order_price": drink.price,

		# === Relationship ===
		"visits": 1,
		"relationship_level": 0,
		"remembered_facts": [],
		"is_returning": false,

		# === Life State ===
		"job": JOBS.pick_random(),
		"relationship_status": RELATIONSHIP_STATUSES.pick_random(),
		"mood": MOODS.pick_random(),
		"life_flags": {},

		# === Story Tracking ===
		"active_storylines": [],
		"completed_storylines": [],
		"last_visit_day": TimeManager.get_day() if TimeManager else 1,
		"consecutive_good_visits": 0,
		"consecutive_bad_visits": 0,

		# === Meta ===
		"arrival_time": Time.get_unix_time_from_system()
	}

	return customer


func _send_notification(customer: Dictionary) -> void:
	# Platform-specific notification
	var message := "%s is waiting at your coffee shop!" % customer.name
	DisplayServer.window_request_attention()
	print(message)  # Log for now until proper notifications implemented


func get_current_customer() -> Dictionary:
	if customer_queue.is_empty():
		return {}
	return customer_queue[0]


func serve_current_customer(order_given: String) -> Dictionary:
	if customer_queue.is_empty():
		return {}

	var customer: Dictionary = customer_queue.pop_front()
	var satisfied: bool = order_given == customer.order

	# Track order result for return value
	customer["given_order"] = order_given

	# Process order result and update relationship/consecutive visits
	_process_order_result(customer, satisfied)

	# Update last visit day
	customer["last_visit_day"] = TimeManager.get_day() if TimeManager else 1

	# Remember this customer
	known_customers[customer.id] = customer

	customer_left.emit(customer, satisfied)
	queue_updated.emit()

	return customer


func _process_order_result(customer: Dictionary, correct: bool) -> void:
	## Process the consequences of serving a correct or incorrect order
	if correct:
		customer["consecutive_good_visits"] = customer.get("consecutive_good_visits", 0) + 1
		customer["consecutive_bad_visits"] = 0

		# Relationship increases with good service
		if customer["consecutive_good_visits"] >= 3:
			customer["relationship_level"] = mini(customer.get("relationship_level", 0) + 1, 5)
			customer["consecutive_good_visits"] = 0  # Reset after relationship boost
		else:
			# Small chance of relationship boost even without streak
			if randf() < 0.3:
				customer["relationship_level"] = mini(customer.get("relationship_level", 0) + 1, 5)
	else:
		customer["consecutive_bad_visits"] = customer.get("consecutive_bad_visits", 0) + 1
		customer["consecutive_good_visits"] = 0

		# Relationship decreases with bad service
		customer["relationship_level"] = customer.get("relationship_level", 0) - 1

		# Extra penalty for multiple consecutive bad visits
		if customer["consecutive_bad_visits"] >= 2:
			customer["relationship_level"] -= 1

		# Check for lost customer
		if customer["relationship_level"] <= -2:
			_lose_customer(customer)


func _lose_customer(customer: Dictionary) -> void:
	## Handle a customer being lost due to poor service
	customer["relationship_level"] = -2
	# They might return someday with a "second chance" storyline
	# For now, just mark them as potentially lost
	customer["life_flags"]["lost_customer"] = true
	print("Lost customer: %s" % customer.name)


func add_customer_fact(customer_id: String, fact: String) -> void:
	if customer_id in known_customers:
		known_customers[customer_id].remembered_facts.append(fact)


func get_queue_size() -> int:
	return customer_queue.size()
