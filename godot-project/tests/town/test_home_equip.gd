## Tests for Home's slot-targeted equip flow (M5 UX). The clumsy "always fill the
## first empty slot" path is replaced by a selectable target slot — which matters now
## that role placement scales an effect's value. Covers the target resolution, the
## tap-to-toggle selection, and that Equip honours the chosen slot.
extends GdUnitTestSuite


func before_test() -> void:
	GameState.load_from_dict({})
	GameState._shop = null
	GameState._craft_system = null


func after_test() -> void:
	GameState.load_from_dict({})
	GameState._shop = null
	GameState._craft_system = null


func _home() -> Node:
	var h: Node = load("res://scenes/screens/home.tscn").instantiate()
	add_child(h)                                  # _ready builds the UI
	return h


func test_target_defaults_to_first_empty_slot() -> void:
	var h := _home()
	assert_int(h._selected_slot).is_equal(-1)
	assert_int(h._target_slot()).is_equal(0)      # empty kit → first empty is slot 0
	h.free()


func test_selecting_a_slot_targets_it_and_taps_toggle_off() -> void:
	var h := _home()
	h._select_slot(3)
	assert_int(h._selected_slot).is_equal(3)
	assert_int(h._target_slot()).is_equal(3)
	h._select_slot(3)                             # tap the same slot again → clear
	assert_int(h._selected_slot).is_equal(-1)
	h.free()


func test_equip_honours_the_chosen_slot_not_first_empty() -> void:
	var ci := GameState.inventory.add(CardInstance.create("火", EconomyEnums.Rarity.COMMON))
	var h := _home()
	h._select_slot(4)                             # an active slot — NOT first-empty (0)
	h._equip_to_target(ci.id)
	assert_object(GameState.loadout.get_slot(4)).is_not_null()
	assert_object(GameState.loadout.get_slot(0)).is_null()
	# After filling the chosen slot, the target advances to the next empty one.
	assert_int(h._selected_slot).is_equal(0)
	h.free()


func test_equip_into_a_filled_chosen_slot_swaps() -> void:
	var a := GameState.inventory.add(CardInstance.create("火", EconomyEnums.Rarity.COMMON))
	var b := GameState.inventory.add(CardInstance.create("水", EconomyEnums.Rarity.COMMON))
	var h := _home()
	h._select_slot(1)
	h._equip_to_target(a.id)                      # slot 1 ← 火
	h._select_slot(1)                             # re-target the now-filled slot 1
	h._equip_to_target(b.id)                      # slot 1 ← 水, 火 returns to the bench
	assert_str(GameState.loadout.get_slot(1).card_id).is_equal("水")
	assert_object(GameState.inventory.get_instance(a.id)).is_not_null()
	h.free()
