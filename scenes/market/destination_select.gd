# destination_select.gd
# 昼パート（MARKETフェーズ）の入口となる行き先選択画面。
#
# 今日は行き先が「市場」1つだけだが、後日ここにボタンを追加するだけで
# 行き先を増やせるようにしておく（Title.tscn の各ボタンと同じ構成）。

class_name DestinationSelectScreen
extends Node2D


func _ready() -> void:
	%BtnMarket.pressed.connect(_on_market_pressed)
	_refresh()


func _on_market_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/market/Shop.tscn")


func _refresh() -> void:
	%LabelMoney.text = "所持金 : %d円" % GameState.money
