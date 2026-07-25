extends Node


func _ready() -> void:
	print("=== Evaluator テスト開始 ===")
	_run()
	get_tree().quit()


func _run() -> void:
	# --- 客を3人 ---

	# 老人: あっさり系（light 寄り）
	var roujin := CustomerResource.new()
	roujin.display_name = "老人"
	roujin.ideal         = _attrs(1, 5, 2)
	roujin.great_threshold = 2
	roujin.ok_threshold    = 5
	roujin.base_price = 300
	roujin.tip        = 100

	# 配達員: 濃厚・旨味重視
	var haitatsuin := CustomerResource.new()
	haitatsuin.display_name = "配達員"
	haitatsuin.ideal         = _attrs(6, 0, 4)
	haitatsuin.great_threshold = 2
	haitatsuin.ok_threshold    = 5
	haitatsuin.base_price = 250
	haitatsuin.tip        = 80

	# 刑事（元料理人）: バランス・旨味重視、閾値が厳しめ
	var keiji := CustomerResource.new()
	keiji.display_name   = "刑事"
	keiji.ideal          = _attrs(3, 3, 5)
	keiji.great_threshold = 2
	keiji.ok_threshold    = 4
	keiji.base_price  = 400
	keiji.tip         = 150
	keiji.is_pro_critic = true

	# --- 評価ケース ---

	print("\n[老人 × 理想ぴったり]")
	_eval(_cup(1, 5, 2), roujin)

	print("\n[老人 × やや濃い／d=3 → OK]")
	_eval(_cup(3, 4, 2), roujin)

	print("\n[老人 × 濃厚スープを出す → BAD]")
	_eval(_cup(5, 0, 3), roujin)

	print("\n[配達員 × 理想ぴったり]")
	_eval(_cup(6, 0, 4), haitatsuin)

	print("\n[配達員 × あっさりを出す → BAD]")
	_eval(_cup(1, 5, 2), haitatsuin)

	print("\n[刑事(元料理人) × ほぼ理想／d=1 → GREAT]")
	_eval(_cup(3, 4, 5), keiji)

	print("\n[刑事(元料理人) × 旨味不足／d=3 → OK（厳しめ閾値でも通る）]")
	_eval(_cup(3, 3, 2), keiji)

	print("\n=== テスト完了 ===")


func _attrs(rich: int, light: int, umami: int) -> SoupAttrs:
	var a := SoupAttrs.new()
	a.rich  = rich
	a.light = light
	a.umami = umami
	return a


func _cup(rich: int, light: int, umami: int) -> SoupServing:
	var c := SoupServing.new()
	c.attrs = _attrs(rich, light, umami)
	return c


func _eval(cup: SoupServing, customer: CustomerResource) -> void:
	var result: Evaluator.Result = Evaluator.evaluate(cup, customer)
	var grade_str: String = ["GREAT", "OK", "BAD"][int(result.grade)]
	var over_str: String  = "over" if result.over else "under"
	var d          := cup.attrs.distance_to(customer.ideal)
	print("  客: %-12s  cup(r=%d l=%d u=%d)  ideal(r=%d l=%d u=%d)  d=%d" % [
		customer.display_name,
		cup.attrs.rich, cup.attrs.light, cup.attrs.umami,
		customer.ideal.rich, customer.ideal.light, customer.ideal.umami, d
	])
	print("  → %-5s  payment=%d  rep_delta=%+d  worst=%s(%s)" % [
		grade_str, result.payment, result.rep_delta,
		result.worst_axis, over_str
	])
