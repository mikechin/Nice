## Tests for HandCard — power computation and dict round-trip.
extends GdUnitTestSuite


func test_total_power_is_base_when_no_boosts() -> void:
	var hc := HandCard.create("好", 5, [])
	assert_int(hc.get_total_power()).is_equal(5)


func test_total_power_sums_base_and_boosts() -> void:
	var boosts: Array = [
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.PINYIN),
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.TONE),
	]
	var hc := HandCard.create("好", 7, boosts)
	# 7 base + 2 boosts of +1 each
	assert_int(hc.get_total_power()).is_equal(9)


func test_create_filters_non_powerboost_entries() -> void:
	# Defensive: if the caller hands us a heterogeneous Array, the typed
	# field must not accept the trash.
	var mixed: Array = [
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.MEANING),
		"not a boost",
		null,
	]
	var hc := HandCard.create("好", 3, mixed)
	assert_int(hc.boosts.size()).is_equal(1)


func test_total_power_clamps_at_zero() -> void:
	# Mirrors PowerCalculator.total_power's clamp — a hypothetical
	# negative-amount boost shouldn't drop the card below zero.
	var penalty := PowerBoost.new()
	penalty.amount = -100
	var hc := HandCard.create("好", 2, [penalty])
	assert_int(hc.get_total_power()).is_equal(0)


func test_dict_round_trip_preserves_power_and_boosts() -> void:
	var boosts: Array = [
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.CHARACTER),
		PowerBoost.from_bonus_stage(BonusEnums.BonusStage.PINYIN),
	]
	var hc := HandCard.create("好", 5, boosts)
	var d := hc.to_dict()
	var restored := HandCard.from_dict(d)

	assert_str(restored.card_id).is_equal("好")
	assert_int(restored.base_power).is_equal(5)
	assert_int(restored.boosts.size()).is_equal(2)
	assert_int(restored.get_total_power()).is_equal(hc.get_total_power())
