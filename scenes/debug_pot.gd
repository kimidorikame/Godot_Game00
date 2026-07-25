extends Control

# ─── 食材データ（設計書 3.2 のプレースホルダ値）────────────
const BASE_DATA: Array = [
	{name = "豚骨", rich = 5, light = 0, umami = 3, volume = 8},
	{name = "精進", rich = 0, light = 5, umami = 2, volume = 8},
]
const TOPPING_DATA: Array = [
	{name = "なし",          rich = 0, light = 0, umami = 0},
	{name = "油条",          rich = 1, light = 0, umami = 0},
	{name = "厚揚げ",        rich = 1, light = 0, umami = 1},
	{name = "チャーシュー",  rich = 2, light = 0, umami = 1},
]
const YAKUMI_DATA: Array = [
	{name = "なし",     rich =  0, light = 0, umami = 0},
	{name = "生姜",     rich =  0, light = 1, umami = 1},
	{name = "ニンニク", rich =  1, light = 0, umami = 2},
	{name = "黒酢",     rich = -1, light = 1, umami = 0},
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
	var roujin := CustomerResource.new()
	roujin.display_name    = "老人"
	roujin.ideal           = _attrs(1, 5, 2)
	roujin.great_threshold = 2
	roujin.ok_threshold    = 5
	roujin.base_price      = 300
	roujin.tip             = 100

	var haitatsuin := CustomerResource.new()
	haitatsuin.display_name    = "配達員"
	haitatsuin.ideal           = _attrs(6, 0, 4)
	haitatsuin.great_threshold = 2
	haitatsuin.ok_threshold    = 5
	haitatsuin.base_price      = 250
	haitatsuin.tip             = 80

	var keiji := CustomerResource.new()
	keiji.display_name    = "刑事（元料理人）"
	keiji.ideal           = _attrs(3, 3, 5)
	keiji.great_threshold = 2
	keiji.ok_threshold    = 4
	keiji.base_price      = 400
	keiji.tip             = 150
	keiji.is_pro_critic   = true

	_customers = [roujin, haitatsuin, keiji]


func _setup_pot() -> void:
	var b: Dictionary = BASE_DATA[_base_index]
	print("[_setup_pot] _base_index=%d  name=%s  r=%d l=%d u=%d" % [
		_base_index, b.name, b.rich, b.light, b.umami])

	# RecipeResource.attrs 代入を経由せず直接 Pot に設定
	_pot = Pot.new()
	_pot.attrs  = _attrs(b.rich, b.light, b.umami)
	_pot.volume = b.volume

	print("[_setup_pot] pot.attrs after setup: r=%d l=%d u=%d  vol=%d" % [
		_pot.attrs.rich, _pot.attrs.light, _pot.attrs.umami, _pot.volume])
	%LabelResult.text = "（提供後に更新）"
	_refresh()


func _attrs(rich: int, light: int, umami: int) -> SoupAttrs:
	var a := SoupAttrs.new()
	a.rich  = rich
	a.light = light
	a.umami = umami
	return a


func _make_recipe(kind: RecipeResource.Kind, data: Dictionary) -> RecipeResource:
	var r := RecipeResource.new()
	r.kind  = kind
	r.attrs = _attrs(data.rich, data.light, data.umami)
	return r


# ─── ボタンハンドラ ────────────────────────────────────────

func _on_select_base() -> void:
	_base_index = (_base_index + 1) % BASE_DATA.size()
	_refresh()


func _on_select_topping() -> void:
	_topping_index = (_topping_index + 1) % TOPPING_DATA.size()
	_refresh()


func _on_select_yakumi() -> void:
	_yakumi_index = (_yakumi_index + 1) % YAKUMI_DATA.size()
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
	var topping: RecipeResource = null
	if _topping_index > 0:
		topping = _make_recipe(RecipeResource.Kind.TOPPING, TOPPING_DATA[_topping_index])
	var yakumi: RecipeResource = null
	if _yakumi_index > 0:
		yakumi = _make_recipe(RecipeResource.Kind.YAKUMI, YAKUMI_DATA[_yakumi_index])
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
	var grade_str: String = ["大満足", "普通", "不満"][int(result.grade)]
	var over_str: String  = "over" if result.over else "under"
	%LabelResult.text = "%s  |  payment=%d  rep_delta=%+d\nworst: %s(%s)  cup(r=%d l=%d u=%d)" % [
		grade_str, result.payment, result.rep_delta,
		result.worst_axis, over_str,
		cup.attrs.rich, cup.attrs.light, cup.attrs.umami,
	]


func _refresh() -> void:
	# 食材選択ボタンのテキスト更新
	var b: Dictionary = BASE_DATA[_base_index]
	%BtnSelectBase.text = "ベース [▶]  %s  r=%d l=%d u=%d" % [b.name, b.rich, b.light, b.umami]

	var t: Dictionary = TOPPING_DATA[_topping_index]
	%BtnSelectTopping.text = "トッピング [▶]  %s" % t.name \
		+ ("" if _topping_index == 0 else "  r%+d l%+d u%+d" % [t.rich, t.light, t.umami])

	var y: Dictionary = YAKUMI_DATA[_yakumi_index]
	%BtnSelectYakumi.text = "薬味 [▶]  %s" % y.name \
		+ ("" if _yakumi_index == 0 else "  r%+d l%+d u%+d" % [y.rich, y.light, y.umami])

	if _pot == null:
		print("[_refresh] _pot is NULL, early return")
		return

	# 鍋の状態
	print("[_refresh] writing labels: r=%d l=%d u=%d vol=%d" % [
		_pot.attrs.rich, _pot.attrs.light, _pot.attrs.umami, _pot.volume])
	%LabelVolume.text = "volume : %d" % _pot.volume
	%LabelRich.text   = "rich   : %d" % _pot.attrs.rich
	%LabelLight.text  = "light  : %d" % _pot.attrs.light
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
	%LabelIdeal.text = "ideal: r=%-2d  l=%-2d  u=%-2d  |  great≤%d  ok≤%d" % [
		c.ideal.rich, c.ideal.light, c.ideal.umami,
		c.great_threshold, c.ok_threshold,
	]
