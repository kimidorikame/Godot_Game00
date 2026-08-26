class_name DishTags
extends RefCounted
## 新系（事情適合＋3層評価）で使うタグ語彙の一元管理。
## インスタンス化はしない、定数の置き場としてのユーティリティクラス。
## IngredientData（食材データ）と判定ルール（成立・相性・事情適合）が
## ここの定数を参照し、タグの綴りを直書きしない。

# --- 味カテゴリ（taste_traits に入る） ---

## 塩気
const TRAIT_SALTY := &"salty"
## 旨味
const TRAIT_UMAMI := &"umami"
## 甘み
const TRAIT_SWEET := &"sweet"
## 酸味
const TRAIT_SOUR := &"sour"
## 苦味
const TRAIT_BITTER := &"bitter"
## コク
const TRAIT_KOKU := &"koku"
## 刺激
const TRAIT_STIMULUS := &"stimulus"

# --- 性質タグ（property_tags に入る） ---
# 苦味は味カテゴリの TRAIT_BITTER を性質としても流用する（別定義しない）。
# 食材によって taste_traits と property_tags のどちらに入れるかは .tres 側で決める。

## 肉
const PROP_MEAT := &"meat"
## 脂
const PROP_FAT := &"fat"
## ゼラチン
const PROP_GELATIN := &"gelatin"
## 海産
const PROP_SEAFOOD := &"seafood"
## 淡泊
const PROP_PLAIN := &"plain"
## 吸味（味を吸う性質）
const PROP_ABSORBENT := &"absorbent"
## 乾物
const PROP_DRIED := &"dried"
## 強い匂い
const PROP_STRONG_ODOR := &"strong_odor"
## 菌類
const PROP_FUNGUS := &"fungus"
## 野菜
const PROP_VEGETABLE := &"vegetable"
## 植物
const PROP_PLANT := &"plant"

# --- 香りタグ（aroma_tags に入る） ---

## 薬膳香
const AROMA_MEDICINAL := &"medicinal_aroma"
## 柑橘香
const AROMA_CITRUS := &"citrus_aroma"
## 温香
const AROMA_WARM := &"warm_aroma"
## 強香
const AROMA_STRONG := &"strong_aroma"
## 発酵香
const AROMA_FERMENTED := &"fermented_aroma"
## 清香
const AROMA_FRESH := &"fresh_aroma"
## 醤香
const AROMA_SOY := &"soy_aroma"
## 磯香
const AROMA_SEA := &"sea_aroma"
## 臭み消し
const AROMA_DEODORIZING := &"deodorizing"

# --- 満腹度（satiety の値。3値のいずれか1つを取る） ---

## 軽い
const SATIETY_LIGHT := &"light"
## 普通
const SATIETY_NORMAL := &"normal"
## 満腹
const SATIETY_FILLING := &"filling"

# --- 価格帯（cost_band の値。3値のいずれか1つを取る） ---

## 安い
const COST_CHEAP := &"cheap"
## 普通
const COST_NORMAL := &"normal"
## 高い
const COST_EXPENSIVE := &"expensive"
