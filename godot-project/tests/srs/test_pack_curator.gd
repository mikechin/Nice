## PackCurator — Tests curate_pack() filling slots correctly and respecting max new cards.
extends GdUnitTestSuite

var fsrs: FsrsAlgorithm
var card_states: Dictionary
var now: float


func before_test() -> void:
	fsrs = FsrsAlgorithm.new()
	now = 1700000000.0
	card_states = {}

	# Create a mix of card states:
	# 5 cards that have been reviewed and are due
	for i in range(5):
		var cs := CardState.create("due_%d" % i, "字", fsrs)
		var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.GOOD, now - 86400.0 * 30)
		cs.update_state("meaning", reviewed)
		card_states["due_%d" % i] = cs

	# 3 cards with very low retrievability (struggling)
	for i in range(3):
		var cs := CardState.create("struggle_%d" % i, "难", fsrs)
		var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.AGAIN, now - 86400.0 * 5)
		cs.update_state("meaning", reviewed)
		card_states["struggle_%d" % i] = cs

	# 2 well-known cards
	for i in range(2):
		var cs := CardState.create("known_%d" % i, "好", fsrs)
		var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.EASY, now)
		cs.update_state("meaning", reviewed)
		card_states["known_%d" % i] = cs


func test_curate_pack_returns_pack_data() -> void:
	var curator := PackCurator.new(fsrs, card_states)
	var pack := curator.curate_pack(now, 10)
	assert_bool(pack != null).is_true()
	assert_str(pack.pack_id).is_not_empty()


func test_curate_pack_fills_to_target_size() -> void:
	var curator := PackCurator.new(fsrs, card_states)
	var pack := curator.curate_pack(now, 10)
	# Pack should try to fill to target; may not reach exactly 10 if not enough cards
	assert_bool(pack.get_total_count() > 0).is_true()
	assert_bool(pack.get_total_count() <= 10).is_true()


func test_curate_pack_includes_new_cards() -> void:
	var curator := PackCurator.new(fsrs, card_states)
	var new_ids: Array = ["new_A", "new_B", "new_C", "new_D", "new_E"]
	var pack := curator.curate_pack(now, 10, new_ids)
	assert_bool(pack.new_cards.size() > 0).is_true()


func test_curate_pack_respects_max_new_cards() -> void:
	var curator := PackCurator.new(fsrs, card_states)
	var new_ids: Array = ["n1", "n2", "n3", "n4", "n5", "n6", "n7", "n8", "n9", "n10"]
	var pack := curator.curate_pack(now, 20, new_ids)
	assert_bool(pack.new_cards.size() <= SrsConfig.MAX_NEW_CARDS_PER_SESSION).is_true()


func test_curate_pack_sets_presentation_order() -> void:
	var curator := PackCurator.new(fsrs, card_states)
	var pack := curator.curate_pack(now, 10)
	assert_bool(pack.presentation_order.size() > 0).is_true()


func test_curate_pack_with_no_card_states() -> void:
	var curator := PackCurator.new(fsrs, {})
	var new_ids: Array = ["new_A", "new_B"]
	var pack := curator.curate_pack(now, 10, new_ids)
	# Only new cards should be present
	assert_int(pack.new_cards.size()).is_equal(2)
	assert_int(pack.common_cards.size()).is_equal(0)
	assert_int(pack.struggling_cards.size()).is_equal(0)


func test_curate_pack_empty_when_nothing_available() -> void:
	var curator := PackCurator.new(fsrs, {})
	var pack := curator.curate_pack(now, 10)
	assert_int(pack.get_total_count()).is_equal(0)
