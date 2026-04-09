## ShopItemCard — Card UI for a single shop item showing name, description, cost,
## and a buy button. Emits purchase_requested when the buy button is pressed.
class_name ShopItemCard
extends Control

signal purchase_requested()

@onready var _name_label: Label = $NameLabel if has_node("NameLabel") else null
@onready var _description_label: Label = $DescriptionLabel if has_node("DescriptionLabel") else null
@onready var _cost_label: Label = $CostLabel if has_node("CostLabel") else null
@onready var _buy_button: Button = $BuyButton if has_node("BuyButton") else null
@onready var _icon_label: Label = $IconLabel if has_node("IconLabel") else null
@onready var _background: Panel = $Background if has_node("Background") else null
@onready var _sold_overlay: Control = $SoldOverlay if has_node("SoldOverlay") else null

var _item: ShopItem
var _is_affordable: bool = true

const TYPE_COLORS: Dictionary = {
	0: Color(0.7, 0.2, 1.0),  # RADICAL
	1: Color(0.2, 0.6, 1.0),  # UTILITY_TILE
	2: Color(1.0, 0.3, 0.3),  # EXTRA_HEART
	3: Color(0.3, 0.8, 0.3),  # PACK_REFRESH
}

const TYPE_ICONS: Dictionary = {
	0: "R",  # RADICAL
	1: "T",  # UTILITY_TILE
	2: "H",  # EXTRA_HEART
	3: "P",  # PACK_REFRESH
}


func _ready() -> void:
	_warn_missing_nodes()
	if _buy_button:
		_buy_button.pressed.connect(_on_buy_pressed)


func setup_item(item: ShopItem) -> void:
	_item = item
	_is_affordable = GameState.total_coins >= item.cost
	_update_display()


func get_item() -> ShopItem:
	return _item


func _update_display() -> void:
	if _item == null:
		return

	if _name_label:
		_name_label.text = _item.display_name

	if _description_label:
		_description_label.text = _item.description

	if _cost_label:
		_cost_label.text = "%d" % _item.cost
		if _is_affordable and not _item.is_sold:
			_cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		else:
			_cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	if _buy_button:
		if _item.is_sold:
			_buy_button.text = "Sold"
			_buy_button.disabled = true
		elif not _is_affordable:
			_buy_button.text = "Buy"
			_buy_button.disabled = true
		else:
			_buy_button.text = "Buy"
			_buy_button.disabled = false

	if _icon_label:
		_icon_label.text = TYPE_ICONS.get(_item.item_type, "?")
		var type_color: Color = TYPE_COLORS.get(_item.item_type, Color.WHITE)
		_icon_label.add_theme_color_override("font_color", type_color)

	if _background:
		var type_color: Color = TYPE_COLORS.get(_item.item_type, Color.WHITE)
		_background.modulate = Color(type_color.r, type_color.g, type_color.b, 0.1)

	if _sold_overlay:
		_sold_overlay.visible = _item.is_sold


func _on_buy_pressed() -> void:
	if _item == null or _item.is_sold:
		return
	if GameState.total_coins < _item.cost:
		_animate_insufficient()
		return
	purchase_requested.emit()


func _animate_insufficient() -> void:
	var tween := create_tween()
	var orig_pos := position
	tween.tween_property(self, "position", orig_pos + Vector2(5, 0), 0.04)
	tween.tween_property(self, "position", orig_pos - Vector2(5, 0), 0.04)
	tween.tween_property(self, "position", orig_pos, 0.04)


func _warn_missing_nodes() -> void:
	if _name_label == null:
		push_warning("shop_item_card.gd: missing node _name_label")
	if _description_label == null:
		push_warning("shop_item_card.gd: missing node _description_label")
	if _cost_label == null:
		push_warning("shop_item_card.gd: missing node _cost_label")
	if _buy_button == null:
		push_warning("shop_item_card.gd: missing node _buy_button")
	if _icon_label == null:
		push_warning("shop_item_card.gd: missing node _icon_label")
	if _background == null:
		push_warning("shop_item_card.gd: missing node _background")
	if _sold_overlay == null:
		push_warning("shop_item_card.gd: missing node _sold_overlay")
