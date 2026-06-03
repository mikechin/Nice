## Wallet — the player's shard balance (Phase 3, M3).
##
## Shards are the soft currency: you earn them by shattering raw/dupe instances
## (and as small run drops), and spend them on grading crafts and shop deals in
## town (M4). A deliberately tiny, well-guarded value type — never goes negative,
## spends are all-or-nothing. Pure data; SaveManager persists it.
class_name Wallet
extends RefCounted

var shards: int = 0


## Add shards (negative amounts are ignored — use spend() to deduct).
func add(amount: int) -> void:
	if amount <= 0:
		return
	shards += amount


func can_afford(amount: int) -> bool:
	return amount >= 0 and shards >= amount


## Deduct `amount` if affordable. Returns true on success, false (no change) if
## you can't cover it — all-or-nothing, never goes negative.
func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	shards -= amount
	return true


func to_dict() -> Dictionary:
	return { "shards": shards }


func load_from_dict(d: Dictionary) -> void:
	shards = maxi(0, int(d.get("shards", 0)))
