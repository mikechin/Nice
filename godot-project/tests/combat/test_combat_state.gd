## Tests for CombatState — ATB charge, hero attacks (hit/miss), mob attacks
## (hit/miss/block), win/loss. Probabilities are forced to 0/1 so outcomes
## are deterministic without RNG seeding.
extends GdUnitTestSuite


func _mob(hp: int, atk: int, rate: float, acc: float = 1.0) -> CombatMob:
	return CombatMob.create("M", hp, atk, rate, acc)


func _state(php: int, mobs: Array[CombatMob], dmg: int = 2, hero_acc: float = 1.0, block: float = 0.0) -> CombatState:
	return CombatState.create(php, mobs, 0.5, dmg, hero_acc, block)


func test_create_targets_first_mob_player_full() -> void:
	var s := _state(10, [_mob(2, 1, 0.0), _mob(2, 1, 0.0)])
	assert_int(s.player_hp).is_equal(10)
	assert_int(s.current_target_index()).is_equal(0)
	assert_int(s.outcome()).is_equal(CombatState.Outcome.ONGOING)
	assert_bool(s.player_attack_ready()).is_false()


func test_correct_answers_charge_atb_to_ready() -> void:
	var s := _state(10, [_mob(2, 1, 0.0)])
	s.answer(true)
	assert_bool(s.player_attack_ready()).is_false()
	s.answer(true)
	assert_bool(s.player_attack_ready()).is_true()


func test_wrong_answer_does_not_charge() -> void:
	var s := _state(10, [_mob(2, 1, 0.0)])
	s.answer(false)
	assert_float(s.player_atb).is_equal(0.0)


func test_hero_attack_hits_and_resets_gauge() -> void:
	var s := _state(10, [_mob(5, 1, 0.0)], 2, 1.0)  # hero_acc 1.0 → always hits
	s.answer(true)
	s.answer(true)
	var res := s.player_attack()
	assert_int(res["outcome"]).is_equal(CombatState.AttackOutcome.HIT)
	assert_int(s.mobs[0].hp).is_equal(3)
	assert_float(s.player_atb).is_equal(0.0)


func test_hero_attack_can_miss_and_still_spends_gauge() -> void:
	var s := _state(10, [_mob(5, 1, 0.0)], 2, 0.0)  # hero_acc 0.0 → always misses
	s.answer(true)
	s.answer(true)
	var res := s.player_attack()
	assert_int(res["outcome"]).is_equal(CombatState.AttackOutcome.MISS)
	assert_int(s.mobs[0].hp).is_equal(5)        # no damage on a miss
	assert_float(s.player_atb).is_equal(0.0)    # but the gauge is still spent
	assert_bool(res["crit"]).is_false()


func test_no_crit_or_spread_keeps_flat_base_damage() -> void:
	# Defaults (spread 0, crit 0) → exactly attack_damage, never a crit.
	var s := _state(10, [_mob(20, 1, 0.0)], 3, 1.0)
	s.answer(true)
	s.answer(true)
	var res := s.player_attack()
	assert_int(res["damage"]).is_equal(3)
	assert_bool(res["crit"]).is_false()


func test_damage_spread_rolls_within_attack_range() -> void:
	var s := _state(10, [_mob(20, 1, 0.0)], 3, 1.0)  # base dmg 3, always hits
	s.damage_spread = 1                              # → rolls 2..4
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	s.rng = rng
	s.answer(true)
	s.answer(true)
	var res := s.player_attack()
	var dmg: int = res["damage"]
	assert_int(dmg).is_greater_equal(2)
	assert_int(dmg).is_less_equal(4)
	assert_bool(res["crit"]).is_false()
	assert_int(s.mobs[0].hp).is_equal(20 - dmg)      # mob took exactly the rolled damage


