## Smoke tests for SignalBusClass — signal definitions exist.
extends GdUnitTestSuite

var bus: SignalBusClass


func before_test() -> void:
	bus = SignalBusClass.new()


func after_test() -> void:
	bus.free()


func test_signal_bus_can_instantiate() -> void:
	assert_bool(bus is Node).is_true()


func test_has_card_answered_signal() -> void:
	assert_bool(bus.has_signal("card_answered")).is_true()


func test_has_run_signals() -> void:
	assert_bool(bus.has_signal("run_started")).is_true()
	assert_bool(bus.has_signal("run_ended")).is_true()
	assert_bool(bus.has_signal("round_started")).is_true()
	assert_bool(bus.has_signal("round_ended")).is_true()


func test_has_progression_signals() -> void:
	assert_bool(bus.has_signal("character_mastered")).is_true()
	assert_bool(bus.has_signal("streak_updated")).is_true()
	assert_bool(bus.has_signal("milestone_achieved")).is_true()
