## AchievementData — Resource defining a single achievement/milestone.
class_name AchievementData
extends Resource

enum AchievementCategory { COLLECTION, MASTERY, SESSION }

@export var achievement_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var category: AchievementCategory = AchievementCategory.COLLECTION
@export var icon_id: String = ""
@export var requirement_value: int = 0
@export var is_hidden: bool = false

func check_completion(current_value: int) -> bool:
	return current_value >= requirement_value

func get_progress(current_value: int) -> float:
	if requirement_value <= 0:
		return 1.0
	return clampf(float(current_value) / float(requirement_value), 0.0, 1.0)

func to_dict() -> Dictionary:
	return {
		"achievement_id": achievement_id,
		"title": title,
		"description": description,
		"category": category,
		"icon_id": icon_id,
		"requirement_value": requirement_value,
		"is_hidden": is_hidden,
	}

static func from_dict(data: Dictionary) -> AchievementData:
	var ad := AchievementData.new()
	ad.achievement_id = data.get("achievement_id", "")
	ad.title = data.get("title", "")
	ad.description = data.get("description", "")
	ad.category = data.get("category", AchievementCategory.COLLECTION)
	ad.icon_id = data.get("icon_id", "")
	ad.requirement_value = data.get("requirement_value", 0)
	ad.is_hidden = data.get("is_hidden", false)
	return ad
