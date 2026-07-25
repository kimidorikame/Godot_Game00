extends Control

var _pot: Pot = null


func _ready() -> void:
	$VBoxContainer/BtnSetup.pressed.connect(_on_setup)
	$VBoxContainer/BtnServe.pressed.connect(_on_serve)
	$VBoxContainer/BtnTurnEnd.pressed.connect(_on_turn_end)
	$VBoxContainer/BtnAddWater.pressed.connect(_on_add_water)
	$VBoxContainer/BtnReset.pressed.connect(_on_reset)
	_setup_pot()


# ベース固定（豚骨: rich=5, umami=3, 8杯）で仕込み直し
func _setup_pot() -> void:
	var base := RecipeResource.new()
	base.id = &"base_tonkotsu"
	base.kind = RecipeResource.Kind.BASE
	base.attrs = SoupAttrs.new()
	base.attrs.rich = 5
	base.attrs.umami = 3
	base.base_volume = 8
	_pot = Pot.new()
	_pot.setup(base, [])
	_refresh()


func _on_setup() -> void:
	_setup_pot()


func _on_serve() -> void:
	if _pot == null or _pot.is_empty():
		return
	_pot.serve(null, null)
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


# 空の鍋だけ作る（売り切れ状態のテスト用）
func _on_reset() -> void:
	_pot = Pot.new()
	_refresh()


func _refresh() -> void:
	if _pot == null:
		return
	%LabelVolume.text = "volume : %d" % _pot.volume
	%LabelRich.text   = "rich   : %d" % _pot.attrs.rich
	%LabelLight.text  = "light  : %d" % _pot.attrs.light
	%LabelUmami.text  = "umami  : %d" % _pot.attrs.umami

	if _pot.is_empty():
		%LabelStatus.text = "★ 売り切れ ★"
		%BtnServe.disabled = true
	else:
		%LabelStatus.text = ""
		%BtnServe.disabled = false
