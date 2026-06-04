## Tests for InstancePower — the flat-base power scalar (M5). Power comes from what
## you EARNED (rarity × grade), never from poor knowledge — these lock that curve.
extends GdUnitTestSuite


func test_common_raw_is_the_unit_floor() -> void:
	# A fresh common drop carries its full base effect and nothing more.
	assert_float(InstancePower.scalar(EconomyEnums.Rarity.COMMON, GradeBand.RAW)).is_equal_approx(1.0, 0.0001)


func test_grade_mult_raw_to_psa10() -> void:
	assert_float(InstancePower.grade_mult(GradeBand.RAW)).is_equal_approx(1.0, 0.0001)
	assert_float(InstancePower.grade_mult(10)).is_equal_approx(1.8, 0.0001)


func test_rarity_strictly_increases_power() -> void:
	var c := InstancePower.rarity_mult(EconomyEnums.Rarity.COMMON)
	var u := InstancePower.rarity_mult(EconomyEnums.Rarity.UNCOMMON)
	var r := InstancePower.rarity_mult(EconomyEnums.Rarity.RARE)
	var e := InstancePower.rarity_mult(EconomyEnums.Rarity.EPIC)
	assert_bool(c < u and u < r and r < e).is_true()


func test_grade_strictly_increases_power_within_a_rarity() -> void:
	var raw := InstancePower.scalar(EconomyEnums.Rarity.RARE, GradeBand.RAW)
	var psa5 := InstancePower.scalar(EconomyEnums.Rarity.RARE, 5)
	var psa10 := InstancePower.scalar(EconomyEnums.Rarity.RARE, 10)
	assert_bool(raw < psa5 and psa5 < psa10).is_true()


func test_top_card_is_the_strongest() -> void:
	# Epic PSA10 = 3.0 × 1.8 = 5.4 — the ceiling of the model.
	assert_float(InstancePower.scalar(EconomyEnums.Rarity.EPIC, 10)).is_equal_approx(5.4, 0.0001)
