extends Node
## Manages customer conversations, reactions, and dialogue flow

# Preload resource scripts to ensure types are available
const DialogueTemplateScript := preload("res://scripts/resources/dialogue_template.gd")
const DialogueLineScript := preload("res://scripts/resources/dialogue_line.gd")
const ReactionScript := preload("res://scripts/resources/reaction.gd")

# Signals for UI and other systems to respond to
signal conversation_started(customer: Dictionary)
signal dialogue_line_ready(line: Resource, formatted_text: String, reactions: Array)
signal player_reacted(reaction: Resource, customer: Dictionary)
signal conversation_ended(customer: Dictionary)

# Dialogue template pools by category
var _templates_by_category: Dictionary = {}  # category -> Array
var _all_templates: Array = []

# Current conversation state
var _current_customer: Dictionary = {}
var _current_template: Resource = null
var _current_line: Resource = null
var _conversation_active: bool = false

# Path to dialogue resources
const DIALOGUE_PATH := "res://data/dialogue/"


func _ready() -> void:
	_load_all_templates()


func _load_all_templates() -> void:
	_templates_by_category.clear()
	_all_templates.clear()

	# Initialize category arrays
	for category in ["greeting", "smalltalk", "news", "story_beat", "farewell", "order"]:
		_templates_by_category[category] = []

	# Load all .tres files from dialogue directory
	var dir: DirAccess = DirAccess.open(DIALOGUE_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var template: Resource = load(DIALOGUE_PATH + file_name)
				if template and template.has_method("is_available"):
					_all_templates.append(template)
					var cat: String = template.category if "category" in template else ""
					if cat in _templates_by_category:
						_templates_by_category[cat].append(template)
			file_name = dir.get_next()
		dir.list_dir_end()

	print("DialogueManager: Loaded %d dialogue templates" % _all_templates.size())


## Start a conversation with a customer
func start_conversation(customer: Dictionary) -> void:
	_current_customer = customer
	_conversation_active = true

	# Select appropriate greeting based on relationship and history
	var template: Resource = _select_template("greeting", customer)
	if not template:
		# Fallback to basic greeting if no templates loaded
		_emit_fallback_greeting(customer)
		return

	_current_template = template
	_start_template(template, customer)

	conversation_started.emit(customer)


## Handle player selecting a reaction
func select_reaction(reaction: Resource) -> void:
	print("select_reaction called")
	if not _conversation_active or _current_customer.is_empty():
		print("  Aborted: conversation not active or no customer")
		return

	# Apply reaction effects
	if reaction.has_method("apply_effects"):
		reaction.apply_effects(_current_customer)

	player_reacted.emit(reaction, _current_customer)

	# Check for next line (branching)
	var next_line_id: String = reaction.next_line_id if "next_line_id" in reaction else ""
	print("  next_line_id: '%s'" % next_line_id)
	if not next_line_id.is_empty() and _current_template:
		var next_line: Resource = _current_template.get_line_by_id(next_line_id)
		if next_line:
			_show_line(next_line, _current_customer)
			return

	# Check if current line ends conversation
	var ends_conv: bool = _current_line.ends_conversation if _current_line and "ends_conversation" in _current_line else false
	print("  ends_conversation: %s" % ends_conv)
	if ends_conv:
		print("  Ending conversation")
		end_conversation()
		return

	# Otherwise, continue to next phase (smalltalk or order)
	print("  Calling _continue_conversation")
	_continue_conversation()


## End the current conversation
func end_conversation() -> void:
	if not _conversation_active:
		return

	_conversation_active = false
	conversation_ended.emit(_current_customer)

	_current_template = null
	_current_line = null


## Add smalltalk to the conversation
func add_smalltalk() -> void:
	if not _conversation_active:
		return

	var template: Resource = _select_template("smalltalk", _current_customer)
	if template:
		_start_template(template, _current_customer)
	else:
		# No smalltalk available, proceed to order
		_show_order_request()


## Show the order request phase
func show_order_phase() -> void:
	_show_order_request()


## Check if a conversation is active
func is_conversation_active() -> bool:
	return _conversation_active


## Get the current customer in conversation
func get_current_customer() -> Dictionary:
	return _current_customer


# === PRIVATE METHODS ===

func _select_template(category: String, customer: Dictionary) -> Resource:
	var templates: Array = _templates_by_category.get(category, [])
	if templates.is_empty():
		return null

	# Filter available templates
	var available: Array = []
	var total_weight: float = 0.0

	for template: Resource in templates:
		if template.is_available(customer):
			available.append(template)
			total_weight += template.get_weight_for_customer(customer)

	if available.is_empty():
		return null

	# Weighted random selection
	var roll: float = randf() * total_weight
	var current: float = 0.0

	for template: Resource in available:
		current += template.get_weight_for_customer(customer)
		if roll <= current:
			return template

	return available[0]  # Fallback


func _start_template(template: Resource, customer: Dictionary) -> void:
	_current_template = template

	# Check if this triggers a storyline
	var triggers: String = template.triggers_storyline if "triggers_storyline" in template else ""
	if not triggers.is_empty():
		# StorylineManager integration point
		pass

	var start_line: Resource = template.get_starting_line()
	if start_line:
		_show_line(start_line, customer)


func _show_line(line: Resource, customer: Dictionary) -> void:
	_current_line = line

	var formatted_text: String = line.get_formatted_text(customer)
	var available_reactions: Array = line.get_available_reactions(customer)

	# Debug: print reaction info
	print("Showing line: %s" % formatted_text)
	print("  Raw reactions in line: %d" % line.reactions.size())
	print("  Available reactions: %d" % available_reactions.size())

	dialogue_line_ready.emit(line, formatted_text, available_reactions)

	# If no reactions and auto-advance is set, continue
	var next_id: String = line.next_line_id if "next_line_id" in line else ""
	if available_reactions.is_empty() and not next_id.is_empty():
		await get_tree().create_timer(1.5).timeout
		var next: Resource = _current_template.get_line_by_id(next_id) if _current_template else null
		if next:
			_show_line(next, customer)


func _continue_conversation() -> void:
	# Decide what comes next based on relationship and randomness
	var rel: int = _current_customer.get("relationship_level", 0)

	# Higher relationship = more chance of additional smalltalk
	var smalltalk_chance: float = 0.3 + (rel * 0.1)
	smalltalk_chance = clampf(smalltalk_chance, 0.2, 0.7)

	print("_continue_conversation: rel=%d, smalltalk_chance=%.2f" % [rel, smalltalk_chance])

	var roll: float = randf()
	print("  Rolled: %.2f (need < %.2f for smalltalk)" % [roll, smalltalk_chance])

	# DEBUG: Force smalltalk for testing
	if true:  # Was: roll < smalltalk_chance
		# Check if we have unused smalltalk
		var template: Resource = _select_template("smalltalk", _current_customer)
		print("  Smalltalk template found: %s" % (template != null))
		if template and template != _current_template:
			print("  Starting smalltalk template!")
			_start_template(template, _current_customer)
			return

	# Proceed to order
	print("  Proceeding to order")
	_show_order_request()


func _show_order_request() -> void:
	# Create a simple order line
	var order_text: String = _generate_order_text(_current_customer)

	# Create a temporary line for the order
	var order_line: Resource = DialogueLineScript.new()
	order_line.speaker = "customer"
	order_line.text = order_text
	order_line.ends_conversation = true

	_current_line = order_line
	dialogue_line_ready.emit(order_line, order_text, [])

	# Auto-end conversation after showing order (so drink station appears)
	await get_tree().create_timer(1.5).timeout
	end_conversation()


func _generate_order_text(customer: Dictionary) -> String:
	var order: String = customer.get("order", "coffee")
	var personality: String = customer.get("personality", "neutral")
	var rel: int = customer.get("relationship_level", 0)
	var visits: int = customer.get("visits", 1)

	# Returning customer with high relationship might order "the usual"
	if visits > 3 and rel >= 2 and randf() < 0.5:
		match personality:
			"chatty":
				return "You know what I want - the usual! A %s, please." % order
			"shy":
				return "Um... the usual? A %s?" % order
			"chill":
				return "The usual, please. %s." % order
			_:
				return "I'll have the usual - %s." % order

	# Standard order variations by personality
	match personality:
		"chatty":
			var options: Array[String] = [
				"Oh! I've been thinking about a %s all morning!" % order,
				"Let me get a %s - I really need it today!" % order,
				"A %s would be perfect right now, don't you think?" % order,
			]
			return options[randi() % options.size()]
		"shy":
			var options: Array[String] = [
				"Could I... get a %s, please?" % order,
				"Um, a %s, if that's okay?" % order,
				"I'd like a %s..." % order,
			]
			return options[randi() % options.size()]
		"grumpy":
			var options: Array[String] = [
				"%s." % order.capitalize(),
				"Just a %s." % order,
				"I need a %s. Please." % order,
			]
			return options[randi() % options.size()]
		"cheerful":
			var options: Array[String] = [
				"A %s would make my day even better!" % order,
				"I'd love a %s, please!" % order,
				"Ooh, a %s sounds wonderful!" % order,
			]
			return options[randi() % options.size()]
		"tired":
			var options: Array[String] = [
				"I really need a %s right now..." % order,
				"*yawn* A %s, please..." % order,
				"Just... a %s. Strong if possible." % order,
			]
			return options[randi() % options.size()]
		"anxious":
			var options: Array[String] = [
				"Um, can I get a %s? Is that okay?" % order,
				"A %s, please - sorry, am I holding up the line?" % order,
				"I'll have a %s, if you're not too busy..." % order,
			]
			return options[randi() % options.size()]
		_:
			return "I'll have a %s, please." % order


func _emit_fallback_greeting(customer: Dictionary) -> void:
	var name_str: String = customer.get("name", "Customer")
	var is_returning: bool = customer.get("is_returning", false)
	var rel: int = customer.get("relationship_level", 0)

	var text: String = ""
	if is_returning and rel >= 2:
		text = "Hey! Good to see you again."
	elif is_returning:
		text = "Hi again!"
	else:
		text = "Hi there!"

	var fallback_line: Resource = DialogueLineScript.new()
	fallback_line.speaker = "customer"
	fallback_line.text = text
	fallback_line.ends_conversation = false

	_current_line = fallback_line
	dialogue_line_ready.emit(fallback_line, text, [])

	# Auto-proceed to order after a moment
	await get_tree().create_timer(1.0).timeout
	_show_order_request()
