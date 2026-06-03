## CombatState — pure state for one ATB fight (Model A).
##
## The player has an HP bar and an ATB gauge charged by *correct answers*
## (knowledge is the fuel). 1–3 CombatMobs each have HP and their own gauge
## that fills on a timer. The CombatController commits each answer to FSRS,
## then calls answer()/player_attack()/tick(); loot is rolled by the
## controller on WON (random cards, decoupled from the answered cards).
##
## Accuracy model: the HERO can miss (hero_accuracy; a miss still spends the
## gauge — that's the cost, and accuracy cards push it toward 100%). MOB
## attacks can miss (mob.accuracy) or be blocked (hero_block_chance) — both
## are upside variance for the player, raised by defense/evasion cards. All
## RNG is injectable so tests can force outcomes.
##
## No scene, no FSRS, no signals — pure and fully testable.
class_name CombatState
extends RefCounted

enum Outcome { ONGOING, WON, LOST }
enum AttackOutcome { HIT, MISS, BLOCKED }

var player_max_hp: int = 30
var player_hp: int = 30
var player_atb: float = 0.0        # 0..1; at 1.0 an attack is ready
var atb_per_correct: float = 0.34  # ~3 correct answers fill the gauge
var attack_damage: int = 1         # base damage per landed attack (the player's active power)
var damage_spread: int = 0         # ± range rolled around attack_damage per hit (0 = flat)
var crit_chance: float = 0.0       # chance a landed hit crits (sanctioned RNG; never punishes recall)
var crit_multiplier: float = 2.0   # crit damage multiplier
var hero_accuracy: float = 0.9     # chance a hero attack lands (cards push → 1.0)
var hero_block_chance: float = 0.2 # chance to block an incoming mob hit (cards raise)

# Limit break — a SECOND gauge, charged only by clutch (about-to-forget) recalls
# and by less per hit than the ATB. At full it's spent for one high-damage strike
# on every living mob. This is the clutch payoff, replacing the old instant ATB
# fill: clutch saves no longer trivialize tempo, they bank toward a big burst.
var limit: float = 0.0             # 0..1; at 1.0 a limit break is ready
var limit_per_clutch: float = 0.2  # charge added per clutch recall (< atb_per_correct)
var limit_damage: int = 1          # flat damage the break deals to ALL live mobs

var mobs: Array[CombatMob] = []
var rng: RandomNumberGenerator
var _target_index: int = -1


static func create(
	player_hp_: int,
	mobs_: Array[CombatMob],
	atb_per_correct_: float,
	attack_damage_: int,
	hero_accuracy_: float = 0.9,
	hero_block_chance_: float = 0.2,
	rng_: RandomNumberGenerator = null,
) -> CombatState:
	var s := CombatState.new()
	s.player_max_hp = maxi(1, player_hp_)
	s.player_hp = s.player_max_hp
	s.mobs = mobs_
	s.atb_per_correct = clampf(atb_per_correct_, 0.01, 1.0)
	s.attack_damage = maxi(1, attack_damage_)
	s.hero_accuracy = clampf(hero_accuracy_, 0.0, 1.0)
	s.hero_block_chance = clampf(hero_block_chance_, 0.0, 1.0)
	if rng_ != null:
		s.rng = rng_
	else:
		s.rng = RandomNumberGenerator.new()
		s.rng.randomize()
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


## Apply an answer's effect on the player gauge. Correct → charge ATB by
## atb_per_correct × charge_scale; wrong → nothing (lost tempo). The scale lets
## the caller reward special cards (e.g. a new card charges 1.5×). The FSRS
## commit and the follow-up attack are the caller's job.
func answer(correct: bool, charge_scale: float = 1.0) -> void:
	if is_over():
		return
	if correct:
		player_atb = minf(1.0, player_atb + atb_per_correct * maxf(0.0, charge_scale))


func limit_ready() -> bool:
	return limit >= 1.0


## Charge the limit gauge — the reward for a correct clutch (about-to-forget)
## recall. Adds limit_per_clutch (or an explicit amount), clamped to full. The
## caller gates this on correctness + clutch; deliberately NOT an ATB fill.
func charge_limit(amount: float = -1.0) -> void:
	if is_over():
		return
	var add := limit_per_clutch if amount < 0.0 else amount
	limit = minf(1.0, limit + maxf(0.0, add))


## Spend a full limit gauge: one high-damage strike on EVERY living mob. Flat
## limit_damage, no miss/crit — a guaranteed payoff. Resets the gauge and
## retargets. Returns {hits:[{mob_index, damage, killed}]} or {} if not ready.
func unleash_limit() -> Dictionary:
	if is_over() or not limit_ready():
		return {}
	limit = 0.0
	var hits: Array = []
	for i in mobs.size():
		var m: CombatMob = mobs[i]
		if not m.is_alive():
			continue
		m.take_damage(limit_damage)
		hits.append({"mob_index": i, "damage": limit_damage, "killed": not m.is_alive()})
	_retarget()
	return {"hits": hits}


## Spend a full gauge to strike the current target. Returns a result dict
## {outcome, mob, mob_index, damage, crit} — outcome HIT or MISS (a miss still
## spends the gauge). On a hit, damage is rolled within ±damage_spread of
## attack_damage and may crit (crit_chance → ×crit_multiplier). Returns {} if
## not ready or no live target.
func player_attack() -> Dictionary:
	if is_over() or not player_attack_ready():
		return {}
	var m := current_mob()
	if m == null:
		return {}
	var idx := _target_index
	player_atb = 0.0
	if rng.randf() >= hero_accuracy:
		return {"outcome": AttackOutcome.MISS, "mob": m, "mob_index": idx, "damage": 0, "crit": false}
	var dmg := _roll_attack_damage()
	var is_crit := rng.randf() < crit_chance
	if is_crit:
		dmg = maxi(1, int(round(dmg * crit_multiplier)))
	m.take_damage(dmg)
	if not m.is_alive():
		_retarget()
	return {"outcome": AttackOutcome.HIT, "mob": m, "mob_index": idx, "damage": dmg, "crit": is_crit}


## Roll a single hit's base damage: attack_damage ± damage_spread, floored at 1.
## With damage_spread 0 this is exactly attack_damage (the flat default).
func _roll_attack_damage() -> int:
	var lo := maxi(1, attack_damage - damage_spread)
	var hi := maxi(lo, attack_damage + damage_spread)
	return rng.randi_range(lo, hi)


## Advance real time: fill each live mob's gauge; a ready mob resolves an
## attack (HIT / MISS / BLOCKED) and resets. Returns the list of attack
## events resolved this tick: {outcome, mob_index, damage}.
func tick(delta: float) -> Array:
	var events: Array = []
	if is_over():
		return events
	for i in mobs.size():
		var m: CombatMob = mobs[i]
		if not m.is_alive():
			continue
		m.advance(delta)
		if m.is_ready():
			m.reset_atb()
			events.append(_resolve_mob_attack(i, m))
			if player_hp <= 0:
				break
	return events


func _resolve_mob_attack(index: int, m: CombatMob) -> Dictionary:
	if rng.randf() >= m.accuracy:
		return {"outcome": AttackOutcome.MISS, "mob_index": index, "damage": 0}
	if rng.randf() < hero_block_chance:
		return {"outcome": AttackOutcome.BLOCKED, "mob_index": index, "damage": 0}
	player_hp = maxi(0, player_hp - m.attack)
	return {"outcome": AttackOutcome.HIT, "mob_index": index, "damage": m.attack}


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
