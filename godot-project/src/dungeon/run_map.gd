## RunMap — the one pre-rendered dungeon layout for 1.0 (Phase 3, M2).
##
## A hand-built, fixed node graph (dungeon-crawler-direction.md: "Ship 1.0
## with ONE pre-rendered dungeon. The layout is hand-built and fixed; the
## cards filling each room are drawn live from FSRS every run."). Replayability
## comes from the scheduler procedurally selecting the cards, not from
## procedural layout. This class owns the graph + a traversal cursor; it knows
## nothing about combat or FSRS.
##
## Cursor model: `current()` is the node the player is standing on. A fightable
## node starts uncleared (you fight it); once cleared the player picks among
## `available_next()` and `move_to()`s a forward edge. EXTRACT gates are not
## fought — arriving on one is a leave-or-push decision the controller drives.
## Forward-only: move_to only accepts a node listed in the current node's edges.
class_name RunMap
extends RefCounted

var nodes: Array[RoomNode] = []
var current_index: int = 0


## The fixed 1.0 layout: enter → branching segment → elite → extract gate →
## deeper segment → elite → extract gate → boss. Depth never decreases along
## an edge (forward-only descent).
static func build_default() -> RunMap:
	var m := RunMap.new()
	var RT := DungeonEnums.RoomType
	m.nodes = [
		RoomNode.create(0, RT.ENCOUNTER, 0, "Entrance", [1, 2]),    # telegraphed branch
		RoomNode.create(1, RT.ENCOUNTER, 1, "East Path", [3]),
		RoomNode.create(2, RT.ENCOUNTER, 1, "West Path", [3]),
		RoomNode.create(3, RT.ELITE,     2, "Warden",    [4]),
		RoomNode.create(4, RT.EXTRACT,   2, "Extract I", [5]),       # gate: leave or push
		RoomNode.create(5, RT.ENCOUNTER, 3, "Deep Hall", [6]),
		RoomNode.create(6, RT.ELITE,     4, "Deep Warden", [7]),
		RoomNode.create(7, RT.EXTRACT,   4, "Extract II", [8]),      # gate: leave or push
		RoomNode.create(8, RT.BOSS,      5, "Boss",      []),        # terminal
	]
	m.current_index = 0
	return m


func current() -> RoomNode:
	if current_index < 0 or current_index >= nodes.size():
		return null
	return nodes[current_index]


func get_node_at(index: int) -> RoomNode:
	if index < 0 or index >= nodes.size():
		return null
	return nodes[index]


## Rooms reachable from the current node (the player's branch choices). One
## entry = a straight corridor; more than one = a telegraphed branch.
func available_next() -> Array[RoomNode]:
	var out: Array[RoomNode] = []
	var cur := current()
	if cur == null:
		return out
	for i in cur.next:
		var n := get_node_at(i)
		if n != null:
			out.append(n)
	return out


func can_move_to(index: int) -> bool:
	var cur := current()
	return cur != null and index in cur.next


## Advance along a forward edge. Rejects any non-adjacent target (forward-only,
## no backtracking). Returns false if the move is illegal.
func move_to(index: int) -> bool:
	if not can_move_to(index):
		return false
	current_index = index
	return true


func mark_current_cleared() -> void:
	var cur := current()
	if cur != null:
		cur.cleared = true


## The run is complete once the boss (the terminal node) is cleared.
func is_complete() -> bool:
	var cur := current()
	return cur != null and cur.is_terminal() and cur.cleared
