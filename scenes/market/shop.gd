# shop.gd
# 市場の店内購入UI（プレースホルダ）。
#
# ベースを購入すると GameState.money が減り GameState.inventory が増える。
# 夜営業（night/game.gd）はこの inventory を見て仕込めるベースを決める。

class_name ShopScene
extends Node2D

var _bases: Array[RecipeResource] = [
	preload("res://data/recipes/base/base_tonkotsu.tres"),
	preload("res://data/recipes/base/base_shojin.tres"),
]

# 困窮脱出動線・段階3（裏手）専用。_bases には絶対に混ぜない
#（_cheapest_base_price() が自己参照して常に0を返すバグになるため別枠で持つ）。
var _junk_base: RecipeResource = preload("res://data/recipes/base/base_kuzu.tres")


func _ready() -> void:
	%BtnBuyBase0.pressed.connect(_on_buy_pressed.bind(0))
	%BtnBuyBase1.pressed.connect(_on_buy_pressed.bind(1))
	%BtnAlley.pressed.connect(_on_junk_pressed)
	%BtnToNight.pressed.connect(_on_to_night_pressed)
	_refresh()


func _on_buy_pressed(index: int) -> void:
	var recipe: RecipeResource = _bases[index]
	if GameState.money < recipe.price:
		return
	GameState.money -= recipe.price
	GameState.inventory[recipe.id] = GameState.inventory.get(recipe.id, 0) + 1
	_refresh()


# 裏手（クズ食材、段階3）の入手処理。金銭のやり取りはなし（0円）。
# _is_junk_available() をここでも再チェックするのは、ボタン表示更新前の
# 連打・状態変化で条件を満たさなくなった後に二重取得させないためのガード。
func _on_junk_pressed() -> void:
	if not _is_junk_available():
		return
	GameState.inventory[_junk_base.id] = GameState.inventory.get(_junk_base.id, 0) + 1
	GameState.junk_taken_today = true
	_refresh()


func _on_to_night_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/night/Game.tscn")


# _bases 中の最安価格。将来ベースの増減があっても追従するよう走査で求める
# （ハードコードしない）。_bases が空になるケースは現状無いが、万一空でも
# 「困窮とみなさない」方向に倒すため大きな値を返すガードを入れている。
func _cheapest_base_price() -> int:
	if _bases.is_empty():
		return 999999
	var cheapest: int = _bases[0].price
	for recipe: RecipeResource in _bases:
		cheapest = min(cheapest, recipe.price)
	return cheapest


# _bases（通常ベースのみ。_junk_base は含めない）のいずれかを1個以上
# 所持していれば true。night/game.gd が _base_catalog を inventory で
# フィルタしているのと同じ「所持しているベースがあるか」の判定。
func _has_base_in_inventory() -> bool:
	for recipe: RecipeResource in _bases:
		if GameState.inventory.get(recipe.id, 0) > 0:
			return true
	return false


# 裏手（クズ食材入手）の発動条件。以下4条件すべてを満たす場合のみ true。
func _is_junk_available() -> bool:
	return (
		GameState.money < _cheapest_base_price()  # 最安ベースすら買うのに足りない
		and not _has_base_in_inventory()  # 通常ベースを1個も持っていない
		and GameState.pot_carryover_volume <= 0  # 残り湯（前日の鍋の持ち越し）も無い
		and not GameState.junk_taken_today  # その日まだ拾っていない
	)


# 日替わりでjunk_taken_todayをリセットするガード。同日中の市場再入場では
# リセットしない（junk_reset_dayとGameState.dayの不一致でのみリセット）。
func _refresh_junk_day_guard() -> void:
	if GameState.junk_reset_day != GameState.day:
		GameState.junk_taken_today = false
		GameState.junk_reset_day = GameState.day


func _refresh() -> void:
	_refresh_junk_day_guard()
	%LabelMoney.text = "所持金 : %d円" % GameState.money
	%BtnBuyBase0.text = _buy_button_text(_bases[0])
	%BtnBuyBase1.text = _buy_button_text(_bases[1])
	%BtnAlley.visible = _is_junk_available()
	%BtnAlley.text = "[裏手] %s を拾う  %d円" % [_junk_base.display_name, _junk_base.price]


func _buy_button_text(recipe: RecipeResource) -> String:
	var owned: int = GameState.inventory.get(recipe.id, 0)
	return "[購入] %s  %d円  （所持:%d）" % [recipe.display_name, recipe.price, owned]
