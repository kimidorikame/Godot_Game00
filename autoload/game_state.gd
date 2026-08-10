extends Node

enum Phase { MORNING, MARKET, PREP, NIGHT, RESULT, HOME }
enum Ending { A, B }

const REP_ENDING_THRESHOLD := 5
const INITIAL_MONEY := 3000

var day: int = 1
var money: int = INITIAL_MONEY
var reputation: int = 0
var inventory: Dictionary = {}
var story_flags: Dictionary = {}
var phase: Phase = Phase.MORNING
# phase同様セーブ対象外。change_scene_to_file が引数を渡せないため、
# Day7判定結果を Ending.tscn へ渡す一時受け渡し用
var last_ending: Ending = Ending.B


func next_day() -> void:
	day += 1


# 骨子は評判1軸の1段階判定のみ。謎の男の実来店・最後の一杯GREAT判定の
# 2段目は骨子外（docs/m4_design.md）
static func ending_for_reputation(rep: int) -> Ending:
	return Ending.A if rep >= REP_ENDING_THRESHOLD else Ending.B


# NEWGAME開始時に呼ぶ。LOAD時はセーブデータで上書きするため呼ばない。
# last_ending はここでは初期化しない: Day7判定直前（result.gd）で必ず上書きされる
# 一時受け渡し用の値であり、NEWGAME時点の値に意味がないため。
func reset_for_new_game() -> void:
	day = 1
	money = INITIAL_MONEY
	reputation = 0
	inventory = {}
	story_flags = {}
	phase = Phase.MORNING
