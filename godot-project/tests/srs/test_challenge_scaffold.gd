## Tests for ChallengeScaffold — format-by-strength selection. New material is
## taught, weak material is recognized (2 options), strong material is recalled
## (4 options).
extends GdUnitTestSuite


func test_new_card_is_taught() -> void:
	# Card's first contact → teach, regardless of (zero) facet stability.
	assert_int(ChallengeScaffold.format_for(true, 0.0)).is_equal(ChallengeScaffold.Format.TEACH)


func test_weak_facet_is_recognized() -> void:
	assert_int(ChallengeScaffold.format_for(false, 2.0)).is_equal(ChallengeScaffold.Format.RECOGNIZE)


func test_strong_facet_is_recalled() -> void:
	assert_int(ChallengeScaffold.format_for(false, 50.0)).is_equal(ChallengeScaffold.Format.RECALL)


func test_recall_threshold_is_inclusive() -> void:
	assert_int(ChallengeScaffold.format_for(false, ChallengeScaffold.RECALL_STABILITY)) \
		.is_equal(ChallengeScaffold.Format.RECALL)
	assert_int(ChallengeScaffold.format_for(false, ChallengeScaffold.RECALL_STABILITY - 0.1)) \
		.is_equal(ChallengeScaffold.Format.RECOGNIZE)
