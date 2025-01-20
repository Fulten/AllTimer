extends Node

signal player_guess(player_index, guess)

var player_index = -1
var player_input = "p%s_answer_%s"

func _set_player(num): 
	print("player set")
	if (player_index > 0): 
		print("Error, attempted to reinstantiate player")
	player_index = num
	pass

func _input(event):
	for i in range(4):
		if event.is_action_pressed(player_input % [player_index,i]):
			player_guess.emit(player_index, i)
	pass

func _freePlayer():
	print("player free")
	queue_free()
	pass
