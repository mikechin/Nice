## ChallengePresenter — Orchestrates the card + answers for each challenge.
## Ties together CardDisplay, AnswerGenerator, and SwipeDetector.
##
## Phase 2: a correct primary answer on a rare/epic card may roll into a
## bonus round (BonusTrigger.roll). Bonus rounds chain the three challenge
## types the primary didn't use; each correct stage banks a PowerBoost,
## a miss stops the chain. The presenter emits per-stage challenge_completed
## events plus a single terminal card_resolved per card so callers can
## record SRS feedback per stage but only advance once the card is done.
class_name ChallengePresenter
extends Control

signal challenge_completed(card_id: String, challenge_type: String, correct: bool, rating: int)
## Fires after a correct primary when the trigger roll succeeds.
signal bonus_round_started(card_id: String)
## Fires once per bonus stage, just before its input is enabled.
signal bonus_stage_started(card_id: String, stage: int)
## Terminal signal — fires exactly once per card after the primary
## (and any bonus stages) finish. boosts is Array[PowerBoost].
signal card_resolved(card_id: String, primary_correct: bool, boosts: Array)

var card_display: CardDisplay
var swipe_detector: SwipeDetector
var answer_generator: AnswerGenerator
var bonus_manager: BonusRoundManager
var rng: RandomNumberGenerator

var _current_card: CharacterData
var _current_challenge_type: String
var _current_answers: Dictionary
var _current_loot_rarity: SrsEnums.LootRarity
var _challenge_start_time: float = 0.0
var _pause_start_ms: float = -1.0
var _is_active: bool = false
var _in_bonus_round: bool = false
var _primary_correct: bool = false


func _ready() -> void:
	if swipe_detector:
		swipe_detector.swipe_completed.connect(_on_swipe)


func _notification(what: int) -> void:
	# When the app pauses (mobile background) or loses focus, freeze the
	# challenge timer so a returning user isn't penalized with a HARD rating.
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if _is_active and _pause_start_ms < 0.0:
				_pause_start_ms = Time.get_ticks_msec()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			if _pause_start_ms >= 0.0:
				_challenge_start_time += Time.get_ticks_msec() - _pause_start_ms
				_pause_start_ms = -1.0


func setup(
	ag: AnswerGenerator,
	cd: CardDisplay = null,
	sd: SwipeDetector = null,
	brm: BonusRoundManager = null,
	rng_: RandomNumberGenerator = null,
) -> void:
	answer_generator = ag
	card_display = cd
	swipe_detector = sd
	bonus_manager = brm
	rng = rng_
	if swipe_detector:
		if not swipe_detector.swipe_completed.is_connected(_on_swipe):
			swipe_detector.swipe_completed.connect(_on_swipe)


func present_challenge(card_data: CharacterData, challenge_type: String, loot_rarity: SrsEnums.LootRarity) -> void:
	_current_card = card_data
	_current_loot_rarity = loot_rarity
	_in_bonus_round = false
	_primary_correct = false

	# Card display reset only happens for the primary — bonus stages reuse
	# the same card without re-animating in.
	if card_display:
		card_display.setup_for_challenge(card_data, challenge_type, loot_rarity)
		card_display.animate_card_in()

	_present_for_challenge_type(challenge_type)


func submit_answer(direction: String) -> void:
	_on_swipe(direction)


func _present_for_challenge_type(challenge_type: String) -> void:
	_current_challenge_type = challenge_type
	_challenge_start_time = Time.get_ticks_msec()
	_pause_start_ms = -1.0
	_is_active = true

	_current_answers = answer_generator.generate_answers(_current_card, challenge_type)

	if card_display and _in_bonus_round:
		# Same card, new prompt — reset just the prompt content without
		# replaying the entrance animation.
		card_display.setup_for_challenge(_current_card, challenge_type, _current_loot_rarity)

	if swipe_detector:
		swipe_detector.set_enabled(true)

	SignalBus.card_presented.emit(_current_card.to_dict(), challenge_type)


