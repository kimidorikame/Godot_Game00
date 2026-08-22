extends Node


func _ready() -> void:
	print("=== Pot テスト開始 ===")
	_run()
	_run_kurozu_and_water_checks()
	get_tree().quit()


func _run() -> void:
	# ベーススープ（豚骨: koku=40, umami=3, 8杯）
	var base := RecipeResource.new()
	base.id = &"base_tonkotsu"
	base.kind = RecipeResource.Kind.BASE
	base.attrs = SoupAttrs.new()
	base.attrs.koku = 40
	base.attrs.umami = 3
	base.base_volume = 8

	# 鍋食材（椎茸: umami+2）
	var shiitake := RecipeResource.new()
	shiitake.kind = RecipeResource.Kind.POT_INGREDIENT
	shiitake.attrs = SoupAttrs.new()
	shiitake.attrs.umami = 2

	# トッピング（揚げパン: koku+5）
	var youtiao := RecipeResource.new()
	youtiao.kind = RecipeResource.Kind.TOPPING
	youtiao.attrs = SoupAttrs.new()
	youtiao.attrs.koku = 5

	# 薬味（黒酢: 実データ（yak_kurozu.tres）を読み込む。サブステップ3-3で
	# koku=-4, stimulus=-4 の引き算食材として機能するようになった）
	var kurozu: RecipeResource = load("res://data/recipes/yakumi/yak_kurozu.tres")

	var pot := Pot.new()

	print("--- setup(豚骨, [椎茸]) ---")
	pot.setup(base, [shiitake])
	_print_pot(pot)

	print("--- serve(揚げパン, null) ---")
	var cup1 := pot.serve(youtiao, null)
	_print_pot(pot)
	_print_cup("cup1", cup1)

	print("--- serve(null, 黒酢) ---")
	var cup2 := pot.serve(null, kurozu)
	_print_pot(pot)
	_print_cup("cup2", cup2)
	# 鍋(koku=40, stimulus=0) + 黒酢(koku=-4, stimulus=-4)
	# → koku=36（下限に達せず素直に減算）、stimulus=-4→クランプで0
	_check("cup2 koku (40-4)", cup2.attrs.koku, 36)
	_check("cup2 stimulus (0-4→clamp)", cup2.attrs.stimulus, 0)

	print("--- on_turn_end / 煮詰まり ---")
	pot.on_turn_end()
	_print_pot(pot)

	print("--- add_water ---")
	pot.add_water()
	_print_pot(pot)

	print("--- serve(null, null) ---")
	var cup3 := pot.serve(null, null)
	_print_pot(pot)
	_print_cup("cup3", cup3)

	print("=== テスト完了 ===")


