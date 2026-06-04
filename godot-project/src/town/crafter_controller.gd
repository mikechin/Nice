## CrafterController — the grading workbench & shard furnace (Phase 3, M4).
##
## Two services, the only place grading happens:
##   - GRADE: pick a RAW target from the bench, surround it with 3 ingredient
##     instances that share a linguistic connection, pay the shard fee → the
##     target is graded in place. A live preview shows the connection axis, the
##     two-cap band ceiling, the expected PSA, and the fee (the teaching hook).
##   - SHATTER: break any bench instance into shards.
##
## All rules live in CraftSystem (via GameState.preview_craft / craft_grade);
## this screen is selection + display. Full rebuild on every interaction.
class_name CrafterController
extends Control

var _target_id: String = ""
var _ingredient_ids: Array[String] = []
var _status: String = ""


func _ready() -> void:
	_ensure_economy()
	_rebuild()


func _rebuild() -> void:
	_prune_selection()
	for c in get_children():
		c.queue_free()
	_build_background()
	_build_top_bar()
	_build_grade_panel()
	_build_bench_panel()


## Drop any selected ids that have left the bench (shattered/crafted away).
func _prune_selection() -> void:
	var inv: Inventory = GameState.inventory
	if _target_id != "" and inv.get_instance(_target_id) == null:
		_target_id = ""
	_ingredient_ids = _ingredient_ids.filter(func(id): return inv.get_instance(id) != null)


# -- grade panel (selection + preview) --------------------------------------

func _build_grade_panel() -> void:
	var panel := TownUi.panel(Vector2(740, 360), Vector2(120, 210))
	add_child(panel)

	var col := VBoxContainer.new()
	col.position = Vector2(28, 22)
	col.custom_minimum_size = Vector2(684, 0)
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	col.add_child(TownUi.label("Grade a card", 28))
	var target := _target_instance()
	col.add_child(TownUi.colored_label(
		"Target:  %s" % (TownUi.instance_text(target) if target != null else "— pick a raw card below —"),
		22, TownUi.ACCENT if target != null else TownUi.MUTED))
	col.add_child(TownUi.colored_label(
		"Ingredients:  %d / 3   %s" % [_ingredient_ids.size(), _ingredient_summary()],
		22, TownUi.ACCENT if _ingredient_ids.size() == 3 else TownUi.MUTED))

	col.add_child(_preview_line())

	var craft_btn := TownUi.button("Craft Grade")
	var ready := _selection_ready()
	craft_btn.disabled = not (ready.has("valid") and ready["valid"] and ready.get("can_afford", false))
	craft_btn.pressed.connect(_on_craft)
	col.add_child(craft_btn)

	if _status != "":
		col.add_child(TownUi.colored_label(_status, 20, TownUi.GOOD))


func _preview_line() -> Label:
	if _target_id == "":
		return TownUi.colored_label("Pick a raw target to grade.", 20, TownUi.MUTED)
	if _ingredient_ids.size() < 3:
		return TownUi.colored_label("Select %d more ingredient(s) sharing a connection." % (3 - _ingredient_ids.size()), 20, TownUi.MUTED)
	var p := GameState.preview_craft(_target_id, _ingredient_ids)
	if not p["valid"]:
		return TownUi.colored_label("No connection — %s" % p["reason"], 20, Color(0.9, 0.5, 0.5))
	var afford := "" if p["can_afford"] else "   (not enough shards)"
	var line := "Connection: %s   ·   band → up to PSA %d   ·   expected PSA %d   ·   fee %d shards%s" % [
		p["axis_name"], p["ceiling"], p["expected_grade"], p["fee"], afford]
	return TownUi.colored_label(line, 20, TownUi.GOOD if p["can_afford"] else Color(0.9, 0.6, 0.4))


## Resolved validity+affordability for the Craft button.
func _selection_ready() -> Dictionary:
	if _target_id == "" or _ingredient_ids.size() != 3:
		return {}
	return GameState.preview_craft(_target_id, _ingredient_ids)


