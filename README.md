# Coffee Shop

A cozy background game where you run a small coffee shop, serve customers, and build relationships through small talk.

## Concept

This is a relaxed, ambient game designed to run in the background throughout your day. Customers arrive periodically, and when you check in, you'll serve them coffee and engage in small dialogue. The game rewards:

- **Remembering orders** - Regular customers appreciate when you remember their usual
- **Building relationships** - Learn about your customers' lives through conversation
- **Decorating your shop** - Unlock and place decorations to improve your space

## Tech Stack

- **Engine**: Godot 4.2+
- **Language**: GDScript
- **Target Platforms**: Windows, macOS, Linux (Steam)

## Project Structure

```
coffee-shop/
├── assets/           # Art, audio, fonts
├── scenes/           # Godot scene files (.tscn)
├── scripts/
│   ├── autoload/     # Singleton managers
│   └── ...           # Other scripts
└── project.godot     # Godot project file
```

## Core Systems

### Autoload Managers

- **GameManager** - Central game state, pause handling, player stats
- **CustomerManager** - Customer generation, queue, relationship tracking
- **SaveManager** - Auto-save, persistence
- **TimeManager** - Real-time sync, time-of-day effects

### Key Features (Planned)

- [ ] Customer generation with personalities
- [ ] Dialogue system with branching choices
- [ ] Relationship/memory system
- [ ] Shop decoration and upgrades
- [ ] System tray integration
- [ ] Steam achievements
- [ ] Cloud saves

## Development

### Prerequisites

- Godot 4.2 or later

### Running

1. Open `project.godot` in Godot
2. Press F5 to run

### Building for Steam

1. Install GodotSteam plugin
2. Configure export presets
3. Build through Godot's export system

## Design Philosophy

- **Minimal resource usage** - Designed to idle without draining battery
- **Real-time pacing** - Customers arrive throughout the day, not all at once
- **No pressure** - No fail states, no rushing, just cozy vibes
- **Meaningful connections** - Characters feel like people you'd want to know

## License

All rights reserved. This is a commercial project intended for Steam release.
