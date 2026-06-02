## AnswerInput — The reusable "answer one card" core.
##
## Presents a single (card, challenge_type) via CardDisplay, generates the
## four directional options via AnswerGenerator, captures the swipe via
## SwipeDetector, times the response, maps it to an FSRS rating, fires the
## correct/wrong feedback, and emits `answered`. It knows nothing about
## bonus rounds, power, mobs, runs, or scoring — callers layer that on top
## of the `answered` signal.
##
## This is the shared input mechanic for dungeon combat (CombatController).
## ChallengePresenter (the study flow) still has its own copy of this logic;
## rebasing it onto AnswerInput to dedupe is a deferred follow-up so this
## change doesn't destabilize the working study flow.
##
## Timer pause/resume compensation lives here so a backgrounded mobile user
## is never penalized with a HARD rating. It records nothing to FSRS — the
## caller owns the single honest record_review commit.
class_name AnswerInput
extends Node

## Fires once per presented challenge, just after feedback starts.
signal answered(card_id: String, challenge_type: String, correct: bool, rating: int)

var card_display: CardDisplay
var swipe_detector: SwipeDetector
var answer_generator: AnswerGenerator

var _card: CharacterData
var _challenge_type: String
var _answers: Dictionary
var _loot_rarity: SrsEnums.LootRarity
var _start_ms: float = 0.0
var _pause_start_ms: float = -1.0
var _active: bool = false


func setup(ag: AnswerGenerator, cd: CardDisplay = null, sd: SwipeDetector = null) -> void:
	answer_generator = ag
	card_display = cd
	swipe_detector = sd
	if swipe_detector and not swipe_detector.swipe_completed.is_connected(_on_swipe):
		swipe_detector.swipe_completed.connect(_on_swipe)


func _notification(what: int) -> void:
	# Freeze the response timer while the app is backgrounded / unfocused so a
	# returning user isn't punished with a slow (HARD) rating.
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if _active and _pause_start_ms < 0.0:
				_pause_start_ms = Time.get_ticks_msec()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			if _pause_start_ms >= 0.0:
				_start_ms += Time.get_ticks_msec() - _pause_start_ms
				_pause_start_ms = -1.0


## Present a challenge. `animate_in` controls the card entrance — true for a
## fresh card, false when reusing the same card for a new facet.
func present(card_data: CharacterData, challenge_type: String, loot_rarity: SrsEnums.LootRarity, animate_in: bool = true) -> void:
	_card = card_data
	_challenge_type = challenge_type
	_loot_rarity = loot_rarity
	_answers = answer_generator.generate_answers(card_data, challenge_type)

	if card_display:
		card_display.setup_for_challenge(card_data, challenge_type, loot_rarity)
		if animate_in:
			card_display.animate_card_in()

	_start_ms = Time.get_ticks_msec()
	_pause_start_ms = -1.0
	_active = true
	if swipe_detector:
		swipe_detector.set_enabled(true)

	SignalBus.card_presented.emit(card_data.to_dict(), challenge_type)


func submit_answer(direction: String) -> void:
	_on_swipe(direction)


func _on_swipe(direction: String) -> void:
	if not _active:
		return
	_active = false
	if swipe_detector:
		swipe_detector.set_enabled(false)

	var correct_dir: String = _answers.get("correct_direction", "")
	var is_correct := direction == correct_dir
	var elapsed_ms := roundi(Time.get_ticks_msec() - _start_ms)
	var rating := _determine_rating(is_correct, elapsed_ms)

	if card_display:
		if is_correct:
			card_display.show_correct_feedback()
		else:
			card_display.show_wrong_feedback()

	SignalBus.card_answered.emit(_card.to_dict(), _challenge_type, is_correct, rating)
	answered.emit(_card.character, _challenge_type, is_correct, rating)


## Map answer correctness + speed to an SRS rating. Identical policy to the
## study flow: fast+correct = Easy, medium = Good, slow = Hard, wrong = Again.
func _determine_rating(correct: bool, elapsed_ms: int) -> int:
	if not correct:
		return FsrsAlgorithm.Rating.AGAIN
	if elapsed_ms < 2000:
		return FsrsAlgorithm.Rating.EASY
	elif elapsed_ms < 5000:
		return FsrsAlgorithm.Rating.GOOD
	else:
		return FsrsAlgorithm.Rating.HARD


func get_current_answers() -> Dictionary:
	return _answers


func is_active() -> bool:
	return _active
