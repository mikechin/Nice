"""
Validate all JSON data files for consistency and completeness.
Checks: valid JSON, required fields, radical references exist, etc.

Usage: python tools/validate_data.py --data-dir godot-project/data
"""
import json
import os
import sys
import argparse

REQUIRED_CHAR_FIELDS = ["character", "pinyin", "tone", "meaning", "hsk_level", "radicals"]
REQUIRED_RADICAL_FIELDS = ["radical", "meaning", "characters"]
REQUIRED_SENTENCE_FIELDS = ["id", "sentence", "meaning", "characters", "hsk_level", "type"]

def validate_characters(data_dir: str) -> list:
    errors = []
    # TODO: Validate all character JSON files
    return errors

def validate_radicals(data_dir: str) -> list:
    errors = []
    # TODO: Validate radical data and cross-reference with characters
    return errors

def validate_sentences(data_dir: str) -> list:
    errors = []
    # TODO: Validate sentence templates
    return errors

def main():
    parser = argparse.ArgumentParser(description="Validate game data files")
    parser.add_argument("--data-dir", required=True)
    args = parser.parse_args()

    all_errors = []
    all_errors.extend(validate_characters(args.data_dir))
    all_errors.extend(validate_radicals(args.data_dir))
    all_errors.extend(validate_sentences(args.data_dir))

    if all_errors:
        print(f"VALIDATION FAILED — {len(all_errors)} errors:")
        for err in all_errors:
            print(f"  - {err}")
        sys.exit(1)
    else:
        print("All data files valid.")

if __name__ == "__main__":
    main()
