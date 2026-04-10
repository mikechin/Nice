## PackCurator — Composes daily packs from SRS state.
## The "dealer" that decides what cards go into each session pack.
class_name PackCurator
extends RefCounted

var _fsrs: FsrsAlgorithm
var _card_states: Dictionary  # card_id -> CardState (reference to ReviewScheduler's)


func _init(fsrs: FsrsAlgorithm = null, card_states: Dictionary = {}) -> void:
	_fsrs = fsrs if fsrs else FsrsAlgorithm.new()
	_card_states = card_states


## Build a pack from current SRS state.
## available_new_ids: card IDs that haven't been introduced yet.
func curate_pack(now: float, pack_size: int = SrsConfig.PACK_SIZE_DEFAULT, available_new_ids: Array = []) -> PackData:
	var pack := PackData.new()
	pack.pack_id = str(roundi(now))
	pack.created_at = now
	pack.pack_type = "daily"

	# Target counts
	var n_common := roundi(pack_size * SrsConfig.PACK_COMMON_RATIO)
	var n_struggling := roundi(pack_size * SrsConfig.PACK_STRUGGLING_RATIO)
	var n_new := mini(
		roundi(pack_size * SrsConfig.PACK_NEW_RATIO),
		SrsConfig.MAX_NEW_CARDS_PER_SESSION
	)
	var n_returning := maxi(0, pack_size - n_common - n_struggling - n_new)

	# Categorize existing cards
	var due_cards: Array[String] = []
	var struggling_cards: Array[String] = []
	var returning_mastered: Array[String] = []
	var common_review: Array[String] = []

	for card_id in _card_states:
		var cs: CardState = _card_states[card_id]
		if cs.is_new():
			continue

		var weakest := cs.get_weakest_challenge_type()
		var retrievability := cs.get_retrievability(weakest, now)
		var is_due := cs.is_any_due(now)
		var stability := cs.get_max_stability()

		if retrievability < SrsConfig.ABOUT_TO_FORGET_THRESHOLD and is_due:
			struggling_cards.append(card_id)
		elif stability >= SrsConfig.TIER_EPIC_STABILITY and is_due:
			returning_mastered.append(card_id)
		elif is_due:
			due_cards.append(card_id)
		elif retrievability > SrsConfig.WELL_KNOWN_THRESHOLD:
			common_review.append(card_id)

	# Sort struggling by lowest retrievability (most urgent first)
	struggling_cards.sort_custom(func(a: String, b: String) -> bool:
		var ra: float = _card_states[a].get_retrievability(_card_states[a].get_weakest_challenge_type(), now)
		var rb: float = _card_states[b].get_retrievability(_card_states[b].get_weakest_challenge_type(), now)
		return ra < rb
	)

	# Fill pack slots
	_fill_slot(pack.struggling_cards, struggling_cards, n_struggling)
	_fill_slot(pack.returning_mastered, returning_mastered, n_returning)

	# Commons: due cards first, then well-known cards for easy reps
	var common_pool: Array[String] = []
	common_pool.append_array(due_cards)
	common_pool.append_array(common_review)
	_fill_slot(pack.common_cards, common_pool, n_common)

	# New cards (limited per session)
	var new_pool: Array = available_new_ids.duplicate()
	new_pool.shuffle()
	var new_added := mini(n_new, new_pool.size())
	for i in new_added:
		pack.new_cards.append(str(new_pool[i]))

	# If we have leftover slots, fill from due_cards first, then any remaining new IDs
	# (capped at MAX_NEW_CARDS_PER_SESSION). This keeps packs full when the review
	# queue is sparse — e.g. brand new players with no card states yet.
	var total := pack.get_total_count()
	if total < pack_size:
		var remaining := pack_size - total
		for card_id in due_cards:
			if remaining <= 0:
				break
			if card_id not in pack.common_cards and card_id not in pack.struggling_cards:
				pack.common_cards.append(card_id)
				remaining -= 1
		var new_cap := SrsConfig.MAX_NEW_CARDS_PER_SESSION
		var i := new_added
		while remaining > 0 and i < new_pool.size() and pack.new_cards.size() < new_cap:
			pack.new_cards.append(str(new_pool[i]))
			remaining -= 1
			i += 1

	pack.build_presentation_order()
	return pack


func _fill_slot(target: Array[String], source: Array, count: int) -> void:
	var added := 0
	for card_id in source:
		if added >= count:
			break
		target.append(str(card_id))
		added += 1
