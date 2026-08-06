extends Node

var _fail_count: int = 0


func _ready() -> void:
	print("=== SaveManager テスト開始 ===")
	_run()
	print("=== テスト完了（FAIL: %d件） ===" % _fail_count)
	get_tree().quit(1 if _fail_count > 0 else 0)


func _run() -> void:
	# a. 既知の値をセット
	GameState.day = 3
	GameState.money = 1234
	GameState.reputation = 2
	GameState.inventory = {&"base_tonkotsu": 2, &"base_syojin": 1}
	GameState.story_flags = {&"flag_x": true, &"flag_y": false}

	# b. save() → 戻り値とファイル存在を確認
	var save_ok: bool = SaveManager.save()
	_check("save()の戻り値がtrue", save_ok == true)
	_check("セーブファイルが存在する", FileAccess.file_exists(SaveManager.SAVE_PATH))

	# c. GameStateをリセット（ロードが本当に復元するか確認するため）
	GameState.reset_for_new_game()
	_check("リセット後にdayが1に戻っている", GameState.day == 1)

	# d. load_game() → 戻り値を確認
	var load_ok: bool = SaveManager.load_game()
	_check("load_game()の戻り値がtrue", load_ok == true)

	# e. 値が一致しているか確認
	_check("dayが復元されている", GameState.day == 3)
	_check("moneyが復元されている", GameState.money == 1234)
	_check("reputationが復元されている", GameState.reputation == 2)
	_check("inventoryの内容が一致", _dict_matches(
		{&"base_tonkotsu": 2, &"base_syojin": 1}, GameState.inventory
	))
	_check("story_flagsの内容が一致", _dict_matches(
		{&"flag_x": true, &"flag_y": false}, GameState.story_flags
	))

	# f. inventory/story_flagsのキーがStringNameに戻っているか
	var inventory_keys_ok := true
	for key: Variant in GameState.inventory.keys():
		if typeof(key) != TYPE_STRING_NAME:
			inventory_keys_ok = false
	_check("inventoryのキーがすべてStringName型", inventory_keys_ok)

	var story_flags_keys_ok := true
	for key: Variant in GameState.story_flags.keys():
		if typeof(key) != TYPE_STRING_NAME:
			story_flags_keys_ok = false
	_check("story_flagsのキーがすべてStringName型", story_flags_keys_ok)

	# f続き: shop.gd/night/game.gd と同じ形（StringNameリテラルで直接引く）で取得できるか
	_check(
		"inventory[&\"base_tonkotsu\"]をStringNameリテラルで直接取得できる",
		GameState.inventory.get(&"base_tonkotsu", -1) == 2
	)
	_check(
		"story_flags[&\"flag_x\"]をStringNameリテラルで直接取得できる",
		GameState.story_flags.get(&"flag_x", null) == true
	)

	# g. セーブファイルを削除してload_game()がfalseを返すか（異常系）
	DirAccess.remove_absolute(SaveManager.SAVE_PATH)
	_check("削除後はファイルが存在しない", not FileAccess.file_exists(SaveManager.SAVE_PATH))

	var day_before_failed_load: int = GameState.day
	var load_after_delete: bool = SaveManager.load_game()
	_check("ファイル無しでload_game()がfalseを返す", load_after_delete == false)
	_check("失敗時にGameStateが変化しない", GameState.day == day_before_failed_load)


func _check(label: String, condition: bool) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		print("  FAIL: %s" % label)
		_fail_count += 1


func _dict_matches(expected: Dictionary, actual: Dictionary) -> bool:
	if expected.size() != actual.size():
		return false
	for key: Variant in expected.keys():
		if not actual.has(key):
			return false
		if actual[key] != expected[key]:
			return false
	return true
