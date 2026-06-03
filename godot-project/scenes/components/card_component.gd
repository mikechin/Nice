## CardComponent — Reusable card UI wrapping CardDisplay for use in scenes.
## Shows a character card with rarity styling and answer labels in four directions.
class_name CardComponent
extends Control

signal card_setup_complete()

@onready var _card_display: CardDisplay = $CardDisplay if has_node("CardDisplay") else null
@onready var _character_label: Label = $CharacterLabel if has_node("CharacterLabel") else null
@onready var _pinyin_label: Label = $PinyinLabel if has_node("PinyinLabel") else null
@onready var _meaning_label: Label = $MeaningLabel if has_node("MeaningLabel") else null
@onready var _rarity_panel: Panel = $RarityPanel if has_node("RarityPanel") else null
@onready var _tier_label: Label = $TierLabel if has_node("TierLabel") else null

var _card_data: CharacterData
var _rarity: SrsEnums.LootRarity = SrsEnums.LootRarity.KNOWN
var _current_answers: Dictionary = {}


func _ready() -> void:
	_warn_missing_nodes()


func setup(card_data: CharacterData, rarity: SrsEnums.LootRarity = SrsEnums.LootRarity.KNOWN) -> void:
	_card_data = card_data
	_rarity = rarity

	if _card_display:
		_card_display.setup(card_data, rarity)
	else:
		_update_labels()

	_apply_rarity_style()
	card_setup_complete.emit()


func setup_for_challenge(card_data: CharacterData, challenge_type: String, rarity: SrsEnums.LootRarity) -> void:
	_card_data = card_data
	_rarity = rarity

	if _card_display:
		_card_display.setup_for_challenge(card_data, challenge_type, rarity)
	else:
		# Manual setup based on challenge type
		if _character_label:
			match challenge_type:
				"meaning":
					_character_label.text = card_data.character
				"character":
					_character_label.text = card_data.meaning
				"pinyin":
					_character_label.text = card_data.character
				"tone":
					_character_label.text = card_data.get_base_pinyin()
				_:
					_character_label.text = card_data.character
		if _pinyin_label:
			_pinyin_label.visible = challenge_type != "pinyin" and challenge_type != "tone"
			if _pinyin_label.visible:
				_pinyin_label.text = card_data.pinyin
		_apply_rarity_style()


func show_answer_labels(answers: Dictionary) -> void:
	_current_answers = answers


func show_correct_feedback() -> void:
	if _card_display:
		_card_display.show_correct_feedback()
	else:
		_flash_color(Color(0.2, 1.0, 0.2))


func show_wrong_feedback() -> void:
	if _card_display:
		_card_display.show_wrong_feedback()
	else:
		_flash_color(Color(1.0, 0.2, 0.2))


func get_card_data() -> CharacterData:
	return _card_data


func get_rarity() -> SrsEnums.LootRarity:
	return _rarity


func _update_labels() -> void:
	if _card_data == null:
		return
	if _character_label:
		_character_label.text = _card_data.character
	if _pinyin_label:
		_pinyin_label.text = _card_data.pinyin
	if _meaning_label:
		_meaning_label.text = _card_data.meaning


func _apply_rarity_style() -> void:
	var color := Color.WHITE
	match _rarity:
		SrsEnums.LootRarity.KNOWN:
			color = Color(0.7, 0.7, 0.7)
		SrsEnums.LootRarity.LEARNING:
			color = Color(0.3, 0.7, 1.0)
		SrsEnums.LootRarity.ABOUT_TO_FORGET:
			color = Color(1.0, 0.4, 0.1)
		SrsEnums.LootRarity.NEW_CARD:
			color = Color(1.0, 0.85, 0.0)

	if _rarity_panel:
		_rarity_panel.modulate = color
	if _tier_label:
		_tier_label.add_theme_color_override("font_color", color)


func _flash_color(color: Color) -> void:
	var tween := create_tween()
	modulate = color
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)


func _warn_missing_nodes() -> void:
	if _card_display == null:
		push_warning("card_component.gd: missing node _card_display")
	if _character_label == null:
		push_warning("card_component.gd: missing node _character_label")
	if _pinyin_label == null:
		push_warning("card_component.gd: missing node _pinyin_label")
	if _meaning_label == null:
		push_warning("card_component.gd: missing node _meaning_label")
	if _rarity_panel == null:
		push_warning("card_component.gd: missing node _rarity_panel")
	if _tier_label == null:
		push_warning("card_component.gd: missing node _tier_label")
