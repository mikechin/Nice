## Tests for LootBagOverlay — the loot-bag grid modal. Covers the column math, the
## grid rendering one cell per carried card, the forced-overflow gating (can't
## leave until the haul fits the cap), and that dropping marked cards moves them
## out of the run's haul. Drag-reorder is engine-driven and felt in playtest.
extends GdUnitTestSuite


func after_test() -> void:
	RunState.clear_run()


func _run_with(n: int, cap: int = 6) -> DungeonRun:
	var r := DungeonRun.create(RunMap.build_default(), 30, cap)
	var loot: Array = []
	for i in n:
		loot.append(CardInstance.create("c%d" % i, EconomyEnums.Rarity.COMMON))
	r.apply_room_result(25, loot, n, n)
	return r


func test_columns_for_is_clamped() -> void:
	assert_int(LootBagOverlay.columns_for(0)).is_equal(1)   # never 0 → GridContainer is happy
	assert_int(LootBagOverlay.columns_for(3)).is_equal(3)
	assert_int(LootBagOverlay.columns_for(6)).is_equal(6)
	assert_int(LootBagOverlay.columns_for(9)).is_equal(6)   # wraps past the cap


func test_open_renders_one_cell_per_card() -> void:
	var overlay: LootBagOverlay = auto_free(LootBagOverlay.new())
	add_child(overlay)
	overlay.open(_run_with(4), false)
	await get_tree().process_frame
	assert_bool(overlay.is_open()).is_true()
	assert_int(overlay._cells.size()).is_equal(4)


func test_forced_overflow_gates_done_until_it_fits() -> void:
	var overlay: LootBagOverlay = auto_free(LootBagOverlay.new())
	add_child(overlay)
	var run := _run_with(8, 6)              # 8 carried, cap 6 → over by 2
	overlay.open(run, true)
	await get_tree().process_frame
	assert_bool(overlay._done_button.disabled).is_true()
	overlay.close()                         # refuses to close while overflowing
	assert_bool(overlay.is_open()).is_true()

	overlay._cells[0].set_marked(true)
	overlay._cells[1].set_marked(true)
	overlay._on_drop_marked()
	await get_tree().process_frame
	assert_int(run.haul.size()).is_equal(6)
	assert_bool(overlay._done_button.disabled).is_false()
	overlay.close()
	assert_bool(overlay.is_open()).is_false()


func test_drop_marked_moves_cards_out_of_the_haul() -> void:
	var overlay: LootBagOverlay = auto_free(LootBagOverlay.new())
	add_child(overlay)
	var run := _run_with(4)
	overlay.open(run, false)
	await get_tree().process_frame
	overlay._cells[0].set_marked(true)
	overlay._on_drop_marked()
	await get_tree().process_frame
	assert_int(run.haul.size()).is_equal(3)
	assert_int(run.dropped.size()).is_equal(1)


func test_reorder_moves_a_card_to_a_new_slot() -> void:
	var overlay: LootBagOverlay = auto_free(LootBagOverlay.new())
	add_child(overlay)
	var run := _run_with(3)                 # haul order: c0, c1, c2
	overlay.open(run, false)
	await get_tree().process_frame
	overlay._on_reorder(2, 0)               # drag the last card onto the first slot
	await get_tree().process_frame
	assert_str(run.haul[0].card_id).is_equal("c2")
	assert_str(run.haul[1].card_id).is_equal("c0")
	assert_str(run.haul[2].card_id).is_equal("c1")
