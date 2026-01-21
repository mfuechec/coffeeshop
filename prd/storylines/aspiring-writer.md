# Storyline: The Aspiring Writer

## Overview
A 4-part customer storyline following a regular customer working on their novel.

## Storyline ID
`writer_storyline`

## Characters
- Customer personality: Favors `creative` or `chatty` types
- Name: Uses {name} placeholder (assigned by CustomerManager)

## Story Arc

### Part 1: The Beginning (`storyline_writer_part1.tres`)
**Trigger:** Random chance during smalltalk (no prerequisites)
**Visit:** Any visit

Customer mentions they're working on a novel.

**Dialogue:**
- Line: "You know what's keeping me going lately? I finally started writing that novel I've been talking about for years."

**Reactions:**
1. "That's amazing! What's it about?" (curious) - +1 relationship, sets memory `writer_started_novel`
2. "Good for you!" (supportive) - +1 relationship, sets memory `writer_started_novel`
3. "Oh, that's nice." (neutral) - sets memory `writer_started_novel` only

**Template Settings:**
- Category: smalltalk
- Tags: ["creative", "personal", "storyline"]
- triggers_storyline: "writer_storyline"
- personality_weights: {"chatty": 1.5, "shy": 0.7}

---

### Part 2: The Struggles (`storyline_writer_part2.tres`)
**Requirements:**
- has_memory: `writer_started_novel`
- min_relationship: 1
- (Implicit: some visits have passed)

Customer shares their writing struggles.

**Dialogue:**
- Line: "Remember my novel? I've hit a wall. Every word I write feels wrong."

**Reactions:**
1. "Writer's block is tough. What part is giving you trouble?" (curious) - +1 relationship, sets memory `writer_struggles_shared`
2. "Take a break. The words will come." (supportive) - +1 relationship, sets memory `writer_struggles_shared`
3. "Maybe it's just not the right time." (dismissive) - -1 relationship, sets memory `writer_struggles_dismissed`

**Template Settings:**
- Category: story_beat
- Tags: ["creative", "personal", "storyline", "emotional"]
- required_memories: ["writer_started_novel"]
- blocked_by_memories: ["writer_struggles_shared", "writer_struggles_dismissed"]
- personality_weights: {"chatty": 1.3, "tired": 1.5}

---

### Part 3: The Breakthrough (`storyline_writer_part3.tres`)
**Requirements:**
- has_memory: `writer_struggles_shared`
- min_relationship: 2

Customer excitedly shares they finished a chapter.

**Dialogue:**
- Line: "I did it! I finally finished chapter one! It took three rewrites but I'm actually proud of it."

**Reactions:**
1. "Congratulations! That's a huge milestone!" (supportive) - +2 relationship, sets memory `writer_chapter_celebrated`
2. "Read me your favorite line?" (curious) - +1 relationship, branches to reading_line
3. "One chapter down, many to go." (neutral) - +0 relationship

**Branch Line (reading_line):**
- Line: *{name} clears their throat* "The coffee grew cold as she stared at the blank page, not knowing that the best stories begin with an empty cup."
- Reactions:
  1. "That's beautiful!" (supportive) - +2 relationship, sets memory `writer_shared_excerpt`, sets flag `heard_novel_excerpt`
  2. "I love the coffee metaphor." (humorous) - +1 relationship, sets memory `writer_shared_excerpt`

**Template Settings:**
- Category: story_beat
- Tags: ["creative", "personal", "storyline", "happy"]
- required_memories: ["writer_struggles_shared"]
- blocked_by_memories: ["writer_chapter_celebrated"]
- min_relationship: 2

---

### Part 4: The Dedication (`storyline_writer_part4.tres`)
**Requirements:**
- has_memory: `writer_chapter_celebrated`
- has_flag: `heard_novel_excerpt` (optional - different dialogue)
- min_relationship: 3

Customer reveals they dedicated a character to the barista.

**Dialogue (if heard_novel_excerpt):**
- Line: "I have something to tell you. The barista in my novel? The one who listens without judgment? That's you. You're in my book."

**Dialogue (if NOT heard_novel_excerpt):**
- Line: "I wanted you to know... there's a barista character in my novel. Someone who makes everyone feel welcome. I based them on you."

**Reactions:**
1. "I'm honored to be in your story." (supportive) - +3 relationship, sets memory `writer_dedication_accepted`
2. "That's... wow. Thank you." (neutral) - +2 relationship, sets memory `writer_dedication_accepted`
3. "Do I get royalties?" (humorous) - +2 relationship, sets memory `writer_dedication_joked`

**Template Settings:**
- Category: story_beat
- Tags: ["creative", "personal", "storyline", "emotional", "conclusion"]
- required_memories: ["writer_chapter_celebrated"]
- min_relationship: 3

## Epilogue Content
After storyline completion, customer occasionally references their novel progress in random smalltalk (requires `writer_dedication_accepted` memory).

## Technical Notes
- All parts use `story_beat` category except Part 1 (smalltalk to allow natural discovery)
- Memory keys must be unique and follow snake_case
- Relationship requirements escalate: 0 -> 1 -> 2 -> 3
- blocked_by_memories prevents repeating story beats
