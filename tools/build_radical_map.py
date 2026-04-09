"""
Generate radical-to-character mappings from character data.
Reads all HSK character files and builds a reverse index.

Usage: python tools/build_radical_map.py --data-dir godot-project/data --output godot-project/data/radicals/radical_character_map.json
"""
import json
import os
import argparse

def build_map(data_dir: str) -> dict:
    """Build radical -> [characters] mapping from all HSK levels."""
    radical_map = {}
    for level in range(2, 6):
        path = os.path.join(data_dir, f"hsk{level}", "characters.json")
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8") as f:
            characters = json.load(f)
        for char_data in characters:
            for radical in char_data.get("radicals", []):
                if radical not in radical_map:
                    radical_map[radical] = []
                if char_data["character"] not in radical_map[radical]:
                    radical_map[radical].append(char_data["character"])
    return radical_map

def main():
    parser = argparse.ArgumentParser(description="Build radical-character map")
    parser.add_argument("--data-dir", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    radical_map = build_map(args.data_dir)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(radical_map, f, ensure_ascii=False, indent=2)
    print(f"Mapped {len(radical_map)} radicals")

if __name__ == "__main__":
    main()
