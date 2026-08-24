# evaluator.gd
# 設計書 4.2「評価（Evaluator）」、味システム6軸化 ステップ5-2b（taste_system_design.md）に対応。
#
# 「カップ（SoupServing）」「客（CustomerResource）」「注文メニュー（MenuResource）」を受け取り、
# 満足度グレード・支払い額・評判変動を計算して Result として返す。
# 呼び出し側の状態を一切変更しない純粋な計算クラス。
#
# インスタンスを作る必要がないよう、すべてのメソッドを static にしている。
# RefCounted を継承しているのは class_name を付けるために最小限の基底クラスが
# 必要なためで、実体としてはユーティリティクラスとして使う。

class_name Evaluator
extends RefCounted

# 満足度のグレード。GREAT（大満足）・GOOD（美味しい）・OK（普通）・POOR（イマイチ）・
# BAD（不満）の5段階。
enum Grade { GREAT, GOOD, OK, POOR, BAD }


# 評価結果をひとまとめにした内部クラス。
# evaluate() の戻り値として返し、UI や GameState の更新に使う。
class Result extends RefCounted:
	# 満足度グレード（GREAT / GOOD / OK / POOR / BAD）。
	var grade: Evaluator.Grade

	# 最も理想から外れていた属性名（&"koku" / &"umami" / &"stimulus" / &"aroma" /
	# &"sweet" / &"sour"）。好み軸（menu.target + customer.taste_offset）を基準に判定する。
	# 不満だったときに「何が原因で不満だったか」を客のリアクションや
	# ヒント台詞につなげるための情報（設計書9章、台詞への接続自体は未実装）。
	var worst_axis: StringName

	# worst_axis が好みの狙い所より多かった（over=true）か少なかった（false）か。
	# worst_axis と組み合わせて「濃すぎた」「薄すぎた」のように
	# 具体的な方向まで伝えられるようにするための値。
	var over: bool

	# 実際に受け取る金額（円）。グレードによって変わる。
	var payment: int

	# 評判の増減値。GREAT/GOOD=+1, OK/POOR=±0, BAD=−1。
	var rep_delta: int


