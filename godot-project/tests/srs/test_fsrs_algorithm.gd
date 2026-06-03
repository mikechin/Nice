## Tests for FsrsAlgorithm — core FSRS scheduling math.
extends GdUnitTestSuite

var fsrs: FsrsAlgorithm


func before_test() -> void:
	fsrs = FsrsAlgorithm.new()


# -- init_card --

func test_init_card_returns_new_state() -> void:
	var card := fsrs.init_card()
	assert_int(card["state"]).is_equal(FsrsAlgorithm.State.NEW)
	assert_float(card["stability"]).is_equal(0.0)
	assert_float(card["difficulty"]).is_equal(0.0)
	assert_int(card["reps"]).is_equal(0)
	assert_int(card["lapses"]).is_equal(0)
	assert_int(card["scheduled_days"]).is_equal(0)
	assert_int(card["elapsed_days"]).is_equal(0)
	assert_float(card["last_review"]).is_equal(0.0)


# -- init_stability --

func test_init_stability_again_is_positive() -> void:
	var s := fsrs.init_stability(FsrsAlgorithm.Rating.AGAIN)
	assert_float(s).is_greater(0.0)


func test_init_stability_hard_is_positive() -> void:
	var s := fsrs.init_stability(FsrsAlgorithm.Rating.HARD)
	assert_float(s).is_greater(0.0)


func test_init_stability_good_is_positive() -> void:
	var s := fsrs.init_stability(FsrsAlgorithm.Rating.GOOD)
	assert_float(s).is_greater(0.0)


func test_init_stability_easy_is_positive() -> void:
	var s := fsrs.init_stability(FsrsAlgorithm.Rating.EASY)
	assert_float(s).is_greater(0.0)


func test_init_stability_increases_with_rating() -> void:
	var s_again := fsrs.init_stability(FsrsAlgorithm.Rating.AGAIN)
	var s_hard := fsrs.init_stability(FsrsAlgorithm.Rating.HARD)
	var s_good := fsrs.init_stability(FsrsAlgorithm.Rating.GOOD)
	var s_easy := fsrs.init_stability(FsrsAlgorithm.Rating.EASY)
	assert_float(s_hard).is_greater(s_again)
	assert_float(s_good).is_greater(s_hard)
	assert_float(s_easy).is_greater(s_good)


# -- init_difficulty --

func test_init_difficulty_again_in_range() -> void:
	var d := fsrs.init_difficulty(FsrsAlgorithm.Rating.AGAIN)
	assert_float(d).is_greater_equal(1.0)
	assert_float(d).is_less_equal(10.0)


func test_init_difficulty_hard_in_range() -> void:
	var d := fsrs.init_difficulty(FsrsAlgorithm.Rating.HARD)
	assert_float(d).is_greater_equal(1.0)
	assert_float(d).is_less_equal(10.0)


func test_init_difficulty_good_in_range() -> void:
	var d := fsrs.init_difficulty(FsrsAlgorithm.Rating.GOOD)
	assert_float(d).is_greater_equal(1.0)
	assert_float(d).is_less_equal(10.0)


func test_init_difficulty_easy_in_range() -> void:
	var d := fsrs.init_difficulty(FsrsAlgorithm.Rating.EASY)
	assert_float(d).is_greater_equal(1.0)
	assert_float(d).is_less_equal(10.0)


func test_init_difficulty_decreases_with_rating() -> void:
	var d_again := fsrs.init_difficulty(FsrsAlgorithm.Rating.AGAIN)
	var d_easy := fsrs.init_difficulty(FsrsAlgorithm.Rating.EASY)
	# Higher rating -> lower initial difficulty
	assert_float(d_again).is_greater(d_easy)


# -- forgetting_curve --

func test_forgetting_curve_at_zero_is_one() -> void:
	var r := fsrs.forgetting_curve(0.0, 5.0)
	assert_float(r).is_equal_approx(1.0, 0.001)


func test_forgetting_curve_decreases_over_time() -> void:
	var r1 := fsrs.forgetting_curve(1.0, 5.0)
	var r10 := fsrs.forgetting_curve(10.0, 5.0)
	var r30 := fsrs.forgetting_curve(30.0, 5.0)
	assert_float(r1).is_less(1.0)
	assert_float(r10).is_less(r1)
	assert_float(r30).is_less(r10)


