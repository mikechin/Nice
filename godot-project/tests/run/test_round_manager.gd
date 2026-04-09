## Tests for RoundManager — round flow and card progression.
extends GdUnitTestSuite

var manager: RoundManager
var _test_cards: Array[String]


func before_test() -> void:
	manager = RoundManager.new()
	_test_cards = ["wo3", "ni3", "ta1"] as Array[String]


func test_start_round_sets_card_ids() -> void:
	manager.start_round(_test_cards, 1)
	assert_int(manager.cards_in_round.size()).is_equal(3)
	assert_int(manager.round_number).is_equal(1)
	assert_int(manager.current_card_index).is_equal(0)


func test_get_current_card_id_returns_first() -> void:
	manager.start_round(_test_cards, 1)
	assert_str(manager.get_current_card_id()).is_equal("wo3")


func test_advance_moves_to_next_card() -> void:
	manager.start_round(_test_cards, 1)
	manager.advance()
	assert_str(manager.get_current_card_id()).is_equal("ni3")


func test_on_card_answered_correct_updates_stats() -> void:
	manager.start_round(_test_cards, 1)
	manager.on_card_answered(true)
	manager.on_card_answered(false)
	var stats := manager.get_round_stats()
	assert_int(stats["correct"]).is_equal(1)
	assert_int(stats["total_cards"]).is_equal(2)


func test_is_round_complete_after_all_cards() -> void:
	manager.start_round(_test_cards, 1)
	assert_bool(manager.is_round_complete()).is_false()
	manager.on_card_answered(true)
	manager.on_card_answered(true)
	manager.on_card_answered(true)
	assert_bool(manager.is_round_complete()).is_true()


func test_get_round_stats_returns_expected_keys() -> void:
	manager.start_round(_test_cards, 1)
	manager.on_card_answered(true)
	var stats := manager.get_round_stats()
	assert_bool(stats.has("round_number")).is_true()
	assert_bool(stats.has("total_cards")).is_true()
	assert_bool(stats.has("correct")).is_true()
	assert_bool(stats.has("accuracy")).is_true()
	assert_bool(stats.has("elapsed_ms")).is_true()


func test_get_current_card_id_empty_when_past_end() -> void:
	manager.start_round(_test_cards, 1)
	manager.on_card_answered(true)
	manager.on_card_answered(true)
	manager.on_card_answered(true)
	assert_str(manager.get_current_card_id()).is_equal("")
