## ConnectionSet — validates the linguistic family you craft a grade along (M4).
##
## Grading is a craft, not a purchase: you surround a TARGET character with a set
## of 3 ingredient instances that share a *linguistic connection* with it. The
## connection does two jobs — it gates which sets are legal, and (the part M4
## cares about) it LOADS where in the mastery band the PSA roll lands. The axis
## also AUTHORS the ability family, but that wiring is M5; here we only validate
## the set and classify its axis + band-load weight.
##
## Axes, by ascending prestige (= ascending band-load):
##   HOMOPHONE — same base pinyin (sound), tone aside. The floor: a genuine sound
##               link, smallest reward. (Tone ALONE is intentionally not an axis —
##               only ~5 tones exist, so it would connect almost any two cards; too
##               broad to author a craft. Same call as the combat radical-set bonus.)
##   RADICAL   — share a semantic radical (氵 water-family, etc.).
##   PHONETIC  — share a phonetic component (声旁): 请/清/晴/情 around 青. The
##               prestige craft — hardest set to gather, top-of-band payoff, and
##               the single best reading hack in Chinese (the language supplies
##               the difficulty curve; we don't hand-tune it).
##
## Pure functions over CharacterData (the resolved-from-instance character rows),
## so it's testable without loading any autoload. CraftSystem resolves the
## instances to CharacterData via the character DB and calls in here.
class_name ConnectionSet
extends RefCounted

enum Axis { NONE = -1, HOMOPHONE, RADICAL, PHONETIC }

const REQUIRED_INGREDIENTS := 3

## Where in the mastery band a connection loads the roll: 0 = bottom, 1 = top.
## Rarer/harder connection → loads higher (self-balancing: the scarcer set is
## also the better reward). CraftSystem maps this onto the actual band.
const BAND_LOAD := {
	Axis.HOMOPHONE: 0.35,
	Axis.RADICAL: 0.6,
	Axis.PHONETIC: 1.0,
}


## Every axis along which `ingredient` connects to `target` (may be several).
static func pair_axes(target: CharacterData, ingredient: CharacterData) -> Array[int]:
	var axes: Array[int] = []
	if target == null or ingredient == null:
		return axes
	if _shares_phonetic(target, ingredient):
		axes.append(Axis.PHONETIC)
	if _shares_radical(target, ingredient):
		axes.append(Axis.RADICAL)
	if _shares_homophone(target, ingredient):
		axes.append(Axis.HOMOPHONE)
	return axes


## Classify a candidate craft: the 3 ingredients must ALL connect to the target
## along at least one common axis. Returns:
##   { valid: bool, axis: Axis, band_load: float, reason: String }
## with axis = the most prestigious axis common to all three (best band-load).
static func classify(target: CharacterData, ingredients: Array) -> Dictionary:
	if target == null:
		return _invalid("no target")
	if ingredients.size() != REQUIRED_INGREDIENTS:
		return _invalid("need exactly %d ingredients, got %d" % [REQUIRED_INGREDIENTS, ingredients.size()])

	# Intersect the per-ingredient axis sets: an axis is usable only if EVERY
	# ingredient connects to the target along it.
	var common: Array[int] = pair_axes(target, ingredients[0])
	for i in range(1, ingredients.size()):
		var axes := pair_axes(target, ingredients[i])
		common = common.filter(func(a): return a in axes)
		if common.is_empty():
			return _invalid("ingredient %d shares no common connection with the target" % i)

	# Most prestigious common axis (enum value ascends with prestige).
	var best: int = Axis.NONE
	for a in common:
		if a > best:
			best = a
	return {
		"valid": true,
		"axis": best,
		"band_load": float(BAND_LOAD.get(best, 0.0)),
		"reason": "",
	}


static func axis_name(axis: int) -> String:
	match axis:
		Axis.PHONETIC: return "phonetic series"
		Axis.RADICAL: return "radical"
		Axis.HOMOPHONE: return "homophone"
		_: return "none"


# -- axis predicates --------------------------------------------------------

static func _shares_homophone(a: CharacterData, b: CharacterData) -> bool:
	var pa := a.get_base_pinyin()
	return pa != "" and pa == b.get_base_pinyin()


static func _shares_radical(a: CharacterData, b: CharacterData) -> bool:
	for r in a.radicals:
		if r in b.radicals:
			return true
	# A radical-character itself counts: 白 is the shared radical of cards listing it.
	if a.is_radical and a.character in b.radicals:
		return true
	if b.is_radical and b.character in a.radicals:
		return true
	return false


## Shared *phonetic* component (声旁): a component present in both characters that
## is NOT a semantic radical of the target — the sound-bearing part. Excludes the
## characters themselves (some data rows list a char among its own components).
static func _shares_phonetic(a: CharacterData, b: CharacterData) -> bool:
	for c in a.components:
		if c == a.character or c == b.character:
			continue
		if c in a.radicals:
			continue  # that's the semantic radical, not the phonetic
		if c in b.components:
			return true
	return false


static func _invalid(reason: String) -> Dictionary:
	return { "valid": false, "axis": Axis.NONE, "band_load": 0.0, "reason": reason }
