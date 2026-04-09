## Smoke tests for AudioManagerClass — basic property existence.
extends GdUnitTestSuite

var manager: AudioManagerClass


func before_test() -> void:
	manager = AudioManagerClass.new()


func after_test() -> void:
	manager.free()


func test_audio_manager_is_node() -> void:
	assert_bool(manager is Node).is_true()


func test_max_sfx_players_constant() -> void:
	assert_int(AudioManagerClass.MAX_SFX_PLAYERS).is_greater(0)


func test_music_fade_time_constant() -> void:
	assert_float(AudioManagerClass.MUSIC_FADE_TIME).is_greater(0.0)


func test_default_volume_values() -> void:
	assert_float(manager.sfx_volume).is_greater(0.0)
	assert_float(manager.sfx_volume).is_less_equal(1.0)
	assert_float(manager.music_volume).is_greater(0.0)
	assert_float(manager.music_volume).is_less_equal(1.0)


func test_sfx_enabled_by_default() -> void:
	assert_bool(manager.sfx_enabled).is_true()


func test_music_enabled_by_default() -> void:
	assert_bool(manager.music_enabled).is_true()
