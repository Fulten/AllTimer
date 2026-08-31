extends Control

var tags_list_theme = preload("res://assets/scenes/Checkbox_Filter.tres")
var style_box_empty:StyleBoxEmpty = StyleBoxEmpty.new()

var config = ConfigFile.new()
var config_path = "user://settings.cfg"

var profiles_list_id_to_name = {}

var flag_options_menu = false
var flag_options_menu_display = false
var flag_options_menu_sound = false
var flag_options_menu_game = false
var flag_profiles_menu = false
var flag_profiles_menu_sub = false

var node_hover_text
var show_award_hover = false

var filter_tag_selectors = []
var filter_selected_key = ""

func _ready():
	$StackAnimator.play("Anim_Stack0_Init")
	await get_tree().create_timer(0.1).timeout
	$Stack_0/TitleHeader2.grab_focus()
	GameState.quizOptions.initilize()
	load_settings()
	UserProfiles._IO_read_profiles()

	#get_tree().create_timer(0.025).timeout.connect(_init_filter_ui)
	_init_filter_ui()
	
	_refresh_profiles_dropdown()
	_update_current_profile_label()
	_update_profile_statistics()
	SoundMaster._play_music_track("main_menu")
	_create_hover_text_node()

func _process(_delta):
	pass

#region Save Settings Methods
func save_audio_settings():
	config.set_value("audio", "sound_device", %SoundDeviceOptions.get_item_text(%SoundDeviceOptions.get_selected_id()))
	config.set_value("audio", "master", %VolumeControl.get_value())
	config.set_value("audio", "music", %VolumeControl2.get_value())
	config.set_value("audio", "sfx", %VolumeControl3.get_value())
	config.set_value("audio", "voiceover", %VolumeControl4.get_value())
	config.save(config_path)


func save_video_settings():
	update_game_state_theme(%SessionThemesList.get_item_text(%SessionThemesList.get_selected_id()))
	config.set_value("video", "type", %DisplayList.get_selected_id())
	config.set_value("video", "resolution", %ResolutionsList.get_selected_id())
	config.set_value("video", "input", %InputDisplayList.get_item_text(%InputDisplayList.get_selected_id()))
	config.set_value("video", "theme", %SessionThemesList.get_item_text(%SessionThemesList.get_selected_id()))
	config.save(config_path)


func save_game_settings():
	update_game_state(int(%TimerSettingList.get_item_text(%TimerSettingList.get_selected_id())))
	config.set_value("game", "timer", GameState.quizOptions.timer)
	config.save(config_path)
#endregion

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
		@warning_ignore("shadowed_variable_base_class")
		var theme = config.get_value("video", "theme", "default")
#		GAME
		var timer = config.get_value("game", "timer", 30)
#		APPLY
		apply_audio_settings(sound_device, master, music, sfx, voiceover)
		apply_video_settings(display_type, resolution, input_display, theme)
		apply_game_settings(timer)
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

#region Apply Settings Methods
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
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master))
	%VolumeControl.set_value_no_signal(master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music))
	%VolumeControl2.set_value_no_signal(music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx))
	%VolumeControl3.set_value_no_signal(sfx)
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"), linear_to_db(voiceover))
	%VolumeControl4.set_value_no_signal(voiceover)

@warning_ignore("shadowed_variable_base_class")
func apply_video_settings(display_type: int, resolution: int, input_display: String, theme: String):
	%DisplayList.select(display_type)
	_on_display_list_item_selected(display_type)
	%ResolutionsList.select(resolution)
	_on_resolutions_list_item_selected(resolution)
	select_option_by_text(%InputDisplayList,input_display)
	select_option_by_text(%SessionThemesList,theme)
	update_game_state_theme(theme)


func apply_game_settings(timer: int):
	select_option_by_int(%TimerSettingList, timer)
	update_game_state(timer)
	return
#endregion


func update_game_state(timer: int):
	GameState.quizOptions.timer = timer

@warning_ignore("shadowed_variable_base_class")
func update_game_state_theme(theme: String):
	GameState.CurrentTheme = theme
	
func _refresh_profiles_dropdown():
	var profile_list = $Options_Profile/ProfileSettingsCase/DimensionFrame/CurrentProfileCase/ProfilesList
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

