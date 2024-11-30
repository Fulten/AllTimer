extends Node

var player_input = "p%s_answer_%s"
var player_name = "Player 1"
var player_index = 0
var player_peer_id = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	var input = _check_player_input(event, player_index)
	if input > 0:
		

func _set_up_player(name,index,peer_id):
	player_peer_id = peer_id
	player_index = index
	player_name = name


func _check_player_input(player_index, event):
	for i in range(4):
		if event.is_action_pressed(player_input % [player_index,i]):
			return i
	return -1
