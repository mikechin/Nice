## Smoke tests for SaveManagerClass — constants and basic structure.
extends GdUnitTestSuite


func test_save_path_constant_exists() -> void:
	assert_str(SaveManagerClass.SAVE_PATH).is_not_empty()


func test_srs_save_path_constant_exists() -> void:
	assert_str(SaveManagerClass.SRS_SAVE_PATH).is_not_empty()


func test_save_version_positive() -> void:
	assert_int(SaveManagerClass.SAVE_VERSION).is_greater_equal(1)


func test_save_path_uses_user_directory() -> void:
	assert_str(SaveManagerClass.SAVE_PATH).starts_with("user://")


func test_srs_save_path_uses_user_directory() -> void:
	assert_str(SaveManagerClass.SRS_SAVE_PATH).starts_with("user://")
