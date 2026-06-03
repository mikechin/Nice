## Inventory — the persistent bench of owned card instances (Phase 3, M3).
##
## The Tarkov-style stash: everything you've extracted and not yet spent. It's
## the buffer that makes aggressive death-stakes survivable — a deep bench means
## losing a loadout stings less. Instances live here between runs; the binder
## (the permanent record) lives elsewhere and survives even when this is wiped.
##
## Owns stable instance ids (minted on add) so the triage UI, crafting, and save
## round-trips can reference a specific copy. Pure data — SaveManager persists it.
class_name Inventory
extends RefCounted

var instances: Array[CardInstance] = []
var _next_id: int = 1


## Add an instance, minting a stable id if it doesn't have one. Returns the
## (now id'd) instance.
func add(instance: CardInstance) -> CardInstance:
	if instance == null:
		return null
	if instance.id == "":
		instance.id = _mint_id()
	instances.append(instance)
	return instance


func add_many(list: Array) -> void:
	for ci in list:
		add(ci)


func _mint_id() -> String:
	var id := "ci_%d" % _next_id
	_next_id += 1
	return id


## Remove and return the instance with `id`, or null if absent.
func remove(id: String) -> CardInstance:
	for i in instances.size():
		if instances[i].id == id:
			var ci := instances[i]
			instances.remove_at(i)
			return ci
	return null


func get_instance(id: String) -> CardInstance:
	for ci in instances:
		if ci.id == id:
			return ci
	return null


func get_all() -> Array[CardInstance]:
	return instances.duplicate()


func size() -> int:
	return instances.size()


func is_empty() -> bool:
	return instances.is_empty()


## How many bench copies of a given character you hold (dupes feed shards/craft).
func count_of(card_id: String) -> int:
	var n := 0
	for ci in instances:
		if ci.card_id == card_id:
			n += 1
	return n


## Shatter a bench instance into shards. Returns the shard value (0 if not
## found). The caller credits the wallet — Inventory doesn't know about currency.
func shatter(id: String) -> int:
	var ci := remove(id)
	return ci.shard_value() if ci != null else 0


func to_dict() -> Dictionary:
	var rows: Array = []
	for ci in instances:
		rows.append(ci.to_dict())
	return {
		"next_id": _next_id,
		"instances": rows,
	}


## Replace contents from a saved dict (migration-safe: missing keys → empty).
func load_from_dict(d: Dictionary) -> void:
	instances.clear()
	_next_id = int(d.get("next_id", 1))
	for row in d.get("instances", []):
		if row is Dictionary:
			instances.append(CardInstance.from_dict(row))
