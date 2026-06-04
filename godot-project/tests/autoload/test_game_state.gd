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


# --- M4 loadout (bench <-> kit; never double-counted) ---

func test_equip_moves_instance_off_bench_into_kit() -> void:
	state.load_from_dict({})
	var ci := state.inventory.add(CardInstance.create("好", EconomyEnums.Rarity.RARE))
	assert_bool(state.equip(ci.id, 0)).is_true()
	assert_int(state.inventory.size()).is_equal(0)          # left the bench
	assert_bool(state.loadout.has_instance(ci.id)).is_true()
	assert_str(state.loadout.get_slot(0).card_id).is_equal("好")


func test_equip_unknown_or_out_of_range_fails() -> void:
	state.load_from_dict({})
	assert_bool(state.equip("nope", 0)).is_false()
	var ci := state.inventory.add(CardInstance.create("学", EconomyEnums.Rarity.COMMON))
	assert_bool(state.equip(ci.id, 99)).is_false()          # bad slot — card stays on bench
	assert_int(state.inventory.size()).is_equal(1)


func test_unequip_returns_instance_to_bench() -> void:
	state.load_from_dict({})
	var ci := state.inventory.add(CardInstance.create("好", EconomyEnums.Rarity.COMMON))
	state.equip(ci.id, 2)
	assert_bool(state.unequip(2)).is_true()
	assert_int(state.inventory.size()).is_equal(1)
	assert_bool(state.loadout.is_empty()).is_true()
	assert_bool(state.unequip(2)).is_false()                # nothing there now


func test_equipping_over_a_slot_returns_the_displaced_card() -> void:
	state.load_from_dict({})
	var a := state.inventory.add(CardInstance.create("我", EconomyEnums.Rarity.COMMON))
	state.equip(a.id, 0)
	var b := state.inventory.add(CardInstance.create("你", EconomyEnums.Rarity.COMMON))
	state.equip(b.id, 0)                                     # displaces 我 back to the bench
	assert_str(state.loadout.get_slot(0).card_id).is_equal("你")
	assert_int(state.inventory.size()).is_equal(1)
	assert_int(state.inventory.count_of("我")).is_equal(1)


func test_loadout_round_trips_without_double_counting() -> void:
	state.load_from_dict({})
	var ci := state.inventory.add(CardInstance.create("好", EconomyEnums.Rarity.RARE))
	state.equip(ci.id, 1)
	var saved := state.to_save_dict()
	assert_bool(saved["economy"].has("loadout")).is_true()

	var restored := GameStateClass.new()
	restored.load_from_dict(saved)
	assert_int(restored.loadout.equipped_count()).is_equal(1)
	assert_int(restored.inventory.size()).is_equal(0)       # staked card is NOT also on the bench
	assert_str(restored.loadout.get_slot(1).card_id).is_equal("好")
	restored.free()


func test_load_v2_save_without_loadout_is_safe() -> void:
	# A pre-M4 (v2) save has an economy block but no "loadout" key.
	state.load_from_dict({ "economy": { "wallet": { "shards": 5 } } })
	assert_object(state.loadout).is_not_null()
	assert_bool(state.loadout.is_empty()).is_true()
	assert_int(state.wallet.shards).is_equal(5)


# --- M4 stake (the loadout is the stake; lost on death, kept on extract) ---

func _equip_two() -> void:
	state.load_from_dict({})
	var a := state.inventory.add(CardInstance.create("我", EconomyEnums.Rarity.RARE))
	var b := state.inventory.add(CardInstance.create("你", EconomyEnums.Rarity.COMMON))
	state.equip(a.id, 0)
	state.equip(b.id, 2)


func test_enter_run_stake_snapshots_the_equipped_kit() -> void:
	_equip_two()
	var stake := state.enter_run_stake()
	assert_int(stake.size()).is_equal(2)
	assert_object(state.current_stake).is_not_null()


func test_extract_alive_keeps_the_kit() -> void:
	_equip_two()
	state.enter_run_stake()
	var lost := state.resolve_stake(true)
	assert_int(lost.size()).is_equal(0)
	assert_int(state.loadout.equipped_count()).is_equal(2)   # kit stays equipped
	assert_object(state.current_stake).is_null()             # stake closed


func test_death_forfeits_the_whole_kit_and_does_not_return_it_to_the_bench() -> void:
	_equip_two()
	state.enter_run_stake()
	var lost := state.resolve_stake(false)
	assert_int(lost.size()).is_equal(2)                      # both staked cards reported lost
	assert_bool(state.loadout.is_empty()).is_true()          # stripped from the kit
	assert_int(state.inventory.size()).is_equal(0)           # destroyed, NOT returned to the bench
	assert_object(state.current_stake).is_null()


func test_death_never_touches_the_binder_or_mastery() -> void:
	# The un-loseable north star: instances die, knowledge does not.
	_equip_two()
	state.binder.record_seen("我")
	state.binder.record_grade("我", 7)
	state.enter_run_stake()
	state.resolve_stake(false)
	assert_bool(state.binder.is_seen("我")).is_true()
	assert_int(state.binder.best_psa("我")).is_equal(7)
