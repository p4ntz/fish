extends Node2D

var multi : int
var multi_bonus : Node = null
var multi_bonus_txt : String = "Gut {multi} fish at once to get 1 {prize} guaranteed!"
var multi_gut : Node = null
var multi_gut_txt : String = "Gut x{multi}"
var pity_max : int
var pity : int
var pity_bar : Node = null
var prize_pool : Array = [
	"Super Rare", 
	"Super Fishy Rare", 
	"Super Super Rare", 
	"Super Super Fishy Rare"
]

func _ready():
	var single_gut = get_node("CanvasLayer/Control/HBoxContainer/Gutting/SingleGut")
	multi_gut = get_node("CanvasLayer/Control/HBoxContainer/Gutting/MultiGut")
	pity_bar = get_node("CanvasLayer/Control/HBoxContainer/PityAndBanners/ProgressBar")
	multi_bonus = get_node("CanvasLayer/Control/HBoxContainer/Gutting/MultiBonus")
	single_gut.pressed.connect(_gut.bind(true))
	multi_gut.pressed.connect(_gut.bind(false))
	_reset_pity()
	_set_multi()
	
func _set_pity(add:int=1,subt:int=0) -> void:
	if add==0 and subt==0:
		pity = 0
	else:
		pity = pity+add-subt
	pity_bar.value = pity
	
func _reset_pity() -> void:
	pity_max = randi_range(1,999)
	pity_bar.max_value = pity_max
	_set_pity(0)
	print("pity meter is currently at ", pity, " and will be maxed at ", pity_max)
	
func _set_multi() -> void:
	multi = randi_range(2,10)
	multi_bonus.text=multi_bonus_txt.format({"multi": str(multi), "prize": prize_pool.pick_random()})
	multi_gut.text=multi_gut_txt.format({"multi": str(multi)})
	print("multi is ", multi)

func gut_prize():
	if pity>=pity_max:
		_reset_pity() 
		return "You are the best fish in the sea."
	var prizes=[
		"Your jokes always leave me reeling.",
		"You always know how to hook my attention.",
		"You're a real catch.",
		"I wouldn't gut you even if you were rainbow!",
		"You're my favorite member of life's cast.",
		"You're fin-ny.",
		"You've got guts!",
		"Let's play Go-Fish together!"
	]
	_set_pity()
	return prizes.pick_random()

func _gut(single:bool, gutting:int=1):
	if not single:
		gutting=multi
		print("Gutting ", gutting, " {fish}...")
	for i in gutting:
		print("You gutted [fish]. You received: ", gut_prize())
	_set_multi()
