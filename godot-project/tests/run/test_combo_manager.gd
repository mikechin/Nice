## Tests for ComboManager — combo tracking, milestones, and multiplier scaling.
extends GdUnitTestSuite

var _combo: ComboManager


func before_test() -> void:
	_combo = ComboManager.new()


# -- increment --

func test_increment_increases_combo() -> void:
	assert_int(_combo.current_combo).is_equal(0)
	_combo.increment()
	assert_int(_combo.current_combo).is_equal(1)


func test_increment_multiple_times() -> void:
	for i in 5:
		_combo.increment()
	assert_int(_combo.current_combo).is_equal(5)


# -- break_combo --

func test_break_resets_to_zero() -> void:
	_combo.increment()
	_combo.increment()
	_combo.break_combo()
	assert_int(_combo.current_combo).is_equal(0)


func test_break_when_already_zero() -> void:
	_combo.break_combo()
	assert_int(_combo.current_combo).is_equal(0)


# -- best_combo --

func test_best_combo_tracked() -> void:
	for i in 7:
		_combo.increment()
	_combo.break_combo()
	for i in 3:
		_combo.increment()
	assert_int(_combo.best_combo).is_equal(7)


func test_best_combo_updates_on_new_record() -> void:
	for i in 3:
		_combo.increment()
	_combo.break_combo()
	for i in 10:
		_combo.increment()
	assert_int(_combo.best_combo).is_equal(10)


# -- multiplier_scaling --

func test_multiplier_base_at_zero_combo() -> void:
	assert_float(_combo.get_multiplier()).is_equal(1.0)


func test_multiplier_base_below_five() -> void:
	for i in 4:
		_combo.increment()
	assert_float(_combo.get_multiplier()).is_equal(1.0)


func test_multiplier_at_five_combo() -> void:
	for i in 5:
		_combo.increment()
	assert_float(_combo.get_multiplier()).is_equal(1.25)


func test_multiplier_at_ten_combo() -> void:
	for i in 10:
		_combo.increment()
	assert_float(_combo.get_multiplier()).is_equal(1.5)


func test_multiplier_at_twenty_combo() -> void:
	for i in 20:
		_combo.increment()
	assert_float(_combo.get_multiplier()).is_equal(2.0)


func test_multiplier_at_fifty_combo() -> void:
	for i in 50:
		_combo.increment()
	assert_float(_combo.get_multiplier()).is_equal(3.0)


# -- milestone_detection --

func test_milestone_detection_at_ten() -> void:
	assert_bool(_combo.is_milestone(10)).is_true()


func test_milestone_detection_at_five() -> void:
	assert_bool(_combo.is_milestone(5)).is_true()


func test_milestone_detection_non_milestone() -> void:
	assert_bool(_combo.is_milestone(7)).is_false()


# -- next_milestone --

func test_next_milestone_from_zero() -> void:
	assert_int(_combo.get_next_milestone()).is_equal(5)


func test_next_milestone_after_five() -> void:
	for i in 5:
		_combo.increment()
	assert_int(_combo.get_next_milestone()).is_equal(10)


func test_next_milestone_after_all_passed() -> void:
	for i in 100:
		_combo.increment()
	assert_int(_combo.get_next_milestone()).is_equal(-1)


# -- progress_to_next_milestone --

func test_progress_at_zero() -> void:
	assert_float(_combo.get_progress_to_next_milestone()).is_equal(0.0)


func test_progress_past_all_milestones() -> void:
	for i in 100:
		_combo.increment()
	assert_float(_combo.get_progress_to_next_milestone()).is_equal(1.0)


# -- reset --

func test_reset_clears_combo() -> void:
	for i in 5:
		_combo.increment()
	_combo.reset()
	assert_int(_combo.current_combo).is_equal(0)
