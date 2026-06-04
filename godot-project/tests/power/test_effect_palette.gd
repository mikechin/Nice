## Tests for EffectPalette — character → EffectKind by meaning (M5). Locks the
## resolution order (curated field > override > keyword > deterministic fallback)
## and that EVERY character resolves to some kind (no blanks, no crashes).
extends GdUnitTestSuite


func _cd(character: String, meaning: String, effect: String = "") -> CharacterData:
	return CharacterData.from_dict({"character": character, "meaning": meaning, "effect": effect})


func test_iconic_overrides() -> void:
	assert_int(EffectPalette.kind_for(_cd("火", "fire"))).is_equal(EffectEnums.Kind.BURN)
	assert_int(EffectPalette.kind_for(_cd("水", "water"))).is_equal(EffectEnums.Kind.MEND)
	assert_int(EffectPalette.kind_for(_cd("大", "big"))).is_equal(EffectEnums.Kind.STRIKE)
	assert_int(EffectPalette.kind_for(_cd("安", "safe, peaceful"))).is_equal(EffectEnums.Kind.WARD)
	assert_int(EffectPalette.kind_for(_cd("心", "heart"))).is_equal(EffectEnums.Kind.FOCUS)
	assert_int(EffectPalette.kind_for(_cd("快", "fast"))).is_equal(EffectEnums.Kind.SURGE)


func test_keyword_scan_for_non_iconic_chars() -> void:
	# Characters not in the override map fall to a meaning keyword scan.
	assert_int(EffectPalette.kind_for(_cd("跑", "to run"))).is_equal(EffectEnums.Kind.SURGE)
	assert_int(EffectPalette.kind_for(_cd("江", "large river"))).is_equal(EffectEnums.Kind.MEND)
	assert_int(EffectPalette.kind_for(_cd("墙", "wall"))).is_equal(EffectEnums.Kind.WARD)


func test_curated_effect_field_wins_over_meaning() -> void:
	# The future HSK 2–3 curation pass writes `effect`; it must beat override+keyword
	# so a hand-tuned ability isn't second-guessed by the gloss.
	assert_int(EffectPalette.kind_for(_cd("水", "water", "strike"))).is_equal(EffectEnums.Kind.STRIKE)


func test_unmapped_char_gets_a_deterministic_passive_fallback() -> void:
	var a := EffectPalette.kind_for(_cd("蛋", "egg"))
	var b := EffectPalette.kind_for(_cd("蛋", "egg"))
	assert_int(a).is_equal(b)                                   # deterministic
	assert_bool(EffectEnums.is_passive(a)).is_true()            # fallbacks are quiet stat sticks


func test_kind_for_char_without_db_uses_override_then_fallback() -> void:
	assert_int(EffectPalette.kind_for_char("火", null)).is_equal(EffectEnums.Kind.BURN)
	# Unknown glyph, no DB → still resolves (never crashes, never blank).
	var k := EffectPalette.kind_for_char("镕", null)
	assert_bool(k in [EffectEnums.Kind.STRIKE, EffectEnums.Kind.WARD,
		EffectEnums.Kind.FOCUS, EffectEnums.Kind.SURGE]).is_true()


# -- live data integration: the HSK 2–3 curation pass (tools/apply_effects.py) wrote
# an `effect` on every character. These lock that data into CI so a future data regen
# can't silently drop the field and quietly fall back to keyword/code-point guesses.

func test_every_hsk2_3_character_has_a_curated_effect() -> void:
	var chars := DataLoader.load_characters_range(2, 3)
	assert_int(chars.size()).is_greater(300)               # ~310 across the two levels
	var valid := [EffectEnums.Kind.STRIKE, EffectEnums.Kind.WARD, EffectEnums.Kind.FOCUS,
		EffectEnums.Kind.SURGE, EffectEnums.Kind.BURN, EffectEnums.Kind.MEND]
	for cd in chars:
		assert_str(cd.effect).override_failure_message(
			"%s (%s) has no curated effect" % [cd.character, cd.meaning]).is_not_empty()
		# Resolution must honour that curated field and land on a real kind.
		assert_bool(EffectPalette.kind_for(cd) in valid).is_true()


func test_curated_data_drives_resolution_for_known_glyphs() -> void:
	# Spot-check that the written data flows through the live load to the intended kind.
	var by_char := {}
	for cd in DataLoader.load_characters_range(2, 3):
		by_char[cd.character] = cd
	var expected := {
		"火": EffectEnums.Kind.BURN, "灯": EffectEnums.Kind.BURN,
		"门": EffectEnums.Kind.WARD, "安": EffectEnums.Kind.WARD,
		"打": EffectEnums.Kind.STRIKE, "力": EffectEnums.Kind.STRIKE,
		"快": EffectEnums.Kind.SURGE, "跑": EffectEnums.Kind.SURGE,
		"病": EffectEnums.Kind.MEND, "河": EffectEnums.Kind.MEND,
		"知": EffectEnums.Kind.FOCUS, "听": EffectEnums.Kind.FOCUS,
	}
	for ch in expected:
		assert_bool(by_char.has(ch)).override_failure_message("%s missing from data" % ch).is_true()
		assert_int(EffectPalette.kind_for(by_char[ch])).override_failure_message(
			"%s resolved to the wrong kind" % ch).is_equal(expected[ch])
