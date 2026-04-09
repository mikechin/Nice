## CardState — Data model for a single SRS card.
## Tracks state per challenge type (meaning, character, pinyin, tone).
class_name CardState
extends RefCounted

var card_id: String = ""
var character: String = ""

## Per-challenge-type SRS state. Each value is an FSRS card dict from FsrsAlgorithm.
var states: Dictionary = {}

var _fsrs: FsrsAlgorithm


func _init(fsrs: FsrsAlgorithm = null) -> void:
	_fsrs = fsrs if fsrs else FsrsAlgorithm.new()
	for ct_str in ["meaning", "character", "pinyin", "tone"]:
		states[ct_str] = _fsrs.init_card()


static func create(id: String, char_text: String, fsrs: FsrsAlgorithm = null) -> CardState:
	var cs := CardState.new(fsrs)
	cs.card_id = id
	cs.character = char_text
	return cs


func get_state_for_type(challenge_type: String) -> Dictionary:
	if challenge_type in states:
		return states[challenge_type]
	return _fsrs.init_card()


func update_state(challenge_type: String, new_state: Dictionary) -> void:
	states[challenge_type] = new_state


## Return the challenge type with the lowest stability (weakest memory).
func get_weakest_challenge_type() -> String:
	var weakest := "meaning"
	var lowest_stability := INF
	for ct_str in states:
		var s: float = states[ct_str].get("stability", 0.0)
		if s < lowest_stability:
			lowest_stability = s
			weakest = ct_str
	return weakest


## Current recall probability for a specific challenge type.
func get_retrievability(challenge_type: String, now: float) -> float:
	var card_dict: Dictionary = states.get(challenge_type, {})
	return _fsrs.get_retrievability(card_dict, now)


## Average retrievability across all challenge types.
func get_average_retrievability(now: float) -> float:
	var total := 0.0
	var count := 0
	for ct_str in states:
		var card_dict: Dictionary = states[ct_str]
		if card_dict.get("state", FsrsAlgorithm.State.NEW) != FsrsAlgorithm.State.NEW:
			total += _fsrs.get_retrievability(card_dict, now)
			count += 1
	if count == 0:
		return 0.0
	return total / float(count)


## Is any challenge type due for review?
func is_due(challenge_type: String, now: float) -> bool:
	var card_dict: Dictionary = states.get(challenge_type, {})
	var state: int = card_dict.get("state", FsrsAlgorithm.State.NEW)
	if state == FsrsAlgorithm.State.NEW:
		return false
	var last_review: float = card_dict.get("last_review", 0.0)
	var scheduled_days: int = card_dict.get("scheduled_days", 0)
	if scheduled_days == 0:
		return true  # Learning/relearning — due immediately
	var due_time := last_review + scheduled_days * 86400.0
	return now >= due_time


## Is any challenge type due?
func is_any_due(now: float) -> bool:
	for ct_str in states:
		if is_due(ct_str, now):
			return true
	return false


## Is retrievability below the danger threshold?
func is_about_to_forget(challenge_type: String, now: float) -> bool:
	var card_dict: Dictionary = states.get(challenge_type, {})
	var state: int = card_dict.get("state", FsrsAlgorithm.State.NEW)
	if state == FsrsAlgorithm.State.NEW:
		return false
	return get_retrievability(challenge_type, now) < SrsConfig.ABOUT_TO_FORGET_THRESHOLD


## Is this card completely new (never reviewed in any challenge type)?
func is_new() -> bool:
	for ct_str in states:
		if states[ct_str].get("state", FsrsAlgorithm.State.NEW) != FsrsAlgorithm.State.NEW:
			return false
	return true


## Get the highest SRS state across all challenge types.
func get_best_state() -> int:
	var best := FsrsAlgorithm.State.NEW
	for ct_str in states:
		var s: int = states[ct_str].get("state", FsrsAlgorithm.State.NEW)
		if s == FsrsAlgorithm.State.REVIEW:
			return FsrsAlgorithm.State.REVIEW
		if s > best:
			best = s
	return best


## Get highest stability across all challenge types.
func get_max_stability() -> float:
	var max_s := 0.0
	for ct_str in states:
		var s: float = states[ct_str].get("stability", 0.0)
		max_s = maxf(max_s, s)
	return max_s


func to_dict() -> Dictionary:
	return {
		"card_id": card_id,
		"character": character,
		"states": states.duplicate(true),
	}


static func from_dict(data: Dictionary, fsrs: FsrsAlgorithm = null) -> CardState:
	var cs := CardState.new(fsrs)
	cs.card_id = data.get("card_id", "")
	cs.character = data.get("character", "")
	var saved_states: Dictionary = data.get("states", {})
	for ct_str in saved_states:
		cs.states[ct_str] = saved_states[ct_str].duplicate(true)
	return cs
