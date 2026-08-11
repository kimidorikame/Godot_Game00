# game.gd
# 夜営業シーン（M2 縦切り）。
#
# 客3人分の「仕込み → 会話（Dialogic） → サーブ → 評価 → 会計」×3 → 営業終了を
# core/ と resources/.tres のデータに接続して通しで確認できるようにする。
# 会話は Dialogic タイムライン再生。今日はダミー会話1本を客に関わらず固定で再生する。

class_name NightScene
extends Node2D

enum Stage { PREP, CONVERSATION, SERVING, RESULT }

# 客ごと・日ごとのタイムライン切り替えは未実装。今日は老人のダミー会話1本を固定で再生する。
const CONVERSATION_TIMELINE_ID := "d1_roujin"

# ─── 食材データ（data/recipes/ の .tres を参照）────────────
# ベースは市場（Shop）で購入した在庫分だけが仕込みに使える。
var _base_catalog: Array[RecipeResource] = [
	preload("res://data/recipes/base/base_tonkotsu.tres"),
	preload("res://data/recipes/base/base_shojin.tres"),
]
const ZANRYU_BASE: RecipeResource = preload("res://data/recipes/base/base_zanryu.tres")
var _bases: Array[RecipeResource] = []
var _is_zanryu: bool = false
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

# ─── 客データ（GameState.day に応じて data/schedule/ から解決）──────
# スケジュール(.tres)のvisitorsが参照するidをCustomerResourceに解決するためのカタログ。
var _customer_catalog: Dictionary = {
	&"roujin": preload("res://data/customers/roujin.tres"),
	&"haitatsuin": preload("res://data/customers/haitatsuin.tres"),
	&"keiji": preload("res://data/customers/keiji.tres"),
}
# スケジュール読み込みに失敗した場合の最終フォールバック（本来は起こらないはずの異常系）。
const _FALLBACK_VISITOR_IDS: Array[StringName] = [&"roujin", &"haitatsuin", &"keiji"]

var _customers: Array[CustomerResource] = []
var _customer_index: int = 0

var _pot: Pot = null
var _base_index: int = 0
var _topping_index: int = 0
var _yakumi_index: int = 0
var _stage: Stage = Stage.PREP


func _ready() -> void:
	_customers = _load_customers_for_today()

	_bases = _base_catalog.filter(func(b: RecipeResource) -> bool:
		return GameState.inventory.get(b.id, 0) > 0)

	if _bases.is_empty():
		if _zanryu_available():
			_bases = [ZANRYU_BASE]
			_is_zanryu = true
		else:
			# NightSceneは1日1回しか生成されないため、現状のフローでは
			# _zanryu_available() が false になる経路はまだ存在しない
			# （M4で同日再訪の仕組みができたときのための骨組み）。
			end_day()
			return

	%BtnSelectBase.pressed.connect(_on_select_base)
	%BtnSetup.pressed.connect(_on_setup)
	Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)
	%BtnSelectTopping.pressed.connect(_on_select_topping)
	%BtnSelectYakumi.pressed.connect(_on_select_yakumi)
	%BtnServe.pressed.connect(_on_serve)
	%BtnResultNext.pressed.connect(_on_result_next)
	_enter_stage(Stage.PREP)


# 残り湯フォールバックが使えるか。「その日限り」の措置なので永続の残量は持たず、
# 常にtrueを返す。同日中に複数回呼ばれる経路が生まれたらここを実装する（M4想定）。
func _zanryu_available() -> bool:
	return true


# GameState.day のスケジュール(.tres)からその日の客リストを解決する。
# スケジュール欠落は7日分揃っていれば本来起こらない開発中の不具合（配置ミス・typo）なので
# assertで即気づけるようにしつつ、本番実行がクラッシュしないよう固定3人にフォールバックする。
func _load_customers_for_today() -> Array[CustomerResource]:
	var path := "res://data/schedule/day%d.tres" % GameState.day
	var schedule: Resource = load(path)
	assert(schedule is DayScheduleResource, "スケジュールが読み込めません: %s" % path)

	if not (schedule is DayScheduleResource):
		push_error("スケジュールが読み込めないため固定客リストにフォールバックします: %s" % path)
		return _resolve_customers(_FALLBACK_VISITOR_IDS)

	return _resolve_customers((schedule as DayScheduleResource).visitors)


# 客id(StringName)の配列をカタログでCustomerResourceに解決する。
# カタログ未登録のidは開発中の不具合（客データのtypo等）なのでassert、
# 本番実行時はその客だけ無視して続行する。
func _resolve_customers(visitor_ids: Array[StringName]) -> Array[CustomerResource]:
	var result: Array[CustomerResource] = []
	for id: StringName in visitor_ids:
		var customer: CustomerResource = _customer_catalog.get(id)
		assert(customer != null, "客カタログに未登録のid: %s" % id)
		if customer == null:
			push_error("客カタログに未登録のidのため無視します: %s" % id)
			continue
		result.append(customer)
	return result


# ─── ステージ遷移 ───────────────────────────────────────

func _enter_stage(stage: Stage) -> void:
	_stage = stage
	%PrepPanel.visible = stage == Stage.PREP
	%ConversationPanel.visible = stage == Stage.CONVERSATION
	%ServingPanel.visible = stage == Stage.SERVING
	%ResultPanel.visible = stage == Stage.RESULT
	if stage == Stage.CONVERSATION:
		Dialogic.start(CONVERSATION_TIMELINE_ID)
	_refresh()


