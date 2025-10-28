extends Control

signal multiplayer_host
signal multiplayer_connect (ip)
signal launch_quiz
signal multiplayer_disconnect

var ip_address = "127.0.0.1"
var IpInputTextNode
const SECURITY_KEY = "0851DSADDTYA84571ARE"

var profiles_list_id_to_name = {}

func _ready():
	$BGM_Lobby.play()
	$StateChangers/LaunchButton.grab_focus()
	IpInputTextNode = $PeerConnectors/TextEdit
	IpInputTextNode.set("text", ip_address)
	_refresh_profiles_dropdown()

func _process(_delta):
	pass

##called when the text in the IP Address field is changed
func _on_text_edit_text_changed():
	ip_address = IpInputTextNode.get("text")
	pass


func _encrypt_ip(ip_to_encrypt):
	var key_bytes = SECURITY_KEY.to_utf8_buffer()
	var plaintext_bytes = ip_to_encrypt.to_utf8_buffer()
	var aes = AESContext.new()
	aes.start(AESContext.MODE_ECB_ENCRYPT, key_bytes)
	var encrypted_bytes = aes.update(plaintext_bytes)
	aes.finish()
	return encrypted_bytes


func _decrypt_ip(encrypted_bytes):
	var key_bytes = SECURITY_KEY.to_utf8_buffer()
	var aes_decrypt = AESContext.new()
	aes_decrypt.start(AESContext.MODE_ECB_DECRYPT, key_bytes)
	var decrypted_bytes = aes_decrypt.update(encrypted_bytes)
	aes_decrypt.finish()
	var decrypted_text = decrypted_bytes.get_string_from_utf8()


##called when the Profiles List drop down's selection is changed
func _on_profiles_list_item_selected(index):
	for key in UserProfiles.profiles.keys():
		UserProfiles.profiles[key]["selected"] = false
		pass
		
	UserProfiles.profiles[profiles_list_id_to_name[index]]["selected"] = true
	UserProfiles._IO_write_profiles()
	pass 
	
#region Host Button
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
	
	$ProfileCase/ProfilesList.disabled = true
	
	$CancelConnectionButton.disabled = false
	$PeerConnectors/HostButton.disabled = true
	$PeerConnectors/JoinButton.disabled = true
	$StateChangers/LaunchButton.disabled = false
#endregion

#region Join Button
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
	
	$ProfileCase/ProfilesList.disabled = true
	
	$CancelConnectionButton.disabled = false
	$PeerConnectors/HostButton.disabled = true
	$PeerConnectors/JoinButton.disabled = true
#endregion

#region Cancel Button
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
	
	$ProfileCase/ProfilesList.disabled = false
	
	$CancelConnectionButton.disabled = true
	$PeerConnectors/HostButton.disabled = false
	$PeerConnectors/JoinButton.disabled = false
	$StateChangers/LaunchButton.disabled = true
	
	multiplayer_disconnect.emit()
	_update_connected_players()
#endregion	

#region Launch Button
func _on_launch_button_mouse_entered():
	$SFX_Hover.play()
func _on_launch_button_focus_entered():
	$SFX_Hover.play()
func _on_launch_button_button_down():
	$SFX_Press.play()
func _on_launch_button_button_up():
	$BGM_Lobby.stop()
	$StateChangers/LaunchButton.disabled = true
	launch_quiz.emit()
	pass
#endregion

#region Back Button
func _on_back_to_main_button_mouse_entered():
	$SFX_Hover.play()
func _on_back_to_main_button_focus_entered():
	$SFX_Hover.play()
func _on_back_to_main_button_button_down():
	$SFX_Press.play()
func _on_back_to_main_button_button_up():
	_exit_menu()
	pass
#endregion

#region Connection Failed confirm Button
func _on_conn_fail_ack_mouse_entered():
	$SFX_Hover.play()
func _on_conn_fail_ack_focus_entered():
	$SFX_Hover.play()
func _on_conn_fail_ack_button_down():
	$SFX_Press.play()
func _on_conn_fail_ack_button_up():
	get_node("ConnectionFailedPopupCase").hide()
#endregion

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

func _enable_launch_button():
	$StateChangers/LaunchButton.disabled = false
	pass

func _connection_reset(error):
	print("Connection Failed: %s" % error)
	get_node("ConnectionFailedPopupCase").show()
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

func _refresh_profiles_dropdown():
	var profile_list = $ProfileCase/ProfilesList
	var id = 0
	profile_list.clear()
	
	if UserProfiles.profiles.size() <= 0: # use placeholder if profiles list is empty
		profile_list.add_item("N/A")
		return
	
	
	for key in UserProfiles.profiles.keys():
		profile_list.add_item(UserProfiles.profiles[key]["name"])
		profiles_list_id_to_name[id] = UserProfiles.profiles[key]["name"]
		
		if (UserProfiles.profiles[key]["selected"]):
			profile_list.select(id)
			pass
		
		id += 1
		pass
	pass

func _reset_menu():
	$HostingLabel.hide()
	$JoiningLabel.hide()
	$JoinedLabel.hide()
	$CancelConnectionButton.hide()
	$PeerConnectors.show()
	
	$ProfileCase/ProfilesList.disabled = false
	
	$CancelConnectionButton.disabled = true
	$PeerConnectors/HostButton.disabled = false
	$PeerConnectors/JoinButton.disabled = false
	$StateChangers/LaunchButton.disabled = true
	
	multiplayer_disconnect.emit()
	_update_connected_players()
	pass
