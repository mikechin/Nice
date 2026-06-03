## Tests for SaveManagerClass durability: atomic writes, backup recovery, the
## corrupt-vs-absent distinction, and version migration/guarding. These exercise
## the file mechanism on scratch paths (never the player's real save) through a
## bare instance — it's never added to the tree, so _ready never fires and no
## autoload state is touched.
extends GdUnitTestSuite

const TMP := "user://__test_save.json"
const TMP_SRS := "user://__test_srs.json"

var sm: SaveManagerClass


func before_test() -> void:
	sm = auto_free(SaveManagerClass.new())   # not added to the tree → _ready does not run
	sm.save_path = TMP
	sm.srs_save_path = TMP_SRS
	_wipe()


func after_test() -> void:
	_wipe()


func _wipe() -> void:
	for base in [TMP, TMP_SRS]:
		for suffix in ["", ".bak", ".tmp", ".corrupt"]:
			if FileAccess.file_exists(base + suffix):
				DirAccess.remove_absolute(base + suffix)


func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


# -- constants still sane --

func test_save_paths_use_user_directory() -> void:
	assert_str(SaveManagerClass.SAVE_PATH).starts_with("user://")
	assert_str(SaveManagerClass.SRS_SAVE_PATH).starts_with("user://")
	assert_int(SaveManagerClass.SAVE_VERSION).is_greater_equal(1)


# -- atomic write + round-trip --

func test_atomic_write_round_trips() -> void:
	assert_bool(sm._write_json_atomic(TMP, {"a": 1, "b": "two"})).is_true()
	assert_bool(FileAccess.file_exists(TMP)).is_true()
	assert_bool(FileAccess.file_exists(TMP + ".tmp")).is_false()   # temp is cleaned up
	var res := sm._read_with_backup(TMP)
	assert_bool(res["ok"]).is_true()
	assert_int(int(res["data"]["a"])).is_equal(1)   # JSON parses numbers back as floats
	assert_str(res["data"]["b"]).is_equal("two")


func test_atomic_write_rotates_previous_to_backup() -> void:
	sm._write_json_atomic(TMP, {"gen": 1})
	sm._write_json_atomic(TMP, {"gen": 2})
	# The live file is the new generation; .bak holds the previous one.
	assert_int(int(sm._parse_json_object(TMP)["gen"])).is_equal(2)
	assert_int(int(sm._parse_json_object(TMP + ".bak")["gen"])).is_equal(1)


# -- read: absent vs corrupt vs backup recovery --

func test_read_missing_is_found_false() -> void:
	# Genuine first run — no file, and that is not an error.
	assert_bool(sm._read_with_backup(TMP)["found"]).is_false()


func test_read_recovers_from_backup_when_primary_corrupt() -> void:
	sm._write_json_atomic(TMP, {"gen": 1})    # creates the live file
	sm._write_json_atomic(TMP, {"gen": 2})    # rotates gen1 → .bak, live = gen2
	_write_raw(TMP, "{ this is not json")     # corrupt the live file
	var res := sm._read_with_backup(TMP)
	assert_bool(res["found"]).is_true()
	assert_bool(res["ok"]).is_true()
	assert_int(int(res["data"]["gen"])).is_equal(1)   # recovered from the backup generation


func test_read_corrupt_with_no_backup_is_found_but_not_ok() -> void:
	_write_raw(TMP, "garbage{")
	var res := sm._read_with_backup(TMP)
	assert_bool(res["found"]).is_true()
	assert_bool(res["ok"]).is_false()


func test_preserve_corrupt_moves_file_aside() -> void:
	_write_raw(TMP, "garbage{")
	sm._preserve_corrupt(TMP)
	assert_bool(FileAccess.file_exists(TMP)).is_false()
	assert_bool(FileAccess.file_exists(TMP + ".corrupt")).is_true()


# -- migration + downgrade guard --

func test_migrate_stamps_current_version_and_keeps_payload() -> void:
	var migrated := sm._migrate({"version": 1, "game_state": {"player_hsk_level": 3}}, 1)
	assert_int(migrated["version"]).is_equal(SaveManagerClass.SAVE_VERSION)
	assert_int(migrated["game_state"]["player_hsk_level"]).is_equal(3)


func test_load_refuses_a_future_version_save() -> void:
	# A save from a newer build must not load (it could carry data this version
	# would drop on the next write). load_game returns before touching GameState.
	var errors: Array = []
	sm.save_error.connect(func(m): errors.append(m))
	_write_raw(TMP, JSON.stringify({"version": 999, "game_state": {}}))
	assert_bool(sm.load_game()).is_false()
	assert_int(errors.size()).is_equal(1)


# -- the SRS-history protection (the critical data-loss fix) --

func test_absent_srs_is_not_a_failure() -> void:
	assert_bool(sm.load_srs_data()).is_false()     # nothing to load...
	assert_bool(sm._srs_load_failed).is_false()    # ...but it is not flagged as corruption


func test_corrupt_srs_blocks_overwrite_to_protect_history() -> void:
	# A corrupt SRS file must never be silently overwritten by a fresh deck.
	_write_raw(TMP_SRS, "not json at all {{{")
	var errors: Array = []
	sm.save_error.connect(func(m): errors.append(m))

	assert_bool(sm.load_srs_data()).is_false()
	assert_bool(sm._srs_load_failed).is_true()
	assert_int(errors.size()).is_equal(1)
	assert_bool(FileAccess.file_exists(TMP_SRS + ".corrupt")).is_true()   # preserved for recovery

	# A subsequent save refuses to write while the failure stands.
	sm.save_srs_data()
	assert_bool(FileAccess.file_exists(TMP_SRS)).is_false()


func test_delete_save_clears_files_and_unblocks() -> void:
	sm._write_json_atomic(TMP, {"gen": 1})
	sm._write_json_atomic(TMP, {"gen": 2})        # leaves TMP + TMP.bak
	sm._srs_load_failed = true
	sm.delete_save()
	assert_bool(FileAccess.file_exists(TMP)).is_false()
	assert_bool(FileAccess.file_exists(TMP + ".bak")).is_false()
	assert_bool(sm._srs_load_failed).is_false()
