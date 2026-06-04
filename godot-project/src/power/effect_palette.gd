## EffectPalette — resolves a character to its combat EffectKind by MEANING
## (Phase 3, M5). This is the "meaning-curated palette": a character's gloss decides
## which of the six abilities it grants (火 burns, 水 mends, 大 strikes, 安 wards …).
##
## Resolution order, first hit wins:
##   1. an explicit curated `effect` field on the CharacterData (what the future
##      one-time HSK 2–3 agent pass writes — empty for now);
##   2. a per-character override for iconic glyphs whose gloss is ambiguous;
##   3. a keyword scan of the English meaning (generalises across HSK levels);
##   4. a deterministic fallback by code-point sum so EVERY card grants *something*
##      (biased to passive kinds — unmapped cards become quiet stat sticks, never
##      surprise riders).
##
## Steps 2–3 ARE the hand-curated slice; the agent pass later just fills step 1 and
## these stay as the fallback. Pure: no scene, no SRS, no RNG. Deterministic.
class_name EffectPalette
extends RefCounted

## Iconic single-character overrides — glyphs whose effect should be unambiguous
## regardless of how their gloss is phrased.
const CHAR_OVERRIDE := {
	"火": EffectEnums.Kind.BURN, "热": EffectEnums.Kind.BURN, "日": EffectEnums.Kind.BURN,
	"红": EffectEnums.Kind.BURN, "光": EffectEnums.Kind.BURN, "灯": EffectEnums.Kind.BURN,
	"水": EffectEnums.Kind.MEND, "雨": EffectEnums.Kind.MEND, "河": EffectEnums.Kind.MEND,
	"海": EffectEnums.Kind.MEND, "茶": EffectEnums.Kind.MEND, "药": EffectEnums.Kind.MEND,
	"大": EffectEnums.Kind.STRIKE, "多": EffectEnums.Kind.STRIKE, "力": EffectEnums.Kind.STRIKE,
	"打": EffectEnums.Kind.STRIKE, "手": EffectEnums.Kind.STRIKE, "牛": EffectEnums.Kind.STRIKE,
	"安": EffectEnums.Kind.WARD, "门": EffectEnums.Kind.WARD, "家": EffectEnums.Kind.WARD,
	"山": EffectEnums.Kind.WARD, "石": EffectEnums.Kind.WARD, "住": EffectEnums.Kind.WARD,
	"心": EffectEnums.Kind.FOCUS, "眼": EffectEnums.Kind.FOCUS, "明": EffectEnums.Kind.FOCUS,
	"看": EffectEnums.Kind.FOCUS, "知": EffectEnums.Kind.FOCUS, "白": EffectEnums.Kind.FOCUS,
	"快": EffectEnums.Kind.SURGE, "走": EffectEnums.Kind.SURGE, "电": EffectEnums.Kind.SURGE,
	"车": EffectEnums.Kind.SURGE, "飞": EffectEnums.Kind.SURGE, "风": EffectEnums.Kind.SURGE,
}

## Meaning keyword → Kind. Scanned in this order; first substring hit wins, so the
## lists are ordered to disambiguate (e.g. "fire" before generic words). Lower-case.
const KEYWORD_KINDS := [
	[EffectEnums.Kind.BURN, ["fire", "hot", "burn", "sun", "summer", "light", "lamp", "red", "flame"]],
	[EffectEnums.Kind.MEND, ["water", "rain", "river", "sea", "lake", "wash", "drink", "tea", "wet",
		"snow", "medicine", "doctor", "heal", "rest", "sleep", "wine"]],
	[EffectEnums.Kind.STRIKE, ["big", "many", "much", "strong", "strength", "power", "hit", "fight",
		"strike", "hand", "force", "meat", "beat", "war"]],
	[EffectEnums.Kind.WARD, ["safe", "peace", "door", "gate", "home", "house", "wall", "mountain",
		"stone", "rock", "protect", "close", "stop", "sit", "stand", "live", "quiet", "heavy"]],
	[EffectEnums.Kind.FOCUS, ["see", "look", "watch", "eye", "heart", "mind", "think", "know",
		"clear", "bright", "white", "study", "read", "learn", "true", "right", "understand"]],
	[EffectEnums.Kind.SURGE, ["fast", "quick", "go", "walk", "run", "move", "car", "drive",
		"electric", "wind", "fly", "open", "start", "early"]],
]

## Fallback kinds (passive only) for characters none of the above resolve. Indexed
## by a stable code-point sum so the choice is deterministic and spread out.
const FALLBACK := [EffectEnums.Kind.STRIKE, EffectEnums.Kind.WARD,
	EffectEnums.Kind.FOCUS, EffectEnums.Kind.SURGE]


## The kind for a CharacterData (assumed non-null). Override → keyword → fallback.
static func kind_for(cd: CharacterData) -> int:
	if cd == null:
		return FALLBACK[0]
	if cd.effect != "":
		return EffectEnums.kind_from_string(cd.effect)
	if CHAR_OVERRIDE.has(cd.character):
		return int(CHAR_OVERRIDE[cd.character])
	var hit := _scan_meaning(cd.meaning)
	if hit >= 0:
		return hit
	return _fallback_for(cd.character)


## Resolve straight from a card_id, looking the character up in `db` when given.
## Without a DB (or an unknown id) it overrides/falls back on the glyph alone.
static func kind_for_char(card_id: String, db: CharacterDatabase) -> int:
	if db != null:
		var cd: CharacterData = db.get_character(card_id)
		if cd != null:
			return kind_for(cd)
	if CHAR_OVERRIDE.has(card_id):
		return int(CHAR_OVERRIDE[card_id])
	return _fallback_for(card_id)


static func _scan_meaning(meaning: String) -> int:
	var m := meaning.to_lower()
	for entry in KEYWORD_KINDS:
		var kind: int = entry[0]
		for kw in entry[1]:
			if m.find(kw) >= 0:
				return kind
	return -1


## Deterministic, engine-independent: sum of the character's UTF-32 code points,
## mod the fallback list. Same character → same kind, every run.
static func _fallback_for(card_id: String) -> int:
	var sum := 0
	for i in card_id.length():
		sum += card_id.unicode_at(i)
	return FALLBACK[sum % FALLBACK.size()]
