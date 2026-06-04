## Tests for CombatLoadout — the seam that turns the equipped kit into combat bonuses
## (M5). Covers role-match scaling, rarity×grade magnitude, passive vs active channels,
## and the per-card description. db is null throughout so resolution rides the iconic
## overrides (no DB needed).
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
