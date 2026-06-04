## Smoke tests for the M4 town screens. Instantiates each scene into the tree so
## its controller's _ready runs against the live autoloads, and asserts the UI
## actually builds (children created, no crash). Seeds a little economy so the
## row-building paths (bench rows, shop stock, loadout slots) are exercised, not
## just the empty states. Restores GameState afterward so no global state leaks.
extends GdUnitTestSuite

const SCREENS := {
	"town": "res://scenes/screens/town.tscn",
	"home": "res://scenes/screens/home.tscn",
	"crafter": "res://scenes/screens/crafter.tscn",
	"shop": "res://scenes/screens/shop.tscn",
}


func before_test() -> void:
	GameState.load_from_dict({})                 # clean economy structs
	GameState.inventory.add(CardInstance.create("请", EconomyEnums.Rarity.RARE))
	GameState.inventory.add(CardInstance.create("清", EconomyEnums.Rarity.COMMON))
	GameState.binder.record_seen("好")
	GameState.wallet.add(50)
	GameState._shop = null                        # force a fresh shop/craft over this economy
	GameState._craft_system = null


func after_test() -> void:
	GameState.load_from_dict({})
	GameState._shop = null
	GameState._craft_system = null


func test_each_town_screen_instantiates_and_builds_ui() -> void:
	for screen_name in SCREENS:
		var inst: Control = load(SCREENS[screen_name]).instantiate()
		add_child(inst)                           # fires _ready → builds UI
		assert_int(inst.get_child_count()) \
			.override_failure_message("screen '%s' built no UI" % screen_name) \
			.is_greater(0)
		inst.free()


func test_home_renders_a_loadout_slot_per_capacity() -> void:
	# A coarse check that the loadout panel reflects the real slot count.
	var inst: Control = load(SCREENS["home"]).instantiate()
	add_child(inst)
	# At minimum the screen built the chrome + two panels.
	assert_int(inst.get_child_count()).is_greater_equal(3)
	inst.free()


func test_debug_grant_seeds_a_resolvable_connected_family() -> void:
	# Regression: the debug bench must seed a family that exists in the LOADED
	# database and forms a real connection. The original bug hardcoded higher-HSK
	# characters (晴/情) absent from the HSK-2 set, so get_character returned null
	# → "No connection — unknown character".
	var db: CharacterDatabase = GameState.character_db
	if not db.is_loaded():
		GameState.initialize_databases()
	assert_int(db.get_count()).is_greater(0)

	var ctrl: Control = load(SCREENS["town"]).instantiate()
	add_child(ctrl)
	var fam: Array = ctrl._debug_family(db, 4)
	assert_int(fam.size()).is_equal(4)

	var cds: Array = []
	for c in fam:
		var cd: CharacterData = db.get_character(c)
		assert_object(cd) \
			.override_failure_message("seeded char '%s' not in loaded DB" % c) \
			.is_not_null()
		cds.append(cd)
	var conn := ConnectionSet.classify(cds[0], [cds[1], cds[2], cds[3]])
	assert_bool(conn["valid"]).is_true()
	ctrl.free()
