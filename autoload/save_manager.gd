extends Node

const SAVE_PATH := "user://save.json"


func save() -> bool:
	var data: Dictionary = {
		"day": GameState.day,
		"money": GameState.money,
		"reputation": GameState.reputation,
		"inventory": GameState.inventory,
		"story_flags": GameState.story_flags,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	var data: Dictionary = parsed
	GameState.day = int(data.get("day", 1))
	GameState.money = int(data.get("money", GameState.INITIAL_MONEY))
	GameState.reputation = int(data.get("reputation", 0))
	GameState.inventory = _to_stringname_keys(data.get("inventory", {}))
	GameState.story_flags = _to_stringname_keys(data.get("story_flags", {}))
	return true


# JSON往復でDictionaryのキーがStringに落ちるため、StringNameキー前提の
# GameState.inventory / story_flags に合わせて明示的に復元する。
func _to_stringname_keys(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in src.keys():
		out[StringName(key)] = src[key]
	return out
