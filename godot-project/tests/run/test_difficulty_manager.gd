## Tests for DifficultyManager — card pacing, speed scaling, and round escalation.
extends GdUnitTestSuite

var _diff: DifficultyManager


func before_test() -> void:
	_diff = DifficultyManager.new()


# -- initial interval --

func test_initial_interval_is_base() -> void:
	assert_float(_diff.get_current_interval()).is_equal(_diff.base_card_interval)


# -- combo speeds up --

func test_combo_speeds_up_interval() -> void:
	var before := _diff.get_current_interval()
	_diff.on_combo_changed(20)
	var after := _diff.get_current_interval()
	assert_float(after).is_less(before)


func test_higher_combo_lower_interval() -> void:
	_diff.on_combo_changed(10)
	var interval_10 := _diff.get_current_interval()
	_diff.on_combo_changed(30)
	var interval_30 := _diff.get_current_interval()
	assert_float(interval_30).is_less(interval_10)


func test_low_combo_no_reduction() -> void:
	# Combo below 10 has floor(combo/10)=0 so no combo reduction
	_diff.on_combo_changed(5)
	assert_float(_diff.get_current_interval()).is_equal(_diff.base_card_interval)


# -- min interval respected --

func test_min_interval_respected() -> void:
	_diff.on_combo_changed(500)
	assert_float(_diff.get_current_interval()).is_greater_equal(_diff.min_interval)


func test_min_interval_with_high_round() -> void:
	_diff.on_round_changed(20)
	_diff.on_combo_changed(200)
	assert_float(_diff.get_current_interval()).is_greater_equal(_diff.min_interval)


# -- cards per round increases --

func test_cards_per_round_base() -> void:
	var base := _diff.get_cards_for_round(0)
	assert_int(base).is_equal(DifficultyManager.BASE_CARDS_PER_ROUND)


func test_cards_per_round_increases_with_round() -> void:
	var round_0 := _diff.get_cards_for_round(0)
	var round_3 := _diff.get_cards_for_round(3)
	assert_int(round_3).is_greater(round_0)


func test_cards_per_round_formula() -> void:
	var round_num := 4
	var expected := DifficultyManager.BASE_CARDS_PER_ROUND + DifficultyManager.CARDS_PER_ROUND_INCREASE * round_num
	assert_int(_diff.get_cards_for_round(round_num)).is_equal(expected)


# -- round changes --

func test_round_change_adjusts_interval() -> void:
	var before := _diff.get_current_interval()
	_diff.on_round_changed(3)
	var after := _diff.get_current_interval()
	assert_float(after).is_less(before)


func test_reset_restores_base_interval() -> void:
	_diff.on_round_changed(5)
	_diff.on_combo_changed(30)
	_diff.reset()
	assert_float(_diff.get_current_interval()).is_equal(_diff.base_card_interval)


# -- challenge type weights --

func test_early_rounds_no_pinyin_tone() -> void:
	var weights := _diff.get_challenge_type_weights(0)
	assert_float(weights["pinyin"]).is_equal(0.0)
	assert_float(weights["tone"]).is_equal(0.0)


func test_late_rounds_all_types_present() -> void:
	var weights := _diff.get_challenge_type_weights(5)
	assert_float(weights["pinyin"]).is_greater(0.0)
	assert_float(weights["tone"]).is_greater(0.0)
	assert_float(weights["meaning"]).is_greater(0.0)
	assert_float(weights["character"]).is_greater(0.0)
