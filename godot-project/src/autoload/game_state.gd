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
var planet_boosts: Array[String] = []
var unlocked_characters: Dictionary = {}  # character -> true

# --- Tile Inventory ---
## Dictionary of character -> count (e.g., {"我": 5, "你": 3})
var tile_inventory: Dictionary = {}

# --- Current Run State ---
var is_in_run: bool = false
var current_run_type: String = ""  # "easy" or "challenge"
var current_hearts: int = 0
var max_hearts: int = 3
var current_combo: int = 0
var best_combo: int = 0
var run_coins_earned: int = 0
var run_tiles_earned: Dictionary = {}
var current_round: int = 0
var current_pack: PackData = null

# --- Session Stats ---
var cards_answered_today: int = 0
var correct_answers_today: int = 0
var daily_sentence_completed_today: bool = false
var session_history: Array[Dictionary] = []

# --- Databases (loaded once) ---
var character_db: CharacterDatabase
var radical_db: RadicalDatabase
var sentence_db: SentenceDatabase
var review_scheduler: ReviewScheduler


func _ready() -> void:
	character_db = CharacterDatabase.new()
	radical_db = RadicalDatabase.new()
	sentence_db = SentenceDatabase.new()
	review_scheduler = ReviewScheduler.new()
	# Note: initialize_databases() is called AFTER SaveManager.load_game()
	# to avoid SaveManager.deserialize_all() clearing the registered cards.
	# SaveManager._ready() calls load_game() then emits load_completed.
	# We defer initialization to ensure proper ordering.


func initialize_databases() -> void:
	print("[GameState] initialize_databases starting, hsk_level=%d" % player_hsk_level)
	character_db.load_all(2, player_hsk_level)
	print("[GameState] character_db loaded: %d characters" % character_db.get_count())
	radical_db.load_all()
	sentence_db.load_all(2, mini(player_hsk_level, 4))
	# Register all characters with the review scheduler
	for cd in character_db.get_all():
		review_scheduler.register_card(cd.character, cd.character)
	print("[GameState] Registered %d cards with review_scheduler" % review_scheduler.card_states.size())


func start_run(run_type: String) -> void:
	is_in_run = true
	current_run_type = run_type
	current_combo = 0
	best_combo = 0
	run_coins_earned = 0
	run_tiles_earned.clear()
	current_round = 0

	match run_type:
		"easy":
			max_hearts = SrsConfig.HEARTS_EASY_RUN
		"challenge":
			max_hearts = SrsConfig.HEARTS_CHALLENGE_RUN
		_:
			max_hearts = SrsConfig.DEFAULT_MAX_HEARTS

	current_hearts = max_hearts
	SignalBus.run_started.emit(run_type)
	SignalBus.hearts_changed.emit(current_hearts, max_hearts)


func end_run() -> void:
	# Bank earned tiles into inventory
	for ch in run_tiles_earned:
		add_tiles(ch, run_tiles_earned[ch])

	total_coins += run_coins_earned

	var result := {
		"run_type": current_run_type,
		"coins": run_coins_earned,
		"tiles": run_tiles_earned.duplicate(),
		"best_combo": best_combo,
		"rounds": current_round,
		"hearts_remaining": current_hearts,
	}

	is_in_run = false
	current_run_type = ""
	current_pack = null
	SignalBus.run_ended.emit(result)


func add_tiles(character: String, count: int = 1) -> void:
	tile_inventory[character] = tile_inventory.get(character, 0) + count
	if is_in_run:
		run_tiles_earned[character] = run_tiles_earned.get(character, 0) + count
	SignalBus.tiles_changed.emit(character, tile_inventory.get(character, 0))


func spend_tiles(characters: Array) -> bool:
	# Check if all tiles available
	var needed: Dictionary = {}
	for ch in characters:
		var ch_str := str(ch)
		needed[ch_str] = needed.get(ch_str, 0) + 1
	for ch_str in needed:
		if tile_inventory.get(ch_str, 0) < needed[ch_str]:
			return false
	# Deduct
	for ch_str in needed:
		tile_inventory[ch_str] -= needed[ch_str]
		if tile_inventory[ch_str] <= 0:
			tile_inventory.erase(ch_str)
	SignalBus.tiles_spent.emit(characters)
	return true


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


func lose_heart() -> void:
	current_hearts = maxi(0, current_hearts - 1)
	SignalBus.heart_lost.emit()
	SignalBus.hearts_changed.emit(current_hearts, max_hearts)
	if current_hearts <= 0:
		SignalBus.all_hearts_lost.emit()


func reset_combo() -> void:
	if current_combo > 0:
		SignalBus.combo_broken.emit(current_combo)
	current_combo = 0


func increment_combo() -> void:
	current_combo += 1
	best_combo = maxi(best_combo, current_combo)
	SignalBus.combo_incremented.emit(current_combo)
	for milestone in SrsConfig.COMBO_MILESTONES:
		if current_combo == milestone:
			SignalBus.combo_milestone.emit(milestone)
			break


func record_answer(correct: bool) -> void:
	cards_answered_today += 1
	if correct:
		correct_answers_today += 1
		increment_combo()
	else:
		reset_combo()
		if is_in_run and current_run_type == "challenge":
			lose_heart()


func get_today_date() -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]


func check_daily_reset() -> void:
	var today := get_today_date()
	if today != last_play_date:
		cards_answered_today = 0
		correct_answers_today = 0
		daily_sentence_completed_today = false
		last_play_date = today


func to_save_dict() -> Dictionary:
	return {
		"player_hsk_level": player_hsk_level,
		"total_coins": total_coins,
		"daily_streak": daily_streak,
		"last_play_date": last_play_date,
		"equipped_radicals": equipped_radicals,
		"owned_radicals": owned_radicals,
		"planet_boosts": planet_boosts,
		"tile_inventory": tile_inventory,
		"unlocked_characters": unlocked_characters,
		"cards_answered_today": cards_answered_today,
		"correct_answers_today": correct_answers_today,
		"daily_sentence_completed_today": daily_sentence_completed_today,
		"session_history": session_history,
	}


func load_from_dict(data: Dictionary) -> void:
	player_hsk_level = data.get("player_hsk_level", 2)
	total_coins = data.get("total_coins", 0)
	daily_streak = data.get("daily_streak", 0)
	last_play_date = data.get("last_play_date", "")
	equipped_radicals.assign(data.get("equipped_radicals", []))
	owned_radicals.assign(data.get("owned_radicals", []))
	planet_boosts.assign(data.get("planet_boosts", []))
	tile_inventory = data.get("tile_inventory", {})
	unlocked_characters = data.get("unlocked_characters", {})
	cards_answered_today = data.get("cards_answered_today", 0)
	correct_answers_today = data.get("correct_answers_today", 0)
	daily_sentence_completed_today = data.get("daily_sentence_completed_today", false)
	session_history.assign(data.get("session_history", []))
