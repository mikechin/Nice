## Tests for DungeonRun — the run-level HP pool, the CardInstance haul, and the
## extract-time carry-cap triage (M3). The HP pool is the design's "player HP
## bar replaces discrete hearts": it persists across rooms (combat seeds from it)
## and 0 HP forfeits the haul. The haul accumulates uncapped during the run; the
## carry cap bites only at extraction, where the player keeps their best N and
## the rest shatter into shards.
extends GdUnitTestSuite


func _run(max_hp: int = 30, cap: int = 6) -> DungeonRun:
	return DungeonRun.create(RunMap.build_default(), max_hp, cap)


func _inst(card_id: String, rarity: int = EconomyEnums.Rarity.COMMON) -> CardInstance:
	return CardInstance.create(card_id, rarity)


func _ids(list: Array) -> Array:
	var out: Array = []
	for ci in list:
		out.append(ci.card_id)
	return out


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
	r.apply_room_result(20, [_inst("a"), _inst("b")], 3, 2)
	assert_int(r.hp).is_equal(20)             # HP persists into the next room
	assert_array(_ids(r.haul)).is_equal(["a", "b"])
	assert_int(r.rooms_cleared).is_equal(1)
	assert_int(r.answered).is_equal(3)
	assert_int(r.correct).is_equal(2)
	assert_bool(r.is_alive()).is_true()


func test_hp_persists_across_multiple_rooms() -> void:
	var r := _run(30)
	r.apply_room_result(22, [_inst("a")], 2, 2)
	r.apply_room_result(15, [_inst("b")], 2, 1)
	assert_int(r.hp).is_equal(15)
	assert_int(r.rooms_cleared).is_equal(2)
	assert_array(_ids(r.haul)).is_equal(["a", "b"])


func test_surviving_hp_clamped_to_max() -> void:
	var r := _run(30)
	r.apply_room_result(999, [], 1, 1)
	assert_int(r.hp).is_equal(30)


func test_zero_hp_dies_and_forfeits_haul() -> void:
	var r := _run()
	r.apply_room_result(20, [_inst("a")], 2, 2)   # carried one card
	r.apply_room_result(0, [_inst("b")], 3, 0)    # wiped in the next room
	assert_int(r.outcome).is_equal(DungeonEnums.RunOutcome.DIED)
	assert_bool(r.is_over()).is_true()
	assert_bool(r.is_alive()).is_false()
	# Death banks nothing — the haul is forfeit.
	assert_array(r.banked_haul()).is_empty()
	# Loot from the fatal room is never added.
	assert_array(_ids(r.haul)).is_equal(["a"])


func test_haul_accumulates_past_cap_without_dropping() -> void:
	# No per-room overflow drop anymore — the haul grows freely, triage is at
	# the gate.
	var r := _run(30, 2)
	r.apply_room_result(25, [_inst("a"), _inst("b"), _inst("c"), _inst("d")], 4, 4)
	assert_int(r.haul.size()).is_equal(4)
	assert_bool(r.needs_triage()).is_true()
	assert_bool(r.haul_full()).is_true()


func test_extract_within_cap_banks_everything() -> void:
	var r := _run(30, 6)
	r.apply_room_result(18, [_inst("a"), _inst("b")], 4, 3)
	r.extract()
	assert_int(r.outcome).is_equal(DungeonEnums.RunOutcome.EXTRACTED)
	assert_array(_ids(r.banked_haul())).contains_exactly_in_any_order(["a", "b"])
	assert_array(r.shattered_haul()).is_empty()
	assert_int(r.shard_gain()).is_equal(0)


func test_extract_over_cap_auto_keeps_best_and_shatters_rest() -> void:
	var r := _run(30, 2)
	# Rarer instances sort first; the two best should be banked.
	r.apply_room_result(20, [
		_inst("common", EconomyEnums.Rarity.COMMON),
		_inst("rare", EconomyEnums.Rarity.RARE),
		_inst("uncommon", EconomyEnums.Rarity.UNCOMMON),
	], 3, 3)
	r.extract()   # no selection → auto-keep best `cap`
	assert_array(_ids(r.banked_haul())).contains_exactly_in_any_order(["rare", "uncommon"])
	assert_array(_ids(r.shattered_haul())).is_equal(["common"])
	assert_int(r.shard_gain()).is_greater(0)


func test_extract_honors_explicit_keep_selection() -> void:
	var r := _run(30, 2)
	var keep_a := _inst("a", EconomyEnums.Rarity.COMMON)
	var keep_c := _inst("c", EconomyEnums.Rarity.COMMON)
	var drop_b := _inst("b", EconomyEnums.Rarity.RARE)   # rarer, but the player drops it
	r.apply_room_result(20, [keep_a, drop_b, keep_c], 3, 3)
	r.extract([keep_a, keep_c])
	assert_array(_ids(r.banked_haul())).contains_exactly_in_any_order(["a", "c"])
	assert_array(_ids(r.shattered_haul())).is_equal(["b"])


func test_keep_selection_is_clamped_to_cap() -> void:
	var r := _run(30, 1)
	var a := _inst("a", EconomyEnums.Rarity.RARE)
	var b := _inst("b", EconomyEnums.Rarity.COMMON)
	r.apply_room_result(20, [a, b], 2, 2)
	r.extract([a, b])   # asked to keep 2 but cap is 1 → best-first wins
	assert_int(r.banked_haul().size()).is_equal(1)
	assert_array(_ids(r.banked_haul())).is_equal(["a"])


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
	r.apply_room_result(20, [_inst("a"), _inst("b")], 4, 3)
	r.extract()
	var s := r.to_summary()
	assert_str(s["mode"]).is_equal("dungeon")
	assert_bool(s["extracted"]).is_true()
	assert_bool(s["died"]).is_false()
	assert_array(s["banked_card_ids"]).contains_exactly_in_any_order(["a", "b"])
	assert_int(s["haul_size"]).is_equal(2)
	assert_bool(s.has("shards_gained")).is_true()
	assert_bool(s.has("banked_instances")).is_true()
	# Legacy keys ResultsScreen reads must exist so it never chokes.
	assert_bool(s.has("accuracy")).is_true()
	assert_bool(s.has("rounds_completed")).is_true()
	assert_bool(s.has("hand_cards")).is_true()
	assert_bool(s.has("total_hand_power")).is_true()
