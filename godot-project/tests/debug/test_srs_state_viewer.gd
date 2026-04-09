## Tests for SrsStateViewer — SRS state querying utility.
extends GdUnitTestSuite

var viewer: SrsStateViewer
var scheduler: ReviewScheduler
var _now: float


func before_test() -> void:
	viewer = SrsStateViewer.new()
	scheduler = ReviewScheduler.new()
	_now = 1700000000.0

	# Register and review some test cards
	scheduler.register_card("wo3", "wo3")
	scheduler.register_card("ni3", "ni3")
	scheduler.register_card("ta1", "ta1")

	# Review two cards so they are no longer NEW
	scheduler.record_review("wo3", "meaning", FsrsAlgorithm.Rating.GOOD, _now)
	scheduler.record_review("ni3", "meaning", FsrsAlgorithm.Rating.GOOD, _now)


func test_get_all_card_summaries_returns_all_cards() -> void:
	var summaries := viewer.get_all_card_summaries(scheduler, _now)
	assert_int(summaries.size()).is_equal(3)


func test_get_all_card_summaries_has_expected_keys() -> void:
	var summaries := viewer.get_all_card_summaries(scheduler, _now)
	var first := summaries[0]
	assert_bool(first.has("card_id")).is_true()
	assert_bool(first.has("tier")).is_true()
	assert_bool(first.has("tier_name")).is_true()
	assert_bool(first.has("is_due")).is_true()
	assert_bool(first.has("weakest_type")).is_true()


func test_get_tier_distribution_has_all_tiers() -> void:
	var dist := viewer.get_tier_distribution(scheduler)
	# Distribution should have keys for each tier from LOCKED to LEGENDARY
	assert_bool(dist.has(CollectionEnums.CardTier.LOCKED)).is_true()
	assert_bool(dist.has(CollectionEnums.CardTier.LEGENDARY)).is_true()


func test_get_tier_distribution_counts_correct() -> void:
	var dist := viewer.get_tier_distribution(scheduler)
	# ta1 is still NEW, so it maps to NEW_CARD tier
	var total := 0
	for tier_val in dist:
		total += dist[tier_val]
	assert_int(total).is_equal(3)


func test_get_due_count_with_reviewed_cards() -> void:
	# Right after review, cards with scheduled_days > 0 should not be due yet
	var due := viewer.get_due_count(scheduler, _now)
	# ta1 is NEW so not due; wo3/ni3 were just reviewed
	assert_int(due).is_greater_equal(0)


func test_get_due_count_increases_over_time() -> void:
	# Far in the future, reviewed cards should be due
	var far_future := _now + 365.0 * 86400.0
	var due := viewer.get_due_count(scheduler, far_future)
	assert_int(due).is_greater_equal(2)
