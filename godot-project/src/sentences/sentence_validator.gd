## SentenceValidator — Checks if a built sentence is valid Chinese.
## Uses pre-built valid sentence database for MVP.
class_name SentenceValidator
extends RefCounted

var sentence_db: SentenceDatabase


func _init(db: SentenceDatabase = null) -> void:
	sentence_db = db


## Check if a sentence exactly matches a known valid sentence.
func validate(sentence: String) -> Dictionary:
	if sentence_db == null:
		return {"valid": false, "score": 0, "feedback": "No sentence database loaded"}

	# Check all levels for a match
	for level in range(2, 6):
		var sentences := sentence_db.get_sentences_for_level(level)
		for s in sentences:
			if s.get("sentence", "") == sentence:
				return {
					"valid": true,
					"score": _calculate_base_score(s),
					"feedback": s.get("meaning", ""),
					"sentence_data": s,
				}

	# Partial match — check if it's a valid substring
	var partial := _check_partial_match(sentence)
	if partial["found"]:
		return {
			"valid": false,
			"score": 0,
			"feedback": "Almost! Keep going: %s" % partial["hint"],
		}

	return {"valid": false, "score": 0, "feedback": "Not a recognized sentence"}


func validate_fill_blank(sentence: String, blank_position: int, answer: String) -> bool:
	# Reconstruct full sentence and check against database
	var chars: Array = []
	for ch in sentence:
		chars.append(ch)
	if blank_position >= 0 and blank_position < chars.size():
		chars[blank_position] = answer
	var full := "".join(chars)
	var result := validate(full)
	return result.get("valid", false)


func validate_scramble(original: String, player_answer: String) -> bool:
	return player_answer == original


func validate_free_build(meaning: String, player_sentence: String) -> bool:
	# Check if any sentence with this meaning matches
	if sentence_db == null:
		return false
	for level in range(2, 6):
		for s in sentence_db.get_sentences_for_level(level):
			if s.get("meaning", "") == meaning and s.get("sentence", "") == player_sentence:
				return true
	return false


func _calculate_base_score(sentence_data: Dictionary) -> int:
	var character_count: int = sentence_data.get("character_count", 0)
	return character_count * 15 + 50


func _check_partial_match(sentence: String) -> Dictionary:
	if sentence_db == null:
		return {"found": false}
	for level in range(2, 6):
		for s in sentence_db.get_sentences_for_level(level):
			var full: String = s.get("sentence", "")
			if full.begins_with(sentence) and full.length() > sentence.length():
				return {"found": true, "hint": full}
	return {"found": false}
