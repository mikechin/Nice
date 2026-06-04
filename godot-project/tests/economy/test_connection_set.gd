## Tests for ConnectionSet — validating + classifying the linguistic family you
## craft a grade along. Uses real HSK character families (the 青 phonetic series,
## the 氵 water radical) so the axis detection is exercised on genuine data shapes.
extends GdUnitTestSuite


func _cd(character: String, pinyin: String, tone: int, radicals: Array = [], components: Array = [], is_radical: bool = false) -> CharacterData:
	return CharacterData.from_dict({
		"character": character,
		"pinyin": pinyin,
		"tone": tone,
		"radicals": radicals,
		"components": components,
		"is_radical": is_radical,
	})


# The 青 phonetic series — the prestige craft.
func _qing_target() -> CharacterData: return _cd("请", "qǐng", 3, ["讠"], ["讠", "青"])
func _qing_family() -> Array:
	return [
		_cd("清", "qīng", 1, ["氵"], ["氵", "青"]),
		_cd("晴", "qíng", 2, ["日"], ["日", "青"]),
		_cd("情", "qíng", 2, ["忄"], ["忄", "青"]),
	]

# The 氵 water radical family.
func _water_target() -> CharacterData: return _cd("河", "hé", 2, ["氵"], ["氵", "可"])
func _water_family() -> Array:
	return [
		_cd("海", "hǎi", 3, ["氵"], ["氵", "每"]),
		_cd("江", "jiāng", 1, ["氵"], ["氵", "工"]),
		_cd("湖", "hú", 2, ["氵"], ["氵", "胡"]),
	]


func test_phonetic_series_is_top_band_load() -> void:
	var res := ConnectionSet.classify(_qing_target(), _qing_family())
	assert_bool(res["valid"]).is_true()
	assert_int(res["axis"]).is_equal(ConnectionSet.Axis.PHONETIC)
	assert_float(res["band_load"]).is_equal(1.0)


func test_phonetic_wins_over_homophone_when_both_apply() -> void:
	# The 青 family also shares a base pinyin (qing), but phonetic series is the
	# more prestigious axis and must be the one chosen.
	var axes := ConnectionSet.pair_axes(_qing_target(), _qing_family()[0])
	assert_bool(ConnectionSet.Axis.PHONETIC in axes).is_true()
	assert_bool(ConnectionSet.Axis.HOMOPHONE in axes).is_true()
	var res := ConnectionSet.classify(_qing_target(), _qing_family())
	assert_int(res["axis"]).is_equal(ConnectionSet.Axis.PHONETIC)   # not HOMOPHONE


func test_shared_radical_classifies_as_radical() -> void:
	var res := ConnectionSet.classify(_water_target(), _water_family())
	assert_bool(res["valid"]).is_true()
	assert_int(res["axis"]).is_equal(ConnectionSet.Axis.RADICAL)
	assert_float(res["band_load"]).is_equal(0.6)


func test_tone_alone_is_not_a_connection() -> void:
	# Tone is too broad to author a craft (only ~5 tones exist). A set that shares
	# ONLY tone — same tone 4, no homophone/radical/phonetic link — is no longer
	# assemblable; pair_axes never returns a tone axis.
	var target := _cd("大", "dà", 4)
	var family := [
		_cd("看", "kàn", 4, ["目"], ["目", "看"]),
		_cd("住", "zhù", 4, ["亻"], ["亻", "主"]),
		_cd("路", "lù", 4, ["足"], ["足", "各"]),
	]
	assert_array(ConnectionSet.pair_axes(target, family[0])).is_empty()
	var res := ConnectionSet.classify(target, family)
	assert_bool(res["valid"]).is_false()
	assert_int(res["axis"]).is_equal(ConnectionSet.Axis.NONE)
	assert_str(res["reason"]).is_not_empty()


func test_no_common_connection_is_invalid() -> void:
	var target := _cd("大", "dà", 4)
	var family := [
		_cd("看", "kàn", 4),          # same tone, but tone is no longer an axis
		_cd("好", "hǎo", 3),          # shares nothing
		_cd("学", "xué", 2),
	]
	var res := ConnectionSet.classify(target, family)
	assert_bool(res["valid"]).is_false()
	assert_int(res["axis"]).is_equal(ConnectionSet.Axis.NONE)
	assert_str(res["reason"]).is_not_empty()


func test_wrong_ingredient_count_is_invalid() -> void:
	var res := ConnectionSet.classify(_water_target(), [_cd("海", "hǎi", 3, ["氵"])])
	assert_bool(res["valid"]).is_false()
	assert_str(res["reason"]).contains("exactly 3")


func test_axis_name_for_display() -> void:
	assert_str(ConnectionSet.axis_name(ConnectionSet.Axis.PHONETIC)).is_equal("phonetic series")
	assert_str(ConnectionSet.axis_name(ConnectionSet.Axis.RADICAL)).is_equal("radical")
	assert_str(ConnectionSet.axis_name(ConnectionSet.Axis.NONE)).is_equal("none")
