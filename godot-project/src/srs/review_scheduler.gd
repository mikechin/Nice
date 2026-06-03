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


## DEBUG: wipe all SRS progress back to brand-new. Every registered card's
## facets reset to NEW so the next encounter teaches them — lets you watch the
## TEACH → 2-option → 4-option scaffold from a clean slate. Cards stay
## REGISTERED (an unregistered card would make record_review a no-op and loop
## the teach forever). Returns how many cards were reset.
func debug_reset_all_new() -> int:
	for card_id in card_states:
		var cs: CardState = card_states[card_id]
		for ct in cs.states.keys():
			cs.states[ct] = fsrs.init_card()
	return card_states.size()


## DEBUG: seed a REALISTIC mature HSK1–2 deck — the actual long-time-player
## snapshot, not an idealized one. Per card we roll an archetype and let the four
## facets DIVERGE; combat shows each card's weakest-by-stability facet, so the
## visible mix lands believably:
##   ~70% mastered   → all facets strong → KNOWN, 4-option recall (standard)
##   ~16% has a lapse → one decayed facet below the clutch bar → ⚡ ABOUT_TO_FORGET
##                       (feeds the limit bar; 2- or 4-option by how weak it is)
##   ~14% learning    → one weak-but-fresh facet → LEARNING, 2-option recognition
## Zero new (no NEW-state facets). Clutch is the minority it should be in a healthy
## deck — it comes from lapses, not from everything decaying at once. Returns the
## number of cards seeded.
func debug_seed_steady_state(now: float) -> int:
	for card_id in card_states:
		var cs: CardState = card_states[card_id]
		for ct in cs.states.keys():
			cs.states[ct] = _known_facet(now)          # start every facet strong…
		var roll := randf()
		if roll < 0.16:
			cs.states[_random_facet(cs)] = _lapsed_facet(now)    # …then drop ONE to a lapse (clutch)
		elif roll < 0.30:
			cs.states[_random_facet(cs)] = _learning_facet(now)  # …or one still in learning
	return card_states.size()


func _random_facet(cs: CardState) -> String:
	var keys := cs.states.keys()
	return keys[randi() % keys.size()]


## A solid long-term memory: high stability (well above the recall floor) and a
## healthy retrievability that's just past due, so it shows up and reads KNOWN.
func _known_facet(now: float) -> Dictionary:
	return _facet(FsrsAlgorithm.State.REVIEW, randf_range(14.0, 45.0), randf_range(0.74, 0.88), now, randi_range(5, 18), 0)


## A facet you nearly forgot: low stability and decayed below the clutch bar — the
## realistic source of about-to-forget cards in a mature deck (a lapse, not rot).
func _lapsed_facet(now: float) -> Dictionary:
	return _facet(FsrsAlgorithm.State.RELEARNING, randf_range(3.0, 9.0), randf_range(0.48, 0.66), now, randi_range(4, 12), randi_range(1, 3))


## Still being acquired: weak stability (→ 2-option recognition) but seen recently
## enough that retrievability stays above the clutch bar (so it reads LEARNING).
func _learning_facet(now: float) -> Dictionary:
	return _facet(FsrsAlgorithm.State.LEARNING, randf_range(1.5, 6.0), randf_range(0.72, 0.90), now, randi_range(1, 3), 0)


## Assemble one facet's FSRS dict, back-dating last_review so its retrievability
## lands on target_r for the given stability (the forgetting curve, inverted).
func _facet(state: int, stability: float, target_r: float, now: float, reps: int, lapses: int) -> Dictionary:
	var elapsed := _days_elapsed_for_retrievability(target_r, stability)
	return {
		"state": state,
		"stability": stability,
		"difficulty": randf_range(4.0, 7.0),
		"elapsed_days": int(round(elapsed)),
		"scheduled_days": fsrs.next_interval(stability),
		"reps": reps,
		"lapses": lapses,
		"last_review": now - elapsed * 86400.0,
	}


## Invert the (monotonic) forgetting curve numerically: the elapsed days at which
## a card of `stability` has decayed to `target_r`. Binary search — the curve has
## no closed-form inverse exposed here.
func _days_elapsed_for_retrievability(target_r: float, stability: float) -> float:
	var lo := 0.0
	var hi := stability * 3000.0 + 10.0
	for _i in 44:
		var mid := (lo + hi) * 0.5
		if fsrs.forgetting_curve(mid, stability) > target_r:
			lo = mid    # still too fresh → push elapsed up to lower R
		else:
			hi = mid
	return (lo + hi) * 0.5


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
