# soup_serving.gd
# 設計書 3.1「属性の表現」に対応（SoupAttrs の「カップ」ラッパー）。
#
# Pot.serve() が返す「一杯分のスープ」を表す一時オブジェクト。
# 鍋の現在属性をコピーし、トッピングと薬味の補正を加えた状態を保持する。
# Evaluator.evaluate() に渡して客の評価を得るために使う。
#
# RefCounted を継承しているのはデータ保持専用の軽量オブジェクトで、
# シーンツリーへの登録や .tres 保存は不要なため。
# （RefCounted は参照カウントで自動解放されるメモリ管理の仕組み）

class_name SoupServing
extends RefCounted

# サーブ時点の最終的なスープ属性（鍋の属性 + トッピング + 薬味を合算済み）。
var attrs: SoupAttrs

# このカップに添えたトッピング。なし の場合は null。
var topping: RecipeResource

# このカップに添えた薬味。なし の場合は null。
var yakumi: RecipeResource
