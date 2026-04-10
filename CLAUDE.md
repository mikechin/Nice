# Claude Code Instructions

## Project Overview

Chinese character learning game — SRS flashcard app disguised as a card-collecting game. Godot 4.x / GDScript, targeting mobile.

**For game design, build phases, and feature specs:** see `docs/planning.md`
**For the full game design document:** see `docs/game-design-doc.docx`

## Tech Stack

- **Engine:** Godot 4.3+ with GDScript
- **Target:** Mobile (iOS / Android), desktop for testing
- **Testing:** GdUnit4 (in `godot-project/addons/gdunit4/`)
- **SRS:** FSRS algorithm ported from ts-fsrs to GDScript
- **Data:** JSON files loaded at runtime

## Project Structure

```
Nice/
├── CLAUDE.md                  # THIS FILE
├── docs/
│   ├── planning.md            # Build phases, features, file inventory, game design
│   └── game-design-doc.docx   # Full game design document
├── godot-project/
│   ├── project.godot
│   ├── addons/                # GdUnit4, etc.
│   ├── assets/                # Art, audio, fonts, themes
│   ├── data/                  # JSON data (HSK chars, radicals, sentences)
│   ├── src/                   # All game scripts by system
│   │   ├── autoload/          # Singletons: GameState, SignalBus, AudioManager, SaveManager
│   │   ├── srs/               # FSRS algorithm, card state, scheduling
│   │   ├── database/          # Data loaders and queries
│   │   ├── run/               # Run/round flow, combo, difficulty
│   │   ├── swipe/             # Card display, swipe input, answer generation
│   │   ├── economy/           # Coins, economy scaling
│   │   ├── radicals/          # Radical equip, activation, bonuses
│   │   ├── shop/              # Shop logic, rotation, items
│   │   ├── sentences/         # Sentence builder, validation, boss rounds
│   │   ├── progression/       # Collection grid, streaks, achievements, stats
│   │   ├── effects/           # VFX, transitions, loot reveals
│   │   ├── tutorial/          # Onboarding, step sequences
│   │   ├── notifications/     # SRS reminders, push notification bridge
│   │   └── debug/             # Dev tools, inspectors, cheat panels
│   ├── scenes/                # .tscn scene files + attached scripts
│   │   ├── screens/           # Full screens (menu, game, shop, etc.)
│   │   ├── components/        # Reusable UI (card, radical badge, etc.)
│   │   └── effects/           # VFX scenes
│   └── tests/                 # GdUnit4 tests, mirrors src/ structure
├── tools/                     # Python data pipeline scripts
└── README.md
```

## Current Priority

Build out the core SRS engine, data pipeline, collection, and pack-opening loop (Phase 1). Follow Godot-idiomatic patterns: one script per scene node, custom Resource types for data structures, shared enum/constant files, component-based composition, thorough test coverage mirroring src/. Every file should contain real, purposeful code.

## Coding Conventions

- GDScript with static typing where possible
- Class names: `PascalCase` (e.g., `FsrsScheduler`, `RunManager`)
- File names: `snake_case` (e.g., `fsrs_scheduler.gd`, `run_manager.gd`)
- Signals: `snake_case` past tense (e.g., `card_answered`, `combo_broken`, `run_ended`)
- Constants: `UPPER_SNAKE_CASE`
- Use Godot's signal system for decoupled communication — cross-system signals go through `SignalBus`
- Autoloads for global state: `GameState`, `SignalBus`, `AudioManager`, `SaveManager`
- Every `src/` file should have a corresponding test file in `tests/`
- Data files are JSON, loaded at runtime by database scripts
- Keep scene trees shallow — prefer composition over deep nesting
- One script per scene node — Godot-idiomatic, each node owns its behavior
- Use custom Resource types (`extends Resource`) for typed data structures (CharacterData, RadicalData, RunConfig, etc.)
- Shared enums and constants in dedicated files under their system directory (e.g., `src/srs/srs_enums.gd`)
- Prefer component-based composition: small, focused scripts composed in scene trees over monolithic managers

## FSRS Source

Porting from ts-fsrs (TypeScript): https://github.com/open-spaced-repetition/ts-fsrs

Key types: State (New, Learning, Review, Relearning), Rating (Again, Hard, Good, Easy). Each card tracks stability and difficulty per challenge type (meaning, character, pinyin, tone).

## Running Tests

```bash
# From Godot editor: install GdUnit4 addon, then run via GdUnit4 panel
# Or via command line:
godot --headless -s addons/gdunit4/bin/GdUnitCmdTool.gd --run-all
```

## Data Pipeline

```bash
python tools/parse_hsk_data.py --level 2 --input raw_data.csv --output godot-project/data/hsk2/characters.json
python tools/build_radical_map.py --data-dir godot-project/data --output godot-project/data/radicals/radical_character_map.json
python tools/validate_data.py --data-dir godot-project/data
```
