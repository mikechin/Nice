## CraftSystem — the grading craft (town-only, Phase 3, M4).
##
## Grading is a CRAFT, not a purchase. You take a raw instance you own (the
## target), surround it with a set of 3 ingredient instances that share a
## linguistic connection (ConnectionSet), and pay a shard fee. The craft consumes
## the three ingredients (the real sink) and upgrades the target in place from RAW
## to a PSA grade. It is the ONLY place grading happens.
##
## The roll obeys the locked two-cap band: the target's rolled RARITY caps how
## high it can grade, the player's MASTERY (FSRS stability) caps the reach within
## that, and the CONNECTION loads where in the band you land (phonetic series →
## top, tone → bottom). "Safe within band" — you always get an in-band grade for
## your ingredients; the gamble lives in the dungeon, not the workbench.
##
## Pure orchestration over injected economy structs (no autoload reads except the
## SignalBus emit), and mastery stability is passed IN by the caller — so it's
## fully testable without the SRS layer. rng is injectable/seedable.
class_name CraftSystem
extends RefCounted

const CRAFT_FEE: int = 10        # shard table-stakes; the ingredients are the real sink
const ROLL_VARIANCE: float = 0.15  # band-position jitter around the connection's load

var _inventory: Inventory
var _wallet: Wallet
var _binder: Binder
var _character_db: CharacterDatabase
var rng := RandomNumberGenerator.new()


func _init(inventory: Inventory, wallet: Wallet, binder: Binder, character_db: CharacterDatabase) -> void:
	_inventory = inventory
	_wallet = wallet
	_binder = binder
	_character_db = character_db


## Non-mutating preview for the crafter UI's teaching hook ("your mastery of 水 →
## up to PSA 8"). Returns the band, axis, fee, affordability, and the expected
## grade without consuming anything.
func preview(target_id: String, ingredient_ids: Array, mastery_stability: float) -> Dictionary:
	var v := _validate(target_id, ingredient_ids)
	if not v["ok"]:
		return { "valid": false, "reason": v["reason"] }

	var conn: Dictionary = v["connection"]
	var target: CardInstance = v["target"]
	var floor_psa: int = GradeBand.MIN_PSA
	var ceiling: int = GradeBand.ceiling(target.rarity, mastery_stability)
	return {
		"valid": true,
		"axis": conn["axis"],
		"axis_name": ConnectionSet.axis_name(conn["axis"]),
		"band_load": conn["band_load"],
		"floor": floor_psa,
		"ceiling": ceiling,
		"rarity_cap": GradeBand.rarity_cap(target.rarity),
		"mastery_cap": GradeBand.mastery_cap(mastery_stability),
		"expected_grade": _expected_grade(floor_psa, ceiling, conn["band_load"]),
		"fee": CRAFT_FEE,
		"can_afford": _wallet.can_afford(CRAFT_FEE),
		"reason": "",
	}


## Perform the craft. On success: spends the fee, consumes the 3 ingredients,
## grades the target in place, records the new best-PSA in the binder, and emits
## instance_graded. Returns { ok, grade, axis, axis_name, fee, reason }. On any
## validation/affordability failure NOTHING is mutated.
func craft(target_id: String, ingredient_ids: Array, mastery_stability: float) -> Dictionary:
	var v := _validate(target_id, ingredient_ids)
	if not v["ok"]:
		return { "ok": false, "reason": v["reason"] }
	if not _wallet.can_afford(CRAFT_FEE):
		return { "ok": false, "reason": "not enough shards (need %d)" % CRAFT_FEE }

	var target: CardInstance = v["target"]
	var conn: Dictionary = v["connection"]
	var ceiling: int = GradeBand.ceiling(target.rarity, mastery_stability)
	var grade: int = _roll_grade(GradeBand.MIN_PSA, ceiling, conn["band_load"])

	# Commit (validation passed, fee affordable): all-or-nothing from here.
	_wallet.spend(CRAFT_FEE)
	for id in ingredient_ids:
		_inventory.remove(id)        # ingredients are consumed
	target.grade = grade             # target stays on the bench, now graded
	_binder.record_grade(target.card_id, grade)
	SignalBus.instance_graded.emit(target, grade)

	return {
		"ok": true,
		"grade": grade,
		"axis": conn["axis"],
		"axis_name": ConnectionSet.axis_name(conn["axis"]),
		"fee": CRAFT_FEE,
		"reason": "",
	}


# -- internals --------------------------------------------------------------

## Resolve + check inputs. Returns { ok, reason, target, connection } — target is
## the CardInstance to grade, connection is ConnectionSet.classify's result.
func _validate(target_id: String, ingredient_ids: Array) -> Dictionary:
	var target := _inventory.get_instance(target_id)
	if target == null:
		return { "ok": false, "reason": "target instance is not on the bench" }
	if not target.is_raw():
		return { "ok": false, "reason": "target is already graded (no re-grading)" }

	if ingredient_ids.size() != ConnectionSet.REQUIRED_INGREDIENTS:
		return { "ok": false, "reason": "need exactly %d ingredients" % ConnectionSet.REQUIRED_INGREDIENTS }

	var seen := {}
	var ingredient_cds: Array = []
	for id in ingredient_ids:
		if id == target_id or seen.has(id):
			return { "ok": false, "reason": "ingredients must be 3 distinct instances, none the target" }
		seen[id] = true
		var ing := _inventory.get_instance(id)
		if ing == null:
			return { "ok": false, "reason": "ingredient '%s' is not on the bench" % id }
		var cd := _character_db.get_character(ing.card_id)
		if cd == null:
			return { "ok": false, "reason": "unknown character '%s'" % ing.card_id }
		ingredient_cds.append(cd)

	var target_cd := _character_db.get_character(target.card_id)
	if target_cd == null:
		return { "ok": false, "reason": "unknown target character '%s'" % target.card_id }

	var conn := ConnectionSet.classify(target_cd, ingredient_cds)
	if not conn["valid"]:
		return { "ok": false, "reason": conn["reason"] }

	return { "ok": true, "reason": "", "target": target, "connection": conn }


## Roll a grade inside [floor, ceiling], loaded toward `band_load` (0..1) with a
## little variance. Always in-band (safe). Phonetic (1.0) lands near the top;
## tone (0.15) near the bottom.
func _roll_grade(floor_psa: int, ceiling: int, band_load: float) -> int:
	if ceiling <= floor_psa:
		return floor_psa
	var center := clampf(band_load + rng.randf_range(-ROLL_VARIANCE, ROLL_VARIANCE), 0.0, 1.0)
	return floor_psa + roundi(center * float(ceiling - floor_psa))


## The variance-free expected grade, for the preview odds display.
func _expected_grade(floor_psa: int, ceiling: int, band_load: float) -> int:
	if ceiling <= floor_psa:
		return floor_psa
	return floor_psa + roundi(clampf(band_load, 0.0, 1.0) * float(ceiling - floor_psa))