# ─── ボタンハンドラ ────────────────────────────────────────

func _on_select_base() -> void:
	_base_index = (_base_index + 1) % _bases.size()
	_refresh()


func _on_setup() -> void:
	var base: RecipeResource = _bases[_base_index]
	if not _is_zanryu:
		GameState.inventory[base.id] -= 1
	_pot = Pot.new()
	_pot.setup(base, [])
	_enter_stage(Stage.CONVERSATION)


func _on_dialogic_timeline_ended() -> void:
	if _stage == Stage.CONVERSATION:
		_enter_stage(Stage.SERVING)


func _on_select_topping() -> void:
	_topping_index = (_topping_index + 1) % _toppings.size()
	_refresh()


func _on_select_yakumi() -> void:
	_yakumi_index = (_yakumi_index + 1) % _yakumis.size()
	_refresh()


func _on_serve() -> void:
	if _pot == null or _pot.is_empty():
		return
	var topping: RecipeResource = _toppings[_topping_index]
	var yakumi: RecipeResource = _yakumis[_yakumi_index]
	var cup := _pot.serve(topping, yakumi)
	var result: Evaluator.Result = Evaluator.evaluate(cup, _customers[_customer_index])
	GameState.money += result.payment
	GameState.reputation += result.rep_delta
	_show_result(cup, result)
	_enter_stage(Stage.RESULT)


# 評価結果画面のボタン。次の客がいればサーブへ戻り、最後の客ならその日の営業を終える。
func _on_result_next() -> void:
	if _customer_index + 1 < _customers.size():
		_pot.on_turn_end()
		_customer_index += 1
		_topping_index = 0
		_yakumi_index = 0
		_enter_stage(Stage.CONVERSATION)
	else:
		end_day()


# 1日の営業終了時に呼ぶ
func end_day() -> void:
	_snapshot_pot_to_gamestate()
	get_tree().change_scene_to_file("res://scenes/home/Result.tscn")


# 営業終了時点の鍋の状態を、加工せずそのままGameStateへスナップショットする
# （困窮脱出動線の土台。翌日以降の持ち越し判定・希釈計算はここでは行わない）。
# _pot が null（営業が一度も始まらなかった日）の場合は明示的に0を書く。
# 書かずに放置すると、前日以前の古いスナップショットがGameStateに残留してしまうため。
func _snapshot_pot_to_gamestate() -> void:
	if _pot == null:
		GameState.pot_carryover_volume = 0
		GameState.pot_carryover_rich = 0
		GameState.pot_carryover_light = 0
		GameState.pot_carryover_umami = 0
		return
	GameState.pot_carryover_volume = _pot.volume
	GameState.pot_carryover_rich = _pot.attrs.rich
	GameState.pot_carryover_light = _pot.attrs.light
	GameState.pot_carryover_umami = _pot.attrs.umami


# ─── 表示更新 ─────────────────────────────────────────────

func _show_result(cup: SoupServing, result: Evaluator.Result) -> void:
	var grade_str: String = ["大満足", "普通", "不満"][int(result.grade)]
	var over_str: String = "over" if result.over else "under"
	%LabelResult.text = "%s  |  payment=%d  rep_delta=%+d\nworst: %s(%s)  cup(r=%d l=%d u=%d)" % [
		grade_str, result.payment, result.rep_delta,
		result.worst_axis, over_str,
		cup.attrs.rich, cup.attrs.light, cup.attrs.umami,
	]


func _refresh() -> void:
	%LabelMoney.text = "所持金 : %d円" % GameState.money

	var b: RecipeResource = _bases[_base_index]
	%BtnSelectBase.text = "ベース [▶]  %s  r=%d l=%d u=%d" % [
		b.display_name, b.attrs.rich, b.attrs.light, b.attrs.umami]

	var c: CustomerResource = _customers[_customer_index]
	%LabelCustomerName.text = "%s  [%d/%d]" % [c.display_name, _customer_index + 1, _customers.size()]

	var t: RecipeResource = _toppings[_topping_index]
	if t == null:
		%BtnSelectTopping.text = "トッピング [▶]  なし"
	else:
		%BtnSelectTopping.text = "トッピング [▶]  %s  r%+d l%+d u%+d" % [
			t.display_name, t.attrs.rich, t.attrs.light, t.attrs.umami]

	var y: RecipeResource = _yakumis[_yakumi_index]
	if y == null:
		%BtnSelectYakumi.text = "薬味 [▶]  なし"
	else:
		%BtnSelectYakumi.text = "薬味 [▶]  %s  r%+d l%+d u%+d" % [
			y.display_name, y.attrs.rich, y.attrs.light, y.attrs.umami]

	if _pot != null:
		%LabelPotStatus.text = "volume:%d rich:%d light:%d umami:%d" % [
			_pot.volume, _pot.attrs.rich, _pot.attrs.light, _pot.attrs.umami]

	if _customer_index + 1 < _customers.size():
		%BtnResultNext.text = "[次の客へ →]"
	else:
		%BtnResultNext.text = "[営業終了（仮）]"
