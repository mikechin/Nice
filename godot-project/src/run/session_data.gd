## SessionData — Resource tracking a single play session's results.
class_name SessionData
extends Resource

@export var session_id: String = ""
@export var started_at: float = 0.0
@export var ended_at: float = 0.0
@export var run_type: String = ""

## Per-card results: Array of { card_id, challenge_type, correct, rating, time_ms }
var card_results: Array[Dictionary] = []

@export var total_cards: int = 0
@export var correct_count: int = 0
@export var best_combo: int = 0
@export var coins_earned: int = 0
@export var new_cards_seen: int = 0
@export var cards_promoted: int = 0

func get_accuracy() -> float:
	if total_cards == 0:
		return 0.0
	return float(correct_count) / float(total_cards)

func get_duration_seconds() -> float:
	return ended_at - started_at

func record_answer(card_id: String, challenge_type: String, correct: bool, rating: int, time_ms: int) -> void:
	card_results.append({
		"card_id": card_id,
		"challenge_type": challenge_type,
		"correct": correct,
		"rating": rating,
		"time_ms": time_ms,
	})
	total_cards += 1
	if correct:
		correct_count += 1

func to_dict() -> Dictionary:
	return {
		"session_id": session_id,
		"started_at": started_at,
		"ended_at": ended_at,
		"run_type": run_type,
		"card_results": card_results,
		"total_cards": total_cards,
		"correct_count": correct_count,
		"best_combo": best_combo,
		"coins_earned": coins_earned,
		"new_cards_seen": new_cards_seen,
		"cards_promoted": cards_promoted,
	}

static func from_dict(data: Dictionary) -> SessionData:
	var sd := SessionData.new()
	sd.session_id = data.get("session_id", "")
	sd.started_at = data.get("started_at", 0.0)
	sd.ended_at = data.get("ended_at", 0.0)
	sd.run_type = data.get("run_type", "")
	sd.card_results = data.get("card_results", [])
	sd.total_cards = data.get("total_cards", 0)
	sd.correct_count = data.get("correct_count", 0)
	sd.best_combo = data.get("best_combo", 0)
	sd.coins_earned = data.get("coins_earned", 0)
	sd.new_cards_seen = data.get("new_cards_seen", 0)
	sd.cards_promoted = data.get("cards_promoted", 0)
	return sd
