## CombatMob — one enemy in an ATB fight (Model A).
##
## Has HP, an attack value, and an ATB gauge that fills on a timer; when the
## gauge is full the mob strikes the player. A mob is a generic enemy — it is
## NOT bound to any card. Loot (random card instances) is rolled separately
## when the whole encounter is cleared. Pure state; CombatState drives it.
class_name CombatMob
extends RefCounted

var label: String = "Mob"
var max_hp: int = 3
var hp: int = 3
var attack: int = 1        # damage dealt to the player when its gauge fills
var atb: float = 0.0       # 0..1; at 1.0 the mob is ready to strike
var atb_rate: float = 0.0  # gauge units filled per second


static func create(label_: String, hp_: int, attack_: int, atb_rate_: float) -> CombatMob:
	var m := CombatMob.new()
	m.label = label_
	m.max_hp = maxi(1, hp_)
	m.hp = m.max_hp
	m.attack = maxi(0, attack_)
	m.atb_rate = maxf(0.0, atb_rate_)
	m.atb = 0.0
	return m


func is_alive() -> bool:
	return hp > 0


func take_damage(n: int) -> void:
	hp = maxi(0, hp - maxi(0, n))


## Advance the gauge by `delta` seconds (no-op when dead or already full).
func advance(delta: float) -> void:
	if not is_alive() or atb >= 1.0:
		return
	atb = minf(1.0, atb + atb_rate * delta)


## True when the gauge is full and the mob is alive (ready to strike).
func is_ready() -> bool:
	return is_alive() and atb >= 1.0


func reset_atb() -> void:
	atb = 0.0
