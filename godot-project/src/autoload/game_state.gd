## GameState — Global game state singleton.
## Tracks player profile, current run state, and session data.
class_name GameStateClass
extends Node

# --- Player Profile ---
var player_hsk_level: int = 2
var last_play_date: String = ""
var unlocked_characters: Dictionary = {}  # character -> true

# --- Current Run State ---
var is_in_run: bool = false
var current_pack: PackData = null
var last_run_summary: Dictionary = {}

# --- Session Stats ---
var cards_answered_today: int = 0
var correct_answers_today: int = 0
var session_history: Array[Dictionary] = []

# --- Databases (loaded once) ---
var character_db: CharacterDatabase
var radical_db: RadicalDatabase
var review_scheduler: ReviewScheduler


func _ready() -> void:
	character_db = CharacterDatabase.new()
	radical_db = RadicalDatabase.new()
	review_scheduler = ReviewScheduler.new()
	SignalBus.card_answered.connect(_on_card_answered)


func initialize_databases() -> void:
	print("[GameState] initialize_databases starting, hsk_level=%d" % player_hsk_level)
	character_db.load_all(2, player_hsk_level)
	print("[GameState] character_db loaded: %d characters" % character_db.get_count())
	radical_db.load_all()
	# Register all characters with the review scheduler
	for cd in character_db.get_all():
		review_scheduler.register_card(cd.character, cd.character)
	print("[GameState] Registered %d cards with review_scheduler" % review_scheduler.card_states.size())


func start_run() -> void:
	is_in_run = true
	last_run_summary.clear()
	SignalBus.run_started.emit()


func end_run(summary: Dictionary = {}) -> void:
	last_run_summary = summary.duplicate()

	is_in_run = false
	current_pack = null
	SignalBus.run_ended.emit(last_run_summary)


func _on_card_answered(_card_data: Dictionary, _challenge_type: String, correct: bool, _rating: int) -> void:
	cards_answered_today += 1
	if correct:
		correct_answers_today += 1


func get_today_date() -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]


func check_daily_reset() -> void:
	var today := get_today_date()
	if today != last_play_date:
		cards_answered_today = 0
		correct_answers_today = 0
		last_play_date = today


func to_save_dict() -> Dictionary:
	return {
		"player_hsk_level": player_hsk_level,
		"last_play_date": last_play_date,
		"unlocked_characters": unlocked_characters,
		"cards_answered_today": cards_answered_today,
		"correct_answers_today": correct_answers_today,
		"session_history": session_history,
	}


func load_from_dict(data: Dictionary) -> void:
	player_hsk_level = data.get("player_hsk_level", 2)
	last_play_date = data.get("last_play_date", "")
	unlocked_characters = data.get("unlocked_characters", {})
	cards_answered_today = data.get("cards_answered_today", 0)
	correct_answers_today = data.get("correct_answers_today", 0)
	session_history.assign(data.get("session_history", []))
