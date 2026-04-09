## ProfileScreen — Displays player stats: HSK level, mastery percentage, streak,
## total mastered characters, and overall accuracy. Reads from GameState.
class_name ProfileScreen
extends Control

@onready var _hsk_label: Label = $StatsContainer/HskLabel if has_node("StatsContainer/HskLabel") else null
@onready var _mastery_label: Label = $StatsContainer/MasteryLabel if has_node("StatsContainer/MasteryLabel") else null
@onready var _streak_label: Label = $StatsContainer/StreakLabel if has_node("StatsContainer/StreakLabel") else null
@onready var _mastered_label: Label = $StatsContainer/MasteredLabel if has_node("StatsContainer/MasteredLabel") else null
@onready var _accuracy_label: Label = $StatsContainer/AccuracyLabel if has_node("StatsContainer/AccuracyLabel") else null
@onready var _coins_label: Label = $StatsContainer/CoinsLabel if has_node("StatsContainer/CoinsLabel") else null
@onready var _tiles_label: Label = $StatsContainer/TilesLabel if has_node("StatsContainer/TilesLabel") else null
@onready var _radicals_label: Label = $StatsContainer/RadicalsLabel if has_node("StatsContainer/RadicalsLabel") else null
@onready var _tier_breakdown: VBoxContainer = $TierBreakdown if has_node("TierBreakdown") else null
@onready var _back_button: Button = $BackButton if has_node("BackButton") else null
@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null


func _ready() -> void:
	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)

	_update_stats()

	SignalBus.character_mastered.connect(_on_character_mastered)
	SignalBus.streak_updated.connect(_on_streak_updated)


func _update_stats() -> void:
	if _title_label:
		_title_label.text = "Profile"

	# HSK level
	if _hsk_label:
		_hsk_label.text = "HSK Level: %d" % GameState.player_hsk_level

	# Build collection grid to get mastery stats
	var grid := CollectionGrid.new()
	var now := Time.get_unix_time_from_system()
	grid.build_grid(GameState.character_db, GameState.review_scheduler, now)

	# Mastery percentage
	var mastery_pct: float = grid.get_completion_percentage() * 100.0
	if _mastery_label:
		_mastery_label.text = "Collection: %.1f%%" % mastery_pct

	# Total mastered (epic+ tier)
	var epic_chars: Array[String] = grid.get_characters_by_tier(CollectionEnums.CardTier.EPIC)
	var legend_chars: Array[String] = grid.get_characters_by_tier(CollectionEnums.CardTier.LEGENDARY)
	var total_mastered: int = epic_chars.size() + legend_chars.size()
	if _mastered_label:
		_mastered_label.text = "Mastered: %d" % total_mastered

	# Streak
	if _streak_label:
		_streak_label.text = "Daily Streak: %d days" % GameState.daily_streak

	# Accuracy
	var answered: int = GameState.cards_answered_today
	var correct: int = GameState.correct_answers_today
	var accuracy: float = (float(correct) / float(answered) * 100.0) if answered > 0 else 0.0
	if _accuracy_label:
		_accuracy_label.text = "Today's Accuracy: %.0f%%" % accuracy

	# Coins
	if _coins_label:
		_coins_label.text = "Coins: %d" % GameState.total_coins

	# Total tiles
	var total_tiles: int = 0
	for ch in GameState.tile_inventory:
		total_tiles += int(GameState.tile_inventory[ch])
	if _tiles_label:
		_tiles_label.text = "Tiles: %d" % total_tiles

	# Radicals owned
	if _radicals_label:
		_radicals_label.text = "Radicals: %d owned, %d equipped" % [
			GameState.owned_radicals.size(),
			GameState.equipped_radicals.size(),
		]

	# Tier breakdown
	_update_tier_breakdown(grid)


func _update_tier_breakdown(grid: CollectionGrid) -> void:
	if _tier_breakdown == null:
		return

	for child in _tier_breakdown.get_children():
		child.queue_free()

	var tiers: Array = [
		CollectionEnums.CardTier.LEGENDARY,
		CollectionEnums.CardTier.EPIC,
		CollectionEnums.CardTier.RARE,
		CollectionEnums.CardTier.UNCOMMON,
		CollectionEnums.CardTier.COMMON,
		CollectionEnums.CardTier.NEW_CARD,
		CollectionEnums.CardTier.LOCKED,
	]

	for tier in tiers:
		var count: int = grid.get_characters_by_tier(tier).size()
		if count == 0:
			continue
		var label := Label.new()
		label.text = "%s: %d" % [CollectionEnums.tier_name(tier), count]
		var color: Color = CollectionEnums.tier_color(tier)
		label.add_theme_color_override("font_color", color)
		_tier_breakdown.add_child(label)


func _on_character_mastered(_character: String) -> void:
	_update_stats()


func _on_streak_updated(_days: int) -> void:
	_update_stats()


func _on_back_pressed() -> void:
	SignalBus.screen_transition_requested.emit("main_menu")
