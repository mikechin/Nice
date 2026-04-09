## Tests for CardEffects — smoke tests for card effect methods.
extends GdUnitTestSuite

var effects: CardEffects


func before_test() -> void:
	effects = CardEffects.new()


func test_instance_is_ref_counted() -> void:
	assert_bool(effects is RefCounted).is_true()


func test_create_correct_tween_callable() -> void:
	assert_bool(effects.has_method("create_correct_tween")).is_true()


func test_create_wrong_tween_callable() -> void:
	assert_bool(effects.has_method("create_wrong_tween")).is_true()


func test_create_combo_burst_callable() -> void:
	assert_bool(effects.has_method("create_combo_burst")).is_true()


func test_create_tier_promotion_callable() -> void:
	assert_bool(effects.has_method("create_tier_promotion")).is_true()


func test_create_new_card_reveal_callable() -> void:
	assert_bool(effects.has_method("create_new_card_reveal")).is_true()
