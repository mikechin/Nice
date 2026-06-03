## ScreenNavigator — Autoload that listens to screen_transition_requested
## and swaps the current scene to the requested screen.
class_name ScreenNavigatorClass
extends Node

const SCREEN_PATHS: Dictionary = {
	"main_menu": "res://scenes/screens/main_menu.tscn",
	"run_select": "res://scenes/screens/run_select.tscn",
	"game": "res://scenes/screens/game_screen.tscn",
	"dungeon_map": "res://scenes/screens/dungeon_map.tscn",
	"combat": "res://scenes/screens/combat.tscn",
	"results": "res://scenes/screens/results_screen.tscn",
	"collection": "res://scenes/screens/collection_screen.tscn",
	"profile": "res://scenes/screens/profile_screen.tscn",
	"settings": "res://scenes/screens/settings_screen.tscn",
}

var _is_transitioning: bool = false


func _ready() -> void:
	SignalBus.screen_transition_requested.connect(_on_screen_transition_requested)


func _on_screen_transition_requested(screen_name: String) -> void:
	if _is_transitioning:
		return
	var path: String = SCREEN_PATHS.get(screen_name, "")
	if path.is_empty():
		push_error("ScreenNavigator: Unknown screen '%s'" % screen_name)
		return
	_is_transitioning = true
	get_tree().change_scene_to_file(path)
	# change_scene_to_file is deferred — reset on next frame
	await get_tree().process_frame
	_is_transitioning = false
