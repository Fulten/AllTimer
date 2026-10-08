extends Control

#region refrences to quiz ui elements
@onready var ui_questions_name = $quizInterface/session_organizer/question_header/question_name
@onready var ui_questions_index = $quizInterface/session_organizer/question_header/question_index
@onready var ui_countdown_timer = $quizInterface/session_organizer/question_header/Countdown
@onready var ui_prequestion_timer = $quizInterface/session_organizer/question_header/Prequestion_timer
@onready var ui_postquestion_timer = $quizInterface/session_organizer/question_header/Postquestion_timer
@onready var ui_countdown_text = $quizInterface/session_organizer/CountdownLabel
@onready var ui_questions_body = $quizInterface/session_organizer/question_body
@onready var ui_post_question = $quizInterface/post_question
@onready var ui_players = [
	$quizInterface/players_region/activePlayer1/player_case,
	$quizInterface/players_region/activePlayer2/player_case,
	$quizInterface/players_region/activePlayer3/player_case,
	$quizInterface/players_region/activePlayer4/player_case]
@onready var ui_multiple_choice_answers = [
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair1/a1,
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair2/a2,
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair3/a3,
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair4/a4]

@onready var ui_this_or_that_answers = [
	$quizInterface/session_organizer/CenteredAnswerCategories/ThisOrThat/This/Cat1Button,
	$quizInterface/session_organizer/CenteredAnswerCategories/ThisOrThat/That/Cat2Button
]

@onready var ui_player_names = [
	$quizInterface/players_region/activePlayer1/player_case/player_name,
	$quizInterface/players_region/activePlayer2/player_case/player_name,
	$quizInterface/players_region/activePlayer3/player_case/player_name,
	$quizInterface/players_region/activePlayer4/player_case/player_name]
@onready var ui_player_scores = [
	$quizInterface/players_region/activePlayer1/player_case/status_row/score,
	$quizInterface/players_region/activePlayer2/player_case/status_row/score,
	$quizInterface/players_region/activePlayer3/player_case/status_row/score,
	$quizInterface/players_region/activePlayer4/player_case/status_row/score]
@onready var ui_question_answer_buttons = [
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair1/a1,
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair2/a2,
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair3/a3,
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair4/a4]
	
var surprize_styleBs_a1 = [
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_AAH.tres"),
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_AAN.tres"),
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_AAP.tres")
]
var surprize_styleBs_a2 = [
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_ABH.tres"),
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_ABN.tres"),
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_ABP.tres")
]
var surprize_styleBs_a3 = [
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_ACH.tres"),
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_ACN.tres"),
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_ACP.tres")
]
var surprize_styleBs_a4 = [
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_ADH.tres"),
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_ADN.tres"),
	load("res://assets/uiux/session_themes/Fatal Surprise/surprise_ADP.tres")
]

var asset_player_pannel_locked
var asset_player_pannel_default
#endregion

#region global variables
var master_chances_data = []
var master_question_data = []
var filtered_question_data = []
var chances_set = {}

#signals
signal sig_end_of_quiz
signal sig_exit_quiz

#quiz phase delays
var pre_question_delay_default = 3.0
var post_question_delay_default = 5.0

var config_path = "user://settings.cfg"
var config = ConfigFile.new()
var menu_location = MENU.noMenu

# question and chances stuff
var QuestionDataFile = "res://data/question_data.json"
var CurrentQuizQuestions = [] #The questions to be used in the current quiz
var CurrentQuestionIndex = 0 #The index of question currently on in quiz

var questions = {}
var tags_list = {}

var TagsFilterFile = "user://quiz_filters.json"
var TagsFilters = {}

var CurrentChances = [] #The list of chance stars to track for the game


enum MENU {
	noMenu = 0,
	pauseMenu = 1,
	optionsMenu = 2,
	subMenuSound = 3,
	subMenuDisplay = 4,
}

#endregion


func _ready():
	_load_config_settings()
	menu_location = MENU.noMenu
	_pause_menu_update_graphics()
	
	if multiplayer.is_server():
		$pauseScreen/pauseCase/pauseBase/quitButton.text = "lobby"

	
func _proccess():
	pass

