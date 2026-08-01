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


func _ready() -> void:
	%BtnBuyBase0.pressed.connect(_on_buy_pressed.bind(0))
	%BtnBuyBase1.pressed.connect(_on_buy_pressed.bind(1))
	%BtnToNight.pressed.connect(_on_to_night_pressed)
	_refresh()


func _on_buy_pressed(index: int) -> void:
	var recipe: RecipeResource = _bases[index]
	if GameState.money < recipe.price:
		return
	GameState.money -= recipe.price
	GameState.inventory[recipe.id] = GameState.inventory.get(recipe.id, 0) + 1
	_refresh()


func _on_to_night_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/night/Game.tscn")


func _refresh() -> void:
	%LabelMoney.text = "所持金 : %d円" % GameState.money
	%BtnBuyBase0.text = _buy_button_text(_bases[0])
	%BtnBuyBase1.text = _buy_button_text(_bases[1])


func _buy_button_text(recipe: RecipeResource) -> String:
	var owned: int = GameState.inventory.get(recipe.id, 0)
	return "[購入] %s  %d円  （所持:%d）" % [recipe.display_name, recipe.price, owned]
