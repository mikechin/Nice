## PowerBoost — Resource recording a single power-up applied to a card.
## Each correct bonus-round stage emits one of these; later phases (radical
## matchup, rime synergy) will emit them too. The full board-game power of a
## card is its base power plus the sum of attached boosts.
class_name PowerBoost
extends Resource

@export var source: PowerEnums.BoostSource = PowerEnums.BoostSource.BONUS_STAGE
@export var amount: int = 0
## Free-form label for the source ("pinyin", "tone", "water>fire", ...).
## Optional — only used by the UI for human-readable boost lists.
@export var label: String = ""


static func from_bonus_stage(stage: BonusEnums.BonusStage, amount_: int = BonusEnums.BOOST_PER_STAGE) -> PowerBoost:
	var b := PowerBoost.new()
	b.source = PowerEnums.BoostSource.BONUS_STAGE
	b.amount = amount_
	b.label = BonusEnums.stage_to_string(stage)
	return b


func to_dict() -> Dictionary:
	return {
		"source": source,
		"amount": amount,
		"label": label,
	}


static func from_dict(data: Dictionary) -> PowerBoost:
	var b := PowerBoost.new()
	b.source = data.get("source", PowerEnums.BoostSource.BONUS_STAGE)
	b.amount = data.get("amount", 0)
	b.label = data.get("label", "")
	return b
