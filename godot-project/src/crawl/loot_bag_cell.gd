## LootBagCell — one card slot in the loot-bag grid (Phase 3, crawler loot UI).
##
## A placeholder card face for a CardInstance: the character glyph, a rarity-tinted
## border, and its rarity/grade tag — shaped portrait/card-proportioned so the real
## card art drops straight in here later. Two interactions, matching the loot-bag
## brief:
##   - TAP toggles the cell "marked to drop"; the overlay batch-shatters the marked
##     cells into shards on confirm.
##   - DRAG reorders the bag (engine drag-and-drop): the dragged cell emits
##     request_reorder(from, to) and the overlay rewrites the haul order.
## Built in code; no scene. Pure presentation + input — it never touches the run.
class_name LootBagCell
extends Panel

const CELL_SIZE := Vector2(150, 210)

signal clicked(cell: LootBagCell)
signal request_reorder(from_index: int, to_index: int)

var instance: CardInstance
var index: int = 0
var marked: bool = false

var _glyph: Label
var _tag: Label
var _veil: ColorRect
var _banner: Label
var _drag_in_progress: bool = false


static func build(ci: CardInstance, idx: int) -> LootBagCell:
	var cell := LootBagCell.new()
	cell.instance = ci
	cell.index = idx
	return cell


func _ready() -> void:
	custom_minimum_size = CELL_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP

	_glyph = Label.new()
	_glyph.text = instance.card_id if instance != null else "?"
	_glyph.add_theme_font_size_override("font_size", 76)
	_glyph.add_theme_color_override("font_color", UiTokens.INK)
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glyph.offset_bottom = -28
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glyph)

	_tag = Label.new()
	_tag.add_theme_font_size_override("font_size", 15)
	_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tag.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_tag.offset_top = -28
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tag)

	# Marked-for-drop treatment: a translucent red veil + a "DROP" banner over the
	# face. Drawn last so they sit on top of the glyph/tag.
	_veil = ColorRect.new()
	_veil.color = Color(UiTokens.INCORRECT.r, UiTokens.INCORRECT.g, UiTokens.INCORRECT.b, 0.22)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.visible = false
	add_child(_veil)

	_banner = Label.new()
	_banner.text = "DROP"
	_banner.add_theme_font_size_override("font_size", 24)
	_banner.add_theme_color_override("font_color", UiTokens.INCORRECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	add_child(_banner)

	_refresh()


func set_marked(value: bool) -> void:
	marked = value
	if is_inside_tree():
		_refresh()


func toggle_marked() -> void:
	set_marked(not marked)


func _refresh() -> void:
	var rarity: int = instance.rarity if instance != null else EconomyEnums.Rarity.COMMON
	var hue := EconomyEnums.rarity_color(rarity)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.SURFACE
	sb.set_corner_radius_all(UiTokens.R_MD)
	sb.set_border_width_all(3)
	sb.border_color = UiTokens.INCORRECT if marked else hue
	sb.set_content_margin_all(6)
	add_theme_stylebox_override("panel", sb)
	if _tag:
		_tag.text = instance.display_label() if instance != null else "—"
		_tag.add_theme_color_override("font_color", hue)
	if _veil:
		_veil.visible = marked
	if _banner:
		_banner.visible = marked


# -- input: tap-to-mark, drag-to-reorder -------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# A left-release that wasn't the tail of a drag is a tap → toggle mark.
		if not _drag_in_progress:
			toggle_marked()
			clicked.emit(self)
		_drag_in_progress = false


func _get_drag_data(_at_position: Vector2) -> Variant:
	_drag_in_progress = true
	var preview := Label.new()
	preview.text = instance.card_id if instance != null else "?"
	preview.add_theme_font_size_override("font_size", 60)
	preview.add_theme_color_override("font_color", UiTokens.INK)
	set_drag_preview(preview)
	return {"loot_cell": true, "index": index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("loot_cell", false)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from: int = int(data.get("index", -1))
	if from >= 0 and from != index:
		request_reorder.emit(from, index)


func _notification(what: int) -> void:
	# Reset the drag latch when any drag ends so a later plain tap isn't swallowed
	# (the source cell never receives the button-up that ends a drag).
	if what == NOTIFICATION_DRAG_END:
		_drag_in_progress = false
