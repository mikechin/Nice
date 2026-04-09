## CardTierCalculator — Tests calculate_tier() mapping stability to tiers, check_promotion() detecting tier changes.
extends GdUnitTestSuite

var fsrs: FsrsAlgorithm


func before_test() -> void:
	fsrs = FsrsAlgorithm.new()


func test_new_card_is_new_card_tier() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var tier := CardTierCalculator.calculate_tier(cs)
	assert_int(tier).is_equal(CollectionEnums.CardTier.NEW_CARD)


func test_low_stability_is_common() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	# Review once with GOOD to move out of NEW state with low stability
	var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.GOOD, now)
	cs.update_state("meaning", reviewed)
	# Stability should be around w[2] = 2.3 which is >= TIER_COMMON_STABILITY (1.0)
	var tier := CardTierCalculator.calculate_tier(cs)
	assert_int(tier).is_equal(CollectionEnums.CardTier.COMMON)


func test_tier_from_stability_new_card() -> void:
	var tier := CardTierCalculator.tier_from_stability(0.5)
	assert_int(tier).is_equal(CollectionEnums.CardTier.NEW_CARD)


func test_tier_from_stability_common() -> void:
	var tier := CardTierCalculator.tier_from_stability(SrsConfig.TIER_COMMON_STABILITY)
	assert_int(tier).is_equal(CollectionEnums.CardTier.COMMON)


func test_tier_from_stability_uncommon() -> void:
	var tier := CardTierCalculator.tier_from_stability(SrsConfig.TIER_UNCOMMON_STABILITY)
	assert_int(tier).is_equal(CollectionEnums.CardTier.UNCOMMON)


func test_tier_from_stability_rare() -> void:
	var tier := CardTierCalculator.tier_from_stability(SrsConfig.TIER_RARE_STABILITY)
	assert_int(tier).is_equal(CollectionEnums.CardTier.RARE)


func test_tier_from_stability_epic() -> void:
	var tier := CardTierCalculator.tier_from_stability(SrsConfig.TIER_EPIC_STABILITY)
	assert_int(tier).is_equal(CollectionEnums.CardTier.EPIC)


func test_tier_from_stability_legendary() -> void:
	var tier := CardTierCalculator.tier_from_stability(SrsConfig.TIER_LEGENDARY_STABILITY)
	assert_int(tier).is_equal(CollectionEnums.CardTier.LEGENDARY)


func test_check_promotion_detected() -> void:
	var result := CardTierCalculator.check_promotion(
		SrsConfig.TIER_COMMON_STABILITY,
		SrsConfig.TIER_UNCOMMON_STABILITY
	)
	assert_bool(result["promoted"]).is_true()
	assert_int(result["old_tier"]).is_equal(CollectionEnums.CardTier.COMMON)
	assert_int(result["new_tier"]).is_equal(CollectionEnums.CardTier.UNCOMMON)


func test_check_promotion_not_detected_same_tier() -> void:
	var result := CardTierCalculator.check_promotion(2.0, 5.0)
	assert_bool(result["promoted"]).is_false()
	assert_int(result["old_tier"]).is_equal(result["new_tier"])