func _update_current_profile_label():
	var currentProfileLable = $Stack_0/ProfileButton/CurrentProfileLabel
	
	for key in UserProfiles.profiles.keys():
		if UserProfiles.profiles[key]["selected"]:
			currentProfileLable.text = UserProfiles.profiles[key]["name"]
			return
		pass
	
	if UserProfiles.profiles.size() > 0: 
		# if there are no profiles selected, mark the first profile in the list as selected
		UserProfiles.profiles[profiles_list_id_to_name[0]]["selected"] = true
		currentProfileLable.text = UserProfiles.profiles[profiles_list_id_to_name[0]]["name"]
		return
	
	# if there are no profiles, user placeholder Guest
	currentProfileLable.text = "Guest"
	pass
	

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_escape_game_menu()
		pass
	
	if show_award_hover and event is InputEventMouse:
		node_hover_text.set_position(get_viewport().get_mouse_position() + Vector2(20.0,0.0))
	pass


#region Button UX
func _on_play_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_play_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_play_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_play_button_button_up():
	if UserProfiles.profiles.size() > 0:
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
		get_node("Stack_0").hide()
		$StackAnimator.play("Anim_OptionsCategories_FadeIn")
		await get_tree().create_timer(0.1).timeout
		get_node("Options_2").show()
		$Options_2/OptionsCategories/DisplayButton.grab_focus()
		flag_options_menu = true


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
	await get_tree().create_timer(0.1).timeout
	get_node("Stack_0").hide()
	get_node("Options_Profile").show()
	flag_profiles_menu = true


func _on_dismiss_notif_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_dismiss_notif_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_dismiss_notif_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_dismiss_notif_button_pressed():
	$StackAnimator.play("Anim_Notif_Dismiss")


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
	await get_tree().create_timer(0.1).timeout
	get_node("Options_Profile").hide()
	get_node("Stack_0").show()
	flag_profiles_menu = false

func _on_profile_creator_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_creator_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_creator_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_profile_creator_button_button_up():
	get_node("Options_Profile/ProfileDestroyer").hide()
	get_node("Options_Profile/ProfileCreator").show()
	flag_profiles_menu_sub = true


func _on_profiles_list_item_selected(index):
	for key in UserProfiles.profiles.keys():
		UserProfiles.profiles[key]["selected"] = false
		pass
		
	UserProfiles.profiles[profiles_list_id_to_name[index]]["selected"] = true
	_update_current_profile_label()
	_update_profile_statistics()
	UserProfiles._IO_write_profiles()
	pass 



func _on_save_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_save_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_save_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_save_button_button_up():
		var new_profile_name = $Options_Profile/ProfileCreator/ProfileNamer/ProfileEntryField.text
		
		if new_profile_name == "": # returns if profile name is empty
			return	
		
		var new_profile = UserProfiles._new_profile(new_profile_name)
		
		UserProfiles._save_new_profile(new_profile)
		_refresh_profiles_dropdown()
		_update_current_profile_label()
		get_node("Options_Profile/ProfileCreator").hide()
		$Options_Profile/ProfileCreator/ProfileNamer/ProfileEntryField.text = ""
		flag_profiles_menu_sub = false
		pass
	
func _on_cancel_profile_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_cancel_profile_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_cancel_profile_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_cancel_profile_button_button_up():
	get_node("Options_Profile/ProfileCreator").hide()
	$Options_Profile/ProfileCreator/ProfileNamer/ProfileEntryField.text = ""
	flag_profiles_menu_sub = false

func _on_profile_deleter_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_deleter_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_profile_deleter_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_profile_deleter_button_button_up():
	get_node("Options_Profile/ProfileCreator").hide()
	$Options_Profile/ProfileCreator/ProfileNamer/ProfileEntryField.text = ""
	get_node("Options_Profile/ProfileDestroyer").show()
	flag_profiles_menu_sub = true
	
func _on_delete_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_delete_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_delete_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_delete_button_button_up():
	var profile_list = $Options_Profile/ProfileSettingsCase/DimensionFrame/CurrentProfileCase/ProfilesList
	if UserProfiles.profiles.size() < 1: # return if theres no profiles to delete
		return
		
	UserProfiles._delete_profile(profiles_list_id_to_name[profile_list.get_selected_id()])
	_refresh_profiles_dropdown()
	_update_current_profile_label()
	_update_profile_statistics()
	get_node("Options_Profile/ProfileDestroyer").hide()
	flag_profiles_menu_sub = false
	pass

