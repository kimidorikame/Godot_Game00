# menu_resource.gd
# 設計書 味の世界観・ゲーム構造設計（taste_world_design.md）、
# 味システム6軸化 ステップ5-2a（taste_system_design.md）に対応。
#
# メニュー1種が持つ目標の味（target）を定義するデータクラス。評価は味（target）で行い、
# 材料リスト＝レシピ集で見せる作り方は将来の構造転換フェーズで別途持つ。

class_name MenuResource
extends Resource

# スクリプト内でメニューを参照するための一意な識別子（例: &"yakuzen"）。
@export var id: StringName

# UI や会話で表示するメニュー名。
@export var display_name: String

# このメニューが目標とする味の6軸値（koku/umami/stimulus/aroma/sweet/sour）。
# 評価のレシピ軸判定で、カップの6軸と突き合わせる基準点になる。
@export var target: SoupAttrs