func _input(event):
	# opens game menu locally on client
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_escape_game_menu()
		pass
		
	# ignore input until quiz starts
	if !GameState._game_started():
		return
		
	#TODO:include debug key to advance to next question

#region rpc functions
@rpc("authority", "call_local", "reliable")
func _server_ending_quiz():
	GameState._reset_quiz_state()
	sig_end_of_quiz.emit()
	queue_free()
	

func _player_dropped():
	
	pass
#endregion

#region quiz setup functions
func _host_setup_quiz():
	pass

func _client_setup_quiz():
	pass
#endregion

#region scoreing functions

#endregion

#region Pause Menu Functionality
func _client_disconnect_from_server():
	GameState._reset_quiz_state()
	sig_exit_quiz.emit()
	queue_free()

func select_option_by_text(option_button: OptionButton, target_text: String) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == str(target_text):
			option_button.select(i)
			return
	print("Warning: Text not found in OptionButton:", target_text)
	
## when called backs out to the previous menu, if in no menu opens the "pause" menu
func _escape_game_menu():
	match menu_location:
		MENU.noMenu:
			menu_location = MENU.pauseMenu
		MENU.pauseMenu:
			menu_location = MENU.noMenu
		MENU.optionsMenu:
			menu_location = MENU.pauseMenu
		MENU.subMenuSound:
			menu_location = MENU.optionsMenu
			_save_sound_settings()
		MENU.subMenuDisplay:
			menu_location = MENU.optionsMenu
			_save_display_settings()
	_pause_menu_update_graphics()

func _pause_menu_update_graphics():
	match menu_location:
		MENU.noMenu:
			$pauseScreen.hide()
		MENU.pauseMenu:
			$pauseScreen.show()
			$pauseScreen/pauseCase/pauseBase.show()
			$pauseScreen/pauseCase/pauseOptions.hide()
			$pauseScreen/pauseCase/pauseSound.hide()
			$pauseScreen/pauseCase/pauseDisplay.hide()
		MENU.optionsMenu:
			$pauseScreen.show()
			$pauseScreen/pauseCase/pauseBase.hide()
			$pauseScreen/pauseCase/pauseOptions.show()
			$pauseScreen/pauseCase/pauseSound.hide()
			$pauseScreen/pauseCase/pauseDisplay.hide()
		MENU.subMenuSound:
			$pauseScreen.show()
			$pauseScreen/pauseCase/pauseBase.hide()
			$pauseScreen/pauseCase/pauseOptions.hide()
			$pauseScreen/pauseCase/pauseSound.show()
			$pauseScreen/pauseCase/pauseDisplay.hide()
		MENU.subMenuDisplay:
			$pauseScreen.show()
			$pauseScreen/pauseCase/pauseBase.hide()
			$pauseScreen/pauseCase/pauseOptions.hide()
			$pauseScreen/pauseCase/pauseSound.hide()
			$pauseScreen/pauseCase/pauseDisplay.show()

func _on_resume_button_mouse_entered():
	$SFX_Hover1.play()
func _on_resume_button_focus_entered():
	$SFX_Hover1.play()
func _on_resume_button_button_down():
	$SFX_Press.play()
func _on_resume_button_button_up():
	_escape_game_menu()

func _on_options_button_focus_entered():
	$SFX_Hover2.play()
func _on_options_button_mouse_entered():
	$SFX_Hover2.play()
func _on_options_button_button_down():
	$SFX_Press.play()
func _on_options_button_button_up():
	menu_location = MENU.optionsMenu
	_pause_menu_update_graphics()

func _on_quit_button_focus_entered():
	$SFX_Hover3.play()
func _on_quit_button_mouse_entered():
	$SFX_Hover3.play()
func _on_quit_button_button_down():
	$SFX_Press.play()
func _on_quit_button_button_up():
	# if server exit to multiplayer lobby
	if multiplayer.is_server():
		_server_ending_quiz.rpc()
	# if client, exit multiplayer session and return to main menu
	else: 
		_client_disconnect_from_server()

func _on_options_back_button_focus_entered():
	$SFX_Hover3.play()
func _on_options_back_button_mouse_entered():
	$SFX_Hover3.play()
