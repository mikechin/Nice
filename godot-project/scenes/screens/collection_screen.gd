## CollectionScreen — Displays the character collection grid with filter and sort controls.
## Shows completion stats, tier distribution, and per-character detail on tap.
class_name CollectionScreen
extends Control

@onready var _grid_container: GridContainer = $ScrollContainer/GridContainer if has_node("ScrollContainer/GridContainer") else null
@onready var _sort_button: OptionButton = $Controls/SortButton if has_node("Controls/SortButton") else null
@onready var _filter_button: OptionButton = $Controls/FilterButton if has_node("Controls/FilterButton") else null
@onready var _completion_label: Label = $CompletionLabel if has_node("CompletionLabel") else null
@onready var _count_label: Label = $CountLabel if has_node("CountLabel") else null
@onready var _back_button: Button = $BackButton if has_node("BackButton") else null

var _collection_grid: CollectionGrid
var _current_sort: CollectionEnums.CollectionSort = CollectionEnums.CollectionSort.HSK_LEVEL
var _current_filter: CollectionEnums.CollectionFilter = CollectionEnums.CollectionFilter.ALL

## Preloaded scene for each grid cell. Falls back to creating cells in code.
var _cell_scene: PackedScene


func _ready() -> void:
	_collection_grid = CollectionGrid.new()

	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)

	_setup_sort_options()
	_setup_filter_options()

	if _sort_button:
		_sort_button.item_selected.connect(_on_sort_changed)
	if _filter_button:
		_filter_button.item_selected.connect(_on_filter_changed)

	# Try to load the cell scene
	if ResourceLoader.exists("res://scenes/components/collection_cell.tscn"):
		_cell_scene = load("res://scenes/components/collection_cell.tscn")

	_build_grid()

	SignalBus.srs_state_updated.connect(_on_srs_state_updated)


func _setup_sort_options() -> void:
	if _sort_button == null:
		return
	_sort_button.clear()
	_sort_button.add_item("HSK Level", CollectionEnums.CollectionSort.HSK_LEVEL)
	_sort_button.add_item("Tier", CollectionEnums.CollectionSort.TIER)
	_sort_button.add_item("Frequency", CollectionEnums.CollectionSort.FREQUENCY)


func _setup_filter_options() -> void:
	if _filter_button == null:
		return
	_filter_button.clear()
	_filter_button.add_item("All", CollectionEnums.CollectionFilter.ALL)
	_filter_button.add_item("Locked", CollectionEnums.CollectionFilter.LOCKED)
	_filter_button.add_item("Unlocked", CollectionEnums.CollectionFilter.UNLOCKED)
	_filter_button.add_item("Mastered", CollectionEnums.CollectionFilter.MASTERED)


func _build_grid() -> void:
	var now := Time.get_unix_time_from_system()
	_collection_grid.build_grid(GameState.character_db, GameState.review_scheduler, now)

	var characters: Array[String] = _collection_grid.get_sorted_characters(
		GameState.character_db, _current_sort, _current_filter
	)

	_update_stats()
	_populate_grid(characters)


func _populate_grid(characters: Array[String]) -> void:
	if _grid_container == null:
		return

	# Clear existing cells
	for child in _grid_container.get_children():
		child.queue_free()

	for ch in characters:
		var entry: Dictionary = _collection_grid.get_entry(ch)
		var tier: CollectionEnums.CardTier = entry.get("tier", CollectionEnums.CardTier.LOCKED)
		var cell: Control = _create_cell(ch, tier)
		_grid_container.add_child(cell)


func _create_cell(character: String, tier: CollectionEnums.CardTier) -> Control:
	var cell: Control
	if _cell_scene:
		cell = _cell_scene.instantiate()
	else:
		cell = _create_fallback_cell()

	if cell.has_method("setup_cell"):
		var card_data: CharacterData = GameState.character_db.get_character(character)
		cell.setup_cell(character, tier, card_data)
	return cell


func _create_fallback_cell() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(64, 64)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _update_stats() -> void:
	var unlocked: int = _collection_grid.get_unlocked_count()
	var total: int = _collection_grid.get_total_count()
	var pct: float = _collection_grid.get_completion_percentage() * 100.0

	if _completion_label:
		_completion_label.text = "%.1f%% Complete" % pct
	if _count_label:
		_count_label.text = "%d / %d" % [unlocked, total]


func _on_sort_changed(index: int) -> void:
	if _sort_button == null:
		return
	_current_sort = _sort_button.get_item_id(index) as CollectionEnums.CollectionSort
	_refresh_display()


func _on_filter_changed(index: int) -> void:
	if _filter_button == null:
		return
	_current_filter = _filter_button.get_item_id(index) as CollectionEnums.CollectionFilter
	_refresh_display()


func _refresh_display() -> void:
	var characters: Array[String] = _collection_grid.get_sorted_characters(
		GameState.character_db, _current_sort, _current_filter
	)
	_populate_grid(characters)


func _on_srs_state_updated(_card_id: String, _new_state: Dictionary) -> void:
	# Rebuild on state change to reflect tier changes
	_build_grid()


func _on_back_pressed() -> void:
	SignalBus.screen_transition_requested.emit("main_menu")
