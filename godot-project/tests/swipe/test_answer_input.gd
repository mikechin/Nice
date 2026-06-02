## Tests for AnswerInput — rating policy and pause/resume timer compensation.
## (present/swipe wiring needs scene nodes + InputEvents, which don't run in
## headless mode; the pure logic is covered here, mirroring the equivalent
## ChallengePresenter tests.)
extends GdUnitTestSuite

var input: AnswerInput


func before_test() -> void:
	input = AnswerInput.new()


func after_test() -> void:
	input.free()


func test_starts_inactive() -> void:
	assert_bool(input.is_active()).is_false()


# -- rating policy --

func test_rating_incorrect_returns_again() -> void:
	assert_int(input._determine_rating(false, 1000)).is_equal(FsrsAlgorithm.Rating.AGAIN)


func test_rating_incorrect_slow_returns_again() -> void:
	assert_int(input._determine_rating(false, 10000)).is_equal(FsrsAlgorithm.Rating.AGAIN)


func test_rating_fast_correct_returns_easy() -> void:
	assert_int(input._determine_rating(true, 500)).is_equal(FsrsAlgorithm.Rating.EASY)


func test_rating_medium_correct_returns_good() -> void:
	assert_int(input._determine_rating(true, 3000)).is_equal(FsrsAlgorithm.Rating.GOOD)


func test_rating_slow_correct_returns_hard() -> void:
	assert_int(input._determine_rating(true, 7000)).is_equal(FsrsAlgorithm.Rating.HARD)


func test_rating_boundary_2000ms_is_good() -> void:
	# elapsed_ms < 2000 is false at exactly 2000 → GOOD, not EASY.
	assert_int(input._determine_rating(true, 2000)).is_equal(FsrsAlgorithm.Rating.GOOD)


# -- pause/resume compensation --

func test_pause_then_resume_advances_start_time() -> void:
	input._active = true
	input._start_ms = 1000.0
	input._pause_start_ms = -1.0

	input._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_float(input._pause_start_ms).is_greater(0.0)
	var pause_anchor: float = input._pause_start_ms

	input._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_float(input._pause_start_ms).is_equal(-1.0)
	assert_float(input._start_ms).is_greater_equal(1000.0)
	var resume_now := float(Time.get_ticks_msec())
	assert_float(input._start_ms).is_less_equal(1000.0 + (resume_now - pause_anchor) + 50.0)


func test_pause_when_inactive_is_noop() -> void:
	input._active = false
	input._pause_start_ms = -1.0
	input._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_float(input._pause_start_ms).is_equal(-1.0)


func test_focus_out_then_in_also_compensates() -> void:
	input._active = true
	input._start_ms = 500.0
	input._pause_start_ms = -1.0
	input._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_float(input._pause_start_ms).is_greater(0.0)
	input._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_float(input._pause_start_ms).is_equal(-1.0)
	assert_float(input._start_ms).is_greater_equal(500.0)
