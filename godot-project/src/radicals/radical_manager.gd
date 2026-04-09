## RadicalManager — Manages owned and equipped radicals.
class_name RadicalManager
extends RefCounted

var owned_radicals: Array[String] = []
var equipped_radicals: Array[String] = []
var max_equipped: int = 5


func equip_radical(radical: String) -> bool:
	if not is_owned(radical):
		return false
	if is_equipped(radical):
		return false
	if equipped_radicals.size() >= max_equipped:
		return false
	equipped_radicals.append(radical)
	SignalBus.radical_equipped.emit(radical)
	return true


func unequip_radical(radical: String) -> void:
	var idx := equipped_radicals.find(radical)
	if idx >= 0:
		equipped_radicals.remove_at(idx)
		SignalBus.radical_unequipped.emit(radical)


func purchase_radical(radical: String) -> void:
	if not is_owned(radical):
		owned_radicals.append(radical)


func is_owned(radical: String) -> bool:
	return radical in owned_radicals


func is_equipped(radical: String) -> bool:
	return radical in equipped_radicals


func get_equipped() -> Array[String]:
	return equipped_radicals


func get_owned() -> Array[String]:
	return owned_radicals


func get_available_slots() -> int:
	return max_equipped - equipped_radicals.size()


func get_unequipped_owned() -> Array[String]:
	var result: Array[String] = []
	for r in owned_radicals:
		if r not in equipped_radicals:
			result.append(r)
	return result


func to_dict() -> Dictionary:
	return {
		"owned_radicals": Array(owned_radicals),
		"equipped_radicals": Array(equipped_radicals),
	}


static func from_dict(data: Dictionary) -> RadicalManager:
	var rm := RadicalManager.new()
	for r in data.get("owned_radicals", []):
		rm.owned_radicals.append(str(r))
	for r in data.get("equipped_radicals", []):
		rm.equipped_radicals.append(str(r))
	return rm
