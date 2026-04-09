## Tests for PlanetBoostManager — milestone unlocks, multipliers, and boost stacking.
extends GdUnitTestSuite

var _boosts: PlanetBoostManager


func before_test() -> void:
	_boosts = PlanetBoostManager.new()


# -- milestone_unlock --

func test_milestone_unlock_25_mastered() -> void:
	var stats := {"total_characters_mastered": 25}
	var unlocked := _boosts.check_milestones(stats)
	assert_bool("coin_boost_1" in unlocked).is_true()
	assert_bool("coin_boost_1" in _boosts.active_boosts).is_true()


func test_milestone_unlock_100_mastered() -> void:
	var stats := {"total_characters_mastered": 100}
	var unlocked := _boosts.check_milestones(stats)
	assert_bool("coin_boost_1" in unlocked).is_true()
	assert_bool("coin_boost_2" in unlocked).is_true()


func test_milestone_unlock_streak_7() -> void:
	var stats := {"current_streak": 7}
	var unlocked := _boosts.check_milestones(stats)
	assert_bool("xp_boost_1" in unlocked).is_true()


func test_milestone_unlock_streak_30() -> void:
	var stats := {"current_streak": 30}
	var unlocked := _boosts.check_milestones(stats)
	assert_bool("xp_boost_1" in unlocked).is_true()
	assert_bool("xp_boost_2" in unlocked).is_true()


func test_milestone_unlock_accuracy_90() -> void:
	var stats := {"accuracy": 0.9}
	var unlocked := _boosts.check_milestones(stats)
	assert_bool("new_card_boost" in unlocked).is_true()


func test_milestone_no_duplicate_unlock() -> void:
	var stats := {"total_characters_mastered": 25}
	_boosts.check_milestones(stats)
	var second := _boosts.check_milestones(stats)
	assert_bool(second.is_empty()).is_true()


func test_milestone_below_threshold_no_unlock() -> void:
	var stats := {"total_characters_mastered": 10}
	var unlocked := _boosts.check_milestones(stats)
	assert_bool("coin_boost_1" not in unlocked).is_true()


# -- multiplier --

func test_multiplier_not_active_returns_one() -> void:
	assert_float(_boosts.get_boost_multiplier("coin_boost_1")).is_equal(1.0)


func test_multiplier_after_unlock() -> void:
	var stats := {"total_characters_mastered": 25}
	_boosts.check_milestones(stats)
	assert_float(_boosts.get_boost_multiplier("coin_boost_1")).is_equal(1.1)


func test_multiplier_coin_boost_2() -> void:
	var stats := {"total_characters_mastered": 100}
	_boosts.check_milestones(stats)
	assert_float(_boosts.get_boost_multiplier("coin_boost_2")).is_equal(1.2)


func test_multiplier_xp_boost_1() -> void:
	var stats := {"current_streak": 7}
	_boosts.check_milestones(stats)
	assert_float(_boosts.get_boost_multiplier("xp_boost_1")).is_equal(1.15)


# -- combined coin multiplier --

func test_combined_coin_multiplier_none_active() -> void:
	assert_float(_boosts.get_combined_coin_multiplier()).is_equal(1.0)


func test_combined_coin_multiplier_one_boost() -> void:
	var stats := {"total_characters_mastered": 25}
	_boosts.check_milestones(stats)
	assert_float(_boosts.get_combined_coin_multiplier()).is_equal_approx(1.1, 0.001)


func test_combined_coin_multiplier_both_boosts() -> void:
	var stats := {"total_characters_mastered": 100}
	_boosts.check_milestones(stats)
	# 1.1 * 1.2 = 1.32
	assert_float(_boosts.get_combined_coin_multiplier()).is_equal_approx(1.32, 0.001)


# -- apply_boosts --

func test_apply_boosts_coin_type() -> void:
	var stats := {"total_characters_mastered": 25}
	_boosts.check_milestones(stats)
	var result := _boosts.apply_boosts(100, "coin")
	# 100 * 1.1 = 110
	assert_int(result).is_equal(110)


func test_apply_boosts_no_matching_type() -> void:
	var stats := {"total_characters_mastered": 25}
	_boosts.check_milestones(stats)
	var result := _boosts.apply_boosts(100, "xp")
	# No xp boosts active, so 100 * 1.0 = 100
	assert_int(result).is_equal(100)


# -- serialization --

func test_to_dict() -> void:
	var stats := {"total_characters_mastered": 25}
	_boosts.check_milestones(stats)
	var dict := _boosts.to_dict()
	assert_bool("coin_boost_1" in dict["active_boosts"]).is_true()


func test_from_dict_round_trip() -> void:
	var stats := {"total_characters_mastered": 100, "current_streak": 7}
	_boosts.check_milestones(stats)
	var dict := _boosts.to_dict()
	var restored := PlanetBoostManager.from_dict(dict)
	assert_bool("coin_boost_1" in restored.active_boosts).is_true()
	assert_bool("coin_boost_2" in restored.active_boosts).is_true()
	assert_bool("xp_boost_1" in restored.active_boosts).is_true()


# -- milestone definitions --

func test_milestone_definitions_complete() -> void:
	var defs := _boosts.get_milestone_definitions()
	assert_int(defs.size()).is_equal(PlanetBoostManager.BOOST_DEFINITIONS.size())


func test_milestone_definitions_show_unlocked_status() -> void:
	var stats := {"total_characters_mastered": 25}
	_boosts.check_milestones(stats)
	var defs := _boosts.get_milestone_definitions()
	var found := false
	for d in defs:
		if d["id"] == "coin_boost_1":
			found = true
			assert_bool(d["unlocked"]).is_true()
	assert_bool(found).is_true()
