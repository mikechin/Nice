## Tests for PowerBoost — factory helpers and dict round-trip.
extends GdUnitTestSuite


func test_from_bonus_stage_default_amount() -> void:
	var b := PowerBoost.from_bonus_stage(BonusEnums.BonusStage.PINYIN)
	assert_int(b.source).is_equal(PowerEnums.BoostSource.BONUS_STAGE)
	assert_int(b.amount).is_equal(BonusEnums.BOOST_PER_STAGE)
	assert_str(b.label).is_equal("pinyin")


func test_from_bonus_stage_custom_amount() -> void:
	var b := PowerBoost.from_bonus_stage(BonusEnums.BonusStage.TONE, 2)
	assert_int(b.amount).is_equal(2)
	assert_str(b.label).is_equal("tone")


func test_dict_round_trip() -> void:
	var b := PowerBoost.from_bonus_stage(BonusEnums.BonusStage.CHARACTER)
	var d := b.to_dict()
	var restored := PowerBoost.from_dict(d)
	assert_int(restored.source).is_equal(b.source)
	assert_int(restored.amount).is_equal(b.amount)
	assert_str(restored.label).is_equal(b.label)
