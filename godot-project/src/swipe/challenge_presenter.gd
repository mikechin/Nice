## ChallengePresenter — Orchestrates the card + answers for each challenge.
## Ties together CardDisplay, AnswerGenerator, and SwipeDetector.
class_name ChallengePresenter
extends Control

signal challenge_completed(card_id: String, challenge_type: String, correct: bool, rating: int)

var card_display: CardDisplay
var swipe_detector: SwipeDetector
var answer_generator: AnswerGenerator

var _current_card: CharacterData
var _current_challenge_type: String
var _current_answers: Dictionary
var _current_loot_rarity: SrsEnums.LootRarity
var _challenge_start_time: float = 0.0
var _pause_start_ms: float = -1.0
var _is_active: bool = false


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


func setup(ag: AnswerGenerator, cd: CardDisplay = null, sd: SwipeDetector = null) -> void:
	answer_generator = ag
	card_display = cd
	swipe_detector = sd
	if swipe_detector:
		if not swipe_detector.swipe_completed.is_connected(_on_swipe):
			swipe_detector.swipe_completed.connect(_on_swipe)


func present_challenge(card_data: CharacterData, challenge_type: String, loot_rarity: SrsEnums.LootRarity) -> void:
	_current_card = card_data
	_current_challenge_type = challenge_type
	_current_loot_rarity = loot_rarity
	_challenge_start_time = Time.get_ticks_msec()
	_pause_start_ms = -1.0
	_is_active = true

	# Generate answer layout
	_current_answers = answer_generator.generate_answers(card_data, challenge_type)

	# Setup card display
	if card_display:
		card_display.setup_for_challenge(card_data, challenge_type, loot_rarity)
		card_display.animate_card_in()

	# Enable swipe input
	if swipe_detector:
		swipe_detector.set_enabled(true)

	# Emit signal for UI to show answer labels
	SignalBus.card_presented.emit(card_data.to_dict(), challenge_type)


func submit_answer(direction: String) -> void:
	_on_swipe(direction)


func _on_swipe(direction: String) -> void:
	if not _is_active:
		return

	_is_active = false
	if swipe_detector:
		swipe_detector.set_enabled(false)

	var correct_dir: String = _current_answers.get("correct_direction", "")
	var is_correct := direction == correct_dir
	var elapsed_ms := roundi(Time.get_ticks_msec() - _challenge_start_time)

	# Determine SRS rating from correctness and speed
	var rating := _determine_rating(is_correct, elapsed_ms)

	# Visual feedback
	if card_display:
		if is_correct:
			card_display.show_correct_feedback()
		else:
			card_display.show_wrong_feedback()

	# Emit result
	SignalBus.card_answered.emit(
		_current_card.to_dict(),
		_current_challenge_type,
		is_correct,
		rating
	)
	challenge_completed.emit(
		_current_card.character,
		_current_challenge_type,
		is_correct,
		rating
	)


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
