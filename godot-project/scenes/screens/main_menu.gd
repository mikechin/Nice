## MainMenu — Main menu screen with navigation to all game modes and screens.
## Provides buttons for Play (run select), Collection, Profile, and Settings.
class_name MainMenu
extends Control

@onready var _play_button: Button = $VBoxContainer/PlayButton if has_node("VBoxContainer/PlayButton") else null
@onready var _collection_button: Button = $VBoxContainer/CollectionButton if has_node("VBoxContainer/CollectionButton") else null
@onready var _profile_button: Button = $VBoxContainer/ProfileButton if has_node("VBoxContainer/ProfileButton") else null
@onready var _settings_button: Button = $VBoxContainer/SettingsButton if has_node("VBoxContainer/SettingsButton") else null
@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null


func _ready() -> void:
	_warn_missing_nodes()
	_connect_buttons()
	_add_town_button()
	_add_debug_combat_button()
	_add_debug_crawl_button()
	_add_debug_srs_buttons()
	_update_displays()
	GameState.check_daily_reset()
	AudioManager.play_music("main_menu")


## The town hub (M4) — the between-runs home for loadout, crafting, and the shop.
## Added in code (like the debug entries) so it doesn't disturb main_menu.tscn;
## the dungeon is reached from inside the town. The Phase-1/2 "Play" path stays
## untouched for now — retiring it is the deferred post-M4 structural sweep.
func _add_town_button() -> void:
	var vbox := get_node_or_null("VBoxContainer")
	if vbox == null:
		return
	var btn := Button.new()
	btn.text = "Town"
	btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		SignalBus.screen_transition_requested.emit("town"))
	# Place it just under Play so the hub reads as the primary destination.
	vbox.add_child(btn)
	vbox.move_child(btn, 1)


## DEBUG (M2): temporary entry into the dungeon run. Built in code so it
## doesn't touch main_menu.tscn; becomes the Town "enter dungeon" door once the
## hub (M4) lands. Starts a fresh run and drops into the run-map screen.
func _add_debug_combat_button() -> void:
	var vbox := get_node_or_null("VBoxContainer")
	if vbox == null:
		return
	var btn := Button.new()
	btn.text = "▶ Dungeon (debug)"
	btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		RunState.begin_run()
		SignalBus.screen_transition_requested.emit("dungeon_map"))
	vbox.add_child(btn)


## DEBUG (crawler slice): drop straight into the spatial crawl room to walk
## around with the arrow keys. Temporary, like the dungeon button above.
func _add_debug_crawl_button() -> void:
	var vbox := get_node_or_null("VBoxContainer")
	if vbox == null:
		return
	var btn := Button.new()
	btn.text = "▶ Crawl (debug)"
	btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		RunState.begin_run()
		SignalBus.screen_transition_requested.emit("crawl"))
	vbox.add_child(btn)


## DEBUG (playtest aids): seed the SRS ledger to either extreme so the scaffold
## states are observable on demand. "Reset" makes every card brand-new (watch
## TEACH → 2-option → 4-option from scratch); "Steady" seeds a mature HSK1–2 deck
## (no new, no clutch, all 4-option recall). Both persist immediately. Temporary,
## like the buttons above — folds into a dev menu later.
func _add_debug_srs_buttons() -> void:
	var vbox := get_node_or_null("VBoxContainer")
	if vbox == null:
		return

	var reset_btn := Button.new()
	reset_btn.text = "↺ Reset SRS (all new)"
	reset_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		var n := GameState.review_scheduler.debug_reset_all_new()
		SaveManager.save_game()
		reset_btn.text = "↺ Reset SRS — %d cards new ✓" % n)
	vbox.add_child(reset_btn)

	var steady_btn := Button.new()
	steady_btn.text = "✓ Seed steady HSK1–2"
	steady_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		var now := Time.get_unix_time_from_system()
		var n := GameState.review_scheduler.debug_seed_steady_state(now)
		SaveManager.save_game()
		steady_btn.text = "✓ Seeded %d cards (steady) ✓" % n)
	vbox.add_child(steady_btn)


func _connect_buttons() -> void:
	if _play_button:
		_play_button.pressed.connect(_on_play_pressed)
	if _collection_button:
		_collection_button.pressed.connect(_on_collection_pressed)
	if _profile_button:
		_profile_button.pressed.connect(_on_profile_pressed)
	if _settings_button:
		_settings_button.pressed.connect(_on_settings_pressed)


func _update_displays() -> void:
	if _title_label:
		_title_label.text = "Nice"


func _on_play_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("run_select")


func _on_collection_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("collection")


func _on_profile_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("profile")


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	SignalBus.screen_transition_requested.emit("settings")


func _warn_missing_nodes() -> void:
	if _play_button == null:
		push_warning("main_menu.gd: missing node _play_button")
	if _collection_button == null:
		push_warning("main_menu.gd: missing node _collection_button")
	if _profile_button == null:
		push_warning("main_menu.gd: missing node _profile_button")
	if _settings_button == null:
		push_warning("main_menu.gd: missing node _settings_button")
	if _title_label == null:
		push_warning("main_menu.gd: missing node _title_label")
