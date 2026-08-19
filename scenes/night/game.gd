# game.gd
# 夜営業シーン（M2 縦切り）。
#
# 客3人分の「仕込み → 会話（Dialogic） → サーブ → 評価 → 会計」×3 → 営業終了を
# core/ と resources/.tres のデータに接続して通しで確認できるようにする。
# 会話は Dialogic タイムライン再生。今日はダミー会話1本を客に関わらず固定で再生する。

class_name NightScene
extends Node2D

enum Stage { PREP, CONVERSATION, SERVING, RESULT }

# 同席抽選やデータが無い場合に再生する最終フォールバックのデフォルト会話。
# 将来ちゃんとした会話が揃ったら再検討。
const CONVERSATION_TIMELINE_ID := "d1_roujin"

# ─── 食材データ（data/recipes/ の .tres を参照）────────────
# ベースは市場（Shop）で購入した在庫分だけが仕込みに使える。
var _base_catalog: Array[RecipeResource] = [
	preload("res://data/recipes/base/base_tonkotsu.tres"),
	preload("res://data/recipes/base/base_shojin.tres"),
	# base_kuzu は困窮脱出動線・段階3のクズ食材。市場「裏手」で0円入手した時のみ
	# inventory に入るので、通常日は下の inventory フィルタで自然に選択肢から外れる。
	preload("res://data/recipes/base/base_kuzu.tres"),
]
# 残り湯（持ち越し希釈）を選んだ目印。_bases に混ぜて通常ベースと同じ選択UIで扱う。
const ZANRYU_CARRYOVER_ID := &"zanryu_carryover"
# 残り湯作成時に足す水の回数（Pot.add_water(times)へ渡す）。客3人前提の仮値、要調整。
const ZANRYU_WATER_TIMES := 2
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

# ─── 同席者モデル（第2階層抽選）───────────────────────────
# その日のスケジュール(.tres)が持つ同席定義。未定義の日はis_empty()のまま
# （companion_scenesが空 → 常に同席なしフォールバック）。
var _companion_scenes: Array[CompanionScene] = []
# 現在のメイン場面の抽選結果。同席なしのときは_current_companionsが空配列。
var _current_timeline_id: StringName = &""
var _current_companions: Array[StringName] = []

var _pot: Pot = null
var _base_index: int = 0
var _topping_index: int = 0
var _yakumi_index: int = 0
var _stage: Stage = Stage.PREP


func _ready() -> void:
	_customers = _load_customers_for_today()

	_bases = _base_catalog.filter(func(b: RecipeResource) -> bool:
		return GameState.inventory.get(b.id, 0) > 0)

	if GameState.pot_carryover_volume > 0:
		_bases.append(_build_zanryu_option())

	if _bases.is_empty():
		# 在庫も持ち越しの残り湯も無い日。困窮からの最終脱出手段（クズ食材、段階3）は
		# 未実装のため、現状は開店できず休業する暫定挙動（クズ食材実装時に置き換える）。
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


# 前日の持ち越し（GameState.pot_carryover_*）から残り湯の選択肢を組み立てる。
# 通常ベースと同じ _bases 配列に混ぜることで、既存の選択UI（%BtnSelectBase）を
# そのまま流用する。attrs/base_volume に持ち越しの値をそのまま入れ、
# 実際の希釈（add_water）は選ばれて _on_setup() が呼ばれた時点で行う。
func _build_zanryu_option() -> RecipeResource:
	var recipe := RecipeResource.new()
	recipe.id = ZANRYU_CARRYOVER_ID
	recipe.display_name = "残り湯（持ち越し）"
	recipe.kind = RecipeResource.Kind.BASE
	recipe.attrs = SoupAttrs.new()
	recipe.attrs.koku = GameState.pot_carryover_koku
	recipe.attrs.umami = GameState.pot_carryover_umami
	recipe.base_volume = GameState.pot_carryover_volume
	recipe.price = 0
	return recipe


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

	_companion_scenes = (schedule as DayScheduleResource).companion_scenes
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


# ─── 同席者モデル（第2階層抽選）───────────────────────────
# 設計メモ docs/conversation_design.md「抽選の二層構造」に対応。
# 第1階層（母集団選出）は日データ側で確定済み（companions_pool等）。ここは第2階層、
# メイン場面ごとに「誰が同席するか」を都度抽選する部分のみを扱う。

# main_idに対応するCompanionSceneを_companion_scenesから探す。無ければnull
# （companion_scenes未定義の日・そのメインの同席定義が無い場合はここでnullになる）。
func _find_companion_scene(main_id: StringName) -> CompanionScene:
	for scene: CompanionScene in _companion_scenes:
		if scene.main == main_id:
			return scene
	return null


# requiredの全フラグがGameState.story_flagsに立っているか（AND条件）。
# requiredが空の場合は「特別パターンではない」の意味であり、ここでは呼ばれない想定。
func _flags_satisfied(required: Array[StringName]) -> bool:
	for flag: StringName in required:
		if not GameState.story_flags.get(flag, false):
			return false
	return true


