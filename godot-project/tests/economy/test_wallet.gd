## Tests for Wallet — the shard balance. Never negative, spends are
## all-or-nothing, and it round-trips.
extends GdUnitTestSuite


func test_starts_empty() -> void:
	assert_int(Wallet.new().shards).is_equal(0)


func test_add_and_ignore_nonpositive() -> void:
	var w := Wallet.new()
	w.add(10)
	w.add(-5)   # ignored
	w.add(0)    # ignored
	assert_int(w.shards).is_equal(10)


func test_spend_all_or_nothing() -> void:
	var w := Wallet.new()
	w.add(10)
	assert_bool(w.can_afford(7)).is_true()
	assert_bool(w.spend(7)).is_true()
	assert_int(w.shards).is_equal(3)
	# Can't overspend; balance is untouched on failure.
	assert_bool(w.spend(99)).is_false()
	assert_int(w.shards).is_equal(3)


func test_round_trip() -> void:
	var w := Wallet.new()
	w.add(42)
	var restored := Wallet.new()
	restored.load_from_dict(w.to_dict())
	assert_int(restored.shards).is_equal(42)
