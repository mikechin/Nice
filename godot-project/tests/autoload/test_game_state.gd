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
	assert_bool(d.has("session_history")).is_true()


func test_to_save_dict_default_values() -> void:
	var d := state.to_save_dict()
	assert_int(d["player_hsk_level"]).is_equal(2)


func test_initial_run_state() -> void:
	assert_bool(state.is_in_run).is_false()
	assert_object(state.current_pack).is_null()


func test_load_from_dict_restores_state() -> void:
	var data := {
		"player_hsk_level": 4,
		"last_play_date": "2024-01-15",
		"unlocked_characters": {},
		"cards_answered_today": 10,
		"correct_answers_today": 8,
		"session_history": [],
	}
	state.load_from_dict(data)
	assert_int(state.player_hsk_level).is_equal(4)


func test_to_save_dict_includes_daily_stats() -> void:
	state.cards_answered_today = 15
	state.correct_answers_today = 12
	var d := state.to_save_dict()
	assert_int(d["cards_answered_today"]).is_equal(15)
	assert_int(d["correct_answers_today"]).is_equal(12)


# --- M3 persistent economy ---

func test_save_dict_includes_economy() -> void:
	var d := state.to_save_dict()
	assert_bool(d.has("economy")).is_true()
	var eco: Dictionary = d["economy"]
	assert_bool(eco.has("inventory")).is_true()
	assert_bool(eco.has("wallet")).is_true()
	assert_bool(eco.has("binder")).is_true()


func test_load_v1_save_without_economy_is_safe() -> void:
	# A pre-M3 (v1) save has no "economy" key — must migrate to empty, not crash.
	state.load_from_dict({ "player_hsk_level": 3 })
	assert_object(state.inventory).is_not_null()
	assert_int(state.inventory.size()).is_equal(0)
	assert_int(state.wallet.shards).is_equal(0)
	assert_int(state.binder.seen_count()).is_equal(0)


func test_economy_round_trips_through_save_dict() -> void:
	state.load_from_dict({})  # ensures the economy structures exist
	state.inventory.add(CardInstance.create("好", EconomyEnums.Rarity.RARE))
	state.wallet.add(25)
	state.binder.record_seen("学")
	var saved := state.to_save_dict()

	var restored := GameStateClass.new()
	restored.load_from_dict(saved)
	assert_int(restored.inventory.size()).is_equal(1)
	assert_int(restored.inventory.count_of("好")).is_equal(1)
	assert_int(restored.wallet.shards).is_equal(25)
	assert_bool(restored.binder.is_seen("学")).is_true()
	restored.free()


func test_bank_haul_credits_bench_and_shards() -> void:
	state.load_from_dict({})
	var kept := [CardInstance.create("好", EconomyEnums.Rarity.RARE)]
	var shattered := [CardInstance.create("大", EconomyEnums.Rarity.COMMON)]
	var receipt := state.bank_haul(kept, shattered)
	assert_int(receipt["banked"]).is_equal(1)
	assert_int(state.inventory.size()).is_equal(1)
	assert_bool(state.binder.is_seen("好")).is_true()        # banking records the drop
	assert_int(state.wallet.shards).is_equal(receipt["shards"])
	assert_int(state.wallet.shards).is_greater(0)
