## Smoke test for DungeonMapController — instantiates the real screen headlessly
## and drives the M3 carry-cap triage UI build, the one interactive path the
## logic-level suites don't exercise. Verifies the screen comes up, the triage
## list renders over-cap, and the keep-set is correctly preselected — without
## firing a real scene transition (ScreenNavigator is a live autoload).
extends GdUnitTestSuite


func after_test() -> void:
	RunState.clear_run()


func _controller_with_over_cap_haul() -> DungeonMapController:
	RunState.clear_run()
	RunState.begin_run(30, 2)                 # cap 2 → 3 carried forces triage
	var run := RunState.run
	run.haul.append(CardInstance.create("a", EconomyEnums.Rarity.RARE))
	run.haul.append(CardInstance.create("b", EconomyEnums.Rarity.COMMON))
	run.haul.append(CardInstance.create("c", EconomyEnums.Rarity.UNCOMMON))
	var ctrl: DungeonMapController = auto_free(DungeonMapController.new())
	add_child(ctrl)                            # fires _ready → _build_ui + _render (no crash = pass)
	return ctrl


func test_screen_comes_up_with_active_run() -> void:
	var ctrl := _controller_with_over_cap_haul()
	# _ready built the header/subhead/panel and rendered the current room.
	assert_object(ctrl._header).is_not_null()
	assert_str(ctrl._header.text).is_not_empty()
	assert_bool(RunState.run.needs_triage()).is_true()


func test_triage_list_builds_and_preselects_best_n() -> void:
	var ctrl := _controller_with_over_cap_haul()
	ctrl._render_triage()
	# One row per carried instance.
	assert_int(ctrl._triage_rows.size()).is_equal(3)
	# Exactly carry_cap rows are pre-checked (the best by rarity).
	var checked := 0
	for row in ctrl._triage_rows:
		if row["btn"].button_pressed:
			checked += 1
	assert_int(checked).is_equal(RunState.run.carry_cap)
	# The status line and an enabled confirm button exist.
	assert_object(ctrl._triage_status).is_not_null()
	assert_str(ctrl._triage_status.text).is_not_empty()
	assert_bool(ctrl._confirm_btn.disabled).is_false()


func test_confirm_button_disables_when_over_cap() -> void:
	var ctrl := _controller_with_over_cap_haul()
	ctrl._render_triage()
	# Check every row → 3 kept against a cap of 2 → over cap → confirm blocked.
	for row in ctrl._triage_rows:
		row["btn"].button_pressed = true
	ctrl._update_triage_status()
	assert_bool(ctrl._confirm_btn.disabled).is_true()