func test_forgetting_curve_always_positive() -> void:
	var r := fsrs.forgetting_curve(365.0, 1.0)
	assert_float(r).is_greater(0.0)


func test_forgetting_curve_higher_stability_slower_decay() -> void:
	var r_low := fsrs.forgetting_curve(10.0, 2.0)
	var r_high := fsrs.forgetting_curve(10.0, 50.0)
	assert_float(r_high).is_greater(r_low)


func test_forgetting_curve_zero_stability_returns_zero() -> void:
	var r := fsrs.forgetting_curve(5.0, 0.0)
	assert_float(r).is_equal(0.0)


# -- review: new card --

func test_review_new_card_good() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var result := fsrs.review(card, FsrsAlgorithm.Rating.GOOD, now)
	assert_int(result["state"]).is_equal(FsrsAlgorithm.State.REVIEW)
	assert_float(result["stability"]).is_greater(0.0)
	assert_float(result["difficulty"]).is_greater_equal(1.0)
	assert_int(result["reps"]).is_equal(1)
	assert_int(result["scheduled_days"]).is_greater_equal(1)


func test_review_new_card_again() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var result := fsrs.review(card, FsrsAlgorithm.Rating.AGAIN, now)
	assert_int(result["state"]).is_equal(FsrsAlgorithm.State.LEARNING)
	assert_int(result["scheduled_days"]).is_equal(0)
	assert_float(result["stability"]).is_greater(0.0)


func test_review_new_card_easy_gives_longest_interval() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var good_result := fsrs.review(card, FsrsAlgorithm.Rating.GOOD, now)
	var easy_result := fsrs.review(card, FsrsAlgorithm.Rating.EASY, now)
	assert_int(easy_result["scheduled_days"]).is_greater_equal(good_result["scheduled_days"])


# -- review: stability changes --

func test_review_increases_stability() -> void:
	# Review a new card with GOOD to get a review state, then review again
	var card := fsrs.init_card()
	var now := 1700000000.0
	var after_first := fsrs.review(card, FsrsAlgorithm.Rating.GOOD, now)
	# Advance time by the scheduled interval
	var later: float = now + float(after_first["scheduled_days"]) * 86400.0
	var after_second := fsrs.review(after_first, FsrsAlgorithm.Rating.GOOD, later)
	assert_float(after_second["stability"]).is_greater(after_first["stability"])


func test_review_again_decreases_stability() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var after_first := fsrs.review(card, FsrsAlgorithm.Rating.GOOD, now)
	# Advance time so it is a real recall test
	var later: float = now + float(after_first["scheduled_days"]) * 86400.0
	var after_fail := fsrs.review(after_first, FsrsAlgorithm.Rating.AGAIN, later)
	assert_float(after_fail["stability"]).is_less(after_first["stability"])
	assert_int(after_fail["state"]).is_equal(FsrsAlgorithm.State.RELEARNING)


func test_review_again_increments_lapses() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var after_first := fsrs.review(card, FsrsAlgorithm.Rating.GOOD, now)
	var later: float = now + float(after_first["scheduled_days"]) * 86400.0
	var after_fail := fsrs.review(after_first, FsrsAlgorithm.Rating.AGAIN, later)
	assert_int(after_fail["lapses"]).is_equal(1)


# -- next_interval --

func test_next_interval_positive() -> void:
	var interval := fsrs.next_interval(5.0)
	assert_int(interval).is_greater_equal(1)


func test_next_interval_increases_with_stability() -> void:
	var i_low := fsrs.next_interval(2.0)
	var i_high := fsrs.next_interval(50.0)
	assert_int(i_high).is_greater(i_low)


func test_next_interval_respects_maximum() -> void:
	var interval := fsrs.next_interval(100000.0)
	assert_int(interval).is_less_equal(fsrs.maximum_interval)


func test_next_interval_tiny_stability_is_one() -> void:
	var interval := fsrs.next_interval(FsrsAlgorithm.S_MIN * 0.1)
	assert_int(interval).is_equal(1)


# -- repeat --

