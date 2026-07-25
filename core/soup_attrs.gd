class_name SoupAttrs
extends Resource

@export var rich: int = 0
@export var light: int = 0
@export var umami: int = 0


func add(other: SoupAttrs) -> void:
	rich += other.rich
	light += other.light
	umami += other.umami


func distance_to(other: SoupAttrs) -> int:
	return abs(rich - other.rich) + abs(light - other.light) + abs(umami - other.umami)


func duplicate_attrs() -> SoupAttrs:
	var a := SoupAttrs.new()
	a.rich = rich
	a.light = light
	a.umami = umami
	return a
