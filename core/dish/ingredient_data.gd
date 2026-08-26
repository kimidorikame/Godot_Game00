class_name IngredientData
extends Resource
## 新しい料理評価システム（事情適合＋3層評価）における食材データ。
## 既存 RecipeResource が持つ6軸数値の attrs を、タグの有無に置き換えたもの。
## 値は数値距離計算をせず、タグを持つか持たないかだけで扱う。
## タグの綴りは DishTags の定数を使う（直書きしない）。

## 具材/調味料/香辛料の種別
enum Kind {
	INGREDIENT, ## 具材
	SEASONING,  ## 調味料
	SPICE,      ## 香辛料
}

## 一意識別子
@export var id: StringName = &""

## 表示名
@export var display_name: String = ""

## 種別（具材/調味料/香辛料）
@export var kind: Kind = Kind.INGREDIENT

## 味カテゴリのタグ集合。DishTags の TRAIT_* を入れる
@export var taste_traits: Array[StringName] = []

## 性質タグ集合。DishTags の PROP_* を入れる（苦味は TRAIT_BITTER を流用）
@export var property_tags: Array[StringName] = []

## 香りタグ集合。DishTags の AROMA_* を入れる
@export var aroma_tags: Array[StringName] = []

## 満腹度。DishTags.SATIETY_* のいずれか1つ
@export var satiety: StringName = &""

## 価格帯。DishTags.COST_* のいずれか1つ
@export var cost_band: StringName = &""
