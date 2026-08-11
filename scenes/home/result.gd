class_name HomeScene
extends Node2D


func _ready() -> void:
	$CanvasLayer/Label.text = "%d日目の営業終了" % GameState.day
	$CanvasLayer/NextDayButton.pressed.connect(_on_next_day_pressed)
	$CanvasLayer/ToTitleButton.pressed.connect(_on_to_title_pressed)
	if GameState.day == 7:
		$CanvasLayer/ToTitleButton.hide()


func _on_next_day_pressed() -> void:
	if not _finalize_day_and_save():
		_handle_day7_ending()
		return
	get_tree().change_scene_to_file("res://scenes/market/DestinationSelect.tscn")


func _on_to_title_pressed() -> void:
	if not _finalize_day_and_save():
		return
	get_tree().change_scene_to_file("res://scenes/title/Title.tscn")


# Day7はクリア後のためセーブしない。day==7の判定はここに一元化する。
func _finalize_day_and_save() -> bool:
	if GameState.day == 7:
		return false
	GameState.next_day()
	if not SaveManager.save():
		push_error("セーブに失敗しました")
	return true


func _handle_day7_ending() -> void:
	GameState.last_ending = GameState.ending_for_reputation(GameState.reputation)
	get_tree().change_scene_to_file("res://scenes/home/Ending.tscn")
