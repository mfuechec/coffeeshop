# Visual Enhancement PRD

## Current State

### CustomerAvatar (`scripts/ui/customer_avatar.gd`)

**Hair Styles (4 total):**
- Style 0: Short hair - rectangular base with circular top
- Style 1: Long hair - large circle with rectangular sides
- Style 2: Spiky/messy - 7 triangular spikes radiating outward
- Style 3: Bald/very short - faded circle

**Hair Colors (8 total):**
- Dark brown, Brown, Light brown, Blonde, Black, Auburn, Red, Gray

**Skin Tones (6 total):**
- Light, Fair, Medium, Tan, Brown, Dark

**Personality-Based Shirt Colors (8 total):**
- shy: Soft blue (0.7, 0.8, 0.9)
- chatty: Warm yellow (1.0, 0.8, 0.4)
- grumpy: Muted purple (0.6, 0.5, 0.6)
- cheerful: Pink (1.0, 0.6, 0.7)
- mysterious: Dark purple (0.4, 0.3, 0.5)
- tired: Sage green (0.6, 0.7, 0.6)
- anxious: Peach (0.9, 0.7, 0.5)
- chill: Teal (0.5, 0.8, 0.8)

**Accessories:**
- Glasses only (30% chance)

**Expressions (3 total):**
- 0: Happy - curved smile
- 1: Neutral - straight line
- 2: Slight smile - subtle curve

**Generation:**
- Uses `hash(customer_id)` as random seed for consistency
- Customer always looks the same across sessions

## Enhancement Tasks

### Priority 1: New Hairstyles (4 additions)
Add to `_draw_hair()` function:

1. **Style 4: Ponytail** - Base hair with extending gathered section to one side
2. **Style 5: Curly** - Multiple overlapping circles for voluminous curls
3. **Style 6: Undercut** - Short sides with longer top section
4. **Style 7: Braided** - Long style with visible braid pattern

### Priority 2: New Accessories (3 additions)
Add new accessory drawing functions with 30% chance each:

1. **Earrings** - Small circles or dangles at ear positions
2. **Hat** - Cap or beanie covering top of head
3. **Bowtie/Necklace** - Neck accessory below collar

### Priority 3: New Expressions (2 additions)
Add to `_draw_face()` expression handling:

1. **Expression 3: Tired** - Droopy eyes with downturned mouth
2. **Expression 4: Excited** - Wide eyes with big smile

### Priority 4: Additional Features
- Eyebrow variations based on mood
- Blush for certain personalities
- Facial hair options

## Implementation Notes

### Deterministic Generation
All new features must use the existing RNG pattern:
```gdscript
var rng := RandomNumberGenerator.new()
rng.seed = hash(customer_data.get("id", "default"))
# Use rng.randi() and rng.randf() for selections
```

### Performance Considerations
- Keep draw calls minimal
- Use simple geometric shapes (circles, rectangles, polygons)
- Avoid complex polygon calculations in _draw()

### Style Consistency
- Line widths should scale with `scale_factor`
- Colors should complement existing palette
- Proportions relative to `head_radius` and `head_center`

## Validation Checklist
- [ ] All new styles render without errors
- [ ] Deterministic generation works (same customer = same appearance)
- [ ] No z-fighting or overdraw issues
- [ ] Accessories don't overlap with hair incorrectly
- [ ] Performance remains smooth with new draw calls
- [ ] Style integrates with existing aesthetic
