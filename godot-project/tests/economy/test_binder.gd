## Tests for Binder — the permanent seen/dropped/best-PSA record. best-PSA only
## ever climbs (a forever trophy), and the record survives a save round-trip.
extends GdUnitTestSuite


func test_record_seen() -> void:
	var b := Binder.new()
	assert_bool(b.is_seen("好")).is_false()
	b.record_seen("好")
	assert_bool(b.is_seen("好")).is_true()
	assert_int(b.seen_count()).is_equal(1)


func test_record_drop_counts_and_marks_seen() -> void:
	var b := Binder.new()
	b.record_drop(CardInstance.create("好", EconomyEnums.Rarity.RARE))
	b.record_drop(CardInstance.create("好", EconomyEnums.Rarity.COMMON))
	assert_int(b.times_dropped("好")).is_equal(2)
	assert_bool(b.is_seen("好")).is_true()
	assert_int(b.dropped_count()).is_equal(1)


func test_best_psa_only_climbs() -> void:
	var b := Binder.new()
	var graded := CardInstance.create("学", EconomyEnums.Rarity.RARE)
	graded.grade = 8
	b.record_drop(graded)
	assert_int(b.best_psa("学")).is_equal(8)
	# A later raw or lower-graded drop never lowers the record.
	b.record_drop(CardInstance.create("学", EconomyEnums.Rarity.RARE))
	assert_int(b.best_psa("学")).is_equal(8)
	b.record_grade("学", 9)
	assert_int(b.best_psa("学")).is_equal(9)
	b.record_grade("学", 3)
	assert_int(b.best_psa("学")).is_equal(9)


func test_round_trip() -> void:
	var b := Binder.new()
	b.record_seen("a")
	var graded := CardInstance.create("b", EconomyEnums.Rarity.RARE)
	graded.grade = 7
	b.record_drop(graded)

	var restored := Binder.new()
	restored.load_from_dict(b.to_dict())
	assert_bool(restored.is_seen("a")).is_true()
	assert_int(restored.times_dropped("b")).is_equal(1)
	assert_int(restored.best_psa("b")).is_equal(7)
