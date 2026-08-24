extends Node

# 味システム6軸化 ステップ5-2b: 二層評価（レシピ軸／好み軸）・6軸・5値Gradeの検証。
# 実データ(.tres)は読み込まず、境界を狙った値をこのテスト内で組み立てる。
#
# 前提となる定数（soup_attrs.gd）:
#   好み軸tolerance(TOLERANCE_xxx)      : koku=8, umami=2, stimulus=2, aroma=2, sweet=2, sour=2
#   レシピ軸tolerance(RECIPE_TOLERANCE_xxx): koku=16, umami=4, stimulus=4, aroma=4, sweet=4, sour=4
#
# 全ケース共通で使うメニュー目標（MENU.target）:
#   koku=40, umami=5, stimulus=2, aroma=4, sweet=3, sour=1

const GRADE_NAMES: Array[String] = ["GREAT", "GOOD", "OK", "POOR", "BAD"]


func _ready() -> void:
	print("=== Evaluator テスト開始 ===")
	_run()
	get_tree().quit()


func _run() -> void:
	var menu := _menu(40, 5, 2, 4, 3, 1)

	# 基準の客: taste_offset全軸0（好みの狙い所=メニュー目標そのまま）、tolerance上書きなし。
	var customer_base := _customer("基準客", _attrs(0, 0, 0, 0, 0, 0), 300, 100)

	# --- 1. GREAT: カップ=メニュー目標そのまま。好み軸6軸すべて diff=0 で合格(taste_pass=6)。---
	# taste_pass==6 が最優先条件なのでrecipe_passに関わらずGREAT。
	# payment=base_price+tip=400, rep_delta=+1。
	# worst_axis: 全軸diff=0のタイ。ループ初期値kokuのまま更新されないためworst=koku、over=(0>0)=false。
	print("\n[GREAT] カップ=メニュー目標ぴったり → 好み軸6/6合格")
	var cup_great := _cup(40, 5, 2, 4, 3, 1)
	_check_result("GREAT", Evaluator.evaluate(cup_great, customer_base, menu),
		Evaluator.Grade.GREAT, 400, 1, &"koku", false)

	# --- 2. GOOD: aromaだけ+3。recipe軸は6/6合格(diff3<=RECIPE_TOLERANCE_AROMA4)、---
	# 好み軸はaromaだけ diff3>TOLERANCE_AROMA2 で不合格、他5軸は合格 → taste_pass=5。
	# recipe_pass==6 かつ taste_pass>=1 → GOOD。payment=base_price=300, rep_delta=+1。
	# worst_axis: aroma diff=+3のみ非0 → worst=aroma, over=true。
	print("\n[GOOD] aromaだけ+3(recipe許容内・好み許容外) → recipe6/6、好み5/6")
	var cup_good := _cup(40, 5, 2, 7, 3, 1)
	_check_result("GOOD", Evaluator.evaluate(cup_good, customer_base, menu),
		Evaluator.Grade.GOOD, 300, 1, &"aroma", true)

	# --- 3. OK: 全軸を「好みtoleranceは超えるがrecipe toleranceには収まる」幅だけずらす。---
	# koku+10(>8,<=16), umami/stimulus/aroma/sweet/sour+3(>2,<=4) → recipe_pass=6, taste_pass=0。
	# recipe_pass==6 かつ taste_pass==0 → OK。payment=base_price=300, rep_delta=0。
	# worst_axis: koku diff=10が最大 → worst=koku, over=true。
	print("\n[OK] 全軸を「recipe許容内・好み許容外」の幅でずらす → recipe6/6、好み0/6")
	var cup_ok := _cup(50, 8, 5, 7, 6, 4)
	_check_result("OK", Evaluator.evaluate(cup_ok, customer_base, menu),
		Evaluator.Grade.OK, 300, 0, &"koku", true)

	# --- 4. POOR: koku/umami/stimulusは目標ぴったり、aroma/sweet/sourは+10で---
	# recipe toleranceも超える(10>4) → recipe_pass=3（1〜5の範囲）。
	# taste_passも3（外した3軸は好みtoleranceも超える）だが、recipe_pass!=6なのでGOOD/OK判定には入らず、
	# recipe_pass>=1 → POOR。payment=int(300*0.5)=150, rep_delta=0。
	# worst_axis: aroma/sweet/sourが同じdiff=10で並ぶが、辞書の走査順(koku→…→sour)で
	# 最初に更新されるaromaのまま以降は「厳密に上回らない」ので確定 → worst=aroma, over=true。
	print("\n[POOR] aroma/sweet/sourをrecipe許容も超える幅(+10)で外す → recipe3/6")
	var cup_poor := _cup(40, 5, 2, 14, 13, 11)
	_check_result("POOR", Evaluator.evaluate(cup_poor, customer_base, menu),
		Evaluator.Grade.POOR, 150, 0, &"aroma", true)

	# --- 5. BAD: 全軸をrecipe toleranceも超える幅でずらす → recipe_pass=0。---
	# payment=int(300*0.5)=150, rep_delta=-1。
	# worst_axis: koku diff=20が最大 → worst=koku, over=true。
	print("\n[BAD] 全軸をrecipe許容も超える幅でずらす → recipe0/6")
	var cup_bad := _cup(60, 15, 12, 14, 13, 11)
	_check_result("BAD", Evaluator.evaluate(cup_bad, customer_base, menu),
		Evaluator.Grade.BAD, 150, -1, &"koku", true)

	# --- 6. 客オフセットの効果検証 ---
	# 同じメニュー・同じカップ(cup_good = aroma+3)でも、客のtaste_offsetが違うとtaste_passが変わる。
	print("\n[客オフセットの効果] 同じカップ(cup_good)を offset違いの2人の客に出す")

	# 6a. offset全軸0の客（customer_base）→ 上のGOODケースと同一条件。aromaだけ好み不合格でGOOD。
	_check_result("offset0×cup_good", Evaluator.evaluate(cup_good, customer_base, menu),
		Evaluator.Grade.GOOD, 300, 1, &"aroma", true)

	# 6b. aromaだけ+3のoffsetを持つ客 → 好みの狙い所がaroma=4+3=7になり、cupのaroma=7と一致(diff0)。
	# 他5軸はoffset0のまま合格 → taste_pass=6 → GREAT。payment=400, rep_delta=+1。
	# worst_axis: 全軸diff=0のタイ → worst=koku(初期値のまま), over=false。
	var customer_offset_aroma := _customer("aromaオフセット客", _attrs(0, 0, 0, 3, 0, 0), 300, 100)
	_check_result("offset+3aroma×cup_good", Evaluator.evaluate(cup_good, customer_offset_aroma, menu),
		Evaluator.Grade.GREAT, 400, 1, &"koku", false)

	# --- 7. 好みtolerance客上書きの効果検証（widen: 上書きで不合格→合格に転じる） ---
	# カップ: umamiだけ+3(diff3)。recipe_pass=6(umami diff3<=RECIPE_TOLERANCE_UMAMI4)。
	print("\n[好みtolerance上書き・widen] umami diff=3 のカップ")
	var cup_umami3 := _cup(40, 8, 2, 4, 3, 1)

	# 7a. tolerance上書きなし(customer_base) → umami diff3>TOLERANCE_UMAMI2で不合格、他5軸合格
	#     → taste_pass=5、recipe_pass=6 → GOOD。payment=300, rep_delta=+1。
	#     worst_axis: umami diff=3のみ非0 → worst=umami, over=true。
	_check_result("umami上書きなし×diff3", Evaluator.evaluate(cup_umami3, customer_base, menu),
		Evaluator.Grade.GOOD, 300, 1, &"umami", true)

	# 7b. tolerance_umami=4に上書き（widen）→ umami diff3<=4で合格に転じる → taste_pass=6 → GREAT。
	#     payment=400, rep_delta=+1。worst_axisはtoleranceと無関係にraw diffで決まるため同じ(umami, over=true)。
	var customer_umami_widen := _customer("umami上書き客(widen)", _attrs(0, 0, 0, 0, 0, 0), 300, 100)
	customer_umami_widen.tolerance_umami = 4
	_check_result("umami widen(4)×diff3", Evaluator.evaluate(cup_umami3, customer_umami_widen, menu),
		Evaluator.Grade.GREAT, 400, 1, &"umami", true)

	# --- 8. 好みtolerance客上書きの効果検証（narrow: 上書きで合格→不合格に転じる） ---
	# カップ: umamiだけ+2(diff2)。共通tolerance(TOLERANCE_UMAMI=2)ではdiff2<=2で境界合格。
	print("\n[好みtolerance上書き・narrow] umami diff=2 のカップ")
	var cup_umami2 := _cup(40, 7, 2, 4, 3, 1)

	# 8a. tolerance上書きなし(customer_base) → umami diff2<=2で合格、他5軸も合格 → taste_pass=6 → GREAT。
	#     payment=400, rep_delta=+1。worst_axis: umami diff=2のみ非0 → worst=umami, over=true。
	_check_result("umami上書きなし×diff2", Evaluator.evaluate(cup_umami2, customer_base, menu),
		Evaluator.Grade.GREAT, 400, 1, &"umami", true)

	# 8b. tolerance_umami=1に上書き（narrow）→ umami diff2>1で不合格に転じる → taste_pass=5、recipe_pass=6
	#     → GOOD。payment=300, rep_delta=+1。worst_axisは同じ(umami, over=true)。
	var customer_umami_narrow := _customer("umami上書き客(narrow)", _attrs(0, 0, 0, 0, 0, 0), 300, 100)
	customer_umami_narrow.tolerance_umami = 1
	_check_result("umami narrow(1)×diff2", Evaluator.evaluate(cup_umami2, customer_umami_narrow, menu),
		Evaluator.Grade.GOOD, 300, 1, &"umami", true)

	# --- 9. worst_axisの向き検証（under方向） ---
	# カップ: umamiだけ-3(diff-3)。recipe: umami diff3<=4合格、他0 → recipe_pass=6。
	# taste: umami diff3>2で不合格、他5軸合格 → taste_pass=5、recipe_pass=6 → GOOD。
	# worst_axis: umami diff=-3のみ非0 → worst=umami, over=(-3>0)=false（under）。
	print("\n[worst_axisのunder方向] umami diff=-3 のカップ")
	var cup_umami_under := _cup(40, 2, 2, 4, 3, 1)
	_check_result("umami under(-3)", Evaluator.evaluate(cup_umami_under, customer_base, menu),
		Evaluator.Grade.GOOD, 300, 1, &"umami", false)

	print("\n=== テスト完了 ===")


