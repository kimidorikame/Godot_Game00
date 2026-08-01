# evaluator.gd
# 設計書 4.2「評価（Evaluator）」に対応。
#
# 「カップ（SoupServing）」と「客（CustomerResource）」を受け取り、
# 満足度グレード・支払い額・評判変動を計算して Result として返す。
# 呼び出し側の状態を一切変更しない純粋な計算クラス。
#
# インスタンスを作る必要がないよう、すべてのメソッドを static にしている。
# RefCounted を継承しているのは class_name を付けるために最小限の基底クラスが
# 必要なためで、実体としてはユーティリティクラスとして使う。

class_name Evaluator
extends RefCounted

# 満足度のグレード。GREAT（大満足）・OK（普通）・BAD（不満）の3段階。
enum Grade { GREAT, OK, BAD }


# 評価結果をひとまとめにした内部クラス。
# evaluate() の戻り値として返し、UI や GameState の更新に使う。
class Result extends RefCounted:
	# 満足度グレード（GREAT / OK / BAD）。
	var grade: Evaluator.Grade

	# 最も理想から外れていた属性名（&"rich" / &"light" / &"umami"）。
	# BAD だったときに「何が原因で不満だったか」を客のリアクションや
	# ヒント台詞につなげるための情報（設計書9章、台詞への接続自体は未実装）。
	var worst_axis: StringName

	# worst_axis が理想より多かった（over=true）か少なかった（false）か。
	# worst_axis と組み合わせて「濃すぎた」「薄すぎた」のように
	# 具体的な方向まで伝えられるようにするための値。
	var over: bool

	# 実際に受け取る金額（円）。グレードによって変わる。
	var payment: int

	# 評判の増減値。GREAT=+1, OK=±0, BAD=−1。
	var rep_delta: int


# カップと客を受け取り、評価結果（Result）を返す。
# Pot.serve() で得た SoupServing を Evaluator.evaluate() に渡すのがメインの使い方。
# 呼んでも鍋・客・ゲーム状態は変化しない（副作用なし）。
static func evaluate(cup: SoupServing, customer: CustomerResource) -> Result:
	var r := Result.new()
	# d はカップ属性と客の理想属性のマンハッタン距離（差の合計）。
	# rich/light/umami の3軸のズレを「どっちの軸がどうずれたか」ではなく
	# まず1つの数値にまとめたいため、単純な絶対差の合計を採用している。
	# 距離が小さいほど客の好みに近い。
	var d := cup.attrs.distance_to(customer.ideal)
	# 閾値を2段階（great_threshold と ok_threshold）用意することで、
	# 「ぴったり好み」と「許容範囲内」を分けて3段階評価にしている。
	# 閾値そのものは客ごとの CustomerResource が持つため、
	# 好みにシビアな客／おおらかな客の作り分けはデータ側だけで完結する。
	if d <= customer.great_threshold:
		r.grade = Grade.GREAT
		r.payment = customer.base_price + customer.tip
		r.rep_delta = 1
	elif d <= customer.ok_threshold:
		r.grade = Grade.OK
		r.payment = customer.base_price
		r.rep_delta = 0
	else:
		r.grade = Grade.BAD
		r.payment = int(customer.base_price * 0.5)
		r.rep_delta = -1
	_fill_worst_axis(r, cup, customer)
	return r


# 3 軸（rich / light / umami）のうち最も差が大きかったものを Result に書き込む。
# evaluate() の内部処理として呼ばれ、直接呼ぶ場面はない。
static func _fill_worst_axis(r: Result, cup: SoupServing, c: CustomerResource) -> void:
	var diffs := {
		&"rich":  cup.attrs.rich  - c.ideal.rich,
		&"light": cup.attrs.light - c.ideal.light,
		&"umami": cup.attrs.umami - c.ideal.umami,
	}
	var worst: StringName = &"rich"
	for k: StringName in diffs:
		if abs(diffs[k]) > abs(diffs[worst]):
			worst = k
	r.worst_axis = worst
	# diffs[worst] が正ならカップの方が多い（over）、負なら少ない（under）。
	r.over = diffs[worst] > 0
