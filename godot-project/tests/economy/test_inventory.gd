## Tests for Inventory — the persistent bench. Mints stable ids, supports
## shatter/remove/count, and round-trips (preserving the id counter so ids
## never collide after a load).
extends GdUnitTestSuite


func _ci(card_id: String, rarity: int = EconomyEnums.Rarity.COMMON) -> CardInstance:
	return CardInstance.create(card_id, rarity)


func test_add_mints_a_stable_id() -> void:
	var inv := Inventory.new()
	var ci := inv.add(_ci("好"))
	assert_str(ci.id).is_not_empty()
	assert_int(inv.size()).is_equal(1)


func test_ids_are_unique() -> void:
	var inv := Inventory.new()
	var a := inv.add(_ci("a"))
	var b := inv.add(_ci("b"))
	assert_str(a.id).is_not_equal(b.id)


func test_add_many_and_count_of() -> void:
	var inv := Inventory.new()
	inv.add_many([_ci("好"), _ci("好"), _ci("学")])
	assert_int(inv.size()).is_equal(3)
	assert_int(inv.count_of("好")).is_equal(2)
	assert_int(inv.count_of("学")).is_equal(1)


func test_remove_returns_and_drops_instance() -> void:
	var inv := Inventory.new()
	var ci := inv.add(_ci("好"))
	var removed := inv.remove(ci.id)
	assert_object(removed).is_not_null()
	assert_int(inv.size()).is_equal(0)
	assert_object(inv.remove("nope")).is_null()


func test_shatter_returns_value_and_removes() -> void:
	var inv := Inventory.new()
	var ci := inv.add(_ci("好", EconomyEnums.Rarity.RARE))
	var value := inv.shatter(ci.id)
	assert_int(value).is_equal(ci.shard_value())
	assert_int(inv.size()).is_equal(0)


func test_round_trip_preserves_instances_and_id_counter() -> void:
	var inv := Inventory.new()
	inv.add(_ci("a", EconomyEnums.Rarity.RARE))
	inv.add(_ci("b"))
	var dict := inv.to_dict()

	var restored := Inventory.new()
	restored.load_from_dict(dict)
	assert_int(restored.size()).is_equal(2)
	# New adds keep minting fresh (non-colliding) ids.
	var fresh := restored.add(_ci("c"))
	assert_object(restored.get_instance(fresh.id)).is_not_null()
	assert_int(restored.count_of("a")).is_equal(1)
