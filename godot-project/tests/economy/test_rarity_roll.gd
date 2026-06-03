## Tests for RarityRoll — the weighted drop-time rarity roll (D7).
## weights/probabilities are the deterministic core (asserted structurally);
## roll is tested for seed reproducibility and staying within the launch set.
extends GdUnitTestSuite


func test_every_launch_tier_has_a_floor_at_depth_zero() -> void:
	# Nonzero floor for all launch-active tiers from drop #1 (no streak/clutch).
	var w := RarityRoll.weights(0, 0, false)
	assert_float(w[EconomyEnums.Rarity.COMMON]).is_greater(0.0)
	assert_float(w[EconomyEnums.Rarity.UNCOMMON]).is_greater(0.0)
	assert_float(w[EconomyEnums.Rarity.RARE]).is_greater(0.0)


func test_epic_is_gated_at_launch() -> void:
	# Epic stays at zero weight everywhere until the ceiling lifts.
	assert_float(RarityRoll.weights(0, 0, false)[EconomyEnums.Rarity.EPIC]).is_equal(0.0)
	assert_float(RarityRoll.weights(10, 20, true)[EconomyEnums.Rarity.EPIC]).is_equal(0.0)


func test_common_dominates_at_shallow_depth() -> void:
	var p := RarityRoll.probabilities(0, 0, false)
	assert_float(p[EconomyEnums.Rarity.COMMON]).is_greater(0.7)


func test_depth_shifts_mass_off_common() -> void:
	var shallow := RarityRoll.probabilities(0, 0, false)
	var deep := RarityRoll.probabilities(8, 0, false)
	# Deeper → fewer commons, more rares.
	assert_float(deep[EconomyEnums.Rarity.COMMON]).is_less(shallow[EconomyEnums.Rarity.COMMON])
	assert_float(deep[EconomyEnums.Rarity.RARE]).is_greater(shallow[EconomyEnums.Rarity.RARE])


func test_streak_and_clutch_raise_upper_tiers() -> void:
	var base := RarityRoll.probabilities(3, 0, false)
	var streaked := RarityRoll.probabilities(3, 10, false)
	var clutched := RarityRoll.probabilities(3, 0, true)
	assert_float(streaked[EconomyEnums.Rarity.RARE]).is_greater(base[EconomyEnums.Rarity.RARE])
	assert_float(clutched[EconomyEnums.Rarity.UNCOMMON]).is_greater(base[EconomyEnums.Rarity.UNCOMMON])


func test_probabilities_sum_to_one() -> void:
	var p := RarityRoll.probabilities(5, 7, true)
	var total := 0.0
	for r in p:
		total += p[r]
	assert_float(total).is_equal_approx(1.0, 0.0001)


func test_roll_is_seed_reproducible() -> void:
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 99
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 99
	var a: Array = []
	var b: Array = []
	for i in 20:
		a.append(RarityRoll.roll(4, 3, false, rng1))
		b.append(RarityRoll.roll(4, 3, false, rng2))
	assert_array(a).is_equal(b)


func test_roll_never_returns_epic_at_launch() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	for i in 200:
		var r := RarityRoll.roll(10, 20, true, rng)
		assert_bool(r != EconomyEnums.Rarity.EPIC).is_true()
