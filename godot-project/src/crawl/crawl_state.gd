## CrawlState — crawl-scoped state that must survive the crawl → battle → crawl
## scene swaps (Phase 3 crawler pivot). Lives on RunState (the cross-scene
## holder) alongside the DungeonRun: the run owns HP / haul / economy; this owns
## where the hero is standing and whether the room's warden has been beaten.
##
## Reset per run (RunState.begin_run makes a fresh one). Pure data; no scene.
class_name CrawlState
extends RefCounted

var hero_pos: Vector2 = Vector2.ZERO
var has_pos: bool = false               # false on first entry → spawn at the door
var warden_defeated: bool = false       # warden down → the extraction door opens
var warden_fight_pending: bool = false  # set when launching the warden fight


## Stash the hero's position before a scene swap so we return where we left off.
func save_hero(pos: Vector2) -> void:
	hero_pos = pos
	has_pos = true
