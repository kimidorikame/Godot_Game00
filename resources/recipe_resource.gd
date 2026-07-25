# recipe_resource.gd
# 設計書 3.2「食材（RecipeResource）」に対応。
#
# ベース・鍋素材・トッピング・薬味といった「レシピ素材」を表すデータクラス。
# kind で用途を区別し、attrs にスープへの補正値を持つ。
# Godot エディターのインスペクターで編集し .tres ファイルとして保存する想定
#（M3 以降で data/recipes/ に置く予定）。
#
# Resource を継承しているのは .tres ファイルへの保存と
# インスペクター編集を行うため（GDScript の @export がインスペクターに表示される）。

class_name RecipeResource
extends Resource

# 素材の種別。サーブ時にどの段階で使われるかを区別する。
# BASE          : 仕込み時にベースとなるスープ（豚骨・精進など）
# POT_INGREDIENT: 仕込み時に鍋に加える具材
# TOPPING       : サーブ時にカップへ追加するトッピング
# YAKUMI        : サーブ時にカップへ追加する薬味
enum Kind { BASE, POT_INGREDIENT, TOPPING, YAKUMI }

# スクリプト内でレシピを参照するための一意な識別子（例: &"tonkotsu_base"）。
@export var id: StringName

# UI や会話で表示する素材名。
@export var display_name: String

# この素材の種別（上の Kind 参照）。
@export var kind: Kind

# スープへの属性補正値。鍋やカップに add() で加算される。
@export var attrs: SoupAttrs

# 素材の仕入れ価格。昼パート（市場）での購入コスト計算に使う（M3 以降）。
@export var price: int

# BASE 種別のとき、この仕込みで得られる初期カップ数。
@export var base_volume: int = 8

# インベントリ画面などで使う素材のアイコン画像（M3 以降で設定）。
@export var icon: Texture2D
