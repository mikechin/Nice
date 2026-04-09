## CardInspector — Debug panel showing a selected card's full SRS state.
## Displays per-challenge-type details: stability, difficulty, state, last_review, retrievability.
class_name CardInspector
extends Control


var _current_card_id: String = ""

var _title_label: Label
var _vbox: VBoxContainer
var _type_labels: Dictionary = {}  # challenge_type_string -> Dictionary of Labels

const CHALLENGE_TYPES: Array[String] = ["meaning", "character", "pinyin", "tone"]


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	_vbox = VBoxContainer.new()
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_vbox)

	_title_label = Label.new()
	_title_label.text = "Card Inspector"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_title_label)

	# Add a separator
	_vbox.add_child(HSeparator.new())

	# Create label groups for each challenge type
	for ct_str in CHALLENGE_TYPES:
		var header := Label.new()
		header.text = ct_str.capitalize()
		header.add_theme_font_size_override("font_size", 15)
		header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_vbox.add_child(header)

		var labels := {}
		labels["state"] = _add_detail_label("  State: --")
		labels["stability"] = _add_detail_label("  Stability: --")
		labels["difficulty"] = _add_detail_label("  Difficulty: --")
		labels["last_review"] = _add_detail_label("  Last Review: --")
		labels["retrievability"] = _add_detail_label("  Retrievability: --")
		labels["due"] = _add_detail_label("  Due: --")
		labels["reps"] = _add_detail_label("  Reps: --")
		labels["lapses"] = _add_detail_label("  Lapses: --")

		_type_labels[ct_str] = labels

	# Add tier summary at bottom
	_vbox.add_child(HSeparator.new())
	_type_labels["_summary"] = {
		"tier": _add_detail_label("Tier: --"),
		"avg_retrievability": _add_detail_label("Avg Retrievability: --"),
		"weakest": _add_detail_label("Weakest Type: --"),
	}

	# Anchor to top-right corner
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-320.0, 8.0)


func _add_detail_label(initial_text: String) -> Label:
	var lbl := Label.new()
	lbl.text = initial_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(lbl)
	return lbl


## Inspect a card by its ID, pulling SRS state from GameState.
func inspect_card(card_id: String) -> void:
	_current_card_id = card_id
	visible = true

	var scheduler: ReviewScheduler = GameState.review_scheduler
	if scheduler == null or card_id not in scheduler.card_states:
		_title_label.text = "Card Inspector: %s (not found)" % card_id
		_clear_detail_labels()
		return

	var cs: CardState = scheduler.card_states[card_id]
	var now: float = Time.get_unix_time_from_system()

	_title_label.text = "Card Inspector: %s [%s]" % [cs.character, card_id]

	for ct_str in CHALLENGE_TYPES:
		var labels: Dictionary = _type_labels[ct_str]
		var state_dict: Dictionary = cs.get_state_for_type(ct_str)

		var srs_state: int = state_dict.get("state", FsrsAlgorithm.State.NEW)
		var stability: float = state_dict.get("stability", 0.0)
		var difficulty: float = state_dict.get("difficulty", 0.0)
		var last_review: float = state_dict.get("last_review", 0.0)
		var reps: int = state_dict.get("reps", 0)
		var lapses: int = state_dict.get("lapses", 0)
		var retrievability: float = cs.get_retrievability(ct_str, now)
		var is_due: bool = cs.is_due(ct_str, now)

		labels["state"].text = "  State: %s" % _state_name(srs_state)
		labels["stability"].text = "  Stability: %.3f days" % stability
		labels["difficulty"].text = "  Difficulty: %.2f / 10" % difficulty
		labels["last_review"].text = "  Last Review: %s" % _format_timestamp(last_review)
		labels["retrievability"].text = "  Retrievability: %.1f%%" % (retrievability * 100.0)
		labels["due"].text = "  Due: %s" % ("YES" if is_due else "no")
		labels["reps"].text = "  Reps: %d" % reps
		labels["lapses"].text = "  Lapses: %d" % lapses

		# Color-code retrievability
		if srs_state == FsrsAlgorithm.State.NEW:
			labels["retrievability"].add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		elif retrievability < SrsConfig.ABOUT_TO_FORGET_THRESHOLD:
			labels["retrievability"].add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		elif retrievability >= SrsConfig.WELL_KNOWN_THRESHOLD:
			labels["retrievability"].add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		else:
			labels["retrievability"].add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

	# Summary
	var summary: Dictionary = _type_labels["_summary"]
	var tier: CollectionEnums.CardTier = CardTierCalculator.calculate_tier(cs)
	var avg_r: float = cs.get_average_retrievability(now)
	var weakest: String = cs.get_weakest_challenge_type()

	summary["tier"].text = "Tier: %s" % CollectionEnums.tier_name(tier)
	summary["tier"].add_theme_color_override("font_color", CollectionEnums.tier_color(tier))
	summary["avg_retrievability"].text = "Avg Retrievability: %.1f%%" % (avg_r * 100.0)
	summary["weakest"].text = "Weakest Type: %s" % weakest.capitalize()


## Clear all displayed data.
func clear() -> void:
	_current_card_id = ""
	_title_label.text = "Card Inspector"
	_clear_detail_labels()
	visible = false


func _clear_detail_labels() -> void:
	for ct_str in CHALLENGE_TYPES:
		var labels: Dictionary = _type_labels[ct_str]
		for key in labels:
			labels[key].text = "  %s: --" % key.capitalize()

	if "_summary" in _type_labels:
		var summary: Dictionary = _type_labels["_summary"]
		summary["tier"].text = "Tier: --"
		summary["avg_retrievability"].text = "Avg Retrievability: --"
		summary["weakest"].text = "Weakest Type: --"


func _state_name(state: int) -> String:
	match state:
		FsrsAlgorithm.State.NEW: return "New"
		FsrsAlgorithm.State.LEARNING: return "Learning"
		FsrsAlgorithm.State.REVIEW: return "Review"
		FsrsAlgorithm.State.RELEARNING: return "Relearning"
	return "Unknown"


func _format_timestamp(unix_time: float) -> String:
	if unix_time <= 0.0:
		return "never"
	var dt := Time.get_datetime_dict_from_unix_time(int(unix_time))
	return "%04d-%02d-%02d %02d:%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"]]
