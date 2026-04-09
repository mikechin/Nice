## ShopScreen — Displays the shop inventory and handles purchases.
## Creates a ShopManager, shows available items, processes purchases through GameState.
class_name ShopScreen
extends Control

@onready var _item_container: VBoxContainer = $ScrollContainer/ItemContainer if has_node("ScrollContainer/ItemContainer") else null
@onready var _coin_label: Label = $CoinLabel if has_node("CoinLabel") else null
@onready var _refresh_button: Button = $RefreshButton if has_node("RefreshButton") else null
@onready var _refresh_cost_label: Label = $RefreshCostLabel if has_node("RefreshCostLabel") else null
@onready var _back_button: Button = $BackButton if has_node("BackButton") else null
@onready var _title_label: Label = $TitleLabel if has_node("TitleLabel") else null

var _shop_manager: ShopManager
var _item_card_scene: PackedScene


func _ready() -> void:
	_shop_manager = ShopManager.new()

	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)
	if _refresh_button:
		_refresh_button.pressed.connect(_on_refresh_pressed)

	if ResourceLoader.exists("res://scenes/components/shop_item_card.tscn"):
		_item_card_scene = load("res://scenes/components/shop_item_card.tscn")

	SignalBus.coins_changed.connect(_on_coins_changed)
	SignalBus.item_purchased.connect(_on_item_purchased)
	SignalBus.shop_opened.emit()


func _exit_tree() -> void:
	SignalBus.coins_changed.disconnect(_on_coins_changed)
	SignalBus.item_purchased.disconnect(_on_item_purchased)

	_generate_shop()
	_update_coin_display()


func _generate_shop() -> void:
	var owned: Array[String] = []
	for r in GameState.owned_radicals:
		owned.append(r)
	_shop_manager.generate_inventory(GameState.player_hsk_level, owned)
	_populate_items()
	_update_refresh_cost()


func _populate_items() -> void:
	if _item_container == null:
		return

	# Clear old items
	for child in _item_container.get_children():
		child.queue_free()

	for item in _shop_manager.get_current_inventory():
		var card: Control = _create_item_card(item)
		_item_container.add_child(card)


func _create_item_card(item: ShopItem) -> Control:
	var card: Control
	if _item_card_scene:
		card = _item_card_scene.instantiate()
	else:
		card = _create_fallback_card(item)

	if card.has_method("setup_item"):
		card.setup_item(item)
	if card.has_signal("purchase_requested"):
		card.purchase_requested.connect(_on_purchase_requested.bind(item))
	return card


func _create_fallback_card(item: ShopItem) -> Control:
	var hbox := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = item.display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	var cost_label := Label.new()
	cost_label.text = "%d coins" % item.cost
	hbox.add_child(cost_label)

	var buy_btn := Button.new()
	buy_btn.text = "Buy" if not item.is_sold else "Sold"
	buy_btn.disabled = item.is_sold
	buy_btn.pressed.connect(_on_purchase_requested.bind(item))
	hbox.add_child(buy_btn)

	return hbox


func _on_purchase_requested(item: ShopItem) -> void:
	if item.is_sold:
		return
	if GameState.total_coins < item.cost:
		AudioManager.play_sfx("error")
		return

	# Spend through GameState so signals fire
	if not GameState.spend_coins(item.cost):
		return

	item.is_sold = true

	# Apply item effect
	match item.item_type:
		ShopItem.ItemType.RADICAL:
			var radical: String = item.data.get("radical", "")
			if radical != "" and radical not in GameState.owned_radicals:
				GameState.owned_radicals.append(radical)
		ShopItem.ItemType.UTILITY_TILE:
			var character: String = item.data.get("character", "")
			if character != "":
				GameState.add_tiles(character)
		ShopItem.ItemType.EXTRA_HEART:
			pass  # Applied at next run start via RunManager
		ShopItem.ItemType.PACK_REFRESH:
			pass  # Applied at next pack curation

	AudioManager.play_purchase()
	SignalBus.item_purchased.emit(item.to_dict())
	_populate_items()
	_update_coin_display()


func _on_refresh_pressed() -> void:
	var cost: int = _shop_manager.get_refresh_cost()
	if GameState.total_coins < cost:
		AudioManager.play_sfx("error")
		return

	if not GameState.spend_coins(cost):
		return

	var owned: Array[String] = []
	for r in GameState.owned_radicals:
		owned.append(r)
	_shop_manager.refresh_count += 1
	_shop_manager.generate_inventory(GameState.player_hsk_level, owned)
	_populate_items()
	_update_refresh_cost()
	_update_coin_display()
	AudioManager.play_sfx("shop_refresh")


func _update_coin_display() -> void:
	if _coin_label:
		_coin_label.text = "%d" % GameState.total_coins


func _update_refresh_cost() -> void:
	var cost: int = _shop_manager.get_refresh_cost()
	if _refresh_cost_label:
		_refresh_cost_label.text = "Refresh: %d coins" % cost
	if _refresh_button:
		_refresh_button.disabled = GameState.total_coins < cost


func _on_coins_changed(_amount: int, total: int) -> void:
	if _coin_label:
		_coin_label.text = "%d" % total
	_update_refresh_cost()


func _on_item_purchased(_item_data: Dictionary) -> void:
	_update_coin_display()


func _on_back_pressed() -> void:
	SignalBus.shop_closed.emit()
	SignalBus.screen_transition_requested.emit("main_menu")
