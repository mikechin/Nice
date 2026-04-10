## Tests for SwipeDetector — direction detection from swipe deltas.
extends GdUnitTestSuite

var _detector: SwipeDetector


func before_test() -> void:
	_detector = auto_free(SwipeDetector.new())


# -- _get_swipe_direction --

func test_up_swipe_detected() -> void:
	# Negative Y = upward
	var dir := _detector._get_swipe_direction(Vector2(0, -100))
	assert_str(dir).is_equal("up")


func test_down_swipe_detected() -> void:
	# Positive Y = downward
	var dir := _detector._get_swipe_direction(Vector2(0, 100))
	assert_str(dir).is_equal("down")


func test_left_swipe_detected() -> void:
	# Negative X = leftward
	var dir := _detector._get_swipe_direction(Vector2(-100, 0))
	assert_str(dir).is_equal("left")


func test_right_swipe_detected() -> void:
	# Positive X = rightward
	var dir := _detector._get_swipe_direction(Vector2(100, 0))
	assert_str(dir).is_equal("right")


func test_diagonal_up_right_horizontal_dominant() -> void:
	# X > Y in abs -> horizontal -> right
	var dir := _detector._get_swipe_direction(Vector2(100, -50))
	assert_str(dir).is_equal("right")


func test_diagonal_down_left_vertical_dominant() -> void:
	# Y > X in abs -> vertical -> down
	var dir := _detector._get_swipe_direction(Vector2(-30, 100))
	assert_str(dir).is_equal("down")


func test_diagonal_up_left_vertical_dominant() -> void:
	# Y > X in abs -> vertical -> up
	var dir := _detector._get_swipe_direction(Vector2(-10, -200))
	assert_str(dir).is_equal("up")


# -- state management --

func test_reset_clears_state() -> void:
	_detector.is_swiping = true
	_detector.swipe_start = Vector2(100, 200)
	_detector.reset()
	assert_bool(_detector.is_swiping).is_false()
	assert_that(_detector.swipe_start).is_equal(Vector2.ZERO)


func test_set_enabled_false_resets() -> void:
	_detector.is_swiping = true
	_detector.set_enabled(false)
	assert_bool(_detector.is_enabled).is_false()
	assert_bool(_detector.is_swiping).is_false()


func test_min_swipe_distance_default() -> void:
	assert_float(_detector.min_swipe_distance).is_equal(80.0)
