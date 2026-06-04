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

# Radical set bonus (M5): when several equipped cards share a semantic radical, the
# deck "comes online" and its WHOLE contribution is amplified. Only the dominant
# (largest) shared-radical group counts, so the reward goes to a FOCUSED kit (a 氵
# water deck, a 心 heart deck) rather than a salad of pairs. Tone is deliberately NOT
# a set axis — only ~5 tones exist, so any two cards would trigger it (too broad).
const SET_MIN := 2         # cards sharing a radical before any bonus
const SET_STEP := 0.10     # each card past the first in the dominant set: +10% kit


## Sum every equipped card's effect into one CombatMods, then amplify the whole kit by
## its dominant radical set (M5). A null/empty loadout → an empty CombatMods (the fight
## runs on its base constants alone). The DB resolves each card's radicals; without it
## there is no set bonus, only the per-card sum.
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

	# Radical-deck identity: a focused kit amplifies its whole contribution.
	var set_info := dominant_radical_set(lo, db)
	mods.set_radical = String(set_info["radical"])
	mods.set_size = int(set_info["size"])
	mods.set_multiplier = float(set_info["multiplier"])
	if mods.set_multiplier != 1.0:
		mods.scale_all(mods.set_multiplier)
	return mods


## The kit's dominant radical set: the semantic radical the most equipped cards share,
## and the whole-kit amplification it grants — 1 + SET_STEP·(size − 1). Below SET_MIN
## shared cards there is no set (radical "", size 0, multiplier 1.0). Needs the DB to
## resolve each card's radicals; a null DB → no set. Ties resolve to the lexicographically
## smallest radical so the result is deterministic. Mirrors ConnectionSet's notion of
## "shares a radical" (a radical-character contributes its own glyph).
static func dominant_radical_set(lo: Loadout, db: CharacterDatabase) -> Dictionary:
	var none := {"radical": "", "size": 0, "multiplier": 1.0}
	if lo == null or db == null:
		return none
	var tally := {}   # radical glyph -> number of equipped cards carrying it
	for ci in lo.equipped():
		var cd: CharacterData = db.get_character(ci.card_id)
		if cd == null:
			continue
		for r in _radical_tags(cd):
			tally[r] = int(tally.get(r, 0)) + 1
	var best_radical := ""
	var best_size := 0
	for r in tally:
		var n := int(tally[r])
		if n > best_size or (n == best_size and r < best_radical):
			best_size = n
			best_radical = r
	if best_size < SET_MIN:
		return none
	return {
		"radical": best_radical,
		"size": best_size,
		"multiplier": 1.0 + SET_STEP * float(best_size - 1),
	}


## The radical glyphs a card contributes to the set tally: its listed semantic radicals,
## plus its own glyph when the card itself IS a radical (白 anchors the cards that list
## it). De-duped so one card counts once per radical.
static func _radical_tags(cd: CharacterData) -> Array:
	var tags: Array = []
	for r in cd.radicals:
		if r not in tags:
			tags.append(r)
	if cd.is_radical and cd.character not in tags:
		tags.append(cd.character)
	return tags


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
