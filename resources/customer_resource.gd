# customer_resource.gd
# 設計書 3.3「客（CustomerResource）」に対応。
#
# 一人の客が持つ「好みのスープ」と「評価基準」を定義するデータクラス。
# Evaluator.evaluate() はこのデータを参照して満足度を計算する。
# .tres ファイルとして data/customers/ に保存し、エディターで編集する想定
#（現在は debug_pot.gd でコード内直接生成している）。

class_name CustomerResource
extends Resource

# スクリプト内で客を参照するための一意な識別子（例: &"roujin"）。
@export var id: StringName

# UI や会話で表示する客の名前。
@export var display_name: String

# 客が「理想」とするスープの属性値（koku / umami）。
# Evaluator がカップとの距離を計算する基準点になる。
@export var ideal: SoupAttrs

# カップと理想の距離がこの値以下なら GREAT（大満足）になる閾値。
# 値が小さいほど厳しい（好みにぴったり合わないと満足しない）。
@export var great_threshold: int = 2

# カップと理想の距離がこの値以下なら OK（普通）になる閾値。
# これを超えると BAD（不満）になる。
@export var ok_threshold: int = 5

# 通常時の支払い額（OK グレードのときに受け取る金額）。
@export var base_price: int

# GREAT 時に base_price に上乗せされるチップ。
@export var tip: int

# 会話シーンで表示するキャラクター立ち絵（M2 以降で設定）。
@export var portrait: Texture2D

# 表情・状況バリエーションの立ち絵一覧（M2 以降で設定）。
@export var portrait_variants: Array[Texture2D]

# true のとき「プロの舌を持つ客」として扱う（将来の評価ロジック拡張用）。
@export var is_pro_critic: bool = false

# 客がスープについてこぼすヒント台詞。
# キー: 状況を表す StringName、値: 台詞の候補リスト（Array[String]）。
# M2 以降の会話システムで使う予定。
@export var hint_lines: Dictionary = {}  # StringName -> Array[String]（後で実装）
