## Tests for DepthDraw — depth-biased card selection.
## weight_for is the deterministic core (depth 0 uniform; deeper favors low
## stability). draw_from is tested structurally + for seeded reproducibility,
## avoiding statistical flakiness.
extends GdUnitTestSuite


func _entries() -> Array:
	return [
		{"id": "a", "stability": 0.5},    # weakly known
		{"id": "b", "stability": 5.0},
		{"id": "c", "stability": 50.0},   # well mastered
		{"id": "d", "stability": 150.0},
	]


func test_depth_zero_is_uniform() -> void:
	assert_float(DepthDraw.weight_for(0.5, 0)).is_equal(1.0)
	assert_float(DepthDraw.weight_for(50.0, 0)).is_equal(1.0)
	assert_float(DepthDraw.weight_for(150.0, 0)).is_equal(1.0)


func test_depth_favors_low_stability() -> void:
	var w_low := DepthDraw.weight_for(0.5, 4)
	var w_mid := DepthDraw.weight_for(5.0, 4)
	var w_high := DepthDraw.weight_for(150.0, 4)
	# Lower stability → strictly more weight at depth.
	assert_float(w_low).is_greater(w_mid)
	assert_float(w_mid).is_greater(w_high)
	# Weight is always at least 1.0 (the uniform floor).
	assert_float(w_high).is_greater_equal(1.0)


func test_deeper_increases_bias() -> void:
	# The same low-stability card gets more weight the deeper you go.
	var shallow := DepthDraw.weight_for(0.5, 1)
	var deep := DepthDraw.weight_for(0.5, 5)
	assert_float(deep).is_greater(shallow)


func test_draw_from_returns_distinct_subset() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var picked := DepthDraw.draw_from(_entries(), 3, 3, rng)
	assert_int(picked.size()).is_equal(3)
	# No duplicates.
	var unique := {}
	for id in picked:
		unique[id] = true
	assert_int(unique.size()).is_equal(3)
	# Subset of the input ids.
	for id in picked:
		assert_bool(id in ["a", "b", "c", "d"]).is_true()


func test_draw_from_caps_at_pool_size() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var picked := DepthDraw.draw_from(_entries(), 2, 99, rng)
	# Asked for 99 but only 4 exist → returns all 4, distinct.
	assert_int(picked.size()).is_equal(4)
	assert_array(picked).contains_exactly_in_any_order(["a", "b", "c", "d"])


func test_draw_from_empty_is_empty() -> void:
	assert_array(DepthDraw.draw_from([], 3, 5)).is_empty()
	assert_array(DepthDraw.draw_from(_entries(), 3, 0)).is_empty()


func test_draw_from_is_seed_reproducible() -> void:
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 42
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 42
	var a := DepthDraw.draw_from(_entries(), 3, 3, rng1)
	var b := DepthDraw.draw_from(_entries(), 3, 3, rng2)
	assert_array(a).is_equal(b)


func test_draw_from_skips_blank_ids() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var entries := [{"id": "", "stability": 1.0}, {"id": "x", "stability": 1.0}]
	var picked := DepthDraw.draw_from(entries, 0, 5, rng)
	assert_array(picked).is_equal(["x"])
