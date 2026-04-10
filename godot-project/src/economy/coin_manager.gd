## CoinManager — Handles coin earning, spending, and value calculation.
class_name CoinManager
extends RefCounted

const BASE_COIN_VALUE: int = 10
const HSK_LEVEL_BONUS: Dictionary = {2: 0, 3: 5, 4: 10, 5: 20}

var total_coins: int = 0


func calculate_coin_value(
	loot_rarity: SrsEnums.LootRarity,
	hsk_level: int,
	has_radical_bonus: bool
) -> int:
	var base: int = BASE_COIN_VALUE + HSK_LEVEL_BONUS.get(hsk_level, 0)

	# Loot rarity multiplier
	var rarity_mult := 1.0
	match loot_rarity:
		SrsEnums.LootRarity.COMMON:
			rarity_mult = SrsConfig.COIN_MULT_COMMON
		SrsEnums.LootRarity.LEARNING:
			rarity_mult = SrsConfig.COIN_MULT_LEARNING
		SrsEnums.LootRarity.ABOUT_TO_FORGET:
			rarity_mult = SrsConfig.COIN_MULT_ABOUT_TO_FORGET
		SrsEnums.LootRarity.NEW_CARD:
			rarity_mult = SrsConfig.COIN_MULT_NEW

	# Radical bonus
	var radical_mult := 1.5 if has_radical_bonus else 1.0

	var total := float(base) * rarity_mult * radical_mult
	return maxi(1, roundi(total))


func earn_coins(amount: int) -> void:
	total_coins += amount
	SignalBus.coins_changed.emit(amount, total_coins)


func spend_coins(amount: int) -> bool:
	if total_coins < amount:
		return false
	total_coins -= amount
	SignalBus.coins_changed.emit(-amount, total_coins)
	return true


func get_balance() -> int:
	return total_coins


func set_balance(amount: int) -> void:
	total_coins = amount
