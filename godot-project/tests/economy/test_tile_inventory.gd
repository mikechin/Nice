## Tests for TileInventory — tile addition, removal, batch operations, and counting.
extends GdUnitTestSuite

var _inv: TileInventory


func before_test() -> void:
	_inv = TileInventory.new()


# -- add_tile --

func test_add_tile_increases_count() -> void:
	_inv.add_tile("好")
	assert_int(_inv.get_count("好")).is_equal(1)


func test_add_tile_multiple() -> void:
	_inv.add_tile("好", 3)
	assert_int(_inv.get_count("好")).is_equal(3)


func test_add_tile_accumulates() -> void:
	_inv.add_tile("好", 2)
	_inv.add_tile("好", 3)
	assert_int(_inv.get_count("好")).is_equal(5)


# -- remove_tile --

func test_remove_tile_decrements() -> void:
	_inv.add_tile("好", 3)
	var result := _inv.remove_tile("好")
	assert_bool(result).is_true()
	assert_int(_inv.get_count("好")).is_equal(2)


func test_remove_tile_to_zero_erases() -> void:
	_inv.add_tile("好", 1)
	_inv.remove_tile("好")
	assert_int(_inv.get_count("好")).is_equal(0)
	assert_bool(_inv.has_tile("好")).is_false()


func test_remove_tile_insufficient_returns_false() -> void:
	_inv.add_tile("好", 1)
	var result := _inv.remove_tile("好", 5)
	assert_bool(result).is_false()
	assert_int(_inv.get_count("好")).is_equal(1)


func test_remove_tile_nonexistent_returns_false() -> void:
	var result := _inv.remove_tile("X")
	assert_bool(result).is_false()


# -- remove_tiles batch --

func test_remove_tiles_batch_success() -> void:
	_inv.add_tile("好", 2)
	_inv.add_tile("大", 1)
	var result := _inv.remove_tiles(["好", "大"])
	assert_bool(result).is_true()
	assert_int(_inv.get_count("好")).is_equal(1)
	assert_int(_inv.get_count("大")).is_equal(0)


func test_remove_tiles_batch_insufficient_fails() -> void:
	_inv.add_tile("好", 1)
	var result := _inv.remove_tiles(["好", "好"])
	assert_bool(result).is_false()
	# Original inventory should be untouched
	assert_int(_inv.get_count("好")).is_equal(1)


func test_remove_tiles_batch_mixed_characters() -> void:
	_inv.add_tile("我", 3)
	_inv.add_tile("好", 2)
	_inv.add_tile("人", 1)
	var result := _inv.remove_tiles(["我", "好", "人", "我"])
	assert_bool(result).is_true()
	assert_int(_inv.get_count("我")).is_equal(1)
	assert_int(_inv.get_count("好")).is_equal(1)
	assert_int(_inv.get_count("人")).is_equal(0)


# -- total_count --

func test_total_count_empty() -> void:
	assert_int(_inv.get_total_tile_count()).is_equal(0)


func test_total_count_sums_all() -> void:
	_inv.add_tile("好", 3)
	_inv.add_tile("大", 2)
	_inv.add_tile("人", 1)
	assert_int(_inv.get_total_tile_count()).is_equal(6)


# -- unique_tile_count --

func test_unique_tile_count() -> void:
	_inv.add_tile("好", 5)
	_inv.add_tile("大", 3)
	assert_int(_inv.get_unique_tile_count()).is_equal(2)


# -- has_tile --

func test_has_tile_true() -> void:
	_inv.add_tile("好")
	assert_bool(_inv.has_tile("好")).is_true()


func test_has_tile_false() -> void:
	assert_bool(_inv.has_tile("X")).is_false()


# -- clear --

func test_clear_empties_inventory() -> void:
	_inv.add_tile("好", 5)
	_inv.add_tile("大", 3)
	_inv.clear()
	assert_int(_inv.get_total_tile_count()).is_equal(0)


# -- serialization --

func test_to_dict_round_trip() -> void:
	_inv.add_tile("好", 3)
	_inv.add_tile("大", 1)
	var dict := _inv.to_dict()
	var restored := TileInventory.new()
	restored.load_from_dict(dict)
	assert_int(restored.get_count("好")).is_equal(3)
	assert_int(restored.get_count("大")).is_equal(1)
