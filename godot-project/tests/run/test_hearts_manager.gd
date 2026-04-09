## Tests for HeartsManager — heart tracking, loss, recovery, and game over.
extends GdUnitTestSuite

var _hearts: HeartsManager


func before_test() -> void:
	_hearts = HeartsManager.new()


# -- reset --

func test_reset_sets_hearts_to_max() -> void:
	_hearts.reset(5)
	assert_int(_hearts.current_hearts).is_equal(5)
	assert_int(_hearts.max_hearts).is_equal(5)


func test_reset_default_three() -> void:
	_hearts.reset()
	assert_int(_hearts.current_hearts).is_equal(3)
	assert_int(_hearts.max_hearts).is_equal(3)


func test_reset_restores_after_loss() -> void:
	_hearts.reset(3)
	_hearts.lose_heart()
	_hearts.reset(3)
	assert_int(_hearts.current_hearts).is_equal(3)


# -- lose_heart --

func test_lose_heart_decrements() -> void:
	_hearts.reset(3)
	_hearts.lose_heart()
	assert_int(_hearts.current_hearts).is_equal(2)


func test_lose_heart_twice() -> void:
	_hearts.reset(3)
	_hearts.lose_heart()
	_hearts.lose_heart()
	assert_int(_hearts.current_hearts).is_equal(1)


func test_lose_heart_does_not_go_below_zero() -> void:
	_hearts.reset(1)
	_hearts.lose_heart()
	_hearts.lose_heart()
	assert_int(_hearts.current_hearts).is_equal(0)


# -- game_over --

func test_game_over_when_zero_hearts() -> void:
	_hearts.reset(1)
	_hearts.lose_heart()
	assert_bool(_hearts.is_game_over()).is_true()


func test_not_game_over_with_hearts() -> void:
	_hearts.reset(3)
	assert_bool(_hearts.is_game_over()).is_false()


func test_not_game_over_after_partial_loss() -> void:
	_hearts.reset(3)
	_hearts.lose_heart()
	assert_bool(_hearts.is_game_over()).is_false()


# -- add_heart --

func test_add_heart_increments() -> void:
	_hearts.reset(3)
	_hearts.lose_heart()
	_hearts.add_heart()
	assert_int(_hearts.current_hearts).is_equal(3)


func test_add_heart_not_above_max() -> void:
	_hearts.reset(3)
	_hearts.add_heart(5)
	assert_int(_hearts.current_hearts).is_equal(3)


func test_add_heart_multiple() -> void:
	_hearts.reset(5)
	_hearts.lose_heart()
	_hearts.lose_heart()
	_hearts.lose_heart()
	_hearts.add_heart(2)
	assert_int(_hearts.current_hearts).is_equal(4)


# -- hearts_percentage --

func test_hearts_percentage_full() -> void:
	_hearts.reset(4)
	assert_float(_hearts.get_hearts_percentage()).is_equal(1.0)


func test_hearts_percentage_half() -> void:
	_hearts.reset(4)
	_hearts.lose_heart()
	_hearts.lose_heart()
	assert_float(_hearts.get_hearts_percentage()).is_equal(0.5)


func test_hearts_percentage_zero() -> void:
	_hearts.reset(2)
	_hearts.lose_heart()
	_hearts.lose_heart()
	assert_float(_hearts.get_hearts_percentage()).is_equal(0.0)
