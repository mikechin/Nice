## SaveManager — Handles persisting game state to disk.
## Uses Godot's user:// directory for save files.
class_name SaveManagerClass
extends Node

const SAVE_PATH: String = "user://save_data.json"
const SRS_SAVE_PATH: String = "user://srs_data.json"
const SAVE_VERSION: int = 1

signal save_completed()
signal load_completed()
signal save_error(message: String)


func _ready() -> void:
	# Auto-load on startup if save exists
	if has_save_file():
		load_game()
	# Always initialize databases after loading save data.
	# This registers any characters not already in card_states
	# (e.g., on first run or when new HSK data is added).
	GameState.initialize_databases()


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": GameState.to_save_dict(),
		"accessibility": AccessibilityManager.to_dict(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var err_msg := "Failed to open save file: error %d" % FileAccess.get_open_error()
		push_error("SaveManager: " + err_msg)
		save_error.emit(err_msg)
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	# Save SRS data separately (can be large)
	save_srs_data()

	save_completed.emit()


func load_game() -> bool:
	if not has_save_file():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Cannot open save file")
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveManager: Corrupted save file")
		return false

	var data: Dictionary = json.data
	var version: int = data.get("version", 0)

	if version < SAVE_VERSION:
		data = _migrate(data, version)

	var game_data: Dictionary = data.get("game_state", {})
	GameState.load_from_dict(game_data)

	var accessibility_data: Dictionary = data.get("accessibility", {})
	if not accessibility_data.is_empty():
		AccessibilityManager.load_from_dict(accessibility_data)

	# Load SRS data
	load_srs_data()

	load_completed.emit()
	return true


func save_srs_data() -> void:
	var srs_cards := GameState.review_scheduler.serialize_all()
	var data := {
		"version": SAVE_VERSION,
		"cards": srs_cards,
	}

	var file := FileAccess.open(SRS_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to save SRS data")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_srs_data() -> void:
	if not FileAccess.file_exists(SRS_SAVE_PATH):
		return

	var file := FileAccess.open(SRS_SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveManager: Corrupted SRS data file")
		return

	var data: Dictionary = json.data
	var cards: Array = data.get("cards", [])
	GameState.review_scheduler.deserialize_all(cards)


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func has_srs_data() -> bool:
	return FileAccess.file_exists(SRS_SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(SRS_SAVE_PATH):
		DirAccess.remove_absolute(SRS_SAVE_PATH)


## Migrate old save data to current version.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	# Future migration logic goes here
	# For now, just stamp the current version
	data["version"] = SAVE_VERSION
	return data
