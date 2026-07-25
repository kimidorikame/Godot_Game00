class_name NightScene
extends Node2D


func _ready() -> void:
	$CanvasLayer/EndDayButton.pressed.connect(end_day)


# 1日の営業終了時に呼ぶ
func end_day() -> void:
	# 売上計算などをここで GameState.money に反映する
	get_tree().change_scene_to_file("res://scenes/home/Result.tscn")
