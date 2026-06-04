## Binder — the permanent, one-entry-per-character collection record (Phase 3, M3).
##
## This is the retermed binder (decision D8): it drops the old COMMON–LEGENDARY
## gem tiers and instead records the factual history of each character —
##   - seen          : the player has encountered/answered it
##   - times_dropped : how many instances of it have ever been banked
##   - best_psa      : the highest grade ever achieved, recorded FOREVER
## The best-PSA ceiling is the beginner's long-term carrot: it only climbs (it
## never falls when the graded instance is later spent or lost), so it's a
## permanent trophy of learning.
##
## The un-loseable north star lives here: death destroys instances, never the
## binder. Knowledge and the best-PSA record are never staked. Pure data;
## SaveManager persists it.
class_name Binder
extends RefCounted

# card_id -> { "seen": bool, "times_dropped": int, "best_psa": int }
var entries: Dictionary = {}


func _entry(card_id: String) -> Dictionary:
	if not entries.has(card_id):
		entries[card_id] = { "seen": false, "times_dropped": 0, "best_psa": 0 }
	return entries[card_id]


## Mark a character as encountered (called when it's answered in a run).
func record_seen(card_id: String) -> void:
	if card_id == "":
		return
	_entry(card_id)["seen"] = true


## Record that an instance of this character was banked. Bumps the drop count,
## marks it seen, and lifts best-PSA if this instance is graded higher.
func record_drop(instance: CardInstance) -> void:
	if instance == null or instance.card_id == "":
		return
	var e := _entry(instance.card_id)
	e["seen"] = true
	e["times_dropped"] = int(e["times_dropped"]) + 1
	if instance.grade > int(e["best_psa"]):
		e["best_psa"] = instance.grade


## Record a freshly crafted grade (M4 town grading). best-PSA only ever climbs.
func record_grade(card_id: String, psa: int) -> void:
	if card_id == "":
		return
	var e := _entry(card_id)
	if psa > int(e["best_psa"]):
		e["best_psa"] = psa


func is_seen(card_id: String) -> bool:
	return entries.has(card_id) and bool(entries[card_id]["seen"])


func times_dropped(card_id: String) -> int:
	return int(_entry(card_id)["times_dropped"]) if entries.has(card_id) else 0


func best_psa(card_id: String) -> int:
	return int(entries[card_id]["best_psa"]) if entries.has(card_id) else 0


## How many distinct characters have been seen / ever dropped — collection
## progress headlines for the binder screen (M4).
func seen_count() -> int:
	var n := 0
	for k in entries:
		if bool(entries[k]["seen"]):
			n += 1
	return n


func dropped_count() -> int:
	var n := 0
	for k in entries:
		if int(entries[k]["times_dropped"]) > 0:
			n += 1
	return n


## The card_ids the player has encountered — the shop's "already-met" pool, and
## the binder screen's discovered set. (M4)
func get_seen_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in entries:
		if bool(entries[k]["seen"]):
			ids.append(k)
	return ids


func to_dict() -> Dictionary:
	return { "entries": entries.duplicate(true) }


func load_from_dict(d: Dictionary) -> void:
	entries.clear()
	var raw: Dictionary = d.get("entries", {})
	for card_id in raw:
		var row: Dictionary = raw[card_id]
		entries[card_id] = {
			"seen": bool(row.get("seen", false)),
			"times_dropped": int(row.get("times_dropped", 0)),
			"best_psa": int(row.get("best_psa", 0)),
		}
