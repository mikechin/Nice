## Tests for UiTokens — sanity checks on the design-token constants.
##
## A constants file is mostly a typo-detector. These tests verify the
## invariants that would silently break the design system if violated:
## the spacing/type scales must be monotonic, rarity values must be
## distinct enough that tiers read as different colors, and the legendary
## rarity must be the same gold accent used elsewhere in the system.
extends GdUnitTestSuite


# -- spacing scale --

func test_spacing_scale_is_strictly_increasing() -> void:
	var scale := [
		UiTokens.S_1, UiTokens.S_2, UiTokens.S_3, UiTokens.S_4,
		UiTokens.S_5, UiTokens.S_6, UiTokens.S_7, UiTokens.S_8, UiTokens.S_9,
	]
	for i in range(1, scale.size()):
		assert_int(scale[i]).is_greater(scale[i - 1])


func test_spacing_base_is_four_pixels() -> void:
	assert_int(UiTokens.S_1).is_equal(4)


# -- radii --

func test_radii_are_strictly_increasing_through_xl() -> void:
	var ramp := [
		UiTokens.R_XS, UiTokens.R_SM, UiTokens.R_MD,
		UiTokens.R_LG, UiTokens.R_CARD, UiTokens.R_XL,
	]
	for i in range(1, ramp.size()):
		assert_int(ramp[i]).is_greater(ramp[i - 1])


func test_pill_radius_dominates_the_ramp() -> void:
	assert_int(UiTokens.R_PILL).is_greater(UiTokens.R_XL)


# -- type scale --

func test_type_scale_is_strictly_increasing() -> void:
	var scale := [
		UiTokens.T_CAPTION, UiTokens.T_BODY, UiTokens.T_H3,
		UiTokens.T_H2, UiTokens.T_H1, UiTokens.T_DISPLAY,
	]
	for i in range(1, scale.size()):
		assert_int(scale[i]).is_greater(scale[i - 1])


# -- rarity colours --

func test_legendary_rarity_uses_the_gold_accent() -> void:
	assert_object(UiTokens.RARITY_LEGENDARY).is_equal(UiTokens.GOLD)


func test_rarity_hues_are_distinct_through_rare() -> void:
	# RARITY_EPIC is intentionally a placeholder duplicating RARITY_RARE
	# until the Epic visual is signed off — see ui_tokens.gd.
	var hues := [
		UiTokens.RARITY_NEW, UiTokens.RARITY_COMMON,
		UiTokens.RARITY_UNCOMMON, UiTokens.RARITY_RARE, UiTokens.RARITY_LEGENDARY,
	]
	for i in range(hues.size()):
		for j in range(i + 1, hues.size()):
			assert_object(hues[i]).is_not_equal(hues[j])


# -- semantic colours --

func test_semantic_feedback_colours_are_distinct() -> void:
	assert_object(UiTokens.CORRECT).is_not_equal(UiTokens.INCORRECT)
	assert_object(UiTokens.CORRECT).is_not_equal(UiTokens.STRUGGLING)
	assert_object(UiTokens.INCORRECT).is_not_equal(UiTokens.STRUGGLING)


# -- transparency on hairlines --

func test_hairlines_are_translucent() -> void:
	assert_float(UiTokens.HAIRLINE.a).is_less(1.0)
	assert_float(UiTokens.HAIRLINE_SOFT.a).is_less(UiTokens.HAIRLINE.a)
