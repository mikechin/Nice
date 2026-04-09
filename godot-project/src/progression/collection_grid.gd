## CollectionGrid — Data model for the character collection grid.
## Characters: locked, new, common, uncommon, rare, epic, legendary.
class_name CollectionGrid
extends RefCounted

## Per-character entry: { tier: CardTier, visual: CardVisualState }
var _grid_entries: Dictionary = {}
var _total_characters: int = 0
var _unlocked_count: int = 0


## Build grid from character database and current SRS states.
func build_grid(char_db: CharacterDatabase, scheduler: ReviewScheduler, now: float) -> void:
	_grid_entries.clear()
	_total_characters = char_db.get_count()
	_unlocked_count = 0

	for cd in char_db.get_all():
		var ch := cd.character
		if ch in scheduler.card_states:
			var cs: CardState = scheduler.card_states[ch]
			if cs.is_new():
				_grid_entries[ch] = {
					"tier": CollectionEnums.CardTier.LOCKED,
					"visual": CardVisualState.locked(ch),
				}
			else:
				var tier := CardTierCalculator.calculate_tier(cs)
				_grid_entries[ch] = {
					"tier": tier,
					"visual": CardTierCalculator.build_visual_state(cs),
				}
				_unlocked_count += 1
		else:
			_grid_entries[ch] = {
				"tier": CollectionEnums.CardTier.LOCKED,
				"visual": CardVisualState.locked(ch),
			}


func get_entry(character: String) -> Dictionary:
	return _grid_entries.get(character, {})


func get_tier(character: String) -> CollectionEnums.CardTier:
	var entry := get_entry(character)
	return entry.get("tier", CollectionEnums.CardTier.LOCKED)


func get_visual_state(character: String) -> CardVisualState:
	var entry := get_entry(character)
	return entry.get("visual")


func update_character_state(character: String, card_state: CardState) -> void:
	if card_state.is_new():
		_grid_entries[character] = {
			"tier": CollectionEnums.CardTier.LOCKED,
			"visual": CardVisualState.locked(character),
		}
	else:
		var was_locked: bool = get_tier(character) == CollectionEnums.CardTier.LOCKED
		var tier := CardTierCalculator.calculate_tier(card_state)
		_grid_entries[character] = {
			"tier": tier,
			"visual": CardTierCalculator.build_visual_state(card_state),
		}
		if was_locked:
			_unlocked_count += 1


func get_completion_percentage() -> float:
	if _total_characters == 0:
		return 0.0
	return float(_unlocked_count) / float(_total_characters)


func get_unlocked_count() -> int:
	return _unlocked_count


func get_total_count() -> int:
	return _total_characters


func get_characters_by_tier(tier: CollectionEnums.CardTier) -> Array[String]:
	var result: Array[String] = []
	for ch in _grid_entries:
		if _grid_entries[ch]["tier"] == tier:
			result.append(ch)
	return result


func get_decaying_characters(scheduler: ReviewScheduler, now: float) -> Array[String]:
	var result: Array[String] = []
	for ch in _grid_entries:
		if _grid_entries[ch]["tier"] == CollectionEnums.CardTier.LOCKED:
			continue
		if ch in scheduler.card_states:
			var cs: CardState = scheduler.card_states[ch]
			var weakest := cs.get_weakest_challenge_type()
			if cs.is_about_to_forget(weakest, now):
				result.append(ch)
	return result


## Get sorted list of characters for display, applying filter and sort.
func get_sorted_characters(
	char_db: CharacterDatabase,
	sort_by: CollectionEnums.CollectionSort = CollectionEnums.CollectionSort.HSK_LEVEL,
	filter_by: CollectionEnums.CollectionFilter = CollectionEnums.CollectionFilter.ALL
) -> Array[String]:
	var characters: Array[String] = []

	for cd in char_db.get_all():
		var ch := cd.character
		var tier := get_tier(ch)

		# Apply filter
		match filter_by:
			CollectionEnums.CollectionFilter.LOCKED:
				if tier != CollectionEnums.CardTier.LOCKED:
					continue
			CollectionEnums.CollectionFilter.UNLOCKED:
				if tier == CollectionEnums.CardTier.LOCKED:
					continue
			CollectionEnums.CollectionFilter.MASTERED:
				if tier < CollectionEnums.CardTier.EPIC:
					continue

		characters.append(ch)

	# Apply sort
	match sort_by:
		CollectionEnums.CollectionSort.TIER:
			characters.sort_custom(func(a: String, b: String) -> bool:
				return get_tier(a) > get_tier(b)
			)
		CollectionEnums.CollectionSort.FREQUENCY:
			characters.sort_custom(func(a: String, b: String) -> bool:
				var ca := char_db.get_character(a)
				var cb := char_db.get_character(b)
				if ca and cb:
					return ca.frequency_rank < cb.frequency_rank
				return a < b
			)

	return characters
