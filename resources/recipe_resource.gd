class_name RecipeResource
extends Resource

enum Kind { BASE, POT_INGREDIENT, TOPPING, YAKUMI }

@export var id: StringName
@export var display_name: String
@export var kind: Kind
@export var attrs: SoupAttrs
@export var price: int
@export var base_volume: int = 8
@export var icon: Texture2D
