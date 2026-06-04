## EffectEnums — the bounded palette of combat abilities an equipped card grants
## (Phase 3, M5). Each character maps to ONE Kind by its meaning (EffectPalette);
## the magnitude scales with the instance's rarity × grade (InstancePower). Six
## kinds keep the catalogue small enough to "backtrack to a few fixed archetypes"
## if the meaning-themed curation ever gets unwieldy — the kinds ARE the archetypes.
##
## Each kind is inherently PASSIVE (a whole-run stat applied at fight setup) or
## ACTIVE (a per-correct-answer rider fired during the fight) — matching the two
## loadout slot ROLES. A card whose nature matches its slot pays full value; a
## mismatch is reduced (CombatLoadout.ROLE_MISMATCH) so placement rewards thought
## without hard-gating which card fits which slot. Pure data; no scene, no SRS.
class_name EffectEnums
extends RefCounted

enum Kind {
	STRIKE,   ## passive — +attack damage          (大 / 多 / 力 …)
	WARD,     ## passive — +max HP & block          (安 / 门 / 家 …)
	FOCUS,    ## passive — +crit chance             (心 / 眼 / 明 …)
	SURGE,    ## passive — +ATB charge & accuracy   (快 / 走 / 电 …)
	BURN,     ## active  — bonus damage on a correct answer  (火 / 热 / 日 …)
	MEND,     ## active  — heal on a correct answer          (水 / 雨 / 医 …)
}

## Which kinds are passive (whole-run stats) vs active (per-answer riders).
const PASSIVE := {
	Kind.STRIKE: true, Kind.WARD: true, Kind.FOCUS: true, Kind.SURGE: true,
	Kind.BURN: false, Kind.MEND: false,
}

const KIND_NAME := {
	Kind.STRIKE: "Strike", Kind.WARD: "Ward", Kind.FOCUS: "Focus",
	Kind.SURGE: "Surge", Kind.BURN: "Burn", Kind.MEND: "Mend",
}

## Per-kind base magnitude, in each effect's native unit, BEFORE the rarity×grade
## scalar. Keys map to CombatMods channels. Tuned against the combat constants
## (ATTACK_DAMAGE 3, HP 30, block 0.25, crit 0.15) — a common-raw card is a small
## nudge; a graded rare is a real swing. Playtest-tunable in one place.
const BASE := {
	Kind.STRIKE: {"attack": 1.0},
	Kind.WARD:   {"max_hp": 4.0, "block": 0.04},
	Kind.FOCUS:  {"crit": 0.05},
	Kind.SURGE:  {"atb": 0.03, "accuracy": 0.03},
	Kind.BURN:   {"burn": 1.0},
	Kind.MEND:   {"heal": 1.0},
}


static func is_passive(kind: int) -> bool:
	return bool(PASSIVE.get(kind, true))


static func kind_name(kind: int) -> String:
	return String(KIND_NAME.get(kind, "Strike"))


static func base_for(kind: int) -> Dictionary:
	return BASE.get(kind, {})


## Lower-case kind name → Kind, for a future curated data field ("burn" → BURN).
## Unknown strings fall back to STRIKE.
static func kind_from_string(name: String) -> int:
	var n := name.strip_edges().to_lower()
	for k in KIND_NAME:
		if String(KIND_NAME[k]).to_lower() == n:
			return k
	return Kind.STRIKE
