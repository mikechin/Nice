## BonusEnums — Constants for the bonus-round system.
## A bonus round chains additional challenge stages onto a single rare/epic
## card; each correct stage adds to that card's board-game power.
class_name BonusEnums
extends RefCounted

## The challenge stages that can fire inside a bonus round. Mirrors the
## challenge type names used throughout the codebase ("meaning", "character",
## "pinyin", "tone"). These are the same four types ChallengePresenter
## already presents — the bonus round chains the three the primary challenge
## did not use.
enum BonusStage { MEANING, CHARACTER, PINYIN, TONE }

## Outcome of the bonus-round trigger roll.
enum BonusOutcome { NOT_TRIGGERED, TRIGGERED }

## Result reported back from BonusRoundManager.record_stage_result.
enum StageOutcome { CONTINUE, STOP }

## Probability that a bonus round triggers on an eligible card.
const BONUS_TRIGGER_CHANCE: float = 0.20

## Power boost added per correctly answered bonus stage.
const BOOST_PER_STAGE: int = 1

## Canonical chain order. The primary challenge type is removed from this
## sequence at runtime so a card never gets re-asked the same thing.
const STAGE_ORDER: Array = [
	BonusStage.MEANING,
	BonusStage.CHARACTER,
	BonusStage.PINYIN,
	BonusStage.TONE,
]

const STAGE_NAMES: Dictionary = {
	BonusStage.MEANING: "meaning",
	BonusStage.CHARACTER: "character",
	BonusStage.PINYIN: "pinyin",
	BonusStage.TONE: "tone",
}

static func stage_to_string(stage: BonusStage) -> String:
	return STAGE_NAMES.get(stage, "unknown")

static func stage_from_string(s: String) -> BonusStage:
	match s:
		"meaning": return BonusStage.MEANING
		"character": return BonusStage.CHARACTER
		"pinyin": return BonusStage.PINYIN
		"tone": return BonusStage.TONE
	return BonusStage.MEANING
