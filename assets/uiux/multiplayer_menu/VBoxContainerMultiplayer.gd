extends VBoxContainer
# Called when the node enters the scene tree for the first time.
func _ready():
	$StartButton.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("1_P"):
		GameState.PlayerCount = 1
	elif event.is_action_pressed("2_P"):
		GameState.PlayerCount = 2
	elif event.is_action_pressed("3_P"):
		GameState.PlayerCount = 3
	elif event.is_action_pressed("4_P"):
		GameState.PlayerCount = 4
		
func _on_start_button_mouse_entered():
	$HoverSFX.play()
func _on_start_button_focus_entered():
	$HoverSFX.play()
func _on_start_button_button_down():
	$ClickSFX.play()
func _on_start_button_button_up():
	pass # Replace with function body.


func _on_multiplayer_host_button_mouse_entered():
	$HoverSFX.play()
func _on_multiplayer_host_button_focus_entered():
	$HoverSFX.play()
func _on_multiplayer_host_button_button_down():
	$ClickSFX.play()
func _on_multiplayer_host_button_button_up():
	pass # Replace with function body.
	
func _on_multiplayer_join_button_mouse_entered():
	$HoverSFX.play()
func _on_multiplayer_join_button_focus_entered():
	$HoverSFX.play()
func _on_multiplayer_join_button_button_down():
	$ClickSFX.play()
func _on_multiplayer_join_button_button_up():
	pass # Replace with function body.



