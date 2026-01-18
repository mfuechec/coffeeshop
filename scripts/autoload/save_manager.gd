extends Node
## Handles saving and loading game data

const SAVE_PATH := "user://save_data.json"
const AUTO_SAVE_INTERVAL := 60.0  # Auto-save every minute

var auto_save_timer: Timer


func _ready() -> void:
	_setup_auto_save()
	load_game()


func _setup_auto_save() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	auto_save_timer.timeout.connect(save_game)
	add_child(auto_save_timer)
	auto_save_timer.start()


func save_game() -> void:
	var save_data := {
		"version": ProjectSettings.get_setting("application/config/version"),
		"timestamp": Time.get_unix_time_from_system(),
		"game": {
			"money": GameManager.money,
			"reputation": GameManager.reputation,
			"days_open": GameManager.days_open,
		},
		"customers": {
			"known": CustomerManager.known_customers,
		},
		"settings": {
			"notifications": GameManager.notification_enabled,
			"idle_notifications": GameManager.idle_notifications,
		}
	}

	var json_string := JSON.stringify(save_data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Game saved successfully")
	else:
		push_error("Failed to save game: %s" % FileAccess.get_open_error())


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, starting fresh")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to load save file")
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file")
		return

	var save_data: Dictionary = json.data

	# Restore game state
	if "game" in save_data:
		GameManager.money = save_data.game.get("money", 100)
		GameManager.reputation = save_data.game.get("reputation", 0)
		GameManager.days_open = save_data.game.get("days_open", 1)

	# Restore customers
	if "customers" in save_data:
		CustomerManager.known_customers = save_data.customers.get("known", {})

	# Restore settings
	if "settings" in save_data:
		GameManager.notification_enabled = save_data.settings.get("notifications", true)
		GameManager.idle_notifications = save_data.settings.get("idle_notifications", true)

	print("Game loaded successfully")


func _notification(what: int) -> void:
	# Save when the game is about to close
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()
