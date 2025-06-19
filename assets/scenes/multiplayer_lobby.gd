extends Control


func _ready():
	pass # Replace with function body.


func _process(delta):
	pass


func _on_host_button_mouse_entered():
	$SFX_Hover.play()
func _on_host_button_focus_entered():
	$SFX_Hover.play()
func _on_host_button_button_down():
	$SFX_Press.play()
func _on_host_button_button_up():
	get_node("PeerConnectors").hide()
	get_node("HostingLabel").show()
	get_node("CancelConnectionButton").show()


func _on_join_button_mouse_entered():
	$SFX_Hover.play()
func _on_join_button_focus_entered():
	$SFX_Hover.play()
func _on_join_button_button_down():
	$SFX_Press.play()
func _on_join_button_button_up():
	get_node("PeerConnectors").hide()
	get_node("JoinedLabel").show()
	get_node("CancelConnectionButton").show()


func _on_cancel_connection_button_mouse_entered():
	$SFX_Hover.play()
func _on_cancel_connection_button_focus_entered():
	$SFX_Hover.play()
func _on_cancel_connection_button_button_down():
	$SFX_Press.play()
func _on_cancel_connection_button_button_up():
	get_node("HostingLabel").hide()
	get_node("JoinedLabel").hide()
	get_node("CancelConnectionButton").hide()
	get_node("PeerConnectors").show()
	
	
func _on_launch_button_mouse_entered():
	$SFX_Hover.play()
func _on_launch_button_focus_entered():
	$SFX_Hover.play()
func _on_launch_button_button_down():
	$SFX_Press.play()
func _on_launch_button_button_up():
	pass # Replace with function body.


func _on_back_to_main_button_mouse_entered():
	$SFX_Hover.play()
func _on_back_to_main_button_focus_entered():
	$SFX_Hover.play()
func _on_back_to_main_button_button_down():
	$SFX_Press.play()
func _on_back_to_main_button_button_up():
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
