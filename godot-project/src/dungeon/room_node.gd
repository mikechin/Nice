## RoomNode — one node in the fixed dungeon run-map graph.
##
## Pure data: a room kind, its depth (position along the fixed path — the
## locked "depth = position" rule that DepthDraw reads to bias the draw), a
## label, and the indices of the rooms reachable from it. Edges are
## forward-only (matches extraction tension: you extract or push, never
## retreat). RunMap owns the array of these and tracks which one is current.
class_name RoomNode
extends RefCounted

var index: int = -1
var type: DungeonEnums.RoomType = DungeonEnums.RoomType.ENCOUNTER
var depth: int = 0
var label: String = ""
var next: Array[int] = []     # forward edges (indices into RunMap.nodes)
var cleared: bool = false


static func create(
	index_: int,
	type_: DungeonEnums.RoomType,
	depth_: int,
	label_: String,
	next_: Array[int] = [],
) -> RoomNode:
	var n := RoomNode.new()
	n.index = index_
	n.type = type_
	n.depth = maxi(0, depth_)
	n.label = label_
	n.next = next_.duplicate()
	return n


## A fightable room (ENCOUNTER/ELITE/BOSS) runs combat; an EXTRACT gate does not.
func is_fight() -> bool:
	return DungeonEnums.is_fight(type)


func is_extract() -> bool:
	return type == DungeonEnums.RoomType.EXTRACT


func is_boss() -> bool:
	return type == DungeonEnums.RoomType.BOSS


## End of the path — no outgoing edges (the boss). Reaching/clearing it ends
## the run in a forced extraction.
func is_terminal() -> bool:
	return next.is_empty()
