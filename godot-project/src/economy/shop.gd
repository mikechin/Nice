## Shop — the town store (Phase 3, M4).
##
## Rotating, shards-priced stock of two kinds:
##   - CARD       : a RAW instance of a character the player has ALREADY met
##                  (binder-known). This is craft-ingredient smoothing — buy the
##                  3rd 氵 mate you couldn't find — plus loadout filler.
##   - CONSUMABLE : one-shot town/dungeon goods (hint, revive, …). Effects are
##                  wired in a later milestone; the store-front + purchase exist now.
##
## Two LOCKED invariants the shop must never violate (2026-06-02):
##   1. NEVER sells new/undiscovered characters — stock is drawn only from the
##      binder's seen set, so you can't BUY knowledge; the shop feeds the crafter,
##      it never bypasses it (binder = genuinely learned).
##   2. NEVER sells grades — every card is RAW (grade 0). Grading happens only at
##      the crafter.
##
## Pure orchestration over injected economy structs (+ the SignalBus-free path),
## rng injectable for deterministic restocks.
class_name Shop
extends RefCounted

enum Kind { CARD, CONSUMABLE }

const CARD_PRICE: int = 5            # a raw common ingredient is cheap by design
const DEFAULT_STOCK_SIZE: int = 6
const CARD_RARITY: int = EconomyEnums.Rarity.COMMON  # shop cards are always common-raw

## The fixed consumable catalogue (id → {label, price}). Effects land later.
const CONSUMABLES := {
	"dungeon_hint": { "label": "Dungeon Hint", "price": 8 },
	"revive": { "label": "Revive Token", "price": 30 },
}

var _inventory: Inventory
var _wallet: Wallet
var _binder: Binder
var rng := RandomNumberGenerator.new()

# Each entry: { kind: Kind, price: int, card_id|item_id: String, rarity?: int, label: String }
var stock: Array = []


func _init(inventory: Inventory, wallet: Wallet, binder: Binder) -> void:
	_inventory = inventory
	_wallet = wallet
	_binder = binder


## Rebuild the rotating stock: up to `card_slots` raw-common cards sampled from
## the binder's seen characters, plus the consumable catalogue. With no characters
## met yet, there simply are no card entries (only consumables).
func restock(card_slots: int = DEFAULT_STOCK_SIZE) -> void:
	stock.clear()
	for card_id in _sample(_binder.get_seen_ids(), card_slots):
		stock.append({
			"kind": Kind.CARD,
			"card_id": card_id,
			"rarity": CARD_RARITY,
			"price": CARD_PRICE,
			"label": card_id,
		})
	for item_id in CONSUMABLES:
		var c: Dictionary = CONSUMABLES[item_id]
		stock.append({
			"kind": Kind.CONSUMABLE,
			"item_id": item_id,
			"price": int(c["price"]),
			"label": String(c["label"]),
		})


func size() -> int:
	return stock.size()


func get_item(index: int) -> Dictionary:
	return stock[index] if (index >= 0 and index < stock.size()) else {}


## Buy stock item `index`. Debits the wallet and, for a card, mints a RAW instance
## onto the bench; the item is removed from the rotating stock. Returns
## { ok, kind, price, instance?/item_id, reason }. Nothing changes on failure.
func buy(index: int) -> Dictionary:
	if index < 0 or index >= stock.size():
		return { "ok": false, "reason": "no such item" }
	var item: Dictionary = stock[index]
	if not _wallet.can_afford(int(item["price"])):
		return { "ok": false, "reason": "not enough shards" }

	if int(item["kind"]) == Kind.CARD:
		# Defensive re-check of the never-new invariant at purchase time.
		if not _binder.is_seen(String(item["card_id"])):
			return { "ok": false, "reason": "the shop never sells undiscovered characters" }
		_wallet.spend(int(item["price"]))
		var ci := _inventory.add(CardInstance.create(String(item["card_id"]), int(item["rarity"])))
		stock.remove_at(index)
		return { "ok": true, "kind": Kind.CARD, "instance": ci, "card_id": ci.card_id, "price": int(item["price"]) }

	# Consumable: charge + remove. (Granting the effect/consumable inventory is a
	# later milestone — the purchase plumbing exists now.)
	_wallet.spend(int(item["price"]))
	var item_id := String(item["item_id"])
	stock.remove_at(index)
	return { "ok": true, "kind": Kind.CONSUMABLE, "item_id": item_id, "price": int(item["price"]) }


## Random sample of up to `n` distinct entries from `pool`, using the injected rng
## so restocks are deterministic when seeded.
func _sample(pool: Array, n: int) -> Array:
	var copy := pool.duplicate()
	var out: Array = []
	while not copy.is_empty() and out.size() < n:
		var i := rng.randi() % copy.size()
		out.append(copy[i])
		copy.remove_at(i)
	return out
