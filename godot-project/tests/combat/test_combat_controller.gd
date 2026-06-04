## Smoke test for CombatController wiring — _ready builds a playable ATB fight:
## a CombatState with full player HP, a live mob, mob views + hero, the four
## answer buttons, and an active prompt. (The real-time ATB / input / animation
## flow needs frame timers + InputEvents, out of scope for headless; the
## resolution logic is covered by test_combat_state / test_combat_mob.)
extends GdUnitTestSuite


# Combat now folds the equipped kit into its setup (M5), and SaveManager loads the
# real on-disk save at boot — so a fresh, unkitted fight needs an empty loadout for
# the base HP pool to be exact. Clear the economy here, restore the disk state after.
func before_test() -> void:
	GameState.load_from_dict({})


func after_test() -> void:
	SaveManager.load_game()


func test_ready_builds_playable_combat() -> void:
	var ctrl: CombatController = auto_free(CombatController.new())
	add_child(ctrl)              # enters tree → _ready builds the stage + combat state
	await get_tree().process_frame

	assert_object(ctrl._combat).is_not_null()
	# Empty kit → the base 30 HP pool, with no Ward bonus added.
	assert_int(ctrl._combat.player_max_hp).is_equal(30)
	assert_int(ctrl._combat.player_hp).is_greater(0)
	assert_object(ctrl._combat.current_mob()).is_not_null()
	assert_int(ctrl._mob_views.size()).is_greater(0)
	assert_object(ctrl._hero_view).is_not_null()
	assert_int(ctrl._answer_buttons.size()).is_equal(4)
	# The limit-break gauge + button are wired and start un-armed.
	assert_object(ctrl._limit_bar).is_not_null()
	assert_object(ctrl._limit_button).is_not_null()
	assert_bool(ctrl._limit_button.disabled).is_true()
	# A card is presented in some valid mode: either a teach beat (first-sight
	# cards) or the live answer flow. Which one depends on the deck's SRS state,
	# so accept both rather than assuming a fresh all-new deck.
	assert_object(ctrl._card_display.card_data).is_not_null()
	assert_bool(ctrl._teaching or ctrl._answer_input.is_active()).is_true()
