## FsrsAlgorithm — Core FSRS (Free Spaced Repetition Scheduler) implementation.
## Ported from ts-fsrs (FSRS-6). This is the heart of the entire app.
## See: https://github.com/open-spaced-repetition/ts-fsrs
class_name FsrsAlgorithm
extends RefCounted

# FSRS-6 default parameters (21 weights)
const DEFAULT_WEIGHTS: Array[float] = [
	0.212, 1.2931, 2.3065, 8.2956,   # w[0-3]: initial stability for Again/Hard/Good/Easy
	6.4133, 0.8334,                    # w[4-5]: initial difficulty
	3.0194, 0.001,                     # w[6-7]: difficulty update
	1.8722, 0.1666, 0.796,            # w[8-10]: recall stability
	1.4835, 0.0614, 0.2629,           # w[11-13]: forget stability
	1.6483, 0.6014, 1.8729,           # w[14-16]: forget stability R factor, hard penalty, easy bonus
	0.5425, 0.0912,                    # w[17-18]: short-term stability
	0.0658,                            # w[19]: short-term S exponent
	0.1542,                            # w[20]: decay (FSRS-6)
]

const S_MIN: float = 0.001
const S_MAX: float = 36500.0
const INIT_S_MAX: float = 100.0

enum State { NEW, LEARNING, REVIEW, RELEARNING }
enum Rating { AGAIN = 1, HARD = 2, GOOD = 3, EASY = 4 }

var weights: Array[float] = DEFAULT_WEIGHTS.duplicate()
var desired_retention: float = 0.9
var maximum_interval: int = 36500
var enable_short_term: bool = true

## Decay and factor derived from w[20].
var _decay: float
var _factor: float


func _init() -> void:
	_update_decay_factor()


func set_weights(w: Array[float]) -> void:
	weights = w.duplicate()
	_update_decay_factor()


func _update_decay_factor() -> void:
	_decay = -weights[20] if weights.size() > 20 else -0.5
	_factor = exp(log(0.9) / _decay) - 1.0


# ---------------------------------------------------------------------------
# Forgetting curve
# ---------------------------------------------------------------------------

## Power forgetting curve — returns retrievability R in [0, 1].
## R(t, S) = (1 + FACTOR * t / S) ^ DECAY
func forgetting_curve(elapsed_days: float, stability: float) -> float:
	if stability < S_MIN:
		return 0.0
	return pow(1.0 + _factor * elapsed_days / stability, _decay)


# ---------------------------------------------------------------------------
# Initial values for new cards
# ---------------------------------------------------------------------------

## Initial stability after the very first review.
## S_0(G) = clamp(w[G-1], 0.1, INIT_S_MAX)
func init_stability(rating: int) -> float:
	var idx := clampi(rating - 1, 0, 3)
	return clampf(weights[idx], 0.1, INIT_S_MAX)


## Initial difficulty after the first review.
## D_0(G) = w[4] - exp((G - 1) * w[5]) + 1, clamped to [1, 10]
func init_difficulty(rating: int) -> float:
	var g := clampf(float(rating), 1.0, 4.0)
	return clampf(weights[4] - exp((g - 1.0) * weights[5]) + 1.0, 1.0, 10.0)


# ---------------------------------------------------------------------------
# Difficulty update
# ---------------------------------------------------------------------------

## Update difficulty after a review.
func next_difficulty(d: float, rating: int) -> float:
	var g := float(rating)
	var delta_d := -weights[6] * (g - 3.0)
	# Linear damping toward boundaries
	var linear_damping := delta_d * (10.0 - d) / 9.0
	# Mean reversion toward D_0(3)
	var d0_g3 := init_difficulty(Rating.GOOD)
	var new_d := weights[7] * d0_g3 + (1.0 - weights[7]) * (d + linear_damping)
	return clampf(new_d, 1.0, 10.0)


# ---------------------------------------------------------------------------
# Stability update
# ---------------------------------------------------------------------------

## Stability after a successful recall (rating >= Hard on a due card).
func next_stability_after_success(d: float, s: float, r: float, rating: int) -> float:
	var hard_penalty := weights[15] if rating == Rating.HARD else 1.0
	var easy_bonus := weights[16] if rating == Rating.EASY else 1.0
	var sinc := s * (exp(weights[8]) * (11.0 - d) * pow(s, -weights[9]) * (exp(weights[10] * (1.0 - r)) - 1.0) * hard_penalty * easy_bonus + 1.0)
	return clampf(sinc, S_MIN, S_MAX)


## Stability after forgetting (rating == Again on a due card).
func next_stability_after_failure(d: float, s: float, r: float) -> float:
	var new_s := weights[11] * pow(d, -weights[12]) * (pow(s + 1.0, weights[13]) - 1.0) * exp(weights[14] * (1.0 - r))
	return clampf(new_s, S_MIN, S_MAX)


