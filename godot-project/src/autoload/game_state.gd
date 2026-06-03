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

# --- Persistent economy (Phase 3, M3) ---
# The bench of owned instances, the shard wallet, and the permanent collection
# record. Created eagerly so they're never null; SaveManager loads into them.
var inventory: Inventory
var wallet: Wallet
var binder: Binder


func _ready() -> void:
	character_db = CharacterDatabase.new()
	radical_db = RadicalDatabase.new()
	review_scheduler = ReviewScheduler.new()
	_ensure_economy()
	SignalBus.card_answered.connect(_on_card_answered)


## Create the persistent economy structures if they don't exist yet. Normally
## done in _ready, but to_save_dict / load_from_dict can run on a bare instance
## (tests, load-before-ready), so both call this first.
func _ensure_economy() -> void:
	if inventory == null:
		inventory = Inventory.new()
	if wallet == null:
		wallet = Wallet.new()
	if binder == null:
		binder = Binder.new()


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


## Bank an extracted haul: kept instances go to the bench (and get recorded in
## the permanent binder), the triaged-away ones shatter into shards. Death never
## calls this — a forfeit haul is simply dropped. Returns a small receipt for
## the debrief. Both args are Array[CardInstance].
func bank_haul(kept: Array, shattered: Array) -> Dictionary:
	var banked := 0
	for ci in kept:
		if ci == null:
			continue
		inventory.add(ci)
		binder.record_drop(ci)
		banked += 1
	var shards := 0
	for ci in shattered:
		if ci == null:
			continue
		shards += ci.shard_value()
	wallet.add(shards)
	return { "banked": banked, "shards": shards }


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
	_ensure_economy()
	return {
		"player_hsk_level": player_hsk_level,
		"last_play_date": last_play_date,
		"unlocked_characters": unlocked_characters,
		"cards_answered_today": cards_answered_today,
		"correct_answers_today": correct_answers_today,
		"session_history": session_history,
		# Persistent economy (save schema v2). A v1 save lacks this key; the
		# loader defaults to empty structures, so old saves migrate cleanly.
		"economy": {
			"inventory": inventory.to_dict(),
			"wallet": wallet.to_dict(),
			"binder": binder.to_dict(),
		},
	}


func load_from_dict(data: Dictionary) -> void:
	player_hsk_level = data.get("player_hsk_level", 2)
	last_play_date = data.get("last_play_date", "")
	unlocked_characters = data.get("unlocked_characters", {})
	cards_answered_today = data.get("cards_answered_today", 0)
	correct_answers_today = data.get("correct_answers_today", 0)
	session_history.assign(data.get("session_history", []))

	_ensure_economy()  # guard against load-before-ready / bare-instance tests
	var economy: Dictionary = data.get("economy", {})
	inventory.load_from_dict(economy.get("inventory", {}))
	wallet.load_from_dict(economy.get("wallet", {}))
	binder.load_from_dict(economy.get("binder", {}))