# サブステップ3-3: 引き算食材メカニクス（黒酢の刺激↓・コク↓）の検証。
# (a) 黒酢投入でkoku/stimulusが下がる
# (b) 引きすぎても負にならず0で下げ止まる
# (c) add_water() のクランプ一本化後も既存挙動（0で下げ止まる／下げ止まらない場合は
#     素直に減算される）が保たれる
func _run_kurozu_and_water_checks() -> void:
	print("\n=== サブステップ3-3 検証（黒酢の引き算・クランプ）===")

	var kurozu: RecipeResource = load("res://data/recipes/yakumi/yak_kurozu.tres")
	_check("黒酢データ koku", kurozu.attrs.koku, -4)
	_check("黒酢データ stimulus", kurozu.attrs.stimulus, -4)

	# --- (a) 黒酢投入でkoku/stimulusが下がる（serve()経由、下限に届かない量）---
	print("\n--- (a) 黒酢投入で下がる: koku=8,stimulus=4 に黒酢(koku=-4,stimulus=-4) ---")
	var base_a := RecipeResource.new()
	base_a.kind = RecipeResource.Kind.BASE
	base_a.attrs = SoupAttrs.new()
	base_a.attrs.koku = 8
	base_a.attrs.stimulus = 4
	base_a.base_volume = 1
	var pot_a := Pot.new()
	pot_a.setup(base_a, [])
	var cup_a := pot_a.serve(null, kurozu)
	_print_cup("cup_a", cup_a)
	_check("(a) koku (8-4)", cup_a.attrs.koku, 4)
	_check("(a) stimulus (4-4)", cup_a.attrs.stimulus, 0)

	# --- (b) 引きすぎても負にならず0で下げ止まる（serve()経由）---
	print("\n--- (b) 下げ止まり: koku=2,stimulus=1 に黒酢(koku=-4,stimulus=-4) ---")
	var base_b := RecipeResource.new()
	base_b.kind = RecipeResource.Kind.BASE
	base_b.attrs = SoupAttrs.new()
	base_b.attrs.koku = 2
	base_b.attrs.stimulus = 1
	base_b.base_volume = 1
	var pot_b := Pot.new()
	pot_b.setup(base_b, [])
	var cup_b := pot_b.serve(null, kurozu)
	_print_cup("cup_b", cup_b)
	_check("(b) koku (2-4→clamp 0)", cup_b.attrs.koku, 0)
	_check("(b) stimulus (1-4→clamp 0)", cup_b.attrs.stimulus, 0)

	# --- (c) add_water() のクランプ一本化後も既存挙動が保たれる ---
	print("\n--- (c) add_water クランプ一本化: 下げ止まらないケース ---")
	var base_c1 := RecipeResource.new()
	base_c1.kind = RecipeResource.Kind.BASE
	base_c1.attrs = SoupAttrs.new()
	base_c1.attrs.koku = 20
	base_c1.attrs.umami = 5
	base_c1.base_volume = 1
	var pot_c1 := Pot.new()
	pot_c1.setup(base_c1, [])
	pot_c1.add_water()  # WATER_KOKU=-8, WATER_UMAMI=-1（下限に届かない）
	_print_pot(pot_c1)
	_check("(c-1) koku (20-8)", pot_c1.attrs.koku, 12)
	_check("(c-1) umami (5-1)", pot_c1.attrs.umami, 4)

	print("\n--- (c) add_water クランプ一本化: 1回で下げ止まるケース ---")
	var base_c2 := RecipeResource.new()
	base_c2.kind = RecipeResource.Kind.BASE
	base_c2.attrs = SoupAttrs.new()
	base_c2.attrs.koku = 2
	base_c2.attrs.umami = 0
	base_c2.base_volume = 1
	var pot_c2 := Pot.new()
	pot_c2.setup(base_c2, [])
	pot_c2.add_water()  # koku: 2-8→clamp 0 / umami: 0-1→clamp 0
	_print_pot(pot_c2)
	_check("(c-2) koku (2-8→clamp 0)", pot_c2.attrs.koku, 0)
	_check("(c-2) umami (0-1→clamp 0)", pot_c2.attrs.umami, 0)

	print("\n--- (c) add_water クランプ一本化: 複数回(times=3)で下げ止まるケース ---")
	var base_c3 := RecipeResource.new()
	base_c3.kind = RecipeResource.Kind.BASE
	base_c3.attrs = SoupAttrs.new()
	base_c3.attrs.koku = 10
	base_c3.attrs.umami = 0
	base_c3.base_volume = 1
	var pot_c3 := Pot.new()
	pot_c3.setup(base_c3, [])
	pot_c3.add_water(3)
	# iter1: 10-8=2 / iter2: 2-8=-6→clamp 0 / iter3: 0-8=-8→clamp 0
	_print_pot(pot_c3)
	_check("(c-3) koku times=3 (下げ止まり)", pot_c3.attrs.koku, 0)

	print("\n=== サブステップ3-3 検証完了 ===")


func _print_pot(pot: Pot) -> void:
	print("  鍋  volume=%-2d  koku=%-2d  umami=%-2d  stimulus=%-2d  aroma=%d" % [
		pot.volume, pot.attrs.koku, pot.attrs.umami, pot.attrs.stimulus, pot.attrs.aroma
	])


func _print_cup(label: String, cup: SoupServing) -> void:
	print("  %-4s koku=%-2d  umami=%-2d  stimulus=%-2d  aroma=%d" % [
		label, cup.attrs.koku, cup.attrs.umami, cup.attrs.stimulus, cup.attrs.aroma
	])


# 期待値と実測値を比較し、OK/NG をログに出す簡易アサーション。
func _check(label: String, actual: int, expected: int) -> void:
	var status := "OK" if actual == expected else "NG"
	print("  [%s] %s : actual=%d expected=%d" % [status, label, actual, expected])
