## PackData — Tests get_total_count(), get_category_for_card(), build_presentation_order(), to_dict()/from_dict().
extends GdUnitTestSuite

var pack: PackData


func before_test() -> void:
	pack = PackData.new()
	pack.pack_id = "test_pack_001"
	pack.created_at = 1700000000.0
	pack.pack_type = "daily"
	pack.common_cards = ["好", "大", "小"] as Array[String]
	pack.struggling_cards = ["难"] as Array[String]
	pack.new_cards = ["新", "鲜"] as Array[String]
	pack.returning_mastered = ["人"] as Array[String]


func test_get_total_count() -> void:
	assert_int(pack.get_total_count()).is_equal(7)


func test_get_total_count_empty() -> void:
	var empty_pack := PackData.new()
	assert_int(empty_pack.get_total_count()).is_equal(0)


func test_get_category_for_new_card() -> void:
	assert_str(pack.get_category_for_card("新")).is_equal("new")


func test_get_category_for_struggling_card() -> void:
	assert_str(pack.get_category_for_card("难")).is_equal("struggling")


func test_get_category_for_returning_mastered() -> void:
	assert_str(pack.get_category_for_card("人")).is_equal("returning_mastered")


func test_get_category_for_common_card() -> void:
	assert_str(pack.get_category_for_card("好")).is_equal("common")


func test_get_category_for_unknown_card() -> void:
	assert_str(pack.get_category_for_card("不存在")).is_equal("common")


func test_build_presentation_order_includes_all_cards() -> void:
	pack.build_presentation_order()
	assert_int(pack.presentation_order.size()).is_equal(pack.get_total_count())


func test_build_presentation_order_contains_each_card() -> void:
	pack.build_presentation_order()
	for card_id in pack.common_cards:
		assert_bool(card_id in pack.presentation_order).is_true()
	for card_id in pack.new_cards:
		assert_bool(card_id in pack.presentation_order).is_true()
	for card_id in pack.struggling_cards:
		assert_bool(card_id in pack.presentation_order).is_true()


func test_to_dict_contains_required_keys() -> void:
	var dict := pack.to_dict()
	assert_bool(dict.has("pack_id")).is_true()
	assert_bool(dict.has("created_at")).is_true()
	assert_bool(dict.has("pack_type")).is_true()
	assert_bool(dict.has("common_cards")).is_true()
	assert_bool(dict.has("struggling_cards")).is_true()
	assert_bool(dict.has("new_cards")).is_true()
	assert_bool(dict.has("returning_mastered")).is_true()


func test_from_dict_round_trip() -> void:
	var dict := pack.to_dict()
	var restored := PackData.from_dict(dict)
	assert_str(restored.pack_id).is_equal(pack.pack_id)
	assert_float(restored.created_at).is_equal(pack.created_at)
	assert_str(restored.pack_type).is_equal(pack.pack_type)
	assert_int(restored.common_cards.size()).is_equal(pack.common_cards.size())
	assert_int(restored.struggling_cards.size()).is_equal(pack.struggling_cards.size())
	assert_int(restored.new_cards.size()).is_equal(pack.new_cards.size())
	assert_int(restored.returning_mastered.size()).is_equal(pack.returning_mastered.size())


func test_from_dict_defaults_on_empty() -> void:
	var restored := PackData.from_dict({})
	assert_str(restored.pack_id).is_equal("")
	assert_str(restored.pack_type).is_equal("daily")
	assert_int(restored.get_total_count()).is_equal(0)
