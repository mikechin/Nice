## Tests for CombatLoadout — the seam that turns the equipped kit into combat bonuses
## (M5). Covers role-match scaling, rarity×grade magnitude, passive vs active channels,
## the per-card description, and the radical SET bonus (deck identity). Earlier tests
## pass db=null so resolution rides the iconic overrides; the set-bonus tests build a
## small CharacterDatabase because radicals can only come from the DB.
extends GdUnitTestSuite


func _inst(card_id: String, rarity: int, grade: int = GradeBand.RAW) -> CardInstance:
	var ci := CardInstance.create(card_id, rarity, 0)
	ci.grade = grade
	return ci


func test_empty_loadout_yields_no_bonuses() -> void:
	var lo := Loadout.new()
	var mods := CombatLoadout.assemble(lo, null)
	assert_bool(mods.is_empty()).is_true()
	assert_str(mods.summary()).is_equal("no bonuses")


func test_passive_strike_in_a_passive_slot_pays_full() -> void:
	# 大 = STRIKE (passive). Slots 0–1 are passive; a rare-raw STRIKE there = base 1 × 2.0.
	var lo := Loadout.new()
	lo.set_slot(0, _inst("大", EconomyEnums.Rarity.RARE))
	var mods := CombatLoadout.assemble(lo, null)
	assert_int(mods.attack_i()).is_equal(2)


func test_role_mismatch_halves_the_effect() -> void:
	# Same rare STRIKE in an ACTIVE slot (index 4): wrong role → half → base 1 × 2.0 × 0.5 = 1.
	var lo := Loadout.new()
	lo.set_slot(4, _inst("大", EconomyEnums.Rarity.RARE))
	var mods := CombatLoadout.assemble(lo, null)
	assert_int(mods.attack_i()).is_equal(1)


func test_grade_scales_magnitude_up() -> void:
	var raw := CombatLoadout.assemble(_one("大", EconomyEnums.Rarity.RARE, GradeBand.RAW, 0), null)
	var graded := CombatLoadout.assemble(_one("大", EconomyEnums.Rarity.RARE, 10, 0), null)
	assert_bool(graded.attack > raw.attack).is_true()


func test_active_kinds_feed_burn_and_heal_in_active_slots() -> void:
	var lo := Loadout.new()
	lo.set_slot(4, _inst("火", EconomyEnums.Rarity.COMMON))   # BURN (active) in an active slot
	lo.set_slot(3, _inst("水", EconomyEnums.Rarity.COMMON))   # MEND (active) in an active slot
	var mods := CombatLoadout.assemble(lo, null)
	assert_int(mods.burn_i()).is_equal(1)
	assert_int(mods.heal_i()).is_equal(1)


func test_ward_fills_hp_and_block_channels() -> void:
	var lo := Loadout.new()
	lo.set_slot(0, _inst("安", EconomyEnums.Rarity.COMMON))   # WARD (passive) in a passive slot
	var mods := CombatLoadout.assemble(lo, null)
	assert_int(mods.max_hp_i()).is_equal(4)
	assert_float(mods.block).is_equal_approx(0.04, 0.0001)


func test_describe_card_flags_a_wrong_slot() -> void:
	var matched := CombatLoadout.describe_card(_inst("火", EconomyEnums.Rarity.COMMON), false, null)
	var mismatched := CombatLoadout.describe_card(_inst("火", EconomyEnums.Rarity.COMMON), true, null)
	assert_str(matched).contains("Burn")
	assert_str(mismatched).contains("wrong slot")


# Helper: a fresh single-card loadout (card in passive slot 0).
func _one(card_id: String, rarity: int, grade: int, slot: int) -> Loadout:
	var lo := Loadout.new()
	lo.set_slot(slot, _inst(card_id, rarity, grade))
	return lo


# -- radical set bonus (deck identity) --------------------------------------

func _cd(character: String, effect: String, radicals: Array, is_radical: bool = false) -> CharacterData:
	var cd := CharacterData.new()
	cd.character = character
	cd.meaning = character
	cd.effect = effect
	for r in radicals:
		cd.radicals.append(str(r))
	cd.is_radical = is_radical
	return cd


func _db(rows: Array) -> CharacterDatabase:
	var chars: Array[CharacterData] = []
	for r in rows:
		chars.append(r)
	var db := CharacterDatabase.new()
	db.load_from_array(chars)
	return db


