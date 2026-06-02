## Tests for CardDisplay — smoke tests on the script + the
## compute_field_state helper that drives the per-challenge visibility
## contract. The static helper is testable without a scene tree; the
## live label rendering is covered manually in-editor.
extends GdUnitTestSuite

var _card: CharacterData


func before_test() -> void:
	_card = CharacterData.from_dict({
		"character": "好", "pinyin": "hǎo", "tone": 3,
		"meaning": "good", "hsk_level": 2, "radicals": ["女", "子"],
	})


# -- smoke --

func test_card_display_is_control() -> void:
	var display := CardDisplay.new()
	assert_bool(display is Control).is_true()
	display.free()


func test_default_loot_rarity() -> void:
	var display := CardDisplay.new()
	assert_int(display.loot_rarity).is_equal(SrsEnums.LootRarity.COMMON)
	display.free()


func test_has_animation_signal() -> void:
	var display := CardDisplay.new()
	assert_bool(display.has_signal("animation_finished")).is_true()
	display.free()


# -- field-visibility plan: meaning challenge --

func test_meaning_challenge_hides_meaning_keeps_pinyin() -> void:
	var plan := CardDisplay.compute_field_state(_card, "meaning")
	assert_str(plan["glyph_text"]).is_equal("好")
	assert_bool(plan["glyph_visible"]).is_true()
	assert_str(plan["pinyin_text"]).is_equal("hǎo")
	assert_bool(plan["pinyin_visible"]).is_true()
	assert_bool(plan["meaning_visible"]).is_false()


# -- field-visibility plan: character challenge --

func test_character_challenge_shows_meaning_hides_glyph_and_pinyin() -> void:
	var plan := CardDisplay.compute_field_state(_card, "character")
	# The meaning becomes the prompt focal point.
	assert_str(plan["glyph_text"]).is_equal("good")
	assert_bool(plan["glyph_visible"]).is_true()
	# Pinyin would give the answer away when picking from 4 character
	# options with distinct readings.
	assert_bool(plan["pinyin_visible"]).is_false()
	# Meaning is already shown via glyph slot — don't double up.
	assert_bool(plan["meaning_visible"]).is_false()


# -- field-visibility plan: pinyin challenge --

func test_pinyin_challenge_hides_pinyin_shows_character_and_meaning() -> void:
	var plan := CardDisplay.compute_field_state(_card, "pinyin")
	assert_str(plan["glyph_text"]).is_equal("好")
	assert_bool(plan["pinyin_visible"]).is_false()
	assert_str(plan["meaning_text"]).is_equal("good")
	assert_bool(plan["meaning_visible"]).is_true()


# -- field-visibility plan: tone challenge --

func test_tone_challenge_strips_tone_marks_from_pinyin() -> void:
	var plan := CardDisplay.compute_field_state(_card, "tone")
	assert_str(plan["glyph_text"]).is_equal("好")
	assert_bool(plan["pinyin_visible"]).is_true()
	# "hǎo" → "hao": tone marks stripped so the player has to choose.
	assert_str(plan["pinyin_text"]).is_equal("hao")
	assert_bool(plan["meaning_visible"]).is_true()


# -- defensive --

func test_null_data_returns_empty_plan() -> void:
	var plan := CardDisplay.compute_field_state(null, "meaning")
	assert_bool(plan.is_empty()).is_true()


func test_unknown_challenge_type_falls_back_to_meaning_layout() -> void:
	# Unrecognized types use the default "meaning" layout (character
	# visible, pinyin visible, meaning hidden) — safer than throwing.
	var plan := CardDisplay.compute_field_state(_card, "unknown")
	assert_str(plan["glyph_text"]).is_equal("好")
	assert_bool(plan["pinyin_visible"]).is_true()
	assert_bool(plan["meaning_visible"]).is_false()
