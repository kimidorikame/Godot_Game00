class_name EndingScene
extends Node2D


func _ready() -> void:
	match GameState.last_ending:
		GameState.Ending.A:
			$CanvasLayer/Label.text = "エンディングA\n評判が閾値以上で謎の男が来た（骨子では実来店未実装）"
		GameState.Ending.B:
			$CanvasLayer/Label.text = "エンディングB\n評判が閾値未満、または最後の一杯が及ばなかった（2段目判定は骨子外）"
	$CanvasLayer/ToTitleButton.pressed.connect(_on_to_title_pressed)


func _on_to_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title/Title.tscn")
