## SrsEnums — Shared enums and constants for the SRS system.
class_name SrsEnums
extends RefCounted

enum CardSrsState { NEW, LEARNING, REVIEW, RELEARNING }

enum Rating { AGAIN = 1, HARD = 2, GOOD = 3, EASY = 4 }

enum ChallengeType { MEANING, CHARACTER, PINYIN, TONE }

## Map ChallengeType enum to string key used in CardState dictionaries.
static func challenge_type_to_string(ct: ChallengeType) -> String:
	match ct:
		ChallengeType.MEANING: return "meaning"
		ChallengeType.CHARACTER: return "character"
		ChallengeType.PINYIN: return "pinyin"
		ChallengeType.TONE: return "tone"
	return "meaning"

static func string_to_challenge_type(s: String) -> ChallengeType:
	match s:
		"meaning": return ChallengeType.MEANING
		"character": return ChallengeType.CHARACTER
		"pinyin": return ChallengeType.PINYIN
		"tone": return ChallengeType.TONE
	return ChallengeType.MEANING

## Loot rarity derived from SRS state during a run.
enum LootRarity { COMMON, LEARNING, ABOUT_TO_FORGET, NEW_CARD }

static func state_name(state: CardSrsState) -> String:
	match state:
		CardSrsState.NEW: return "New"
		CardSrsState.LEARNING: return "Learning"
		CardSrsState.REVIEW: return "Review"
		CardSrsState.RELEARNING: return "Relearning"
	return "Unknown"

static func rating_name(rating: Rating) -> String:
	match rating:
		Rating.AGAIN: return "Again"
		Rating.HARD: return "Hard"
		Rating.GOOD: return "Good"
		Rating.EASY: return "Easy"
	return "Unknown"
