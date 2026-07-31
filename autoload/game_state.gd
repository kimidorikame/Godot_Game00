extends Node

enum Phase { MORNING, MARKET, PREP, NIGHT, RESULT, HOME }

const REP_ENDING_THRESHOLD := 5
const INITIAL_MONEY := 3000

var day: int = 1
var money: int = INITIAL_MONEY
var reputation: int = 0
var inventory: Dictionary = {}
var story_flags: Dictionary = {}
var phase: Phase = Phase.MORNING


func next_day() -> void:
	day += 1


# NEWGAME開始時に呼ぶ。LOAD時はセーブデータで上書きするため呼ばない。
func reset_for_new_game() -> void:
	day = 1
	money = INITIAL_MONEY
	reputation = 0
	inventory = {}
	story_flags = {}
	phase = Phase.MORNING
