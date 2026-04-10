## DebugOverlay — In-game HUD showing live debug stats.
## Toggle with F3. Displays FPS, SRS state, and daily review count.
class_name DebugOverlay
extends Control


var _vbox: VBoxContainer
var _fps_label: Label
var _srs_label: Label
var _reviewed_label: Label
var _scheduler_label: Label

var _update_interval: float = 0.25
var _time_since_update: float = 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_ui()
	_connect_signals()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	_vbox = VBoxContainer.new()
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_vbox)

	_fps_label = _create_stat_label("FPS: --")
	_srs_label = _create_stat_label("SRS: --")
	_reviewed_label = _create_stat_label("Reviewed: 0")
	_scheduler_label = _create_stat_label("Due: --")

	# Anchor to top-left corner
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(8.0, 8.0)


func _create_stat_label(initial_text: String) -> Label:
	var lbl := Label.new()
	lbl.text = initial_text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	_vbox.add_child(lbl)
	return lbl


func _connect_signals() -> void:
	SignalBus.card_answered.connect(_on_card_answered)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			toggle_visibility()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return

	_time_since_update += delta
	if _time_since_update >= _update_interval:
		_time_since_update = 0.0
		_refresh_stats()


func toggle_visibility() -> void:
	visible = not visible
	if visible:
		_refresh_stats()


func _refresh_stats() -> void:
	_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	_update_srs_label()
	_update_reviewed_label()
	_update_scheduler_label()


func _update_srs_label() -> void:
	var scheduler: ReviewScheduler = GameState.review_scheduler
	if scheduler == null:
		_srs_label.text = "SRS: no scheduler"
		return

	var total_cards: int = scheduler.card_states.size()
	var new_count: int = 0
	var learning_count: int = 0
	var review_count: int = 0

	for card_id in scheduler.card_states:
		var cs: CardState = scheduler.card_states[card_id]
		var best_state: int = cs.get_best_state()
		match best_state:
			FsrsAlgorithm.State.NEW:
				new_count += 1
			FsrsAlgorithm.State.LEARNING, FsrsAlgorithm.State.RELEARNING:
				learning_count += 1
			FsrsAlgorithm.State.REVIEW:
				review_count += 1

	_srs_label.text = "SRS: %d total | N:%d L:%d R:%d" % [total_cards, new_count, learning_count, review_count]


func _update_reviewed_label() -> void:
	var total: int = GameState.cards_answered_today
	var correct: int = GameState.correct_answers_today
	var accuracy: float = (float(correct) / float(total) * 100.0) if total > 0 else 0.0
	_reviewed_label.text = "Reviewed: %d (%d correct, %.0f%%)" % [total, correct, accuracy]


func _update_scheduler_label() -> void:
	var scheduler: ReviewScheduler = GameState.review_scheduler
	if scheduler == null:
		_scheduler_label.text = "Due: no scheduler"
		return

	var now: float = Time.get_unix_time_from_system()
	var due_cards: Array[CardState] = scheduler.get_due_cards(now)
	var about_to_forget: Array[CardState] = scheduler.get_about_to_forget_cards(now)

	_scheduler_label.text = "Due: %d | Forgetting: %d" % [due_cards.size(), about_to_forget.size()]


# --- Signal handlers ---

func _on_card_answered(_card_data: Dictionary, _challenge_type: String, _correct: bool, _rating: int) -> void:
	if visible:
		_update_reviewed_label()
