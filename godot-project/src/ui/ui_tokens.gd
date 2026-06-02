## UiTokens — visual design tokens (colors, spacing, radii, type sizes).
##
## Sourced from docs/design/Style Guide.html. Color values are converted from
## the guide's OKLCH definitions to sRGB hex. The OKLCH source values are
## kept in the inline comments so the conversion can be re-derived if needed.
class_name UiTokens
extends RefCounted

# --- Surfaces (warm dark) ---
const BG            := Color("#120d09")    # oklch(0.165 0.012 62)  — default screen background
const BG_DEEP       := Color("#0b0705")    # oklch(0.135 0.010 60)  — app canvas, modal scrim base
const SURFACE       := Color("#1c1611")    # oklch(0.205 0.014 62)  — cards at rest, sheets
const ELEVATED      := Color("#261f18")    # oklch(0.245 0.016 65)  — selected, hover, popovers
const HAIRLINE      := Color("#38312bb2")  # oklch(0.32 0.014 65 / 0.7)  — borders, dividers
const HAIRLINE_SOFT := Color("#38312b59")  # oklch(0.32 0.014 65 / 0.35) — subtle dividers

# --- Text ---
const INK   := Color("#f5f3ef")  # oklch(0.965 0.006 82) — headings, characters, key data
const INK_2 := Color("#bcb7af")  # oklch(0.78 0.012 78)  — body
const INK_3 := Color("#79736d")  # oklch(0.56 0.012 72)  — muted, captions
const INK_4 := Color("#514c46")  # oklch(0.42 0.012 70)  — disabled

# --- Primary action surface (cream, like a flipped card) ---
const PAPER       := Color("#f2ece3")  # oklch(0.945 0.014 78)
const PAPER_PRESS := Color("#e3dbd1")  # oklch(0.895 0.016 76)

# --- Accent: gold. Reserved for rare pulls + legendary moments. ---
const GOLD      := Color("#efb14e")    # oklch(0.80 0.135 76)
const GOLD_DEEP := Color("#ca7e26")    # oklch(0.66 0.135 64)
const GOLD_GLOW := Color("#ffc53c8c")  # oklch(0.86 0.16 82 / 0.55)

# --- Semantic (answer feedback) ---
const CORRECT    := Color("#6dbf91")  # oklch(0.74 0.105 158) — jade
const INCORRECT  := Color("#e16852")  # oklch(0.66 0.155 32)  — terracotta
const STRUGGLING := Color("#e6aa61")  # oklch(0.78 0.115 70)  — ember

# --- Rarity hues (subtle border / corner accents on cards) ---
# Tier order matches CollectionEnums.CardTier: NEW_CARD, COMMON, UNCOMMON, RARE, EPIC, LEGENDARY.
# RARITY_EPIC is a placeholder — final visual treatment is pending sign-off.
const RARITY_NEW       := Color("#80b4c5")  # oklch(0.74 0.060 220) — cool indigo
const RARITY_COMMON    := Color("#a59d92")  # oklch(0.70 0.018 78)  — warm neutral
const RARITY_UNCOMMON  := Color("#77bba1")  # oklch(0.74 0.080 168) — jade tint
const RARITY_RARE      := Color("#9d9aea")  # oklch(0.72 0.115 285) — violet
const RARITY_EPIC      := Color("#9d9aea")  # PLACEHOLDER — to be replaced when Epic visual is signed off
const RARITY_LEGENDARY := GOLD

# --- Spacing (4px base) ---
const S_1 := 4
const S_2 := 8
const S_3 := 12
const S_4 := 16
const S_5 := 24
const S_6 := 32
const S_7 := 48
const S_8 := 64
const S_9 := 96

# --- Radii ---
const R_XS   := 4    # chips, tags
const R_SM   := 8    # inputs, small surfaces
const R_MD   := 12   # buttons, controls
const R_LG   := 18   # sheets, panels
const R_CARD := 22   # THE card radius
const R_XL   := 28   # modals
const R_PILL := 999  # chips, progress

# --- Component-specific colors (derived from style guide button/chip specs) ---
const INK_ON_PAPER          := Color("#16100c")    # primary button label on paper bg
const ICON_BTN_HOVER        := Color("#2c251e")    # icon button hover bg
const PROGRESS_TRACK        := Color("#332c27b2")  # progress bar track (translucent)
const BORDER_HSK            := Color("#90692f99")  # gold-tinted border for HSK chip
const BORDER_CORRECT        := Color("#30614680")  # tinted border for "correct" chip
const BORDER_INCORRECT      := Color("#843d3080")  # tinted border for "incorrect" chip
const BORDER_STRUGGLING     := Color("#805b2c80")  # tinted border for "struggling" chip
const BORDER_SECONDARY_HOVER := Color("#5b544dcc") # secondary button hover border
const SECONDARY_HOVER_BG    := Color(1, 1, 1, 0.04)  # subtle white wash on secondary hover

# --- Type sizes (px, matched to Style Guide spec) ---
const T_DISPLAY := 56
const T_H1      := 32
const T_H2      := 22
const T_H3      := 17
const T_BODY    := 15
const T_CAPTION := 12
const T_MONO    := 13
