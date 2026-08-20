extends Node


func _ready() -> void:
	print("=== Evaluator テスト開始 ===")
	_run()
	get_tree().quit()


func _run() -> void:
	# --- 客を3人 ---

	# 老人: あっさり系（koku低め）・旨味高・香り高・刺激苦手
	var roujin := CustomerResource.new()
	roujin.display_name = "老人"
	roujin.ideal      = _attrs(10, 4, 0, 4)
	roujin.base_price = 300
	roujin.tip        = 100

	# 配達員: 濃厚・旨味重視・刺激好き
	var haitatsuin := CustomerResource.new()
	haitatsuin.display_name = "配達員"
	haitatsuin.ideal      = _attrs(45, 4, 4, 2)
	haitatsuin.base_price = 250
	haitatsuin.tip        = 80

	# 刑事（元料理人）: バランス・旨味重視・香り良い
	var keiji := CustomerResource.new()
	keiji.display_name   = "刑事"
	keiji.ideal          = _attrs(25, 5, 2, 4)
	keiji.base_price     = 400
	keiji.tip            = 150
	keiji.is_pro_critic  = true

	# --- 評価ケース（軸ごと合格判定モデル。4段階すべてを網羅する）---

	print("\n[老人 × 理想ぴったり(4軸合格) → GREAT]")
	_eval(_cup(10, 4, 0, 4), roujin)

	print("\n[配達員 × 香りだけ大外し(3軸合格) → GOOD、worst=aroma(over)]")
	_eval(_cup(45, 4, 4, 10), haitatsuin)

	print("\n[刑事 × 刺激・香り外し(2軸合格) → OK、worst=stimulus(over)]")
	_eval(_cup(25, 5, 20, 10), keiji)

	print("\n[配達員 × koku以外全外し(1軸合格) → OK]")
	_eval(_cup(45, 20, 20, 20), haitatsuin)

	print("\n[老人 × 全軸大外し(0軸合格) → BAD、worst=koku(over)]")
	_eval(_cup(40, 0, 10, 0), roujin)

	# --- 客別tolerance上書き検証（サブステップ3-2）---
	# 老人にtolerance上書き（.tresと同じ値: umami=1(狭め)/stimulus=4(広め)/aroma=1(狭め)、
	# kokuは-1のまま共通定数(8)にフォールバック）を持たせた客を用意し、
	# 同じカップを「共通定数のみのroujin」と評価し比べることで、
	# フォールバック（既存roujinが変わらないこと）と上書き効果の両方を確認する。
	var roujin_tol := CustomerResource.new()
	roujin_tol.display_name = "老人(tolerance上書き)"
	roujin_tol.ideal              = _attrs(10, 4, 0, 4)
	roujin_tol.tolerance_umami    = 1
	roujin_tol.tolerance_stimulus = 4
	roujin_tol.tolerance_aroma    = 1
	roujin_tol.base_price = 300
	roujin_tol.tip        = 100

	print("\n[老人(共通定数) × umamiズレ2(共通tolerance=2で合格) → GREAT]")
	_eval(_cup(10, 6, 0, 4), roujin)

	print("\n[老人(tolerance上書きumami=1・狭め) × 同じカップ → 不合格に転じる → GOOD、worst=umami(over)]")
	_eval(_cup(10, 6, 0, 4), roujin_tol)

	print("\n[老人(共通定数) × stimulusズレ3(共通tolerance=2で不合格) → GOOD、worst=stimulus(over)]")
	_eval(_cup(10, 4, 3, 4), roujin)

	print("\n[老人(tolerance上書きstimulus=4・広め) × 同じカップ → 合格に転じる → GREAT]")
	_eval(_cup(10, 4, 3, 4), roujin_tol)

	print("\n=== テスト完了 ===")


func _attrs(koku: int, umami: int, stimulus: int, aroma: int) -> SoupAttrs:
	var a := SoupAttrs.new()
	a.koku     = koku
	a.umami    = umami
	a.stimulus = stimulus
	a.aroma    = aroma
	return a


func _cup(koku: int, umami: int, stimulus: int, aroma: int) -> SoupServing:
	var c := SoupServing.new()
	c.attrs = _attrs(koku, umami, stimulus, aroma)
	return c


func _eval(cup: SoupServing, customer: CustomerResource) -> void:
	var result: Evaluator.Result = Evaluator.evaluate(cup, customer)
	var grade_str: String = ["GREAT", "GOOD", "OK", "BAD"][int(result.grade)]
	var over_str: String  = "over" if result.over else "under"
	print("  客: %-12s  cup(koku=%d u=%d s=%d a=%d)  ideal(koku=%d u=%d s=%d a=%d)" % [
		customer.display_name,
		cup.attrs.koku, cup.attrs.umami, cup.attrs.stimulus, cup.attrs.aroma,
		customer.ideal.koku, customer.ideal.umami, customer.ideal.stimulus, customer.ideal.aroma,
	])
	print("  → %-5s  payment=%d  rep_delta=%+d  worst=%s(%s)" % [
		grade_str, result.payment, result.rep_delta,
		result.worst_axis, over_str
	])
