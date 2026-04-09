## Tests for ChallengePresenter — rating determination logic.
extends GdUnitTestSuite

var presenter: ChallengePresenter


func before_test() -> void:
	presenter = ChallengePresenter.new()


func after_test() -> void:
	presenter.free()


func test_determine_rating_incorrect_returns_again() -> void:
	var rating := presenter._determine_rating(false, 1000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.AGAIN)


func test_determine_rating_incorrect_slow_returns_again() -> void:
	var rating := presenter._determine_rating(false, 10000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.AGAIN)


func test_determine_rating_fast_correct_returns_easy() -> void:
	var rating := presenter._determine_rating(true, 500)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.EASY)


func test_determine_rating_medium_correct_returns_good() -> void:
	var rating := presenter._determine_rating(true, 3000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.GOOD)


func test_determine_rating_slow_correct_returns_hard() -> void:
	var rating := presenter._determine_rating(true, 7000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.HARD)


func test_determine_rating_boundary_2000ms_is_good() -> void:
	# Exactly at the 2000ms boundary: elapsed_ms < 2000 is false, so GOOD
	var rating := presenter._determine_rating(true, 2000)
	assert_int(rating).is_equal(FsrsAlgorithm.Rating.GOOD)
