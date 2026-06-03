## Tests for GradeBand — the PSA scale and its two-cap math. The reachable top
## grade is min(rarity ceiling, mastery reach); PSA 10 is doubly earned.
extends GdUnitTestSuite


func test_raw_is_the_drop_default() -> void:
	assert_bool(GradeBand.is_raw(GradeBand.RAW)).is_true()
	assert_bool(GradeBand.is_raw(1)).is_false()
	assert_str(GradeBand.grade_name(GradeBand.RAW)).is_equal("Raw")
	assert_str(GradeBand.grade_name(9)).is_equal("PSA 9")


func test_rarity_cap_climbs_with_rarity() -> void:
	assert_int(GradeBand.rarity_cap(EconomyEnums.Rarity.COMMON)).is_less(10)
	assert_int(GradeBand.rarity_cap(EconomyEnums.Rarity.RARE)).is_equal(10)
	# Only rare/epic can ever reach PSA 10.
	assert_int(GradeBand.rarity_cap(EconomyEnums.Rarity.UNCOMMON)).is_less(10)


func test_mastery_cap_climbs_with_stability() -> void:
	var low := GradeBand.mastery_cap(0.0)
	var mid := GradeBand.mastery_cap(30.0)
	var high := GradeBand.mastery_cap(200.0)
	assert_int(low).is_less(mid)
	assert_int(mid).is_less_equal(high)
	# PSA 10 is only reachable at the deepest mastery band.
	assert_int(high).is_equal(10)
	assert_int(low).is_less(10)


func test_ceiling_is_the_lower_of_the_two_caps() -> void:
	# Rare roll but shallow mastery → mastery is the binding cap.
	var rare_unmastered := GradeBand.ceiling(EconomyEnums.Rarity.RARE, 0.0)
	assert_int(rare_unmastered).is_equal(GradeBand.mastery_cap(0.0))
	# Common roll but deep mastery → rarity is the binding cap.
	var common_mastered := GradeBand.ceiling(EconomyEnums.Rarity.COMMON, 300.0)
	assert_int(common_mastered).is_equal(GradeBand.rarity_cap(EconomyEnums.Rarity.COMMON))


func test_psa_10_needs_rare_roll_and_deep_mastery() -> void:
	assert_int(GradeBand.ceiling(EconomyEnums.Rarity.RARE, 300.0)).is_equal(10)
	# Either piece missing → below 10.
	assert_int(GradeBand.ceiling(EconomyEnums.Rarity.COMMON, 300.0)).is_less(10)
	assert_int(GradeBand.ceiling(EconomyEnums.Rarity.RARE, 5.0)).is_less(10)
