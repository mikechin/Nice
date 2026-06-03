## Tests for DungeonRun — the run-level HP pool, haul, carry cap, and
## extract/death outcomes. The HP pool is the design's "player HP bar replaces
## discrete hearts": it persists across rooms (combat seeds from it) and 0 HP
## forfeits the haul.
extends GdUnitTestSuite


func _run(max_hp: int = 30, cap: int = 6) -> DungeonRun:
	return DungeonRun.create(RunMap.build_default(), max_hp, cap)


func test_create_starts_full_and_alive() -> void:
	var r := _run(30, 6)
	assert_int(r.max_hp).is_equal(30)
	assert_int(r.hp).is_equal(30)            # full HP at run start
	assert_int(r.carry_cap).is_equal(6)
	assert_bool(r.is_alive()).is_true()
	assert_bool(r.is_over()).is_false()
	assert_int(r.outcome).is_equal(DungeonEnums.RunOutcome.ONGOING)


func test_room_win_carries_hp_and_haul() -> void:
	var r := _run()
	r.apply_room_result(20, ["a", "b"], 3, 2)
	assert_int(r.hp).is_equal(20)             # HP persists into the next room
	assert_array(r.haul).is_equal(["a", "b"])
	assert_int(r.rooms_cleared).is_equal(1)
	assert_int(r.answered).is_equal(3)
	assert_int(r.correct).is_equal(2)
	assert_bool(r.is_alive()).is_true()


func test_hp_persists_across_multiple_rooms() -> void:
	var r := _run(30)
	r.apply_room_result(22, ["a"], 2, 2)
	r.apply_room_result(15, ["b"], 2, 1)
	assert_int(r.hp).is_equal(15)
	assert_int(r.rooms_cleared).is_equal(2)
	assert_array(r.haul).is_equal(["a", "b"])


func test_surviving_hp_clamped_to_max() -> void:
	var r := _run(30)
	r.apply_room_result(999, [], 1, 1)
	assert_int(r.hp).is_equal(30)


func test_zero_hp_dies_and_forfeits_haul() -> void:
	var r := _run()
	r.apply_room_result(20, ["a"], 2, 2)   # carried one card
	r.apply_room_result(0, ["b"], 3, 0)    # wiped in the next room
	assert_int(r.outcome).is_equal(DungeonEnums.RunOutcome.DIED)
	assert_bool(r.is_over()).is_true()
	assert_bool(r.is_alive()).is_false()
	# Death does not bank the haul.
	assert_array(r.banked_haul()).is_empty()
	# Loot from the fatal room is not added.
	assert_array(r.haul).is_equal(["a"])


func test_carry_cap_drops_overflow() -> void:
	var r := _run(30, 2)
	r.apply_room_result(25, ["a", "b", "c", "d"], 4, 4)
	assert_int(r.haul.size()).is_equal(2)
	assert_array(r.haul).is_equal(["a", "b"])
	assert_int(r.dropped_overflow).is_equal(2)
	assert_bool(r.haul_full()).is_true()


func test_extract_banks_haul() -> void:
	var r := _run()
	r.apply_room_result(18, ["a", "b"], 4, 3)
	r.extract()
	assert_int(r.outcome).is_equal(DungeonEnums.RunOutcome.EXTRACTED)
	assert_array(r.banked_haul()).is_equal(["a", "b"])


func test_die_after_extract_is_noop() -> void:
	var r := _run()
	r.extract()
	r.die()  # guarded — can't overwrite a finished outcome
	assert_int(r.outcome).is_equal(DungeonEnums.RunOutcome.EXTRACTED)


func test_accuracy() -> void:
	var r := _run()
	assert_float(r.get_accuracy()).is_equal(0.0)  # no answers yet
	r.apply_room_result(20, [], 4, 3)
	assert_float(r.get_accuracy()).is_equal(0.75)


func test_reached_bumps_depth() -> void:
	var r := _run()
	r.reached(r.map.get_node_at(5))   # depth 3
	assert_int(r.depth).is_equal(3)
	r.reached(r.map.get_node_at(1))   # depth 1 — does not lower
	assert_int(r.depth).is_equal(3)


func test_summary_has_dungeon_and_legacy_keys() -> void:
	var r := _run()
	r.apply_room_result(20, ["a", "b"], 4, 3)
	r.extract()
	var s := r.to_summary()
	assert_str(s["mode"]).is_equal("dungeon")
	assert_bool(s["extracted"]).is_true()
	assert_bool(s["died"]).is_false()
	assert_array(s["banked_card_ids"]).is_equal(["a", "b"])
	assert_int(s["haul_size"]).is_equal(2)
	# Legacy keys ResultsScreen reads must exist so it never chokes.
	assert_bool(s.has("accuracy")).is_true()
	assert_bool(s.has("rounds_completed")).is_true()
	assert_bool(s.has("hand_cards")).is_true()
	assert_bool(s.has("total_hand_power")).is_true()
