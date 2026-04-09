## SrsEnums — Tests challenge_type_to_string(), string_to_challenge_type(), state_name(), rating_name().
extends GdUnitTestSuite


func before_test() -> void:
	pass


# -- challenge_type_to_string --

func test_challenge_type_to_string_meaning() -> void:
	assert_str(SrsEnums.challenge_type_to_string(SrsEnums.ChallengeType.MEANING)).is_equal("meaning")


func test_challenge_type_to_string_character() -> void:
	assert_str(SrsEnums.challenge_type_to_string(SrsEnums.ChallengeType.CHARACTER)).is_equal("character")


func test_challenge_type_to_string_pinyin() -> void:
	assert_str(SrsEnums.challenge_type_to_string(SrsEnums.ChallengeType.PINYIN)).is_equal("pinyin")


func test_challenge_type_to_string_tone() -> void:
	assert_str(SrsEnums.challenge_type_to_string(SrsEnums.ChallengeType.TONE)).is_equal("tone")


# -- string_to_challenge_type --

func test_string_to_challenge_type_meaning() -> void:
	assert_int(SrsEnums.string_to_challenge_type("meaning")).is_equal(SrsEnums.ChallengeType.MEANING)


func test_string_to_challenge_type_character() -> void:
	assert_int(SrsEnums.string_to_challenge_type("character")).is_equal(SrsEnums.ChallengeType.CHARACTER)


func test_string_to_challenge_type_pinyin() -> void:
	assert_int(SrsEnums.string_to_challenge_type("pinyin")).is_equal(SrsEnums.ChallengeType.PINYIN)


func test_string_to_challenge_type_tone() -> void:
	assert_int(SrsEnums.string_to_challenge_type("tone")).is_equal(SrsEnums.ChallengeType.TONE)


func test_string_to_challenge_type_unknown_defaults_to_meaning() -> void:
	assert_int(SrsEnums.string_to_challenge_type("bogus")).is_equal(SrsEnums.ChallengeType.MEANING)


# -- state_name --

func test_state_name_new() -> void:
	assert_str(SrsEnums.state_name(SrsEnums.CardSrsState.NEW)).is_equal("New")


func test_state_name_learning() -> void:
	assert_str(SrsEnums.state_name(SrsEnums.CardSrsState.LEARNING)).is_equal("Learning")


func test_state_name_review() -> void:
	assert_str(SrsEnums.state_name(SrsEnums.CardSrsState.REVIEW)).is_equal("Review")


func test_state_name_relearning() -> void:
	assert_str(SrsEnums.state_name(SrsEnums.CardSrsState.RELEARNING)).is_equal("Relearning")


# -- rating_name --

func test_rating_name_again() -> void:
	assert_str(SrsEnums.rating_name(SrsEnums.Rating.AGAIN)).is_equal("Again")


func test_rating_name_hard() -> void:
	assert_str(SrsEnums.rating_name(SrsEnums.Rating.HARD)).is_equal("Hard")


func test_rating_name_good() -> void:
	assert_str(SrsEnums.rating_name(SrsEnums.Rating.GOOD)).is_equal("Good")


func test_rating_name_easy() -> void:
	assert_str(SrsEnums.rating_name(SrsEnums.Rating.EASY)).is_equal("Easy")
