## Tests for CraftSystem — the town grading craft. Verifies the locked two-cap
## band (rarity ceiling × mastery reach), connection band-loading, ingredient
## consumption + fee, the "safe within band" guarantee, and that every rejection
## path mutates nothing. rng is seeded for deterministic grades.
extends GdUnitTestSuite

const HIGH_MASTERY := 200.0   # → mastery_cap 10
const NO_MASTERY := 0.0       # → mastery_cap 4

var _inv: Inventory
var _wallet: Wallet
var _binder: Binder
var _db: CharacterDatabase
var _craft: CraftSystem


func before_test() -> void:
	_inv = Inventory.new()
	_wallet = Wallet.new()
	_binder = Binder.new()
	_db = CharacterDatabase.new()
	_db.load_from_array(_family_data())
	_craft = CraftSystem.new(_inv, _wallet, _binder, _db)
	_craft.rng.seed = 12345


func _cd(character: String, pinyin: String, tone: int, radicals: Array, components: Array) -> CharacterData:
	return CharacterData.from_dict({
		"character": character, "pinyin": pinyin, "tone": tone,
		"radicals": radicals, "components": components,
	})


func _family_data() -> Array[CharacterData]:
	var rows: Array[CharacterData] = []
	# 青 phonetic series
	rows.append(_cd("请", "qǐng", 3, ["讠"], ["讠", "青"]))
	rows.append(_cd("清", "qīng", 1, ["氵"], ["氵", "青"]))
	rows.append(_cd("晴", "qíng", 2, ["日"], ["日", "青"]))
	rows.append(_cd("情", "qíng", 2, ["忄"], ["忄", "青"]))
	# unrelated singletons (for the invalid-set test)
	rows.append(_cd("好", "hǎo", 3, ["女"], ["女", "子"]))
	rows.append(_cd("学", "xué", 2, ["子"], ["子"]))
	rows.append(_cd("大", "dà", 4, [], []))
	return rows


## Add a raw instance to the bench, return its minted id.
func _add(card_id: String, rarity: int = EconomyEnums.Rarity.RARE) -> String:
	return _inv.add(CardInstance.create(card_id, rarity)).id


## A valid phonetic craft: target 请 + 清/晴/情 ingredients.
func _phonetic_setup(target_rarity: int = EconomyEnums.Rarity.RARE) -> Dictionary:
	var target_id := _add("请", target_rarity)
	var ings := [_add("清"), _add("晴"), _add("情")]
	return { "target": target_id, "ings": ings }


func test_phonetic_craft_grades_high_within_band() -> void:
	_wallet.add(100)
	var s := _phonetic_setup()
	var res := _craft.craft(s["target"], s["ings"], HIGH_MASTERY)
	assert_bool(res["ok"]).is_true()
	assert_int(res["axis"]).is_equal(ConnectionSet.Axis.PHONETIC)
	# Rare rarity (cap 10) × deep mastery (cap 10) → ceiling 10; phonetic loads top.
	assert_int(res["grade"]).is_between(8, 10)


func test_craft_consumes_ingredients_and_fee_and_grades_target() -> void:
	_wallet.add(100)
	var s := _phonetic_setup()
	var res := _craft.craft(s["target"], s["ings"], HIGH_MASTERY)
	assert_int(_inv.size()).is_equal(1)                       # 3 ingredients consumed, target remains
	var target := _inv.get_instance(s["target"])
	assert_bool(target.is_raw()).is_false()
	assert_int(target.grade).is_equal(res["grade"])
	assert_int(_wallet.shards).is_equal(100 - CraftSystem.CRAFT_FEE)
	assert_int(_binder.best_psa("请")).is_equal(res["grade"])  # binder records the best forever


