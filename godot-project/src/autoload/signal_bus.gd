## SignalBus — Global signal hub for decoupled communication between systems.
## Autoloaded singleton. All cross-system signals go through here.
class_name SignalBusClass
extends Node

# --- SRS Signals ---
signal card_presented(card_data: Dictionary, challenge_type: String)
signal card_answered(card_data: Dictionary, challenge_type: String, correct: bool, rating: int)
signal srs_state_updated(card_id: String, new_state: Dictionary)

# --- Run Signals ---
signal run_started(run_type: String)  # "easy" or "challenge"
signal run_ended(result: Dictionary)
signal round_started(round_number: int)
signal round_ended(round_number: int)

# --- Swipe Signals ---
signal swipe_detected(direction: Vector2)
signal answer_selected(direction: String, answer: String)

# --- Economy Signals ---
signal coins_changed(amount: int, total: int)
signal word_drop(word: String, characters: Array)

# --- Radical Signals ---
signal radical_activated(radical: String, character: String, bonus_coins: int)
signal radical_attach_triggered(base: String, radical: String, result: String)
signal radical_equipped(radical: String)
signal radical_unequipped(radical: String)

# --- Shop Signals ---
signal shop_opened()
signal shop_closed()
signal item_purchased(item_data: Dictionary)
signal shop_refreshed(items: Array)

# --- Progression Signals ---
signal hsk_level_changed(old_level: int, new_level: int)
signal character_mastered(character: String)
signal character_decaying(character: String)
signal streak_updated(days: int)
signal streak_broken()
signal milestone_achieved(milestone_id: String)

# --- UI Signals ---
signal screen_transition_requested(screen_name: String)
signal card_effect_requested(effect_type: String, card_data: Dictionary)
signal score_popup_requested(amount: int, position: Vector2, multiplier: float)
