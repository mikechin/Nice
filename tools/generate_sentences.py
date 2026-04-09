"""
Create sentence template databases for daily goals and weekly trials.
Can generate from existing corpora or manually curated lists.

Usage: python tools/generate_sentences.py --level 3 --output godot-project/data/sentences/hsk3_daily.json
"""
import json
import argparse

def generate_sentences(hsk_level: int) -> list:
    """Generate sentence templates for a given HSK level."""
    # TODO: Implement — either parse from corpus or load curated list
    return []

def main():
    parser = argparse.ArgumentParser(description="Generate sentence templates")
    parser.add_argument("--level", type=int, required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    sentences = generate_sentences(args.level)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(sentences, f, ensure_ascii=False, indent=2)
    print(f"Generated {len(sentences)} sentences for HSK {args.level}")

if __name__ == "__main__":
    main()
