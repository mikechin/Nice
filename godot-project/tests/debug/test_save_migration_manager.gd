## Tests for SaveMigrationManager — versioned migration system.
extends GdUnitTestSuite

var manager: SaveMigrationManager


func before_test() -> void:
	manager = SaveMigrationManager.new(3)


func test_get_current_version() -> void:
	assert_int(manager.get_current_version()).is_equal(3)


func test_register_migration_and_has_migration() -> void:
	manager.register_migration(1, func(data: Dictionary) -> Dictionary:
		data["migrated_v1"] = true
		return data
	)
	assert_bool(manager.has_migration(1)).is_true()
	assert_bool(manager.has_migration(2)).is_false()


func test_migrate_applies_single_migration() -> void:
	manager.register_migration(1, func(data: Dictionary) -> Dictionary:
		data["v2_field"] = "added"
		return data
	)
	var data := {"name": "test"}
	var result := manager.migrate(data, 1, 2)
	assert_str(result["v2_field"]).is_equal("added")
	assert_int(result["version"]).is_equal(2)


func test_migrate_applies_migrations_in_order() -> void:
	manager.register_migration(1, func(data: Dictionary) -> Dictionary:
		data["step"] = 1
		return data
	)
	manager.register_migration(2, func(data: Dictionary) -> Dictionary:
		data["step"] = data["step"] + 1
		return data
	)
	var data := {"name": "test"}
	var result := manager.migrate(data, 1, 3)
	assert_int(result["step"]).is_equal(2)
	assert_int(result["version"]).is_equal(3)


func test_migrate_same_version_returns_unchanged() -> void:
	var data := {"name": "test", "value": 42}
	var result := manager.migrate(data, 2, 2)
	assert_int(result["value"]).is_equal(42)


func test_can_migrate_checks_full_path() -> void:
	manager.register_migration(1, func(data: Dictionary) -> Dictionary: return data)
	manager.register_migration(2, func(data: Dictionary) -> Dictionary: return data)
	assert_bool(manager.can_migrate(1, 3)).is_true()
	assert_bool(manager.can_migrate(1, 4)).is_false()


func test_get_registered_versions_sorted() -> void:
	manager.register_migration(2, func(data: Dictionary) -> Dictionary: return data)
	manager.register_migration(1, func(data: Dictionary) -> Dictionary: return data)
	var versions := manager.get_registered_versions()
	assert_int(versions[0]).is_equal(1)
	assert_int(versions[1]).is_equal(2)
