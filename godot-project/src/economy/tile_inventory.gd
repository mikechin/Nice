## TileInventory — Manages the player's character tile collection.
## Tiles are consumable — earned through runs, spent in sentence building.
class_name TileInventory
extends RefCounted

var tiles: Dictionary = {}  # character -> count


func add_tile(character: String, count: int = 1) -> void:
	tiles[character] = tiles.get(character, 0) + count
	SignalBus.tiles_changed.emit(character, tiles[character])


func remove_tile(character: String, count: int = 1) -> bool:
	if get_count(character) < count:
		return false
	tiles[character] -= count
	if tiles[character] <= 0:
		tiles.erase(character)
	SignalBus.tiles_changed.emit(character, tiles.get(character, 0))
	return true


func remove_tiles(characters: Array) -> bool:
	# Check availability first
	var needed: Dictionary = {}
	for ch in characters:
		var ch_str := str(ch)
		needed[ch_str] = needed.get(ch_str, 0) + 1
	for ch_str in needed:
		if get_count(ch_str) < needed[ch_str]:
			return false
	# Deduct
	for ch_str in needed:
		tiles[ch_str] -= needed[ch_str]
		if tiles[ch_str] <= 0:
			tiles.erase(ch_str)
		SignalBus.tiles_changed.emit(ch_str, tiles.get(ch_str, 0))
	SignalBus.tiles_spent.emit(characters)
	return true


func get_count(character: String) -> int:
	return tiles.get(character, 0)


func has_tile(character: String) -> bool:
	return get_count(character) > 0


func get_all_tiles() -> Dictionary:
	return tiles


func get_total_tile_count() -> int:
	var total := 0
	for ch in tiles:
		total += tiles[ch]
	return total


func get_unique_tile_count() -> int:
	return tiles.size()


func clear() -> void:
	tiles.clear()


func to_dict() -> Dictionary:
	return tiles.duplicate()


func load_from_dict(data: Dictionary) -> void:
	tiles = data.duplicate()
