## Tests for SessionData — session result tracking and serialization.
extends GdUnitTestSuite

var session: SessionData


func before_test() -> void:
	session = SessionData.new()
	session.session_id = "test_session_001"
	session.started_at = 1700000000.0
	session.ended_at = 1700000300.0


# -- record_answer is the SRS-stage event --

func test_record_answer_increments_total() -> void:
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	assert_int(session.total_cards).is_equal(1)


func test_record_answer_tracks_correct() -> void:
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	session.record_answer("ni3", "meaning", false, FsrsAlgorithm.Rating.AGAIN, 3000)
	assert_int(session.correct_count).is_equal(1)
	assert_int(session.total_cards).is_equal(2)


func test_record_answer_appends_to_card_results() -> void:
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	assert_int(session.card_results.size()).is_equal(1)
	assert_str(session.card_results[0]["card_id"]).is_equal("wo3")
	assert_bool(session.card_results[0]["correct"]).is_true()


func test_record_answer_does_not_touch_hand_cards() -> void:
	# Hand membership is decided per-card by record_card_resolution, not
	# by per-stage record_answer. Otherwise bonus stages would re-add the
	# card and inflate the hand.
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	assert_int(session.hand_cards.size()).is_equal(0)


func test_get_accuracy_correct_ratio() -> void:
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	session.record_answer("ni3", "meaning", false, FsrsAlgorithm.Rating.AGAIN, 3000)
	assert_float(session.get_accuracy()).is_equal_approx(0.5, 0.001)


func test_get_accuracy_zero_when_no_cards() -> void:
	assert_float(session.get_accuracy()).is_equal(0.0)


# -- record_card_resolution: per-card hand membership + power --

func test_record_card_resolution_correct_adds_handcard() -> void:
	var boosts: Array = [PowerBoost.from_bonus_stage(BonusEnums.BonusStage.PINYIN)]
	session.record_card_resolution("wo3", true, 7, boosts)
	assert_int(session.hand_cards.size()).is_equal(1)
	var hc := session.get_hand_card("wo3")
	assert_str(hc.card_id).is_equal("wo3")
	assert_int(hc.base_power).is_equal(7)
	assert_int(hc.get_total_power()).is_equal(8)


func test_record_card_resolution_wrong_does_not_add() -> void:
	session.record_card_resolution("wo3", false, 7, [])
	assert_int(session.hand_cards.size()).is_equal(0)


func test_record_card_resolution_dedupes_by_card_id() -> void:
	# Should never happen in practice (one resolution per card per run),
	# but the dedup makes the contract robust.
	session.record_card_resolution("wo3", true, 7, [])
	session.record_card_resolution("wo3", true, 5, [])
	assert_int(session.hand_cards.size()).is_equal(1)
	# First resolution wins — second is ignored entirely.
	assert_int(session.get_hand_card("wo3").base_power).is_equal(7)


func test_has_hand_card_returns_true_when_present() -> void:
	session.record_card_resolution("wo3", true, 4, [])
	assert_bool(session.has_hand_card("wo3")).is_true()
	assert_bool(session.has_hand_card("ni3")).is_false()


func test_get_hand_card_ids_returns_string_list() -> void:
	session.record_card_resolution("wo3", true, 4, [])
	session.record_card_resolution("hao3", true, 5, [])
	session.record_card_resolution("ni3", false, 4, [])
	var ids := session.get_hand_card_ids()
	assert_int(ids.size()).is_equal(2)
	assert_bool("wo3" in ids).is_true()
	assert_bool("hao3" in ids).is_true()
	assert_bool("ni3" in ids).is_false()


func test_get_total_hand_power_sums_across_cards() -> void:
	var boosts: Array = [PowerBoost.from_bonus_stage(BonusEnums.BonusStage.PINYIN)]
	session.record_card_resolution("wo3", true, 7, boosts)  # 7 + 1 = 8
	session.record_card_resolution("hao3", true, 4, [])     # 4
	session.record_card_resolution("ni3", false, 9, [])     # not added
	assert_int(session.get_total_hand_power()).is_equal(12)


func test_get_total_hand_power_zero_when_empty() -> void:
	assert_int(session.get_total_hand_power()).is_equal(0)


# -- serialization --

func test_to_dict_has_expected_keys() -> void:
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	var d := session.to_dict()
	assert_str(d["session_id"]).is_equal("test_session_001")
	assert_int(d["total_cards"]).is_equal(1)
	assert_int(d["correct_count"]).is_equal(1)
	assert_bool(d.has("card_results")).is_true()
	assert_bool(d.has("hand_cards")).is_true()


func test_from_dict_round_trip_preserves_handcards() -> void:
	var boosts: Array = [PowerBoost.from_bonus_stage(BonusEnums.BonusStage.TONE)]
	session.record_card_resolution("wo3", true, 7, boosts)
	var d := session.to_dict()
	var restored := SessionData.from_dict(d)
	assert_int(restored.hand_cards.size()).is_equal(1)
	var hc := restored.get_hand_card("wo3")
	assert_int(hc.get_total_power()).is_equal(8)


func test_from_dict_round_trip_basic_fields() -> void:
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	var d := session.to_dict()
	var restored := SessionData.from_dict(d)
	assert_str(restored.session_id).is_equal("test_session_001")
	assert_int(restored.total_cards).is_equal(1)
