## CardDisplay — Visual representation of a character card.
## Handles card appearance, animations, and loot rarity effects.
class_name CardDisplay
extends Control

signal animation_finished()

var card_data: CharacterData
var loot_rarity: SrsEnums.LootRarity = SrsEnums.LootRarity.COMMON
var visual_state: CardVisualState

var _tween: Tween

@onready var _character_label: Label = $CharacterLabel if has_node("CharacterLabel") else null
@onready var _prompt_label: Label = $PromptLabel if has_node("PromptLabel") else null
@onready var _pinyin_label: Label = $PinyinLabel if has_node("PinyinLabel") else null
@onready var _rarity_border: Panel = $RarityBorder if has_node("RarityBorder") else null


func setup(data: CharacterData, rarity: SrsEnums.LootRarity) -> void:
	card_data = data
	loot_rarity = rarity
	_update_display()


func setup_for_challenge(data: CharacterData, challenge_type: String, rarity: SrsEnums.LootRarity) -> void:
	card_data = data
	loot_rarity = rarity

	# Show different info based on challenge type
	if _character_label:
		match challenge_type:
			"meaning":
				_character_label.text = data.character
			"character":
				_character_label.text = data.meaning
			"pinyin":
				_character_label.text = data.character
			"tone":
				_character_label.text = data.get_base_pinyin()
			_:
				_character_label.text = data.character

	if _pinyin_label:
		_pinyin_label.visible = challenge_type != "pinyin" and challenge_type != "tone"
		if _pinyin_label.visible:
			_pinyin_label.text = data.pinyin

	_apply_rarity_style()


func _update_display() -> void:
	if card_data == null:
		return
	if _character_label:
		_character_label.text = card_data.character
	if _pinyin_label:
		_pinyin_label.text = card_data.pinyin
	_apply_rarity_style()


func _apply_rarity_style() -> void:
	if _rarity_border == null:
		return
	var color := Color.WHITE
	match loot_rarity:
		SrsEnums.LootRarity.COMMON:
			color = Color(0.7, 0.7, 0.7)
		SrsEnums.LootRarity.LEARNING:
			color = Color(0.3, 0.7, 1.0)
		SrsEnums.LootRarity.ABOUT_TO_FORGET:
			color = Color(1.0, 0.4, 0.1)
		SrsEnums.LootRarity.NEW_CARD:
			color = Color(1.0, 0.85, 0.0)

	_rarity_border.modulate = color


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


func show_radical_highlight(radical: String) -> void:
	# Visual cue that a radical was activated
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
