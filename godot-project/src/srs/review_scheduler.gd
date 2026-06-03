## ReviewScheduler — Determines which cards to present and when.
## Interfaces with FsrsAlgorithm and CardState to schedule reviews.
## This is the "dealer" — it decides what the player sees.
class_name ReviewScheduler
extends RefCounted

var fsrs: FsrsAlgorithm
var card_states: Dictionary = {}  # card_id -> CardState
var _pack_curator: PackCurator

## Debug-only: when populated, get_loot_rarity returns the override
## instead of computing from SRS state. Used by the Tier Sample debug
## pack to render one card per visual tier without faking SRS history.
var _debug_tier_overrides: Dictionary = {}  # card_id -> SrsEnums.LootRarity


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
	if _debug_tier_overrides.has(card_id):
		return _debug_tier_overrides[card_id]
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

	return SrsEnums.LootRarity.KNOWN


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


# -- Debug helpers -------------------------------------------------------

func set_debug_tier_override(card_id: String, tier: SrsEnums.LootRarity) -> void:
	_debug_tier_overrides[card_id] = tier


func clear_debug_tier_overrides() -> void:
	_debug_tier_overrides.clear()


## Build a 4-card pack with one card per LootRarity tier, used to
## visually verify CardDisplay renders each tier correctly. Each card
## is registered in card_states (so record_review doesn't drop the
## answer) and gets a tier override so get_loot_rarity returns the
## forced tier regardless of SRS state.
func curate_debug_tier_sample_pack(sample_cards: Array[CharacterData]) -> PackData:
	clear_debug_tier_overrides()
	var pack := PackData.new()
	pack.pack_id = "debug_tier_sample"
	pack.created_at = Time.get_unix_time_from_system()
	pack.pack_type = "debug"

	var tier_order: Array[SrsEnums.LootRarity] = [
		SrsEnums.LootRarity.KNOWN,
		SrsEnums.LootRarity.LEARNING,
		SrsEnums.LootRarity.ABOUT_TO_FORGET,
		SrsEnums.LootRarity.NEW_CARD,
	]

	var slots := mini(sample_cards.size(), tier_order.size())
	for i in slots:
		var card := sample_cards[i]
		var card_id := card.get_card_id()
		register_card(card_id, card.character)
		set_debug_tier_override(card_id, tier_order[i])
		match tier_order[i]:
			SrsEnums.LootRarity.NEW_CARD:
				pack.new_cards.append(card_id)
			SrsEnums.LootRarity.ABOUT_TO_FORGET:
				pack.struggling_cards.append(card_id)
			_:
				pack.common_cards.append(card_id)

	pack.build_presentation_order()
	return pack
