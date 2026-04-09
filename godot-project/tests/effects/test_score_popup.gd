## Tests for ScorePopup — floating score label creation.
extends GdUnitTestSuite

var popup: ScorePopup


func before_test() -> void:
	popup = ScorePopup.new()


func test_constants_defined() -> void:
	assert_float(ScorePopup.DEFAULT_RISE_DISTANCE).is_greater(0.0)
	assert_float(ScorePopup.DEFAULT_DURATION).is_greater(0.0)
	assert_int(ScorePopup.DEFAULT_FONT_SIZE).is_greater(0)


func test_score_color_high_multiplier_is_gold() -> void:
	var color := popup._score_color(50, 3.0)
	assert_float(color.r).is_equal(1.0)
	assert_float(color.g).is_equal_approx(0.8, 0.01)


func test_score_color_positive_amount_is_green() -> void:
	var color := popup._score_color(10, 1.0)
	assert_float(color.g).is_equal(1.0)


func test_score_color_negative_is_red() -> void:
	var color := popup._score_color(-5, 1.0)
	assert_float(color.r).is_equal(1.0)


func test_score_scale_high_multiplier() -> void:
	var scale := popup._score_scale(3.0)
	assert_float(scale).is_equal(1.5)


func test_score_scale_default_multiplier() -> void:
	var scale := popup._score_scale(1.0)
	assert_float(scale).is_equal(1.0)
