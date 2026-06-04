# Chinese Character Learning Game

An SRS-powered Chinese character flashcard app disguised as an addictive card-collecting game. Anki's science, none of its misery.

## Quick Start

1. Install [Godot 4.3+](https://godotengine.org/download)
2. Open `godot-project/project.godot` in the Godot editor
3. Install GdUnit4 addon into `godot-project/addons/gdUnit4/`
4. Run the project

## Using Claude Code

This project is structured for development with [Claude Code](https://docs.claude.com/en/docs/claude-code/overview). The `CLAUDE.md` file contains the full project context, design decisions, and conventions.

```bash
cd chinese-card-game
claude
```

Claude Code will read `CLAUDE.md` automatically and understand the entire project.

### Suggested first commands:
- "Port the FSRS algorithm from ts-fsrs to GDScript in src/srs/"
- "Fill in the character database with complete HSK 2 data"
- "Build the pack-opening loop for Phase 1"

## Project Structure

See `CLAUDE.md` for the complete structure and design rationale.

## Build Phases

1. **Foundation** — SRS algorithm, character database, collection grid, pack-opening loop
2. **Draft Phase** — Challenge interaction, bonus rounds, card tier promotion, foil variants
3. **Board Game** — Triple Triad-style 3x3 grid, radical matchups, computer opponent, parallax variants
4. **Polish & Endgame** — Open world opponents, survival mode, economy tuning, art/audio

See `docs/planning.md` for the full build plan.

## Tech Stack

- Godot 4.x / GDScript
- FSRS algorithm (ported from ts-fsrs)
- JSON data files for HSK 2-5 characters
- GdUnit4 for testing

## Data Pipeline

Tools in `tools/` process raw HSK data into game-ready JSON:

```bash
python tools/parse_hsk_data.py --level 2 --input raw_data.csv --output godot-project/data/hsk2/characters.json
python tools/build_radical_map.py --data-dir godot-project/data --output godot-project/data/radicals/radical_character_map.json
python tools/validate_data.py --data-dir godot-project/data
```

## License

TBD
