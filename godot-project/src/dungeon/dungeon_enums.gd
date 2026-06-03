## DungeonEnums — Shared enums for the dungeon run layer (Phase 3, M2).
##
## Lives here (not inline) so RoomNode, RunMap, DungeonRun, and the screens
## all reference one set of room kinds / outcomes — mirrors the existing
## *_enums.gd convention (srs_enums, collection_enums, bonus_enums).
class_name DungeonEnums
extends RefCounted

## Room kinds along the fixed run-map path (dungeon-crawler-direction.md
## "Run shape: TOWN → enter → segment → elite → [extract gate] → … → boss").
##   ENCOUNTER — a normal 1–3 mob ATB fight.
##   ELITE     — a single tanky mob; gateway to an extract point.
##   EXTRACT   — the leave-or-push gate (a decision, not a fight; the full
##               answer-your-way-out gauntlet + greed tax is M2b).
##   BOSS      — the cloze climax (a tougher fight stub until M6 fills it in).
enum RoomType { ENCOUNTER, ELITE, EXTRACT, BOSS }

## How a run ended. ONGOING while in progress; EXTRACTED = banked the haul
## home; DIED = HP hit 0, haul lost. Death never touches binder / mastery /
## unlocks — the un-loseable principle lives one layer up (M3+).
enum RunOutcome { ONGOING, EXTRACTED, DIED }


static func room_type_name(t: RoomType) -> String:
	match t:
		RoomType.ENCOUNTER: return "Encounter"
		RoomType.ELITE: return "Elite"
		RoomType.EXTRACT: return "Extract"
		RoomType.BOSS: return "Boss"
	return "Room"


static func room_type_icon(t: RoomType) -> String:
	match t:
		RoomType.ENCOUNTER: return "⚔"
		RoomType.ELITE: return "☠"
		RoomType.EXTRACT: return "⏏"
		RoomType.BOSS: return "♛"
	return "?"


## Fightable rooms run the ATB combat scene; an EXTRACT gate is a decision
## point that never enters combat.
static func is_fight(t: RoomType) -> bool:
	return t == RoomType.ENCOUNTER or t == RoomType.ELITE or t == RoomType.BOSS
