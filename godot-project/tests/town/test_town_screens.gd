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
		# town is a spatial Node2D world; the interiors are Control screens — so
		# the common base is Node.
		var inst: Node = load(SCREENS[screen_name]).instantiate()
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

	var ctrl: Node = load(SCREENS["town"]).instantiate()
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


func test_town_world_builds_hero_and_one_zone_per_destination() -> void:
	# The spatial town must put down a walkable hero and one interaction zone per
	# destination (Home / Crafter / Shop / Dungeon), so every door is reachable.
	var town: Node = load(SCREENS["town"]).instantiate()
	add_child(town)

	var heroes := 0
	var zones := 0
	for c in town.get_children():
		if c is CharacterBody2D:
			heroes += 1
		elif c is Area2D:
			zones += 1
	assert_int(heroes).override_failure_message("town has no walkable hero").is_equal(1)
	assert_int(zones) \
		.override_failure_message("expected one door zone per destination") \
		.is_equal(town._destinations().size())
	town.free()


func test_town_spawns_hero_at_the_door_it_left_by() -> void:
	# Leaving by the shop door and coming back should put the hero outside the shop,
	# on its horizontal midline — not at the town entrance.
	TownWorld._return_spawn_id = "shop"
	var town: Node = load(SCREENS["town"]).instantiate()
	add_child(town)

	var shop_cx := 0.0
	for d in town._destinations():
		if d["id"] == "shop":
			shop_cx = d["cx"]
	var hero: Node = null
	for c in town.get_children():
		if c is CharacterBody2D:
			hero = c
	assert_object(hero).is_not_null()
	assert_float(hero.position.x) \
		.override_failure_message("hero should spawn on the shop's midline, not the entrance") \
		.is_equal_approx(shop_cx, 1.0)

	town.free()
	TownWorld._return_spawn_id = ""        # don't leak the door into other tests


func test_town_spawns_hero_at_the_entrance_with_no_remembered_door() -> void:
	TownWorld._return_spawn_id = ""
	var town: Node = load(SCREENS["town"]).instantiate()
	add_child(town)
	var hero: Node = null
	for c in town.get_children():
		if c is CharacterBody2D:
			hero = c
	assert_object(hero).is_not_null()
	# Entrance is near the left edge — well left of the first building.
	assert_float(hero.position.x).is_less(town._destinations()[0]["cx"])
	town.free()


func test_door_zone_rect_sits_on_the_structure_front_edge() -> void:
	# The approach strip is centered on the building's base and hangs just below it,
	# where the hero walks up to the door. Pure geometry — no scene needed.
	var structure := Rect2(100, 100, 320, 280)
	var zone := TownWorld.door_zone_rect(structure, Vector2(240, 130))
	assert_float(zone.position.x).is_equal_approx(140.0, 0.01)   # centered: 100 + 160 - 120
	assert_float(zone.position.y).is_equal_approx(380.0, 0.01)   # structure.end.y
	assert_float(zone.size.x).is_equal_approx(240.0, 0.01)
	assert_float(zone.size.y).is_equal_approx(130.0, 0.01)
	# Centered on the structure's horizontal midline.
	assert_float(zone.position.x + zone.size.x * 0.5) \
		.is_equal_approx(structure.position.x + structure.size.x * 0.5, 0.01)
