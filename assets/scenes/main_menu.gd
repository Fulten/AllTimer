extends Control

var config = ConfigFile.new()
var config_path = "user://settings.cfg"


func _ready():
	$StackAnimator.play("Anim_Stack0_Init")
	$Stack_0/TitleHeader2.grab_focus()
	load_settings()


func _process(_delta):
	pass


func save_audio_settings(sound_device: String, master: float, music: float, sfx: float, voiceover: float):
	config.set_value("audio", "sound_device", $Options_Sound2/SettingsList/HBoxContainer5/OptionButton.get_item_text($Options_Sound2/SettingsList/HBoxContainer5/OptionButton.get_selected_id()))
	config.set_value("audio", "master", $Options_Sound2/SettingsList/VolumeControlHeader/VolumeSlidersCase/VolumeControl.get_value())
	config.set_value("video", "music", $Options_Sound2/SettingsList/VolumeControlHeader/VolumeSlidersCase/VolumeControl2.get_value())
	config.set_value("video", "sfx", $Options_Sound2/SettingsList/VolumeControlHeader/VolumeSlidersCase/VolumeControl3.get_value())
	config.set_value("video", "voiceover", $Options_Sound2/SettingsList/VolumeControlHeader/VolumeSlidersCase/VolumeControl4.get_value())
	config.save(config_path)


func save_video_settings():
	config.set_value("video", "type", $Options_Display2/OptionsList/DisplayType/DisplayList.get_item_text($Options_Display2/OptionsList/DisplayType/DisplayList.get_selected_id()))
	var resolution = $Options_Display2/OptionsList/ResolutionSettings/ResolutionsList.get_item_text($Options_Display2/OptionsList/ResolutionSettings/ResolutionsList.get_selected_id()).split("x")
	config.set_value("video", "resolution_width", resolution[0])
	config.set_value("video", "resolution_height", resolution[1])
	config.set_value("video", "input", $Options_Display2/OptionsList/ButtonIcons/OptionButton.get_item_text($Options_Display2/OptionsList/ButtonIcons/OptionButton.get_selected_id()))
	config.set_value("video", "theme", $Options_Display2/OptionsList/SessionThemes/OptionButton.get_item_text($Options_Display2/OptionsList/SessionThemes/OptionButton.get_selected_id()))
	config.save(config_path)


func save_game_settings(timer: int, win_con: String, tallies: bool, skipping_losses: bool, gambling_modes: bool):
	config.set_value("game", "timer", $Options_Game2/SettingsList/TimerSetting/OptionButton.get_item_text($Options_Game2/SettingsList/TimerSetting/OptionButton.get_selected_id()))
	config.set_value("game", "win_con", $Options_Game2/SettingsList/WinConditions/OptionButton.get_item_text($Options_Game2/SettingsList/WinConditions/OptionButton.get_selected_id()))
	config.set_value("game", "tallies", $Options_Game2/SettingsList/AltRulesContainer/HBoxContainer/CheckBox.is_pressed())
	config.set_value("game", "skipping_losses", $Options_Game2/SettingsList/AltRulesContainer/HBoxContainer2/CheckBox.is_pressed())
	config.set_value("game", "gambling_modes", $Options_Game2/SettingsList/AltRulesContainer/HBoxContainer3/CheckBox.is_pressed())
	config.save(config_path)


func load_settings():
	var err = config.load(config_path)
	if err == OK:
#		AUDIO
		var sound_device = config.get_value("audio", "sound_device", "default")
		var master = config.get_value("audio", "master", 1.0)
		var music = config.get_value("audio", "music", 1.0)
		var sfx = config.get_value("audio", "sfx", 1.0)
		var voiceover = config.get_value("audio", "voiceover", 1.0)
#		VIDEO
		var display_type = config.get_value("video", "type", 0)
		var width = config.get_value("video", "resolution_width", 1920)
		var height = config.get_value("video", "resolution_height", 1080)
		var input_display = config.get_value("video", "input", "default")
		var theme = config.get_value("video", "theme", "default")
#		GAME
		var timer = config.get_value("game", "timer", "30")
		var win_con = config.get_value("game", "win_con", "default")
		var tallies = config.get_value("game", "tallies", false)
		var skipping_losses = config.get_value("game", "skipping_losses", false)
		var gambling_modes = config.get_value("game", "gambling_modes", false)
#		APPLY
		apply_audio_settings(sound_device, master, music, sfx, voiceover)
		apply_video_settings(display_type, Vector2(1920, 1080), input_display, theme)
		apply_game_settings(timer, win_con, tallies, skipping_losses, gambling_modes)
	else:
		print("No settings file found. Using defaults.")


func apply_audio_settings(sound_device: String, master: float, music: float, sfx: float, voiceover: float):
	var devices = AudioServer.get_output_device_list()
	if sound_device not in devices:
		sound_device = devices[0]
	AudioServer.set_output_device(sound_device)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"), voiceover)
	


func apply_video_settings(display_type: int, resolution: Vector2, input_display: String, theme: String):
	_on_display_list_item_selected(display_type)
	DisplayServer.window_set_size(resolution)


func apply_game_settings(timer: int, win_con: String, tallies: bool, skipping_losses: bool, gambling_modes: bool):
#	will need to do this later for a game_options global state
	return


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

