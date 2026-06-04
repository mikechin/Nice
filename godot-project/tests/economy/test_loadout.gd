## Tests for Loadout — the 5-card kit (= the stake). Slots are untyped (any card
## fits any slot); the 2-passive/3-active split survives only as per-slot ROLES
## the M5 combat layer reads. Covers equip/displace/clear, role partitioning, the
## strip-on-death path, and save round-trip.
extends GdUnitTestSuite


func _ci(card_id: String, rarity: int = EconomyEnums.Rarity.COMMON) -> CardInstance:
	var ci := CardInstance.create(card_id, rarity)
	ci.id = "id_" + card_id  # stable id for assertions (Inventory normally mints these)
	return ci


func test_default_kit_is_five_slots_two_passive_three_active() -> void:
	var lo := Loadout.new()
	assert_int(lo.capacity).is_equal(5)
	assert_int(lo.passive_count).is_equal(2)
	assert_int(lo.active_count()).is_equal(3)
	assert_bool(lo.is_empty()).is_true()
	assert_int(lo.first_empty_slot()).is_equal(0)


func test_slot_roles_partition_by_index() -> void:
	var lo := Loadout.new()
	assert_int(lo.slot_role(0)).is_equal(Loadout.SlotRole.PASSIVE)
	assert_int(lo.slot_role(1)).is_equal(Loadout.SlotRole.PASSIVE)
	assert_int(lo.slot_role(2)).is_equal(Loadout.SlotRole.ACTIVE)
	assert_int(lo.slot_role(4)).is_equal(Loadout.SlotRole.ACTIVE)


func test_any_card_fits_any_slot_no_type_gate() -> void:
	# Untyped: a card equips into a passive slot AND an active slot with no
	# part-of-speech restriction.
	var lo := Loadout.new()
	assert_object(lo.set_slot(0, _ci("我"))).is_null()   # passive slot
	assert_object(lo.set_slot(3, _ci("跑"))).is_null()   # active slot
	assert_int(lo.equipped_count()).is_equal(2)
	assert_bool(lo.has_instance("id_我")).is_true()
	assert_bool(lo.has_instance("id_跑")).is_true()


func test_set_slot_displaces_previous_occupant() -> void:
	var lo := Loadout.new()
	lo.set_slot(2, _ci("a"))
	var displaced := lo.set_slot(2, _ci("b"))
	assert_object(displaced).is_not_null()
	assert_str(displaced.id).is_equal("id_a")           # caller returns this to the bench
	assert_str(lo.get_slot(2).id).is_equal("id_b")
	assert_int(lo.equipped_count()).is_equal(1)


func test_clear_slot_returns_occupant() -> void:
	var lo := Loadout.new()
	lo.set_slot(1, _ci("x"))
	var removed := lo.clear_slot(1)
	assert_str(removed.id).is_equal("id_x")
	assert_object(lo.get_slot(1)).is_null()
	assert_object(lo.clear_slot(1)).is_null()           # already empty


func test_out_of_range_and_null_are_safe_noops() -> void:
	var lo := Loadout.new()
	assert_object(lo.set_slot(99, _ci("a"))).is_null()
	assert_object(lo.set_slot(0, null)).is_null()
	assert_object(lo.get_slot(-1)).is_null()
	assert_int(lo.equipped_count()).is_equal(0)


func test_passive_and_active_instance_partitions() -> void:
	var lo := Loadout.new()
	lo.set_slot(0, _ci("p0"))
	lo.set_slot(1, _ci("p1"))
	lo.set_slot(2, _ci("a2"))
	lo.set_slot(4, _ci("a4"))
	assert_int(lo.passive_instances().size()).is_equal(2)
	assert_int(lo.active_instances().size()).is_equal(2)
	assert_int(lo.equipped().size()).is_equal(4)


func test_first_empty_and_is_full() -> void:
	var lo := Loadout.new()
	for i in 5:
		assert_int(lo.first_empty_slot()).is_equal(i)
		lo.set_slot(i, _ci("c%d" % i))
	assert_bool(lo.is_full()).is_true()
	assert_int(lo.first_empty_slot()).is_equal(-1)


func test_strip_all_empties_and_returns_the_stake() -> void:
	# The death path: the whole kit is lost at once.
	var lo := Loadout.new()
	lo.set_slot(0, _ci("a"))
	lo.set_slot(3, _ci("b"))
	var lost := lo.strip_all()
	assert_int(lost.size()).is_equal(2)
	assert_bool(lo.is_empty()).is_true()


func test_round_trip_preserves_slots_roles_and_grades() -> void:
	var lo := Loadout.new()
	var graded := _ci("好", EconomyEnums.Rarity.RARE)
	graded.grade = 8
	lo.set_slot(0, graded)
	lo.set_slot(4, _ci("学"))

	var restored := Loadout.new()
	restored.load_from_dict(lo.to_dict())
	assert_int(restored.capacity).is_equal(5)
	assert_int(restored.passive_count).is_equal(2)
	assert_int(restored.equipped_count()).is_equal(2)
	assert_str(restored.get_slot(0).card_id).is_equal("好")
	assert_int(restored.get_slot(0).grade).is_equal(8)
	assert_object(restored.get_slot(2)).is_null()       # empty slots stay empty
	assert_str(restored.get_slot(4).card_id).is_equal("学")
