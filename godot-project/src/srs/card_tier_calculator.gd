## CardTierCalculator — Maps SRS state to visual card tier.
## A card's tier IS its SRS mastery — no separate upgrade mechanic.
class_name CardTierCalculator
extends RefCounted


## Determine tier from max stability across all challenge types.
static func calculate_tier(card_state: CardState) -> CollectionEnums.CardTier:
	if card_state.is_new():
		return CollectionEnums.CardTier.NEW_CARD

	var stability := card_state.get_max_stability()

	if stability >= SrsConfig.TIER_LEGENDARY_STABILITY:
		return CollectionEnums.CardTier.LEGENDARY
	elif stability >= SrsConfig.TIER_EPIC_STABILITY:
		return CollectionEnums.CardTier.EPIC
	elif stability >= SrsConfig.TIER_RARE_STABILITY:
		return CollectionEnums.CardTier.RARE
	elif stability >= SrsConfig.TIER_UNCOMMON_STABILITY:
		return CollectionEnums.CardTier.UNCOMMON
	elif stability >= SrsConfig.TIER_COMMON_STABILITY:
		return CollectionEnums.CardTier.COMMON
	else:
		return CollectionEnums.CardTier.NEW_CARD


## Build a CardVisualState from a CardState.
static func build_visual_state(card_state: CardState) -> CardVisualState:
	var tier := calculate_tier(card_state)
	return CardVisualState.for_tier(card_state.character, tier)


## Get tier from raw stability value (for previews / debug).
static func tier_from_stability(stability: float) -> CollectionEnums.CardTier:
	if stability >= SrsConfig.TIER_LEGENDARY_STABILITY:
		return CollectionEnums.CardTier.LEGENDARY
	elif stability >= SrsConfig.TIER_EPIC_STABILITY:
		return CollectionEnums.CardTier.EPIC
	elif stability >= SrsConfig.TIER_RARE_STABILITY:
		return CollectionEnums.CardTier.RARE
	elif stability >= SrsConfig.TIER_UNCOMMON_STABILITY:
		return CollectionEnums.CardTier.UNCOMMON
	elif stability >= SrsConfig.TIER_COMMON_STABILITY:
		return CollectionEnums.CardTier.COMMON
	else:
		return CollectionEnums.CardTier.NEW_CARD


## Check if a card was just promoted to a new tier after a review.
static func check_promotion(old_stability: float, new_stability: float) -> Dictionary:
	var old_tier := tier_from_stability(old_stability)
	var new_tier := tier_from_stability(new_stability)
	return {
		"promoted": new_tier > old_tier,
		"old_tier": old_tier,
		"new_tier": new_tier,
	}
