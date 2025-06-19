extends Control

var config = ConfigFile.new()
var config_path = "user://settings.cfg"

func _ready():
	$StackAnimator.play("Anim_Stack0_Init")
	$Stack_0/TitleHeader2.grab_focus()
	load_settings()

func _process(_delta):
	pass


func save_audio_settings():
	config.set_value("audio", "sound_device", %SoundDeviceOptions.get_item_text(%SoundDeviceOptions.get_selected_id()))
	config.set_value("audio", "master", %VolumeControl.get_value())
	config.set_value("audio", "music", %VolumeControl2.get_value())
	config.set_value("audio", "sfx", %VolumeControl3.get_value())
	config.set_value("audio", "voiceover", %VolumeControl4.get_value())
	config.save(config_path)


func save_video_settings():
	config.set_value("video", "type", %DisplayList.get_selected_id())
	config.set_value("video", "resolution", %ResolutionsList.get_selected_id())
	config.set_value("video", "input", %InputDisplayList.get_item_text(%InputDisplayList.get_selected_id()))
	config.set_value("video", "theme", %SessionThemesList.get_item_text(%SessionThemesList.get_selected_id()))
	config.save(config_path)


func save_game_settings():
	config.set_value("game", "timer", int(%TimerSettingList.get_item_text(%TimerSettingList.get_selected_id())))
	config.set_value("game", "win_con", %WinConList.get_item_text(%WinConList.get_selected_id()))
	config.set_value("game", "tallies", %TalliesCheckBox.is_pressed())
	config.set_value("game", "skipping_losses", %Lose4SkipCheckBox.is_pressed())
	config.set_value("game", "gambling_modes", %GamblingOnCheckBox.is_pressed())
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
		var resolution = config.get_value("video", "resolution", 0)
		var input_display = config.get_value("video", "input", "default")
		var theme = config.get_value("video", "theme", "default")
#		GAME
		var timer = config.get_value("game", "timer", 30)
		var win_con = config.get_value("game", "win_con", "default")
		var tallies = config.get_value("game", "tallies", false)
		var skipping_losses = config.get_value("game", "skipping_losses", false)
		var gambling_modes = config.get_value("game", "gambling_modes", false)
#		APPLY
		apply_audio_settings(sound_device, master, music, sfx, voiceover)
		apply_video_settings(display_type, resolution, input_display, theme)
		apply_game_settings(timer, win_con, tallies, skipping_losses, gambling_modes)
	else:
		print("No settings file found. Using defaults.")


func select_option_by_text(option_button: OptionButton, target_text: String) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == str(target_text):
			option_button.select(i)
			return
	print("Text not found in OptionButton:", target_text)


func select_option_by_int(option_button: OptionButton, target_int: int) -> void:
	for i in range(option_button.item_count):
		if int(option_button.get_item_text(i)) == target_int:
			option_button.select(i)
			return
	print("Int not found in OptionButton:", target_int)


func apply_audio_settings(sound_device: String, master: float, music: float, sfx: float, voiceover: float):
	var devices = AudioServer.get_output_device_list()
	var found_match = false
	%SoundDeviceOptions.clear()
	for device in devices:
		%SoundDeviceOptions.add_item(device)
		if sound_device == device:
			found_match = true
			select_option_by_text(%SoundDeviceOptions, sound_device)
	AudioServer.set_output_device(sound_device if found_match else devices[0])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master)
	%VolumeControl.set_value_no_signal(master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music))
	%VolumeControl2.set_value_no_signal(music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx))
	%VolumeControl3.set_value_no_signal(sfx)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"), linear_to_db(voiceover))
	%VolumeControl4.set_value_no_signal(voiceover)
	


func apply_video_settings(display_type: int, resolution: int, input_display: String, theme: String):
	%DisplayList.select(display_type)
	_on_display_list_item_selected(display_type)
	%ResolutionsList.select(resolution)
	_on_resolutions_list_item_selected(resolution)
	select_option_by_text(%InputDisplayList,input_display)
	select_option_by_text(%SessionThemesList,theme)


func apply_game_settings(timer: int, win_con: String, tallies: bool, skipping_losses: bool, gambling_modes: bool):
	select_option_by_int(%TimerSettingList, timer)
	select_option_by_text(%WinConList, win_con)
	%TalliesCheckBox.set_pressed_no_signal(tallies)
	%Lose4SkipCheckBox.set_pressed_no_signal(skipping_losses)
	%GamblingOnCheckBox.set_pressed_no_signal(gambling_modes)
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


