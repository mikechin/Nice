## Tests for ChallengePresenter bonus-round wiring — drive the state
## machine via submit_answer, verify per-stage and terminal signals.
extends GdUnitTestSuite

var _presenter: ChallengePresenter
var _gen: AnswerGenerator
var _bonus: BonusRoundManager
var _card: CharacterData


func before_test() -> void:
	_presenter = auto_free(ChallengePresenter.new())
	_bonus = BonusRoundManager.new()

	# Tiny deterministic-ish DB so AnswerGenerator can fill 4 slots.
	var db := CharacterDatabase.new()
	var chars: Array[CharacterData] = [
		CharacterData.from_dict({
			"character": "好", "pinyin": "hǎo", "tone": 3,
			"meaning": "good", "hsk_level": 2, "radicals": ["女", "子"],
		}),
		CharacterData.from_dict({
			"character": "大", "pinyin": "dà", "tone": 4,
			"meaning": "big", "hsk_level": 2, "radicals": ["大"],
		}),
		CharacterData.from_dict({
			"character": "小", "pinyin": "xiǎo", "tone": 3,
			"meaning": "small", "hsk_level": 2, "radicals": ["小"],
		}),
		CharacterData.from_dict({
			"character": "人", "pinyin": "rén", "tone": 2,
			"meaning": "person", "hsk_level": 2, "radicals": ["人"],
		}),
	]
	db.load_from_array(chars)
	_gen = AnswerGenerator.new(db)
	_card = chars[0]


# -- helpers --

## Find a seed whose first randf() falls on the requested side of the
## trigger threshold. We probe a fresh RNG each iteration so the seed we
## return is identical to the one the presenter will use.
func _seed_for_trigger(should_trigger: bool) -> int:
	for s in range(1, 500):
		var probe := RandomNumberGenerator.new()
		probe.seed = s
		var hits := probe.randf() < BonusEnums.BONUS_TRIGGER_CHANCE
		if hits == should_trigger:
			return s
	fail("No seed in [1, 500) produced the requested trigger outcome")
	return -1


func _make_rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _submit_correct() -> void:
	var dir: String = _presenter.get_current_answers()["correct_direction"]
	_presenter.submit_answer(dir)


func _submit_wrong() -> void:
	var correct_dir: String = _presenter.get_current_answers()["correct_direction"]
	for d in ["up", "down", "left", "right"]:
		if d != correct_dir:
			_presenter.submit_answer(d)
			return


# -- ineligible loot rarity skips the bonus path entirely --

func test_common_loot_resolves_immediately_on_correct() -> void:
	_presenter.setup(_gen, null, null, _bonus, _make_rng(1))
	var resolved: Array[Dictionary] = []
	# Lambdas capture ints by value, so use a 1-element Array as a counter.
	var bonus_starts: Array[int] = [0]
	_presenter.card_resolved.connect(
		func(card_id: String, primary_correct: bool, base_power: int, boosts: Array) -> void:
			resolved.append({
				"card_id": card_id,
				"correct": primary_correct,
				"base_power": base_power,
				"boosts": boosts,
			})
	)
	_presenter.bonus_round_started.connect(func(_c: String) -> void: bonus_starts[0] += 1)

	_presenter.present_challenge(_card, "meaning", SrsEnums.LootRarity.COMMON)
	_submit_correct()

	assert_int(resolved.size()).is_equal(1)
	assert_str(resolved[0]["card_id"]).is_equal("好")
	assert_bool(resolved[0]["correct"]).is_true()
	assert_int(resolved[0]["boosts"].size()).is_equal(0)
	# COMMON loot rarity → weakest base power.
	assert_int(resolved[0]["base_power"]).is_equal(PowerEnums.BASE_POWER[SrsEnums.LootRarity.COMMON])
	assert_int(bonus_starts[0]).is_equal(0)


# -- wrong primary never triggers a bonus --

func test_wrong_primary_resolves_with_no_boosts() -> void:
	# Even seeded for a guaranteed trigger, a wrong primary must skip bonus.
	var seed_val := _seed_for_trigger(true)
	_presenter.setup(_gen, null, null, _bonus, _make_rng(seed_val))
	var resolved: Array[Dictionary] = []
	var bonus_starts: Array[int] = [0]
	_presenter.card_resolved.connect(
		func(_c: String, primary_correct: bool, _bp: int, boosts: Array) -> void:
			resolved.append({"correct": primary_correct, "boosts": boosts})
	)
	_presenter.bonus_round_started.connect(func(_c: String) -> void: bonus_starts[0] += 1)

	_presenter.present_challenge(_card, "meaning", SrsEnums.LootRarity.NEW_CARD)
	_submit_wrong()

	assert_int(resolved.size()).is_equal(1)
	assert_bool(resolved[0]["correct"]).is_false()
	assert_int(resolved[0]["boosts"].size()).is_equal(0)
	assert_int(bonus_starts[0]).is_equal(0)


# -- triggered bonus, full clean run --

