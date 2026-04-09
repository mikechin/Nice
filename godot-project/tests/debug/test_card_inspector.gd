## Smoke tests for CardInspector — extends Control, minimal instantiation.
extends GdUnitTestSuite


func test_card_inspector_class_exists() -> void:
	var inspector := CardInspector.new()
	assert_bool(inspector is Control).is_true()
	inspector.free()


func test_challenge_types_constant() -> void:
	assert_int(CardInspector.CHALLENGE_TYPES.size()).is_equal(4)
	assert_bool(CardInspector.CHALLENGE_TYPES.has("meaning")).is_true()
	assert_bool(CardInspector.CHALLENGE_TYPES.has("character")).is_true()
	assert_bool(CardInspector.CHALLENGE_TYPES.has("pinyin")).is_true()
	assert_bool(CardInspector.CHALLENGE_TYPES.has("tone")).is_true()


func test_has_inspect_card_method() -> void:
	var inspector := CardInspector.new()
	assert_bool(inspector.has_method("inspect_card")).is_true()
	inspector.free()


func test_has_clear_method() -> void:
	var inspector := CardInspector.new()
	assert_bool(inspector.has_method("clear")).is_true()
	inspector.free()
