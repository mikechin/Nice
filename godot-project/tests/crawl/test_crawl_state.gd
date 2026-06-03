## Tests for CrawlState — the crawl-scoped state that survives the
## crawl→battle→crawl scene swaps (hero position + warden status).
extends GdUnitTestSuite


func test_defaults() -> void:
	var cs := CrawlState.new()
	assert_bool(cs.has_pos).is_false()
	assert_bool(cs.warden_defeated).is_false()
	assert_bool(cs.warden_fight_pending).is_false()


func test_save_hero_records_position() -> void:
	var cs := CrawlState.new()
	cs.save_hero(Vector2(300, 400))
	assert_bool(cs.has_pos).is_true()
	assert_vector(cs.hero_pos).is_equal(Vector2(300, 400))
