## ShopRotation — Tests generate_rotation() item composition, get_available_radicals() filtering.
extends GdUnitTestSuite

var rad_db: RadicalDatabase
var rotation: ShopRotation


func before_test() -> void:
	rad_db = RadicalDatabase.new()
	var radicals: Array[RadicalData] = []
	radicals.append(RadicalData.from_dict({
		"radical": "氵", "meaning": "water", "rarity_tier": "common",
		"shop_cost": 50, "characters": ["海", "河"], "display_name": "Water",
	}))
	radicals.append(RadicalData.from_dict({
		"radical": "火", "meaning": "fire", "rarity_tier": "rare",
		"shop_cost": 100, "characters": ["烤", "灯"], "display_name": "Fire",
	}))
	radicals.append(RadicalData.from_dict({
		"radical": "金", "meaning": "gold", "rarity_tier": "epic",
		"shop_cost": 200, "characters": ["银", "钱"], "display_name": "Gold",
	}))
	radicals.append(RadicalData.from_dict({
		"radical": "木", "meaning": "wood", "rarity_tier": "common",
		"shop_cost": 50, "characters": ["林", "森"], "display_name": "Wood",
	}))
	rad_db.load_from_array(radicals)
	rotation = ShopRotation.new(rad_db)


func test_generate_rotation_returns_items() -> void:
	var owned: Array[String] = []
	var items := rotation.generate_rotation(4, owned)
	assert_bool(items.size() > 0).is_true()


func test_generate_rotation_includes_extra_heart() -> void:
	var owned: Array[String] = []
	var items := rotation.generate_rotation(4, owned)
	var has_heart := false
	for item in items:
		if item.item_type == ShopItem.ItemType.EXTRA_HEART:
			has_heart = true
			break
	assert_bool(has_heart).is_true()


func test_generate_rotation_includes_pack_refresh() -> void:
	var owned: Array[String] = []
	var items := rotation.generate_rotation(4, owned)
	var has_refresh := false
	for item in items:
		if item.item_type == ShopItem.ItemType.PACK_REFRESH:
			has_refresh = true
			break
	assert_bool(has_refresh).is_true()


func test_available_radicals_excludes_owned() -> void:
	var owned: Array = ["氵"]
	var available := rotation.get_available_radicals(4, owned, 10)
	for item in available:
		assert_str(item.data.get("radical", "")).is_not_equal("氵")


func test_available_radicals_excludes_epic_for_low_level() -> void:
	var owned: Array = []
	var available := rotation.get_available_radicals(2, owned, 10)
	for item in available:
		assert_str(item.data.get("rarity_tier", "")).is_not_equal("epic")


func test_available_radicals_excludes_rare_for_level_below_3() -> void:
	var owned: Array = []
	var available := rotation.get_available_radicals(2, owned, 10)
	for item in available:
		assert_str(item.data.get("rarity_tier", "")).is_not_equal("rare")


func test_available_radicals_respects_count_limit() -> void:
	var owned: Array = []
	var available := rotation.get_available_radicals(4, owned, 2)
	assert_bool(available.size() <= 2).is_true()