# カップ・客・注文メニューを受け取り、評価結果（Result）を返す。
# Pot.serve() で得た SoupServing を Evaluator.evaluate() に渡すのがメインの使い方。
# 呼んでも鍋・客・メニュー・ゲーム状態は変化しない（副作用なし）。
#
# 二層評価モデル: 「レシピ軸」と「好み軸」の2つの軸ごと合格判定を独立に行い、
# その組み合わせでグレードを決める。
# - レシピ軸: カップが menu.target（注文されたメニューの目標値）にどれだけ近いか。
#   「メニューとして成立しているか」を見る層で、客の好みは関係ない。tolerance は
#   RECIPE_TOLERANCE_xxx（共通・客上書きなし）を使う。合格軸数を recipe_pass とする。
# - 好み軸: カップが menu.target + customer.taste_offset（その客にとっての狙い所）に
#   どれだけ近いか。「その客の好みに刺さっているか」を見る層。tolerance は
#   TOLERANCE_xxx（客ごとに tolerance_xxx で上書き可、_tol() で解決）を使う。
#   合格軸数を taste_pass とする。
# 6軸（koku/umami/stimulus/aroma/sweet/sour）すべてで判定する。
#
# Grade判定は以下の優先順で決める（この順で最初に当てはまったものを採用）:
#   1. taste_pass == 6                     → GREAT（狙い所に完全に刺さった）
#   2. recipe_pass == 6 かつ taste_pass >= 1 → GOOD（メニューとして成立＋多少好みにも合う）
#   3. recipe_pass == 6 かつ taste_pass == 0 → OK（メニューとしては成立するが好みには合わない）
#   4. recipe_pass が 1〜5                  → POOR（メニューとして半端）
#   5. recipe_pass == 0                    → BAD（メニューとして成立していない）
static func evaluate(cup: SoupServing, customer: CustomerResource, menu: MenuResource) -> Result:
	var r := Result.new()

	var recipe_pass := 0
	if abs(cup.attrs.koku - menu.target.koku) <= SoupAttrs.RECIPE_TOLERANCE_KOKU:
		recipe_pass += 1
	if abs(cup.attrs.umami - menu.target.umami) <= SoupAttrs.RECIPE_TOLERANCE_UMAMI:
		recipe_pass += 1
	if abs(cup.attrs.stimulus - menu.target.stimulus) <= SoupAttrs.RECIPE_TOLERANCE_STIMULUS:
		recipe_pass += 1
	if abs(cup.attrs.aroma - menu.target.aroma) <= SoupAttrs.RECIPE_TOLERANCE_AROMA:
		recipe_pass += 1
	if abs(cup.attrs.sweet - menu.target.sweet) <= SoupAttrs.RECIPE_TOLERANCE_SWEET:
		recipe_pass += 1
	if abs(cup.attrs.sour - menu.target.sour) <= SoupAttrs.RECIPE_TOLERANCE_SOUR:
		recipe_pass += 1

	var taste_pass := 0
	if abs(cup.attrs.koku - (menu.target.koku + customer.taste_offset.koku)) <= _tol(customer.tolerance_koku, SoupAttrs.TOLERANCE_KOKU):
		taste_pass += 1
	if abs(cup.attrs.umami - (menu.target.umami + customer.taste_offset.umami)) <= _tol(customer.tolerance_umami, SoupAttrs.TOLERANCE_UMAMI):
		taste_pass += 1
	if abs(cup.attrs.stimulus - (menu.target.stimulus + customer.taste_offset.stimulus)) <= _tol(customer.tolerance_stimulus, SoupAttrs.TOLERANCE_STIMULUS):
		taste_pass += 1
	if abs(cup.attrs.aroma - (menu.target.aroma + customer.taste_offset.aroma)) <= _tol(customer.tolerance_aroma, SoupAttrs.TOLERANCE_AROMA):
		taste_pass += 1
	if abs(cup.attrs.sweet - (menu.target.sweet + customer.taste_offset.sweet)) <= _tol(customer.tolerance_sweet, SoupAttrs.TOLERANCE_SWEET):
		taste_pass += 1
	if abs(cup.attrs.sour - (menu.target.sour + customer.taste_offset.sour)) <= _tol(customer.tolerance_sour, SoupAttrs.TOLERANCE_SOUR):
		taste_pass += 1

	if taste_pass == 6:
		r.grade = Grade.GREAT
		r.payment = customer.base_price + customer.tip
		r.rep_delta = 1
	elif recipe_pass == 6 and taste_pass >= 1:
		r.grade = Grade.GOOD
		r.payment = customer.base_price
		r.rep_delta = 1
	elif recipe_pass == 6 and taste_pass == 0:
		r.grade = Grade.OK
		r.payment = customer.base_price
		r.rep_delta = 0
	elif recipe_pass >= 1:
		r.grade = Grade.POOR
		r.payment = int(customer.base_price * 0.5)
		r.rep_delta = 0
	else:
		r.grade = Grade.BAD
		r.payment = int(customer.base_price * 0.5)
		r.rep_delta = -1
	_fill_worst_axis(r, cup, customer, menu)
	return r


# 軸1本分のtoleranceを解決する。customer_value が -1（未指定）なら共通定数
# default_const を、0以上ならその客の上書き値をそのまま返す。
# 好み軸でのみ使う（レシピ軸は常に共通のRECIPE_TOLERANCE_xxxをそのまま使い、
# customer側の上書きを持たない）。
static func _tol(customer_value: int, default_const: int) -> int:
	return default_const if customer_value < 0 else customer_value


# 6軸（koku/umami/stimulus/aroma/sweet/sour）のうち、好み軸の基準
# （menu.target + c.taste_offset）から最も差が大きかったものを Result に書き込む。
# evaluate() の内部処理として呼ばれ、直接呼ぶ場面はない。
static func _fill_worst_axis(r: Result, cup: SoupServing, c: CustomerResource, menu: MenuResource) -> void:
	var diffs := {
		&"koku":     cup.attrs.koku     - (menu.target.koku     + c.taste_offset.koku),
		&"umami":    cup.attrs.umami    - (menu.target.umami    + c.taste_offset.umami),
		&"stimulus": cup.attrs.stimulus - (menu.target.stimulus + c.taste_offset.stimulus),
		&"aroma":    cup.attrs.aroma    - (menu.target.aroma    + c.taste_offset.aroma),
		&"sweet":    cup.attrs.sweet    - (menu.target.sweet    + c.taste_offset.sweet),
		&"sour":     cup.attrs.sour     - (menu.target.sour     + c.taste_offset.sour),
	}
	var worst: StringName = &"koku"
	for k: StringName in diffs:
		if abs(diffs[k]) > abs(diffs[worst]):
			worst = k
	r.worst_axis = worst
	# diffs[worst] が正ならカップの方が多い（over）、負なら少ない（under）。
	r.over = diffs[worst] > 0
