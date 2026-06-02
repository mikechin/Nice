## CombatState — pure state for one ATB fight (Model A).
##
## The player has an HP bar and an ATB gauge charged by *correct answers*
## (knowledge is the fuel). 1–3 CombatMobs each have HP and their own gauge
## that fills on a timer. The CombatController commits each answer to FSRS,
## then calls answer()/player_attack()/tick(); loot is rolled by the
## controller on WON (random cards, decoupled from the answered cards).
##
## No scene, no FSRS, no signals — pure and fully testable (tick takes an
## explicit delta).
class_name CombatState
extends RefCounted

enum Outcome { ONGOING, WON, LOST }

var player_max_hp: int = 30
var player_hp: int = 30
var player_atb: float = 0.0        # 0..1; at 1.0 an attack is ready
var atb_per_correct: float = 0.34  # ~3 correct answers fill the gauge
var attack_damage: int = 1         # damage per attack (the player's active power)

var mobs: Array[CombatMob] = []
var _target_index: int = -1


static func create(player_hp_: int, mobs_: Array[CombatMob], atb_per_correct_: float, attack_damage_: int) -> CombatState:
	var s := CombatState.new()
	s.player_max_hp = maxi(1, player_hp_)
	s.player_hp = s.player_max_hp
	s.mobs = mobs_
	s.atb_per_correct = clampf(atb_per_correct_, 0.01, 1.0)
	s.attack_damage = maxi(1, attack_damage_)
	s._retarget()
	return s


func current_mob() -> CombatMob:
	if _target_index < 0 or _target_index >= mobs.size():
		return null
	return mobs[_target_index]


func current_target_index() -> int:
	return _target_index


## Choose which mob to focus. Ignores out-of-range / dead targets.
func set_target(index: int) -> void:
	if index >= 0 and index < mobs.size() and mobs[index].is_alive():
		_target_index = index


func player_attack_ready() -> bool:
	return player_atb >= 1.0


## Apply an answer's effect on the player gauge. Correct → charge ATB; wrong
## → nothing (lost tempo). The FSRS commit and the follow-up attack are the
## caller's job.
func answer(correct: bool) -> void:
	if is_over():
		return
	if correct:
		player_atb = minf(1.0, player_atb + atb_per_correct)


## Spend a full gauge to strike the current target. No-op if not ready or no
## live target. Returns the struck mob (or null).
func player_attack() -> CombatMob:
	if is_over() or not player_attack_ready():
		return null
	var m := current_mob()
	if m == null:
		return null
	m.take_damage(attack_damage)
	player_atb = 0.0
	if not m.is_alive():
		_retarget()
	return m


## Advance real time: fill each live mob's gauge; a ready mob strikes the
## player and resets. Stops early if the player dies.
func tick(delta: float) -> void:
	if is_over():
		return
	for m in mobs:
		if not m.is_alive():
			continue
		m.advance(delta)
		if m.is_ready():
			player_hp = maxi(0, player_hp - m.attack)
			m.reset_atb()
			if player_hp <= 0:
				return


func outcome() -> Outcome:
	if player_hp <= 0:
		return Outcome.LOST
	if _alive_count() == 0:
		return Outcome.WON
	return Outcome.ONGOING


func is_over() -> bool:
	return outcome() != Outcome.ONGOING


func alive_count() -> int:
	return _alive_count()


func _alive_count() -> int:
	var n := 0
	for m in mobs:
		if m.is_alive():
			n += 1
	return n


func _retarget() -> void:
	for i in mobs.size():
		if mobs[i].is_alive():
			_target_index = i
			return
	_target_index = -1
