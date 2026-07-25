class_name Pot
extends RefCounted

const KONIZUMARI_PER_TURN := 1
const WATER_VOLUME := 2
const WATER_RICH := -2
const WATER_UMAMI := -1

var volume: int = 0
var attrs: SoupAttrs = SoupAttrs.new()


func setup(base: RecipeResource, pot_ingredients: Array[RecipeResource]) -> void:
	attrs = base.attrs.duplicate_attrs()
	for ing in pot_ingredients:
		attrs.add(ing.attrs)
	volume = base.base_volume


func serve(topping: RecipeResource, yakumi: RecipeResource) -> SoupServing:
	assert(volume > 0)
	volume -= 1
	var cup := SoupServing.new()
	cup.attrs = attrs.duplicate_attrs()
	if topping:
		cup.attrs.add(topping.attrs)
	if yakumi:
		cup.attrs.add(yakumi.attrs)
	cup.topping = topping
	cup.yakumi = yakumi
	return cup


func on_turn_end() -> void:
	attrs.rich += KONIZUMARI_PER_TURN


func add_water() -> void:
	volume += WATER_VOLUME
	attrs.rich = maxi(attrs.rich + WATER_RICH, 0)
	attrs.umami = maxi(attrs.umami + WATER_UMAMI, 0)


func is_empty() -> bool:
	return volume <= 0
