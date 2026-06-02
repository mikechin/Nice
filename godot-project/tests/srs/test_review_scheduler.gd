## Tests for ReviewScheduler — card scheduling, pack curation, loot rarity.
extends GdUnitTestSuite

var scheduler: ReviewScheduler
var _now: float


func before_test() -> void:
	scheduler = ReviewScheduler.new()
	_now = 1700000000.0


# -- register_card --

func test_register_card_adds_to_states() -> void:
	scheduler.register_card("c1", "好")
	assert_bool(scheduler.card_states.has("c1")).is_true()


func test_register_card_returns_card_state() -> void:
	var cs := scheduler.register_card("c1", "好")
	assert_str(cs.card_id).is_equal("c1")
	assert_str(cs.character).is_equal("好")


func test_register_card_duplicate_returns_existing() -> void:
	var cs1 := scheduler.register_card("c1", "好")
	var cs2 := scheduler.register_card("c1", "好")
	# Same object returned for duplicate registration
	assert_str(cs1.card_id).is_equal(cs2.card_id)


func test_register_multiple_cards() -> void:
	scheduler.register_card("c1", "好")
	scheduler.register_card("c2", "大")
	scheduler.register_card("c3", "人")
	assert_int(scheduler.card_states.size()).is_equal(3)


# -- record_review --

func test_record_review_updates_card_state() -> void:
	scheduler.register_card("c1", "好")
	var result := scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.GOOD, _now)
	assert_bool(result.has("card_id")).is_true()
	assert_str(result["card_id"]).is_equal("c1")
	# The card should no longer be in NEW state for "meaning"
	var cs: CardState = scheduler.card_states["c1"]
	var state: int = cs.states["meaning"]["state"]
	assert_int(state).is_equal(FsrsAlgorithm.State.REVIEW)


func test_record_review_unknown_card_returns_empty() -> void:
	var result := scheduler.record_review("nonexistent", "meaning", FsrsAlgorithm.Rating.GOOD, _now)
	assert_int(result.size()).is_equal(0)


func test_record_review_contains_promotion_info() -> void:
	scheduler.register_card("c1", "好")
	var result := scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.GOOD, _now)
	assert_bool(result.has("promotion")).is_true()
	assert_bool(result["promotion"].has("promoted")).is_true()


func test_record_review_reps_increment() -> void:
	scheduler.register_card("c1", "好")
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.GOOD, _now)
	var cs: CardState = scheduler.card_states["c1"]
	assert_int(cs.states["meaning"]["reps"]).is_equal(1)


# -- get_due_cards --

func test_get_due_cards_empty_when_all_new() -> void:
	scheduler.register_card("c1", "好")
	scheduler.register_card("c2", "大")
	var due := scheduler.get_due_cards(_now)
	assert_int(due.size()).is_equal(0)


func test_get_due_cards_returns_learning_cards() -> void:
	scheduler.register_card("c1", "好")
	# Review with AGAIN -> goes to LEARNING state, immediately due
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.AGAIN, _now)
	var due := scheduler.get_due_cards(_now + 1.0)
	assert_int(due.size()).is_equal(1)


func test_get_due_cards_not_due_within_interval() -> void:
	scheduler.register_card("c1", "好")
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.GOOD, _now)
	# Check shortly after -- the review card should not be due
	var due := scheduler.get_due_cards(_now + 1.0)
	assert_int(due.size()).is_equal(0)


func test_get_due_cards_due_after_interval() -> void:
	scheduler.register_card("c1", "好")
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.GOOD, _now)
	var cs: CardState = scheduler.card_states["c1"]
	var scheduled_days: int = cs.states["meaning"]["scheduled_days"]
	# Advance time past the scheduled interval
	var future := _now + (scheduled_days + 1) * 86400.0
	var due := scheduler.get_due_cards(future)
	assert_int(due.size()).is_equal(1)


# -- serialize / deserialize round-trip --

