## Tests for Chip — variant styling and text propagation.
extends GdUnitTestSuite

const ChipScene: PackedScene = preload("res://scenes/components/chip.tscn")


func _make_chip(variant: Chip.Variant, text: String = "") -> Chip:
	var chip: Chip = ChipScene.instantiate()
	chip.variant = variant
	chip.text = text
	add_child(chip)
	auto_free(chip)
	return chip


func _label_in(chip: Chip) -> Label:
	for c in chip.get_children():
		if c is Label:
			return c
	return null


func _stylebox(chip: Chip) -> StyleBoxFlat:
	return chip.get_theme_stylebox("panel") as StyleBoxFlat


# -- text propagation --

func test_text_property_sets_inner_label() -> void:
	var chip := _make_chip(Chip.Variant.DEFAULT, "qing")
	assert_str(_label_in(chip).text).is_equal("qing")


func test_text_setter_after_ready_updates_label() -> void:
	var chip := _make_chip(Chip.Variant.DEFAULT, "")
	chip.text = "HSK 2"
	assert_str(_label_in(chip).text).is_equal("HSK 2")


# -- default variant --

func test_default_variant_uses_elevated_bg() -> void:
	var chip := _make_chip(Chip.Variant.DEFAULT, "x")
	assert_object(_stylebox(chip).bg_color).is_equal(UiTokens.ELEVATED)


func test_default_variant_uses_ink_2_label_color() -> void:
	var chip := _make_chip(Chip.Variant.DEFAULT, "x")
	var color: Color = _label_in(chip).get_theme_color("font_color")
	assert_object(color).is_equal(UiTokens.INK_2)


# -- HSK variant --

func test_hsk_variant_uses_transparent_bg() -> void:
	var chip := _make_chip(Chip.Variant.HSK, "HSK 2")
	assert_float(_stylebox(chip).bg_color.a).is_equal(0.0)


func test_hsk_variant_label_is_gold() -> void:
	var chip := _make_chip(Chip.Variant.HSK, "HSK 2")
	var color: Color = _label_in(chip).get_theme_color("font_color")
	assert_object(color).is_equal(UiTokens.GOLD)


# -- semantic variants --

func test_correct_variant_label_is_correct_color() -> void:
	var chip := _make_chip(Chip.Variant.CORRECT, "ok")
	var color: Color = _label_in(chip).get_theme_color("font_color")
	assert_object(color).is_equal(UiTokens.CORRECT)


func test_incorrect_variant_label_is_incorrect_color() -> void:
	var chip := _make_chip(Chip.Variant.INCORRECT, "miss")
	var color: Color = _label_in(chip).get_theme_color("font_color")
	assert_object(color).is_equal(UiTokens.INCORRECT)


func test_struggling_variant_label_is_struggling_color() -> void:
	var chip := _make_chip(Chip.Variant.STRUGGLING, "low")
	var color: Color = _label_in(chip).get_theme_color("font_color")
	assert_object(color).is_equal(UiTokens.STRUGGLING)


# -- variant change rebuilds the stylebox --

func test_changing_variant_after_ready_rebuilds_stylebox() -> void:
	var chip := _make_chip(Chip.Variant.DEFAULT, "x")
	chip.variant = Chip.Variant.CORRECT
	var border_color: Color = _stylebox(chip).border_color
	assert_object(border_color).is_equal(UiTokens.BORDER_CORRECT)


# -- shape --

func test_corner_radius_is_pill() -> void:
	var chip := _make_chip(Chip.Variant.DEFAULT, "x")
	assert_int(_stylebox(chip).corner_radius_top_left).is_equal(UiTokens.R_PILL)
