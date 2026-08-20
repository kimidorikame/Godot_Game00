extends Control

# ─── 食材データ（data/recipes/ の .tres を参照）────────────
# トッピング・薬味の先頭 null は「なし」を表す。
var _bases: Array[RecipeResource] = [
	preload("res://data/recipes/base/base_tonkotsu.tres"),
	preload("res://data/recipes/base/base_shojin.tres"),
]
var _toppings: Array[RecipeResource] = [
	null,
	preload("res://data/recipes/topping/top_yutiao.tres"),
	preload("res://data/recipes/topping/top_atsuage.tres"),
	preload("res://data/recipes/topping/top_chashu.tres"),
]
var _yakumis: Array[RecipeResource] = [
	null,
	preload("res://data/recipes/yakumi/yak_shoga.tres"),
	preload("res://data/recipes/yakumi/yak_ninniku.tres"),
	preload("res://data/recipes/yakumi/yak_kurozu.tres"),
]

var _pot: Pot = null
var _customers: Array[CustomerResource] = []
var _customer_index: int = 0
var _base_index: int    = 0
var _topping_index: int = 0
var _yakumi_index: int  = 0


func _ready() -> void:
	_build_customers()
	%BtnSelectBase.pressed.connect(_on_select_base)
	%BtnSelectTopping.pressed.connect(_on_select_topping)
	%BtnSelectYakumi.pressed.connect(_on_select_yakumi)
	%BtnSwitchCustomer.pressed.connect(_on_switch_customer)
	%BtnSetup.pressed.connect(_on_setup)
	%BtnServe.pressed.connect(_on_serve)
	%BtnTurnEnd.pressed.connect(_on_turn_end)
	%BtnAddWater.pressed.connect(_on_add_water)
	%BtnReset.pressed.connect(_on_reset)
	_setup_pot()


func _build_customers() -> void:
	_customers = [
		preload("res://data/customers/roujin.tres"),
		preload("res://data/customers/haitatsuin.tres"),
		preload("res://data/customers/keiji.tres"),
	]


func _setup_pot() -> void:
	var base: RecipeResource = _bases[_base_index]
	_pot = Pot.new()
	_pot.setup(base, [])
	%LabelResult.text = "（提供後に更新）"
	_refresh()


# ─── ボタンハンドラ ────────────────────────────────────────

func _on_select_base() -> void:
	_base_index = (_base_index + 1) % _bases.size()
	_refresh()


func _on_select_topping() -> void:
	_topping_index = (_topping_index + 1) % _toppings.size()
	_refresh()


func _on_select_yakumi() -> void:
	_yakumi_index = (_yakumi_index + 1) % _yakumis.size()
	_refresh()


func _on_switch_customer() -> void:
	_customer_index = (_customer_index + 1) % _customers.size()
	%LabelResult.text = "（提供後に更新）"
	_refresh()


func _on_setup() -> void:
	_setup_pot()


func _on_serve() -> void:
	if _pot == null or _pot.is_empty():
		return
	var topping: RecipeResource = _toppings[_topping_index]
	var yakumi: RecipeResource = _yakumis[_yakumi_index]
	var cup := _pot.serve(topping, yakumi)
	var result: Evaluator.Result = Evaluator.evaluate(cup, _customers[_customer_index])
	_show_result(cup, result)
	_refresh()


func _on_turn_end() -> void:
	if _pot == null:
		return
	_pot.on_turn_end()
	_refresh()


func _on_add_water() -> void:
	if _pot == null:
		return
	_pot.add_water()
	_refresh()


func _on_reset() -> void:
	_pot = Pot.new()
	%LabelResult.text = "（提供後に更新）"
	_refresh()


# ─── 表示更新 ─────────────────────────────────────────────

func _show_result(cup: SoupServing, result: Evaluator.Result) -> void:
	var grade_str: String = ["大満足", "美味しい", "普通", "不満"][int(result.grade)]
	var over_str: String  = "over" if result.over else "under"
	%LabelResult.text = "%s  |  payment=%d  rep_delta=%+d\nworst: %s(%s)  cup(koku=%d u=%d)" % [
		grade_str, result.payment, result.rep_delta,
		result.worst_axis, over_str,
		cup.attrs.koku, cup.attrs.umami,
	]


func _refresh() -> void:
	# 食材選択ボタンのテキスト更新
	var b: RecipeResource = _bases[_base_index]
	%BtnSelectBase.text = "ベース [▶]  %s  koku=%d u=%d" % [
		b.display_name, b.attrs.koku, b.attrs.umami]

	var t: RecipeResource = _toppings[_topping_index]
	if t == null:
		%BtnSelectTopping.text = "トッピング [▶]  なし"
	else:
		%BtnSelectTopping.text = "トッピング [▶]  %s  koku%+d u%+d" % [
			t.display_name, t.attrs.koku, t.attrs.umami]

	var y: RecipeResource = _yakumis[_yakumi_index]
	if y == null:
		%BtnSelectYakumi.text = "薬味 [▶]  なし"
	else:
		%BtnSelectYakumi.text = "薬味 [▶]  %s  koku%+d u%+d" % [
			y.display_name, y.attrs.koku, y.attrs.umami]

	if _pot == null:
		return

	# 鍋の状態
	%LabelVolume.text = "volume : %d" % _pot.volume
	%LabelKoku.text   = "koku   : %d" % _pot.attrs.koku
	%LabelUmami.text  = "umami  : %d" % _pot.attrs.umami

	if _pot.is_empty():
		%LabelStatus.text  = "★ 売り切れ ★"
		%BtnServe.disabled = true
	else:
		%LabelStatus.text  = ""
		%BtnServe.disabled = false

	# 客の情報
	var c := _customers[_customer_index]
	%LabelCustomerName.text = "%s  [%d/%d]" % [
		c.display_name, _customer_index + 1, _customers.size()
	]
	%LabelIdeal.text = "ideal: koku=%-2d  u=%-2d  s=%-2d  a=%-2d" % [
		c.ideal.koku, c.ideal.umami, c.ideal.stimulus, c.ideal.aroma,
	]
