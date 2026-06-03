## Tests for RunMap — the fixed 1.0 dungeon graph + traversal cursor.
## Verifies the hand-built layout, forward-only movement (no backtracking),
## depth never decreasing along an edge, and boss-clear completion.
extends GdUnitTestSuite


func test_default_map_shape() -> void:
	var m := RunMap.build_default()
	assert_int(m.nodes.size()).is_equal(9)
	assert_int(m.current_index).is_equal(0)
	assert_int(m.current().type).is_equal(DungeonEnums.RoomType.ENCOUNTER)
	assert_int(m.current().depth).is_equal(0)
	# Last node is the terminal boss.
	var last: RoomNode = m.nodes[8]
	assert_int(last.type).is_equal(DungeonEnums.RoomType.BOSS)
	assert_bool(last.is_terminal()).is_true()


func test_entrance_branches() -> void:
	var m := RunMap.build_default()
	var nexts := m.available_next()
	assert_int(nexts.size()).is_equal(2)  # telegraphed branch
	assert_int(nexts[0].index).is_equal(1)
	assert_int(nexts[1].index).is_equal(2)


func test_move_only_along_edges() -> void:
	var m := RunMap.build_default()
	assert_bool(m.can_move_to(1)).is_true()
	assert_bool(m.can_move_to(3)).is_false()  # not adjacent to 0
	assert_bool(m.move_to(3)).is_false()
	assert_int(m.current_index).is_equal(0)   # rejected → cursor unchanged
	assert_bool(m.move_to(1)).is_true()
	assert_int(m.current_index).is_equal(1)


func test_no_backtracking() -> void:
	var m := RunMap.build_default()
	m.move_to(1)
	m.move_to(3)
	# Cannot return to a previous node (forward-only).
	assert_bool(m.can_move_to(0)).is_false()
	assert_bool(m.can_move_to(1)).is_false()
	assert_bool(m.move_to(0)).is_false()
	assert_int(m.current_index).is_equal(3)


func test_depth_never_decreases_along_edges() -> void:
	var m := RunMap.build_default()
	for node in m.nodes:
		for nxt in node.next:
			var target: RoomNode = m.nodes[nxt]
			assert_int(target.depth).is_greater_equal(node.depth)


func test_full_traversal_to_boss() -> void:
	var m := RunMap.build_default()
	for idx in [1, 3, 4, 5, 6, 7, 8]:
		assert_bool(m.move_to(idx)).is_true()
	assert_int(m.current().type).is_equal(DungeonEnums.RoomType.BOSS)
	# Boss reached but not cleared → run not complete yet.
	assert_bool(m.is_complete()).is_false()
	m.mark_current_cleared()
	assert_bool(m.is_complete()).is_true()


func test_mark_current_cleared() -> void:
	var m := RunMap.build_default()
	assert_bool(m.current().cleared).is_false()
	m.mark_current_cleared()
	assert_bool(m.current().cleared).is_true()


func test_extract_nodes_are_gates_not_fights() -> void:
	var m := RunMap.build_default()
	var gate: RoomNode = m.nodes[4]
	assert_int(gate.type).is_equal(DungeonEnums.RoomType.EXTRACT)
	assert_bool(gate.is_extract()).is_true()
	assert_bool(gate.is_fight()).is_false()
