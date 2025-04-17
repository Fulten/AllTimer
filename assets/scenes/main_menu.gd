extends Control

func _ready():
	$StackAnimator.play("Anim_Stack0_Init")
	$Stack_0/TitleHeader2.grab_focus()
func _process(_delta):
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

#Button UX
func _on_play_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_play_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_play_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_play_button_button_up():
	get_tree().change_scene_to_file("res://assets/scenes/loading_screen.tscn")

func _on_options_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_options_button_button_up():
	$StackAnimator/Timer_Stack0_to_Options.start()
	$StackAnimator.play("Anim_Stack0_FadeOut")
func _on_timer_stack_0_to_options_categories_timeout():
		$StackAnimator.play("Anim_OptionsCategories_FadeIn")
		get_node("Stack_0").hide()
		get_node("Options_2").show()	
		$Options_2/OptionsCategories/DisplayButton.grab_focus()

func _on_quit_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_quit_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_quit_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_quit_button_button_up():
	get_tree().quit()


func _on_options_categories_return_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_categories_return_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_categories_return_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_options_categories_return_button_up():
	$StackAnimator/Timer_Options_to_Stack0.start()
	$StackAnimator.play("Anim_OptionCategories_FadeOut")
func _on_timer_options_categories_to_stack_0_timeout():
	$StackAnimator.play("Anim_Stack0_FadeIn")
	get_node("Options_2").hide()
	get_node("Stack_0").show()
	$Stack_0/MainMenuButtons/PlayButton.grab_focus()

func _on_display_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_display_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_display_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_display_button_button_up():
	$StackAnimator/Timer_Options_to_Display.start()
	$StackAnimator.play("Anim_OptionCategories_FadeOut")
func _on_timer_options_to_display_timeout():
	$StackAnimator.play("Anim_Display_FadeIn")
	get_node("Options_2").hide()
	get_node("Options_Display2").show()

func _on_sound_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_sound_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_sound_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_sound_button_button_up():
	$StackAnimator/Timer_Options_to_Sound.start()
	$StackAnimator.play("Anim_OptionCategories_FadeOut")
func _on_timer_options_to_sound_timeout():
	$StackAnimator.play("Anim_Sound_FadeIn")
	get_node("Options_2").hide()
	get_node("Options_Sound2").show()

func _on_game_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_game_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_game_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_game_button_button_up():
	$StackAnimator/Timer_Options_to_Game.start()
	$StackAnimator.play("Anim_OptionCategories_FadeOut")
func _on_timer_options_to_game_timeout():
	$StackAnimator.play("Anim_Game_FadeIn")
	get_node("Options_2").hide()
	get_node("Options_Game2").show()


func _on_options_display_return_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_display_return_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_display_return_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_options_display_return_button_up():
	$StackAnimator/Timer_Display_to_Options.start()
	$StackAnimator.play("Anim_Display_FadeOut")
func _on_timer_display_to_options_timeout():
	get_node("Options_Display2").hide()
	get_node("Options_2").show()
	$StackAnimator.play("Anim_OptionsCategories_FadeIn")	
	$Options_2/OptionsCategories/DisplayButton.grab_focus()
	
func _on_display_list_item_selected(index: int)->void:
	match index:
		0:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		1:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		2:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)



func _on_options_sound_return_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_sound_return_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_sound_return_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_options_sound_return_button_up():
	$StackAnimator/Timer_Sound_to_Options.start()
	$StackAnimator.play("Anim_Sound_FadeOut")
func _on_timer_sound_to_options_timeout():
	$StackAnimator.play("Anim_OptionsCategories_FadeIn")
	get_node("Options_Sound2").hide()
	get_node("Options_2").show()
	$Options_2/OptionsCategories/SoundButton.grab_focus()

func _on_options_game_return_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_game_return_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_game_return_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_options_game_return_button_up():
	$StackAnimator/Timer_Game_to_Options.start()
	$StackAnimator.play("Anim_Game_FadeOut")
func _on_timer_game_to_options_timeout():
	$StackAnimator.play("Anim_OptionsCategories_FadeIn")
	get_node("Options_Game2").hide()
	get_node("Options_2").show()
	$Options_2/OptionsCategories/GameButton.grab_focus()

