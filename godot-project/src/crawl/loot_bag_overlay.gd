## LootBagOverlay — the loot-bag grid (Phase 3, crawler loot UI).
##
## A modal grid of the run's carried CardInstances, opened two ways:
##   - BROWSE: the player opens it from the crawl HUD (button / B key) to look at
##     the haul, reorder it, and drop cards they don't want (→ shards at extract).
##   - FORCED: a battle dropped more than the bag holds → the crawl auto-opens it
##     on overflow and gates "Done" until the haul fits the carry cap, so the
##     player has to choose what to keep and what to drop on the spot.
##
## It drives a DungeonRun directly (drop_instance / reorder_haul) and renders one
## LootBagCell per carried instance in a GridContainer — a real grid so the actual
## card art slots straight in later. Built in code; a CanvasLayer so it floats over
## the Node2D crawl world. Reusable: the town/home loadout can mount the same node.
class_name LootBagOverlay
extends CanvasLayer

const MAX_COLS := 6
const PANEL_SIZE := Vector2(1180, 760)

signal closed

var _run: DungeonRun
var _forced: bool = false

var _scrim: ColorRect
var _panel: Panel
var _title: Label
var _capacity: Label
var _hint: Label
var _grid: GridContainer
var _shard_label: Label
var _drop_button: Button
var _done_button: Button
var _cells: Array[LootBagCell] = []


func _ready() -> void:
	layer = 128
	visible = false
	_ensure_built()


## Open the bag on `run`. `forced` makes it an overflow triage: the player can't
## leave (Done stays disabled) until the haul fits the carry cap.
func open(run: DungeonRun, forced: bool = false) -> void:
	_ensure_built()
	_run = run
	_forced = forced
	visible = true
	_rebuild()


func close() -> void:
	# A forced overflow can't be dismissed until the bag actually fits.
	if _forced and _run != null and _run.overflow() > 0:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


## Columns for `count` cards — a single row up to MAX_COLS, then wrap. Never 0
## (GridContainer requires >= 1 column). Pure for tests.
static func columns_for(count: int) -> int:
	return clampi(count, 1, MAX_COLS)


# -- build -------------------------------------------------------------------

func _ensure_built() -> void:
	if _grid != null:
		return

	_scrim = ColorRect.new()
	_scrim.color = Color(UiTokens.BG_DEEP.r, UiTokens.BG_DEEP.g, UiTokens.BG_DEEP.b, 0.82)
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP   # swallow clicks to the world
	add_child(_scrim)

	_panel = Panel.new()
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_left = -PANEL_SIZE.x * 0.5
	_panel.offset_top = -PANEL_SIZE.y * 0.5
	_panel.offset_right = PANEL_SIZE.x * 0.5
	_panel.offset_bottom = PANEL_SIZE.y * 0.5
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.BG
	sb.set_corner_radius_all(UiTokens.R_XL)
	sb.set_border_width_all(2)
	sb.border_color = UiTokens.HAIRLINE
	sb.set_content_margin_all(UiTokens.S_5)
	_panel.add_theme_stylebox_override("panel", sb)
	_scrim.add_child(_panel)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = UiTokens.S_5
	root.offset_top = UiTokens.S_5
	root.offset_right = -UiTokens.S_5
	root.offset_bottom = -UiTokens.S_5
	root.add_theme_constant_override("separation", UiTokens.S_4)
	_panel.add_child(root)

	# Header row: title + live capacity readout.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", UiTokens.S_4)
	root.add_child(header)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", UiTokens.T_H1)
	_title.add_theme_color_override("font_color", UiTokens.INK)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)

	_capacity = Label.new()
	_capacity.add_theme_font_size_override("font_size", UiTokens.T_H2)
	_capacity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_capacity)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", UiTokens.T_BODY)
	_hint.add_theme_color_override("font_color", UiTokens.INK_3)
	root.add_child(_hint)

	# The card grid, centered in a scroll region so a big haul stays reachable.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var grid_wrap := CenterContainer.new()
	grid_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid_wrap)

	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", UiTokens.S_4)
	_grid.add_theme_constant_override("v_separation", UiTokens.S_4)
	grid_wrap.add_child(_grid)

	# Footer: shard preview + the two actions.
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", UiTokens.S_4)
	root.add_child(footer)

	_shard_label = Label.new()
	_shard_label.add_theme_font_size_override("font_size", UiTokens.T_BODY)
	_shard_label.add_theme_color_override("font_color", UiTokens.INK_2)
	_shard_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shard_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_shard_label)

	_drop_button = Button.new()
	_drop_button.pressed.connect(_on_drop_marked)
	footer.add_child(_drop_button)

	_done_button = Button.new()
	_done_button.pressed.connect(close)
	footer.add_child(_done_button)


# -- rendering ---------------------------------------------------------------

func _rebuild() -> void:
	_ensure_built()
	_cells.clear()
	for child in _grid.get_children():
		child.queue_free()
	if _run == null:
		return
	_grid.columns = columns_for(_run.haul.size())
	for i in _run.haul.size():
		var cell := LootBagCell.build(_run.haul[i], i)
		cell.clicked.connect(_on_cell_clicked)
		cell.request_reorder.connect(_on_reorder)
		_grid.add_child(cell)
		_cells.append(cell)
	_refresh_chrome()


func _marked_cells() -> Array[LootBagCell]:
	var out: Array[LootBagCell] = []
	for cell in _cells:
		if cell.marked:
			out.append(cell)
	return out


func _refresh_chrome() -> void:
	if _run == null:
		return
	var carrying := _run.haul.size()
	var cap := _run.carry_cap
	var over := _run.overflow()

	_title.text = "BAG OVERFLOW" if (_forced and over > 0) else "LOOT BAG"

	_capacity.text = "%d / %d" % [carrying, cap]
	_capacity.add_theme_color_override("font_color", UiTokens.INCORRECT if over > 0 else UiTokens.INK_2)

	if _forced and over > 0:
		_hint.text = "Your bag is full. Mark %d to drop, then Drop them to fit." % over
	else:
		_hint.text = "Tap a card to mark it · drag to reorder · dropped cards shatter into shards"

	var marked := _marked_cells()
	var shards := 0
	for cell in marked:
		shards += cell.instance.shard_value()
	_drop_button.text = "Drop marked (%d) → +%d shards" % [marked.size(), shards]
	_drop_button.disabled = marked.is_empty()

	_done_button.text = "Done"
	_done_button.disabled = _forced and over > 0


# -- interactions ------------------------------------------------------------

func _on_cell_clicked(_cell: LootBagCell) -> void:
	_refresh_chrome()


func _on_drop_marked() -> void:
	if _run == null:
		return
	for cell in _marked_cells():
		_run.drop_instance(cell.instance)
	AudioManager.play_sfx("button_tap")
	_rebuild()


func _on_reorder(from_index: int, to_index: int) -> void:
	if _run == null:
		return
	var haul := _run.haul
	if from_index < 0 or from_index >= haul.size() or to_index < 0 or to_index >= haul.size():
		return
	var order: Array = haul.duplicate()
	var moved: CardInstance = order[from_index]
	var target: CardInstance = order[to_index]
	order.erase(moved)
	order.insert(order.find(target), moved)   # reinsert before the drop target
	_run.reorder_haul(order)
	_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_B):
		close()
		get_viewport().set_input_as_handled()
