extends Node


func _ready() -> void:
	print("=== Pot テスト開始 ===")
	_run()
	get_tree().quit()


func _run() -> void:
	# ベーススープ（豚骨: rich=5, umami=3, 8杯）
	var base := RecipeResource.new()
	base.id = &"base_tonkotsu"
	base.kind = RecipeResource.Kind.BASE
	base.attrs = SoupAttrs.new()
	base.attrs.rich = 5
	base.attrs.umami = 3
	base.base_volume = 8

	# 鍋食材（椎茸: umami+2）
	var shiitake := RecipeResource.new()
	shiitake.kind = RecipeResource.Kind.POT_INGREDIENT
	shiitake.attrs = SoupAttrs.new()
	shiitake.attrs.umami = 2

	# トッピング（揚げパン: rich+1）
	var youtiao := RecipeResource.new()
	youtiao.kind = RecipeResource.Kind.TOPPING
	youtiao.attrs = SoupAttrs.new()
	youtiao.attrs.rich = 1

	# 薬味（黒酢: rich-1, light+1）
	var kurozu := RecipeResource.new()
	kurozu.kind = RecipeResource.Kind.YAKUMI
	kurozu.attrs = SoupAttrs.new()
	kurozu.attrs.rich = -1
	kurozu.attrs.light = 1

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


func _print_pot(pot: Pot) -> void:
	print("  鍋  volume=%-2d  rich=%-2d  light=%-2d  umami=%d" % [
		pot.volume, pot.attrs.rich, pot.attrs.light, pot.attrs.umami
	])


func _print_cup(label: String, cup: SoupServing) -> void:
	print("  %-4s rich=%-2d  light=%-2d  umami=%d" % [
		label, cup.attrs.rich, cup.attrs.light, cup.attrs.umami
	])
