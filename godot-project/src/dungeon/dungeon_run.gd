## DungeonRun — lifecycle state for one dungeon run (Phase 3, M2).
##
## Owns the run-level **HP pool** — the design's single player HP bar that
## REPLACED discrete hearts (dungeon-crawler-direction.md: "Both sides have HP
## bars. You (one player HP bar — replaces discrete hearts) vs. 1–3 mobs").
## HP persists across rooms within a run (mobs chip it on their ATB timer) and
## resets to full only at the start of a NEW run ("HP resets to full each run").
## HP hits 0 → DIED → the haul is lost. Death never touches binder / mastery /
## unlocks — that un-loseable guarantee lives a layer up (M3+); here we only
## ever lose the run's instances/haul.
##
## Also owns the accumulating **haul** (raw carried card ids — instances and
## PSA grades arrive in M3, so for now the haul is just what you carried out),
## the **depth** reached, a **fixed carry cap** (a real growing meta stat in
## M7; fixed here), and an answer tally for the post-run debrief.
##
## Pure state: the dungeon-map controller drives it and combat reads/writes the
## HP + haul. No scene, no FSRS, no signals.
class_name DungeonRun
extends RefCounted

const DEFAULT_MAX_HP := 30
const DEFAULT_CARRY_CAP := 6

var map: RunMap
var max_hp: int = DEFAULT_MAX_HP
var hp: int = DEFAULT_MAX_HP
var carry_cap: int = DEFAULT_CARRY_CAP
var depth: int = 0                 # deepest room reached
var rooms_cleared: int = 0
var answered: int = 0              # combat answers this run (debrief only)
var correct: int = 0
var haul: Array[String] = []       # carried raw card ids, capped at carry_cap
var dropped_overflow: int = 0      # cards left behind at the cap (triage UI is M2b)
var outcome: DungeonEnums.RunOutcome = DungeonEnums.RunOutcome.ONGOING


static func create(map_: RunMap, max_hp_: int = DEFAULT_MAX_HP, carry_cap_: int = DEFAULT_CARRY_CAP) -> DungeonRun:
	var r := DungeonRun.new()
	r.map = map_ if map_ != null else RunMap.build_default()
	r.max_hp = maxi(1, max_hp_)
	r.hp = r.max_hp                 # full HP at run start
	r.carry_cap = maxi(0, carry_cap_)
	return r


func is_alive() -> bool:
	return hp > 0 and outcome == DungeonEnums.RunOutcome.ONGOING


func is_over() -> bool:
	return outcome != DungeonEnums.RunOutcome.ONGOING


## Mark that the player has reached `room` (updates the deepest depth). Called
## by the controller as it moves the cursor into a room.
func reached(room: RoomNode) -> void:
	if room != null:
		depth = maxi(depth, room.depth)


## Combat reports back after a fight: the surviving HP (persists into the next
## room), the loot ids dropped, and how many answers were given/correct (for
## the debrief). If HP <= 0 the run dies and the haul is lost.
func apply_room_result(surviving_hp: int, loot_ids: Array, answered_: int, correct_: int) -> void:
	hp = clampi(surviving_hp, 0, max_hp)
	answered += maxi(0, answered_)
	correct += maxi(0, correct_)
	if hp <= 0:
		die()
		return
	add_loot(loot_ids)
	rooms_cleared += 1


func haul_full() -> bool:
	return haul.size() >= carry_cap


## Add looted ids up to the carry cap; overflow is left behind (counted, so the
## debrief can say "you couldn't carry it all"). The at-the-door triage UI that
## lets the player CHOOSE what to drop is the M2b follow-up.
func add_loot(loot_ids: Array) -> void:
	for id in loot_ids:
		if typeof(id) != TYPE_STRING or id == "":
			continue
		if haul_full():
			dropped_overflow += 1
			continue
		haul.append(id)


## Bank the haul and end the run alive. Only valid at an extract gate (or boss
## clear) — the controller enforces that; this just records the outcome.
func extract() -> void:
	if outcome == DungeonEnums.RunOutcome.ONGOING:
		outcome = DungeonEnums.RunOutcome.EXTRACTED


## End the run dead — the haul is forfeit.
func die() -> void:
	if outcome == DungeonEnums.RunOutcome.ONGOING:
		outcome = DungeonEnums.RunOutcome.DIED


func get_accuracy() -> float:
	if answered == 0:
		return 0.0
	return float(correct) / float(answered)


## Whether the haul actually comes home. Extract → yes; died → forfeit.
func banked_haul() -> Array[String]:
	if outcome == DungeonEnums.RunOutcome.EXTRACTED:
		return haul.duplicate()
	return []


## A debrief dict. Carries dungeon-native keys (mode/outcome/depth/haul) AND
## legacy keys ResultsScreen already reads (accuracy/rounds_completed/
## hand_cards/total_hand_power) so the existing screen renders without choking.
func to_summary() -> Dictionary:
	return {
		"mode": "dungeon",
		"outcome": outcome,
		"extracted": outcome == DungeonEnums.RunOutcome.EXTRACTED,
		"died": outcome == DungeonEnums.RunOutcome.DIED,
		"depth": depth,
		"rooms_cleared": rooms_cleared,
		"carry_cap": carry_cap,
		"haul_card_ids": haul.duplicate(),         # what was carried
		"banked_card_ids": banked_haul(),          # what came home (empty if died)
		"haul_size": haul.size(),
		"dropped_overflow": dropped_overflow,
		"answered": answered,
		"correct": correct,
		# --- legacy-compatible keys for ResultsScreen ---
		"accuracy": get_accuracy(),
		"rounds_completed": rooms_cleared,
		"hand_cards": [],
		"total_hand_power": 0,
	}
