## Tests for CardState — per-card SRS data model with challenge types.
extends GdUnitTestSuite

var fsrs: FsrsAlgorithm


func before_test() -> void:
	fsrs = FsrsAlgorithm.new()


# -- create --

func test_create_sets_id_and_character() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	assert_str(cs.card_id).is_equal("char_001")
	assert_str(cs.character).is_equal("好")


func test_create_initializes_four_challenge_types() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	assert_int(cs.states.size()).is_equal(4)
	assert_bool(cs.states.has("meaning")).is_true()
	assert_bool(cs.states.has("character")).is_true()
	assert_bool(cs.states.has("pinyin")).is_true()
	assert_bool(cs.states.has("tone")).is_true()


func test_create_all_states_are_new() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	for ct_str in cs.states:
		assert_int(cs.states[ct_str]["state"]).is_equal(FsrsAlgorithm.State.NEW)


# -- is_new --

func test_is_new_fresh_card() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	assert_bool(cs.is_new()).is_true()


func test_is_new_after_review() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	var new_state := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.GOOD, now)
	cs.update_state("meaning", new_state)
	assert_bool(cs.is_new()).is_false()


# -- get_weakest_challenge_type --

func test_weakest_challenge_type_all_new_returns_first() -> void:
	# All at stability 0.0, should return one of them deterministically
	var cs := CardState.create("char_001", "好", fsrs)
	var weakest := cs.get_weakest_challenge_type()
	# When all are equal (0.0), the first iterated key wins
	assert_bool(weakest in ["meaning", "character", "pinyin", "tone"]).is_true()


func test_weakest_challenge_type_returns_lowest_stability() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	# Review all types except "tone" so tone remains weakest (stability 0)
	for ct_str in ["meaning", "character", "pinyin"]:
		var reviewed := fsrs.review(cs.states[ct_str], FsrsAlgorithm.Rating.GOOD, now)
		cs.update_state(ct_str, reviewed)
	assert_str(cs.get_weakest_challenge_type()).is_equal("tone")


func test_weakest_challenge_type_picks_lower_stability() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	# Review all types
	for ct_str in ["meaning", "character", "pinyin", "tone"]:
		var rating := FsrsAlgorithm.Rating.EASY if ct_str != "pinyin" else FsrsAlgorithm.Rating.AGAIN
		var reviewed := fsrs.review(cs.states[ct_str], rating, now)
		cs.update_state(ct_str, reviewed)
	# "pinyin" was rated AGAIN -> lower stability
	assert_str(cs.get_weakest_challenge_type()).is_equal("pinyin")


# -- is_due --

func test_is_due_new_card_not_due() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	assert_bool(cs.is_due("meaning", now)).is_false()


func test_is_due_after_short_interval() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.GOOD, now)
	cs.update_state("meaning", reviewed)
	var scheduled_days: int = reviewed["scheduled_days"]
	# Advance past the scheduled interval
	var future := now + (scheduled_days + 1) * 86400.0
	assert_bool(cs.is_due("meaning", future)).is_true()


func test_is_due_learning_state_immediately() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.AGAIN, now)
	cs.update_state("meaning", reviewed)
	# Learning state with scheduled_days=0 should be due immediately
	assert_int(reviewed["scheduled_days"]).is_equal(0)
	assert_bool(cs.is_due("meaning", now + 1.0)).is_true()


func test_is_not_due_within_interval() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.GOOD, now)
	cs.update_state("meaning", reviewed)
	# Check immediately after review -- should not be due yet
	assert_bool(cs.is_due("meaning", now + 1.0)).is_false()


func test_is_any_due() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	# Review only meaning
	var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.AGAIN, now)
	cs.update_state("meaning", reviewed)
	# Learning card is immediately due
	assert_bool(cs.is_any_due(now + 1.0)).is_true()


# -- retrievability --

func test_retrievability_new_card_zero() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	var r := cs.get_retrievability("meaning", now)
	assert_float(r).is_equal(0.0)


func test_retrievability_after_review() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.GOOD, now)
	cs.update_state("meaning", reviewed)
	# One day later
	var r := cs.get_retrievability("meaning", now + 86400.0)
	assert_float(r).is_greater(0.0)
	assert_float(r).is_less_equal(1.0)


func test_average_retrievability_no_reviews_zero() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	assert_float(cs.get_average_retrievability(now)).is_equal(0.0)


# -- is_about_to_forget --

func test_is_about_to_forget_new_card_false() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	assert_bool(cs.is_about_to_forget("meaning", now)).is_false()


# -- serialization round-trip --

func test_serialization_round_trip() -> void:
	var cs := CardState.create("char_002", "大", fsrs)
	var now := 1700000000.0
	# Do a review so there is non-trivial state
	var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.GOOD, now)
	cs.update_state("meaning", reviewed)

	var dict := cs.to_dict()
	var restored := CardState.from_dict(dict, fsrs)

	assert_str(restored.card_id).is_equal("char_002")
	assert_str(restored.character).is_equal("大")
	assert_int(restored.states.size()).is_equal(4)
	# The reviewed challenge type should have its state preserved
	assert_int(restored.states["meaning"]["state"]).is_equal(FsrsAlgorithm.State.REVIEW)
	assert_float(restored.states["meaning"]["stability"]).is_equal(cs.states["meaning"]["stability"])
	assert_float(restored.states["meaning"]["difficulty"]).is_equal(cs.states["meaning"]["difficulty"])


func test_serialization_preserves_all_challenge_types() -> void:
	var cs := CardState.create("char_003", "人", fsrs)
	var dict := cs.to_dict()
	var restored := CardState.from_dict(dict, fsrs)
	for ct_str in ["meaning", "character", "pinyin", "tone"]:
		assert_bool(restored.states.has(ct_str)).is_true()


# -- get_best_state --

func test_get_best_state_all_new() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	assert_int(cs.get_best_state()).is_equal(FsrsAlgorithm.State.NEW)


func test_get_best_state_after_review() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.GOOD, now)
	cs.update_state("meaning", reviewed)
	assert_int(cs.get_best_state()).is_equal(FsrsAlgorithm.State.REVIEW)


# -- get_max_stability --

func test_get_max_stability_new_card() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	assert_float(cs.get_max_stability()).is_equal(0.0)


func test_get_max_stability_after_review() -> void:
	var cs := CardState.create("char_001", "好", fsrs)
	var now := 1700000000.0
	var reviewed := fsrs.review(cs.states["meaning"], FsrsAlgorithm.Rating.EASY, now)
	cs.update_state("meaning", reviewed)
	assert_float(cs.get_max_stability()).is_greater(0.0)
