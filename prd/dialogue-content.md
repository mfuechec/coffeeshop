# Dialogue Content PRD

## Schema Reference

### DialogueTemplate (`scripts/resources/dialogue_template.gd`)
- `id`: String - Unique identifier
- `category`: "greeting" | "smalltalk" | "news" | "story_beat" | "farewell" | "order"
- `weight`: float - Selection probability (higher = more likely)
- `lines`: Array[DialogueLine] - Dialogue lines in sequence
- `personality_weights`: Dictionary - e.g., `{"chatty": 1.5, "shy": 0.5}`
- `min_relationship`: int - Minimum relationship level required (-1 for none)
- `max_relationship`: int - Maximum relationship level (-1 for no max)
- `required_memories`: Array[String] - Required customer memories
- `blocked_by_memories`: Array[String] - Memories that block this dialogue
- `triggers_storyline`: String - Storyline ID this starts
- `tags`: Array[String] - Filtering tags

### DialogueLine (`scripts/resources/dialogue_line.gd`)
- `id`: String - Unique identifier for branching
- `speaker`: "customer" | "narrator"
- `text`: String - Dialogue text with placeholders: `{name}`, `{drink}`, `{order}`, `{job}`, `{mood}`, `{personality}`, `{memory:key:default}`
- `reactions`: Array[Reaction] - Player response options
- `condition`: String - Availability condition (e.g., "relationship >= 2", "has_memory:some_fact")
- `ends_conversation`: bool - If true, ends the conversation
- `next_line_id`: String - Auto-advance to this line (for narrator lines)

### Reaction (`scripts/resources/reaction.gd`)
- `id`: String - Unique identifier
- `label`: String - Button text shown to player
- `tone`: "supportive" | "curious" | "dismissive" | "humorous" | "neutral"
- `effects`: Dictionary - Effects when chosen:
  - `"relationship"`: int (e.g., 1, -1)
  - `"mood"`: String (e.g., "happy", "sad")
  - `"memory"`: String (memory to add)
  - `"flag"`: String (flag to set true)
- `next_line_id`: String - Branch to specific line
- `condition`: String - Availability condition

## Existing Templates (4 total)

### greeting_basic.tres
- Category: greeting
- Weight: 1.0
- Single line: "Hi there!"
- 3 reactions: Welcome! (supportive), How are you? (curious), What can I get you? (neutral)

### greeting_returning.tres
- Category: greeting
- Weight: 2.0
- Requires: min_relationship 1
- Single line: "Hey! Back again."
- 3 reactions: including relationship-gated "The usual?" reaction

### smalltalk_weather.tres
- Category: smalltalk
- Tags: ["weather", "casual"]
- Personality weights: chatty 1.5, shy 0.5
- Single line: "Nice weather we're having, isn't it?"
- 3 reactions with varied tones

### smalltalk_busy.tres
- Category: smalltalk
- Tags: ["work", "stress"]
- Personality weights: tired 2.0, anxious 1.5, cheerful 0.3
- Single line: "It's been such a busy week..."
- 3 reactions including memory-setting "shared_busy_day"

## Personality Types (8 total)
- `shy` - Soft blue, hesitant speech
- `chatty` - Warm yellow, talkative
- `grumpy` - Muted purple, brief/curt
- `cheerful` - Pink, optimistic
- `mysterious` - Dark purple, cryptic
- `tired` - Sage green, low energy
- `anxious` - Peach, nervous
- `chill` - Teal, relaxed

## Generation Tasks

### Priority 1: Smalltalk Templates (5 new)
1. **smalltalk_hobbies.tres** - Customer shares a hobby
2. **smalltalk_weekend.tres** - Weekend plans discussion
3. **smalltalk_work_stress.tres** - Work-related venting
4. **smalltalk_local_events.tres** - Local happenings/events
5. **smalltalk_favorite_drink.tres** - Discussing coffee preferences

### Priority 2: Personality-Specific Greetings (8 new)
One greeting per personality type with characteristic speech patterns.

### Priority 3: Farewell Templates (5 new)
Varied farewells based on relationship level and conversation quality.

### Priority 4: Storyline Templates
Multi-part customer arcs using required_memories and triggers_storyline.

## .tres File Format

```
[gd_resource type="Resource" script_class="DialogueTemplate" load_steps=N format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue_template.gd" id="1"]
[ext_resource type="Script" path="res://scripts/resources/dialogue_line.gd" id="2"]
[ext_resource type="Script" path="res://scripts/resources/reaction.gd" id="3"]

[sub_resource type="Resource" id="reaction_id"]
script = ExtResource("3")
id = "unique_reaction_id"
label = "Button Text"
tone = "supportive"
effects = {"relationship": 1}
next_line_id = ""
condition = ""

[sub_resource type="Resource" id="line_id"]
script = ExtResource("2")
id = "unique_line_id"
speaker = "customer"
text = "Dialogue text with {placeholders}"
reactions = [SubResource("reaction_id"), ...]
condition = ""
ends_conversation = false
next_line_id = ""

[resource]
script = ExtResource("1")
id = "template_id"
category = "smalltalk"
weight = 1.0
lines = [SubResource("line_id")]
personality_weights = {"chatty": 1.5}
min_relationship = 0
max_relationship = -1
required_memories = []
blocked_by_memories = []
triggers_storyline = ""
tags = ["tag1", "tag2"]
```

## Validation Checklist
- [ ] Valid Godot .tres syntax
- [ ] Unique IDs for all resources
- [ ] Valid placeholders only: {name}, {drink}, {order}, {job}, {mood}, {personality}
- [ ] Valid tones: supportive, curious, dismissive, humorous, neutral
- [ ] Valid categories: greeting, smalltalk, news, story_beat, farewell, order
- [ ] Reactions have meaningful effects for tone
- [ ] Personality weights match existing personality types
- [ ] load_steps count matches actual resource count
