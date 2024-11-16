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
	get_tree().change_scene_to_file("res://assets/scenes/loading_screen.tscn")


func _on_options_button_mouse_entered():
	$HoverSFX.play()
func _on_options_button_button_down():
	$ClickSFX.play()
func _on_options_button_focus_entered():
	$HoverSFX.play()


func _on_quit_button_mouse_entered():
	$HoverSFX.play()
func _on_quit_button_focus_entered():
	$HoverSFX.play()
func _on_quit_button_button_down():		
	$ClickSFX.play()
func _on_quit_button_pressed():
		get_tree().quit()


func _on_credits_button_mouse_entered():
	$HoverSFX.play()
func _on_credits_button_focus_entered():
	$HoverSFX.play()
func _on_credits_button_button_down():
	$ClickSFX.play()

