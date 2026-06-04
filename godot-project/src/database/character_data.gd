## CharacterData — Resource type for a single HSK character entry.
class_name CharacterData
extends Resource

@export var character: String = ""
@export var pinyin: String = ""
@export var tone: int = 0
@export var meaning: String = ""
@export var hsk_level: int = 2
@export var radicals: Array[String] = []
@export var components: Array[String] = []
@export var is_radical: bool = false
@export var frequency_rank: int = 0
## M5 combat ability, as a curated EffectKind name ("burn"/"mend"/…). Empty means
## "derive from meaning" (EffectPalette). The one-time HSK 2–3 curation pass fills
## this; until then it's blank and the palette's keyword/fallback path is used.
@export var effect: String = ""

static func from_dict(data: Dictionary) -> CharacterData:
	var cd := CharacterData.new()
	cd.character = data.get("character", "")
	cd.pinyin = data.get("pinyin", "")
	cd.tone = data.get("tone", 0)
	cd.meaning = data.get("meaning", "")
	cd.hsk_level = data.get("hsk_level", 2)
	cd.is_radical = data.get("is_radical", false)
	cd.frequency_rank = data.get("frequency_rank", 0)
	cd.effect = data.get("effect", "")

	var raw_radicals: Array = data.get("radicals", [])
	for r in raw_radicals:
		cd.radicals.append(str(r))

	var raw_components: Array = data.get("components", [])
	for c in raw_components:
		cd.components.append(str(c))

	return cd

func to_dict() -> Dictionary:
	return {
		"character": character,
		"pinyin": pinyin,
		"tone": tone,
		"meaning": meaning,
		"hsk_level": hsk_level,
		"radicals": Array(radicals),
		"components": Array(components),
		"is_radical": is_radical,
		"frequency_rank": frequency_rank,
		"effect": effect,
	}

## Get the base pinyin without tone marks (for comparison/grouping).
func get_base_pinyin() -> String:
	var base := pinyin
	var tone_marks := "āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ"
	var plain_chars := "aaaaeeeeiiiioooouuuuüüüü"
	var result := ""
	for ch in base:
		var idx := tone_marks.find(ch)
		if idx >= 0:
			result += plain_chars[idx]
		else:
			result += ch
	return result

## Returns a unique ID used as the key in SRS card states.
func get_card_id() -> String:
	return character
