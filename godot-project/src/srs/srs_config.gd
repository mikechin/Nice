## SrsConfig — Configuration constants for the SRS system.
class_name SrsConfig
extends RefCounted

# --- Retrievability thresholds ---
const ABOUT_TO_FORGET_THRESHOLD: float = 0.7
const WELL_KNOWN_THRESHOLD: float = 0.95

# --- Pack composition (percentage targets) ---
# Fixed pack size: each run shows the player a sealed set of 12 cards.
const PACK_SIZE_DEFAULT: int = 12

const PACK_COMMON_RATIO: float = 0.70
const PACK_STRUGGLING_RATIO: float = 0.15
const PACK_NEW_RATIO: float = 0.10
const PACK_RETURNING_RATIO: float = 0.05

# --- New card limits ---
const MAX_NEW_CARDS_PER_DAY: int = 5
const MAX_NEW_CARDS_PER_SESSION: int = 3

# --- Stability thresholds for card tier mapping ---
const TIER_COMMON_STABILITY: float = 1.0       # Learning / early
const TIER_UNCOMMON_STABILITY: float = 7.0      # ~1 week intervals
const TIER_RARE_STABILITY: float = 30.0         # ~1 month intervals
const TIER_EPIC_STABILITY: float = 90.0         # ~3 month intervals
const TIER_LEGENDARY_STABILITY: float = 180.0   # ~6 month+ intervals

# --- Desired retention ---
const DEFAULT_DESIRED_RETENTION: float = 0.9
const MAXIMUM_INTERVAL: int = 36500
