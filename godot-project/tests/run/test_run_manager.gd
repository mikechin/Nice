## Tests for RunManager — run flow, card answering, and combo tracking.
extends GdUnitTestSuite

var _run: RunManager
var _pack: PackData


func before_test() -> void:
	_run = RunManager.new()
	_pack = PackData.new()
	_pack.pack_id = "test_pack"
	_pack.common_cards = ["char_a", "char_b", "char_c", "char_d", "char_e",
		"char_f", "char_g", "char_h", "char_i", "char_j"]
	_pack.build_presentation_order()


# -- start_run --

func test_start_run_initializes_state() -> void:
	_run.start_run("challenge", _pack)
	assert_bool(_run.is_active).is_true()
	assert_str(_run.run_type).is_equal("challenge")
	assert_int(_run.round_count).is_equal(1)


func test_start_run_resets_combo() -> void:
	_run.start_run("challenge", _pack)
	assert_int(_run.get_combo_manager().current_combo).is_equal(0)


# -- on_card_answered correct --

func test_on_card_answered_correct_increments_combo() -> void:
	_run.start_run("challenge", _pack)
	_run.on_card_answered("char_a", "meaning", true, 3)
	assert_int(_run.get_combo_manager().current_combo).is_equal(1)


func test_on_card_answered_wrong_breaks_combo() -> void:
	_run.start_run("challenge", _pack)
	_run.on_card_answered("char_a", "meaning", true, 3)
	_run.on_card_answered("char_b", "meaning", true, 3)
	assert_int(_run.get_combo_manager().current_combo).is_equal(2)
	_run.on_card_answered("char_c", "meaning", false, 1)
	assert_int(_run.get_combo_manager().current_combo).is_equal(0)


# -- session tracking --

func test_session_records_answers() -> void:
	_run.start_run("challenge", _pack)
	_run.on_card_answered("char_a", "meaning", true, 3)
	_run.on_card_answered("char_b", "pinyin", false, 1)
	var session := _run.get_session_data()
	assert_int(session.total_cards).is_equal(2)
	assert_int(session.correct_count).is_equal(1)


# -- run summary --

func test_run_summary_accuracy() -> void:
	_run.start_run("easy", _pack)
	_run.on_card_answered("char_a", "meaning", true, 3)
	_run.on_card_answered("char_b", "meaning", true, 4)
	_run.on_card_answered("char_c", "meaning", false, 1)
	var summary := _run.get_run_summary()
	assert_int(summary["total_cards"]).is_equal(3)
	assert_int(summary["correct_count"]).is_equal(2)


# -- inactive run ignores answers --

func test_inactive_run_ignores_answers() -> void:
	_run.on_card_answered("char_a", "meaning", true, 3)
	# Should not crash or change state when run is not active
	assert_bool(_run.is_active).is_false()
