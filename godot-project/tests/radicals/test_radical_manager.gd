## Tests for RadicalManager — radical ownership, equipping, and limits.
extends GdUnitTestSuite

var _mgr: RadicalManager


func before_test() -> void:
	_mgr = RadicalManager.new()


# -- purchase --

func test_purchase_adds_to_owned() -> void:
	_mgr.purchase_radical("水")
	assert_bool(_mgr.is_owned("水")).is_true()


func test_purchase_multiple() -> void:
	_mgr.purchase_radical("水")
	_mgr.purchase_radical("火")
	assert_int(_mgr.owned_radicals.size()).is_equal(2)


func test_purchase_duplicate_no_double() -> void:
	_mgr.purchase_radical("水")
	_mgr.purchase_radical("水")
	assert_int(_mgr.owned_radicals.size()).is_equal(1)


# -- equip --

func test_equip_owned_radical_succeeds() -> void:
	_mgr.purchase_radical("水")
	var result := _mgr.equip_radical("水")
	assert_bool(result).is_true()
	assert_bool(_mgr.is_equipped("水")).is_true()


func test_equip_adds_to_equipped_list() -> void:
	_mgr.purchase_radical("水")
	_mgr.equip_radical("水")
	assert_int(_mgr.equipped_radicals.size()).is_equal(1)


# -- equip not owned --

func test_equip_not_owned_returns_false() -> void:
	var result := _mgr.equip_radical("水")
	assert_bool(result).is_false()
	assert_bool(_mgr.is_equipped("水")).is_false()


# -- equip already equipped --

func test_equip_already_equipped_returns_false() -> void:
	_mgr.purchase_radical("水")
	_mgr.equip_radical("水")
	var result := _mgr.equip_radical("水")
	assert_bool(result).is_false()
	assert_int(_mgr.equipped_radicals.size()).is_equal(1)


# -- max equipped --

func test_max_equipped_respects_limit() -> void:
	for i in _mgr.max_equipped + 2:
		var r := "rad_%d" % i
		_mgr.purchase_radical(r)
		_mgr.equip_radical(r)
	assert_int(_mgr.equipped_radicals.size()).is_equal(_mgr.max_equipped)


func test_equip_beyond_max_returns_false() -> void:
	for i in _mgr.max_equipped:
		var r := "rad_%d" % i
		_mgr.purchase_radical(r)
		_mgr.equip_radical(r)
	_mgr.purchase_radical("extra")
	var result := _mgr.equip_radical("extra")
	assert_bool(result).is_false()


# -- unequip --

func test_unequip_removes_from_equipped() -> void:
	_mgr.purchase_radical("水")
	_mgr.equip_radical("水")
	_mgr.unequip_radical("水")
	assert_bool(_mgr.is_equipped("水")).is_false()
	assert_int(_mgr.equipped_radicals.size()).is_equal(0)


func test_unequip_keeps_owned() -> void:
	_mgr.purchase_radical("水")
	_mgr.equip_radical("水")
	_mgr.unequip_radical("水")
	assert_bool(_mgr.is_owned("水")).is_true()


func test_unequip_frees_slot() -> void:
	for i in _mgr.max_equipped:
		var r := "rad_%d" % i
		_mgr.purchase_radical(r)
		_mgr.equip_radical(r)
	assert_int(_mgr.get_available_slots()).is_equal(0)
	_mgr.unequip_radical("rad_0")
	assert_int(_mgr.get_available_slots()).is_equal(1)


func test_unequip_nonexistent_no_crash() -> void:
	_mgr.unequip_radical("nonexistent")
	assert_int(_mgr.equipped_radicals.size()).is_equal(0)


# -- get_unequipped_owned --

func test_get_unequipped_owned() -> void:
	_mgr.purchase_radical("水")
	_mgr.purchase_radical("火")
	_mgr.equip_radical("水")
	var unequipped := _mgr.get_unequipped_owned()
	assert_int(unequipped.size()).is_equal(1)
	assert_str(unequipped[0]).is_equal("火")


# -- serialization --

func test_serialization_round_trip() -> void:
	_mgr.purchase_radical("水")
	_mgr.purchase_radical("火")
	_mgr.equip_radical("水")
	var dict := _mgr.to_dict()
	var restored := RadicalManager.from_dict(dict)
	assert_bool(restored.is_owned("水")).is_true()
	assert_bool(restored.is_owned("火")).is_true()
	assert_bool(restored.is_equipped("水")).is_true()
	assert_bool(restored.is_equipped("火")).is_false()
