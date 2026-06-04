## SaveManager — Handles persisting game state to disk.
## Uses Godot's user:// directory for save files.
##
## Durability model: every write is atomic (serialize to a `.tmp`, validate it,
## then rename it over the live file — rename is atomic on the same filesystem),
## and the previous file is rotated to `.bak`. A crash mid-write can therefore
## never truncate the live save; the worst case loses only the in-flight write,
## and a corrupt primary transparently falls back to `.bak` on load. A file that
## exists but cannot be parsed (even via backup) is preserved as `.corrupt` and
## surfaced via `save_error` rather than silently discarded — critically, a bad
## SRS file does NOT silently wipe the player's learning history.
class_name SaveManagerClass
extends Node

const SAVE_PATH: String = "user://save_data.json"
const SRS_SAVE_PATH: String = "user://srs_data.json"
const SAVE_VERSION: int = 3  # v2 adds the economy; v3 adds the loadout (the staked kit)

# Paths are instance vars (defaulting to the constants) so tests can point the
# whole pipeline at scratch files instead of the player's real save.
var save_path: String = SAVE_PATH
var srs_save_path: String = SRS_SAVE_PATH

# Set when an existing SRS file failed to load this session. While true we refuse
# to overwrite it, so a single unreadable load can't cement a wiped history.
var _srs_load_failed: bool = false

signal save_completed()
signal load_completed()
signal save_error(message: String)


func _ready() -> void:
	# load_game() is a safe no-op on a first run (no file present). It loads SRS
	# history on success. initialize_databases() then registers any characters not
	# already known (first run, or newly added HSK data).
	load_game()
	GameState.initialize_databases()


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": GameState.to_save_dict(),
		"accessibility": AccessibilityManager.to_dict(),
	}

	if not _write_json_atomic(save_path, data):
		var err_msg := "Failed to write save file"
		push_error("SaveManager: " + err_msg)
		save_error.emit(err_msg)
		return

	# Save SRS data separately (can be large).
	save_srs_data()

	save_completed.emit()


func load_game() -> bool:
	var res := _read_with_backup(save_path)
	if not res["found"]:
		return false  # genuine first run — nothing saved yet
	if not res["ok"]:
		_preserve_corrupt(save_path)
		var msg := "Save file is unreadable (backup also failed); preserved as .corrupt for recovery"
		push_error("SaveManager: " + msg)
		save_error.emit(msg)
		return false

	var data: Dictionary = res["data"]
	var version: int = int(data.get("version", 0))

	# Never load a save written by a newer build — its schema may carry data this
	# version would drop on the next write. Refuse rather than silently downgrade.
	if version > SAVE_VERSION:
		var msg := "Save is from a newer version (%d > %d); not loading to avoid data loss" % [version, SAVE_VERSION]
		push_error("SaveManager: " + msg)
		save_error.emit(msg)
		return false

	if version < SAVE_VERSION:
		data = _migrate(data, version)

	GameState.load_from_dict(data.get("game_state", {}))

	var accessibility_data: Dictionary = data.get("accessibility", {})
	if not accessibility_data.is_empty():
		AccessibilityManager.load_from_dict(accessibility_data)

	# Load SRS data.
	load_srs_data()

	load_completed.emit()
	return true


func save_srs_data() -> void:
	if _srs_load_failed:
		# We couldn't read the existing history this session; refuse to overwrite
		# it with the (empty/fresh) in-memory deck so the preserved .corrupt file
		# stays recoverable. The error was already surfaced at load time.
		push_warning("SaveManager: SRS save skipped — prior load failed; refusing to overwrite recoverable history")
		return

	var data := {
		"version": SAVE_VERSION,
		"cards": GameState.review_scheduler.serialize_all(),
	}

	if not _write_json_atomic(srs_save_path, data):
		var msg := "Failed to write SRS data"
		push_error("SaveManager: " + msg)
		save_error.emit(msg)


