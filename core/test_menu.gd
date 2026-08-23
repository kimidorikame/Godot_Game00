extends Node


func _ready() -> void:
	print("=== Menu テスト開始 ===")
	_run()
	get_tree().quit()


func _run() -> void:
	_check_menu("res://data/menus/yakuzen.tres", &"yakuzen", "薬膳スープ",
		_attrs(40, 5, 1, 5, 3, 1))
	_check_menu("res://data/menus/tomyum.tres", &"tomyum", "トムヤム",
		_attrs(10, 5, 5, 5, 3, 5))
	_check_menu("res://data/menus/tomkha.tres", &"tomkha", "トムカーガイ",
		_attrs(40, 3, 3, 5, 5, 3))

	print("\n=== テスト完了 ===")


func _attrs(koku: int, umami: int, stimulus: int, aroma: int, sweet: int, sour: int) -> SoupAttrs:
	var a := SoupAttrs.new()
	a.koku = koku
	a.umami = umami
	a.stimulus = stimulus
	a.aroma = aroma
	a.sweet = sweet
	a.sour = sour
	return a


# 1メニュー分のロード検証。load成功・MenuResource型・id/display_name・target6軸の一致を確認する。
func _check_menu(path: String, expected_id: StringName, expected_display_name: String,
		expected_target: SoupAttrs) -> void:
	print("\n--- %s ---" % path)
	var menu: MenuResource = load(path)
	assert(menu != null, "ロード失敗: %s" % path)
	assert(menu is MenuResource, "MenuResource型でない: %s" % path)
	_check("id", str(menu.id), str(expected_id))
	_check("display_name", menu.display_name, expected_display_name)
	_check("target.koku", menu.target.koku, expected_target.koku)
	_check("target.umami", menu.target.umami, expected_target.umami)
	_check("target.stimulus", menu.target.stimulus, expected_target.stimulus)
	_check("target.aroma", menu.target.aroma, expected_target.aroma)
	_check("target.sweet", menu.target.sweet, expected_target.sweet)
	_check("target.sour", menu.target.sour, expected_target.sour)


# 期待値と実測値を比較し、OK/NG をログに出す簡易アサーション。値の型を問わず文字列化して比較する。
func _check(label: String, actual, expected) -> void:
	var status := "OK" if actual == expected else "NG"
	print("  [%s] %s : actual=%s expected=%s" % [status, label, actual, expected])
	assert(actual == expected, "%s : actual=%s expected=%s" % [label, actual, expected])
