## CardDisplay — The single rendered card during the study interaction.
## ChallengePresenter drives it: present_challenge → setup_for_challenge,
## per-stage bonus rounds re-call setup_for_challenge to swap which field
## is hidden, and the answer feedback methods are called on swipe.
##
## Visibility contract per challenge type — the field being TESTED is
## always hidden so the card never leaks the answer:
##   meaning   → glyph=character, pinyin shown, meaning hidden (it's the answer)
##   character → glyph=meaning,   pinyin hidden (would give it away), meaning hidden
##   pinyin    → glyph=character, pinyin hidden, meaning shown
##   tone      → glyph=character, pinyin=toneless, meaning shown
class_name CardDisplay
extends Control

signal animation_finished()

# LootRarity is the legacy 4-state input from ChallengePresenter; CardTier
# is the canonical 6-tier visual scheme. This table maps the legacy states
# onto the visual tier closest in spirit so the style guide treatment
# applies even before the call sites migrate to CardTier directly.
const _LOOT_TO_TIER := {
	SrsEnums.LootRarity.NEW_CARD: CollectionEnums.CardTier.NEW_CARD,
	SrsEnums.LootRarity.COMMON: CollectionEnums.CardTier.COMMON,
	SrsEnums.LootRarity.LEARNING: CollectionEnums.CardTier.UNCOMMON,
	SrsEnums.LootRarity.ABOUT_TO_FORGET: CollectionEnums.CardTier.RARE,
}

var card_data: CharacterData
var loot_rarity: SrsEnums.LootRarity = SrsEnums.LootRarity.COMMON
var current_challenge_type: String = ""

var _tween: Tween

@onready var _frame: Panel = $Frame if has_node("Frame") else null
@onready var _glyph_label: Label = $Frame/VBox/GlyphLabel if has_node("Frame/VBox/GlyphLabel") else null
@onready var _pinyin_label: Label = $Frame/VBox/PinyinLabel if has_node("Frame/VBox/PinyinLabel") else null
@onready var _meaning_label: Label = $Frame/VBox/MeaningLabel if has_node("Frame/VBox/MeaningLabel") else null
@onready var _tier_label: Label = $Frame/TierLabel if has_node("Frame/TierLabel") else null


## Show the full card (no field hidden). Used for reveal states; not
## currently called during the challenge flow.
func setup(data: CharacterData, rarity: SrsEnums.LootRarity) -> void:
	card_data = data
	loot_rarity = rarity
	current_challenge_type = ""
	_show_full()
	_apply_tier_style()


## Configure for a challenge — hides the field being tested. See class
## docstring for the per-type visibility table.
func setup_for_challenge(data: CharacterData, challenge_type: String, rarity: SrsEnums.LootRarity) -> void:
	card_data = data
	loot_rarity = rarity
	current_challenge_type = challenge_type
	if data == null:
		return
	_apply_challenge_visibility(data, challenge_type)
	_apply_tier_style()


func _show_full() -> void:
	if card_data == null:
		return
	if _glyph_label:
		_glyph_label.text = card_data.character
		_glyph_label.visible = true
	if _pinyin_label:
		_pinyin_label.text = card_data.pinyin
		_pinyin_label.visible = true
	if _meaning_label:
		_meaning_label.text = card_data.meaning
		_meaning_label.visible = true


func _apply_challenge_visibility(data: CharacterData, challenge_type: String) -> void:
	var plan := compute_field_state(data, challenge_type)
	if plan.is_empty():
		return
	if _glyph_label:
		_glyph_label.text = plan["glyph_text"]
		_glyph_label.visible = plan["glyph_visible"]
	if _pinyin_label:
		_pinyin_label.text = plan["pinyin_text"]
		_pinyin_label.visible = plan["pinyin_visible"]
	if _meaning_label:
		_meaning_label.text = plan["meaning_text"]
		_meaning_label.visible = plan["meaning_visible"]


