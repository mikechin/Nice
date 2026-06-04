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
const SELECT_COLOR := Color(1.0, 0.85, 0.35)   # the gold-highlighted, currently-targeted slot

# Which loadout slot the next Equip will fill (-1 = none chosen → first empty slot).
# Selecting a slot makes role placement explicit, which now matters: a card whose
# nature matches the slot role pays full value, a mismatch pays half (M5).
var _selected_slot: int = -1


func _ready() -> void:
	_ensure_economy()
	SignalBus.loadout_changed.connect(_rebuild)
	_rebuild()


# -- slot selection ----------------------------------------------------------

## Tap a slot to target it; tap the same slot again to clear the target.
func _select_slot(index: int) -> void:
	_selected_slot = -1 if index == _selected_slot else index
	_rebuild()


## The slot the next Equip fills: the explicitly chosen one, else the first empty.
func _target_slot() -> int:
	if _selected_slot >= 0 and _selected_slot < GameState.loadout.capacity:
		return _selected_slot
	return GameState.loadout.first_empty_slot()


## Equip a bench card into the target slot. When the player explicitly picked the
## slot, advance the selection to the next empty one so repeated equips flow down
## the kit instead of overwriting the same slot. (GameState.equip returns any
## displaced card to the bench and fires loadout_changed → _rebuild.)
func _equip_to_target(id: String) -> void:
	AudioManager.play_sfx("button_tap")
	var slot := _target_slot()
	var was_explicit := _selected_slot == slot
	GameState.equip(id, slot)
	if was_explicit:
		_selected_slot = GameState.loadout.first_empty_slot()
		_rebuild()


## "Passive 1" / "Active 2" — role plus its index within that role.
func _slot_label(index: int, lo: Loadout) -> String:
	if lo.slot_role(index) == Loadout.SlotRole.PASSIVE:
		return "Passive %d" % (index + 1)
	return "Active %d" % (index - lo.passive_count + 1)


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
	heading.position = Vector2(28, 16)
	panel.add_child(heading)

	# What the whole kit grants in a fight (M5) — the sum the dungeon will apply.
	var mods := CombatLoadout.assemble(GameState.loadout, GameState.character_db)
	var kit := TownUi.colored_label("In combat:  " + mods.summary(), 18, EFFECT_COLOR)
	kit.position = Vector2(28, 50)
	panel.add_child(kit)

	# Where the next Equip will land — the whole point of letting you pick a slot.
	var lo_ref: Loadout = GameState.loadout
	var target_text := ("Equipping into: %s  (tap it again to clear)" % _slot_label(_selected_slot, lo_ref)) \
		if _selected_slot >= 0 else "Tap a slot to choose where the next card goes"
	var status := TownUi.colored_label(target_text, 18, TownUi.ACCENT)
	status.position = Vector2(28, 76)
	panel.add_child(status)

	var list := VBoxContainer.new()
	list.position = Vector2(28, 108)
	list.custom_minimum_size = Vector2(664, 0)
	list.add_theme_constant_override("separation", 12)
	panel.add_child(list)

	var lo: Loadout = GameState.loadout
	for i in lo.capacity:
		list.add_child(_slot_row(i, lo))


func _slot_row(index: int, lo: Loadout) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	# The slot face doubles as its selector — tap it to target this slot for Equip.
	var face := TownUi.button(_slot_label(index, lo), 150.0)
	if index == _selected_slot:
		face.modulate = SELECT_COLOR
	face.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		_select_slot(index))
	row.add_child(face)

	var ci := lo.get_slot(index)
	if ci == null:
		var empty := TownUi.colored_label("— empty —", 22, TownUi.MUTED)
		empty.custom_minimum_size = Vector2(360, 0)
		row.add_child(empty)
	else:
		# Card identity on top, its combat effect (scaled by rarity×grade and this
		# slot's role-match) on the line beneath — so the kit's shape is legible.
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(360, 0)
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
		var note := TownUi.colored_label("Loadout full — tap a slot, then Equip to swap.", 18, TownUi.MUTED)
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
	lbl.custom_minimum_size = Vector2(410, 0)
	row.add_child(lbl)

	# The ability this card grants. With a slot selected, also call out whether it
	# would land at full value or half there — so you place by role, not by guess.
	var kind := EffectPalette.kind_for_char(ci.card_id, GameState.character_db)
	var tag_text := EffectEnums.kind_name(kind)
	var tag_color := EFFECT_COLOR
	if _selected_slot >= 0:
		var slot_passive := GameState.loadout.slot_role(_selected_slot) == Loadout.SlotRole.PASSIVE
		var matched := slot_passive == EffectEnums.is_passive(kind)
		tag_text += "  ·  full" if matched else "  ·  ½"
		tag_color = TownUi.GOOD if matched else TownUi.MUTED
	var tag := TownUi.colored_label(tag_text, 18, tag_color)
	tag.custom_minimum_size = Vector2(150, 0)
	row.add_child(tag)

	# Enabled when there's somewhere to put it: an empty slot, or a chosen slot to
	# swap into. A full kit with no slot picked is the only locked-out case.
	var btn := TownUi.button("Equip")
	btn.disabled = loadout_full and _selected_slot < 0
	var id := ci.id
	btn.pressed.connect(func() -> void:
		_equip_to_target(id))
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
