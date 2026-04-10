## Smoke tests for GameStateClass — save dict structure and basic properties.
extends GdUnitTestSuite

var state: GameStateClass


func before_test() -> void:
	state = GameStateClass.new()


func after_test() -> void:
	state.free()


func test_to_save_dict_has_expected_keys() -> void:
	var d := state.to_save_dict()
	assert_bool(d.has("player_hsk_level")).is_true()
	assert_bool(d.has("daily_streak")).is_true()
	assert_bool(d.has("session_history")).is_true()


func test_to_save_dict_default_values() -> void:
	var d := state.to_save_dict()
	assert_int(d["player_hsk_level"]).is_equal(2)
	assert_int(d["daily_streak"]).is_equal(0)


func test_initial_run_state() -> void:
	assert_bool(state.is_in_run).is_false()
	assert_str(state.current_run_type).is_equal("")


func test_load_from_dict_restores_state() -> void:
	var data := {
		"player_hsk_level": 4,
		"daily_streak": 7,
		"last_play_date": "2024-01-15",
		"unlocked_characters": {},
		"cards_answered_today": 10,
		"correct_answers_today": 8,
		"session_history": [],
	}
	state.load_from_dict(data)
	assert_int(state.player_hsk_level).is_equal(4)
	assert_int(state.daily_streak).is_equal(7)


func test_to_save_dict_includes_daily_stats() -> void:
	state.cards_answered_today = 15
	state.correct_answers_today = 12
	var d := state.to_save_dict()
	assert_int(d["cards_answered_today"]).is_equal(15)
	assert_int(d["correct_answers_today"]).is_equal(12)