func test_shared_radical_amplifies_the_whole_kit() -> void:
	# Three 火-radical BURN cards in active slots 2–4 (all role-matched). Each rare-raw
	# BURN = base 1 × 2.0 = 2 burn → sum 6. A 3-card set → ×1.2 → 7.2 → 7.
	var db := _db([
		_cd("焰", "burn", ["火"]), _cd("炬", "burn", ["火"]), _cd("煌", "burn", ["火"]),
	])
	var lo := Loadout.new()
	lo.set_slot(2, _inst("焰", EconomyEnums.Rarity.RARE))
	lo.set_slot(3, _inst("炬", EconomyEnums.Rarity.RARE))
	lo.set_slot(4, _inst("煌", EconomyEnums.Rarity.RARE))
	var mods := CombatLoadout.assemble(lo, db)
	assert_int(mods.set_size).is_equal(3)
	assert_float(mods.set_multiplier).is_equal_approx(1.2, 0.0001)
	assert_int(mods.burn_i()).is_equal(7)               # 6 × 1.2, rounded
	assert_str(mods.summary()).contains("火 set +20%")


func test_distinct_radicals_form_no_set() -> void:
	# Same three cards, now with unrelated radicals → no set, raw sum (6), no amplifier.
	var db := _db([
		_cd("焰", "burn", ["火"]), _cd("炬", "burn", ["水"]), _cd("煌", "burn", ["木"]),
	])
	var lo := Loadout.new()
	lo.set_slot(2, _inst("焰", EconomyEnums.Rarity.RARE))
	lo.set_slot(3, _inst("炬", EconomyEnums.Rarity.RARE))
	lo.set_slot(4, _inst("煌", EconomyEnums.Rarity.RARE))
	var mods := CombatLoadout.assemble(lo, db)
	assert_int(mods.set_size).is_equal(0)
	assert_float(mods.set_multiplier).is_equal_approx(1.0, 0.0001)
	assert_int(mods.burn_i()).is_equal(6)
	assert_str(mods.summary()).not_contains("set +")


func test_dominant_set_is_the_largest_shared_group() -> void:
	# 3 cards share 火, 2 share 水 → the dominant set is 火 (size 3), not 水.
	var db := _db([
		_cd("焰", "burn", ["火"]), _cd("炬", "burn", ["火"]), _cd("煌", "burn", ["火"]),
		_cd("江", "mend", ["水"]), _cd("河", "mend", ["水"]),
	])
	var lo := Loadout.new()
	var ids := ["焰", "炬", "煌", "江", "河"]
	for i in ids.size():
		lo.set_slot(i, _inst(ids[i], EconomyEnums.Rarity.COMMON))
	var info := CombatLoadout.dominant_radical_set(lo, db)
	assert_str(String(info["radical"])).is_equal("火")
	assert_int(int(info["size"])).is_equal(3)


func test_radical_character_itself_anchors_a_set() -> void:
	# 白 IS a radical; two cards listing 白 plus the 白 card → a size-3 白 set.
	var db := _db([
		_cd("白", "focus", [], true),
		_cd("的", "focus", ["白"]), _cd("百", "strike", ["白"]),
	])
	var lo := Loadout.new()
	lo.set_slot(0, _inst("白", EconomyEnums.Rarity.COMMON))
	lo.set_slot(1, _inst("的", EconomyEnums.Rarity.COMMON))
	lo.set_slot(2, _inst("百", EconomyEnums.Rarity.COMMON))
	var info := CombatLoadout.dominant_radical_set(lo, db)
	assert_str(String(info["radical"])).is_equal("白")
	assert_int(int(info["size"])).is_equal(3)


func test_no_set_bonus_without_a_db() -> void:
	# Radicals can only come from the DB; a null DB → no set, the per-card sum stands.
	var lo := Loadout.new()
	lo.set_slot(2, _inst("焰", EconomyEnums.Rarity.RARE))
	lo.set_slot(3, _inst("炬", EconomyEnums.Rarity.RARE))
	var info := CombatLoadout.dominant_radical_set(lo, null)
	assert_int(int(info["size"])).is_equal(0)
	assert_float(float(info["multiplier"])).is_equal_approx(1.0, 0.0001)
