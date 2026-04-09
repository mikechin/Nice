## Tests for AccessibilityManagerClass — accessibility settings logic.
extends GdUnitTestSuite

var manager: AccessibilityManagerClass


func before_test() -> void:
	manager = AccessibilityManagerClass.new()


func after_test() -> void:
	manager.free()


func test_set_font_scale_clamps_low() -> void:
	manager.set_font_scale(0.1)
	assert_float(manager.font_scale).is_equal(AccessibilityManagerClass.MIN_FONT_SCALE)


func test_set_font_scale_clamps_high() -> void:
	manager.set_font_scale(5.0)
	assert_float(manager.font_scale).is_equal(AccessibilityManagerClass.MAX_FONT_SCALE)


func test_set_font_scale_normal_value() -> void:
	manager.set_font_scale(1.5)
	assert_float(manager.font_scale).is_equal(1.5)


func test_increase_font_scale() -> void:
	manager.font_scale = 1.0
	manager.increase_font_scale()
	assert_float(manager.font_scale).is_equal(1.25)


func test_decrease_font_scale() -> void:
	manager.font_scale = 1.5
	manager.decrease_font_scale()
	assert_float(manager.font_scale).is_equal(1.25)


func test_set_color_blind_mode() -> void:
	manager.set_color_blind_mode(AccessibilityManagerClass.ColorBlindMode.PROTANOPIA)
	assert_int(manager.color_blind_mode).is_equal(AccessibilityManagerClass.ColorBlindMode.PROTANOPIA)


func test_to_dict_has_expected_keys() -> void:
	var d := manager.to_dict()
	assert_bool(d.has("font_scale")).is_true()
	assert_bool(d.has("color_blind_mode")).is_true()
	assert_bool(d.has("haptic_enabled")).is_true()
	assert_bool(d.has("reduced_motion")).is_true()
	assert_bool(d.has("high_contrast")).is_true()
	assert_bool(d.has("screen_reader_hints")).is_true()


func test_load_from_dict_restores_state() -> void:
	var data := {
		"font_scale": 1.75,
		"color_blind_mode": AccessibilityManagerClass.ColorBlindMode.DEUTERANOPIA,
		"haptic_enabled": false,
		"reduced_motion": true,
		"high_contrast": true,
		"screen_reader_hints": true,
	}
	manager.load_from_dict(data)
	assert_float(manager.font_scale).is_equal(1.75)
	assert_int(manager.color_blind_mode).is_equal(AccessibilityManagerClass.ColorBlindMode.DEUTERANOPIA)
	assert_bool(manager.haptic_enabled).is_false()
	assert_bool(manager.reduced_motion).is_true()


func test_animation_speed_multiplier_with_reduced_motion() -> void:
	manager.set_reduced_motion(true)
	assert_float(manager.get_animation_speed_multiplier()).is_equal(0.0)
	manager.set_reduced_motion(false)
	assert_float(manager.get_animation_speed_multiplier()).is_equal(1.0)