func test_bonus_triggered_three_correct_stages_yields_three_boosts() -> void:
	var seed_val := _seed_for_trigger(true)
	_presenter.setup(_gen, null, null, _bonus, _make_rng(seed_val))

	var stages_started: Array[int] = []
	var resolved: Dictionary = {}
	var bonus_starts: Array[int] = [0]
	_presenter.bonus_round_started.connect(func(_c: String) -> void: bonus_starts[0] += 1)
	_presenter.bonus_stage_started.connect(
		func(_c: String, stage: int) -> void: stages_started.append(stage)
	)
	_presenter.card_resolved.connect(
		func(_c: String, primary_correct: bool, base_power: int, boosts: Array) -> void:
			resolved["correct"] = primary_correct
			resolved["base_power"] = base_power
			resolved["boosts"] = boosts
	)

	_presenter.present_challenge(_card, "meaning", SrsEnums.LootRarity.NEW_CARD)
	# Primary correct
	_submit_correct()
	# Three bonus stages, all correct
	for i in 3:
		_submit_correct()

	assert_int(bonus_starts[0]).is_equal(1)
	assert_int(stages_started.size()).is_equal(3)
	# The primary was MEANING, so the chain must skip MEANING.
	assert_bool(BonusEnums.BonusStage.MEANING in stages_started).is_false()
	assert_bool(resolved.get("correct", false)).is_true()
	var boosts: Array = resolved["boosts"]
	assert_int(boosts.size()).is_equal(3)
	# All three boosts come from the bonus-stage source.
	for b in boosts:
		assert_int(b.source).is_equal(PowerEnums.BoostSource.BONUS_STAGE)
		assert_int(b.amount).is_equal(BonusEnums.BOOST_PER_STAGE)


# -- triggered bonus, miss stops the chain mid-flight --

func test_bonus_miss_after_one_correct_stops_chain_with_one_boost() -> void:
	var seed_val := _seed_for_trigger(true)
	_presenter.setup(_gen, null, null, _bonus, _make_rng(seed_val))

	var resolved: Dictionary = {}
	_presenter.card_resolved.connect(
		func(_c: String, primary_correct: bool, _bp: int, boosts: Array) -> void:
			resolved["correct"] = primary_correct
			resolved["boosts"] = boosts
	)

	_presenter.present_challenge(_card, "tone", SrsEnums.LootRarity.NEW_CARD)
	_submit_correct()  # primary
	_submit_correct()  # bonus #1
	_submit_wrong()    # bonus #2 — chain stops here

	var boosts: Array = resolved["boosts"]
	assert_int(boosts.size()).is_equal(1)
	assert_bool(resolved["correct"]).is_true()
	# is_in_bonus_round must reset on terminal resolution.
	assert_bool(_presenter.is_in_bonus_round()).is_false()


# -- the trigger roll can simply miss --

func test_bonus_not_triggered_when_roll_above_threshold() -> void:
	var seed_val := _seed_for_trigger(false)
	_presenter.setup(_gen, null, null, _bonus, _make_rng(seed_val))

	var bonus_starts: Array[int] = [0]
	var resolved: Dictionary = {}
	_presenter.bonus_round_started.connect(func(_c: String) -> void: bonus_starts[0] += 1)
	_presenter.card_resolved.connect(
		func(_c: String, primary_correct: bool, _bp: int, boosts: Array) -> void:
			resolved["correct"] = primary_correct
			resolved["boosts"] = boosts
	)

	_presenter.present_challenge(_card, "meaning", SrsEnums.LootRarity.NEW_CARD)
	_submit_correct()

	assert_int(bonus_starts[0]).is_equal(0)
	assert_int(resolved["boosts"].size()).is_equal(0)
	assert_bool(resolved["correct"]).is_true()


# -- defensive: presenter without a bonus manager still resolves cleanly --

func test_no_bonus_manager_skips_bonus_path_safely() -> void:
	_presenter.setup(_gen, null, null, null, null)
	var resolved: Array[bool] = [false]
	_presenter.card_resolved.connect(func(_c: String, _ok: bool, _bp: int, _b: Array) -> void: resolved[0] = true)

	_presenter.present_challenge(_card, "meaning", SrsEnums.LootRarity.NEW_CARD)
	_submit_correct()
	assert_bool(resolved[0]).is_true()


# -- per-stage challenge_completed fires for every challenge in the chain --

func test_challenge_completed_fires_per_stage_in_full_chain() -> void:
	var seed_val := _seed_for_trigger(true)
	_presenter.setup(_gen, null, null, _bonus, _make_rng(seed_val))

	var completions: Array[String] = []
	_presenter.challenge_completed.connect(
		func(_card_id: String, ct: String, _ok: bool, _r: int) -> void:
			completions.append(ct)
	)

	_presenter.present_challenge(_card, "meaning", SrsEnums.LootRarity.NEW_CARD)
	_submit_correct()
	for i in 3:
		_submit_correct()

	# 1 primary + 3 bonus stages
	assert_int(completions.size()).is_equal(4)
	assert_str(completions[0]).is_equal("meaning")
	# Bonus stages cover the other three types in some order.
	var bonus_set := completions.slice(1)
	for ct in ["character", "pinyin", "tone"]:
		assert_bool(ct in bonus_set).is_true()
