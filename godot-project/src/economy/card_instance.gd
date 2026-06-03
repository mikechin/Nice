## CardInstance — one consumable, owned copy of a character (Phase 3, M3).
##
## The split the whole economy turns on: the BINDER is the permanent, one-per-
## character record (seen / dropped / best-PSA, never destroyed); INSTANCES are
## the disposable game objects you bank, stake, shatter, and (in M4) grade.
## Death loses instances, never the binder. You never spend a character — you
## spend its instances.
##
## An instance carries its rolled `rarity` (RarityRoll, fixed at drop) and its
## `grade` (PSA 1–10, RAW until crafted in town). "card = rarity × grade" lives
## here. A typed Resource per the project's data-modeling convention.
class_name CardInstance
extends Resource

var id: String = ""                                          # stable id, minted by Inventory on add
var card_id: String = ""                                     # the character (== CharacterData.get_card_id())
var rarity: int = EconomyEnums.Rarity.COMMON                 # rolled at drop, never changes
var grade: int = GradeBand.RAW                               # PSA grade; RAW until crafted (M4)
var dropped_at_depth: int = 0                                # provenance / flavor

# Shards yielded by shattering, by rarity. Small for commons (pure currency),
# meaningful for rares — the floor of "what a drop is worth" if you don't keep it.
const SHARD_BY_RARITY := {
	EconomyEnums.Rarity.COMMON: 1,
	EconomyEnums.Rarity.UNCOMMON: 3,
	EconomyEnums.Rarity.RARE: 8,
	EconomyEnums.Rarity.EPIC: 20,
}


static func create(card_id_: String, rarity_: int, depth: int = 0) -> CardInstance:
	var ci := CardInstance.new()
	ci.card_id = card_id_
	ci.rarity = rarity_
	ci.grade = GradeBand.RAW
	ci.dropped_at_depth = maxi(0, depth)
	return ci


func is_raw() -> bool:
	return GradeBand.is_raw(grade)


## Shards from shattering this instance — rarity sets the base, a graded copy
## adds its grade (you're destroying earned condition, so it's worth more).
func shard_value() -> int:
	var base: int = SHARD_BY_RARITY.get(rarity, 1)
	return base + maxi(0, grade)


## Higher = more worth keeping at triage. Rarity dominates; grade breaks ties.
func sort_key() -> int:
	return EconomyEnums.rarity_rank(rarity) * 100 + grade


func display_label() -> String:
	var tag := EconomyEnums.rarity_initial(rarity)
	if is_raw():
		return "%s [%s]" % [card_id, tag]
	return "%s [%s · %s]" % [card_id, tag, GradeBand.grade_name(grade)]


func to_dict() -> Dictionary:
	return {
		"id": id,
		"card_id": card_id,
		"rarity": rarity,
		"grade": grade,
		"dropped_at_depth": dropped_at_depth,
	}


static func from_dict(d: Dictionary) -> CardInstance:
	var ci := CardInstance.new()
	ci.id = str(d.get("id", ""))
	ci.card_id = str(d.get("card_id", ""))
	ci.rarity = int(d.get("rarity", EconomyEnums.Rarity.COMMON))
	ci.grade = int(d.get("grade", GradeBand.RAW))
	ci.dropped_at_depth = int(d.get("dropped_at_depth", 0))
	return ci
