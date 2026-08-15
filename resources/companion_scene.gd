# companion_scene.gd
# 設計メモ「同席者モデル 具体設計」（docs/conversation_design.md）に対応。
#
# 1人のメイン客の場面に対する「同席定義」。そのメインがカウンターに立つ場面で、
# どんな同席パターン群から抽選するかをまとめる。

class_name CompanionScene
extends Resource

# このシーンのメイン客のid。
@export var main: StringName

# そのメイン場面で使う同席パターンの集合。この中から（特別パターン優先→通常は
# 重み抽選で）1つを選ぶ。
@export var patterns: Array[CompanionPattern]
