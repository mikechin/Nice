## SettingsScreen — Player settings for music volume, SFX volume, and HSK level.
## Persists settings through SaveManager on change.
class_name SettingsScreen
extends Control

@onready var _music_slider: HSlider = $SettingsContainer/MusicSlider if has_node("SettingsContainer/MusicSlider") else null
@onready var _sfx_slider: HSlider = $SettingsContainer/SfxSlider if has_node("SettingsContainer/SfxSlider") else null
@onready var _music_label: Label = $SettingsContainer/MusicLabel if has_node("SettingsContainer/MusicLabel") else null
@onready var _sfx_label: Label = $SettingsContainer/SfxLabel if has_node("SettingsContainer/SfxLabel") else null
@onready var _hsk_selector: OptionButton = $SettingsContainer/HskSelector if has_node("SettingsContainer/HskSelector") else null
@onready var _music_toggle: CheckButton = $SettingsContainer/MusicToggle if has_node("SettingsContainer/MusicToggle") else null
@onready var _sfx_toggle: CheckButton = $SettingsContainer/SfxToggle if has_node("SettingsContainer/SfxToggle") else null
@onready var _back_button: Button = $BackButton if has_node("BackButton") else null
@onready var _reset_button: Button = $ResetButton if has_node("ResetButton") else null


func _ready() -> void:
	_load_current_settings()
	_connect_controls()


func _load_current_settings() -> void:
	# Music volume
	if _music_slider:
		_music_slider.min_value = 0.0
		_music_slider.max_value = 1.0
		_music_slider.step = 0.05
		_music_slider.value = AudioManager.music_volume
	if _music_label:
		_music_label.text = "Music: %d%%" % roundi(AudioManager.music_volume * 100)

	# SFX volume
	if _sfx_slider:
		_sfx_slider.min_value = 0.0
		_sfx_slider.max_value = 1.0
		_sfx_slider.step = 0.05
		_sfx_slider.value = AudioManager.sfx_volume
	if _sfx_label:
		_sfx_label.text = "SFX: %d%%" % roundi(AudioManager.sfx_volume * 100)

	# Toggles
	if _music_toggle:
		_music_toggle.button_pressed = AudioManager.music_enabled
	if _sfx_toggle:
		_sfx_toggle.button_pressed = AudioManager.sfx_enabled

	# HSK level selector
	if _hsk_selector:
		_hsk_selector.clear()
		for level in range(1, 7):
			_hsk_selector.add_item("HSK %d" % level, level)
		# Select current level
		var current_idx: int = GameState.player_hsk_level - 1
		if current_idx >= 0 and current_idx < _hsk_selector.item_count:
			_hsk_selector.selected = current_idx


func _connect_controls() -> void:
	if _music_slider:
		_music_slider.value_changed.connect(_on_music_volume_changed)
	if _sfx_slider:
		_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	if _music_toggle:
		_music_toggle.toggled.connect(_on_music_toggled)
	if _sfx_toggle:
		_sfx_toggle.toggled.connect(_on_sfx_toggled)
	if _hsk_selector:
		_hsk_selector.item_selected.connect(_on_hsk_level_changed)
	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)
	if _reset_button:
		_reset_button.pressed.connect(_on_reset_pressed)


func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	if _music_label:
		_music_label.text = "Music: %d%%" % roundi(value * 100)
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	if _sfx_label:
		_sfx_label.text = "SFX: %d%%" % roundi(value * 100)
	_save_settings()


func _on_music_toggled(enabled: bool) -> void:
	AudioManager.music_enabled = enabled
	if not enabled:
		AudioManager.stop_music()
	_save_settings()


func _on_sfx_toggled(enabled: bool) -> void:
	AudioManager.sfx_enabled = enabled
	_save_settings()


func _on_hsk_level_changed(index: int) -> void:
	if _hsk_selector == null:
		return
	var new_level: int = _hsk_selector.get_item_id(index)
	if new_level < 1 or new_level > 6:
		return

	var old_level: int = GameState.player_hsk_level
	if new_level == old_level:
		return

	GameState.player_hsk_level = new_level
	GameState.initialize_databases()
	SignalBus.hsk_level_changed.emit(old_level, new_level)
	_save_settings()


func _on_reset_pressed() -> void:
	# Reset to defaults
	AudioManager.set_music_volume(0.7)
	AudioManager.set_sfx_volume(1.0)
	AudioManager.music_enabled = true
	AudioManager.sfx_enabled = true
	_load_current_settings()
	_save_settings()


func _save_settings() -> void:
	SaveManager.save_game()


func _on_back_pressed() -> void:
	SignalBus.screen_transition_requested.emit("main_menu")
