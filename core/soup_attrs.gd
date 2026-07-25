# soup_attrs.gd
# 設計書 3.1「属性の表現」に対応。
#
# スープの「濃厚さ・あっさり感・旨味」を3つの整数で表すデータクラス。
# Pot（鍋）が持つ現在の状態、CustomerResource が持つ理想値、
# RecipeResource が持つ食材の補正値など、スープ関連の数値はすべてこの型を使う。
#
# Resource を継承しているのは、Godot エディター上でインスペクターから
# 値を確認・編集できるようにするため（将来的に .tres ファイルで保存する想定）。

class_name SoupAttrs
extends Resource

# rich  : スープの濃厚さ。豚骨ベースで高く、水を足すと下がる。
# light : あっさり感。精進ベースや黒酢薬味で上がる。
# umami : 旨味の強さ。客の満足度に大きく影響する軸。
# 3 軸の合計距離（distance_to）で客の理想との差を計算する。
@export var rich: int = 0
@export var light: int = 0
@export var umami: int = 0


# 別の SoupAttrs の値をこのインスタンスに加算する。
# 鍋に食材を投入するときや、サーブ時にトッピング・薬味の補正を
# カップの属性に足す際に呼ぶ。
func add(other: SoupAttrs) -> void:
	rich += other.rich
	light += other.light
	umami += other.umami


# 別の SoupAttrs との「差のマンハッタン距離」を返す。
# rich・light・umami それぞれの絶対差を合計した値で、
# Evaluator が客の理想とカップの乖離を測るために使う。
func distance_to(other: SoupAttrs) -> int:
	return abs(rich - other.rich) + abs(light - other.light) + abs(umami - other.umami)


# 同じ値を持つ新しい SoupAttrs インスタンスを返す。
# Resource は参照型なので、コピーせずに渡すと複数箇所が同じオブジェクトを
# 変更してしまう。Pot.setup や Pot.serve の中で安全なコピーを作るために使う。
func duplicate_attrs() -> SoupAttrs:
	var a := SoupAttrs.new()
	a.rich = rich
	a.light = light
	a.umami = umami
	return a
