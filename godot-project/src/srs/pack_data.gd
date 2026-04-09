## PackData — Resource describing a curated pack of cards for a session.
class_name PackData
extends Resource

@export var pack_id: String = ""
@export var created_at: float = 0.0
@export var pack_type: String = "daily"

## Arrays of card_id strings, categorized by how they ended up in the pack.
@export var common_cards: Array[String] = []
@export var struggling_cards: Array[String] = []
@export var new_cards: Array[String] = []
@export var returning_mastered: Array[String] = []

## The merged, shuffled order for presentation.
var presentation_order: Array[String] = []

func get_total_count() -> int:
	return common_cards.size() + struggling_cards.size() + new_cards.size() + returning_mastered.size()

func get_category_for_card(card_id: String) -> String:
	if card_id in new_cards:
		return "new"
	if card_id in struggling_cards:
		return "struggling"
	if card_id in returning_mastered:
		return "returning_mastered"
	return "common"

func build_presentation_order() -> void:
	presentation_order.clear()
	# Interleave: commons spread throughout, specials placed at intervals
	var specials: Array[String] = []
	specials.append_array(new_cards)
	specials.append_array(struggling_cards)
	specials.append_array(returning_mastered)

	var commons_copy: Array[String] = common_cards.duplicate()
	var all_cards: Array[String] = []

	if commons_copy.is_empty():
		all_cards = specials
	elif specials.is_empty():
		all_cards = commons_copy
	else:
		# Place specials evenly among commons
		var spacing := maxi(1, commons_copy.size() / maxi(1, specials.size()))
		var special_idx := 0
		for i in commons_copy.size():
			all_cards.append(commons_copy[i])
			if special_idx < specials.size() and (i + 1) % spacing == 0:
				all_cards.append(specials[special_idx])
				special_idx += 1
		# Append remaining specials
		while special_idx < specials.size():
			all_cards.append(specials[special_idx])
			special_idx += 1

	presentation_order = all_cards

func to_dict() -> Dictionary:
	return {
		"pack_id": pack_id,
		"created_at": created_at,
		"pack_type": pack_type,
		"common_cards": Array(common_cards),
		"struggling_cards": Array(struggling_cards),
		"new_cards": Array(new_cards),
		"returning_mastered": Array(returning_mastered),
	}

static func from_dict(data: Dictionary) -> PackData:
	var pd := PackData.new()
	pd.pack_id = data.get("pack_id", "")
	pd.created_at = data.get("created_at", 0.0)
	pd.pack_type = data.get("pack_type", "daily")
	for c in data.get("common_cards", []):
		pd.common_cards.append(str(c))
	for c in data.get("struggling_cards", []):
		pd.struggling_cards.append(str(c))
	for c in data.get("new_cards", []):
		pd.new_cards.append(str(c))
	for c in data.get("returning_mastered", []):
		pd.returning_mastered.append(str(c))
	return pd
