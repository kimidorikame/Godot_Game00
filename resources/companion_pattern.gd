# companion_pattern.gd
# 設計メモ「同席者モデル 具体設計」（docs/conversation_design.md）に対応。
#
# 1つの「同席パターン」を表すデータクラス。あるメイン客の場面で「誰が同席し、
# どの会話を、どれくらいの確率で出すか」を1件分持つ。
# CompanionScene.patterns に複数まとめて、特別パターン優先→通常は重み付き抽選で
# 1件選ばれる想定。

class_name CompanionPattern
extends Resource

# この同席パターンで同席する客のid（メイン客自身は含めない）。空配列ならメインのみ（同席者なし）。
@export var companions: Array[StringName]

# 重み付き抽選での重み。大きいほど選ばれやすい。
@export var weight: int = 1

# この顔ぶれ用の会話タイムライン(.dtl)候補。抽選でこのパターンが選ばれた後、
# この中からさらにランダムで1本再生する。
@export var timeline_ids: Array[StringName]

# 空でなければ「特別パターン」。GameState.story_flags がこの条件を満たす時のみ、
# 通常の重み抽選より優先して使う（Day5の黒社会＋刑事の掛け合いなど）。空なら通常パターン。
@export var required_flags: Array[StringName]
