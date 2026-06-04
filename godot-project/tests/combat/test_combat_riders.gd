## Tests for the M5 active-rider methods on CombatState — heal_player (MEND) and
## strike_target (BURN). Both fire on a correct answer, outside the ATB gauge.
extends GdUnitTestSuite


func _state(player_hp: int, mob_hp: int) -> CombatState:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	# atb_rate 0 → the mob never charges, so the fight stays put during the test.
	var mob := CombatMob.create("M", mob_hp, 1, 0.0)
	var mobs: Array[CombatMob] = [mob]
	return CombatState.create(player_hp, mobs, 0.34, 3, 0.9, 0.2, rng)


func test_heal_restores_and_caps_at_max() -> void:
	var s := _state(30, 5)
	s.player_hp = 20
	assert_int(s.heal_player(5)).is_equal(5)
	assert_int(s.player_hp).is_equal(25)
	# Overheal is capped at max and reports only what it actually restored.
	assert_int(s.heal_player(100)).is_equal(5)
	assert_int(s.player_hp).is_equal(30)


func test_heal_at_full_or_nonpositive_is_a_noop() -> void:
	var s := _state(30, 5)
	assert_int(s.heal_player(10)).is_equal(0)   # already full
	assert_int(s.heal_player(-3)).is_equal(0)   # nonsense amount
	assert_int(s.player_hp).is_equal(30)


func test_strike_target_chips_then_kills_and_retargets() -> void:
	var s := _state(30, 5)
	var hit := s.strike_target(2)
	assert_int(hit["damage"]).is_equal(2)
	assert_bool(hit["killed"]).is_false()
	assert_int(s.current_mob().hp).is_equal(3)

	var kill := s.strike_target(3)
	assert_bool(kill["killed"]).is_true()
	# Only mob down → retargets to none, and the fight is won.
	assert_object(s.current_mob()).is_null()
	assert_bool(s.outcome() == CombatState.Outcome.WON).is_true()


func test_strike_over_or_nonpositive_returns_empty() -> void:
	var s := _state(30, 5)
	assert_bool(s.strike_target(0).is_empty()).is_true()
	# After the fight is over, riders no-op.
	s.strike_target(5)                          # kills the lone mob → WON
	assert_bool(s.strike_target(3).is_empty()).is_true()
	assert_int(s.heal_player(5)).is_equal(0)
