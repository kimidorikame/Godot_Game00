class_name HomeScene
extends Node2D


func _ready() -> void:
	$CanvasLayer/Label.text = "%d日目の営業終了" % GameState.day
	$CanvasLayer/NextDayButton.pressed.connect(_on_next_day_pressed)
	$CanvasLayer/ToTitleButton.pressed.connect(_on_to_title_pressed)


func _on_next_day_pressed() -> void:
	if GameState.day == 7:
		_handle_day7_ending()
		return
	GameState.next_day()
	if not SaveManager.save():
		push_error("セーブに失敗しました")
	get_tree().change_scene_to_file("res://scenes/market/DestinationSelect.tscn")


func _on_to_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title/Title.tscn")


# TODO(M4-4): Day7判定（reputation閾値）とEnding.tscnへの遷移をここに実装する。
# ステップ3時点では受け皿のみ（実際の遷移は行わない。セーブもしない）。
func _handle_day7_ending() -> void:
	push_warning("Day7エンディング未実装（M4-4で対応）")
