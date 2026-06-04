## Loadout — the 5-card kit you bring into a run, which IS your stake (Phase 3, M4).
##
## Extraction-shooter model: there is no separate collateral pool — the cards you
## equip are exactly the cards on the line. Die in the dungeon → lose the whole
## kit; extract alive → it comes home. (Stake assembly + loss/keep is Stake's job;
## this is the pure data container.)
##
## Slots are UNTYPED (2026-06-04 decision): any instance fits any slot — there is
## no part-of-speech gate. The "2 passive + 3 active" split survives only as a
## per-slot ROLE the combat layer (M5) reads to decide how an equipped card's
## effect applies — passive slots → whole-run stats, active slots → per-answer
## damage. Roles never constrain what you may equip.
##
## An equipped instance is owned by the loadout and is NOT simultaneously on the
## inventory bench — GameState moves an instance between the two so save round-
## trips never double-count it. `capacity`/`passive_count` are stored (not const)
## so M7 meta-unlocks can grow the kit; M4 ships the fixed 2+3.
class_name Loadout
extends RefCounted

enum SlotRole { PASSIVE, ACTIVE }

const DEFAULT_CAPACITY := 5
const DEFAULT_PASSIVE_COUNT := 2  # the remaining slots are active

# How many slots exist, and how many of the leading slots are passive-role.
# Active-role count is the remainder (capacity - passive_count).
var capacity: int = DEFAULT_CAPACITY
var passive_count: int = DEFAULT_PASSIVE_COUNT

# One entry per slot; null = empty. Leading `passive_count` slots are passive-role.
var slots: Array[CardInstance] = []


func _init(capacity_: int = DEFAULT_CAPACITY, passive_count_: int = DEFAULT_PASSIVE_COUNT) -> void:
	capacity = maxi(1, capacity_)
	passive_count = clampi(passive_count_, 0, capacity)
	_resize_slots()


func _resize_slots() -> void:
	slots.resize(capacity)  # new entries default to null


## The role of a slot by index: leading `passive_count` slots are passive.
func slot_role(index: int) -> SlotRole:
	return SlotRole.PASSIVE if index < passive_count else SlotRole.ACTIVE


func active_count() -> int:
	return capacity - passive_count


## Place `instance` in `slot`, returning whatever was there (null if it was empty)
## so the caller can return the displaced instance to the bench. Out-of-range or a
## null instance is a no-op returning null.
func set_slot(index: int, instance: CardInstance) -> CardInstance:
	if index < 0 or index >= capacity or instance == null:
		return null
	var prev := slots[index]
	slots[index] = instance
	return prev


## Empty `slot`, returning the instance that was there (null if already empty) so
## the caller can put it back on the bench.
func clear_slot(index: int) -> CardInstance:
	if index < 0 or index >= capacity:
		return null
	var prev := slots[index]
	slots[index] = null
	return prev


func get_slot(index: int) -> CardInstance:
	if index < 0 or index >= capacity:
		return null
	return slots[index]


## The first empty slot index, or -1 if the kit is full.
func first_empty_slot() -> int:
	for i in capacity:
		if slots[i] == null:
			return i
	return -1


## All non-empty instances (the actual stake).
func equipped() -> Array[CardInstance]:
	var out: Array[CardInstance] = []
	for ci in slots:
		if ci != null:
			out.append(ci)
	return out


func passive_instances() -> Array[CardInstance]:
	return _instances_in_role(SlotRole.PASSIVE)


func active_instances() -> Array[CardInstance]:
	return _instances_in_role(SlotRole.ACTIVE)


func _instances_in_role(role: SlotRole) -> Array[CardInstance]:
	var out: Array[CardInstance] = []
	for i in capacity:
		if slots[i] != null and slot_role(i) == role:
			out.append(slots[i])
	return out


func equipped_count() -> int:
	return equipped().size()


func is_full() -> bool:
	return equipped_count() >= capacity


func is_empty() -> bool:
	return equipped_count() == 0


func has_instance(id: String) -> bool:
	for ci in slots:
		if ci != null and ci.id == id:
			return true
	return false


## Remove every card from the kit and return them (for death-loss: the stake is
## gone) — leaves an empty loadout.
func strip_all() -> Array[CardInstance]:
	var out := equipped()
	for i in capacity:
		slots[i] = null
	return out


func to_dict() -> Dictionary:
	var rows: Array = []
	for ci in slots:
		rows.append(ci.to_dict() if ci != null else {})
	return {
		"capacity": capacity,
		"passive_count": passive_count,
		"slots": rows,
	}


## Restore from a saved dict (migration-safe: absent → an empty default kit).
func load_from_dict(d: Dictionary) -> void:
	capacity = maxi(1, int(d.get("capacity", DEFAULT_CAPACITY)))
	passive_count = clampi(int(d.get("passive_count", DEFAULT_PASSIVE_COUNT)), 0, capacity)
	_resize_slots()
	var rows: Array = d.get("slots", [])
	for i in capacity:
		var row: Variant = rows[i] if i < rows.size() else null
		slots[i] = CardInstance.from_dict(row) if (row is Dictionary and not row.is_empty()) else null
