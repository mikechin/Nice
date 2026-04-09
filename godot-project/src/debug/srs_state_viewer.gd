## SrsStateViewer — Data-only utility for querying SRS state across all cards.
## Lists cards with their current tier, retrievability, and due status.
## No UI — used by debug panels and test harnesses.
class_name SrsStateViewer
extends RefCounted


## Return a summary of every card in the scheduler.
## Each entry: { card_id, character, tier, tier_name, avg_retrievability, is_due, weakest_type, best_state, max_stability }
func get_all_card_summaries(scheduler: ReviewScheduler, now: float) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []

	for card_id in scheduler.card_states:
		var cs: CardState = scheduler.card_states[card_id]
		var tier: CollectionEnums.CardTier = CardTierCalculator.calculate_tier(cs)
		var avg_r: float = cs.get_average_retrievability(now)
		var is_due: bool = cs.is_any_due(now)
		var weakest: String = cs.get_weakest_challenge_type()
		var best_state: int = cs.get_best_state()
		var max_stability: float = cs.get_max_stability()

		summaries.append({
			"card_id": card_id,
			"character": cs.character,
			"tier": tier,
			"tier_name": CollectionEnums.tier_name(tier),
			"avg_retrievability": avg_r,
			"is_due": is_due,
			"weakest_type": weakest,
			"best_state": best_state,
			"best_state_name": _state_name(best_state),
			"max_stability": max_stability,
		})

	return summaries


## Return a breakdown of how many cards are at each tier.
## Keys are CollectionEnums.CardTier values, values are counts.
func get_tier_distribution(scheduler: ReviewScheduler) -> Dictionary:
	var distribution: Dictionary = {}

	# Initialize all tiers to zero
	for tier_val in range(CollectionEnums.CardTier.LOCKED, CollectionEnums.CardTier.LEGENDARY + 1):
		distribution[tier_val] = 0

	for card_id in scheduler.card_states:
		var cs: CardState = scheduler.card_states[card_id]
		var tier: int = CardTierCalculator.calculate_tier(cs)
		distribution[tier] = distribution.get(tier, 0) + 1

	return distribution


## Return the number of cards due for review right now.
func get_due_count(scheduler: ReviewScheduler, now: float) -> int:
	var count: int = 0
	for card_id in scheduler.card_states:
		var cs: CardState = scheduler.card_states[card_id]
		if cs.is_any_due(now):
			count += 1
	return count


## Return cards sorted by retrievability (ascending — most at risk first).
func get_cards_by_urgency(scheduler: ReviewScheduler, now: float) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = get_all_card_summaries(scheduler, now)

	# Filter out new cards (no retrievability data)
	var reviewed: Array[Dictionary] = []
	for s in summaries:
		if s["best_state"] != FsrsAlgorithm.State.NEW:
			reviewed.append(s)

	# Sort ascending by avg_retrievability (lowest = most urgent)
	reviewed.sort_custom(_compare_by_retrievability)
	return reviewed


## Return cards that are about to be forgotten (below threshold).
func get_at_risk_cards(scheduler: ReviewScheduler, now: float) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = get_all_card_summaries(scheduler, now)
	var at_risk: Array[Dictionary] = []

	for s in summaries:
		if s["best_state"] == FsrsAlgorithm.State.NEW:
			continue
		if s["avg_retrievability"] < SrsConfig.ABOUT_TO_FORGET_THRESHOLD:
			at_risk.append(s)

	return at_risk


## Return a per-challenge-type breakdown for a single card.
func get_card_detail(scheduler: ReviewScheduler, card_id: String, now: float) -> Dictionary:
	if card_id not in scheduler.card_states:
		return {}

	var cs: CardState = scheduler.card_states[card_id]
	var detail: Dictionary = {
		"card_id": card_id,
		"character": cs.character,
		"tier": CardTierCalculator.calculate_tier(cs),
		"challenge_types": {},
	}

	for ct_str in ["meaning", "character", "pinyin", "tone"]:
		var state_dict: Dictionary = cs.get_state_for_type(ct_str)
		var retrievability: float = cs.get_retrievability(ct_str, now)
		var is_due: bool = cs.is_due(ct_str, now)

		detail["challenge_types"][ct_str] = {
			"state": state_dict.get("state", FsrsAlgorithm.State.NEW),
			"state_name": _state_name(state_dict.get("state", FsrsAlgorithm.State.NEW)),
			"stability": state_dict.get("stability", 0.0),
			"difficulty": state_dict.get("difficulty", 0.0),
			"reps": state_dict.get("reps", 0),
			"lapses": state_dict.get("lapses", 0),
			"last_review": state_dict.get("last_review", 0.0),
			"retrievability": retrievability,
			"is_due": is_due,
		}

	return detail


## Return summary statistics across the entire collection.
func get_collection_stats(scheduler: ReviewScheduler, now: float) -> Dictionary:
	var total: int = scheduler.card_states.size()
	var due: int = get_due_count(scheduler, now)
	var distribution: Dictionary = get_tier_distribution(scheduler)
	var at_risk: int = get_at_risk_cards(scheduler, now).size()

	var total_retrievability: float = 0.0
	var reviewed_count: int = 0
	for card_id in scheduler.card_states:
		var cs: CardState = scheduler.card_states[card_id]
		if not cs.is_new():
			total_retrievability += cs.get_average_retrievability(now)
			reviewed_count += 1

	var avg_retrievability: float = 0.0
	if reviewed_count > 0:
		avg_retrievability = total_retrievability / float(reviewed_count)

	return {
		"total_cards": total,
		"due_count": due,
		"at_risk_count": at_risk,
		"reviewed_count": reviewed_count,
		"new_count": total - reviewed_count,
		"avg_retrievability": avg_retrievability,
		"tier_distribution": distribution,
	}


static func _compare_by_retrievability(a: Dictionary, b: Dictionary) -> bool:
	return a["avg_retrievability"] < b["avg_retrievability"]


static func _state_name(state: int) -> String:
	match state:
		FsrsAlgorithm.State.NEW: return "New"
		FsrsAlgorithm.State.LEARNING: return "Learning"
		FsrsAlgorithm.State.REVIEW: return "Review"
		FsrsAlgorithm.State.RELEARNING: return "Relearning"
	return "Unknown"