## Short-term stability update (for learning/relearning, elapsed_days == 0).
func short_term_stability(s: float, rating: int) -> float:
	var g := float(rating)
	var sinc := s * exp(weights[17] * (g - 3.0 + weights[18])) * pow(s, -weights[19])
	# For Hard or better, stability should not decrease
	if rating >= Rating.HARD:
		sinc = maxf(sinc, s)
	return clampf(sinc, S_MIN, S_MAX)


# ---------------------------------------------------------------------------
# Interval calculation
# ---------------------------------------------------------------------------

## Calculate the next review interval in days from stability and desired retention.
func next_interval(stability: float) -> int:
	if stability < S_MIN:
		return 1
	var interval := (pow(desired_retention, 1.0 / _decay) - 1.0) / _factor * stability
	return clampi(roundi(interval), 1, maximum_interval)


# ---------------------------------------------------------------------------
# Card creation
# ---------------------------------------------------------------------------

## Create a fresh card state dictionary.
func init_card() -> Dictionary:
	return {
		"state": State.NEW,
		"stability": 0.0,
		"difficulty": 0.0,
		"elapsed_days": 0,
		"scheduled_days": 0,
		"reps": 0,
		"lapses": 0,
		"last_review": 0.0,
	}


# ---------------------------------------------------------------------------
# Core review — compute next state after a rating
# ---------------------------------------------------------------------------

## Process a review and return the updated card state dictionary.
## `card` is a card state dict, `rating` is Rating enum (1-4), `now` is unix timestamp.
func review(card: Dictionary, rating: int, now: float) -> Dictionary:
	var result := card.duplicate(true)
	var s: float = card.get("stability", 0.0)
	var d: float = card.get("difficulty", 0.0)
	var state: int = card.get("state", State.NEW)
	var last_review: float = card.get("last_review", 0.0)

	# Calculate elapsed days since last review
	var elapsed_days: float = 0.0
	if last_review > 0.0:
		elapsed_days = maxf(0.0, (now - last_review) / 86400.0)

	# Compute retrievability
	var r: float = 1.0
	if s > S_MIN and elapsed_days > 0.0:
		r = forgetting_curve(elapsed_days, s)

	# --- State machine ---
	if state == State.NEW:
		# First ever review — initialize
		s = init_stability(rating)
		d = init_difficulty(rating)
		if rating == Rating.AGAIN:
			result["state"] = State.LEARNING
			result["scheduled_days"] = 0
		else:
			result["state"] = State.REVIEW
			result["scheduled_days"] = next_interval(s)
	elif elapsed_days == 0.0 and enable_short_term and state != State.REVIEW:
		# Short-term review (same day, still in learning/relearning)
		s = short_term_stability(s, rating)
		d = next_difficulty(d, rating)
		if rating == Rating.AGAIN:
			result["state"] = State.RELEARNING if state == State.REVIEW else State.LEARNING
			result["scheduled_days"] = 0
		else:
			result["state"] = State.REVIEW
			result["scheduled_days"] = next_interval(s)
	elif rating == Rating.AGAIN:
		# Lapse — forgot the card
		var floor_s := s / exp(weights[17] * weights[18]) if weights.size() > 18 else s
		s = minf(next_stability_after_failure(d, s, r), floor_s)
		d = next_difficulty(d, rating)
		result["state"] = State.RELEARNING
		result["lapses"] = card.get("lapses", 0) + 1
		result["scheduled_days"] = 0
	else:
		# Successful recall
		s = next_stability_after_success(d, s, r, rating)
		d = next_difficulty(d, rating)
		result["state"] = State.REVIEW
		result["scheduled_days"] = next_interval(s)

	result["stability"] = s
	result["difficulty"] = d
	result["elapsed_days"] = roundi(elapsed_days)
	result["reps"] = card.get("reps", 0) + 1
	result["last_review"] = now

	return result


## Preview all four ratings and return { rating -> card_state }.
func repeat(card: Dictionary, now: float) -> Dictionary:
	var results := {}
	for r in [Rating.AGAIN, Rating.HARD, Rating.GOOD, Rating.EASY]:
		results[r] = review(card, r, now)
	return results


## Get current retrievability for a card at time `now`.
func get_retrievability(card: Dictionary, now: float) -> float:
	var s: float = card.get("stability", 0.0)
	var last_review: float = card.get("last_review", 0.0)
	if s < S_MIN or last_review <= 0.0:
		return 0.0
	var elapsed := maxf(0.0, (now - last_review) / 86400.0)
	return forgetting_curve(elapsed, s)
