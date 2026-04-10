## GameState — Global game state singleton.
## Tracks player profile, current run state, and session data.
class_name GameStateClass
extends Node

# --- Player Profile ---
var player_hsk_level: int = 2
var total_coins: int = 0
var daily_streak: int = 0
var last_play_date: String = ""
var equipped_radicals: Array[String] = []
var owned_radicals: Array[String] = []
var unlocked_characters: Dictionary = {}  # character -> true

# --- Current Run State ---
var is_in_run: bool = false
var current_run_type: String = ""  # "easy" or "challenge"
var run_coins_earned: int = 0
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


func start_run(run_type: String) -> void:
	is_in_run = true
	current_run_type = run_type
	run_coins_earned = 0
	last_run_summary.clear()
	SignalBus.run_started.emit(run_type)


func end_run(summary: Dictionary = {}) -> void:
	total_coins += run_coins_earned

	last_run_summary = summary.duplicate()
	last_run_summary["run_type"] = current_run_type
	last_run_summary["coins"] = run_coins_earned

	is_in_run = false
	current_run_type = ""
	current_pack = null
	SignalBus.run_ended.emit(last_run_summary)


func add_coins(amount: int) -> void:
	if is_in_run:
		run_coins_earned += amount
	else:
		total_coins += amount
	SignalBus.coins_changed.emit(amount, total_coins + (run_coins_earned if is_in_run else 0))


func spend_coins(amount: int) -> bool:
	if total_coins < amount:
		return false
	total_coins -= amount
	SignalBus.coins_changed.emit(-amount, total_coins)
	return true


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
		"total_coins": total_coins,
		"daily_streak": daily_streak,
		"last_play_date": last_play_date,
		"equipped_radicals": equipped_radicals,
		"owned_radicals": owned_radicals,
		"unlocked_characters": unlocked_characters,
		"cards_answered_today": cards_answered_today,
		"correct_answers_today": correct_answers_today,
		"session_history": session_history,
	}


func load_from_dict(data: Dictionary) -> void:
	player_hsk_level = data.get("player_hsk_level", 2)
	total_coins = data.get("total_coins", 0)
	daily_streak = data.get("daily_streak", 0)
	last_play_date = data.get("last_play_date", "")
	equipped_radicals.assign(data.get("equipped_radicals", []))
	owned_radicals.assign(data.get("owned_radicals", []))
	unlocked_characters = data.get("unlocked_characters", {})
	cards_answered_today = data.get("cards_answered_today", 0)
	correct_answers_today = data.get("correct_answers_today", 0)
	session_history.assign(data.get("session_history", []))
