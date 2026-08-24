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
# sweet    : 甘さ（甘い⇔甘くない）。ココナッツ・砂糖等が主担当。単極: 0=甘くない、高=強い甘み
# sour     : 酸味（酸っぱい⇔酸味なし）。ライム・タマリンド・酢等が主担当。単極: 0=酸味なし、高=強い酸味
# 評価は4軸それぞれについて「idealとの差がtolerance以内か」を個別判定する
# 軸ごと合格判定モデル（Evaluator参照）。sweet/sourはステップ5-1時点では器のみで評価には未参加。
@export var koku: int = 0
@export var umami: int = 0
@export var stimulus: int = 0
@export var aroma: int = 0
@export var sweet: int = 0
@export var sour: int = 0

# 各軸のスケール最大値の目安。データ作成の指針＋失敗判定/UI等の基準。intに上限強制はしない。
const TASTE_AXIS_MAX := 50

# 軸ごとの許容幅（Evaluatorの軸ごと合格判定で使う）。値は暫定、ステップ4の数値調整で確定する。
const TOLERANCE_KOKU := 8
const TOLERANCE_UMAMI := 2
const TOLERANCE_STIMULUS := 2
const TOLERANCE_AROMA := 2
# sweet/sourはステップ5-1時点ではEvaluatorから未参照（評価導入はステップ5-2b）。
# 軸の定義を1箇所に揃えるため、器と同時に先に置いておく。値は暫定、ステップ4の数値調整で確定する。
const TOLERANCE_SWEET := 2
const TOLERANCE_SOUR := 2

# レシピ軸（Evaluatorの二層評価のうち、カップがメニュー目標と一致しているかを見る層）の
# 許容幅。「メニューとして成立しているか」を緩く見る判定のため、上のTOLERANCE_xxx（好み軸、
# 客ごと上書き可）より広めに取ってある。レシピ軸は客ごとの上書きを持たず常にこの共通値を使う。
# 値は暫定、スケール統一・バランス調整フェーズで確定する。
const RECIPE_TOLERANCE_KOKU := 16
const RECIPE_TOLERANCE_UMAMI := 4
const RECIPE_TOLERANCE_STIMULUS := 4
const RECIPE_TOLERANCE_AROMA := 4
const RECIPE_TOLERANCE_SWEET := 4
const RECIPE_TOLERANCE_SOUR := 4


# 別の SoupAttrs の値をこのインスタンスに加算する。
# 鍋に食材を投入するときや、サーブ時にトッピング・薬味の補正を
# カップの属性に足す際に呼ぶ。
func add(other: SoupAttrs) -> void:
	koku += other.koku
	umami += other.umami
	stimulus += other.stimulus
	aroma += other.aroma
	sweet += other.sweet
	sour += other.sour


# 負の attrs を持つ食材（黒酢など）を投入した後、各軸が負にならないよう
# 下限0で丸める。投入処理（複数回の add）の最後に1回呼ぶ。
func clamp_to_zero() -> void:
	koku = maxi(koku, 0)
	umami = maxi(umami, 0)
	stimulus = maxi(stimulus, 0)
	aroma = maxi(aroma, 0)
	sweet = maxi(sweet, 0)
	sour = maxi(sour, 0)


# 同じ値を持つ新しい SoupAttrs インスタンスを返す。
# Resource は参照型なので、コピーせずに渡すと複数箇所が同じオブジェクトを
# 変更してしまう。Pot.setup や Pot.serve の中で安全なコピーを作るために使う。
func duplicate_attrs() -> SoupAttrs:
	var a := SoupAttrs.new()
	a.koku = koku
	a.umami = umami
	a.stimulus = stimulus
	a.aroma = aroma
	a.sweet = sweet
	a.sour = sour
	return a
