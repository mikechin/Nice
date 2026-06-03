## Tests for BonusTrigger — eligibility and seeded-RNG roll behavior.
extends GdUnitTestSuite


func test_common_is_not_eligible() -> void:
	assert_bool(BonusTrigger.is_eligible(SrsEnums.LootRarity.KNOWN)).is_false()


func test_learning_about_to_forget_new_are_eligible() -> void:
	assert_bool(BonusTrigger.is_eligible(SrsEnums.LootRarity.LEARNING)).is_true()
	assert_bool(BonusTrigger.is_eligible(SrsEnums.LootRarity.ABOUT_TO_FORGET)).is_true()
	assert_bool(BonusTrigger.is_eligible(SrsEnums.LootRarity.NEW_CARD)).is_true()


func test_common_never_triggers() -> void:
	# Even with a forced-low RNG, COMMON should refuse to fire.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var outcome := BonusTrigger.roll(SrsEnums.LootRarity.KNOWN, rng)
	assert_int(outcome).is_equal(BonusEnums.BonusOutcome.NOT_TRIGGERED)


func test_eligible_triggers_when_roll_below_threshold() -> void:
	# Find a seed whose first randf() < 0.20 — confirms the firing path works.
	var rng := RandomNumberGenerator.new()
	for s in range(1, 200):
		rng.seed = s
		# Peek at the value the way roll() will consume it.
		var probe := RandomNumberGenerator.new()
		probe.seed = s
		if probe.randf() < BonusEnums.BONUS_TRIGGER_CHANCE:
			var outcome := BonusTrigger.roll(SrsEnums.LootRarity.NEW_CARD, rng)
			assert_int(outcome).is_equal(BonusEnums.BonusOutcome.TRIGGERED)
			return
	fail("No seed in [1, 200) produced a roll below the trigger threshold — RNG misconfigured?")


func test_eligible_does_not_trigger_when_roll_above_threshold() -> void:
	var rng := RandomNumberGenerator.new()
	for s in range(1, 200):
		rng.seed = s
		var probe := RandomNumberGenerator.new()
		probe.seed = s
		if probe.randf() >= BonusEnums.BONUS_TRIGGER_CHANCE:
			var outcome := BonusTrigger.roll(SrsEnums.LootRarity.LEARNING, rng)
			assert_int(outcome).is_equal(BonusEnums.BonusOutcome.NOT_TRIGGERED)
			return
	fail("No seed in [1, 200) produced a roll at/above the trigger threshold")


func test_default_rng_does_not_crash() -> void:
	# Smoke test — calling without an injected RNG should construct one
	# internally and return a valid outcome.
	var outcome := BonusTrigger.roll(SrsEnums.LootRarity.NEW_CARD)
	assert_bool(
		outcome == BonusEnums.BonusOutcome.TRIGGERED
		or outcome == BonusEnums.BonusOutcome.NOT_TRIGGERED
	).is_true()


func test_rate_converges_to_twenty_percent_over_many_rolls() -> void:
	# Statistical sanity: across 5000 rolls the firing rate should sit
	# inside a generous window around 20%. Seeded for determinism.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var hits := 0
	var total := 5000
	for i in total:
		if BonusTrigger.roll(SrsEnums.LootRarity.NEW_CARD, rng) == BonusEnums.BonusOutcome.TRIGGERED:
			hits += 1
	var rate := float(hits) / float(total)
	# Generous 5-point band — tolerates RNG variance, would still catch a
	# transposed digit (e.g. 0.02 instead of 0.20).
	assert_float(rate).is_between(0.15, 0.25)
