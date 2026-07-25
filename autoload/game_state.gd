extends Node

enum Phase { MORNING, MARKET, PREP, NIGHT, RESULT, HOME }

const REP_ENDING_THRESHOLD := 5

var day: int = 1
var money: int = 3000
var reputation: int = 0
var inventory: Dictionary = {}
var story_flags: Dictionary = {}
var phase: Phase = Phase.MORNING


func next_day() -> void:
	day += 1
