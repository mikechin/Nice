## Tests for LootBagCell — the loot-bag grid card face. The visual layout is felt
## in playtest; here we assert the data binding, the mark-to-drop treatment, and
## the drag-drop payload gate (the actual drag is engine-driven, not unit-tested).
extends GdUnitTestSuite


func _inst(card_id: String = "好", rarity: int = EconomyEnums.Rarity.RARE) -> CardInstance:
	return CardInstance.create(card_id, rarity)


func test_build_carries_instance_and_index() -> void:
	var cell: LootBagCell = auto_free(LootBagCell.build(_inst("好", EconomyEnums.Rarity.RARE), 3))
	assert_str(cell.instance.card_id).is_equal("好")
	assert_int(cell.index).is_equal(3)


func test_marking_shows_the_drop_treatment() -> void:
	var cell: LootBagCell = auto_free(LootBagCell.build(_inst(), 0))
	add_child(cell)
	assert_bool(cell.marked).is_false()
	assert_bool(cell._banner.visible).is_false()
	cell.toggle_marked()
	assert_bool(cell.marked).is_true()
	assert_bool(cell._banner.visible).is_true()
	assert_bool(cell._veil.visible).is_true()
	cell.toggle_marked()
	assert_bool(cell.marked).is_false()
	assert_bool(cell._banner.visible).is_false()


func test_can_drop_only_loot_cell_payloads() -> void:
	var cell: LootBagCell = auto_free(LootBagCell.build(_inst(), 0))
	add_child(cell)
	assert_bool(cell._can_drop_data(Vector2.ZERO, {"loot_cell": true, "index": 2})).is_true()
	assert_bool(cell._can_drop_data(Vector2.ZERO, {"something": 1})).is_false()
	assert_bool(cell._can_drop_data(Vector2.ZERO, "not a dict")).is_false()
