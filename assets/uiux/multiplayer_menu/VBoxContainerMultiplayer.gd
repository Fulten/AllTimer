extends VBoxContainer

signal multiplayer_host
signal multiplayer_connect (ip)
signal launch_quiz
signal multiplayer_disconnect

var ip_address = "127.0.0.1"
var IpInputTextNode

# Called when the node enters the scene tree for the first time.
func _ready():
	$StartButton.grab_focus()
	IpInputTextNode = get_parent().get_node("IpInputText")
	IpInputTextNode.set("text", ip_address)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_text_edit_text_changed():
	ip_address = IpInputTextNode.get("Text")
	pass
	
func _on_start_button_mouse_entered():
	$HoverSFX.play()
func _on_start_button_focus_entered():
	$HoverSFX.play()
func _on_start_button_button_down():
	$ClickSFX.play()
func _on_start_button_button_up():
	launch_quiz.emit()
	queue_free()

func _on_multiplayer_host_button_mouse_entered():
	$HoverSFX.play()
func _on_multiplayer_host_button_focus_entered():
	$HoverSFX.play()
func _on_multiplayer_host_button_button_down():
	$ClickSFX.play()
func _on_multiplayer_host_button_button_up():
	multiplayer_host.emit(ip_address)
	$StartButton.disabled = false
	$MultiplayerHostButton.disabled = true
	$MultiplayerJoinButton.disabled = true
	pass
	
func _on_multiplayer_join_button_mouse_entered():
	$HoverSFX.play()
func _on_multiplayer_join_button_focus_entered():
	$HoverSFX.play()
func _on_multiplayer_join_button_button_down():
	$ClickSFX.play()
func _on_multiplayer_join_button_button_up():
	# TODO:: check if ipaddress is valid
	multiplayer_connect.emit(ip_address)
	$MultiplayerHostButton.disabled = true
	$MultiplayerJoinButton.disabled = true
	pass


func _on_back_button_mouse_entered():
	$HoverSFX.play()
func _on_back_button_focus_entered():
	$HoverSFX.play()
func _on_back_button_button_down():
	$ClickSFX.play()
func _on_back_button_button_up():
	_exit_menu()
	
func _update_connected_players(index):
	for n in range(1, 4):
		var playerLabel = get_node( "../VPlayerLabelContainer/Player%dLabel" % n)
		playerLabel.set("text", "")
		
	var n = 1
	
	for playerId in GameState.players:
		var playerLabel = get_node("../VPlayerLabelContainer/Player%dLabel" % n)
		playerLabel.set("text", GameState.players[playerId].name)
		n += 1

	pass
	
func _exit_menu():
	multiplayer_disconnect.emit()
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
	queue_free()

