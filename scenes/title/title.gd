class_name TitleScreen
extends Node2D


func _ready() -> void:
	$CanvasLayer/VBoxContainer/newgame.pressed.connect(_on_newgame_pressed)
	$CanvasLayer/VBoxContainer/load.pressed.connect(_on_load_pressed)
	$CanvasLayer/VBoxContainer/option.pressed.connect(_on_option_pressed)
	$CanvasLayer/VBoxContainer/debug.pressed.connect(_on_debug_pressed)


func _on_newgame_pressed() -> void:
	GameState.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/night/Game.tscn")


func _on_load_pressed() -> void:
	pass  # TODO: セーブデータ読み込み


func _on_option_pressed() -> void:
	pass  # TODO: オプション画面


func _on_debug_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/DebugPot.tscn")
