## DungeonRun — lifecycle state for one dungeon run (Phase 3, M2 + M3).
##
## Owns the run-level **HP pool** — the design's single player HP bar that
## REPLACED discrete hearts (dungeon-crawler-direction.md: "Both sides have HP
## bars. You (one player HP bar — replaces discrete hearts) vs. 1–3 mobs").
## HP persists across rooms within a run (mobs chip it on their ATB timer) and
## resets to full only at the start of a NEW run ("HP resets to full each run").
## HP hits 0 → DIED → the haul is lost. Death never touches binder / mastery /
## unlocks — that un-loseable guarantee lives a layer up; here we only ever lose
## the run's instances/haul.
##
## Owns the accumulating **haul** of real CardInstances (M3). The haul grows
## without limit during the run — the **carry cap** bites only at the extract
## gate, where the player triages down to their best N (banked) and the rest
## shatter into shards. "Triage at the door" (decision: carry cap = the headline
## meta stat). Also tracks the **depth** reached and an answer tally for the
## debrief.
##
## Pure state: the dungeon-map controller drives it and combat reads/writes the
## HP + haul. No scene, no FSRS, no signals. GameState.bank_haul does the actual
## crediting of bench/binder/wallet once this resolves the kept-vs-shattered split.
class_name DungeonRun
extends RefCounted

const DEFAULT_MAX_HP := 30
const DEFAULT_CARRY_CAP := 6

var map: RunMap
var max_hp: int = DEFAULT_MAX_HP
var hp: int = DEFAULT_MAX_HP
var carry_cap: int = DEFAULT_CARRY_CAP
var depth: int = 0                          # deepest room reached
var rooms_cleared: int = 0
var answered: int = 0                        # combat answers this run (debrief only)
var correct: int = 0
var haul: Array[CardInstance] = []           # everything grabbed (uncapped until extract)
var banked: Array[CardInstance] = []         # what came home (set at extract)
var shattered: Array[CardInstance] = []      # triaged away → shards (set at extract)
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
## room), the loot dropped (Array[CardInstance]), and how many answers were
## given/correct (for the debrief). If HP <= 0 the run dies and the haul is lost.
func apply_room_result(surviving_hp: int, loot: Array, answered_: int, correct_: int) -> void:
	hp = clampi(surviving_hp, 0, max_hp)
	answered += maxi(0, answered_)
	correct += maxi(0, correct_)
	if hp <= 0:
		die()
		return
	add_loot(loot)
	rooms_cleared += 1


## Append looted instances to the haul. No cap here — the haul grows freely and
## the carry cap is resolved at the extract gate (see extract()).
func add_loot(loot: Array) -> void:
	for ci in loot:
		if ci is CardInstance:
			haul.append(ci)


## True once the haul has reached the cap — a soft nudge for the UI; carrying
## more is allowed, it just means triage at the gate.
func haul_full() -> bool:
	return haul.size() >= carry_cap


## True when extracting now would force the player to leave cards behind.
func needs_triage() -> bool:
	return haul.size() > carry_cap


## Bank the haul and end the run alive. `keep` is the player's triage choice
## (a subset of the haul, by object reference); empty → auto-keep the best
## `carry_cap` by sort key. Kept → banked, the remainder → shattered (shards).
## Only valid at an extract gate / boss clear — the controller enforces that.
func extract(keep: Array = []) -> void:
	if outcome != DungeonEnums.RunOutcome.ONGOING:
		return
	_resolve_haul(keep)
	outcome = DungeonEnums.RunOutcome.EXTRACTED


func _resolve_haul(keep: Array) -> void:
	var kept: Array[CardInstance] = []
	if keep.is_empty():
		kept = _best_n(carry_cap)
	else:
		# Honor the selection, but never exceed the cap — best-first if over.
		for ci in _sorted_desc(keep):
			if kept.size() >= carry_cap:
				break
			if haul.has(ci) and not kept.has(ci):
				kept.append(ci)
	banked = kept
	shattered = []
	for ci in haul:
		if not kept.has(ci):
			shattered.append(ci)


## The best `n` instances of the haul by sort key (rarity, then grade).
func _best_n(n: int) -> Array[CardInstance]:
	var sorted := _sorted_desc(haul)
	var out: Array[CardInstance] = []
	for ci in sorted:
		if out.size() >= maxi(0, n):
			break
		out.append(ci)
	return out


func _sorted_desc(arr: Array) -> Array[CardInstance]:
	var copy: Array[CardInstance] = []
	for ci in arr:
		if ci is CardInstance:
			copy.append(ci)
	copy.sort_custom(func(a: CardInstance, b: CardInstance) -> bool:
		return a.sort_key() > b.sort_key())
	return copy


## End the run dead — the haul is forfeit (nothing banked, nothing shattered).
func die() -> void:
	if outcome == DungeonEnums.RunOutcome.ONGOING:
		outcome = DungeonEnums.RunOutcome.DIED


func get_accuracy() -> float:
	if answered == 0:
		return 0.0
	return float(correct) / float(answered)


## What actually comes home. Extract → the banked subset; died → nothing.
func banked_haul() -> Array[CardInstance]:
	if outcome == DungeonEnums.RunOutcome.EXTRACTED:
		return banked.duplicate()
	return []


## What was triaged away at the gate (→ shards). Empty unless extracted.
func shattered_haul() -> Array[CardInstance]:
	if outcome == DungeonEnums.RunOutcome.EXTRACTED:
		return shattered.duplicate()
	return []


## Total shards the triaged-away instances are worth (for the debrief preview).
func shard_gain() -> int:
	var total := 0
	for ci in shattered_haul():
		total += ci.shard_value()
	return total


func _card_ids(list: Array) -> Array[String]:
	var ids: Array[String] = []
	for ci in list:
		if ci is CardInstance:
			ids.append(ci.card_id)
	return ids


func _instance_dicts(list: Array) -> Array:
	var rows: Array = []
	for ci in list:
		if ci is CardInstance:
			rows.append(ci.to_dict())
	return rows


## A debrief dict. Carries dungeon-native keys (mode/outcome/depth/haul/shards)
## AND legacy keys ResultsScreen already reads (accuracy/rounds_completed/
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
		"haul_card_ids": _card_ids(haul),               # everything carried
		"banked_card_ids": _card_ids(banked_haul()),    # what came home (empty if died)
		"banked_instances": _instance_dicts(banked_haul()),
		"haul_size": haul.size(),
		"shattered_count": shattered_haul().size(),
		"shards_gained": shard_gain(),
		"answered": answered,
		"correct": correct,
		# --- legacy-compatible keys for ResultsScreen ---
		"accuracy": get_accuracy(),
		"rounds_completed": rooms_cleared,
		"hand_cards": [],
		"total_hand_power": 0,
	}