## Load SRS history. Returns true if history was loaded, false otherwise.
## Distinguishes "no file yet" (first run — fine) from "file present but corrupt"
## (surfaces save_error and blocks overwrite so the history isn't silently reset).
func load_srs_data() -> bool:
	var res := _read_with_backup(srs_save_path)
	if not res["found"]:
		return false  # no SRS history yet — expected on a first run
	if not res["ok"]:
		_srs_load_failed = true
		_preserve_corrupt(srs_save_path)
		var msg := "SRS history is unreadable (backup also failed); preserved as .corrupt — history was NOT reset"
		push_error("SaveManager: " + msg)
		save_error.emit(msg)
		return false

	_srs_load_failed = false
	var data: Dictionary = res["data"]
	var cards: Array = data.get("cards", [])
	GameState.review_scheduler.deserialize_all(cards)
	return true


func has_save_file() -> bool:
	return FileAccess.file_exists(save_path)


func has_srs_data() -> bool:
	return FileAccess.file_exists(srs_save_path)


func delete_save() -> void:
	# Remove the live files and every sidecar so a fresh start is truly fresh.
	for base in [save_path, srs_save_path]:
		for suffix in ["", ".bak", ".tmp", ".corrupt"]:
			_remove_if_exists(base + suffix)
	_srs_load_failed = false


## Migrate older save data up to SAVE_VERSION. Steps are explicit so an old save
## loads deterministically rather than relying on luck-of-default-values.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	var v := from_version
	if v < 2:
		# v1 → v2: persistent economy added. v1 saves have no "economy" key;
		# GameState.load_from_dict defaults inventory/wallet/binder to empty when
		# it's absent, so this step only needs to record the version bump.
		v = 2
	if v < 3:
		# v2 → v3: loadout added. v2 saves have an "economy" block but no
		# "loadout" key inside it; load_from_dict defaults it to an empty kit, so
		# again only the version bump is needed.
		v = 3
	data["version"] = SAVE_VERSION
	return data


# ---------------------------------------------------------------------------
# Atomic write / safe read helpers
# ---------------------------------------------------------------------------

## Write `data` as JSON to `path` atomically: serialize to `<path>.tmp`, verify it
## re-parses, rotate any existing file to `<path>.bak`, then rename the temp over
## the target. Returns false (leaving the previous file intact) on any failure.
func _write_json_atomic(path: String, data: Dictionary) -> bool:
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot open temp file (error %d)" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	# Guard against a partial/failed write replacing a good save.
	if _parse_json_object(tmp) == null:
		push_error("SaveManager: temp save failed validation; keeping previous save")
		_remove_if_exists(tmp)
		return false

	if FileAccess.file_exists(path):
		var bak := path + ".bak"
		_remove_if_exists(bak)
		DirAccess.rename_absolute(path, bak)

	return DirAccess.rename_absolute(tmp, path) == OK


## Parse a JSON object from `path`. Returns the Dictionary on success, or null if
## the file is absent, unreadable, not valid JSON, or not a JSON object.
func _parse_json_object(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return null
	return json.data


## Read+parse a JSON object, trying `path` then its `.bak`. Returns:
##   {found = false}                       — neither file exists (genuine first run)
##   {found = true, ok = true, data = ...} — parsed cleanly (from primary or backup)
##   {found = true, ok = false}            — a file exists but nothing parses
func _read_with_backup(path: String) -> Dictionary:
	var bak := path + ".bak"
	var primary_exists := FileAccess.file_exists(path)
	var bak_exists := FileAccess.file_exists(bak)
	if not primary_exists and not bak_exists:
		return {"found": false}

	var parsed: Variant = _parse_json_object(path) if primary_exists else null
	if parsed == null and bak_exists:
		parsed = _parse_json_object(bak)
		if parsed != null:
			push_warning("SaveManager: primary '%s' unreadable; recovered from backup" % path)

	if parsed == null:
		return {"found": true, "ok": false}
	return {"found": true, "ok": true, "data": parsed}


## Move an unreadable file aside (never delete) so it can be recovered manually.
func _preserve_corrupt(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var dest := path + ".corrupt"
	_remove_if_exists(dest)  # keep only the latest corrupt copy
	DirAccess.rename_absolute(path, dest)


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
