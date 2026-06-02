## CardTierStyler — single source of truth for card tier visual treatment.
##
## Maps a CollectionEnums.CardTier to a StyleBoxFlat (frame fill + border)
## and to the accent color/label used elsewhere on the card. All values
## come from UiTokens so the design system stays coherent.
##
## Tier treatments per docs/design/Style Guide.html:
##   NEW       — cool indigo, attention-grabbing border (the dopamine hit;
##               final flashy treatment incl. badge + pulse is Phase 2)
##   COMMON    — honest baseline: surface bg, hairline outline
##   UNCOMMON  — jade tint, slightly stronger border
##   RARE      — violet depth (corner ornaments are a Phase 2 polish)
##   EPIC      — PLACEHOLDER (mirrors RARE) until visual is signed off
##   LEGENDARY — gold border, deeper amber tint (full ceremony incl.
##               ghost glyph + breathing glow is Phase 2)
class_name CardTierStyler
extends RefCounted


## Build the StyleBoxFlat that paints the card frame for this tier.
static func style_for(tier: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var radius := UiTokens.R_CARD
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.bg_color = bg_color_for(tier)
	sb.border_color = border_color_for(tier)
	var w := border_width_for(tier)
	sb.border_width_left = w
	sb.border_width_right = w
	sb.border_width_top = w
	sb.border_width_bottom = w
	return sb


## Accent hue used for the tier label and any tier-themed text.
static func accent_for(tier: int) -> Color:
	match tier:
		CollectionEnums.CardTier.NEW_CARD:  return UiTokens.RARITY_NEW
		CollectionEnums.CardTier.COMMON:    return UiTokens.RARITY_COMMON
		CollectionEnums.CardTier.UNCOMMON:  return UiTokens.RARITY_UNCOMMON
		CollectionEnums.CardTier.RARE:      return UiTokens.RARITY_RARE
		CollectionEnums.CardTier.EPIC:      return UiTokens.RARITY_EPIC
		CollectionEnums.CardTier.LEGENDARY: return UiTokens.RARITY_LEGENDARY
		_:                                  return UiTokens.RARITY_COMMON


## Display label shown on the card for this tier.
static func label_for(tier: int) -> String:
	match tier:
		CollectionEnums.CardTier.NEW_CARD:  return "NEW"
		CollectionEnums.CardTier.COMMON:    return "Common"
		CollectionEnums.CardTier.UNCOMMON:  return "Uncommon"
		CollectionEnums.CardTier.RARE:      return "Rare"
		CollectionEnums.CardTier.EPIC:      return "Epic"
		CollectionEnums.CardTier.LEGENDARY: return "Legendary"
		_:                                  return ""


static func bg_color_for(tier: int) -> Color:
	# Each tier mixes the SURFACE base with its rarity hue; richer tiers get a stronger tint.
	return UiTokens.SURFACE.lerp(accent_for(tier), _bg_mix_strength(tier))


static func border_color_for(tier: int) -> Color:
	if tier == CollectionEnums.CardTier.COMMON:
		return UiTokens.HAIRLINE
	return accent_for(tier)


static func border_width_for(tier: int) -> int:
	match tier:
		CollectionEnums.CardTier.COMMON:    return 1
		CollectionEnums.CardTier.UNCOMMON:  return 1
		CollectionEnums.CardTier.NEW_CARD:  return 3  # exciting first-contact
		CollectionEnums.CardTier.RARE:      return 2
		CollectionEnums.CardTier.EPIC:      return 2
		CollectionEnums.CardTier.LEGENDARY: return 3
		_:                                  return 1


## Tier label font size — NEW gets a larger badge so the first-contact
## moment reads loud; other tiers keep a quiet caption-sized label.
static func tier_label_font_size(tier: int) -> int:
	if tier == CollectionEnums.CardTier.NEW_CARD:
		return 16
	return UiTokens.T_CAPTION


## Optional pill-shaped background painted behind the tier label.
## Returned only for NEW (the indigo badge); other tiers render the
## label as plain coloured text.
static func tier_label_badge_for(tier: int) -> StyleBox:
	if tier != CollectionEnums.CardTier.NEW_CARD:
		return null
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.RARITY_NEW.lerp(UiTokens.SURFACE, 0.65)
	sb.border_color = UiTokens.RARITY_NEW
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = UiTokens.R_PILL
	sb.corner_radius_top_right = UiTokens.R_PILL
	sb.corner_radius_bottom_left = UiTokens.R_PILL
	sb.corner_radius_bottom_right = UiTokens.R_PILL
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb


static func _bg_mix_strength(tier: int) -> float:
	match tier:
		CollectionEnums.CardTier.NEW_CARD:  return 0.18  # noticeable indigo wash
		CollectionEnums.CardTier.COMMON:    return 0.0
		CollectionEnums.CardTier.UNCOMMON:  return 0.08
		CollectionEnums.CardTier.RARE:      return 0.12
		CollectionEnums.CardTier.EPIC:      return 0.12
		CollectionEnums.CardTier.LEGENDARY: return 0.14
		_:                                  return 0.0