func _on_options_back_button_button_down():
	$SFX_Press.play()
func _on_options_back_button_button_up():
	_escape_game_menu()

func _on_sound_button_focus_entered():
	$SFX_Hover1.play()
func _on_sound_button_mouse_entered():
	$SFX_Hover1.play()
func _on_sound_button_button_down():
	$SFX_Press.play()
func _on_sound_button_button_up():
	menu_location = MENU.subMenuSound
	_pause_menu_update_graphics()

func _on_sound_back_button_focus_entered():
	$SFX_Hover3.play()
func _on_sound_back_button_mouse_entered():
	$SFX_Hover3.play()
func _on_sound_back_button_button_down():
	$SFX_Press.play()
func _on_sound_back_button_button_up():
	_escape_game_menu()

func _on_display_button_focus_entered():
	$SFX_Hover2.play()
func _on_display_button_mouse_entered():
	$SFX_Hover2.play()
func _on_display_button_button_down():
	$SFX_Press.play()
func _on_display_button_button_up():
	menu_location = MENU.subMenuDisplay
	_pause_menu_update_graphics()

func _on_display_back_button_focus_entered():
	$SFX_Hover3.play()
func _on_display_back_button_mouse_entered():
	$SFX_Hover3.play()
func _on_display_back_button_button_down():
	$SFX_Press.play()
func _on_display_back_button_button_up():
	_escape_game_menu()

func _load_config_settings():
	var err = config.load(config_path)
	if err == OK:
		# AUDIO
		var sound_device = config.get_value("audio", "sound_device", "default")
		var master = config.get_value("audio", "master", 1.0)
		var music = config.get_value("audio", "music", 1.0)
		var sfx = config.get_value("audio", "sfx", 1.0)
		var voiceover = config.get_value("audio", "voiceover", 1.0)
		# VIDEO
		var display_type = config.get_value("video", "type", 0)
		var resolution = config.get_value("video", "resolution", 0)
		var input_display = config.get_value("video", "input", "default")
		@warning_ignore("shadowed_variable_base_class")
		var theme = config.get_value("video", "theme", "default")
		# APPLY
		_apply_audio_settings(sound_device, master, music, sfx, voiceover)
		_apply_video_settings(display_type, resolution, input_display, theme)
	else:
		print("!!ERROR: load config settings failed Reason: [%s]" % err)

## Sound Options
func _on_sound_device_options_item_selected(index: int) -> void:
	AudioServer.set_output_device(%SoundDeviceOptions.get_item_text(index))

func _apply_audio_settings(sound_device: String, master: float, music: float, sfx: float, voiceover: float):
	%VolumeControl.set_value_no_signal(master)
	%VolumeControl2.set_value_no_signal(music)
	%VolumeControl3.set_value_no_signal(sfx)
	%VolumeControl4.set_value_no_signal(voiceover)
		
	var devices = AudioServer.get_output_device_list()
	%SoundDeviceOptions.clear()
	for device in devices:
		%SoundDeviceOptions.add_item(device)
		if sound_device == device:
			select_option_by_text(%SoundDeviceOptions, sound_device)

func _save_sound_settings():
	config.set_value("audio", "sound_device", %SoundDeviceOptions.get_item_text(%SoundDeviceOptions.get_selected_id()))
	config.set_value("audio", "master", %VolumeControl.get_value())
	config.set_value("audio", "music", %VolumeControl2.get_value())
	config.set_value("audio", "sfx", %VolumeControl3.get_value())
	config.set_value("audio", "voiceover", %VolumeControl4.get_value())
	config.save(config_path)

## Display Options
func _apply_video_settings(display_type: int, resolution: int, input_display: String, _theme: String):
	%DisplayList.select(display_type)
	%ResolutionsList.select(resolution)
	select_option_by_text(%InputDisplayList,input_display)

func _save_display_settings():
	config.set_value("video", "type", %DisplayList.get_selected_id())
	config.set_value("video", "resolution", %ResolutionsList.get_selected_id())
	config.set_value("video", "input", %InputDisplayList.get_item_text(%InputDisplayList.get_selected_id()))
	config.save(config_path)

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
#endregion
