## CombatMods — the summed combat bonuses an equipped kit contributes (Phase 3, M5).
##
## A plain accumulator produced by CombatLoadout.assemble: passive kinds add to the
## whole-run stat fields (attack / max_hp / block / crit / atb / accuracy), active
## kinds add to the per-correct-answer riders (burn / heal). Fields stay floats while
## summing across cards; combat reads the integer channels through *_i() so rounding
## happens once, at the end. No scene, no RNG — a derived runtime value, never saved.
class_name CombatMods
extends RefCounted

# Passive — applied to CombatState at fight setup.
var attack: float = 0.0       # + base attack damage
var max_hp: float = 0.0       # + player max HP
var block: float = 0.0        # + block chance (0..1 added)
var crit: float = 0.0         # + crit chance
var atb: float = 0.0          # + ATB charge per correct answer
var accuracy: float = 0.0     # + hero accuracy

# Active — fired on each correct answer during the fight.
var burn: float = 0.0         # bonus flat damage to the current target
var heal: float = 0.0         # HP restored to the hero


func add(channel: String, amount: float) -> void:
	match channel:
		"attack": attack += amount
		"max_hp": max_hp += amount
		"block": block += amount
		"crit": crit += amount
		"atb": atb += amount
		"accuracy": accuracy += amount
		"burn": burn += amount
		"heal": heal += amount


func attack_i() -> int:
	return int(round(attack))


func max_hp_i() -> int:
	return int(round(max_hp))


func burn_i() -> int:
	return int(round(burn))


func heal_i() -> int:
	return int(round(heal))


func is_empty() -> bool:
	return attack == 0.0 and max_hp == 0.0 and block == 0.0 and crit == 0.0 \
		and atb == 0.0 and accuracy == 0.0 and burn == 0.0 and heal == 0.0


## Compact human-readable buff list for the UI ("+3 atk · +12 HP · 2 burn/ans").
## Only non-zero channels appear; empty kit → "no bonuses".
func summary() -> String:
	var parts: Array[String] = []
	if attack_i() != 0:
		parts.append("+%d atk" % attack_i())
	if max_hp_i() != 0:
		parts.append("+%d HP" % max_hp_i())
	if block != 0.0:
		parts.append("+%d%% block" % int(round(block * 100.0)))
	if crit != 0.0:
		parts.append("+%d%% crit" % int(round(crit * 100.0)))
	if atb != 0.0:
		parts.append("+%d%% charge" % int(round(atb * 100.0)))
	if accuracy != 0.0:
		parts.append("+%d%% acc" % int(round(accuracy * 100.0)))
	if burn_i() != 0:
		parts.append("%d burn/ans" % burn_i())
	if heal_i() != 0:
		parts.append("%d heal/ans" % heal_i())
	if parts.is_empty():
		return "no bonuses"
	return "  ·  ".join(parts)
