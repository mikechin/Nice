## CollectionEnums — Tests tier_name(), tier_color() returns non-white for each known tier.
extends GdUnitTestSuite


func before_test() -> void:
	pass


func test_tier_name_locked() -> void:
	assert_str(CollectionEnums.tier_name(CollectionEnums.CardTier.LOCKED)).is_equal("Locked")


func test_tier_name_new_card() -> void:
	assert_str(CollectionEnums.tier_name(CollectionEnums.CardTier.NEW_CARD)).is_equal("New")


func test_tier_name_common() -> void:
	assert_str(CollectionEnums.tier_name(CollectionEnums.CardTier.COMMON)).is_equal("Common")


func test_tier_name_uncommon() -> void:
	assert_str(CollectionEnums.tier_name(CollectionEnums.CardTier.UNCOMMON)).is_equal("Uncommon")


func test_tier_name_rare() -> void:
	assert_str(CollectionEnums.tier_name(CollectionEnums.CardTier.RARE)).is_equal("Rare")


func test_tier_name_epic() -> void:
	assert_str(CollectionEnums.tier_name(CollectionEnums.CardTier.EPIC)).is_equal("Epic")


func test_tier_name_legendary() -> void:
	assert_str(CollectionEnums.tier_name(CollectionEnums.CardTier.LEGENDARY)).is_equal("Legendary")


func test_tier_color_locked_not_white() -> void:
	var c := CollectionEnums.tier_color(CollectionEnums.CardTier.LOCKED)
	assert_bool(c.is_equal_approx(Color.WHITE)).is_false()


func test_tier_color_new_card_not_white() -> void:
	var c := CollectionEnums.tier_color(CollectionEnums.CardTier.NEW_CARD)
	assert_bool(c.is_equal_approx(Color.WHITE)).is_false()


func test_tier_color_uncommon_not_white() -> void:
	var c := CollectionEnums.tier_color(CollectionEnums.CardTier.UNCOMMON)
	assert_bool(c.is_equal_approx(Color.WHITE)).is_false()


func test_tier_color_rare_not_white() -> void:
	var c := CollectionEnums.tier_color(CollectionEnums.CardTier.RARE)
	assert_bool(c.is_equal_approx(Color.WHITE)).is_false()


func test_tier_color_epic_not_white() -> void:
	var c := CollectionEnums.tier_color(CollectionEnums.CardTier.EPIC)
	assert_bool(c.is_equal_approx(Color.WHITE)).is_false()


func test_tier_color_legendary_not_white() -> void:
	var c := CollectionEnums.tier_color(CollectionEnums.CardTier.LEGENDARY)
	assert_bool(c.is_equal_approx(Color.WHITE)).is_false()