func _on_cancel_deletion_button_mouse_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_cancel_deletion_button_focus_entered():
	$Stack_0/MainMenuButtons/SFX_Hover.play()
func _on_cancel_deletion_button_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_cancel_deletion_button_button_up():
	get_node("Options_Profile/ProfileDestroyer").hide()
	flag_profiles_menu_sub = false

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
	await get_tree().create_timer(0.1).timeout
	get_node("Options_2").hide()
	get_node("Stack_0").show()
	$Stack_0/MainMenuButtons/PlayButton.grab_focus()
	flag_options_menu = false

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
	await get_tree().create_timer(0.1).timeout
	get_node("Options_2").hide()
	get_node("Options_Display2").show()
	flag_options_menu_display = true

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
	await get_tree().create_timer(0.1).timeout
	get_node("Options_2").hide()
	get_node("Options_Sound2").show()
	flag_options_menu_sound = true


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
	await get_tree().create_timer(0.1).timeout
	get_node("Options_2").hide()
	get_node("Options_Game2").show()
	flag_options_menu_game = true

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
	await get_tree().create_timer(0.1).timeout
	$Options_2/OptionsCategories/DisplayButton.grab_focus()
	flag_options_menu_display = false

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
	await get_tree().create_timer(0.1).timeout
	get_node("Options_Sound2").hide()
	get_node("Options_2").show()
	$Options_2/OptionsCategories/SoundButton.grab_focus()
	flag_options_menu_sound = false


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
	await get_tree().create_timer(0.1).timeout
	get_node("Options_Game2").hide()
	get_node("Options_2").show()
	$Options_2/OptionsCategories/GameButton.grab_focus()
	flag_options_menu_game = false

func _on_filter_save_preset_button_button_up():
	_save_filter()

func _on_alphabetical_sort_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_alphabetical_sort_button_up():
	if current_sort == SortMode.ALPHA_ASCEND:
		current_sort = SortMode.ALPHA_DESCEND
	else:
		current_sort = SortMode.ALPHA_ASCEND
	sort_tags(filter_tag_selectors)
func _on_count_sort_button_down():
	$Stack_0/MainMenuButtons/SFX_Press.play()
func _on_count_sort_button_up():
	if current_sort == SortMode.VALUE_ASCEND:
		current_sort = SortMode.VALUE_DESCEND
	else:
		current_sort = SortMode.VALUE_ASCEND
	sort_tags(filter_tag_selectors)
	
func _on_delete_preset_button_button_up():
	_delete_filter()
	
func _on_filter_selected(index):
	var ui_filter_selector:OptionButton = $Options_Game2/SettingsList/FiltersCase/FilterContainers/ColumnAlignment/LoadPresetFields/FilterPresetList
	filter_selected_key = ui_filter_selector.get_item_text(index)
	for i in range(GameState.TagsFilters.size()):
		if ui_filter_selector.get_item_text(i) != filter_selected_key:
			GameState.TagsFilters[ui_filter_selector.get_item_text(i)]["selected"] = false
	_load_filter()
	
func _on_clear_filters_button_button_up():
	_UI_reset_filter_tag_buttons()
	_UI_toggle_blacklist_button()
	
func _on_filter_whitelist_toggle_button_up():
	var blacklist_btn = $Options_Game2/SettingsList/FiltersCase/WhitelistToggle
	_UI_toggle_blacklist_button(blacklist_btn["button_pressed"])
#endregion

#region tag filter functions
##initilizes the filter ui
func _init_filter_ui():
	GameState._IO_read_tags_filter()
	GameState._build_complete_tags_list()
	_UI_load_filter_tag_buttons()
	_UI_load_filter_selector()
	_load_filter()

func _UI_load_filter_selector():
	var ui_filter_selector:OptionButton = $Options_Game2/SettingsList/FiltersCase/FilterContainers/ColumnAlignment/LoadPresetFields/FilterPresetList
	ui_filter_selector.clear()
	var filter_selected = false
	for filter in GameState.TagsFilters:
		ui_filter_selector.add_item(filter)
	for i in range(GameState.TagsFilters.size()):
		if GameState.TagsFilters[ui_filter_selector.get_item_text(i)]["selected"] and not filter_selected:
			ui_filter_selector.select(i)
			filter_selected_key = ui_filter_selector.get_item_text(i)
			filter_selected = true
		else:
			GameState.TagsFilters[ui_filter_selector.get_item_text(i)]["selected"] = false
	
	# select the first index if there is no filter selected in file
	if not filter_selected and GameState.TagsFilters.size() > 0:
		ui_filter_selector.select(0)
		filter_selected_key = ui_filter_selector.get_item_text(0)
	# if there are no filters to select, set to default
	elif not filter_selected:
		filter_selected_key = "Default"
		ui_filter_selector.add_item("Default")