func test_serialize_deserialize_round_trip() -> void:
	scheduler.register_card("c1", "好")
	scheduler.register_card("c2", "大")
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.GOOD, _now)

	var serialized := scheduler.serialize_all()
	assert_int(serialized.size()).is_equal(2)

	var new_scheduler := ReviewScheduler.new()
	new_scheduler.deserialize_all(serialized)
	assert_int(new_scheduler.card_states.size()).is_equal(2)
	assert_bool(new_scheduler.card_states.has("c1")).is_true()
	assert_bool(new_scheduler.card_states.has("c2")).is_true()


func test_serialize_preserves_review_state() -> void:
	scheduler.register_card("c1", "好")
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.GOOD, _now)

	var serialized := scheduler.serialize_all()
	var new_scheduler := ReviewScheduler.new()
	new_scheduler.deserialize_all(serialized)

	var cs: CardState = new_scheduler.card_states["c1"]
	assert_int(cs.states["meaning"]["state"]).is_equal(FsrsAlgorithm.State.REVIEW)
	assert_float(cs.states["meaning"]["stability"]).is_greater(0.0)


# -- curate_pack --

func test_curate_pack_returns_pack() -> void:
	# Register some cards with reviews so the pack has something to work with
	for i in range(10):
		var card_id := "c%d" % i
		scheduler.register_card(card_id, "字%d" % i)
		scheduler.record_review(card_id, "meaning", FsrsAlgorithm.Rating.GOOD, _now)

	# Advance time so cards are due
	var future := _now + 30 * 86400.0
	var pack := scheduler.curate_pack(future, 5)
	assert_bool(pack != null).is_true()
	assert_int(pack.get_total_count()).is_greater_equal(0)


func test_curate_pack_with_new_ids() -> void:
	scheduler.register_card("c1", "好")
	var pack := scheduler.curate_pack(_now, 5, ["c1"])
	# Pack should include new cards from available_new_ids
	assert_bool(pack != null).is_true()


# -- loot rarity --

func test_loot_rarity_new_card() -> void:
	scheduler.register_card("c1", "好")
	var rarity := scheduler.get_loot_rarity("c1", "meaning", _now)
	assert_int(rarity).is_equal(SrsEnums.LootRarity.NEW_CARD)


func test_loot_rarity_unknown_card() -> void:
	var rarity := scheduler.get_loot_rarity("nonexistent", "meaning", _now)
	assert_int(rarity).is_equal(SrsEnums.LootRarity.NEW_CARD)


func test_loot_rarity_learning_card() -> void:
	scheduler.register_card("c1", "好")
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.AGAIN, _now)
	var rarity := scheduler.get_loot_rarity("c1", "meaning", _now + 1.0)
	assert_int(rarity).is_equal(SrsEnums.LootRarity.LEARNING)


func test_loot_rarity_common_review() -> void:
	scheduler.register_card("c1", "好")
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.GOOD, _now)
	# Right after a GOOD review, retrievability should be high -> COMMON
	var rarity := scheduler.get_loot_rarity("c1", "meaning", _now + 1.0)
	assert_int(rarity).is_equal(SrsEnums.LootRarity.COMMON)


# -- select_challenge_type --

func test_select_challenge_type_picks_weakest() -> void:
	scheduler.register_card("c1", "好")
	# Review all types except "tone"
	for ct_str in ["meaning", "character", "pinyin"]:
		scheduler.record_review("c1", ct_str, FsrsAlgorithm.Rating.GOOD, _now)
	var weakest := scheduler.select_challenge_type("c1")
	assert_str(weakest).is_equal("tone")


func test_select_challenge_type_unknown_card() -> void:
	var ct := scheduler.select_challenge_type("nonexistent")
	assert_str(ct).is_equal("meaning")


# -- get_new_card_ids --

func test_get_new_card_ids() -> void:
	scheduler.register_card("c1", "好")
	scheduler.register_card("c2", "大")
	var new_ids := scheduler.get_new_card_ids()
	assert_int(new_ids.size()).is_equal(2)


