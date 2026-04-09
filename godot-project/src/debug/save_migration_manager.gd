## SaveMigrationManager — Versioned save data migration system.
## Registers migration callables keyed by source version, applies them
## sequentially to bring save data from any old version to current.
class_name SaveMigrationManager
extends RefCounted


## Maps version number -> Callable that transforms data from that version to version + 1.
## Each callable has signature: func(data: Dictionary) -> Dictionary
var migration_registry: Dictionary = {}

## The current (latest) save format version.
var _current_version: int = 1


func _init(current_version: int = 1) -> void:
	_current_version = current_version


## Register a migration from `from_version` to `from_version + 1`.
## The migration callable receives a Dictionary and must return the transformed Dictionary.
func register_migration(from_version: int, migration: Callable) -> void:
	if from_version < 1:
		push_warning("SaveMigrationManager: Invalid version %d, must be >= 1" % from_version)
		return
	if from_version in migration_registry:
		push_warning("SaveMigrationManager: Overwriting existing migration for version %d" % from_version)
	migration_registry[from_version] = migration


## Apply all migrations in order from `from_version` to `to_version`.
## Returns the migrated data dictionary. If no migrations are needed, returns data unchanged.
func migrate(data: Dictionary, from_version: int, to_version: int) -> Dictionary:
	if from_version >= to_version:
		return data

	var result: Dictionary = data.duplicate(true)
	var current: int = from_version

	while current < to_version:
		if current not in migration_registry:
			push_error("SaveMigrationManager: Missing migration for version %d -> %d" % [current, current + 1])
			result["_migration_error"] = "Missing migration from version %d" % current
			result["_migrated_to"] = current
			return result

		var migration: Callable = migration_registry[current]
		result = migration.call(result)

		if not result is Dictionary:
			push_error("SaveMigrationManager: Migration %d returned non-Dictionary" % current)
			result = data.duplicate(true)
			result["_migration_error"] = "Migration %d returned invalid type" % current
			result["_migrated_to"] = current
			return result

		current += 1

	result["version"] = to_version
	return result


## Return the latest save format version.
func get_current_version() -> int:
	return _current_version


## Set the current (target) version. Typically called once at init.
func set_current_version(version: int) -> void:
	_current_version = version


## Check if a migration exists for a given version.
func has_migration(from_version: int) -> bool:
	return from_version in migration_registry


## Check if full migration path exists from one version to another.
func can_migrate(from_version: int, to_version: int) -> bool:
	if from_version >= to_version:
		return true
	var current: int = from_version
	while current < to_version:
		if current not in migration_registry:
			return false
		current += 1
	return true


## Migrate data from its embedded version to the current version.
## Reads "version" key from data, defaults to 1 if missing.
func migrate_to_current(data: Dictionary) -> Dictionary:
	var data_version: int = data.get("version", 1)
	return migrate(data, data_version, _current_version)


## Return a list of all registered migration version numbers, sorted ascending.
func get_registered_versions() -> Array[int]:
	var versions: Array[int] = []
	for v in migration_registry:
		versions.append(v)
	versions.sort()
	return versions
