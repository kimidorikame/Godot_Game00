# pot.gd
# 設計書 4.1「鍋（Pot）」に対応。
#
# 屋台の鍋そのものを表すロジッククラス。
# 仕込み（setup）→ 営業中のサーブ（serve）→ ターン経過（on_turn_end）→
# 水差し（add_water）という一晩の流れを管理する。
# UI もシーンも持たない純粋なロジッククラスで、テストと差し替えが簡単。
#
# RefCounted を継承しているのはシーンツリーへの登録が不要なため。

class_name Pot
extends RefCounted

# ターン経過ごとに koku が増える量（煮詰まりシミュレーション）。
const KONIZUMARI_PER_TURN := 4

# 水を差したときに増えるカップ数。
const WATER_VOLUME := 2

# 水を差したときの koku の補正値（薄まるので減る）。
const WATER_KOKU := -8

# 水を差したときの umami の補正値（薄まるので減る）。
const WATER_UMAMI := -1

# 残りのサーブ可能カップ数。0 になると売り切れ（is_empty() が true）。
var volume: int = 0

# 現在の鍋のスープ属性。on_turn_end や add_water で動的に変化する。
var attrs: SoupAttrs = SoupAttrs.new()


# 仕込み。ベースレシピと追加の鍋素材を受け取り、鍋の初期状態を作る。
# 昼パート（仕込み画面）で素材を選んだ後、夜営業の開始前に呼ぶ。
func setup(base: RecipeResource, pot_ingredients: Array[RecipeResource]) -> void:
	attrs = base.attrs.duplicate_attrs()
	for ing in pot_ingredients:
		attrs.add(ing.attrs)
	volume = base.base_volume


# 一杯サーブ。トッピングと薬味を受け取り、カップ（SoupServing）を返す。
# volume を 1 消費するので、事前に is_empty() で残量を確認してから呼ぶこと。
# topping / yakumi は「なし」の場合 null を渡す。
func serve(topping: RecipeResource, yakumi: RecipeResource) -> SoupServing:
	assert(volume > 0)
	volume -= 1
	var cup := SoupServing.new()
	cup.attrs = attrs.duplicate_attrs()
	if topping:
		cup.attrs.add(topping.attrs)
	if yakumi:
		cup.attrs.add(yakumi.attrs)
	cup.topping = topping
	cup.yakumi = yakumi
	return cup


# ターン経過処理。客が帰るなどゲーム内の「1ターン」が進むたびに呼ぶ。
# 煮詰まりにより koku が KONIZUMARI_PER_TURN だけ上昇する。
func on_turn_end() -> void:
	attrs.koku += KONIZUMARI_PER_TURN


# 水を差す。volume を増やし、koku と umami を薄める（下限 0）。
# volume が少なくなってきたとき、または濃くなりすぎたときに使う手段。
# times は適用回数（1回分の効果を times 回重ねる）。残り湯作成など、
# 通常の水差しより大量に薄める場合に times を増やして呼ぶ。
func add_water(times: int = 1) -> void:
	for i in times:
		volume += WATER_VOLUME
		attrs.koku = maxi(attrs.koku + WATER_KOKU, 0)
		attrs.umami = maxi(attrs.umami + WATER_UMAMI, 0)


# 鍋が空かどうかを返す。serve する前に必ずチェックすること。
func is_empty() -> bool:
	return volume <= 0
