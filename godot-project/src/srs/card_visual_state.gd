## CardVisualState — Resource describing a card's current visual presentation.
## Derived from SRS state by CardTierCalculator. Used by UI to render cards.
class_name CardVisualState
extends Resource

@export var card_id: String = ""
@export var tier: CollectionEnums.CardTier = CollectionEnums.CardTier.LOCKED
@export var glow_intensity: float = 0.0
@export var particle_enabled: bool = false
@export var border_color: Color = Color.WHITE
@export var background_style: String = "default"
@export var animation_id: String = ""
@export var is_foil: bool = false

static func locked(character: String) -> CardVisualState:
	var vs := CardVisualState.new()
	vs.card_id = character
	vs.tier = CollectionEnums.CardTier.LOCKED
	vs.border_color = CollectionEnums.tier_color(CollectionEnums.CardTier.LOCKED)
	vs.background_style = "locked"
	return vs

static func for_tier(character: String, tier: CollectionEnums.CardTier) -> CardVisualState:
	var vs := CardVisualState.new()
	vs.card_id = character
	vs.tier = tier
	vs.border_color = CollectionEnums.tier_color(tier)
	match tier:
		CollectionEnums.CardTier.RARE:
			vs.glow_intensity = 0.3
			vs.background_style = "rare"
		CollectionEnums.CardTier.EPIC:
			vs.glow_intensity = 0.6
			vs.particle_enabled = true
			vs.background_style = "epic"
			vs.animation_id = "epic_idle"
		CollectionEnums.CardTier.LEGENDARY:
			vs.glow_intensity = 1.0
			vs.particle_enabled = true
			vs.background_style = "legendary"
			vs.animation_id = "legendary_idle"
		_:
			vs.background_style = "default"
	return vs
