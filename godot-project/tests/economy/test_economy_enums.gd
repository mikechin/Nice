## Tests for EconomyEnums — the rolled print-rarity axis. Confirms the launch
## ceiling (epic gated), naming, and the rank used for triage sorting.
extends GdUnitTestSuite


func test_all_rarities_in_order() -> void:
	var all := EconomyEnums.all_rarities()
	assert_array(all).is_equal([
		EconomyEnums.Rarity.COMMON,
		EconomyEnums.Rarity.UNCOMMON,
		EconomyEnums.Rarity.RARE,
		EconomyEnums.Rarity.EPIC,
	])


func test_launch_excludes_epic() -> void:
	var launch := EconomyEnums.launch_rarities()
	assert_bool(EconomyEnums.Rarity.RARE in launch).is_true()
	assert_bool(EconomyEnums.Rarity.EPIC in launch).is_false()
	assert_int(EconomyEnums.LAUNCH_MAX_RARITY).is_equal(EconomyEnums.Rarity.RARE)


func test_rank_increases_with_rarity() -> void:
	assert_int(EconomyEnums.rarity_rank(EconomyEnums.Rarity.COMMON)) \
		.is_less(EconomyEnums.rarity_rank(EconomyEnums.Rarity.RARE))
	assert_int(EconomyEnums.rarity_rank(EconomyEnums.Rarity.UNCOMMON)) \
		.is_less(EconomyEnums.rarity_rank(EconomyEnums.Rarity.EPIC))


func test_names_and_initials() -> void:
	assert_str(EconomyEnums.rarity_name(EconomyEnums.Rarity.UNCOMMON)).is_equal("Uncommon")
	assert_str(EconomyEnums.rarity_initial(EconomyEnums.Rarity.RARE)).is_equal("R")
