class_name DishResult
extends RefCounted
## 3層評価（料理成立・食材相性・事情適合）＋固定嗜好＋物語フラグの結果を、
## 合算せずに別々に保持する器。
## 旧 Evaluator.Result が payment/grade という単一の総合値に畳んでいたのと対照的に、
## ここでは各層の判定を独立したフィールドのまま持つ。
## 経済出力（支払・評判）はこの結果から別途導出する（このクラス自身は経済を持たない）。

## 料理成立: 失敗/難あり/成立
enum Validity {
	FAIL,    ## 失敗（料理として成立していない）
	FLAWED,  ## 難あり（成立しているが問題を抱える）
	VALID,   ## 成立
}

## 食材相性: 衝突/中立/調和
enum Harmony {
	CLASH,   ## 衝突（相性が悪い）
	NEUTRAL, ## 中立
	HARMONY, ## 調和（相性が良い）
}

## 事情適合: 不一致/一部一致/一致
enum NeedFit {
	MISS,    ## 不一致（今夜の事情に合わない）
	PARTIAL, ## 一部一致
	MATCH,   ## 一致（今夜の事情に応えている）
}

## 固定嗜好: 苦手/中立/好み
enum PreferenceFit {
	DISLIKE, ## 苦手
	NEUTRAL, ## 中立
	LIKE,    ## 好み
}

## 料理成立の判定
var validity: Validity = Validity.FAIL

## 食材相性の判定
var harmony: Harmony = Harmony.NEUTRAL

## 事情適合の判定
var need_fit: NeedFit = NeedFit.MISS

## 固定嗜好の判定
var preference_fit: PreferenceFit = PreferenceFit.NEUTRAL

## 立った物語フラグ（例: care_seen）
var story_flags: Array[StringName] = []

## 発火したフィードバックイベントID
var fired_events: Array[StringName] = []
