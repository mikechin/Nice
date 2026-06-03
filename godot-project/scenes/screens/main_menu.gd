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
	_add_debug_combat_button()
	_add_debug_crawl_button()
	_update_displays()
	GameState.check_daily_reset()
	AudioManager.play_music("main_menu")


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
