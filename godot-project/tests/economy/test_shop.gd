## Tests for Shop — the town store. Enforces the two LOCKED invariants (never
## sells undiscovered characters, never sells grades) plus purchase mechanics
## (debit + mint, affordability, rotating stock). rng seeded for determinism.
extends GdUnitTestSuite

var _inv: Inventory
var _wallet: Wallet
var _binder: Binder
var _shop: Shop


func before_test() -> void:
	_inv = Inventory.new()
	_wallet = Wallet.new()
	_binder = Binder.new()
	_shop = Shop.new(_inv, _wallet, _binder)
	_shop.rng.seed = 999


func _see(ids: Array) -> void:
	for id in ids:
		_binder.record_seen(id)


func _card_entries() -> Array:
	return _shop.stock.filter(func(e): return int(e["kind"]) == Shop.Kind.CARD)


func test_stock_cards_are_only_discovered_characters() -> void:
	_see(["好", "学", "水"])
	_shop.restock()
	var cards := _card_entries()
	assert_int(cards.size()).is_greater(0)
	for e in cards:
		assert_bool(_binder.is_seen(String(e["card_id"]))).is_true()


func test_never_sells_an_undiscovered_character() -> void:
	# Binder knows only 好; 火 was never met → can never appear in stock.
	_see(["好"])
	_shop.restock()
	for e in _card_entries():
		assert_str(String(e["card_id"])).is_not_equal("火")


func test_empty_binder_yields_no_card_stock() -> void:
	_shop.restock()                      # nothing discovered yet
	assert_int(_card_entries().size()).is_equal(0)
	# ...but consumables still stock (they aren't characters).
	assert_int(_shop.size()).is_greater(0)


func test_all_card_stock_is_raw_never_graded() -> void:
	_see(["好", "学", "水", "大"])
	_shop.restock()
	for e in _card_entries():
		assert_int(int(e["rarity"])).is_equal(EconomyEnums.Rarity.COMMON)
	# And a bought card mints RAW.
	_wallet.add(50)
	var idx := _shop.stock.find_custom(func(e): return int(e["kind"]) == Shop.Kind.CARD)
	var res := _shop.buy(idx)
	assert_bool(res["ok"]).is_true()
	assert_bool(res["instance"].is_raw()).is_true()


func test_buying_a_card_debits_and_mints() -> void:
	_see(["好"])
	_shop.restock()
	_wallet.add(50)
	var idx := _shop.stock.find_custom(func(e): return int(e["kind"]) == Shop.Kind.CARD)
	var before := _shop.size()
	var res := _shop.buy(idx)
	assert_bool(res["ok"]).is_true()
	assert_int(_wallet.shards).is_equal(50 - Shop.CARD_PRICE)
	assert_int(_inv.size()).is_equal(1)
	assert_int(_inv.count_of("好")).is_equal(1)
	assert_int(_shop.size()).is_equal(before - 1)        # sold item leaves the rotation


func test_cannot_afford_is_rejected_and_mints_nothing() -> void:
	_see(["好"])
	_shop.restock()                                      # wallet is empty
	var idx := _shop.stock.find_custom(func(e): return int(e["kind"]) == Shop.Kind.CARD)
	var res := _shop.buy(idx)
	assert_bool(res["ok"]).is_false()
	assert_int(_inv.size()).is_equal(0)


func test_buying_a_consumable_debits_wallet() -> void:
	_shop.restock()
	_wallet.add(100)
	var idx := _shop.stock.find_custom(func(e): return int(e["kind"]) == Shop.Kind.CONSUMABLE)
	var price := int(_shop.stock[idx]["price"])
	var res := _shop.buy(idx)
	assert_bool(res["ok"]).is_true()
	assert_int(res["kind"]).is_equal(Shop.Kind.CONSUMABLE)
	assert_int(_wallet.shards).is_equal(100 - price)


func test_buy_out_of_range_is_safe() -> void:
	_shop.restock()
	assert_bool(_shop.buy(-1)["ok"]).is_false()
	assert_bool(_shop.buy(9999)["ok"]).is_false()
