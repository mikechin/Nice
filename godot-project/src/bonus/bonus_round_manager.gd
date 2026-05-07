## BonusRoundManager — State machine for a single card's bonus round.
##
## Lifecycle:
##   1. start(card_id, primary_challenge_type) builds the chain of remaining
##      stages (the three challenge types the primary didn't use).
##   2. next_stage() returns the next BonusStage to present (or null when
##      done).
##   3. record_stage_result(correct) appends a PowerBoost on success and
##      stops the round on failure (a single miss ends the chain — spec).
##   4. is_complete() goes true when stages run out OR the chain stopped.
##   5. get_boosts() / get_total_boost() return the rewards earned.
##
## This is pure state — no signals, no UI. The presenter owns scene wiring.
class_name BonusRoundManager
extends RefCounted

var card_id: String = ""
var primary_stage: BonusEnums.BonusStage = BonusEnums.BonusStage.MEANING
var is_active: bool = false

## Stages stored as ints — Godot's typed arrays don't accept inner-enum
## parameterizations, but values are still BonusEnums.BonusStage members.
var _remaining_stages: Array[int] = []
var _completed_stages: Array[int] = []
var _boosts: Array[PowerBoost] = []
var _stopped_early: bool = false


## Begin a bonus round for `card_id` whose primary challenge was
## `primary_challenge_type`. Resets all state — safe to reuse a single
## manager across cards.
func start(card_id_: String, primary_challenge_type: String) -> void:
	card_id = card_id_
	primary_stage = BonusEnums.stage_from_string(primary_challenge_type)
	_remaining_stages = []
	for stage in BonusEnums.STAGE_ORDER:
		if stage != primary_stage:
			_remaining_stages.append(stage)
	_completed_stages = []
	_boosts = []
	_stopped_early = false
	is_active = true


## Peek at the next stage without consuming it. Returns -1 when no stages
## remain (use is_complete to check definitively).
func peek_next_stage() -> int:
	if _remaining_stages.is_empty():
		return -1
	return _remaining_stages[0]


## Pop and return the next stage. Caller is expected to follow up with
## record_stage_result. Returns -1 if there is no next stage.
func next_stage() -> int:
	if _remaining_stages.is_empty():
		return -1
	return _remaining_stages.pop_front()


## Record the outcome of the just-presented stage. On success a PowerBoost
## is appended; on failure the round stops (no further stages will be
## offered). Returns CONTINUE if more stages remain, STOP otherwise.
func record_stage_result(stage: BonusEnums.BonusStage, correct: bool) -> BonusEnums.StageOutcome:
	if not is_active:
		return BonusEnums.StageOutcome.STOP

	if correct:
		_completed_stages.append(stage)
		_boosts.append(PowerBoost.from_bonus_stage(stage))
		if _remaining_stages.is_empty():
			is_active = false
			return BonusEnums.StageOutcome.STOP
		return BonusEnums.StageOutcome.CONTINUE

	# Wrong answer ends the chain — spec: "Miss at any stage → stop boosting".
	_stopped_early = true
	is_active = false
	return BonusEnums.StageOutcome.STOP


func is_complete() -> bool:
	return not is_active


func was_stopped_early() -> bool:
	return _stopped_early


func get_boosts() -> Array[PowerBoost]:
	return _boosts.duplicate()


func get_total_boost() -> int:
	return PowerCalculator.total_boost(_boosts)


func get_completed_stages() -> Array[int]:
	return _completed_stages.duplicate()


func get_remaining_count() -> int:
	return _remaining_stages.size()
