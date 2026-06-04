## Tests for Stake — the entry-time snapshot of the equipped kit (= what's on the
## line). Snapshot semantics only; the loss/keep resolution is tested at the
## GameState integration layer.
extends GdUnitTestSuite


func _ci(card_id: String) -> CardInstance:
	var ci := CardInstance.create(card_id, EconomyEnums.Rarity.COMMON)
	ci.id = "id_" + card_id
	return ci


func test_from_loadout_snapshots_equipped_cards() -> void:
	var lo := Loadout.new()
	lo.set_slot(0, _ci("我"))
	lo.set_slot(3, _ci("跑"))
	var s := Stake.from_loadout(lo)
	assert_int(s.size()).is_equal(2)
	assert_bool(s.card_ids().has("我")).is_true()
	assert_bool(s.card_ids().has("跑")).is_true()


func test_empty_loadout_is_an_empty_stake() -> void:
	var s := Stake.from_loadout(Loadout.new())
	assert_bool(s.is_empty()).is_true()
	assert_int(s.size()).is_equal(0)


func test_null_loadout_is_safe() -> void:
	var s := Stake.from_loadout(null)
	assert_bool(s.is_empty()).is_true()


func test_snapshot_is_detached_from_later_loadout_changes() -> void:
	# The stake is a snapshot: stripping the loadout afterward doesn't shrink it.
	var lo := Loadout.new()
	lo.set_slot(0, _ci("我"))
	var s := Stake.from_loadout(lo)
	lo.strip_all()
	assert_int(s.size()).is_equal(1)