## Pure helper: returns the visibility/text plan for a challenge type.
## Extracted so the visibility contract can be tested without instantiating
## the scene (the @onready labels need a scene tree to resolve).
static func compute_field_state(data: CharacterData, challenge_type: String) -> Dictionary:
	if data == null:
		return {}
	# "meaning" challenge layout is the default; each branch overrides.
	var glyph_text := data.character
	var glyph_visible := true
	var pinyin_text := data.pinyin
	var pinyin_visible := true
	var meaning_text := data.meaning
	var meaning_visible := false

	match challenge_type:
		"meaning":
			pass
		"character":
			# Meaning IS the prompt; both character and pinyin would leak
			# the answer when 4 character options share readings.
			glyph_text = data.meaning
			pinyin_visible = false
			meaning_visible = false
		"pinyin":
			pinyin_visible = false
			meaning_visible = true
		"tone":
			pinyin_text = data.get_base_pinyin()
			meaning_visible = true

	return {
		"glyph_text": glyph_text,
		"glyph_visible": glyph_visible,
		"pinyin_text": pinyin_text,
		"pinyin_visible": pinyin_visible,
		"meaning_text": meaning_text,
		"meaning_visible": meaning_visible,
	}


## Apply the canonical tier visual (frame StyleBox + tier label accent).
## Sourced from the design system via CardTierStyler. Use this from new code;
## legacy callers still flow through setup() / setup_for_challenge() which
## translate LootRarity to CardTier internally.
func apply_tier(tier: CollectionEnums.CardTier) -> void:
	if _frame:
		_frame.add_theme_stylebox_override("panel", CardTierStyler.style_for(tier))
	if _tier_label:
		_tier_label.text = CardTierStyler.label_for(tier)
		_tier_label.add_theme_color_override("font_color", CardTierStyler.accent_for(tier))
		_tier_label.add_theme_font_size_override("font_size", CardTierStyler.tier_label_font_size(tier))
		var badge: StyleBox = CardTierStyler.tier_label_badge_for(tier)
		if badge != null:
			_tier_label.add_theme_stylebox_override("normal", badge)
		else:
			_tier_label.remove_theme_stylebox_override("normal")


func _apply_tier_style() -> void:
	var tier: int = _LOOT_TO_TIER.get(loot_rarity, CollectionEnums.CardTier.COMMON)
	apply_tier(tier)


# -- Feedback / animations (driven by ChallengePresenter) --

func show_correct_feedback() -> void:
	_kill_tween()
	_tween = create_tween()
	modulate = Color(0.2, 1.0, 0.2)
	_tween.tween_property(self, "modulate", Color.WHITE, 0.3)


func show_wrong_feedback() -> void:
	_kill_tween()
	_tween = create_tween()
	var orig_pos := position
	modulate = Color(1.0, 0.2, 0.2)
	_tween.tween_property(self, "position", orig_pos + Vector2(10, 0), 0.05)
	_tween.tween_property(self, "position", orig_pos - Vector2(10, 0), 0.05)
	_tween.tween_property(self, "position", orig_pos, 0.05)
	_tween.tween_property(self, "modulate", Color.WHITE, 0.2)


func show_srs_rare_effect() -> void:
	_kill_tween()
	_tween = create_tween().set_loops(3)
	_tween.tween_property(self, "modulate:a", 0.6, 0.3)
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)


func show_radical_highlight(_radical: String) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.15)


func show_new_discovery_effect() -> void:
	_kill_tween()
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)


func animate_card_in() -> void:
	_kill_tween()
	var target_pos := position
	position.y += 100
	modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position", target_pos, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	_tween.chain().tween_callback(animation_finished.emit)


func animate_card_out(direction: Vector2) -> void:
	_kill_tween()
	var target := position + direction * 500
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position", target, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_tween.chain().tween_callback(animation_finished.emit)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
