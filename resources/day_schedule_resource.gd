# day_schedule_resource.gd
# 設計書 3.4「来店スケジュール（DayScheduleResource）」に対応。
#
# その日に来店する客の並びを定義するデータクラス。
# night/game.gd が GameState.day に応じて data/schedule/day{N}.tres を読み込み、
# visitors を客カタログで解決して _customers を組み立てる。

class_name DayScheduleResource
extends Resource

# 何日目のスケジュールか（対応する.tresのファイル名 day{N}.tres と一致させる）。
@export var day: int

# 来店順の客id（CustomerResource.id と対応、3件）。
@export var visitors: Array[StringName]

# 前日のMORNINGで予告される2人（骨子では未使用、会話フェーズで使用予定）。
@export var previewed: Array[StringName]

# 制作メモ（例: 節目の日の演出予定など）。
@export var note: String
