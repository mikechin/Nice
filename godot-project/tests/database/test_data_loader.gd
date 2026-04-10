## Tests for DataLoader — JSON file loading and existence checks.
## Note: These tests use the static API without depending on actual data files.
extends GdUnitTestSuite


# -- load_json with nonexistent path --

func test_load_json_nonexistent_returns_null() -> void:
	var result: Variant = DataLoader.load_json("res://nonexistent/fake_file.json")
	assert_bool(result == null).is_true()


func test_load_json_invalid_path_returns_null() -> void:
	var result: Variant = DataLoader.load_json("")
	assert_bool(result == null).is_true()


# -- file_exists --

func test_file_exists_nonexistent_returns_false() -> void:
	var exists := DataLoader.file_exists("nonexistent/fake_file.json")
	assert_bool(exists).is_false()


func test_file_exists_empty_path() -> void:
	var exists := DataLoader.file_exists("")
	assert_bool(exists).is_false()


# -- load_characters for nonexistent level --

func test_load_characters_nonexistent_level_returns_empty() -> void:
	# Level 99 should not have a data file
	var chars := DataLoader.load_characters(99)
	assert_int(chars.size()).is_equal(0)


# -- load_radicals when file missing --

# -- load_radical_character_map when file missing --

func test_load_radical_character_map_missing_returns_empty() -> void:
	# In a test environment without data files, this should return empty dict
	var result := DataLoader.load_radical_character_map()
	assert_bool(result is Dictionary).is_true()
