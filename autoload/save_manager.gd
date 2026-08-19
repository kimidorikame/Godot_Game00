extends Node

const AUTO_SAVE_PATH := "user://save.json"


func save() -> bool:
	var data: Dictionary = {
		"day": GameState.day,
		"money": GameState.money,
		"reputation": GameState.reputation,
		"inventory": GameState.inventory,
		"story_flags": GameState.story_flags,
		"pot_carryover_volume": GameState.pot_carryover_volume,
		"pot_carryover_koku": GameState.pot_carryover_koku,
		"pot_carryover_umami": GameState.pot_carryover_umami,
	}
	var file := FileAccess.open(AUTO_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true


func has_save() -> bool:
	return FileAccess.file_exists(AUTO_SAVE_PATH)


func load_game() -> bool:
	if not FileAccess.file_exists(AUTO_SAVE_PATH):
		return false
	var file := FileAccess.open(AUTO_SAVE_PATH, FileAccess.READ)
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
	# 3キーとも .get(key, 0) で読む。この3フィールド追加以前のsave.jsonにはキー自体が
	# 無いため、デフォルト0で「持ち越しなし」として復元し、旧セーブを読んでも落ちないようにする。
	# pot_carryover_koku は旧セーブ（統合前の2フィールド形式）のキーを持たないため、
	# 旧形式のセーブをロードすると鍋持ち越しは0になる（変換しない、実害なしと許容）。
	GameState.pot_carryover_volume = int(data.get("pot_carryover_volume", 0))
	GameState.pot_carryover_koku = int(data.get("pot_carryover_koku", 0))
	GameState.pot_carryover_umami = int(data.get("pot_carryover_umami", 0))
	return true


# JSON往復でDictionaryのキーがStringに落ちるため、StringNameキー前提の
# GameState.inventory / story_flags に合わせて明示的に復元する。
func _to_stringname_keys(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in src.keys():
		out[StringName(key)] = src[key]
	return out