func test_mastery_caps_the_grade_even_on_a_rare_instance() -> void:
	# Rare instance (rarity cap 10) but zero mastery (cap 4) → ceiling 4.
	_wallet.add(100)
	var s := _phonetic_setup(EconomyEnums.Rarity.RARE)
	var res := _craft.craft(s["target"], s["ings"], NO_MASTERY)
	assert_bool(res["ok"]).is_true()
	assert_int(res["grade"]).is_between(GradeBand.MIN_PSA, 4)   # mastery-capped


func test_rarity_caps_the_grade_even_with_deep_mastery() -> void:
	# Common instance (rarity cap 8) with deep mastery (cap 10) → ceiling 8.
	_wallet.add(100)
	var s := _phonetic_setup(EconomyEnums.Rarity.COMMON)
	var res := _craft.craft(s["target"], s["ings"], HIGH_MASTERY)
	assert_bool(res["ok"]).is_true()
	assert_int(res["grade"]).is_less_equal(8)                  # rarity-capped, never PSA 10


func test_invalid_connection_rejected_and_nothing_mutated() -> void:
	_wallet.add(100)
	var target := _add("请")
	var ings := [_add("好"), _add("学"), _add("大")]  # no common axis with 请
	var res := _craft.craft(target, ings, HIGH_MASTERY)
	assert_bool(res["ok"]).is_false()
	assert_int(_inv.size()).is_equal(4)                        # nothing consumed
	assert_int(_wallet.shards).is_equal(100)                   # fee not charged
	assert_bool(_inv.get_instance(target).is_raw()).is_true()  # target untouched


func test_cannot_afford_rejected_and_nothing_mutated() -> void:
	# Wallet empty — valid set but no shards for the fee.
	var s := _phonetic_setup()
	var res := _craft.craft(s["target"], s["ings"], HIGH_MASTERY)
	assert_bool(res["ok"]).is_false()
	assert_str(res["reason"]).contains("shards")
	assert_int(_inv.size()).is_equal(4)                        # ingredients NOT consumed
	assert_bool(_inv.get_instance(s["target"]).is_raw()).is_true()


func test_cannot_regrade_an_already_graded_target() -> void:
	_wallet.add(100)
	var s := _phonetic_setup()
	_inv.get_instance(s["target"]).grade = 5                   # pretend already graded
	var res := _craft.craft(s["target"], s["ings"], HIGH_MASTERY)
	assert_bool(res["ok"]).is_false()
	assert_str(res["reason"]).contains("already graded")


func test_ingredients_must_be_distinct_and_not_the_target() -> void:
	_wallet.add(100)
	var s := _phonetic_setup()
	var dup := [s["ings"][0], s["ings"][0], s["ings"][1]]      # a repeated ingredient
	assert_bool(_craft.craft(s["target"], dup, HIGH_MASTERY)["ok"]).is_false()
	var with_target := [s["target"], s["ings"][0], s["ings"][1]]
	assert_bool(_craft.craft(s["target"], with_target, HIGH_MASTERY)["ok"]).is_false()


func test_emits_instance_graded_signal() -> void:
	_wallet.add(100)
	var s := _phonetic_setup()
	var captured := []
	SignalBus.instance_graded.connect(func(inst, grade): captured.append(grade))
	var res := _craft.craft(s["target"], s["ings"], HIGH_MASTERY)
	assert_int(captured.size()).is_equal(1)
	assert_int(captured[0]).is_equal(res["grade"])


func test_preview_reports_band_without_mutating() -> void:
	_wallet.add(100)
	var s := _phonetic_setup()
	var p := _craft.preview(s["target"], s["ings"], HIGH_MASTERY)
	assert_bool(p["valid"]).is_true()
	assert_int(p["axis"]).is_equal(ConnectionSet.Axis.PHONETIC)
	assert_int(p["ceiling"]).is_equal(10)
	assert_int(p["expected_grade"]).is_between(8, 10)
	assert_bool(p["can_afford"]).is_true()
	# preview is read-only:
	assert_int(_inv.size()).is_equal(4)
	assert_int(_wallet.shards).is_equal(100)
	assert_bool(_inv.get_instance(s["target"]).is_raw()).is_true()
