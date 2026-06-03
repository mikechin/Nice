## Smoke test for CombatController wiring — _ready builds a playable ATB fight:
## a CombatState with full player HP, a live mob, mob views + hero, the four
## answer buttons, and an active prompt. (The real-time ATB / input / animation
## flow needs frame timers + InputEvents, out of scope for headless; the
## resolution logic is covered by test_combat_state / test_combat_mob.)
extends GdUnitTestSuite


func test_ready_builds_playable_combat() -> void:
	var ctrl: CombatController = auto_free(CombatController.new())
	add_child(ctrl)              # enters tree → _ready builds the stage + combat state
	await get_tree().process_frame

	assert_object(ctrl._combat).is_not_null()
	assert_int(ctrl._combat.player_max_hp).is_equal(30)
	assert_int(ctrl._combat.player_hp).is_greater(0)
	assert_object(ctrl._combat.current_mob()).is_not_null()
	assert_int(ctrl._mob_views.size()).is_greater(0)
	assert_object(ctrl._hero_view).is_not_null()
	assert_int(ctrl._answer_buttons.size()).is_equal(4)
	# A prompt is up, so input is live and answers are populated.
	assert_bool(ctrl._answer_input.is_active()).is_true()
	assert_bool(ctrl._answer_input.get_current_answers().has("correct_direction")).is_true()
