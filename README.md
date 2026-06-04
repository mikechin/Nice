# Chinese Character Learning Game

An SRS-powered Chinese character flashcard app disguised as an addictive card-collecting game. Anki's science, none of its misery.

## Quick Start

1. Install [Godot 4.3+](https://godotengine.org/download)
2. Clone the repo and verify your environment:

   ```bash
   git clone git@github.com:mikechin/Nice.git
   cd Nice
   ./setup.sh   # checks Godot, confirms the bundled GdUnit4 addon, runs the test suite
   ```

3. Open `godot-project/project.godot` in the Godot editor to play or develop.

GdUnit4 (the test framework) is bundled under `godot-project/addons/gdUnit4/` — no separate install needed.

## Tests

Run the full suite headless from the `godot-project/` directory:

```bash
cd godot-project
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests -c --ignoreHeadlessMode
```

`setup.sh` runs exactly this after verifying your environment.

## Using Claude Code

This project is structured for development with [Claude Code](https://docs.claude.com/en/docs/claude-code/overview). The `CLAUDE.md` file contains the full project context, design decisions, and conventions.

```bash
cd Nice
claude
```

Claude Code will read `CLAUDE.md` automatically and understand the entire project.

### Where to start
The core systems (SRS engine, HSK data, pack-opening, economy, combat) are already built. See `docs/planning.md` for the build plan and current phase, and read `CLAUDE.md` for conventions before making changes.

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
