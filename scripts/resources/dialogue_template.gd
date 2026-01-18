@tool
class_name DialogueTemplate extends Resource
## A template for a type of conversation (greeting, smalltalk, story beat, etc.)

## Unique identifier for this template
@export var id: String = ""

## Category of dialogue
@export_enum("greeting", "smalltalk", "news", "story_beat", "farewell", "order") var category: String = "smalltalk"

## Base weight for random selection (higher = more likely)
@export var weight: float = 1.0

## The dialogue lines in this template
@export var lines: Array = []

## Personality-specific weight modifiers (e.g., {"chatty": 2.0, "shy": 0.5})
@export var personality_weights: Dictionary = {}

## Minimum relationship level required
@export var min_relationship: int = -1

## Maximum relationship level (use -1 for no max)
@export var max_relationship: int = -1

## Required memories for this dialogue to be available
@export var required_memories: Array[String] = []

## Memories that block this dialogue from appearing
@export var blocked_by_memories: Array[String] = []

## If set, starting this dialogue triggers a storyline
@export var triggers_storyline: String = ""

## Tags for filtering (e.g., ["morning", "weather", "work"])
@export var tags: Array[String] = []


func is_available(customer: Dictionary) -> bool:
	var rel: int = customer.get("relationship_level", 0)

	# Check relationship bounds
	if rel < min_relationship:
		return false
	if max_relationship >= 0 and rel > max_relationship:
		return false

	# Check required memories
	var facts: Array = customer.get("remembered_facts", [])
	for required in required_memories:
		if required not in facts:
			return false

	# Check blocked memories
	for blocked in blocked_by_memories:
		if blocked in facts:
			return false

	return true


func get_weight_for_customer(customer: Dictionary) -> float:
	var final_weight: float = weight
	var personality: String = customer.get("personality", "")

	if personality in personality_weights:
		final_weight *= personality_weights[personality]

	# Boost weight for higher relationships (they get more varied dialogue)
	var rel: int = customer.get("relationship_level", 0)
	if rel >= 3:
		final_weight *= 1.2

	return final_weight


func get_starting_line() -> Resource:
	if lines.is_empty():
		return null
	return lines[0]


func get_line_by_id(line_id: String) -> Resource:
	for line in lines:
		if "id" in line and line.id == line_id:
			return line
	return null


func get_all_available_lines(customer: Dictionary) -> Array:
	var available: Array = []
	for line in lines:
		if line.has_method("is_available") and line.is_available(customer):
			available.append(line)
	return available
