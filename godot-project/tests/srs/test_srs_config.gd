## Tests for SrsConfig — validates configuration constants.
extends GdUnitTestSuite


# -- thresholds --

func test_about_to_forget_threshold_in_range() -> void:
	assert_float(SrsConfig.ABOUT_TO_FORGET_THRESHOLD).is_greater(0.0)
	assert_float(SrsConfig.ABOUT_TO_FORGET_THRESHOLD).is_less(1.0)


func test_well_known_threshold_in_range() -> void:
	assert_float(SrsConfig.WELL_KNOWN_THRESHOLD).is_greater(0.0)
	assert_float(SrsConfig.WELL_KNOWN_THRESHOLD).is_less(1.0)


func test_well_known_above_about_to_forget() -> void:
	assert_float(SrsConfig.WELL_KNOWN_THRESHOLD).is_greater(SrsConfig.ABOUT_TO_FORGET_THRESHOLD)


func test_desired_retention_in_range() -> void:
	assert_float(SrsConfig.DEFAULT_DESIRED_RETENTION).is_greater(0.0)
	assert_float(SrsConfig.DEFAULT_DESIRED_RETENTION).is_less_equal(1.0)


# -- pack composition ratios sum to ~1.0 --

func test_pack_ratios_sum_to_one() -> void:
	var total := SrsConfig.PACK_COMMON_RATIO + SrsConfig.PACK_STRUGGLING_RATIO + SrsConfig.PACK_NEW_RATIO + SrsConfig.PACK_RETURNING_RATIO
	assert_float(total).is_equal_approx(1.0, 0.01)


# -- tier stability ordering --

func test_tier_stability_ordering() -> void:
	assert_float(SrsConfig.TIER_COMMON_STABILITY).is_less(SrsConfig.TIER_UNCOMMON_STABILITY)
	assert_float(SrsConfig.TIER_UNCOMMON_STABILITY).is_less(SrsConfig.TIER_RARE_STABILITY)
	assert_float(SrsConfig.TIER_RARE_STABILITY).is_less(SrsConfig.TIER_EPIC_STABILITY)
	assert_float(SrsConfig.TIER_EPIC_STABILITY).is_less(SrsConfig.TIER_LEGENDARY_STABILITY)


func test_tier_stabilities_positive() -> void:
	assert_float(SrsConfig.TIER_COMMON_STABILITY).is_greater(0.0)
	assert_float(SrsConfig.TIER_UNCOMMON_STABILITY).is_greater(0.0)
	assert_float(SrsConfig.TIER_RARE_STABILITY).is_greater(0.0)
	assert_float(SrsConfig.TIER_EPIC_STABILITY).is_greater(0.0)
	assert_float(SrsConfig.TIER_LEGENDARY_STABILITY).is_greater(0.0)


# -- pack size --

func test_pack_size_default_is_twelve() -> void:
	assert_int(SrsConfig.PACK_SIZE_DEFAULT).is_equal(12)


# -- new card limits --

func test_new_card_session_limit_within_daily() -> void:
	assert_int(SrsConfig.MAX_NEW_CARDS_PER_SESSION).is_less_equal(SrsConfig.MAX_NEW_CARDS_PER_DAY)


# -- maximum interval --

func test_maximum_interval_positive() -> void:
	assert_int(SrsConfig.MAXIMUM_INTERVAL).is_greater(0)
