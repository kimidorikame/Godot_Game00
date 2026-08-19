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

# koku     : コク。濃厚⇔さらり。単極: 高いほど濃厚、水を足すと下がる、煮詰まると上がる。
# umami    : 旨味の強さ。客の満足度に大きく影響する軸。
# stimulus : 刺激（パンチ⇔マイルド）。薬味が主担当。単極: 0=マイルド、高=パンチ
# aroma    : 香り（芳醇⇔淡泊）。香味系が主担当。単極: 0=淡泊、高=芳醇
# 評価（distance_to）は koku/umami の2軸のみで計算する。stimulus/aroma は評価に含めない
# （器として存在するが未使用。ステップ3で評価に組み込む）。
@export var koku: int = 0
@export var umami: int = 0
@export var stimulus: int = 0
@export var aroma: int = 0

# 各軸のスケール最大値の目安。データ作成の指針＋失敗判定/UI等の基準。intに上限強制はしない。
const TASTE_AXIS_MAX := 50


# 別の SoupAttrs の値をこのインスタンスに加算する。
# 鍋に食材を投入するときや、サーブ時にトッピング・薬味の補正を
# カップの属性に足す際に呼ぶ。
func add(other: SoupAttrs) -> void:
	koku += other.koku
	umami += other.umami
	stimulus += other.stimulus
	aroma += other.aroma


# 別の SoupAttrs との「差のマンハッタン距離」を返す。
# koku・umami それぞれの絶対差を合計した値で、
# Evaluator が客の理想とカップの乖離を測るために使う。
# stimulus/aroma は器にあるが評価には含めない（ステップ3で追加予定）。
func distance_to(other: SoupAttrs) -> int:
	return abs(koku - other.koku) + abs(umami - other.umami)


# 同じ値を持つ新しい SoupAttrs インスタンスを返す。
# Resource は参照型なので、コピーせずに渡すと複数箇所が同じオブジェクトを
# 変更してしまう。Pot.setup や Pot.serve の中で安全なコピーを作るために使う。
func duplicate_attrs() -> SoupAttrs:
	var a := SoupAttrs.new()
	a.koku = koku
	a.umami = umami
	a.stimulus = stimulus
	a.aroma = aroma
	return a
