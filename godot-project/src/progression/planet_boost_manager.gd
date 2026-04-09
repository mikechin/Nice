## PlanetBoostManager — Manages permanent mastery bonuses (planet-style).
## Earned through demonstrated mastery, not purchased.
class_name PlanetBoostManager
extends RefCounted

var active_boosts: Array[String] = []
var milestone_progress: Dictionary = {}

## Boost definitions: id -> { requirement, multiplier, description }
const BOOST_DEFINITIONS: Dictionary = {
	"coin_boost_1": {"requirement": "master_25", "multiplier": 1.1, "description": "Master 25 characters: +10% coins"},
	"coin_boost_2": {"requirement": "master_100", "multiplier": 1.2, "description": "Master 100 characters: +20% coins"},
	"xp_boost_1": {"requirement": "streak_7", "multiplier": 1.15, "description": "7-day streak: +15% experience"},
	"xp_boost_2": {"requirement": "streak_30", "multiplier": 1.3, "description": "30-day streak: +30% experience"},
	"rare_boost": {"requirement": "master_50_rare", "multiplier": 1.5, "description": "50 Rare+ cards: +50% rare card chance"},
	"new_card_boost": {"requirement": "accuracy_90", "multiplier": 1.25, "description": "90% accuracy: +25% new card rate"},
}


func check_milestones(stats: Dictionary) -> Array:
	var newly_unlocked: Array = []
	var mastered: int = stats.get("total_characters_mastered", 0)
	var streak: int = stats.get("current_streak", 0)
	var rare_count: int = stats.get("rare_plus_count", 0)
	var accuracy: float = stats.get("accuracy", 0.0)

	if mastered >= 25 and "coin_boost_1" not in active_boosts:
		active_boosts.append("coin_boost_1")
		newly_unlocked.append("coin_boost_1")

	if mastered >= 100 and "coin_boost_2" not in active_boosts:
		active_boosts.append("coin_boost_2")
		newly_unlocked.append("coin_boost_2")

	if streak >= 7 and "xp_boost_1" not in active_boosts:
		active_boosts.append("xp_boost_1")
		newly_unlocked.append("xp_boost_1")

	if streak >= 30 and "xp_boost_2" not in active_boosts:
		active_boosts.append("xp_boost_2")
		newly_unlocked.append("xp_boost_2")

	if rare_count >= 50 and "rare_boost" not in active_boosts:
		active_boosts.append("rare_boost")
		newly_unlocked.append("rare_boost")

	if accuracy >= 0.9 and "new_card_boost" not in active_boosts:
		active_boosts.append("new_card_boost")
		newly_unlocked.append("new_card_boost")

	for boost_id in newly_unlocked:
		SignalBus.planet_boost_unlocked.emit(boost_id)

	return newly_unlocked


func get_active_boosts() -> Array[String]:
	return active_boosts


func get_boost_multiplier(boost_id: String) -> float:
	if boost_id not in active_boosts:
		return 1.0
	var def: Dictionary = BOOST_DEFINITIONS.get(boost_id, {})
	return def.get("multiplier", 1.0)


func get_combined_coin_multiplier() -> float:
	var mult := 1.0
	for boost_id in active_boosts:
		if boost_id.begins_with("coin_boost"):
			mult *= get_boost_multiplier(boost_id)
	return mult


func apply_boosts(base_value: int, boost_type: String) -> int:
	var mult := 1.0
	for boost_id in active_boosts:
		if boost_id.contains(boost_type):
			mult *= get_boost_multiplier(boost_id)
	return roundi(float(base_value) * mult)


func get_milestone_definitions() -> Array:
	var result: Array = []
	for boost_id in BOOST_DEFINITIONS:
		var def: Dictionary = BOOST_DEFINITIONS[boost_id].duplicate()
		def["id"] = boost_id
		def["unlocked"] = boost_id in active_boosts
		result.append(def)
	return result


func to_dict() -> Dictionary:
	return {
		"active_boosts": active_boosts,
	}


static func from_dict(data: Dictionary) -> PlanetBoostManager:
	var pbm := PlanetBoostManager.new()
	var boosts: Array = data.get("active_boosts", [])
	for b in boosts:
		pbm.active_boosts.append(str(b))
	return pbm