func test_crit_multiplies_damage() -> void:
	var s := _state(10, [_mob(20, 1, 0.0)], 3, 1.0)  # base dmg 3, always hits
	s.damage_spread = 0
	s.crit_chance = 1.0                              # force every hit to crit
	s.crit_multiplier = 2.0
	s.answer(true)
	s.answer(true)
	var res := s.player_attack()
	assert_bool(res["crit"]).is_true()
	assert_int(res["damage"]).is_equal(6)            # 3 × 2
	assert_int(s.mobs[0].hp).is_equal(14)            # 20 − 6


func test_attack_not_ready_is_empty() -> void:
	var s := _state(10, [_mob(5, 1, 0.0)])
	assert_bool(s.player_attack().is_empty()).is_true()
	assert_int(s.mobs[0].hp).is_equal(5)


func test_killing_all_mobs_wins() -> void:
	var s := _state(10, [_mob(2, 1, 0.0)], 2, 1.0)
	s.answer(true)
	s.answer(true)
	s.player_attack()
	assert_int(s.outcome()).is_equal(CombatState.Outcome.WON)


func test_multi_mob_retargets_after_kill() -> void:
	var s := _state(10, [_mob(2, 1, 0.0), _mob(2, 1, 0.0)], 2, 1.0)
	s.answer(true)
	s.answer(true)
	s.player_attack()
	assert_int(s.current_target_index()).is_equal(1)
	assert_int(s.outcome()).is_equal(CombatState.Outcome.ONGOING)


func test_tick_mob_hit_damages_player() -> void:
	var s := _state(10, [_mob(5, 3, 1.0, 1.0)], 2, 1.0, 0.0)  # mob acc 1.0, block 0.0 → HIT
	var events := s.tick(1.0)
	assert_int(events.size()).is_equal(1)
	assert_int(events[0]["outcome"]).is_equal(CombatState.AttackOutcome.HIT)
	assert_int(s.player_hp).is_equal(7)
	assert_float(s.mobs[0].atb).is_equal(0.0)


func test_tick_mob_miss_deals_no_damage() -> void:
	var s := _state(10, [_mob(5, 3, 1.0, 0.0)], 2, 1.0, 0.0)  # mob acc 0.0 → MISS
	var events := s.tick(1.0)
	assert_int(events[0]["outcome"]).is_equal(CombatState.AttackOutcome.MISS)
	assert_int(s.player_hp).is_equal(10)


func test_tick_block_deals_no_damage() -> void:
	var s := _state(10, [_mob(5, 3, 1.0, 1.0)], 2, 1.0, 1.0)  # mob would hit, block 1.0 → BLOCKED
	var events := s.tick(1.0)
	assert_int(events[0]["outcome"]).is_equal(CombatState.AttackOutcome.BLOCKED)
	assert_int(s.player_hp).is_equal(10)


func test_player_dies_when_hp_zero() -> void:
	var s := _state(3, [_mob(5, 3, 1.0, 1.0)], 2, 1.0, 0.0)
	s.tick(1.0)
	assert_int(s.player_hp).is_equal(0)
	assert_int(s.outcome()).is_equal(CombatState.Outcome.LOST)


func test_set_target_switches_and_ignores_dead() -> void:
	var s := _state(10, [_mob(2, 1, 0.0), _mob(2, 1, 0.0)], 2, 1.0)
	s.set_target(1)
	assert_int(s.current_target_index()).is_equal(1)
	s.answer(true)
	s.answer(true)
	s.player_attack()  # kills mob 1 → auto-retargets to 0
	assert_int(s.current_target_index()).is_equal(0)
	s.set_target(1)  # mob 1 dead → ignored
	assert_int(s.current_target_index()).is_equal(0)


func test_over_stops_answer_attack_tick() -> void:
	var s := _state(3, [_mob(2, 3, 1.0, 1.0)], 2, 1.0, 0.0)
	s.tick(1.0)  # LOST
	s.answer(true)
	assert_float(s.player_atb).is_equal(0.0)
	assert_bool(s.player_attack().is_empty()).is_true()
	assert_int(s.tick(1.0).size()).is_equal(0)  # tick no-ops once over