func _on_swipe(direction: String) -> void:
	if not _is_active:
		return

	_is_active = false
	if swipe_detector:
		swipe_detector.set_enabled(false)

	var correct_dir: String = _current_answers.get("correct_direction", "")
	var is_correct := direction == correct_dir
	var elapsed_ms := roundi(Time.get_ticks_msec() - _challenge_start_time)
	var rating := _determine_rating(is_correct, elapsed_ms)

	if card_display:
		if is_correct:
			card_display.show_correct_feedback()
		else:
			card_display.show_wrong_feedback()

	# Per-stage feedback to the rest of the system. SRS tracks each
	# challenge type independently — bonus stages are real reviews too.
	SignalBus.card_answered.emit(
		_current_card.to_dict(),
		_current_challenge_type,
		is_correct,
		rating,
	)
	challenge_completed.emit(
		_current_card.character,
		_current_challenge_type,
		is_correct,
		rating,
	)

	if _in_bonus_round:
		_handle_bonus_stage_result(is_correct)
	else:
		_handle_primary_result(is_correct)


func _handle_primary_result(is_correct: bool) -> void:
	_primary_correct = is_correct
	if not is_correct:
		_resolve_card([])
		return

	# Primary correct — try to roll a bonus round if eligible and we have a manager.
	if bonus_manager == null:
		_resolve_card([])
		return

	var outcome := BonusTrigger.roll(_current_loot_rarity, rng)
	if outcome != BonusEnums.BonusOutcome.TRIGGERED:
		_resolve_card([])
		return

	_start_bonus_round()


func _start_bonus_round() -> void:
	_in_bonus_round = true
	bonus_manager.start(_current_card.character, _current_challenge_type)
	bonus_round_started.emit(_current_card.character)
	_advance_bonus_stage()


func _advance_bonus_stage() -> void:
	var stage := bonus_manager.next_stage()
	if stage < 0:
		_resolve_card(bonus_manager.get_boosts())
		return
	bonus_stage_started.emit(_current_card.character, stage)
	_present_for_challenge_type(BonusEnums.stage_to_string(stage))


func _handle_bonus_stage_result(is_correct: bool) -> void:
	# Translate the just-presented challenge type back into a BonusStage
	# so the manager can record it. Defensive: if it doesn't map, we stop
	# the round rather than feeding a bogus value into the manager.
	var stage := BonusEnums.stage_from_string(_current_challenge_type)
	var outcome := bonus_manager.record_stage_result(stage, is_correct)
	if outcome == BonusEnums.StageOutcome.CONTINUE:
		_advance_bonus_stage()
	else:
		_resolve_card(bonus_manager.get_boosts())


func _resolve_card(boosts: Array) -> void:
	_in_bonus_round = false
	card_resolved.emit(_current_card.character, _primary_correct, boosts)


## Map answer correctness + speed to an SRS rating.
func _determine_rating(correct: bool, elapsed_ms: int) -> int:
	if not correct:
		return FsrsAlgorithm.Rating.AGAIN

	# Fast and correct = Easy, slow = Hard, medium = Good
	if elapsed_ms < 2000:
		return FsrsAlgorithm.Rating.EASY
	elif elapsed_ms < 5000:
		return FsrsAlgorithm.Rating.GOOD
	else:
		return FsrsAlgorithm.Rating.HARD


func get_challenge_prompt(card_data: CharacterData, challenge_type: String) -> String:
	match challenge_type:
		"meaning":
			return card_data.character  # Show character, ask for meaning
		"character":
			return card_data.meaning    # Show meaning, ask for character
		"pinyin":
			return card_data.character  # Show character, ask for pinyin
		"tone":
			return card_data.get_base_pinyin()  # Show pinyin without tone, ask for tone
	return card_data.character


func get_current_answers() -> Dictionary:
	return _current_answers


func is_active() -> bool:
	return _is_active


func is_in_bonus_round() -> bool:
	return _in_bonus_round
