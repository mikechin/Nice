## CollectionEnums — Enums for the collection and card tier systems.
class_name CollectionEnums
extends RefCounted

## Visual tier of a card, determined by SRS mastery.
enum CardTier {
	LOCKED,      ## Not yet encountered
	NEW_CARD,    ## Just introduced via SRS
	COMMON,      ## Learning / early reviews
	UNCOMMON,    ## Stable, medium intervals
	RARE,        ## Well-known, long intervals
	EPIC,        ## Mastered, very long intervals
	LEGENDARY    ## Fully mastered, maximum intervals
}

## Sort options for the collection grid.
enum CollectionSort {
	HSK_LEVEL,
	TIER,
	PINYIN,
	FREQUENCY,
	RECENTLY_REVIEWED,
}

## Filter options for the collection grid.
enum CollectionFilter {
	ALL,
	LOCKED,
	UNLOCKED,
	DUE_FOR_REVIEW,
	MASTERED,
	STRUGGLING,
}

static func tier_name(tier: CardTier) -> String:
	match tier:
		CardTier.LOCKED: return "Locked"
		CardTier.NEW_CARD: return "New"
		CardTier.COMMON: return "Common"
		CardTier.UNCOMMON: return "Uncommon"
		CardTier.RARE: return "Rare"
		CardTier.EPIC: return "Epic"
		CardTier.LEGENDARY: return "Legendary"
	return "Unknown"

## Tier color for UI display.
static func tier_color(tier: CardTier) -> Color:
	match tier:
		CardTier.LOCKED: return Color(0.3, 0.3, 0.3, 0.5)
		CardTier.NEW_CARD: return Color(0.9, 0.9, 0.9)
		CardTier.COMMON: return Color(0.7, 0.7, 0.7)
		CardTier.UNCOMMON: return Color(0.2, 0.8, 0.2)
		CardTier.RARE: return Color(0.2, 0.4, 1.0)
		CardTier.EPIC: return Color(0.7, 0.2, 1.0)
		CardTier.LEGENDARY: return Color(1.0, 0.8, 0.0)
	return Color.WHITE
