## Tests for CardTierStyler — the single source of truth for tier visuals.
##
## These tests verify the tier→accent mapping matches the style guide,
## that border widths escalate with rarity, and that COMMON keeps the
## neutral hairline outline (no rarity hue) so it reads as the baseline.
extends GdUnitTestSuite


func test_accent_for_each_tier_matches_ui_tokens() -> void:
	assert_object(CardTierStyler.accent_for(CollectionEnums.CardTier.NEW_CARD)) \
		.is_equal(UiTokens.RARITY_NEW)
	assert_object(CardTierStyler.accent_for(CollectionEnums.CardTier.COMMON)) \
		.is_equal(UiTokens.RARITY_COMMON)
	assert_object(CardTierStyler.accent_for(CollectionEnums.CardTier.UNCOMMON)) \
		.is_equal(UiTokens.RARITY_UNCOMMON)
	assert_object(CardTierStyler.accent_for(CollectionEnums.CardTier.RARE)) \
		.is_equal(UiTokens.RARITY_RARE)
	assert_object(CardTierStyler.accent_for(CollectionEnums.CardTier.LEGENDARY)) \
		.is_equal(UiTokens.RARITY_LEGENDARY)


func test_labels_match_collection_enums_naming() -> void:
	assert_str(CardTierStyler.label_for(CollectionEnums.CardTier.NEW_CARD)).is_equal("NEW")
	assert_str(CardTierStyler.label_for(CollectionEnums.CardTier.COMMON)).is_equal("Common")
	assert_str(CardTierStyler.label_for(CollectionEnums.CardTier.UNCOMMON)).is_equal("Uncommon")
	assert_str(CardTierStyler.label_for(CollectionEnums.CardTier.RARE)).is_equal("Rare")
	assert_str(CardTierStyler.label_for(CollectionEnums.CardTier.EPIC)).is_equal("Epic")
	assert_str(CardTierStyler.label_for(CollectionEnums.CardTier.LEGENDARY)).is_equal("Legendary")


func test_common_uses_neutral_hairline_border() -> void:
	# COMMON is the "honest baseline" per the style guide — no rarity hue,
	# just the standard hairline. All other tiers use their accent.
	assert_object(CardTierStyler.border_color_for(CollectionEnums.CardTier.COMMON)) \
		.is_equal(UiTokens.HAIRLINE)


func test_non_common_tiers_use_accent_for_border() -> void:
	for tier in [
		CollectionEnums.CardTier.NEW_CARD,
		CollectionEnums.CardTier.UNCOMMON,
		CollectionEnums.CardTier.RARE,
		CollectionEnums.CardTier.LEGENDARY,
	]:
		assert_object(CardTierStyler.border_color_for(tier)) \
			.is_equal(CardTierStyler.accent_for(tier))


func test_border_widths_escalate_with_rarity() -> void:
	# COMMON/UNCOMMON sit at the baseline thickness; NEW/RARE bump up;
	# LEGENDARY is the heaviest border.
	assert_int(CardTierStyler.border_width_for(CollectionEnums.CardTier.COMMON)).is_equal(1)
	assert_int(CardTierStyler.border_width_for(CollectionEnums.CardTier.UNCOMMON)).is_equal(1)
	assert_int(CardTierStyler.border_width_for(CollectionEnums.CardTier.NEW_CARD)).is_greater(1)
	assert_int(CardTierStyler.border_width_for(CollectionEnums.CardTier.RARE)).is_greater(1)
	assert_int(CardTierStyler.border_width_for(CollectionEnums.CardTier.LEGENDARY)) \
		.is_greater(CardTierStyler.border_width_for(CollectionEnums.CardTier.RARE))


func test_style_for_returns_card_radius() -> void:
	var sb := CardTierStyler.style_for(CollectionEnums.CardTier.RARE)
	assert_int(sb.corner_radius_top_left).is_equal(UiTokens.R_CARD)
	assert_int(sb.corner_radius_top_right).is_equal(UiTokens.R_CARD)
	assert_int(sb.corner_radius_bottom_left).is_equal(UiTokens.R_CARD)
	assert_int(sb.corner_radius_bottom_right).is_equal(UiTokens.R_CARD)


func test_style_for_common_has_surface_bg() -> void:
	# COMMON gets no rarity tint — pure SURFACE.
	var sb := CardTierStyler.style_for(CollectionEnums.CardTier.COMMON)
	assert_object(sb.bg_color).is_equal(UiTokens.SURFACE)


func test_legendary_bg_pulls_toward_gold() -> void:
	# Legendary should look noticeably warmer than COMMON because of the
	# gold tint mix — verify the red channel rises.
	var common_bg := CardTierStyler.bg_color_for(CollectionEnums.CardTier.COMMON)
	var legend_bg := CardTierStyler.bg_color_for(CollectionEnums.CardTier.LEGENDARY)
	assert_float(legend_bg.r).is_greater(common_bg.r)
	assert_float(legend_bg.g).is_greater(common_bg.g)


# -- NEW tier badge --

func test_new_tier_label_uses_larger_font_size() -> void:
	# NEW gets a punchier badge so the first-contact moment reads loud.
	assert_int(CardTierStyler.tier_label_font_size(CollectionEnums.CardTier.NEW_CARD)) \
		.is_greater(CardTierStyler.tier_label_font_size(CollectionEnums.CardTier.COMMON))


func test_new_tier_returns_a_badge_stylebox() -> void:
	var sb := CardTierStyler.tier_label_badge_for(CollectionEnums.CardTier.NEW_CARD)
	assert_object(sb).is_not_null()
	if sb is StyleBoxFlat:
		assert_int(sb.corner_radius_top_left).is_equal(UiTokens.R_PILL)
		assert_object(sb.border_color).is_equal(UiTokens.RARITY_NEW)


func test_other_tiers_return_no_badge_stylebox() -> void:
	for tier in [
		CollectionEnums.CardTier.COMMON,
		CollectionEnums.CardTier.UNCOMMON,
		CollectionEnums.CardTier.RARE,
		CollectionEnums.CardTier.LEGENDARY,
	]:
		assert_object(CardTierStyler.tier_label_badge_for(tier)).is_null()


# -- Epic placeholder --

func test_epic_currently_mirrors_rare_visual() -> void:
	# EPIC is a placeholder until the visual is signed off. Pinned here so
	# we get a reminder when this file changes.
	assert_object(CardTierStyler.accent_for(CollectionEnums.CardTier.EPIC)) \
		.is_equal(CardTierStyler.accent_for(CollectionEnums.CardTier.RARE))
