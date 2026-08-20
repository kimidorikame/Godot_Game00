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

# 満足度のグレード。GREAT（大満足）・GOOD（美味しい）・OK（普通）・BAD（不満）の4段階。
enum Grade { GREAT, GOOD, OK, BAD }


# 評価結果をひとまとめにした内部クラス。
# evaluate() の戻り値として返し、UI や GameState の更新に使う。
class Result extends RefCounted:
	# 満足度グレード（GREAT / GOOD / OK / BAD）。
	var grade: Evaluator.Grade

	# 最も理想から外れていた属性名（&"koku" / &"umami" / &"stimulus" / &"aroma"）。
	# BAD だったときに「何が原因で不満だったか」を客のリアクションや
	# ヒント台詞につなげるための情報（設計書9章、台詞への接続自体は未実装）。
	var worst_axis: StringName

	# worst_axis が理想より多かった（over=true）か少なかった（false）か。
	# worst_axis と組み合わせて「濃すぎた」「薄すぎた」のように
	# 具体的な方向まで伝えられるようにするための値。
	var over: bool

	# 実際に受け取る金額（円）。グレードによって変わる。
	var payment: int

	# 評判の増減値。GREAT/GOOD=+1, OK=±0, BAD=−1。
	var rep_delta: int


# カップと客を受け取り、評価結果（Result）を返す。
# Pot.serve() で得た SoupServing を Evaluator.evaluate() に渡すのがメインの使い方。
# 呼んでも鍋・客・ゲーム状態は変化しない（副作用なし）。
#
# 軸ごと合格判定モデル: 合算した単一距離ではなく、koku/umami/stimulus/aroma の4軸
# それぞれについて「idealとの差がtolerance以内か」を個別に判定し、合格した軸の本数で
# グレードを決める。1軸大外し＋他ピタリ、と全軸を薄く外す、を区別できるようにするため。
# 各軸のtoleranceは客ごとに上書き可能（CustomerResource.tolerance_xxx が -1 なら
# soup_attrs.gd の共通定数、0以上ならその客の値を使う。_tol() で解決する）。
static func evaluate(cup: SoupServing, customer: CustomerResource) -> Result:
	var r := Result.new()
	var pass_count := 0
	if abs(cup.attrs.koku - customer.ideal.koku) <= _tol(customer.tolerance_koku, SoupAttrs.TOLERANCE_KOKU):
		pass_count += 1
	if abs(cup.attrs.umami - customer.ideal.umami) <= _tol(customer.tolerance_umami, SoupAttrs.TOLERANCE_UMAMI):
		pass_count += 1
	if abs(cup.attrs.stimulus - customer.ideal.stimulus) <= _tol(customer.tolerance_stimulus, SoupAttrs.TOLERANCE_STIMULUS):
		pass_count += 1
	if abs(cup.attrs.aroma - customer.ideal.aroma) <= _tol(customer.tolerance_aroma, SoupAttrs.TOLERANCE_AROMA):
		pass_count += 1

	# 合格本数→グレード。4→GREAT, 3→GOOD, 2/1→OK, 0→BAD。
	if pass_count == 4:
		r.grade = Grade.GREAT
		r.payment = customer.base_price + customer.tip
		r.rep_delta = 1
	elif pass_count == 3:
		r.grade = Grade.GOOD
		r.payment = customer.base_price
		r.rep_delta = 1
	elif pass_count >= 1:
		r.grade = Grade.OK
		r.payment = customer.base_price
		r.rep_delta = 0
	else:
		r.grade = Grade.BAD
		r.payment = int(customer.base_price * 0.5)
		r.rep_delta = -1
	_fill_worst_axis(r, cup, customer)
	return r


# 軸1本分のtoleranceを解決する。customer_value が -1（未指定）なら共通定数
# default_const を、0以上ならその客の上書き値をそのまま返す。
static func _tol(customer_value: int, default_const: int) -> int:
	return default_const if customer_value < 0 else customer_value


# 4軸（koku / umami / stimulus / aroma）のうち最も差が大きかったものを Result に書き込む。
# evaluate() の内部処理として呼ばれ、直接呼ぶ場面はない。
static func _fill_worst_axis(r: Result, cup: SoupServing, c: CustomerResource) -> void:
	var diffs := {
		&"koku":     cup.attrs.koku     - c.ideal.koku,
		&"umami":    cup.attrs.umami    - c.ideal.umami,
		&"stimulus": cup.attrs.stimulus - c.ideal.stimulus,
		&"aroma":    cup.attrs.aroma    - c.ideal.aroma,
	}
	var worst: StringName = &"koku"
	for k: StringName in diffs:
		if abs(diffs[k]) > abs(diffs[worst]):
			worst = k
	r.worst_axis = worst
	# diffs[worst] が正ならカップの方が多い（over）、負なら少ない（under）。
	r.over = diffs[worst] > 0
