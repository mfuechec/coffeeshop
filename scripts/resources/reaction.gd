@tool
class_name Reaction extends Resource
## A player reaction choice in dialogue

## Unique identifier for this reaction
@export var id: String = ""

## Display text shown to player (e.g., "That's great!", "Tell me more")
@export var label: String = ""

## Emotional tone of the reaction
@export_enum("supportive", "curious", "dismissive", "humorous", "neutral") var tone: String = "neutral"

## Effects applied when this reaction is chosen
## Keys: "relationship" (int), "mood" (String), "memory" (String), "flag" (String)
@export var effects: Dictionary = {}

## Optional: ID of next dialogue line to show (for branching)
@export var next_line_id: String = ""

## Optional: Condition that must be true for this reaction to be available
## Format: "relationship >= 2" or "has_memory:job_interview"
@export var condition: String = ""


func is_available(customer: Dictionary) -> bool:
	if condition.is_empty():
		return true
	return _evaluate_condition(customer)


func _evaluate_condition(customer: Dictionary) -> bool:
	# Simple condition parser
	if condition.begins_with("relationship"):
		var parts := condition.split(" ")
		if parts.size() >= 3:
			var op := parts[1]
			var value := int(parts[2])
			var rel: int = customer.get("relationship_level", 0)
			match op:
				">=": return rel >= value
				">": return rel > value
				"<=": return rel <= value
				"<": return rel < value
				"==": return rel == value
	elif condition.begins_with("has_memory:"):
		var memory_key := condition.substr(11)
		var facts: Array = customer.get("remembered_facts", [])
		return memory_key in facts
	elif condition.begins_with("has_flag:"):
		var flag_key := condition.substr(9)
		var flags: Dictionary = customer.get("life_flags", {})
		return flags.get(flag_key, false)

	return true


func apply_effects(customer: Dictionary) -> void:
	for key: String in effects:
		match key:
			"relationship":
				customer["relationship_level"] = customer.get("relationship_level", 0) + int(effects[key])
			"mood":
				customer["mood"] = effects[key]
			"memory":
				var facts: Array = customer.get("remembered_facts", [])
				if effects[key] not in facts:
					facts.append(effects[key])
				customer["remembered_facts"] = facts
			"flag":
				var flags: Dictionary = customer.get("life_flags", {})
				flags[effects[key]] = true
				customer["life_flags"] = flags
