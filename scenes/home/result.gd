class_name HomeScene
extends Node2D


func _ready() -> void:
	$CanvasLayer/Label.text = "%d日目の営業終了" % GameState.day
	$CanvasLayer/NextDayButton.pressed.connect(_on_next_day_pressed)
	$CanvasLayer/ToTitleButton.pressed.connect(_on_to_title_pressed)


func _on_next_day_pressed() -> void:
	GameState.next_day()
	get_tree().change_scene_to_file("res://scenes/market/DestinationSelect.tscn")


func _on_to_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title/Title.tscn")
