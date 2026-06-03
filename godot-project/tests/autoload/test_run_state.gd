## Tests for RunStateClass — the cross-scene run holder. Focuses on the crawler
## additions: begin_run seeds a fresh CrawlState and resets the combat return
## screen to the node-map default.
extends GdUnitTestSuite


func _rs() -> RunStateClass:
	return auto_free(RunStateClass.new())


func test_begin_run_initializes_crawl_and_return_screen() -> void:
	var rs := _rs()
	rs.begin_run()
	assert_object(rs.crawl).is_not_null()
	assert_str(rs.combat_return_screen).is_equal("dungeon_map")
	assert_bool(rs.has_active_run()).is_true()


func test_begin_run_resets_crawl_each_run() -> void:
	var rs := _rs()
	rs.begin_run()
	rs.crawl.warden_defeated = true
	rs.begin_run()                       # a new run wipes the prior crawl state
	assert_bool(rs.crawl.warden_defeated).is_false()


func test_clear_run() -> void:
	var rs := _rs()
	rs.begin_run()
	rs.clear_run()
	assert_object(rs.run).is_null()
	assert_bool(rs.has_active_run()).is_false()
