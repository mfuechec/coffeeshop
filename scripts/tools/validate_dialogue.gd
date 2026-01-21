@tool
extends SceneTree
## Dialogue validation script - run with: godot --headless --script scripts/tools/validate_dialogue.gd

const DIALOGUE_DIR := "res://data/dialogue/"

const VALID_CATEGORIES := ["greeting", "smalltalk", "news", "story_beat", "farewell", "order"]
const VALID_TONES := ["supportive", "curious", "dismissive", "humorous", "neutral"]
const VALID_SPEAKERS := ["customer", "narrator"]
const VALID_PLACEHOLDERS := ["{name}", "{drink}", "{order}", "{job}", "{mood}", "{personality}"]
const VALID_PERSONALITIES := ["shy", "chatty", "grumpy", "cheerful", "mysterious", "tired", "anxious", "chill"]

var errors: Array[String] = []
var warnings: Array[String] = []
var templates_checked: int = 0


func _init() -> void:
	print("\n========================================")
	print("  DIALOGUE VALIDATION SCRIPT")
	print("========================================\n")

	_validate_all_dialogues()
	_print_results()

	quit()


func _validate_all_dialogues() -> void:
	var dir := DirAccess.open(DIALOGUE_DIR)
	if not dir:
		errors.append("Cannot open dialogue directory: " + DIALOGUE_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			_validate_template_file(DIALOGUE_DIR + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()


func _validate_template_file(path: String) -> void:
	print("Checking: " + path.get_file())
	templates_checked += 1

	var resource = ResourceLoader.load(path)
	if not resource:
		errors.append("[%s] Failed to load resource" % path.get_file())
		return

	if not resource is DialogueTemplate:
		errors.append("[%s] Not a DialogueTemplate resource" % path.get_file())
		return

	var template: DialogueTemplate = resource
	_validate_template(template, path.get_file())


func _validate_template(template: DialogueTemplate, file_name: String) -> void:
	var prefix := "[%s]" % file_name

	# Check ID
	if template.id.is_empty():
		errors.append("%s Missing template ID" % prefix)

	# Check category
	if template.category not in VALID_CATEGORIES:
		errors.append("%s Invalid category '%s'. Valid: %s" % [prefix, template.category, VALID_CATEGORIES])

	# Check weight
	if template.weight <= 0:
		warnings.append("%s Weight is <= 0 (template will never be selected)" % prefix)

	# Check lines
	if template.lines.is_empty():
		errors.append("%s No dialogue lines defined" % prefix)
	else:
		for i in range(template.lines.size()):
			var line = template.lines[i]
			if line is DialogueLine:
				_validate_line(line, prefix, i)
			else:
				errors.append("%s Line %d is not a DialogueLine resource" % [prefix, i])

	# Check personality weights
	for personality in template.personality_weights.keys():
		if personality not in VALID_PERSONALITIES:
			warnings.append("%s Unknown personality in weights: '%s'" % [prefix, personality])

	# Check relationship bounds
	if template.min_relationship > template.max_relationship and template.max_relationship >= 0:
		errors.append("%s min_relationship (%d) > max_relationship (%d)" % [prefix, template.min_relationship, template.max_relationship])


func _validate_line(line: DialogueLine, prefix: String, index: int) -> void:
	var line_prefix := "%s Line %d" % [prefix, index]

	# Check ID
	if line.id.is_empty():
		warnings.append("%s: Missing line ID (needed for branching)" % line_prefix)

	# Check speaker
	if line.speaker not in VALID_SPEAKERS:
		errors.append("%s: Invalid speaker '%s'. Valid: %s" % [line_prefix, line.speaker, VALID_SPEAKERS])

	# Check text
	if line.text.is_empty():
		errors.append("%s: Empty dialogue text" % line_prefix)
	else:
		_validate_placeholders(line.text, line_prefix)

	# Check reactions
	if line.speaker == "customer" and line.reactions.is_empty() and not line.ends_conversation:
		warnings.append("%s: Customer line with no reactions and doesn't end conversation" % line_prefix)

	for j in range(line.reactions.size()):
		var reaction = line.reactions[j]
		if reaction is Reaction:
			_validate_reaction(reaction, line_prefix, j)
		else:
			errors.append("%s: Reaction %d is not a Reaction resource" % [line_prefix, j])

	# Check condition syntax
	if not line.condition.is_empty():
		_validate_condition(line.condition, line_prefix)


func _validate_reaction(reaction: Reaction, prefix: String, index: int) -> void:
	var reaction_prefix := "%s Reaction %d" % [prefix, index]

	# Check ID
	if reaction.id.is_empty():
		warnings.append("%s: Missing reaction ID" % reaction_prefix)

	# Check label
	if reaction.label.is_empty():
		errors.append("%s: Empty reaction label" % reaction_prefix)

	# Check tone
	if reaction.tone not in VALID_TONES:
		errors.append("%s: Invalid tone '%s'. Valid: %s" % [reaction_prefix, reaction.tone, VALID_TONES])

	# Check effects
	for effect_key in reaction.effects.keys():
		if effect_key not in ["relationship", "mood", "memory", "flag"]:
			warnings.append("%s: Unknown effect key '%s'" % [reaction_prefix, effect_key])

	# Check condition syntax
	if not reaction.condition.is_empty():
		_validate_condition(reaction.condition, reaction_prefix)


func _validate_placeholders(text: String, prefix: String) -> void:
	# Find all {placeholder} patterns
	var regex := RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	var matches := regex.search_all(text)

	for m in matches:
		var placeholder := "{" + m.get_string(1) + "}"

		# Check for memory placeholder pattern {memory:key:default}
		if placeholder.begins_with("{memory:"):
			continue  # Valid memory placeholder

		# Check standard placeholders
		if placeholder not in VALID_PLACEHOLDERS:
			warnings.append("%s: Unknown placeholder '%s'. Valid: %s" % [prefix, placeholder, VALID_PLACEHOLDERS])


func _validate_condition(condition: String, prefix: String) -> void:
	# Valid condition formats:
	# - "relationship >= N"
	# - "has_memory:key"
	# - "!has_memory:key"
	# - "has_flag:key"
	# - "personality:type"
	# - "mood:type"

	var valid_prefixes := ["relationship", "has_memory:", "!has_memory:", "has_flag:", "!has_flag:", "personality:", "mood:"]
	var is_valid := false

	for valid_prefix in valid_prefixes:
		if condition.begins_with(valid_prefix):
			is_valid = true
			break

	if not is_valid:
		warnings.append("%s: Unrecognized condition format '%s'" % [prefix, condition])


func _print_results() -> void:
	print("\n========================================")
	print("  VALIDATION RESULTS")
	print("========================================")
	print("Templates checked: %d" % templates_checked)
	print("")

	if errors.is_empty() and warnings.is_empty():
		print("SUCCESS: All dialogue templates are valid!")
	else:
		if not errors.is_empty():
			print("ERRORS (%d):" % errors.size())
			for error in errors:
				print("  ERROR: " + error)
			print("")

		if not warnings.is_empty():
			print("WARNINGS (%d):" % warnings.size())
			for warning in warnings:
				print("  WARN: " + warning)

	print("\n========================================\n")
