## Tests for CombatMob — HP, damage, and the ATB gauge.
extends GdUnitTestSuite


func test_create_full_hp_alive() -> void:
	var m := CombatMob.create("Slime", 3, 2, 0.5)
	assert_int(m.max_hp).is_equal(3)
	assert_int(m.hp).is_equal(3)
	assert_int(m.attack).is_equal(2)
	assert_bool(m.is_alive()).is_true()
	assert_float(m.atb).is_equal(0.0)


func test_take_damage_floors_and_kills() -> void:
	var m := CombatMob.create("Slime", 3, 1, 0.0)
	m.take_damage(2)
	assert_int(m.hp).is_equal(1)
	assert_bool(m.is_alive()).is_true()
	m.take_damage(5)  # overkill floors at 0
	assert_int(m.hp).is_equal(0)
	assert_bool(m.is_alive()).is_false()


func test_advance_fills_and_caps() -> void:
	var m := CombatMob.create("Slime", 3, 1, 0.5)
	m.advance(1.0)
	assert_float(m.atb).is_equal(0.5)
	assert_bool(m.is_ready()).is_false()
	m.advance(2.0)  # 0.5 + 1.0 → capped at 1.0
	assert_float(m.atb).is_equal(1.0)
	assert_bool(m.is_ready()).is_true()


func test_dead_mob_does_not_advance() -> void:
	var m := CombatMob.create("Slime", 1, 1, 1.0)
	m.take_damage(1)
	m.advance(2.0)
	assert_float(m.atb).is_equal(0.0)
	assert_bool(m.is_ready()).is_false()


func test_reset_atb() -> void:
	var m := CombatMob.create("Slime", 3, 1, 1.0)
	m.advance(1.0)
	m.reset_atb()
	assert_float(m.atb).is_equal(0.0)


func test_create_clamps_minimums() -> void:
	var m := CombatMob.create("X", 0, -5, -1.0)
	assert_int(m.max_hp).is_equal(1)
	assert_int(m.attack).is_equal(0)
	assert_float(m.atb_rate).is_equal(0.0)
