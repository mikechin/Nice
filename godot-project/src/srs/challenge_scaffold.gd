## ChallengeScaffold — picks the challenge FORMAT for a (card, challenge_type),
## so new material is taught before it's tested and eased in before full recall
## is demanded (recognition before production).
##
##   card's first contact ever      → TEACH      show the answer (a reveal block)
##   seen, this facet still weak     → RECOGNIZE  2 options (easier recognition)
##   this facet strong (S ≥ floor)   → RECALL     4 options (full recall)
##
## TEACH is keyed off the CARD (its very first contact), not the facet — the
## teach reveals the whole card, so every facet has been seen once before it's
## ever quizzed. After that, each facet escalates on its own stability.
##
## Honest-FSRS note: TEACH is not a free pass — the caller still commits a real
## first review (AGAIN: just introduced, weak), so initial stability is honest
## and the card comes back soon as a RECOGNIZE. Pure logic; no scene, no FSRS
## mutation here.
class_name ChallengeScaffold
extends RefCounted

enum Format { TEACH, RECOGNIZE, RECALL }

## Stability at/above which a facet graduates from 2-option to 4-option.
const RECALL_STABILITY := 7.0


static func format_for(card_is_new: bool, facet_stability: float) -> Format:
	if card_is_new:
		return Format.TEACH
	if facet_stability < RECALL_STABILITY:
		return Format.RECOGNIZE
	return Format.RECALL
