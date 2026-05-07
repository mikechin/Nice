## Tests for ChallengePresenter — rating determination logic.
extends GdUnitTestSuite

var presenter: ChallengePresenter


func before_test() -> void:
	presenter = ChallengePresenter.new()


func after_test() -> void:
	presenter.free()


func test_determine_rating_incorrect_returns_again() -> void:
	var rating := presenter._determine_rating(false, 1000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.AGAIN)


func test_determine_rating_incorrect_slow_returns_again() -> void:
	var rating := presenter._determine_rating(false, 10000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.AGAIN)


func test_determine_rating_fast_correct_returns_easy() -> void:
	var rating := presenter._determine_rating(true, 500)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.EASY)


func test_determine_rating_medium_correct_returns_good() -> void:
	var rating := presenter._determine_rating(true, 3000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.GOOD)


func test_determine_rating_slow_correct_returns_hard() -> void:
	var rating := presenter._determine_rating(true, 7000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.HARD)


func test_determine_rating_boundary_2000ms_is_good() -> void:
	# Exactly at the 2000ms boundary: elapsed_ms < 2000 is false, so GOOD
	var rating := presenter._determine_rating(true, 2000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.GOOD)


# -- get_challenge_prompt: prompt must not leak the answer --

func test_tone_prompt_strips_tone_marks() -> void:
	# Regression: the tone prompt previously returned the toned pinyin (e.g. "hǎo"),
	# leaking the answer that the player is supposed to identify by tone.
	var card := CharacterData.from_dict({
		"character": "好", "pinyin": "hǎo", "tone": 3,
		"meaning": "good", "hsk_level": 2, "radicals": ["女", "子"],
	})
	var prompt := presenter.get_challenge_prompt(card, "tone")
	assert_str(prompt).is_equal("hao")


func test_pinyin_prompt_uses_character() -> void:
	var card := CharacterData.from_dict({
		"character": "好", "pinyin": "hǎo", "tone": 3,
		"meaning": "good", "hsk_level": 2, "radicals": [],
	})
	assert_str(presenter.get_challenge_prompt(card, "pinyin")).is_equal("好")


# -- pause/resume notifications: timer must not penalize backgrounded users --

func test_pause_then_resume_advances_start_time() -> void:
	presenter._is_active = true
	presenter._challenge_start_time = 1000.0
	presenter._pause_start_ms = -1.0

	# Simulate pause: capture pause start
	presenter._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_float(presenter._pause_start_ms).is_greater(0.0)
	var pause_anchor: float = presenter._pause_start_ms

	# Simulate resume after some elapsed time: shift start forward by the pause delta
	presenter._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_float(presenter._pause_start_ms).is_equal(-1.0)
	# Advanced by at least 0 ms; cannot regress past original start.
	assert_float(presenter._challenge_start_time).is_greater_equal(1000.0)
	# And not advanced beyond the now-of-resume.
	var resume_now := float(Time.get_ticks_msec())
	assert_float(presenter._challenge_start_time).is_less_equal(1000.0 + (resume_now - pause_anchor) + 50.0)


func test_pause_when_inactive_is_noop() -> void:
	presenter._is_active = false
	presenter._pause_start_ms = -1.0
	presenter._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_float(presenter._pause_start_ms).is_equal(-1.0)


func test_focus_out_then_in_also_compensates() -> void:
	# Desktop window-level events should pause the timer too.
	presenter._is_active = true
	presenter._challenge_start_time = 500.0
	presenter._pause_start_ms = -1.0
	presenter._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_float(presenter._pause_start_ms).is_greater(0.0)
	presenter._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_float(presenter._pause_start_ms).is_equal(-1.0)
	assert_float(presenter._challenge_start_time).is_greater_equal(500.0)
