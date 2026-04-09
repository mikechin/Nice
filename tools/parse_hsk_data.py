"""
Parse HSK word lists into structured JSON for the game.
Input: Raw HSK word list files (CSV or text)
Output: data/hskN/characters.json files

Usage: python tools/parse_hsk_data.py --level 2 --input raw_hsk2.csv --output godot-project/data/hsk2/characters.json
"""
import json
import argparse

def parse_hsk_file(input_path: str, hsk_level: int) -> list:
    """Parse raw HSK data into character entries."""
    # TODO: Implement parsing logic
    # Each entry needs: character, pinyin, tone, meaning, hsk_level,
    #                    radicals, components, is_radical, frequency_rank
    return []

def main():
    parser = argparse.ArgumentParser(description="Parse HSK data into game JSON")
    parser.add_argument("--level", type=int, required=True, help="HSK level (2-5)")
    parser.add_argument("--input", required=True, help="Input file path")
    parser.add_argument("--output", required=True, help="Output JSON path")
    args = parser.parse_args()
    
    characters = parse_hsk_file(args.input, args.level)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(characters, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(characters)} characters to {args.output}")

if __name__ == "__main__":
    main()
