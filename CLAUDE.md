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

## FSRS Source

Porting from ts-fsrs (TypeScript): https://github.com/open-spaced-repetition/ts-fsrs

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