## iterates through a list of all existing tags, 
## and and creates new nodes to represent them using checkbox buttons in the filter container
func _UI_load_filter_tag_buttons(): 
	var ui_filter_container = $Options_Game2/SettingsList/FiltersCase/FilterContainers/ScrollCase/FilterContainer
	for child in ui_filter_container.get_children():
		child.queue_free()
	filter_tag_selectors.clear()
	
	for tag in GameState.tags_list:
		var new_tag = CheckBox.new()
		new_tag.text = tag
		new_tag.flat = true
		new_tag.toggle_mode = true
		
		new_tag.theme = tags_list_theme
		new_tag.add_theme_font_size_override("font_size", 16)
		
		#new_tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		new_tag.set_meta("tag_ref", tag)
		ui_filter_container.add_child(new_tag)
		filter_tag_selectors.append(new_tag)
	current_sort = SortMode.ALPHA_ASCEND
	sort_tags(filter_tag_selectors)

func sync_ui_tag_order() -> void:
	var ui_filter_container = $Options_Game2/SettingsList/FiltersCase/FilterContainers/ScrollCase/FilterContainer
	for i in range(filter_tag_selectors.size()):
		var target_tag_text = filter_tag_selectors[i].text
		# find the child tagged with this entry
		for child in ui_filter_container.get_children():
			if child.get_meta("tag_ref") == target_tag_text:
				ui_filter_container.move_child(child, i)
				break

## sets all of the buttons in the filter container to unpressed
func _UI_reset_filter_tag_buttons():
	for i in range(filter_tag_selectors.size()):
		filter_tag_selectors[i]["button_pressed"] = false

## sets the toggle state of the tag buttons
func _UI_set_filter_tag_buttons(selected_tags = {}):
	for i in range(filter_tag_selectors.size()):
		filter_tag_selectors[i]["button_pressed"] = filter_tag_selectors[i].text.to_lower() in selected_tags

## toggles the ui state for the filter creators, blacklist button
## defaults to true, as an empty blacklist filters out no questions
## as opposed to an empty whitelist which filters out all questions
func _UI_toggle_blacklist_button(is_blacklist:bool = true):
	var ui_blacklist_btn:Button = $Options_Game2/SettingsList/FiltersCase/WhitelistToggle
	if is_blacklist:
		ui_blacklist_btn.text = "Blacklist: True"
		ui_blacklist_btn["button_pressed"] = true
	else:
		ui_blacklist_btn.text = "Blacklist: False"
		ui_blacklist_btn["button_pressed"] = false

enum SortMode { ALPHA_ASCEND, ALPHA_DESCEND, VALUE_ASCEND, VALUE_DESCEND }

var current_sort: SortMode = SortMode.ALPHA_ASCEND

func sort_tags(arr: Array) -> void:
	match current_sort:
		SortMode.ALPHA_ASCEND:
			arr.sort_custom(func(a, b): return a["text"].to_lower() < b["text"].to_lower())
		SortMode.ALPHA_DESCEND:
			arr.sort_custom(func(a, b): return a["text"].to_lower() > b["text"].to_lower())
		SortMode.VALUE_ASCEND:
			return; #no opp until counts are loaded
			#arr.sort_custom(func(a, b): return a["value"] < b["value"])
		SortMode.VALUE_DESCEND:
			return; #no opp until counts are loaded
			#arr.sort_custom(func(a, b): return a["value"] > b["value"])
	sync_ui_tag_order()

# load a filter's settings using the filter_selected_key
func _load_filter():
	if filter_selected_key in GameState.TagsFilters:
		var filter = GameState.TagsFilters[filter_selected_key]
		_UI_set_filter_tag_buttons(filter["tags"])
		_UI_toggle_blacklist_button(filter["blacklist"])
		$Options_Game2/SettingsList/FiltersCase/FilterContainers/ColumnAlignment/SavePresetFields/PresetNameField.text = filter_selected_key
	else:
		_UI_reset_filter_tag_buttons()
		_UI_toggle_blacklist_button()

