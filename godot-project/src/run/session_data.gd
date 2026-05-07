## SessionData — Resource tracking a single play session's results.
##
## record_answer logs an SRS-level event (per card, per challenge type).
## record_card_resolution is the per-card event that decides whether a
## card joins hand_cards (i.e. survives into the board-game phase) and
## stores the PowerBoosts earned in any bonus round.
class_name SessionData
extends Resource

@export var session_id: String = ""
@export var started_at: float = 0.0
@export var ended_at: float = 0.0

## Per-stage results: { card_id, challenge_type, correct, rating, time_ms }.
var card_results: Array[Dictionary] = []

## Cards the player answered correctly this run, with their final
## board-game power. Carried forward into Phase 3.
var hand_cards: Array[HandCard] = []

@export var total_cards: int = 0
@export var correct_count: int = 0
@export var new_cards_seen: int = 0
@export var cards_promoted: int = 0


func get_accuracy() -> float:
	if total_cards == 0:
		return 0.0
	return float(correct_count) / float(total_cards)


func get_duration_seconds() -> float:
	return ended_at - started_at


## Log a single challenge-stage answer. This is the SRS-grain event:
## bonus stages count too. Per-card bookkeeping (hand_cards membership,
## final power) lives in record_card_resolution instead.
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


## Per-card resolution: called once after the primary challenge (and any
## bonus stages) wrap. A correct primary adds the card to hand_cards with
## its frozen base power and earned boosts; a wrong primary is a no-op.
## Dedupes by card_id so the same card resolved twice in one run only
## appears once.
func record_card_resolution(card_id: String, primary_correct: bool, base_power: int, boosts: Array) -> void:
	if not primary_correct:
		return
	if has_hand_card(card_id):
		return
	hand_cards.append(HandCard.create(card_id, base_power, boosts))


func has_hand_card(card_id: String) -> bool:
	for hc in hand_cards:
		if hc.card_id == card_id:
			return true
	return false


func get_hand_card(card_id: String) -> HandCard:
	for hc in hand_cards:
		if hc.card_id == card_id:
			return hc
	return null


## Card IDs only — convenience for code that doesn't care about power.
func get_hand_card_ids() -> Array[String]:
	var ids: Array[String] = []
	for hc in hand_cards:
		ids.append(hc.card_id)
	return ids


## Sum of every hand card's total power. Drives the results-screen payoff
## and seeds the Phase 3 board-game stats display.
func get_total_hand_power() -> int:
	var total := 0
	for hc in hand_cards:
		total += hc.get_total_power()
	return total


func to_dict() -> Dictionary:
	var hand_dicts: Array = []
	for hc in hand_cards:
		hand_dicts.append(hc.to_dict())
	return {
		"session_id": session_id,
		"started_at": started_at,
		"ended_at": ended_at,
		"card_results": card_results,
		"hand_cards": hand_dicts,
		"total_cards": total_cards,
		"correct_count": correct_count,
		"new_cards_seen": new_cards_seen,
		"cards_promoted": cards_promoted,
	}


static func from_dict(data: Dictionary) -> SessionData:
	var sd := SessionData.new()
	sd.session_id = data.get("session_id", "")
	sd.started_at = data.get("started_at", 0.0)
	sd.ended_at = data.get("ended_at", 0.0)
	sd.card_results = data.get("card_results", [])
	var raw_hand: Array = data.get("hand_cards", [])
	var typed_hand: Array[HandCard] = []
	for h in raw_hand:
		if h is Dictionary:
			typed_hand.append(HandCard.from_dict(h))
	sd.hand_cards = typed_hand
	sd.total_cards = data.get("total_cards", 0)
	sd.correct_count = data.get("correct_count", 0)
	sd.new_cards_seen = data.get("new_cards_seen", 0)
	sd.cards_promoted = data.get("cards_promoted", 0)
	return sd
