## DepthDraw — depth-biased card selection for dungeon rooms (Phase 3, M2).
##
## The locked "depth biases the draw" rule (dungeon-crawler-direction.md:
## "Deeper rooms pull lower-stability, less-mastered characters as prompts").
## Shallow rooms surface ordinary due reviews; deeper rooms tilt the draw
## toward the cards you know least — the harder, more valuable reviews. This is
## a *bias on RNG*, never a power handout: it only changes which card you're
## quizzed on, and every answer still routes through the one honest
## record_review commit in combat.
##
## Split for testability: weight_for() is the deterministic core (no RNG, hit
## directly in tests); draw_from() samples a pure {id, stability} list; draw()
## is the thin adapter that builds that list from a ReviewScheduler.
class_name DepthDraw
extends RefCounted

## How hard each depth level tilts toward low stability. At depth 0 the bias
## term is zero so every card weighs exactly 1.0 (uniform — no bias). Tuning.
const DEPTH_BIAS_K := 6.0


## Selection weight for one card given its memory stability and the room depth.
## Depth 0 → 1.0 for every card (uniform). Deeper → low-stability cards earn
## strictly more weight than high-stability ones; the reciprocal keeps it
## bounded and always ≥ 1.0 (monotonically decreasing in stability).
static func weight_for(stability: float, depth: int) -> float:
	var s := maxf(0.0, stability)
	return 1.0 + (float(maxi(0, depth)) * DEPTH_BIAS_K) / (1.0 + s)


## Weighted sample without replacement from a pure list of {id, stability}
## dicts. Returns up to `count` distinct ids. RNG is injectable so tests can
## force the draw; when null a fresh randomized RNG is used.
static func draw_from(entries: Array, depth: int, count: int, rng: RandomNumberGenerator = null) -> Array[String]:
	var picked: Array[String] = []
	if entries.is_empty() or count <= 0:
		return picked
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	# Work on a copy of (id, weight) so we can remove as we draw.
	var pool: Array = []
	for e in entries:
		var id: String = e.get("id", "")
		if id == "":
			continue
		pool.append({"id": id, "w": weight_for(float(e.get("stability", 0.0)), depth)})

	var take := mini(count, pool.size())
	for _i in take:
		var total := 0.0
		for p in pool:
			total += p["w"]
		if total <= 0.0:
			break
		var roll := rng.randf() * total
		var acc := 0.0
		var chosen := -1
		for j in pool.size():
			acc += pool[j]["w"]
			if roll <= acc:
				chosen = j
				break
		if chosen < 0:
			chosen = pool.size() - 1
		picked.append(pool[chosen]["id"])
		pool.remove_at(chosen)
	return picked


## Build the {id, stability} candidate list from the scheduler, then draw.
## Candidate pool = due cards + new cards (the cards a session would surface);
## falls back to every registered card if that's empty. Stability is the card's
## max across challenge types (its strongest memory) — low here = a card the
## player hasn't locked in, exactly what depth wants to dredge up.
static func draw(scheduler: ReviewScheduler, now: float, depth: int, count: int, rng: RandomNumberGenerator = null) -> Array[String]:
	return draw_from(_candidate_entries(scheduler, now), depth, count, rng)


static func _candidate_entries(scheduler: ReviewScheduler, now: float) -> Array:
	var seen := {}
	var entries: Array = []

	for cs in scheduler.get_due_cards(now):
		if cs.card_id in seen:
			continue
		seen[cs.card_id] = true
		entries.append({"id": cs.card_id, "stability": cs.get_max_stability()})

	for nid in scheduler.get_new_card_ids():
		if nid in seen:
			continue
		seen[nid] = true
		var ncs: CardState = scheduler.card_states.get(nid)
		entries.append({"id": nid, "stability": ncs.get_max_stability() if ncs != null else 0.0})

	if entries.is_empty():
		for cid in scheduler.card_states:
			var cs: CardState = scheduler.card_states[cid]
			entries.append({"id": cid, "stability": cs.get_max_stability()})

	return entries
