extends Control

signal multiplayer_host
signal multiplayer_connect (ip)
signal launch_quiz
signal multiplayer_disconnect

var ip_address = "127.0.0.1"
var IpInputTextNode

func _ready():
	$StateChangers/LaunchButton.grab_focus()
	IpInputTextNode = $PeerConnectors/TextEdit
	IpInputTextNode.set("text", ip_address)

func _process(_delta):
	pass

func _on_text_edit_text_changed():
	ip_address = IpInputTextNode.get("text")
	pass

func _on_host_button_mouse_entered():
	$SFX_Hover.play()
func _on_host_button_focus_entered():
	$SFX_Hover.play()
func _on_host_button_button_down():
	$SFX_Press.play()
func _on_host_button_button_up():
	multiplayer_host.emit(ip_address)
	$PeerConnectors.hide()
	$HostingLabel.show()
	$CancelConnectionButton.show()
	
	$CancelConnectionButton.disabled = false
	$PeerConnectors/HostButton.disabled = true
	$PeerConnectors/JoinButton.disabled = true
	$StateChangers/LaunchButton.disabled = false

func _on_join_button_mouse_entered():
	$SFX_Hover.play()
func _on_join_button_focus_entered():
	$SFX_Hover.play()
func _on_join_button_button_down():
	$SFX_Press.play()
func _on_join_button_button_up():
	multiplayer_connect.emit(ip_address)
	$PeerConnectors.hide()
	$JoiningLabel.show()
	$CancelConnectionButton.show()
	
	$CancelConnectionButton.disabled = false
	$PeerConnectors/HostButton.disabled = true
	$PeerConnectors/JoinButton.disabled = true

func _on_cancel_connection_button_mouse_entered():
	$SFX_Hover.play()
func _on_cancel_connection_button_focus_entered():
	$SFX_Hover.play()
func _on_cancel_connection_button_button_down():
	$SFX_Press.play()
func _on_cancel_connection_button_button_up():
	$HostingLabel.hide()
	$JoiningLabel.hide()
	$JoinedLabel.hide()
	$CancelConnectionButton.hide()
	$PeerConnectors.show()
	
	$CancelConnectionButton.disabled = true
	$PeerConnectors/HostButton.disabled = false
	$PeerConnectors/JoinButton.disabled = false
	$StateChangers/LaunchButton.disabled = true
	
	multiplayer_disconnect.emit()
	_update_connected_players()
	
func _on_launch_button_mouse_entered():
	$SFX_Hover.play()
func _on_launch_button_focus_entered():
	$SFX_Hover.play()
func _on_launch_button_button_down():
	$SFX_Press.play()
func _on_launch_button_button_up():
	$StateChangers/LaunchButton.disabled = true
	launch_quiz.emit()
	pass

func _on_back_to_main_button_mouse_entered():
	$SFX_Hover.play()
func _on_back_to_main_button_focus_entered():
	$SFX_Hover.play()
func _on_back_to_main_button_button_down():
	$SFX_Press.play()
func _on_back_to_main_button_button_up():
	_exit_menu()
	pass

func _update_connected_players():
	for n in range(0, 3):
		var playerLabel = get_node("./PeerCase/Peer%d" % n)
		playerLabel.set("text", "")
		playerLabel.hide()
		
	var n = 0
	
	for playerId in GameState.players:
		var playerLabel = get_node("./PeerCase/Peer%d" % n)
		playerLabel.set("text", GameState.players[playerId].name)
		playerLabel.show()
		n += 1
	pass
	
func _exit_menu():
	multiplayer_disconnect.emit()
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
	queue_free()
	
func _connected_to_server():
	$JoiningLabel.hide()
	$JoinedLabel.show()
	pass
	
func _connection_reset(error):
	print("Connection Failed: %s" % error)
	_update_connected_players()
	
	$HostingLabel.hide()
	$JoinedLabel.hide()
	$JoiningLabel.hide()
	$CancelConnectionButton.hide()
	$PeerConnectors.show()
	
	$CancelConnectionButton.disabled = true
	$PeerConnectors/HostButton.disabled = false
	$PeerConnectors/JoinButton.disabled = false
	$StateChangers/LaunchButton.disabled = true
	
	pass
