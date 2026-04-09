## Tests for ChallengeEnums — direction helpers and constants.
extends GdUnitTestSuite


func test_direction_from_vector_up() -> void:
	var dir := ChallengeEnums.direction_from_vector(Vector2(0, -1))
	assert_int(dir).is_equal(ChallengeEnums.SwipeDirection.UP)


func test_direction_from_vector_down() -> void:
	var dir := ChallengeEnums.direction_from_vector(Vector2(0, 1))
	assert_int(dir).is_equal(ChallengeEnums.SwipeDirection.DOWN)


func test_direction_from_vector_left() -> void:
	var dir := ChallengeEnums.direction_from_vector(Vector2(-1, 0))
	assert_int(dir).is_equal(ChallengeEnums.SwipeDirection.LEFT)


func test_direction_from_vector_right() -> void:
	var dir := ChallengeEnums.direction_from_vector(Vector2(1, 0))
	assert_int(dir).is_equal(ChallengeEnums.SwipeDirection.RIGHT)


func test_direction_from_vector_diagonal_favors_vertical() -> void:
	# When |y| > |x|, vertical wins
	var dir := ChallengeEnums.direction_from_vector(Vector2(0.3, -0.9))
	assert_int(dir).is_equal(ChallengeEnums.SwipeDirection.UP)


func test_direction_to_string_all_directions() -> void:
	assert_str(ChallengeEnums.direction_to_string(ChallengeEnums.SwipeDirection.UP)).is_equal("up")
	assert_str(ChallengeEnums.direction_to_string(ChallengeEnums.SwipeDirection.DOWN)).is_equal("down")
	assert_str(ChallengeEnums.direction_to_string(ChallengeEnums.SwipeDirection.LEFT)).is_equal("left")
	assert_str(ChallengeEnums.direction_to_string(ChallengeEnums.SwipeDirection.RIGHT)).is_equal("right")


func test_direction_vectors_has_all_directions() -> void:
	assert_bool(ChallengeEnums.DIRECTION_VECTORS.has(ChallengeEnums.SwipeDirection.UP)).is_true()
	assert_bool(ChallengeEnums.DIRECTION_VECTORS.has(ChallengeEnums.SwipeDirection.DOWN)).is_true()
	assert_bool(ChallengeEnums.DIRECTION_VECTORS.has(ChallengeEnums.SwipeDirection.LEFT)).is_true()
	assert_bool(ChallengeEnums.DIRECTION_VECTORS.has(ChallengeEnums.SwipeDirection.RIGHT)).is_true()


func test_direction_vectors_values_correct() -> void:
	assert_that(ChallengeEnums.DIRECTION_VECTORS[ChallengeEnums.SwipeDirection.UP]).is_equal(Vector2.UP)
	assert_that(ChallengeEnums.DIRECTION_VECTORS[ChallengeEnums.SwipeDirection.DOWN]).is_equal(Vector2.DOWN)
	assert_that(ChallengeEnums.DIRECTION_VECTORS[ChallengeEnums.SwipeDirection.LEFT]).is_equal(Vector2.LEFT)
	assert_that(ChallengeEnums.DIRECTION_VECTORS[ChallengeEnums.SwipeDirection.RIGHT]).is_equal(Vector2.RIGHT)