func _menu(koku: int, umami: int, stimulus: int, aroma: int, sweet: int, sour: int) -> MenuResource:
	var m := MenuResource.new()
	m.id = &"test_menu"
	m.display_name = "テスト用メニュー"
	m.target = _attrs(koku, umami, stimulus, aroma, sweet, sour)
	return m


func _customer(display_name: String, offset: SoupAttrs, base_price: int, tip: int) -> CustomerResource:
	var c := CustomerResource.new()
	c.display_name = display_name
	c.taste_offset = offset
	c.base_price = base_price
	c.tip = tip
	return c


func _attrs(koku: int, umami: int, stimulus: int, aroma: int, sweet: int, sour: int) -> SoupAttrs:
	var a := SoupAttrs.new()
	a.koku = koku
	a.umami = umami
	a.stimulus = stimulus
	a.aroma = aroma
	a.sweet = sweet
	a.sour = sour
	return a


func _cup(koku: int, umami: int, stimulus: int, aroma: int, sweet: int, sour: int) -> SoupServing:
	var c := SoupServing.new()
	c.attrs = _attrs(koku, umami, stimulus, aroma, sweet, sour)
	return c


# 1件の評価結果(grade/payment/rep_delta/worst_axis/over)を期待値とまとめて検証する。
func _check_result(label: String, result: Evaluator.Result, expected_grade: Evaluator.Grade,
		expected_payment: int, expected_rep_delta: int, expected_worst_axis: StringName,
		expected_over: bool) -> void:
	print("  → %-5s  payment=%d  rep_delta=%+d  worst=%s(%s)" % [
		GRADE_NAMES[int(result.grade)], result.payment, result.rep_delta,
		result.worst_axis, "over" if result.over else "under",
	])
	_check("%s grade" % label, GRADE_NAMES[int(result.grade)], GRADE_NAMES[int(expected_grade)])
	_check("%s payment" % label, result.payment, expected_payment)
	_check("%s rep_delta" % label, result.rep_delta, expected_rep_delta)
	_check("%s worst_axis" % label, String(result.worst_axis), String(expected_worst_axis))
	_check("%s over" % label, result.over, expected_over)


# 期待値と実測値を比較し、OK/NG をログに出す簡易アサーション（test_pot.gdと同じ流儀）。
func _check(label: String, actual: Variant, expected: Variant) -> void:
	var status := "OK" if actual == expected else "NG"
	print("  [%s] %s : actual=%s expected=%s" % [status, label, str(actual), str(expected)])
