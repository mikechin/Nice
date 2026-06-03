## Tests for CrawlRoom — the spatial crawl screen (step 1: movement + walls).
## The wall/spawn geometry is pure and asserted directly; a smoke test confirms
## the real scene builds the hero inside the room headlessly (the movement
## itself is felt in playtest, not unit-tested).
extends GdUnitTestSuite


func after_test() -> void:
	RunState.clear_run()


func test_wall_rects_returns_four() -> void:
	assert_int(CrawlRoom.wall_rects(Rect2(100, 100, 400, 300), 20.0).size()).is_equal(4)


func test_walls_sit_outside_the_interior() -> void:
	var room := Rect2(100, 100, 400, 300)
	for w in CrawlRoom.wall_rects(room, 20.0):
		# Walls fence the room; none overlaps the play area (touching edges only).
		assert_bool(room.intersects(w)).is_false()


func test_walls_are_flush_against_the_room_edges() -> void:
	var room := Rect2(100, 100, 400, 300)
	var walls := CrawlRoom.wall_rects(room, 20.0)
	assert_float(walls[0].end.y).is_equal(room.position.y)        # top wall's inner edge
	assert_float(walls[1].position.y).is_equal(room.end.y)        # bottom wall's inner edge
	assert_float(walls[2].end.x).is_equal(room.position.x)        # left wall's inner edge
	assert_float(walls[3].position.x).is_equal(room.end.x)        # right wall's inner edge


func test_spawn_point_is_inside_the_room() -> void:
	var room := Rect2(100, 100, 400, 300)
	assert_bool(room.has_point(CrawlRoom.spawn_point(room, Vector2(40, 50)))).is_true()


func _in_any_wall(walls: Array, p: Vector2) -> bool:
	for w in walls:
		if w.has_point(p):
			return true
	return false


func test_world_is_wider_than_the_viewport() -> void:
	# End-to-end is meant to need scrolling: the world spans well past 1920px.
	assert_float(CrawlRoom.ROOM_B.end.x - CrawlRoom.ROOM_RECT.position.x).is_greater(1920.0)


func test_world_wall_rects_box_two_rooms_and_a_corridor() -> void:
	var walls := CrawlRoom.world_wall_rects(CrawlRoom.ROOM_RECT, CrawlRoom.ROOM_B, CrawlRoom.CORRIDOR, CrawlRoom.WALL_THICK)
	assert_int(walls.size()).is_equal(12)
	# A real wall is solid: the start room's left edge blocks.
	assert_bool(_in_any_wall(walls, Vector2(CrawlRoom.ROOM_RECT.position.x - CrawlRoom.WALL_THICK * 0.5, 540.0))).is_true()


func test_corridor_mouth_connects_the_two_rooms() -> void:
	var walls := CrawlRoom.world_wall_rects(CrawlRoom.ROOM_RECT, CrawlRoom.ROOM_B, CrawlRoom.CORRIDOR, CrawlRoom.WALL_THICK)
	# A straight line at the corridor's mid-height from the start room into the far
	# room crosses no wall — the passage is genuinely open both ends.
	var mid_y := CrawlRoom.CORRIDOR.position.y + CrawlRoom.CORRIDOR.size.y * 0.5
	for x in [1700.0, CrawlRoom.ROOM_RECT.end.x, 1920.0, CrawlRoom.CORRIDOR.end.x, 2140.0]:
		assert_bool(_in_any_wall(walls, Vector2(x, mid_y))).is_false()


func test_scene_builds_hero_inside_room() -> void:
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	assert_object(room._hero).is_not_null()
	assert_bool(CrawlRoom.ROOM_RECT.has_point(room._hero.position)).is_true()


func test_warden_present_until_defeated() -> void:
	RunState.begin_run()
	RunState.crawl.warden_defeated = false
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	assert_object(room._warden).is_not_null()


func test_warden_absent_once_defeated() -> void:
	RunState.begin_run()
	RunState.crawl.warden_defeated = true
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	assert_object(room._warden).is_null()


func test_returning_from_warden_fight_opens_the_door() -> void:
	# A win is the only way back here, so a pending warden fight resolves to
	# "defeated" on re-entry — the door opens and the warden is gone.
	RunState.begin_run()
	RunState.crawl.warden_fight_pending = true
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	assert_bool(RunState.crawl.warden_defeated).is_true()
	assert_bool(RunState.crawl.warden_fight_pending).is_false()
	assert_object(room._warden).is_null()


func test_bag_overlay_is_built_and_starts_closed() -> void:
	RunState.begin_run()
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	assert_object(room._bag_button).is_not_null()
	assert_object(room._bag).is_not_null()
	assert_bool(room._bag.is_open()).is_false()
	assert_bool(room._bag_open).is_false()


func test_overflowing_haul_forces_the_bag_open_on_entry() -> void:
	RunState.begin_run()
	var run := RunState.run
	var loot: Array = []
	for i in run.carry_cap + 2:                    # two more than the bag holds
		loot.append(CardInstance.create("c%d" % i, EconomyEnums.Rarity.COMMON))
	run.apply_room_result(25, loot, loot.size(), loot.size())
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	await get_tree().process_frame
	assert_bool(room._bag_open).is_true()
	assert_bool(room._bag.is_open()).is_true()


func test_camera_follows_hero_and_is_world_limited() -> void:
	RunState.begin_run()
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	assert_object(room._camera).is_not_null()
	assert_object(room._camera.get_parent()).is_same(room._hero)   # tracks the hero
	assert_int(room._camera.limit_left).is_equal(int(CrawlRoom.ROOM_RECT.position.x - CrawlRoom.WALL_THICK))
	assert_int(room._camera.limit_right).is_equal(int(CrawlRoom.ROOM_B.end.x + CrawlRoom.WALL_THICK))


func test_exit_and_warden_live_in_the_far_room() -> void:
	RunState.begin_run()
	RunState.crawl.warden_defeated = false
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	assert_bool(CrawlRoom.ROOM_B.has_point(room._door.position)).is_true()
	assert_bool(CrawlRoom.ROOM_B.has_point(room._warden.position)).is_true()


func test_hero_restored_to_saved_position() -> void:
	RunState.begin_run()
	RunState.crawl.save_hero(Vector2(640, 600))
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	assert_vector(room._hero.position).is_equal(Vector2(640, 600))
