## Smoke tests for DebugOverlay — extends Control, minimal instantiation.
extends GdUnitTestSuite


func test_debug_overlay_class_exists() -> void:
	var overlay := DebugOverlay.new()
	assert_bool(overlay is Control).is_true()
	overlay.free()


func test_has_toggle_visibility_method() -> void:
	var overlay := DebugOverlay.new()
	assert_bool(overlay.has_method("toggle_visibility")).is_true()
	overlay.free()


func test_update_interval_positive() -> void:
	var overlay := DebugOverlay.new()
	assert_float(overlay._update_interval).is_greater(0.0)
	overlay.free()


func test_initial_time_since_update_zero() -> void:
	var overlay := DebugOverlay.new()
	assert_float(overlay._time_since_update).is_equal(0.0)
	overlay.free()