func test_repeat_returns_all_ratings() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var results := fsrs.repeat(card, now)
	assert_int(results.size()).is_equal(4)
	assert_bool(results.has(FsrsAlgorithm.Rating.AGAIN)).is_true()
	assert_bool(results.has(FsrsAlgorithm.Rating.HARD)).is_true()
	assert_bool(results.has(FsrsAlgorithm.Rating.GOOD)).is_true()
	assert_bool(results.has(FsrsAlgorithm.Rating.EASY)).is_true()


func test_repeat_each_result_has_reps_one() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var results := fsrs.repeat(card, now)
	for rating in results:
		assert_int(results[rating]["reps"]).is_equal(1)


# -- get_retrievability --

func test_get_retrievability_new_card_is_zero() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var r := fsrs.get_retrievability(card, now)
	assert_float(r).is_equal(0.0)


func test_get_retrievability_reviewed_card_positive() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var after := fsrs.review(card, FsrsAlgorithm.Rating.GOOD, now)
	var r := fsrs.get_retrievability(after, now + 86400.0)
	assert_float(r).is_greater(0.0)
	assert_float(r).is_less_equal(1.0)


# -- maximum_interval respected through review --

func test_maximum_interval_respected() -> void:
	var card := fsrs.init_card()
	var now := 1700000000.0
	var result := fsrs.review(card, FsrsAlgorithm.Rating.EASY, now)
	assert_int(result["scheduled_days"]).is_less_equal(fsrs.maximum_interval)


# -- difficulty mean reversion target --

func test_difficulty_mean_reverts_toward_easy_not_good() -> void:
	# ts-fsrs reverts difficulty toward D_0(Easy), not D_0(Good). A GOOD answer
	# carries no difficulty delta, so iterating next_difficulty exposes the
	# reversion fixed point — it must settle at the EASY baseline.
	var d0_easy := fsrs.init_difficulty(FsrsAlgorithm.Rating.EASY)
	var d0_good := fsrs.init_difficulty(FsrsAlgorithm.Rating.GOOD)
	assert_float(d0_easy).is_less(d0_good)   # EASY is the lower target
	var d := 9.0
	for _i in 30000:
		d = fsrs.next_difficulty(d, FsrsAlgorithm.Rating.GOOD)
	assert_float(d).is_equal_approx(d0_easy, 0.05)
	assert_float(absf(d - d0_easy)).is_less(absf(d - d0_good))


# -- interval fuzz --

func test_apply_fuzz_is_noop_when_disabled() -> void:
	fsrs.enable_fuzz = false
	assert_int(fsrs.apply_fuzz(50)).is_equal(50)


func test_apply_fuzz_leaves_short_intervals_exact() -> void:
	fsrs.enable_fuzz = true
	# Under 3 days there's nothing meaningful to spread.
	assert_int(fsrs.apply_fuzz(1)).is_equal(1)
	assert_int(fsrs.apply_fuzz(2)).is_equal(2)


func test_apply_fuzz_stays_within_band() -> void:
	fsrs.enable_fuzz = true
	# For ivl=100: delta = 1 + .15*(7-2.5) + .1*(20-7) + .05*(100-20) = 6.975,
	# so the fuzzed value lands in [93, 107].
	for _i in 200:
		var f := fsrs.apply_fuzz(100)
		assert_int(f).is_greater_equal(93)
		assert_int(f).is_less_equal(107)


func test_apply_fuzz_respects_maximum_interval() -> void:
	fsrs.enable_fuzz = true
	fsrs.maximum_interval = 100
	for _i in 50:
		assert_int(fsrs.apply_fuzz(100)).is_less_equal(100)


func test_fuzz_spreads_identical_intervals() -> void:
	# The point of fuzz: a batch of cards with the same interval shouldn't all
	# fall due on one day. Fuzzing the same interval yields more than one value.
	fsrs.enable_fuzz = true
	var seen := {}
	for _i in 100:
		seen[fsrs.apply_fuzz(60)] = true
	assert_int(seen.size()).is_greater(1)


func test_review_intervals_are_deterministic_without_fuzz() -> void:
	# Fuzz is off by default, so the scheduled interval is the exact base interval.
	var card := fsrs.init_card()
	var now := 1700000000.0
	var a := fsrs.review(card, FsrsAlgorithm.Rating.EASY, now)
	var b := fsrs.review(card, FsrsAlgorithm.Rating.EASY, now)
	assert_int(a["scheduled_days"]).is_equal(b["scheduled_days"])
