## ReviewScheduler — Determines which cards to present and when.
## Interfaces with FsrsAlgorithm and CardState to schedule reviews.
## This is the "dealer" — it decides what the player sees.
class_name ReviewScheduler
extends RefCounted

var fsrs: FsrsAlgorithm
var card_states: Dictionary = {}  # card_id -> CardState
var _pack_curator: PackCurator


func _init() -> void:
	fsrs = FsrsAlgorithm.new()
	_pack_curator = PackCurator.new(fsrs, card_states)


## Register a card so the scheduler knows about it.
func register_card(card_id: String, character: String) -> CardState:
	if card_id in card_states:
		return card_states[card_id]
	var cs := CardState.create(card_id, character, fsrs)
	card_states[card_id] = cs
	return cs


## Load previously saved card state.
func load_card_state(data: Dictionary) -> void:
	var cs := CardState.from_dict(data, fsrs)
	card_states[cs.card_id] = cs


## Get all cards currently due for review (any challenge type).
func get_due_cards(now: float) -> Array[CardState]:
	var due: Array[CardState] = []
	for card_id in card_states:
		var cs: CardState = card_states[card_id]
		if cs.is_any_due(now):
			due.append(cs)
	return due


## Get cards near the forgetting threshold — the "rare loot".
func get_about_to_forget_cards(now: float) -> Array[CardState]:
	var result: Array[CardState] = []
	for card_id in card_states:
		var cs: CardState = card_states[card_id]
		if cs.is_new():
			continue
		var weakest := cs.get_weakest_challenge_type()
		if cs.is_about_to_forget(weakest, now):
			result.append(cs)
	return result


## Get unreviewed cards to introduce.
func get_new_card_ids() -> Array[String]:
	var new_ids: Array[String] = []
	for card_id in card_states:
		var cs: CardState = card_states[card_id]
		if cs.is_new():
			new_ids.append(card_id)
	return new_ids


## Build a pack for a session.
func curate_pack(now: float, pack_size: int = SrsConfig.PACK_SIZE_DEFAULT, available_new_ids: Array = []) -> PackData:
	_pack_curator._card_states = card_states
	return _pack_curator.curate_pack(now, pack_size, available_new_ids)


## Record a review result and update the card's SRS state.
## Returns promotion info if the card tier changed.
func record_review(card_id: String, challenge_type: String, rating: int, now: float) -> Dictionary:
	if card_id not in card_states:
		return {}

	var cs: CardState = card_states[card_id]
	var old_state := cs.get_state_for_type(challenge_type)
	var old_stability: float = old_state.get("stability", 0.0)

	var new_state := fsrs.review(old_state, rating, now)
	cs.update_state(challenge_type, new_state)

	var new_stability: float = new_state.get("stability", 0.0)
	var promotion := CardTierCalculator.check_promotion(old_stability, new_stability)

	return {
		"card_id": card_id,
		"challenge_type": challenge_type,
		"old_state": old_state,
		"new_state": new_state,
		"promotion": promotion,
	}


## Pick the weakest challenge type for a card (what to quiz next).
func select_challenge_type(card_id: String) -> String:
	if card_id not in card_states:
		return "meaning"
	return card_states[card_id].get_weakest_challenge_type()


## Determine loot rarity for a card in the current session.
func get_loot_rarity(card_id: String, challenge_type: String, now: float) -> SrsEnums.LootRarity:
	if card_id not in card_states:
		return SrsEnums.LootRarity.NEW_CARD

	var cs: CardState = card_states[card_id]
	if cs.is_new():
		return SrsEnums.LootRarity.NEW_CARD

	var r := cs.get_retrievability(challenge_type, now)
	if r < SrsConfig.ABOUT_TO_FORGET_THRESHOLD:
		return SrsEnums.LootRarity.ABOUT_TO_FORGET

	var state: int = cs.get_state_for_type(challenge_type).get("state", FsrsAlgorithm.State.NEW)
	if state == FsrsAlgorithm.State.LEARNING or state == FsrsAlgorithm.State.RELEARNING:
		return SrsEnums.LootRarity.LEARNING

	return SrsEnums.LootRarity.COMMON


## Get coin multiplier for a card's loot rarity.
func get_coin_multiplier(card_id: String, challenge_type: String, now: float) -> float:
	var rarity := get_loot_rarity(card_id, challenge_type, now)
	match rarity:
		SrsEnums.LootRarity.COMMON:
			return SrsConfig.COIN_MULT_COMMON
		SrsEnums.LootRarity.LEARNING:
			return SrsConfig.COIN_MULT_LEARNING
		SrsEnums.LootRarity.ABOUT_TO_FORGET:
			return SrsConfig.COIN_MULT_ABOUT_TO_FORGET
		SrsEnums.LootRarity.NEW_CARD:
			return SrsConfig.COIN_MULT_NEW
	return 1.0


## Serialize all card states for saving.
func serialize_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card_id in card_states:
		result.append(card_states[card_id].to_dict())
	return result


## Load all card states from saved data.
func deserialize_all(data: Array) -> void:
	card_states.clear()
	for entry in data:
		load_card_state(entry)
	_pack_curator._card_states = card_states
