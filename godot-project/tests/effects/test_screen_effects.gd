## Tests for ScreenEffects — smoke tests for screen transition methods.
extends GdUnitTestSuite

var effects: ScreenEffects


func before_test() -> void:
	effects = ScreenEffects.new()


func test_instance_is_ref_counted() -> void:
	assert_bool(effects is RefCounted).is_true()


func test_fade_in_callable() -> void:
	assert_bool(effects.has_method("fade_in")).is_true()


func test_fade_out_callable() -> void:
	assert_bool(effects.has_method("fade_out")).is_true()


func test_slide_in_from_callable() -> void:
	assert_bool(effects.has_method("slide_in_from")).is_true()


func test_slide_out_to_callable() -> void:
	assert_bool(effects.has_method("slide_out_to")).is_true()


func test_cross_fade_callable() -> void:
	assert_bool(effects.has_method("cross_fade")).is_true()