# sceneのpatternsから1つを選ぶ。特別パターン（required_flags非空）が条件を満たせば
# 記述順で最初の1つを優先確定（先勝ち、重み抽選はスキップ）。無ければrequired_flagsが
# 空の通常パターンだけを対象に重み抽選する。抽選対象が無い（patternsが空、通常パターンが
# 無い、通常パターンの合計weightが0以下）場合はnull（呼び出し側で同席なしにフォールバック）。
func _select_companion_pattern(scene: CompanionScene) -> CompanionPattern:
	if scene == null or scene.patterns.is_empty():
		return null

	for pattern: CompanionPattern in scene.patterns:
		if not pattern.required_flags.is_empty() and _flags_satisfied(pattern.required_flags):
			return pattern

	var normal_patterns: Array[CompanionPattern] = []
	var total_weight: int = 0
	for pattern: CompanionPattern in scene.patterns:
		if pattern.required_flags.is_empty():
			normal_patterns.append(pattern)
			total_weight += pattern.weight
	if normal_patterns.is_empty() or total_weight <= 0:
		return null

	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for pattern: CompanionPattern in normal_patterns:
		cumulative += pattern.weight
		if roll < cumulative:
			return pattern
	return null  # 理論上到達しない（防御的フォールバック）


# 現在のメイン客（_customers[_customer_index]）について同席パターンを抽選し、
# _current_companions / _current_timeline_id に反映する。
# このステップではDialogic.start呼び出しは従来通り固定のまま変えない
# （_current_timeline_idはまだ会話再生に使わず、ログ確認のみに使う）。
func _select_companions_for_current_main() -> void:
	var main_id: StringName = _customers[_customer_index].id
	var scene: CompanionScene = _find_companion_scene(main_id)
	var pattern: CompanionPattern = _select_companion_pattern(scene)

	if pattern != null:
		_current_companions = pattern.companions
		_current_timeline_id = (pattern.timeline_ids.pick_random()
			if not pattern.timeline_ids.is_empty() else CONVERSATION_TIMELINE_ID)
	else:
		_current_companions = []
		_current_timeline_id = CONVERSATION_TIMELINE_ID


# ─── ステージ遷移 ───────────────────────────────────────

func _enter_stage(stage: Stage) -> void:
	_stage = stage
	%PrepPanel.visible = stage == Stage.PREP
	%ConversationPanel.visible = stage == Stage.CONVERSATION
	%ServingPanel.visible = stage == Stage.SERVING
	%ResultPanel.visible = stage == Stage.RESULT
	if stage == Stage.CONVERSATION:
		_select_companions_for_current_main()
		var timeline_id: StringName = (_current_timeline_id
			if _current_timeline_id != &"" else CONVERSATION_TIMELINE_ID)
		Dialogic.start(timeline_id)
	_refresh()


# ─── ボタンハンドラ ────────────────────────────────────────

func _on_select_base() -> void:
	_base_index = (_base_index + 1) % _bases.size()
	_refresh()


func _on_setup() -> void:
	var base: RecipeResource = _bases[_base_index]
	_is_zanryu = base.id == ZANRYU_CARRYOVER_ID
	if not _is_zanryu:
		GameState.inventory[base.id] -= 1
	_pot = Pot.new()
	_pot.setup(base, [])
	if _is_zanryu:
		_pot.add_water(ZANRYU_WATER_TIMES)
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
		GameState.pot_carryover_koku = 0
		GameState.pot_carryover_umami = 0
		return
	GameState.pot_carryover_volume = _pot.volume
	GameState.pot_carryover_koku = _pot.attrs.koku
	GameState.pot_carryover_umami = _pot.attrs.umami


# ─── 表示更新 ─────────────────────────────────────────────

func _show_result(cup: SoupServing, result: Evaluator.Result) -> void:
	var grade_str: String = ["大満足", "普通", "不満"][int(result.grade)]
	var over_str: String = "over" if result.over else "under"
	%LabelResult.text = "%s  |  payment=%d  rep_delta=%+d\nworst: %s(%s)  cup(koku=%d u=%d)" % [
		grade_str, result.payment, result.rep_delta,
		result.worst_axis, over_str,
		cup.attrs.koku, cup.attrs.umami,
	]


func _refresh() -> void:
	%LabelMoney.text = "所持金 : %d円" % GameState.money

	var b: RecipeResource = _bases[_base_index]
	%BtnSelectBase.text = "ベース [▶]  %s  koku=%d u=%d" % [
		b.display_name, b.attrs.koku, b.attrs.umami]

	var c: CustomerResource = _customers[_customer_index]
	%LabelCustomerName.text = "%s  [%d/%d]" % [c.display_name, _customer_index + 1, _customers.size()]

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

	if _pot != null:
		%LabelPotStatus.text = "volume:%d koku:%d umami:%d" % [
			_pot.volume, _pot.attrs.koku, _pot.attrs.umami]

	if _customer_index + 1 < _customers.size():
		%BtnResultNext.text = "[次の客へ →]"
	else:
		%BtnResultNext.text = "[営業終了（仮）]"
