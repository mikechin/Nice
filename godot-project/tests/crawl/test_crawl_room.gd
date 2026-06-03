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


func test_scene_builds_hero_inside_room() -> void:
	var room: CrawlRoom = auto_free(CrawlRoom.new())
	add_child(room)
	assert_object(room._hero).is_not_null()
	assert_bool(CrawlRoom.ROOM_RECT.has_point(room._hero.position)).is_true()
