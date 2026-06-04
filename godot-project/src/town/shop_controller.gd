## ShopController — the town store (Phase 3, M4).
##
## Browse the rotating stock and buy: raw-common instances of characters you've
## already met (craft-ingredient smoothing — buy the 3rd 氵 mate) and one-shot
## consumables. Never new characters, never grades (enforced by Shop). All rules
## live in Shop (GameState.get_shop()); this screen is list + buy. Restocks on
## entry if the stock is empty. Code-built UI, full rebuild per interaction.
class_name ShopController
extends Control

var _status: String = ""


func _ready() -> void:
	_ensure_economy()
	var shop := GameState.get_shop()
	if shop.size() == 0:
		shop.restock()
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_build_background()
	_build_top_bar()
	_build_stock_panel()


func _build_stock_panel() -> void:
	var panel := TownUi.panel(Vector2(1100, 660), Vector2(410, 200))
	add_child(panel)
	var shop := GameState.get_shop()

	var heading := TownUi.label("Stock", 28)
	heading.position = Vector2(28, 20)
	panel.add_child(heading)

	var restock := TownUi.button("Restock")
	restock.position = Vector2(900, 22)
	restock.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		GameState.get_shop().restock()
		_status = ""
		_rebuild())
	panel.add_child(restock)

	var list := TownUi.scroll_list(panel, Vector2(28, 78), Vector2(1044, 520))
	if shop.size() == 0:
		list.add_child(TownUi.colored_label("Out of stock — restock to refresh.", 22, TownUi.MUTED))
		return
	for i in shop.size():
		list.add_child(_stock_row(i, shop))


func _stock_row(index: int, shop: Shop) -> Control:
	var item := shop.get_item(index)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var is_card := int(item["kind"]) == Shop.Kind.CARD
	var desc := ""
	if is_card:
		desc = "%s   ·   raw common instance" % String(item["label"])
	else:
		desc = "%s   ·   consumable" % String(item["label"])
	var lbl := TownUi.label(desc, 22)
	lbl.custom_minimum_size = Vector2(720, 0)
	row.add_child(lbl)

	var price := int(item["price"])
	var afford := GameState.wallet.can_afford(price)
	var buy := TownUi.button("Buy — %d shards" % price)
	buy.disabled = not afford
	buy.pressed.connect(func() -> void: _on_buy(index))
	row.add_child(buy)
	return row


func _on_buy(index: int) -> void:
	AudioManager.play_sfx("button_tap")
	var res := GameState.get_shop().buy(index)
	if res["ok"]:
		if int(res["kind"]) == Shop.Kind.CARD:
			_status = "Bought %s → added to bench (-%d shards)" % [String(res["card_id"]), int(res["price"])]
		else:
			_status = "Bought %s (-%d shards)" % [String(res["item_id"]), int(res["price"])]
	else:
		_status = "Can't — %s" % res["reason"]
	_rebuild()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)


func _build_top_bar() -> void:
	var back := TownUi.button("← Town")
	back.position = Vector2(40, 50)
	back.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		SignalBus.screen_transition_requested.emit("town"))
	add_child(back)

	var title := TownUi.label("Shop", 40, true)
	title.position = Vector2(0, 50)
	title.size = Vector2(1920, 52)
	add_child(title)

	var sub := TownUi.colored_label("%d shards   ·   %d on the bench" % [
		GameState.wallet.shards, GameState.inventory.size()], 24, TownUi.GOOD)
	sub.position = Vector2(0, 120)
	sub.size = Vector2(1920, 32)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	if _status != "":
		var st := TownUi.colored_label(_status, 22, TownUi.ACCENT)
		st.position = Vector2(0, 160)
		st.size = Vector2(1920, 30)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(st)


func _ensure_economy() -> void:
	if GameState.inventory == null:
		GameState.load_from_dict({})
