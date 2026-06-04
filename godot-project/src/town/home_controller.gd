## HomeController — outfit the hero & view the binder (Phase 3, M4).
##
## The "Home" building: assemble the 5-card loadout (2 passive + 3 active = your
## stake) from the bench, and glance at binder progress. Slots are untyped — any
## instance fits any slot; the passive/active labels are the slot ROLE the combat
## layer (M5) will read, shown here so equipping starts teaching the kit shape.
##
## Equipping moves an instance off the bench into the slot (GameState.equip);
## unequipping returns it. Re-renders on loadout_changed. Code-built UI.
class_name HomeController
extends Control

const EFFECT_COLOR := Color(0.62, 0.82, 0.66)


func _ready() -> void:
	_ensure_economy()
	SignalBus.loadout_changed.connect(_rebuild)
	_rebuild()


func _rebuild(_lo: Variant = null) -> void:
	for c in get_children():
		c.queue_free()
	_build_background()
	_build_top_bar()
	_build_loadout_panel()
	_build_bench_panel()


# -- panels -----------------------------------------------------------------

func _build_loadout_panel() -> void:
	var panel := TownUi.panel(Vector2(720, 640), Vector2(120, 220))
	add_child(panel)
	var heading := TownUi.label("Loadout — your stake", 28)
	heading.position = Vector2(28, 20)
	panel.add_child(heading)

	# What the whole kit grants in a fight (M5) — the sum the dungeon will apply.
	var mods := CombatLoadout.assemble(GameState.loadout, GameState.character_db)
	var kit := TownUi.colored_label("In combat:  " + mods.summary(), 18, EFFECT_COLOR)
	kit.position = Vector2(28, 52)
	panel.add_child(kit)

	var list := VBoxContainer.new()
	list.position = Vector2(28, 80)
	list.custom_minimum_size = Vector2(664, 0)
	list.add_theme_constant_override("separation", 12)
	panel.add_child(list)

	var lo: Loadout = GameState.loadout
	for i in lo.capacity:
		list.add_child(_slot_row(i, lo))


func _slot_row(index: int, lo: Loadout) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var role := "Passive" if lo.slot_role(index) == Loadout.SlotRole.PASSIVE else "Active"
	var tag := TownUi.colored_label("%s" % role, 18, TownUi.MUTED)
	tag.custom_minimum_size = Vector2(90, 0)
	row.add_child(tag)

	var ci := lo.get_slot(index)
	if ci == null:
		var empty := TownUi.colored_label("— empty —", 22, TownUi.MUTED)
		empty.custom_minimum_size = Vector2(420, 0)
		row.add_child(empty)
	else:
		# Card identity on top, its combat effect (scaled by rarity×grade and this
		# slot's role-match) on the line beneath — so the kit's shape is legible.
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(420, 0)
		cell.add_theme_constant_override("separation", 2)
		cell.add_child(TownUi.label(TownUi.instance_text(ci), 22))
		var passive := lo.slot_role(index) == Loadout.SlotRole.PASSIVE
		var eff := CombatLoadout.describe_card(ci, passive, GameState.character_db)
		cell.add_child(TownUi.colored_label(eff, 16, EFFECT_COLOR))
		row.add_child(cell)
		var btn := TownUi.button("Unequip")
		btn.pressed.connect(func() -> void:
			AudioManager.play_sfx("button_tap")
			GameState.unequip(index))
		row.add_child(btn)
	return row


func _build_bench_panel() -> void:
	var panel := TownUi.panel(Vector2(840, 640), Vector2(960, 220))
	add_child(panel)
	var bench: Inventory = GameState.inventory
	var heading := TownUi.label("Bench — %d instances" % bench.size(), 28)
	heading.position = Vector2(28, 20)
	panel.add_child(heading)

	var lo: Loadout = GameState.loadout
	var full := lo.is_full()
	if full:
		var note := TownUi.colored_label("Loadout full — unequip a slot to swap.", 18, TownUi.MUTED)
		note.position = Vector2(300, 28)
		panel.add_child(note)

	var list := TownUi.scroll_list(panel, Vector2(28, 80), Vector2(784, 536))
	if bench.is_empty():
		list.add_child(TownUi.colored_label("Bench is empty — extract a haul from a run.", 22, TownUi.MUTED))
		return
	for ci in bench.get_all():
		list.add_child(_bench_row(ci, full))


func _bench_row(ci: CardInstance, loadout_full: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var lbl := TownUi.label(TownUi.instance_text(ci), 22)
	lbl.custom_minimum_size = Vector2(430, 0)
	row.add_child(lbl)

	# The ability this card would grant (kind only — the role-match scaling depends
	# on which slot you drop it into, shown on the loadout side).
	var kind := EffectPalette.kind_for_char(ci.card_id, GameState.character_db)
	var tag := TownUi.colored_label(EffectEnums.kind_name(kind), 18, EFFECT_COLOR)
	tag.custom_minimum_size = Vector2(120, 0)
	row.add_child(tag)

	var btn := TownUi.button("Equip")
	btn.disabled = loadout_full
	var id := ci.id
	btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		GameState.equip(id, GameState.loadout.first_empty_slot()))
	row.add_child(btn)
	return row


# -- chrome -----------------------------------------------------------------

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

	var title := TownUi.label("Home", 40, true)
	title.position = Vector2(0, 50)
	title.size = Vector2(1920, 52)
	add_child(title)

	var seen: int = GameState.binder.seen_count()
	var dropped: int = GameState.binder.dropped_count()
	var sub := TownUi.colored_label(
		"Binder: %d characters seen · %d ever dropped" % [seen, dropped], 22, TownUi.MUTED)
	sub.position = Vector2(0, 120)
	sub.size = Vector2(1920, 32)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)


func _ensure_economy() -> void:
	if GameState.inventory == null:
		GameState.load_from_dict({})
