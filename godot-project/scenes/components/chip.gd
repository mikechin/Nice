## Chip — small pill-shaped tag.
##
## Six variants per the style guide: a neutral default, a radical chip
## (Chinese serif glyph), an HSK level chip (mono, gold), and three
## semantic states (correct/incorrect/struggling). The chip rebuilds its
## stylebox and label whenever `variant` or `text` changes so it stays
## in sync when set from the editor inspector or from code.
class_name Chip
extends PanelContainer

enum Variant {
	DEFAULT,
	RADICAL,
	HSK,
	CORRECT,
	INCORRECT,
	STRUGGLING,
}

const _NOTO_SERIF_SC: FontFile = preload("res://assets/fonts/NotoSerifSC-VariableFont.ttf")
const _JETBRAINS_MONO: FontFile = preload("res://assets/fonts/JetBrainsMono-VariableFont.ttf")

@export var variant: Variant = Variant.DEFAULT:
	set(v):
		variant = v
		_refresh()

@export var text: String = "":
	set(t):
		text = t
		if _label:
			_label.text = t

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _label == null:
		_label = Label.new()
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_label)
	_label.text = text
	_refresh()


func _refresh() -> void:
	if _label == null:
		return
	add_theme_stylebox_override("panel", _build_stylebox())
	_label.add_theme_color_override("font_color", _label_color())
	_label.add_theme_font_size_override("font_size", _font_size())
	var font := _font_for_variant()
	if font != null:
		_label.add_theme_font_override("font", font)
	else:
		_label.remove_theme_font_override("font")


func _build_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left = UiTokens.R_PILL
	sb.corner_radius_top_right = UiTokens.R_PILL
	sb.corner_radius_bottom_left = UiTokens.R_PILL
	sb.corner_radius_bottom_right = UiTokens.R_PILL
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.bg_color = _bg_color()
	sb.border_color = _border_color()
	return sb


func _bg_color() -> Color:
	if variant == Variant.HSK:
		return Color(0, 0, 0, 0)
	return UiTokens.ELEVATED


func _border_color() -> Color:
	match variant:
		Variant.HSK:        return UiTokens.BORDER_HSK
		Variant.CORRECT:    return UiTokens.BORDER_CORRECT
		Variant.INCORRECT:  return UiTokens.BORDER_INCORRECT
		Variant.STRUGGLING: return UiTokens.BORDER_STRUGGLING
		_:                  return UiTokens.HAIRLINE_SOFT


func _label_color() -> Color:
	match variant:
		Variant.HSK:        return UiTokens.GOLD
		Variant.CORRECT:    return UiTokens.CORRECT
		Variant.INCORRECT:  return UiTokens.INCORRECT
		Variant.STRUGGLING: return UiTokens.STRUGGLING
		_:                  return UiTokens.INK_2


func _font_size() -> int:
	if variant == Variant.RADICAL:
		return 13
	return UiTokens.T_CAPTION


func _font_for_variant() -> FontFile:
	match variant:
		Variant.RADICAL: return _NOTO_SERIF_SC
		Variant.HSK:     return _JETBRAINS_MONO
		_:               return null