func _save_filter():
	# only save if the entry name is not blank
	var filter_name = $Options_Game2/SettingsList/FiltersCase/FilterContainers/ColumnAlignment/SavePresetFields/PresetNameField.text
	if filter_name != "":
		var blacklist_btn = $Options_Game2/SettingsList/FiltersCase/WhitelistToggle
		var is_blacklist = blacklist_btn["button_pressed"]
		var tags = []
	
		for i in range(filter_tag_selectors.size()):
			if filter_tag_selectors[i]["button_pressed"]:
				tags.append(filter_tag_selectors[i].text.to_lower())
		
		GameState.TagsFilters[filter_name] = {}
		GameState.TagsFilters[filter_name]["blacklist"] = is_blacklist
		GameState.TagsFilters[filter_name]["tags"] = tags
		for filter in GameState.TagsFilters:
			GameState.TagsFilters[filter]["selected"] = false
		GameState.TagsFilters[filter_name]["selected"] = true
		GameState._IO_write_tags_filter()
		
		filter_selected_key = filter_name
		_UI_load_filter_selector()
		_load_filter()
	
func _delete_filter():
	GameState.TagsFilters.erase(filter_selected_key)
	GameState._IO_write_tags_filter()
	filter_selected_key = ""
	_UI_load_filter_selector()
	_load_filter()

#endregion

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

func _on_sound_device_options_item_selected(index: int) -> void:
	AudioServer.set_output_device(%SoundDeviceOptions.get_item_text(index))

## backs out of nested menus, handles both the options and profiles menus
func _escape_game_menu():
	if flag_options_menu:
		if flag_options_menu_display:
			get_node("Options_Display2").hide()
			get_node("Options_2").show()
			$StackAnimator.play("Anim_OptionsCategories_FadeIn")	
			await get_tree().create_timer(0.1).timeout
			$Options_2/OptionsCategories/DisplayButton.grab_focus()
			flag_options_menu_display = false
			save_video_settings()
			return
		if flag_options_menu_sound:
			$StackAnimator.play("Anim_OptionsCategories_FadeIn")
			await get_tree().create_timer(0.1).timeout
			get_node("Options_Sound2").hide()
			get_node("Options_2").show()
			$Options_2/OptionsCategories/SoundButton.grab_focus()
			flag_options_menu_sound = false
			save_audio_settings()
			return
		if flag_options_menu_game:
			$StackAnimator.play("Anim_OptionsCategories_FadeIn")
			await get_tree().create_timer(0.1).timeout
			get_node("Options_Game2").hide()
			get_node("Options_2").show()
			$Options_2/OptionsCategories/GameButton.grab_focus()
			flag_options_menu_game = false
			save_game_settings()
			return
		$StackAnimator.play("Anim_Stack0_FadeIn")
		await get_tree().create_timer(0.1).timeout
		get_node("Options_2").hide()
		get_node("Stack_0").show()
		$Stack_0/MainMenuButtons/PlayButton.grab_focus()
		flag_options_menu = false
		return
	pass

	if flag_profiles_menu:
		if flag_profiles_menu_sub:
			get_node("Options_Profile/ProfileCreator").hide()
			$Options_Profile/ProfileCreator/ProfileNamer/ProfileEntryField.text = ""
			get_node("Options_Profile/ProfileDestroyer").hide()
			return
		$StackAnimator.play("Anim_Stack0_FadeIn")
		await get_tree().create_timer(0.1).timeout
		get_node("Options_Profile").hide()
		get_node("Stack_0").show()
		flag_profiles_menu = false
	pass

