## Tests for CombatState — ATB charge, attacks, mob timers, win/loss.
extends GdUnitTestSuite


func _mob(hp: int, atk: int, rate: float) -> CombatMob:
	return CombatMob.create("M", hp, atk, rate)


func test_create_targets_first_mob_player_full() -> void:
	var s := CombatState.create(10, [_mob(2, 1, 0.0), _mob(2, 1, 0.0)], 0.5, 2)
	assert_int(s.player_hp).is_equal(10)
	assert_int(s.current_target_index()).is_equal(0)
	assert_int(s.outcome()).is_equal(CombatState.Outcome.ONGOING)
	assert_bool(s.player_attack_ready()).is_false()


func test_correct_answers_charge_atb_to_ready() -> void:
	var s := CombatState.create(10, [_mob(2, 1, 0.0)], 0.5, 2)
	s.answer(true)
	assert_bool(s.player_attack_ready()).is_false()  # 0.5
	s.answer(true)
	assert_bool(s.player_attack_ready()).is_true()    # 1.0


func test_wrong_answer_does_not_charge() -> void:
	var s := CombatState.create(10, [_mob(2, 1, 0.0)], 0.5, 2)
	s.answer(false)
	assert_float(s.player_atb).is_equal(0.0)


func test_attack_when_ready_damages_target_and_resets_gauge() -> void:
	var s := CombatState.create(10, [_mob(5, 1, 0.0)], 0.5, 2)
	s.answer(true)
	s.answer(true)
	var struck := s.player_attack()
	assert_object(struck).is_not_null()
	assert_int(s.mobs[0].hp).is_equal(3)  # 5 - 2
	assert_float(s.player_atb).is_equal(0.0)
	assert_int(s.outcome()).is_equal(CombatState.Outcome.ONGOING)


func test_attack_not_ready_is_noop() -> void:
	var s := CombatState.create(10, [_mob(5, 1, 0.0)], 0.5, 2)
	assert_object(s.player_attack()).is_null()
	assert_int(s.mobs[0].hp).is_equal(5)


func test_killing_all_mobs_wins() -> void:
	var s := CombatState.create(10, [_mob(2, 1, 0.0)], 0.5, 2)
	s.answer(true)
	s.answer(true)
	s.player_attack()  # 2 dmg kills a 2-hp mob
	assert_int(s.outcome()).is_equal(CombatState.Outcome.WON)
	assert_bool(s.is_over()).is_true()


func test_multi_mob_retargets_after_kill() -> void:
	var s := CombatState.create(10, [_mob(2, 1, 0.0), _mob(2, 1, 0.0)], 0.5, 2)
	s.answer(true)
	s.answer(true)
	s.player_attack()  # kills mob 0
	assert_int(s.current_target_index()).is_equal(1)
	assert_int(s.outcome()).is_equal(CombatState.Outcome.ONGOING)


func test_tick_fills_mob_gauge_and_damages_player() -> void:
	var s := CombatState.create(10, [_mob(5, 3, 1.0)], 0.5, 2)
	s.tick(1.0)  # gauge fills (rate 1.0 × 1.0s) → strikes for 3
	assert_int(s.player_hp).is_equal(7)
	assert_float(s.mobs[0].atb).is_equal(0.0)  # reset after striking


func test_player_dies_when_hp_zero() -> void:
	var s := CombatState.create(3, [_mob(5, 3, 1.0)], 0.5, 2)
	s.tick(1.0)  # 3 dmg → hp 0
	assert_int(s.player_hp).is_equal(0)
	assert_int(s.outcome()).is_equal(CombatState.Outcome.LOST)


func test_set_target_switches_and_ignores_dead() -> void:
	var s := CombatState.create(10, [_mob(2, 1, 0.0), _mob(2, 1, 0.0)], 0.5, 2)
	s.set_target(1)
	assert_int(s.current_target_index()).is_equal(1)
	s.answer(true)
	s.answer(true)
	s.player_attack()  # kills mob 1 → auto-retargets to 0
	assert_int(s.current_target_index()).is_equal(0)
	s.set_target(1)  # mob 1 is dead → ignored
	assert_int(s.current_target_index()).is_equal(0)


func test_over_stops_answer_attack_tick() -> void:
	var s := CombatState.create(3, [_mob(2, 3, 1.0)], 0.5, 2)
	s.tick(1.0)  # LOST
	s.answer(true)
	assert_float(s.player_atb).is_equal(0.0)        # answer no-ops when over
	assert_object(s.player_attack()).is_null()
