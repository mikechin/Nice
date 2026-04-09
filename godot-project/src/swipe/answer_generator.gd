## AnswerGenerator — Creates answer layouts for the four-directional swipe.
## Generates plausible wrong answers and assigns them to directions.
class_name AnswerGenerator
extends RefCounted

var char_db: CharacterDatabase

const DIRECTIONS: Array[String] = ["up", "down", "left", "right"]
const TONE_MARKS: Array[String] = ["ˉ (1st)", "ˊ (2nd)", "ˇ (3rd)", "ˋ (4th)", "· (neutral)"]


func _init(db: CharacterDatabase = null) -> void:
	char_db = db


## Generate a full answer layout: 1 correct + 3 wrong, randomly assigned to directions.
## Returns {"up": str, "down": str, "left": str, "right": str, "correct_direction": str}
func generate_answers(card_data: CharacterData, challenge_type: String) -> Dictionary:
	var correct_answer := _get_correct_answer(card_data, challenge_type)
	var wrong_answers := _generate_wrong_answers(card_data, challenge_type, 3)

	# Assign to random directions
	var all_answers: Array[String] = [correct_answer]
	all_answers.append_array(wrong_answers)

	var shuffled_dirs := DIRECTIONS.duplicate()
	shuffled_dirs.shuffle()

	var result := {}
	for i in all_answers.size():
		result[shuffled_dirs[i]] = all_answers[i]

	result["correct_direction"] = shuffled_dirs[0]
	result["correct_answer"] = correct_answer
	result["challenge_type"] = challenge_type

	return result


func _get_correct_answer(card_data: CharacterData, challenge_type: String) -> String:
	match challenge_type:
		"meaning":
			return card_data.meaning
		"character":
			return card_data.character
		"pinyin":
			return card_data.pinyin
		"tone":
			return _tone_label(card_data.tone)
	return card_data.meaning


func _generate_wrong_answers(card_data: CharacterData, challenge_type: String, count: int) -> Array[String]:
	match challenge_type:
		"meaning":
			return _generate_wrong_meanings(card_data, count)
		"character":
			return _generate_wrong_characters(card_data, count)
		"pinyin":
			return _generate_wrong_pinyin(card_data, count)
		"tone":
			return _generate_wrong_tones(card_data.tone, count)
	return _generate_wrong_meanings(card_data, count)


func _generate_wrong_meanings(card_data: CharacterData, count: int) -> Array[String]:
	if char_db == null:
		return _fallback_strings(count)

	var result: Array[String] = []
	var seen := {card_data.meaning: true}

	# Strategy 1: Same radical (semantically confusable)
	var same_radical := char_db.get_same_radical_characters(card_data.character)
	same_radical.shuffle()
	for cd in same_radical:
		if result.size() >= count:
			break
		if cd.meaning not in seen:
			result.append(cd.meaning)
			seen[cd.meaning] = true

	# Strategy 2: Same HSK level
	if result.size() < count:
		var same_level := char_db.get_random_same_level(card_data.character, count * 2)
		for cd in same_level:
			if result.size() >= count:
				break
			if cd.meaning not in seen:
				result.append(cd.meaning)
				seen[cd.meaning] = true

	return result


func _generate_wrong_characters(card_data: CharacterData, count: int) -> Array[String]:
	if char_db == null:
		return _fallback_strings(count)

	var result: Array[String] = []
	var seen := {card_data.character: true}

	# Same radical = visually similar
	var same_radical := char_db.get_same_radical_characters(card_data.character)
	same_radical.shuffle()
	for cd in same_radical:
		if result.size() >= count:
			break
		if cd.character not in seen:
			result.append(cd.character)
			seen[cd.character] = true

	# Fallback: same level
	if result.size() < count:
		var same_level := char_db.get_random_same_level(card_data.character, count * 2)
		for cd in same_level:
			if result.size() >= count:
				break
			if cd.character not in seen:
				result.append(cd.character)
				seen[cd.character] = true

	return result


func _generate_wrong_pinyin(card_data: CharacterData, count: int) -> Array[String]:
	if char_db == null:
		return _fallback_strings(count)

	var result: Array[String] = []
	var seen := {card_data.pinyin: true}

	# Similar sounding pinyin (same base)
	var similar := char_db.get_similar_pinyin_characters(card_data.character)
	similar.shuffle()
	for cd in similar:
		if result.size() >= count:
			break
		if cd.pinyin not in seen:
			result.append(cd.pinyin)
			seen[cd.pinyin] = true

	# Same tone (different pinyin)
	if result.size() < count:
		var same_tone := char_db.get_same_tone_characters(card_data.character)
		same_tone.shuffle()
		for cd in same_tone:
			if result.size() >= count:
				break
			if cd.pinyin not in seen:
				result.append(cd.pinyin)
				seen[cd.pinyin] = true

	# Fallback: same level
	if result.size() < count:
		var same_level := char_db.get_random_same_level(card_data.character, count * 2)
		for cd in same_level:
			if result.size() >= count:
				break
			if cd.pinyin not in seen:
				result.append(cd.pinyin)
				seen[cd.pinyin] = true

	return result


func _generate_wrong_tones(correct_tone: int, count: int) -> Array[String]:
	var result: Array[String] = []
	var all_tones := [0, 1, 2, 3, 4]
	all_tones.erase(correct_tone)
	all_tones.shuffle()
	for i in mini(count, all_tones.size()):
		result.append(_tone_label(all_tones[i]))
	return result


func _tone_label(tone: int) -> String:
	if tone >= 0 and tone < TONE_MARKS.size():
		return TONE_MARKS[tone]
	return "· (neutral)"


func _fallback_strings(count: int) -> Array[String]:
	var result: Array[String] = []
	for i in count:
		result.append("???")
	return result
