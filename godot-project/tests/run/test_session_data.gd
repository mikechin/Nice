## Tests for SessionData — session result tracking and serialization.
extends GdUnitTestSuite

var session: SessionData


func before_test() -> void:
	session = SessionData.new()
	session.session_id = "test_session_001"
	session.started_at = 1700000000.0
	session.ended_at = 1700000300.0
	session.run_type = "easy"


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


func test_get_accuracy_correct_ratio() -> void:
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	session.record_answer("ni3", "meaning", false, FsrsAlgorithm.Rating.AGAIN, 3000)
	assert_float(session.get_accuracy()).is_equal_approx(0.5, 0.001)


func test_get_accuracy_zero_when_no_cards() -> void:
	assert_float(session.get_accuracy()).is_equal(0.0)


func test_to_dict_has_expected_keys() -> void:
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	var d := session.to_dict()
	assert_str(d["session_id"]).is_equal("test_session_001")
	assert_str(d["run_type"]).is_equal("easy")
	assert_int(d["total_cards"]).is_equal(1)
	assert_int(d["correct_count"]).is_equal(1)
	assert_bool(d.has("card_results")).is_true()


func test_from_dict_round_trip() -> void:
	session.record_answer("wo3", "meaning", true, FsrsAlgorithm.Rating.GOOD, 1500)
	var d := session.to_dict()
	var restored := SessionData.from_dict(d)
	assert_str(restored.session_id).is_equal("test_session_001")
	assert_int(restored.total_cards).is_equal(1)
