## RunState — Autoload holding the active DungeonRun across scene swaps.
##
## The dungeon uses full-scene navigation (ScreenNavigator does
## change_scene_to_file, which destroys the outgoing scene and carries no
## payload), so the run lifecycle can't live on any one screen. The map screen
## and the combat screen both read the active run — and *which room is being
## entered* — from here. This is the agreed home for run state (vs. a single
## host scene that swaps internal views): it stays consistent with the existing
## GameState-style autoload spine and solves param-passing in one move.
##
## Holds no game logic of its own — DungeonRun owns the rules; this is the
## handle the screens share.
class_name RunStateClass
extends Node

var run: DungeonRun = null
var current_room: RoomNode = null


## Start a fresh run on the default map at full HP. Returns the new run.
func begin_run(max_hp: int = DungeonRun.DEFAULT_MAX_HP, carry_cap: int = DungeonRun.DEFAULT_CARRY_CAP) -> DungeonRun:
	run = DungeonRun.create(RunMap.build_default(), max_hp, carry_cap)
	current_room = run.map.current()
	run.reached(current_room)
	return run


func has_active_run() -> bool:
	return run != null and not run.is_over()


## Set the room the player is moving into (combat reads this on _ready) and
## bump the run's deepest-depth marker.
func enter_room(room: RoomNode) -> void:
	current_room = room
	if run != null:
		run.reached(room)


func clear_run() -> void:
	run = null
	current_room = null
