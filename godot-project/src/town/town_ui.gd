## TownUi — small static factory for the town screens' code-built UI (Phase 3, M4).
##
## The town screens follow the project's newest idiom (dungeon_map): a minimal
## .tscn that is just a Control root + script, with the controller assembling the
## interface in code. These helpers keep that assembly short and consistent —
## labels, styled buttons, and panels with the shared dark card look.
class_name TownUi
extends RefCounted

const BG := Color(0.10, 0.10, 0.13, 0.94)
const BORDER := Color(0.40, 0.50, 0.62)
const ACCENT := Color(0.55, 0.78, 0.95)
const MUTED := Color(0.62, 0.66, 0.72)
const GOOD := Color(0.55, 0.85, 0.55)


static func label(text: String, font_size: int = 22, align_center: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if align_center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func colored_label(text: String, font_size: int, color: Color) -> Label:
	var l := label(text, font_size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, min_width: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
	if min_width > 0.0:
		b.custom_minimum_size = Vector2(min_width, 0)
	return b


static func panel(size: Vector2, pos: Vector2 = Vector2.ZERO) -> Panel:
	var p := Panel.new()
	p.size = size
	p.position = pos
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = BORDER
	p.add_theme_stylebox_override("panel", sb)
	return p


## A scrolling vertical list inside a fixed rect — the common "rows of cards"
## layout. Returns the inner VBoxContainer to add rows to.
static func scroll_list(parent: Node, pos: Vector2, size: Vector2) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.position = pos
	scroll.size = size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(size.x - 20, 0)
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	return vbox


## Human-readable instance label, e.g. "好  ·  rare  ·  PSA 8" / "学  ·  common  ·  raw".
static func instance_text(ci: CardInstance) -> String:
	var grade_str := "raw" if ci.is_raw() else ("PSA %d" % ci.grade)
	return "%s  ·  %s  ·  %s" % [ci.card_id, _rarity_name(ci.rarity), grade_str]


static func _rarity_name(rarity: int) -> String:
	match rarity:
		EconomyEnums.Rarity.COMMON: return "common"
		EconomyEnums.Rarity.UNCOMMON: return "uncommon"
		EconomyEnums.Rarity.RARE: return "rare"
		EconomyEnums.Rarity.EPIC: return "epic"
		_: return "?"