func _on_profile_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_profile_button_button_up():
	$StackAnimator/Timer_Stack0_to_Profile.start()
	$StackAnimator.play("Anim_Stack0_FadeOut")
func _on_timer_stack_0_to_profile_timeout():
	$StackAnimator.play("Anim_Profile_FadeIn")
	get_node("Stack_0").hide()
	get_node("Options_Profile").show()


func _on_options_profile_return_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_profile_return_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_profile_return_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_options_profile_return_button_up():
	$StackAnimator/Timer_Profile_to_Stack0.start()
	$StackAnimator.play("Anim_Profile_FadeOut")
func _on_timer_profile_to_stack_0_timeout():
	$StackAnimator.play("Anim_Stack0_FadeIn")
	get_node("Options_Profile").hide()
	get_node("Stack_0").show()

func _on_profile_creator_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_creator_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_creator_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_profile_creator_button_button_up():
	get_node("Options_Profile/ProfileDestroyer").hide()
	get_node("Options_Profile/ProfileCreator").show()

func _on_save_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_save_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_save_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_save_button_button_up():
	pass # This is the button-press that saves a new profile to the ProfilesList. It should name the profile with whatever string is in ProfileEntryField and then clear the field

func _on_cancel_profile_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_cancel_profile_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_cancel_profile_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_cancel_profile_button_button_up():
	get_node("Options_Profile/ProfileCreator").hide()

func _on_profile_deleter_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_deleter_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_deleter_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_profile_deleter_button_button_up():
	get_node("Options_Profile/ProfileCreator").hide()
	get_node("Options_Profile/ProfileDestroyer").show()
	
func _on_delete_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_delete_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_delete_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_delete_button_button_up():
	pass # This button should read the currently selected profile in ProfilesList and then  D E L E T E  it

func _on_cancel_deletion_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_cancel_deletion_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_cancel_deletion_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_cancel_deletion_button_button_up():
	get_node("Options_Profile/ProfileDestroyer").hide()

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
	save_video_settings()
	$StackAnimator/Timer_Display_to_Options.start()
	$StackAnimator.play("Anim_Display_FadeOut")
func _on_timer_display_to_options_timeout():
	get_node("Options_Display2").hide()
	get_node("Options_2").show()
	$StackAnimator.play("Anim_OptionsCategories_FadeIn")	
	$Options_2/OptionsCategories/DisplayButton.grab_focus()


const display_options = [
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	DisplayServer.WINDOW_MODE_WINDOWED,
	DisplayServer.WINDOW_MODE_FULLSCREEN,
]


func _on_display_list_item_selected(index: int) -> void:
		DisplayServer.window_set_mode(display_options[index])


const resolution_options = [
	 Vector2(648, 648),
	 Vector2(640, 480),
	 Vector2(720, 480),
	 Vector2(800, 600),
	 Vector2(1152, 648),
	 Vector2(1280, 720),
	 Vector2(1280, 800),
	 Vector2(1680, 720),
	 Vector2(1920, 1080),
	 Vector2(2560, 1440)
]


func _on_resolutions_list_item_selected(index: int) -> void:
	DisplayServer.window_set_size(resolution_options[index])


func _on_options_sound_return_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_sound_return_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_sound_return_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_options_sound_return_button_up():
	save_audio_settings()
	$StackAnimator/Timer_Sound_to_Options.start()
	$StackAnimator.play("Anim_Sound_FadeOut")
func _on_timer_sound_to_options_timeout():
	$StackAnimator.play("Anim_OptionsCategories_FadeIn")
	get_node("Options_Sound2").hide()
	get_node("Options_2").show()
	$Options_2/OptionsCategories/SoundButton.grab_focus()


func _on_sound_device_options_item_selected(index: int) -> void:
	AudioServer.set_output_device(%SoundDeviceOptions.get_item_text(index))


func _on_options_game_return_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()

func _on_options_game_return_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_options_game_return_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_options_game_return_button_up():
	save_game_settings()
	$StackAnimator/Timer_Game_to_Options.start()
	$StackAnimator.play("Anim_Game_FadeOut")
func _on_timer_game_to_options_timeout():
	$StackAnimator.play("Anim_OptionsCategories_FadeIn")
	get_node("Options_Game2").hide()
	get_node("Options_2").show()
	$Options_2/OptionsCategories/GameButton.grab_focus()
