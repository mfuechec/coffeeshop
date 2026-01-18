extends Panel
## UI component for displaying dialogue and reaction choices

signal reaction_selected(reaction: Resource)
signal conversation_ended()

@onready var dialogue_label: RichTextLabel = $VBox/DialogueText
@onready var reactions_container: HBoxContainer = $VBox/ChoicesContainer

# Button styling
const BUTTON_COLORS := {
	"supportive": Color(0.3, 0.6, 0.4),  # Green-ish
	"curious": Color(0.3, 0.4, 0.6),     # Blue-ish
	"dismissive": Color(0.5, 0.35, 0.35), # Muted red
	"humorous": Color(0.6, 0.5, 0.3),    # Warm yellow
	"neutral": Color(0.4, 0.4, 0.4),     # Gray
}

var _current_reactions: Array = []
var _is_displaying: bool = false


func _ready() -> void:
	# Connect to DialogueManager signals
	DialogueManager.dialogue_line_ready.connect(_on_dialogue_line_ready)
	DialogueManager.conversation_started.connect(_on_conversation_started)
	DialogueManager.conversation_ended.connect(_on_conversation_ended)

	# Initialize empty state
	_clear_reactions()


func _on_conversation_started(customer: Dictionary) -> void:
	_is_displaying = true
	show()


func _on_dialogue_line_ready(line: Resource, formatted_text: String, reactions: Array) -> void:
	print("dialogue_ui received line with %d reactions" % reactions.size())
	_display_line(line, formatted_text, reactions)


func _on_conversation_ended(customer: Dictionary) -> void:
	_is_displaying = false
	_clear_reactions()
	conversation_ended.emit()


func _display_line(line: Resource, text: String, reactions: Array) -> void:
	if not dialogue_label:
		return

	# Format and display the text
	var display_text: String = ""
	var speaker: String = line.speaker if "speaker" in line else "customer"
	if speaker == "customer":
		display_text = "[b]Customer:[/b] \"%s\"" % text
	else:
		display_text = "[i]%s[/i]" % text

	dialogue_label.text = display_text

	# Show reaction buttons
	_show_reactions(reactions)


func _show_reactions(reactions: Array) -> void:
	print("_show_reactions called with %d reactions" % reactions.size())

	# Clear old buttons completely first
	if reactions_container:
		for child in reactions_container.get_children():
			child.queue_free()
		# Wait for buttons to be freed
		await get_tree().process_frame

	_current_reactions = reactions

	if reactions.is_empty():
		print("  reactions is empty, returning")
		return

	if not reactions_container:
		print("  reactions_container is null, returning")
		return

	print("  Creating %d buttons in container: %s" % [reactions.size(), reactions_container])
	print("  Container visible: %s, size: %s" % [reactions_container.visible, reactions_container.size])
	for reaction: Resource in reactions:
		var button := Button.new()
		var label_text: String = reaction.label if "label" in reaction else "..."
		button.text = label_text
		button.custom_minimum_size = Vector2(120, 40)
		print("    Creating button: %s" % label_text)

		# Style based on tone
		var tone: String = reaction.tone if "tone" in reaction else "neutral"
		var tone_color: Color = BUTTON_COLORS.get(tone, BUTTON_COLORS["neutral"])
		var style := StyleBoxFlat.new()
		style.bg_color = tone_color
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 5
		style.content_margin_bottom = 5

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = tone_color.lightened(0.2)
		hover_style.corner_radius_top_left = 4
		hover_style.corner_radius_top_right = 4
		hover_style.corner_radius_bottom_left = 4
		hover_style.corner_radius_bottom_right = 4
		hover_style.content_margin_left = 10
		hover_style.content_margin_right = 10
		hover_style.content_margin_top = 5
		hover_style.content_margin_bottom = 5

		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = tone_color.darkened(0.2)
		pressed_style.corner_radius_top_left = 4
		pressed_style.corner_radius_top_right = 4
		pressed_style.corner_radius_bottom_left = 4
		pressed_style.corner_radius_bottom_right = 4
		pressed_style.content_margin_left = 10
		pressed_style.content_margin_right = 10
		pressed_style.content_margin_top = 5
		pressed_style.content_margin_bottom = 5

		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", pressed_style)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)

		# Connect button press
		button.pressed.connect(_on_reaction_button_pressed.bind(reaction))

		reactions_container.add_child(button)
		print("    Button added, visible: %s, size: %s" % [button.visible, button.size])


func _on_reaction_button_pressed(reaction: Resource) -> void:
	reaction_selected.emit(reaction)
	DialogueManager.select_reaction(reaction)
	_clear_reactions()


func _clear_reactions() -> void:
	_current_reactions.clear()
	if reactions_container:
		for child in reactions_container.get_children():
			child.queue_free()
	print("_clear_reactions called, children remaining: %d" % (reactions_container.get_child_count() if reactions_container else -1))


## Display a simple message without reactions (for non-dialogue text)
func show_message(text: String, use_bbcode: bool = true) -> void:
	if dialogue_label:
		dialogue_label.text = text
	_clear_reactions()


## Check if currently displaying dialogue
func is_displaying() -> bool:
	return _is_displaying