func _on_craft() -> void:
	AudioManager.play_sfx("button_tap")
	var target := _target_instance()
	var target_char := target.card_id if target != null else "?"
	var res := GameState.craft_grade(_target_id, _ingredient_ids)
	if res["ok"]:
		_status = "Graded %s → PSA %d  (%s)" % [target_char, res["grade"], res["axis_name"]]
		_target_id = ""
		_ingredient_ids = []
	else:
		_status = "Can't — %s" % res["reason"]
	_rebuild()


# -- bench panel (selection + shatter) --------------------------------------

func _build_bench_panel() -> void:
	var panel := TownUi.panel(Vector2(820, 640), Vector2(980, 210))
	add_child(panel)
	var bench: Inventory = GameState.inventory
	var heading := TownUi.label("Bench — %d instances" % bench.size(), 28)
	heading.position = Vector2(28, 20)
	panel.add_child(heading)

	var list := TownUi.scroll_list(panel, Vector2(28, 78), Vector2(764, 540))
	if bench.is_empty():
		list.add_child(TownUi.colored_label("Bench is empty — extract a haul from a run.", 22, TownUi.MUTED))
		return
	for ci in bench.get_all():
		list.add_child(_bench_row(ci))


func _bench_row(ci: CardInstance) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var id := ci.id

	var is_target := id == _target_id
	var is_ing := id in _ingredient_ids

	var lbl := TownUi.label(TownUi.instance_text(ci), 22)
	lbl.custom_minimum_size = Vector2(360, 0)
	if is_target:
		lbl.add_theme_color_override("font_color", TownUi.ACCENT)
	elif is_ing:
		lbl.add_theme_color_override("font_color", TownUi.GOOD)
	row.add_child(lbl)

	# Target (raw only).
	var t_btn := TownUi.button("Target ✓" if is_target else "Target")
	t_btn.disabled = not ci.is_raw()
	t_btn.pressed.connect(func() -> void: _set_target(id))
	row.add_child(t_btn)

	# Ingredient toggle.
	var i_btn := TownUi.button("✓ Ingredient" if is_ing else "+ Ingredient")
	i_btn.pressed.connect(func() -> void: _toggle_ingredient(id))
	row.add_child(i_btn)

	# Shatter.
	var s_btn := TownUi.button("Shatter +%d" % ci.shard_value())
	s_btn.pressed.connect(func() -> void: _on_shatter(id))
	row.add_child(s_btn)
	return row


func _set_target(id: String) -> void:
	AudioManager.play_sfx("button_tap")
	if id == _target_id:
		_target_id = ""
	else:
		_target_id = id
		_ingredient_ids.erase(id)  # a card can't be both target and ingredient
	_status = ""
	_rebuild()


func _toggle_ingredient(id: String) -> void:
	AudioManager.play_sfx("button_tap")
	if id in _ingredient_ids:
		_ingredient_ids.erase(id)
	elif _ingredient_ids.size() < 3 and id != _target_id:
		_ingredient_ids.append(id)
	_status = ""
	_rebuild()


func _on_shatter(id: String) -> void:
	AudioManager.play_sfx("button_tap")
	var gained := GameState.shatter_instance(id)
	_status = "Shattered → +%d shards" % gained
	_rebuild()


# -- helpers / chrome -------------------------------------------------------

func _target_instance() -> CardInstance:
	return GameState.inventory.get_instance(_target_id) if _target_id != "" else null


func _ingredient_summary() -> String:
	var ids: Array[String] = []
	for id in _ingredient_ids:
		var ci := GameState.inventory.get_instance(id)
		if ci != null:
			ids.append(ci.card_id)
	return ("(%s)" % ", ".join(ids)) if not ids.is_empty() else ""


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

	var title := TownUi.label("Crafter", 40, true)
	title.position = Vector2(0, 50)
	title.size = Vector2(1920, 52)
	add_child(title)

	var sub := TownUi.colored_label("%d shards" % GameState.wallet.shards, 24, TownUi.GOOD)
	sub.position = Vector2(0, 120)
	sub.size = Vector2(1920, 32)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)


func _ensure_economy() -> void:
	if GameState.inventory == null:
		GameState.load_from_dict({})