#region functions for displaying profile statistics
func _update_profile_statistics():
	var questions_correct = 0
	var questions_seen = 0
	var percentage_correct = 0
	
	# in the case that there are no profiles at all
	if UserProfiles.profiles.size() < 1:
		# correct answers
		$Options_Profile/ProfileStatsCase/HBoxContainer/ProfileUniqueAnswerCounter.text = "0/0"
		# answer accuracy
		$Options_Profile/ProfileStatsCase/HBoxContainer2/ProfileAnswerAccuracyCounter.text = "N/A"
		# Highest Score
		$Options_Profile/ProfileStatsCase/HBoxContainer3/ProfileHighestScoreCounter.text = "0"
		# lowest Score
		$Options_Profile/ProfileStatsCase/HBoxContainer4/ProfileLowestScoreCounter.text = "0"
		_update_profile_awards()
		return
	
	var selectedProfile = UserProfiles.profiles[UserProfiles._get_selected_profile_key()]
	
	for key in selectedProfile["questions_answered"]:
		questions_correct += selectedProfile["questions_answered"][key]
	for key in selectedProfile["questions_seen"]:
		questions_seen += selectedProfile["questions_seen"][key]

	if questions_seen != 0:
		percentage_correct = "%0.1f%%" % (100*(questions_correct / questions_seen))
	else:
		percentage_correct = "N/A"
	
	# correct answers
	$Options_Profile/ProfileStatsCase/HBoxContainer/ProfileUniqueAnswerCounter.text = "%s/%s" % [questions_correct, questions_seen]
	# answer accuracy
	$Options_Profile/ProfileStatsCase/HBoxContainer2/ProfileAnswerAccuracyCounter.text = "%s" % percentage_correct
	# Highest Score
	$Options_Profile/ProfileStatsCase/HBoxContainer3/ProfileHighestScoreCounter.text = "%s" % selectedProfile["score_highest"]
	# lowest Score
	$Options_Profile/ProfileStatsCase/HBoxContainer4/ProfileLowestScoreCounter.text = "%s" % selectedProfile["score_lowest"]
	_update_profile_awards()
	pass
	
func _update_profile_awards():
	var node_awards_case = $Options_Profile/AwardsSection/AwardsCase
	# remove any previous awards
	for node in node_awards_case.get_children():
		node_awards_case.remove_child(node)
		node.queue_free()
	
	if UserProfiles.profiles.size() < 1:
		return # just return if there is no profile
		
	var selectedProfile = UserProfiles.profiles[UserProfiles._get_selected_profile_key()]
	
	for key in selectedProfile["questions_chances"]:
		create_new_award(key)
		
	pass
	
## creates new nodes that represent a single chance using the chances hash id
func create_new_award(awardHash: String):
	if !UserProfiles._has_chance_hash(awardHash):
		print("!Warning: Award Hash:[\"%s\"]" % awardHash)
		return
	
	var node_awards_case = get_node("Options_Profile/AwardsSection/AwardsCase")
	var node_texture = TextureRect.new()
	var node_label = Label.new()
	var node_label_settings = LabelSettings.new()
	var node_vbox_container = VBoxContainer.new()
	
	var award_texture = load(UserProfiles.chance_descriptors[awardHash]["icon"])
	
	node_label_settings.outline_size = 4
	node_label_settings.outline_color = _select_award_outline_color(UserProfiles.chance_descriptors[awardHash]["type"])
	node_label_settings.font_size = 20
	
	node_label.text = UserProfiles.chance_descriptors[awardHash]["name"]
	node_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node_label.label_settings = node_label_settings
	
	
	node_texture.texture = award_texture
	node_texture.custom_minimum_size = Vector2(128, 128)
	node_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node_texture.stretch_mode = TextureRect.STRETCH_SCALE
	
	#TODO: add hover text to award texture containing detailed description
	node_texture.mouse_entered.connect(
		func(): 
			node_hover_text.text = UserProfiles.chance_descriptors[awardHash]["description"]
			node_hover_text.set_position(get_viewport().get_mouse_position())
			show_award_hover = true
			node_hover_text.show()
			)
	node_texture.mouse_exited.connect(
		func(): 
			show_award_hover = false
			node_hover_text.text = ""
			node_hover_text.hide()
			)
	
	
	node_vbox_container.add_child(node_texture)
	node_vbox_container.add_child(node_label)
	
	node_awards_case.add_child(node_vbox_container)
	pass
	
func _select_award_outline_color(awardType: String):
	if awardType == "QUESTION":
		return "2200bb"
	return "000000"

func _create_hover_text_node():
	var node_lable_settings = LabelSettings.new()
	var node_style_box = StyleBoxFlat.new()
	node_hover_text = Label.new()
	
	node_style_box.set_border_width_all(5)
	node_style_box.border_color = "313131"
	node_style_box.bg_color = "212121"
	
	node_lable_settings.font_size = 18
	
	node_hover_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node_hover_text.label_settings = node_lable_settings
	node_hover_text.text = ""
	node_hover_text.set_size(Vector2(200.0,20.0))
	node_hover_text.add_theme_stylebox_override("normal", node_style_box)
	node_hover_text.hide()
	
	get_tree().root.add_child(node_hover_text)
#endregion
