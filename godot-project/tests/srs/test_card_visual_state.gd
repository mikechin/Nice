## CardVisualState — Tests locked(), for_tier() setting correct visual properties.
extends GdUnitTestSuite


func before_test() -> void:
	pass


func test_locked_sets_tier() -> void:
	var vs := CardVisualState.locked("好")
	assert_int(vs.tier).is_equal(CollectionEnums.CardTier.LOCKED)


func test_locked_sets_card_id() -> void:
	var vs := CardVisualState.locked("好")
	assert_str(vs.card_id).is_equal("好")


func test_locked_sets_background_style() -> void:
	var vs := CardVisualState.locked("好")
	assert_str(vs.background_style).is_equal("locked")


func test_locked_border_color_matches_tier_color() -> void:
	var vs := CardVisualState.locked("好")
	var expected := CollectionEnums.tier_color(CollectionEnums.CardTier.LOCKED)
	assert_bool(vs.border_color.is_equal_approx(expected)).is_true()


func test_for_tier_common_default_style() -> void:
	var vs := CardVisualState.for_tier("大", CollectionEnums.CardTier.COMMON)
	assert_str(vs.card_id).is_equal("大")
	assert_int(vs.tier).is_equal(CollectionEnums.CardTier.COMMON)
	assert_str(vs.background_style).is_equal("default")
	assert_float(vs.glow_intensity).is_equal(0.0)
	assert_bool(vs.particle_enabled).is_false()


func test_for_tier_rare_has_glow() -> void:
	var vs := CardVisualState.for_tier("龙", CollectionEnums.CardTier.RARE)
	assert_float(vs.glow_intensity).is_equal_approx(0.3, 0.01)
	assert_str(vs.background_style).is_equal("rare")


func test_for_tier_epic_has_particles() -> void:
	var vs := CardVisualState.for_tier("凤", CollectionEnums.CardTier.EPIC)
	assert_bool(vs.particle_enabled).is_true()
	assert_float(vs.glow_intensity).is_equal_approx(0.6, 0.01)
	assert_str(vs.background_style).is_equal("epic")
	assert_str(vs.animation_id).is_equal("epic_idle")


func test_for_tier_legendary_max_glow() -> void:
	var vs := CardVisualState.for_tier("仙", CollectionEnums.CardTier.LEGENDARY)
	assert_bool(vs.particle_enabled).is_true()
	assert_float(vs.glow_intensity).is_equal_approx(1.0, 0.01)
	assert_str(vs.background_style).is_equal("legendary")
	assert_str(vs.animation_id).is_equal("legendary_idle")
