## CombatLoadout — turns the equipped kit into the combat modifiers a fight applies
## (Phase 3, M5). This is the seam that finally makes the loadout MATTER: until now
## the kit was only a thing you could lose at the gate; here each equipped card grants
## a real combat effect.
##
## Pure: given the Loadout (instances + their slot roles) and the character DB, it
## resolves each card to an EffectKind (EffectPalette), scales that kind's base by the
## instance's rarity×grade (InstancePower) and by a role-match multiplier, and sums
## everything into a CombatMods. Passive kinds become whole-run stat deltas applied at
## fight setup; active kinds become per-correct-answer riders. No scene, no FSRS, no RNG.
##
## Role-match: a card whose nature matches its slot role pays full; a mismatch pays
## ROLE_MISMATCH (it still works, at half) — placement rewards thought, never hard-gates.
class_name CombatLoadout
extends RefCounted

const ROLE_MATCH := 1.0
const ROLE_MISMATCH := 0.5   # right card, wrong slot role → still works, at half value


## Sum every equipped card's effect into one CombatMods. A null/empty loadout → an
## empty CombatMods (the fight runs on its base constants alone).
static func assemble(lo: Loadout, db: CharacterDatabase) -> CombatMods:
	var mods := CombatMods.new()
	if lo == null:
		return mods
	for i in lo.capacity:
		var ci: CardInstance = lo.get_slot(i)
		if ci == null:
			continue
		var kind := EffectPalette.kind_for_char(ci.card_id, db)
		var slot_passive := lo.slot_role(i) == Loadout.SlotRole.PASSIVE
		var role_mult := ROLE_MATCH if (slot_passive == EffectEnums.is_passive(kind)) else ROLE_MISMATCH
		var scalar := InstancePower.scalar(ci.rarity, ci.grade) * role_mult
		for channel in EffectEnums.base_for(kind):
			mods.add(channel, float(EffectEnums.base_for(kind)[channel]) * scalar)
	return mods


## One-line description of a single card's contribution in a given slot role, for the
## Home loadout UI ("Strike  +3 atk" / "Burn  2 dmg/ans  (½ — wrong slot)").
static func describe_card(ci: CardInstance, slot_passive: bool, db: CharacterDatabase) -> String:
	if ci == null:
		return ""
	var kind := EffectPalette.kind_for_char(ci.card_id, db)
	var matched := slot_passive == EffectEnums.is_passive(kind)
	var scalar := InstancePower.scalar(ci.rarity, ci.grade) * (ROLE_MATCH if matched else ROLE_MISMATCH)

	var bits: Array[String] = []
	for channel in EffectEnums.base_for(kind):
		var v: float = float(EffectEnums.base_for(kind)[channel]) * scalar
		bits.append(_channel_phrase(channel, v))
	var text := "%s  %s" % [EffectEnums.kind_name(kind), "  ".join(bits)]
	if not matched:
		text += "  (½ — wrong slot)"
	return text


static func _channel_phrase(channel: String, v: float) -> String:
	match channel:
		"attack": return "+%d atk" % int(round(v))
		"max_hp": return "+%d HP" % int(round(v))
		"block": return "+%d%% block" % int(round(v * 100.0))
		"crit": return "+%d%% crit" % int(round(v * 100.0))
		"atb": return "+%d%% charge" % int(round(v * 100.0))
		"accuracy": return "+%d%% acc" % int(round(v * 100.0))
		"burn": return "%d dmg/ans" % int(round(v))
		"heal": return "%d heal/ans" % int(round(v))
	return ""
