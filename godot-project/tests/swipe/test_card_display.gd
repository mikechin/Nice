## Smoke tests for CardDisplay — extends Control, minimal instantiation.
extends GdUnitTestSuite


func test_card_display_is_control() -> void:
	var display := CardDisplay.new()
	assert_bool(display is Control).is_true()
	display.free()


func test_has_setup_method() -> void:
	var display := CardDisplay.new()
	assert_bool(display.has_method("setup")).is_true()
	display.free()


func test_has_setup_for_challenge_method() -> void:
	var display := CardDisplay.new()
	assert_bool(display.has_method("setup_for_challenge")).is_true()
	display.free()


func test_has_animation_signal() -> void:
	var display := CardDisplay.new()
	assert_bool(display.has_signal("animation_finished")).is_true()
	display.free()


func test_default_loot_rarity() -> void:
	var display := CardDisplay.new()
	assert_int(display.loot_rarity).is_equal(SrsEnums.LootRarity.COMMON)
	display.free()


func test_has_feedback_methods() -> void:
	var display := CardDisplay.new()
	assert_bool(display.has_method("show_correct_feedback")).is_true()
	assert_bool(display.has_method("show_wrong_feedback")).is_true()
	assert_bool(display.has_method("animate_card_in")).is_true()
	assert_bool(display.has_method("animate_card_out")).is_true()
	display.free()
