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
	get_node("/root/MainMenu/Stack_0").hide()
	get_node("/root/MainMenu/Options_1").show()
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


# Submenu buttons that show/hide respective submenus
func _on_options_1_return_mouse_entered():
	$HoverSFX.play()
func _on_options_1_return_focus_entered():
	$HoverSFX.play()
func _on_options_1_return_pressed():
	$ClickSFX.play()
	get_node("/root/MainMenu/Options_1").hide()
	get_node("/root/MainMenu/Stack_0").show()

func _on_display_options_mouse_entered():
	$HoverSFX.play()
func _on_display_options_focus_entered():
	$HoverSFX.play()
func _on_display_options_pressed():
	$ClickSFX.play()
	get_node("/root/MainMenu/Options_1").hide()
	get_node("/root/MainMenu/Options_Display").show()

func _on_options_display_return_mouse_entered():
	$HoverSFX.play()
func _on_options_display_return_focus_entered():
	$HoverSFX.play()
func _on_options_display_return_pressed():
	$ClickSFX.play()
	get_node("/root/MainMenu/Options_Display").hide()
	get_node("/root/MainMenu/Options_1").show()

func _on_sound_options_mouse_entered():
	$HoverSFX.play()
func _on_sound_options_focus_entered():
	$HoverSFX.play()
func _on_sound_options_pressed():
	$ClickSFX.play()
	get_node("/root/MainMenu/Options_1").hide()
	get_node("/root/MainMenu/Options_Sound").show()

func _on_options_sound_return_mouse_entered():
	$HoverSFX.play()
func _on_options_sound_return_focus_entered():
	$HoverSFX.play()
func _on_options_sound_return_pressed():
	$ClickSFX.play()
	get_node("/root/MainMenu/Options_Sound").hide()
	get_node("/root/MainMenu/Options_1").show()

func _on_game_options_mouse_entered():
	$HoverSFX.play()
func _on_game_options_focus_entered():
	$HoverSFX.play()
func _on_game_options_pressed():
	$ClickSFX.play()
	get_node("/root/MainMenu/Options_1").hide()
	get_node("/root/MainMenu/Options_Game").show()

func _on_options_game_return_mouse_entered():
	$HoverSFX.play()
func _on_options_game_return_focus_entered():
	$HoverSFX.play()
func _on_options_game_return_pressed():
	$ClickSFX.play()
	get_node("/root/MainMenu/Options_Game").hide()
	get_node("/root/MainMenu/Options_1").show()


func _on_display_list_item_selected(index: int)->void:
	match index:
		0:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		1:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		2:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
