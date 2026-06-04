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
