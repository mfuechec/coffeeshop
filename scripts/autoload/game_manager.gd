extends Node
## Central game state manager
## Handles core game loop, pause states, and global game settings

signal game_paused
signal game_resumed
signal customer_served(customer_data: Dictionary)
signal relationship_updated(customer_id: String, new_level: int)

enum GameState { RUNNING, PAUSED, IDLE, CUSTOMER_WAITING }

var current_state: GameState = GameState.IDLE
var is_window_focused: bool = true
var idle_mode: bool = false  # True when minimized/unfocused - reduces processing

# Player stats
var money: int = 100
var reputation: int = 0
var days_open: int = 1

# Settings
var notification_enabled: bool = true
var idle_notifications: bool = true  # Notify when customer arrives while minimized


func _ready() -> void:
	get_tree().root.focus_entered.connect(_on_window_focus_entered)
	get_tree().root.focus_exited.connect(_on_window_focus_exited)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_window_focus_entered() -> void:
	is_window_focused = true
	idle_mode = false
	game_resumed.emit()


func _on_window_focus_exited() -> void:
	is_window_focused = false
	idle_mode = true
	game_paused.emit()


func add_money(amount: int) -> void:
	money += amount


func add_reputation(amount: int) -> void:
	reputation += amount


func serve_customer(customer_data: Dictionary, order_correct: bool) -> void:
	var tip := 0
	if order_correct:
		tip = randi_range(1, 5)
		add_reputation(1)
	else:
		add_reputation(-1)

	add_money(customer_data.get("order_price", 3) + tip)
	customer_served.emit(customer_data)


func set_state(new_state: GameState) -> void:
	current_state = new_state
