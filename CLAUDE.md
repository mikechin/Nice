# Claude Code Instructions

## Project Overview

Chinese character learning game — SRS flashcard app disguised as a card-collecting game. Two-phase session: draft (SRS pack opening with challenges) + optional board game (Triple Triad-style card placement). Godot 4.x / GDScript, targeting mobile.

**For game design, build phases, and feature specs:** see `docs/planning.md`
**For the full game design document:** see `docs/game-design-doc.docx`

## Current Priority

Build out the core SRS engine, data pipeline, collection, and pack-opening loop (Phase 1). Every file should contain real, purposeful code.

## Key Design Decisions

- Cross-system signals go through `SignalBus` autoload — don't connect directly between systems
- One script per scene node — Godot-idiomatic, each node owns its behavior
- Prefer component-based composition over deep inheritance or monolithic managers
- Custom Resource types (`extends Resource`) for typed data structures, not raw dictionaries
- SRS tracks per-card, per-challenge-type (meaning, character, pinyin, tone, recall_pinyin) independently
- Every `src/` file should have a corresponding test file in `tests/`
- **Study interaction**: 4-direction swipe-or-tap (`src/swipe/`). Same input for all cards; rares get a distinct "ting" + glow on correct, common treatment on miss. Rare/epic cards have a 20% chance to trigger a slot-machine-style bonus round chaining additional challenge types — each correct stage adds to the card's board game power.
- **Hand carry-forward**: cards answered correctly in a run are collected into `SessionData.hand_cards` and surfaced via `RunManager.get_run_summary()` — this is the bridge into the future Phase 3 Triple Triad-style board game.

## FSRS Source

Porting from ts-fsrs (TypeScript): https://github.com/open-spaced-repetition/ts-fsrs

## Running Tests

```bash
# From the Godot editor: install the GdUnit4 addon (gitignored — user maintains
# locally under addons/gdUnit4/), then run via the GdUnit4 panel.

# Command line (headless), run from the godot-project/ directory:
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests -c --ignoreHeadlessMode
#   -a tests              run every suite under tests/
#   -c                    continue past the first failure (disable fail-fast)
#   --ignoreHeadlessMode  required — GdUnit4 refuses headless runs otherwise

# Or just run the helper from the repo root:
./setup.sh
```

## Data Pipeline

```bash
python tools/parse_hsk_data.py --level 2 --input raw_data.csv --output godot-project/data/hsk2/characters.json
python tools/build_radical_map.py --data-dir godot-project/data --output godot-project/data/radicals/radical_character_map.json
python tools/validate_data.py --data-dir godot-project/data
```
