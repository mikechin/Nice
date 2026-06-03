## Tests for PowerCalculator — base lookup, additive boosts, inversion.
extends GdUnitTestSuite


func test_base_power_inverted_curve() -> void:
	# Spec lock: NEW (just-introduced, hardest to answer) is the strongest
	# on the board; COMMON (mastered routine) is the weakest. If this
	# inversion ever flips, the board game's risk/reward inverts with it.
	var new_power := PowerCalculator.base_power(SrsEnums.LootRarity.NEW_CARD)
	var atf_power := PowerCalculator.base_power(SrsEnums.LootRarity.ABOUT_TO_FORGET)
	var learn_power := PowerCalculator.base_power(SrsEnums.LootRarity.LEARNING)
	var common_power := PowerCalculator.base_power(SrsEnums.LootRarity.KNOWN)

	assert_bool(new_power > atf_power).is_true()
	assert_bool(atf_power > learn_power).is_true()
	assert_bool(learn_power > common_power).is_true()


func test_total_boost_sums_amounts() -> void:
	var boosts: Array[PowerBoost] = [
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.PINYIN),
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.TONE),
	]
	assert_int(PowerCalculator.total_boost(boosts)).is_equal(2)


func test_total_boost_skips_nulls() -> void:
	var boosts: Array[PowerBoost] = [
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.PINYIN),
		null,
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.TONE, 3),
	]
	assert_int(PowerCalculator.total_boost(boosts)).is_equal(4)


func test_total_power_with_no_boosts_equals_base() -> void:
	var empty: Array[PowerBoost] = []
	var power := PowerCalculator.total_power(SrsEnums.LootRarity.NEW_CARD, empty)
	assert_int(power).is_equal(PowerCalculator.base_power(SrsEnums.LootRarity.NEW_CARD))


func test_total_power_three_stages_full_chain() -> void:
	# Most exciting outcome: NEW card, all 3 bonus stages correct.
	var boosts: Array[PowerBoost] = [
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.CHARACTER),
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.PINYIN),
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.TONE),
	]
	var expected := PowerCalculator.base_power(SrsEnums.LootRarity.NEW_CARD) + 3
	assert_int(PowerCalculator.total_power(SrsEnums.LootRarity.NEW_CARD, boosts)).is_equal(expected)


func test_total_power_clamps_at_zero() -> void:
	# Defensive: a hypothetical negative-boost source (penalty) shouldn't
	# drive total below 0.
	var penalty := PowerBoost.new()
	penalty.source = PowerEnums.BoostSource.RADICAL_MATCHUP
	penalty.amount = -50
	var boosts: Array[PowerBoost] = [penalty]
	assert_int(PowerCalculator.total_power(SrsEnums.LootRarity.KNOWN, boosts)).is_equal(0)
