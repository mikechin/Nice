## Tests for BonusEnums — stage labels and enum round-trip helpers.
extends GdUnitTestSuite


func test_stage_to_string_all_known() -> void:
	assert_str(BonusEnums.stage_to_string(BonusEnums.BonusStage.MEANING)).is_equal("meaning")
	assert_str(BonusEnums.stage_to_string(BonusEnums.BonusStage.CHARACTER)).is_equal("character")
	assert_str(BonusEnums.stage_to_string(BonusEnums.BonusStage.PINYIN)).is_equal("pinyin")
	assert_str(BonusEnums.stage_to_string(BonusEnums.BonusStage.TONE)).is_equal("tone")


func test_stage_from_string_round_trip() -> void:
	for stage in [
		BonusEnums.BonusStage.MEANING,
		BonusEnums.BonusStage.CHARACTER,
		BonusEnums.BonusStage.PINYIN,
		BonusEnums.BonusStage.TONE,
	]:
		var label := BonusEnums.stage_to_string(stage)
		assert_int(BonusEnums.stage_from_string(label)).is_equal(stage)


func test_stage_from_string_unknown_falls_back_to_meaning() -> void:
	# The fallback exists so callers can pass through challenge_type strings
	# from older code paths without crashing. Picks the safest default.
	assert_int(BonusEnums.stage_from_string("nonsense")).is_equal(BonusEnums.BonusStage.MEANING)


func test_trigger_chance_is_twenty_percent() -> void:
	# Spec lock — changing this changes the game feel and should be deliberate.
	assert_float(BonusEnums.BONUS_TRIGGER_CHANCE).is_equal(0.20)


func test_boost_per_stage_is_one() -> void:
	assert_int(BonusEnums.BOOST_PER_STAGE).is_equal(1)


func test_stage_order_covers_all_four() -> void:
	assert_int(BonusEnums.STAGE_ORDER.size()).is_equal(4)
	for stage in [
		BonusEnums.BonusStage.MEANING,
		BonusEnums.BonusStage.CHARACTER,
		BonusEnums.BonusStage.PINYIN,
		BonusEnums.BonusStage.TONE,
	]:
		assert_bool(stage in BonusEnums.STAGE_ORDER).is_true()
