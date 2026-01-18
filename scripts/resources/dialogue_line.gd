@tool
class_name DialogueLine extends Resource
## A single line of dialogue with optional player reactions

## Unique identifier for this line (used for branching)
@export var id: String = ""

## Who is speaking: "customer" or "narrator"
@export_enum("customer", "narrator") var speaker: String = "customer"

## The dialogue text. Supports placeholders: {name}, {drink}, {job}, {mood}
@export_multiline var text: String = ""

## Player reactions available after this line (only for customer lines)
@export var reactions: Array = []

## Optional condition for this line to appear
## Format: "relationship >= 2" or "has_memory:some_fact"
@export var condition: String = ""

## If true, this is the end of the conversation branch
@export var ends_conversation: bool = false

## Optional: auto-advance to this line ID after display (for narrator lines)
@export var next_line_id: String = ""


func get_formatted_text(customer: Dictionary) -> String:
	var result: String = text

	# Replace placeholders
	result = result.replace("{name}", customer.get("name", "Customer"))
	result = result.replace("{drink}", customer.get("favorite_drink", "coffee"))
	result = result.replace("{order}", customer.get("order", "coffee"))
	result = result.replace("{job}", customer.get("job", "their job"))
	result = result.replace("{mood}", customer.get("mood", "okay"))

	# Replace personality-specific placeholders
	var personality: String = customer.get("personality", "neutral")
	result = result.replace("{personality}", personality)

	# Replace memory references: {memory:key:default}
	var memory_regex := RegEx.new()
	memory_regex.compile("\\{memory:([^:}]+):?([^}]*)\\}")
	var matches: Array = memory_regex.search_all(result)
	for m in matches:
		var key: String = m.get_string(1)
		var default_val: String = m.get_string(2) if m.get_string(2) else "something"
		var facts: Array = customer.get("remembered_facts", [])
		var value: String = default_val
		for fact in facts:
			if str(fact).begins_with(key + ":"):
				value = str(fact).substr(key.length() + 1)
				break
		result = result.replace(m.get_string(), value)

	return result


func is_available(customer: Dictionary) -> bool:
	if condition.is_empty():
		return true
	return _evaluate_condition(customer)


func _evaluate_condition(customer: Dictionary) -> bool:
	if condition.begins_with("relationship"):
		var parts: PackedStringArray = condition.split(" ")
		if parts.size() >= 3:
			var op: String = parts[1]
			var value: int = int(parts[2])
			var rel: int = customer.get("relationship_level", 0)
			match op:
				">=": return rel >= value
				">": return rel > value
				"<=": return rel <= value
				"<": return rel < value
				"==": return rel == value
	elif condition.begins_with("has_memory:"):
		var memory_key: String = condition.substr(11)
		var facts: Array = customer.get("remembered_facts", [])
		return memory_key in facts
	elif condition.begins_with("!has_memory:"):
		var memory_key: String = condition.substr(12)
		var facts: Array = customer.get("remembered_facts", [])
		return memory_key not in facts
	elif condition.begins_with("has_flag:"):
		var flag_key: String = condition.substr(9)
		var flags: Dictionary = customer.get("life_flags", {})
		return flags.get(flag_key, false)
	elif condition.begins_with("personality:"):
		var expected: String = condition.substr(12)
		return customer.get("personality", "") == expected
	elif condition.begins_with("mood:"):
		var expected: String = condition.substr(5)
		return customer.get("mood", "neutral") == expected

	return true


func get_available_reactions(customer: Dictionary) -> Array:
	var available: Array = []
	for reaction in reactions:
		if reaction.has_method("is_available") and reaction.is_available(customer):
			available.append(reaction)
	return available
