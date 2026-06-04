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

# --- Loadout (Phase 3, M4) ---
# The 5-card kit you bring into a run (= your stake). An equipped instance is
# moved OFF the bench and held here, so the two never double-count.
var loadout: Loadout

# Snapshot of the equipped kit taken at dungeon entry — what's on the line this
# run. Null between runs. (See Stake.)
var current_stake: Stake


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
	if loadout == null:
		loadout = Loadout.new()


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


## Shatter a bench instance into shards in town (the Crafter's shard service).
## Removes it from the bench and credits the wallet. Returns the shards gained
## (0 if the instance isn't on the bench).
func shatter_instance(instance_id: String) -> int:
	_ensure_economy()
	var ci := inventory.get_instance(instance_id)
	if ci == null:
		return 0
	var shards := ci.shard_value()
	inventory.remove(instance_id)
	wallet.add(shards)
	return shards


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
		# Persistent economy (save schema v2; v3 adds loadout). A v1 save lacks
		# this key, a v2 save lacks "loadout" — the loader defaults both to empty
		# structures, so old saves migrate cleanly.
		"economy": {
			"inventory": inventory.to_dict(),
			"wallet": wallet.to_dict(),
			"binder": binder.to_dict(),
			"loadout": loadout.to_dict(),
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
	loadout.load_from_dict(economy.get("loadout", {}))


## Equip an inventory instance into a loadout slot. Moves it OFF the bench (a card
## can't be both staked and benched); any card already in that slot returns to the
## bench. Returns true if the instance was found and equipped.
func equip(instance_id: String, slot: int) -> bool:
	_ensure_economy()
	if slot < 0 or slot >= loadout.capacity:
		return false
	var ci := inventory.remove(instance_id)
	if ci == null:
		return false  # not on the bench (already equipped, or unknown)
	var displaced := loadout.set_slot(slot, ci)
	if displaced != null:
		inventory.add(displaced)
	SignalBus.loadout_changed.emit(loadout)
	return true


## Unequip the instance in `slot` back onto the bench. Returns true if a card was
## there to remove.
func unequip(slot: int) -> bool:
	_ensure_economy()
	var ci := loadout.clear_slot(slot)
	if ci == null:
		return false
	inventory.add(ci)
	SignalBus.loadout_changed.emit(loadout)
	return true


## The crafting grade station (town). Lazily built so it always sees the live
## economy + character DB. The caller (crafter screen) hands us instance ids; we
## supply the target's mastery from the SRS layer so CraftSystem stays SRS-free.
var _craft_system: CraftSystem

func _ensure_craft_system() -> CraftSystem:
	_ensure_economy()
	if _craft_system == null:
		_craft_system = CraftSystem.new(inventory, wallet, binder, character_db)
	return _craft_system


## Max FSRS stability across a character's challenge types — how mastery caps the
## grade band. 0 for an unregistered/never-seen character.
func get_mastery_stability(card_id: String) -> float:
	if review_scheduler == null or card_id not in review_scheduler.card_states:
		return 0.0
	return review_scheduler.card_states[card_id].get_max_stability()


func preview_craft(target_id: String, ingredient_ids: Array) -> Dictionary:
	var cs := _ensure_craft_system()
	var target := inventory.get_instance(target_id)
	var stability := get_mastery_stability(target.card_id) if target != null else 0.0
	return cs.preview(target_id, ingredient_ids, stability)


func craft_grade(target_id: String, ingredient_ids: Array) -> Dictionary:
	var cs := _ensure_craft_system()
	var target := inventory.get_instance(target_id)
	var stability := get_mastery_stability(target.card_id) if target != null else 0.0
	return cs.craft(target_id, ingredient_ids, stability)


## The town shop. Lazily built over the live economy; the shop screen restocks
## and buys against it.
var _shop: Shop

func get_shop() -> Shop:
	_ensure_economy()
	if _shop == null:
		_shop = Shop.new(inventory, wallet, binder)
	return _shop


## Snapshot the equipped loadout as this run's stake (called at dungeon entry).
func enter_run_stake() -> Stake:
	_ensure_economy()
	current_stake = Stake.from_loadout(loadout)
	return current_stake


## Resolve the stake at the end of a run. Survived (extracted) → the kit comes
## home unchanged. Died → the whole kit is FORFEIT: stripped from the loadout and
## destroyed (NOT returned to the bench — that's the extraction stake). The binder
## and mastery are never touched (the un-loseable north star). Clears the stake
## either way; returns the lost instances for the debrief.
func resolve_stake(survived: bool) -> Array:
	_ensure_economy()
	var lost: Array = []
	if not survived:
		lost = loadout.strip_all()
		SignalBus.loadout_changed.emit(loadout)
	current_stake = null
	return lost
