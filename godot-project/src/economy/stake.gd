## Stake — the kit you put on the line when you enter a run (Phase 3, M4).
##
## In the extraction-shooter model the loadout IS the stake: there's no separate
## collateral pool. This is a snapshot of the equipped instances taken at dungeon
## entry — "what you're risking." It drives the debrief ("you brought these 5")
## and the death-loss resolution (GameState.resolve_stake destroys them). Extract
## alive → the kit simply stays equipped; die → the whole snapshot is forfeit.
##
## A snapshot, not a live link: it holds the instance references as they were at
## entry. Runs live in-memory (RunState autoload, never serialized), so the stake
## doesn't persist across app restarts and needs no save form.
class_name Stake
extends RefCounted

var instances: Array[CardInstance] = []


static func from_loadout(lo: Loadout) -> Stake:
	var s := Stake.new()
	if lo != null:
		s.instances = lo.equipped()
	return s


func card_ids() -> Array[String]:
	var ids: Array[String] = []
	for ci in instances:
		ids.append(ci.card_id)
	return ids


func size() -> int:
	return instances.size()


func is_empty() -> bool:
	return instances.is_empty()
