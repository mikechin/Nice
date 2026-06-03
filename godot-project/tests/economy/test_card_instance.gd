## Tests for CardInstance — the consumable owned copy ("card = rarity × grade").
## Drops raw; shard value scales with rarity; survives a dict round-trip.
extends GdUnitTestSuite


func test_create_drops_raw() -> void:
	var ci := CardInstance.create("好", EconomyEnums.Rarity.RARE, 4)
	assert_str(ci.card_id).is_equal("好")
	assert_int(ci.rarity).is_equal(EconomyEnums.Rarity.RARE)
	assert_int(ci.grade).is_equal(GradeBand.RAW)
	assert_bool(ci.is_raw()).is_true()
	assert_int(ci.dropped_at_depth).is_equal(4)


func test_shard_value_scales_with_rarity() -> void:
	var common := CardInstance.create("a", EconomyEnums.Rarity.COMMON)
	var rare := CardInstance.create("b", EconomyEnums.Rarity.RARE)
	assert_int(rare.shard_value()).is_greater(common.shard_value())


func test_grade_adds_to_shard_value() -> void:
	var raw := CardInstance.create("a", EconomyEnums.Rarity.RARE)
	var graded := CardInstance.create("a", EconomyEnums.Rarity.RARE)
	graded.grade = 9
	assert_int(graded.shard_value()).is_greater(raw.shard_value())


func test_sort_key_rarity_dominates_grade() -> void:
	var rare_raw := CardInstance.create("a", EconomyEnums.Rarity.RARE)
	var common_graded := CardInstance.create("b", EconomyEnums.Rarity.COMMON)
	common_graded.grade = 10
	# A rare beats a maxed-out common at triage.
	assert_int(rare_raw.sort_key()).is_greater(common_graded.sort_key())


func test_round_trips_through_dict() -> void:
	var ci := CardInstance.create("学", EconomyEnums.Rarity.UNCOMMON, 2)
	ci.id = "ci_7"
	ci.grade = 6
	var restored := CardInstance.from_dict(ci.to_dict())
	assert_str(restored.id).is_equal("ci_7")
	assert_str(restored.card_id).is_equal("学")
	assert_int(restored.rarity).is_equal(EconomyEnums.Rarity.UNCOMMON)
	assert_int(restored.grade).is_equal(6)
	assert_int(restored.dropped_at_depth).is_equal(2)
