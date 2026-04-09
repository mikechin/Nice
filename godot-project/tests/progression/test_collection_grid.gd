## Tests for CollectionGrid — collection grid data model.
extends GdUnitTestSuite

var grid: CollectionGrid
var char_db: CharacterDatabase
var scheduler: ReviewScheduler
var fsrs: FsrsAlgorithm


func before_test() -> void:
	fsrs = FsrsAlgorithm.new()
	grid = CollectionGrid.new()
	char_db = CharacterDatabase.new()
	scheduler = ReviewScheduler.new()

	# Build test character data
	var chars: Array[CharacterData] = []
	var cd1 := CharacterData.from_dict({"character": "wo3_char", "pinyin": "wo3", "meaning": "I", "hsk_level": 2})
	var cd2 := CharacterData.from_dict({"character": "ni3_char", "pinyin": "ni3", "meaning": "you", "hsk_level": 2})
	var cd3 := CharacterData.from_dict({"character": "ta1_char", "pinyin": "ta1", "meaning": "he", "hsk_level": 2})
	chars.append(cd1)
	chars.append(cd2)
	chars.append(cd3)
	char_db.load_from_array(chars)

	# Register all in scheduler
	for cd in chars:
		scheduler.register_card(cd.character, cd.character)


func test_build_grid_all_locked_when_new() -> void:
	var now := 1700000000.0
	grid.build_grid(char_db, scheduler, now)
	assert_int(grid.get_tier("wo3_char")).is_equal(CollectionEnums.CardTier.LOCKED)
	assert_int(grid.get_tier("ni3_char")).is_equal(CollectionEnums.CardTier.LOCKED)


func test_build_grid_unlocked_after_review() -> void:
	var now := 1700000000.0
	# Review one card to move it out of NEW state
	scheduler.record_review("wo3_char", "meaning", FsrsAlgorithm.Rating.GOOD, now)
	grid.build_grid(char_db, scheduler, now)
	# wo3_char should no longer be LOCKED
	var tier := grid.get_tier("wo3_char")
	assert_bool(tier != CollectionEnums.CardTier.LOCKED).is_true()


func test_get_completion_percentage_partial() -> void:
	var now := 1700000000.0
	scheduler.record_review("wo3_char", "meaning", FsrsAlgorithm.Rating.GOOD, now)
	grid.build_grid(char_db, scheduler, now)
	# 1 out of 3 unlocked
	var pct := grid.get_completion_percentage()
	assert_float(pct).is_equal_approx(1.0 / 3.0, 0.01)


func test_get_characters_by_tier_locked() -> void:
	var now := 1700000000.0
	grid.build_grid(char_db, scheduler, now)
	var locked := grid.get_characters_by_tier(CollectionEnums.CardTier.LOCKED)
	assert_int(locked.size()).is_equal(3)


func test_get_completion_percentage_zero_when_all_new() -> void:
	var now := 1700000000.0
	grid.build_grid(char_db, scheduler, now)
	assert_float(grid.get_completion_percentage()).is_equal(0.0)


func test_get_total_count_matches_database() -> void:
	var now := 1700000000.0
	grid.build_grid(char_db, scheduler, now)
	assert_int(grid.get_total_count()).is_equal(3)