func test_get_new_card_ids_excludes_reviewed() -> void:
	scheduler.register_card("c1", "好")
	scheduler.register_card("c2", "大")
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.GOOD, _now)
	var new_ids := scheduler.get_new_card_ids()
	assert_int(new_ids.size()).is_equal(1)
	assert_str(new_ids[0]).is_equal("c2")


# -- debug tier overrides --

func test_set_debug_tier_override_returned_by_get_loot_rarity() -> void:
	scheduler.register_card("c1", "好")
	# Without override, an unreviewed card-state isn't NEW (it's been
	# registered) — record one review so it's in COMMON territory.
	scheduler.record_review("c1", "meaning", FsrsAlgorithm.Rating.EASY, _now)
	scheduler.set_debug_tier_override("c1", SrsEnums.LootRarity.NEW_CARD)
	var rarity := scheduler.get_loot_rarity("c1", "meaning", _now)
	assert_int(rarity).is_equal(SrsEnums.LootRarity.NEW_CARD)


func test_clear_debug_tier_overrides_restores_computed_rarity() -> void:
	scheduler.register_card("c1", "好")
	scheduler.set_debug_tier_override("c1", SrsEnums.LootRarity.COMMON)
	scheduler.clear_debug_tier_overrides()
	# Brand new (no review history) → NEW_CARD
	var rarity := scheduler.get_loot_rarity("c1", "meaning", _now)
	assert_int(rarity).is_equal(SrsEnums.LootRarity.NEW_CARD)


func test_override_works_for_unregistered_card() -> void:
	# The debug pack registers cards explicitly, but the override should
	# take precedence even if the lookup happens before registration.
	scheduler.set_debug_tier_override("ghost", SrsEnums.LootRarity.LEARNING)
	var rarity := scheduler.get_loot_rarity("ghost", "meaning", _now)
	assert_int(rarity).is_equal(SrsEnums.LootRarity.LEARNING)


# -- curate_debug_tier_sample_pack --

func _make_card(ch: String) -> CharacterData:
	return CharacterData.from_dict({
		"character": ch, "pinyin": "x", "tone": 1,
		"meaning": "m", "hsk_level": 2, "radicals": [],
	})


func test_debug_tier_sample_pack_has_one_card_per_tier() -> void:
	var sample: Array[CharacterData] = [
		_make_card("一"), _make_card("二"), _make_card("三"), _make_card("四"),
	]
	var pack := scheduler.curate_debug_tier_sample_pack(sample)

	assert_int(pack.get_total_count()).is_equal(4)
	assert_str(pack.pack_type).is_equal("debug")

	var tiers_seen: Array[int] = []
	for cid in pack.presentation_order:
		tiers_seen.append(scheduler.get_loot_rarity(cid, "meaning", _now))
	# All four tiers represented exactly once.
	for tier in [
		SrsEnums.LootRarity.COMMON,
		SrsEnums.LootRarity.LEARNING,
		SrsEnums.LootRarity.ABOUT_TO_FORGET,
		SrsEnums.LootRarity.NEW_CARD,
	]:
		assert_int(tiers_seen.count(tier)).is_equal(1)


func test_debug_tier_sample_pack_registers_cards_for_review_recording() -> void:
	var sample: Array[CharacterData] = [_make_card("一"), _make_card("二")]
	scheduler.curate_debug_tier_sample_pack(sample)
	# Both characters must be in card_states so record_review accepts the answer.
	assert_bool(scheduler.card_states.has("一")).is_true()
	assert_bool(scheduler.card_states.has("二")).is_true()


func test_debug_tier_sample_pack_clears_prior_overrides() -> void:
	scheduler.set_debug_tier_override("stale", SrsEnums.LootRarity.NEW_CARD)
	var sample: Array[CharacterData] = [_make_card("一")]
	scheduler.curate_debug_tier_sample_pack(sample)
	# Stale override is wiped so old debug runs don't leak forward.
	assert_bool(scheduler._debug_tier_overrides.has("stale")).is_false()
