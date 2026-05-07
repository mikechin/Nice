## Tests for BonusRoundManager — chain construction, miss-stops-chain,
## boost accumulation.
extends GdUnitTestSuite

var _mgr: BonusRoundManager


func before_test() -> void:
	_mgr = BonusRoundManager.new()


# -- chain construction --

func test_start_chains_three_non_primary_stages() -> void:
	_mgr.start("好", "meaning")
	# Primary was meaning, so chain should hold the other 3.
	assert_int(_mgr.get_remaining_count()).is_equal(3)
	assert_bool(_mgr.is_active).is_true()


func test_start_excludes_primary_stage() -> void:
	_mgr.start("好", "tone")
	# Walk the chain and confirm TONE never appears.
	var seen: Array[int] = []
	while not _mgr.is_complete():
		var stage := _mgr.next_stage()
		if stage < 0:
			break
		seen.append(stage)
		_mgr.record_stage_result(stage, true)
	assert_bool(BonusEnums.BonusStage.TONE in seen).is_false()
	assert_int(seen.size()).is_equal(3)


func test_start_resets_state_between_cards() -> void:
	# First card: stop after one wrong stage.
	_mgr.start("好", "meaning")
	var s1 := _mgr.next_stage()
	_mgr.record_stage_result(s1, false)
	assert_int(_mgr.get_total_boost()).is_equal(1 * 0)  # zero boosts banked
	assert_bool(_mgr.was_stopped_early()).is_true()

	# Second card on the same manager: state should be fresh.
	_mgr.start("大", "pinyin")
	assert_bool(_mgr.is_active).is_true()
	assert_bool(_mgr.was_stopped_early()).is_false()
	assert_int(_mgr.get_total_boost()).is_equal(0)
	assert_int(_mgr.get_remaining_count()).is_equal(3)


# -- correct chain --

func test_three_correct_stages_yield_three_boosts() -> void:
	_mgr.start("好", "meaning")
	for i in 3:
		var stage := _mgr.next_stage()
		_mgr.record_stage_result(stage, true)
	assert_bool(_mgr.is_complete()).is_true()
	assert_bool(_mgr.was_stopped_early()).is_false()
	assert_int(_mgr.get_total_boost()).is_equal(3)
	assert_int(_mgr.get_boosts().size()).is_equal(3)


func test_completed_stages_recorded_in_order() -> void:
	_mgr.start("好", "meaning")
	var ordered: Array[int] = []
	while not _mgr.is_complete():
		var stage := _mgr.next_stage()
		if stage < 0:
			break
		ordered.append(stage)
		_mgr.record_stage_result(stage, true)
	assert_array(_mgr.get_completed_stages()).is_equal(ordered)


# -- miss stops the chain --

func test_miss_after_one_correct_stops_chain() -> void:
	_mgr.start("好", "meaning")
	var s1 := _mgr.next_stage()
	assert_int(_mgr.record_stage_result(s1, true)).is_equal(BonusEnums.StageOutcome.CONTINUE)
	var s2 := _mgr.next_stage()
	assert_int(_mgr.record_stage_result(s2, false)).is_equal(BonusEnums.StageOutcome.STOP)
	assert_bool(_mgr.is_complete()).is_true()
	assert_bool(_mgr.was_stopped_early()).is_true()
	assert_int(_mgr.get_total_boost()).is_equal(1)


func test_immediate_miss_yields_zero_boost() -> void:
	_mgr.start("好", "meaning")
	var s := _mgr.next_stage()
	_mgr.record_stage_result(s, false)
	assert_int(_mgr.get_total_boost()).is_equal(0)
	assert_int(_mgr.get_boosts().size()).is_equal(0)
	assert_bool(_mgr.was_stopped_early()).is_true()


func test_record_after_complete_is_safe_noop() -> void:
	# Defensive: a stray result arriving after the round closed shouldn't
	# crash or revive the chain.
	_mgr.start("好", "meaning")
	for i in 3:
		_mgr.record_stage_result(_mgr.next_stage(), true)
	var outcome := _mgr.record_stage_result(BonusEnums.BonusStage.MEANING, true)
	assert_int(outcome).is_equal(BonusEnums.StageOutcome.STOP)


# -- peek_next_stage doesn't consume --

func test_peek_does_not_advance_chain() -> void:
	_mgr.start("好", "meaning")
	var peeked := _mgr.peek_next_stage()
	var consumed := _mgr.next_stage()
	assert_int(peeked).is_equal(consumed)
	assert_int(_mgr.get_remaining_count()).is_equal(2)


func test_peek_returns_minus_one_when_empty() -> void:
	_mgr.start("好", "meaning")
	for i in 3:
		_mgr.record_stage_result(_mgr.next_stage(), true)
	assert_int(_mgr.peek_next_stage()).is_equal(-1)
	assert_int(_mgr.next_stage()).is_equal(-1)


# -- boosts come from the bonus stage source --

func test_boosts_tagged_with_bonus_stage_source() -> void:
	_mgr.start("好", "meaning")
	_mgr.record_stage_result(_mgr.next_stage(), true)
	var boosts := _mgr.get_boosts()
	assert_int(boosts.size()).is_equal(1)
	assert_int(boosts[0].source).is_equal(PowerEnums.BoostSource.BONUS_STAGE)
	assert_int(boosts[0].amount).is_equal(BonusEnums.BOOST_PER_STAGE)
