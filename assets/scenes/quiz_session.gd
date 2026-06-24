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

var local_question_set_uuids = []

signal end_of_quiz
signal exit_quiz

var QUIZ_SIZE = 10
var CHANCE_COUNT = 3

var flag_DEBUG = true

var flag_pre_quiz_rules = false
var pre_question_delay_default = 3.0
var flag_pre_question_time = false
var post_question_delay_default = 5.0
var flag_post_question_time = false

var current_index = 0
var correct_answer = 0
var loaded = false
var players_answered = 0
var player_input = "p_answer_%s"
var flag_accept_input = false

var player_statuses_ui_2d: Array[Array]

var flag_game_menu_shown = false
var flag_in_options_menu = false
var flag_in_options_submenu = false

var local_clock_reading = [0,0]
var local_answer_order = [0, 1, 2, 3]

var QuizEndScreen = false

var config_path = "user://settings.cfg"
var config = ConfigFile.new()

# variables for score rollup animation
var rollup_count = 0

var selectedTagsFilter
var useTagFilter = false

#endregion

##Called when the node enters the scene tree for the first time.
##primarily used by the server to setup the quiz session
func _ready():
	_reset_question_rules_visibility()
	_set_theme_specific_graphics()
	_load_config_settings()
	_select_music_track()
	
	if multiplayer.is_server():
		$pauseScreen/pauseCase/pauseBase/quitButton.text = "lobby"
		QUIZ_SIZE = GameState.quizOptions.win_questions
		_select_tags_filter()
		_load_quiz_data()
		_select_quiz_questions(QUIZ_SIZE)
		_prepare_quiz_chances(CHANCE_COUNT)
		_store_quiz_questions_locally()
		GameState._build_player_number_to_id_table()
		_sync_server_client_data.rpc(local_question_set_uuids, GameState.playerNumberToIds)
		_sync_server_client_game_rules.rpc(
			GameState.quizOptions.timer, 
			"Highest score after 10 questions", 
			0,  # cut feature, always use "highest score after x question"
			10, # 10 questions
			GameState.quizOptions.win_points)
		_clean_master_questions()
		_clean_chance_set_and_master()
		_generate_answer_order()
		_sync_answer_order.rpc(local_answer_order)
		if GameState.CurrentQuizQuestions[current_index]["questionType"] == "True/False":
			_ui_present_question_true_false.rpc()
		elif GameState.CurrentQuizQuestions[current_index]["questionType"] == "This/That":
			_ui_present_question_this_that.rpc()
		else:
			_ui_present_question_multiple_choice.rpc()
		_player_loaded(multiplayer.get_unique_id())
		print("server [%s] loaded" % multiplayer.get_unique_id())
		pass
	pass

func _process(_delta):
	if GameState.GameStarted:
		if multiplayer.is_server():
			if flag_pre_question_time:
				local_clock_reading = pre_question_clock()
			elif flag_post_question_time:
				local_clock_reading = post_question_clock()
			else:
				local_clock_reading = countdown_clock()
			_sync_server_client_clock_reading.rpc(local_clock_reading)
			_load_question_refresh_scores()
			ui_countdown_text.text = "%02d:%02d" % local_clock_reading
			pass
		else:
			_load_question_refresh_scores()
			ui_countdown_text.text = "%02d:%02d" % local_clock_reading
			pass
		pass
	pass

func _input(event):
	# ignore input until quiz starts
	if !GameState.GameStarted:
		return
	# opens game menu locally on client
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_escape_game_menu()
		pass
	
	if (flag_DEBUG and multiplayer.is_server() and !flag_pre_quiz_rules) and (event is InputEventKey and event.pressed and event.keycode == KEY_P):
		_debug_advance_to_next_question()
		pass	
	
	for i in range(4):
		if event.is_action_pressed(player_input % i):
			if current_index >= GameState.CurrentQuizQuestions.size():
				return # ignore answer input after quiz has ended
			#if we're a "this or that" or a "true/false" question ingnore input from 3 or 4
			var questionType = GameState.CurrentQuizQuestions[current_index]["questionType"]
			if (questionType == "True/False" or questionType == "This/That") and i > 1:
				continue
			if multiplayer.is_server(): # call locally if server
				_player_guess(1, i)
				pass
			else: #send guess to server
				_player_guess.rpc_id(1, multiplayer.get_unique_id(), i)
				pass
			pass
	pass

#region RPC functions used by the server to communicate with clients
##RPC: called by the server when it wants to sync the quiz timer clock between server and clients
@rpc("any_peer", "reliable")
func _sync_server_client_clock_reading(server_clock):
	local_clock_reading = server_clock
	pass
	
##RPC: called by the server host on clients to send question and chance data to peers
@rpc("authority", "reliable")
func _sync_server_client_data(question_set_uuids, playerNumToIds):
	_load_quiz_data()
	GameState.playerNumberToIds = playerNumToIds
	
	var i = 0
	for questionUuid in question_set_uuids:
		var questionIndex = -1
		
		for k in range(master_question_data.size()):
			if master_question_data[k]["uuid"] == questionUuid:
				questionIndex = k
				break
			pass
		
		GameState.CurrentQuizQuestions.append(_next_question_data_and_store_chances(i, questionIndex))
		i += 1
		pass
	
	_clean_master_questions()
	_clean_chance_set_and_master()
	_player_loaded.rpc_id(1, multiplayer.get_unique_id())
	pass
	
@rpc("authority", "reliable")
func _sync_server_client_game_rules(
	i_timer: int, 
	i_win_con: String, 
	i_win_con_int: int, 
	i_win_questions: int, 
	i_win_points: int):
		
	GameState.quizOptions.timer = i_timer
	GameState.quizOptions.win_con = i_win_con
	GameState.quizOptions.win_con_int = i_win_con_int

	GameState.quizOptions.win_questions = i_win_questions
	GameState.quizOptions.win_points = i_win_points
	pass

@rpc("authority", "reliable")
func _sync_answer_order(server_answer_order):
	local_answer_order = server_answer_order
	pass
	
@rpc("authority", "reliable")
func _start_quiz_client():
	GameState._reset_players()
	for i in range(GameState.PlayerCount):
		var player = GameState.players[GameState.playerNumberToIds[i]]
		ui_player_names[i].text = player["name"]
		ui_player_scores[i].text = str(player["score"])
		ui_players[i].visible = true
		pass
	
	GameState.GameStarted = true
	pass
	
@rpc("authority", "reliable")
func _sync_update_question_on_clients(question_index):
	current_index = question_index
	loaded = false
	pass
	
@rpc("authority", "reliable", "call_local")
func _sync_update_scores_on_clients(scores, last_scores):
	for key in scores.keys():
		GameState.players[key]["score"] = scores[key]
		GameState.players[key]["last_score"] = last_scores[key]
		pass
	rollup_count = 10
	_local_score_rollup()
	pass

@rpc("authority", "call_local", "reliable")
func _show_end_of_quiz_screen():
	ui_countdown_timer.stop()
	QuizEndScreen = true
	
	## add score from chances
	for key in GameState.players:
		var chance_bonus = 0
		for chanceKey in GameState.players[key]["chances"].keys():
			chance_bonus += GameState._get_chance_from_uuid(chanceKey)["bonus"]
		GameState.players[key].score += chance_bonus
	
	var scoreOrder = []
	
	for n in range(4):
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer" % (n + 1)).hide()
		pass
	
	for key in GameState.players.keys():
		scoreOrder.append(key)
		pass
		
	# create an index of the player entries thats sorted based on score
	for n in range(GameState.PlayerCount):
		var highestScore = GameState.players[scoreOrder[n]].score
		var indexOfHighest = n
		var swapTemp
		
		for i in range(n, GameState.PlayerCount):
			if GameState.players[scoreOrder[i]].score > highestScore:
				highestScore = GameState.players[scoreOrder[i]].score
				indexOfHighest = i
				pass
			pass
		
		swapTemp = scoreOrder[n]
		scoreOrder[n] = scoreOrder[indexOfHighest]
		scoreOrder[indexOfHighest] = swapTemp
		pass
	
	for n in range(GameState.PlayerCount):
		var uiNum = n + 1
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/MedalCase/Awards" % uiNum)["text"] = "N/A"
		pass
		
	for n in range(GameState.PlayerCount):
		var uiNum = n + 1
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/Name" % uiNum).text = GameState.players[scoreOrder[n]].name
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/ScoreDisplay/Score" % uiNum).text = "%s" % GameState.players[scoreOrder[n]].score
		
		var chanceStr = ""
		for chanceKey in GameState.players[scoreOrder[n]]["chances"].keys():
			chanceStr += "%s, " % (GameState._get_chance_from_uuid(chanceKey)["name"])
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/MedalCase/Awards" % uiNum)["text"] = chanceStr
		
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer" % uiNum).show()
		pass
	
	$ControlSwapper0.play("QuizFinish")
	pass

@rpc("authority", "call_local", "reliable")
func _end_quiz():
	get_node("quizEnd/PlayerStandingsOrg/1Placer").hide()
	get_node("quizEnd/PlayerStandingsOrg/2Placer").hide()
	get_node("quizEnd/PlayerStandingsOrg/3Placer").hide()
	get_node("quizEnd/PlayerStandingsOrg/4Placer").hide()
	$quizInterface.show()
	$quizEnd.hide()
	QuizEndScreen = false
	GameState._reset_quiz_state()
	end_of_quiz.emit()
	queue_free()
	pass

@rpc("authority", "reliable", "call_local")
##RPC: accepts a bool, and tells the clients and server to switch all player pannels between the locked and unlocked states
func _update_ui_player_pannel_locked_all(lock: bool):
	for i in range(GameState.PlayerCount):
		_update_ui_player_pannel_locked(lock, GameState.playerNumberToIds[i])
		pass
	pass

@rpc("authority", "reliable", "call_local")
##RPC: accepts a bool, and tells the clients and server to switch a given player's pannel between the locked and unlocked states
func _update_ui_player_pannel_locked(lock: bool, in_playerId):
	var UIPlayerEntry = 0
	for i in range(GameState.PlayerCount):
		if GameState.playerNumberToIds[i] == in_playerId:
			UIPlayerEntry = i + 1
			break
		pass
	
	if lock:
		get_node("quizInterface/players_region/activePlayer%s/player_case/player_name" % UIPlayerEntry).set_label_settings(asset_player_pannel_locked)
		pass
	else:
		get_node("quizInterface/players_region/activePlayer%s/player_case/player_name" % UIPlayerEntry).set_label_settings(asset_player_pannel_default)
		pass
	pass

##RPC: sends player statistics to clients and save them 
@rpc("authority", "reliable", "call_local")
func _sync_and_save_client_profile_statistics(playersData):
	#gets the data only for the local player
	var profileData = playersData[multiplayer.get_unique_id()]
	var gameScore = GameState.players[multiplayer.get_unique_id()].score
	
	if profileData["score_highest"] < gameScore:
		profileData["score_highest"] = gameScore
		
	if profileData["score_lowest"] > gameScore:
		profileData["score_lowest"] = gameScore
	
	# account chances to theme unlocks
	for chanceKey in GameState.players[multiplayer.get_unique_id()]["chances"].keys():
		UserProfiles._check_theme_unlock(chanceKey)
		UserProfiles._IO_write_themes_unlocks()
		pass
	
	UserProfiles._overwrite_profile_with_reference(profileData)
	pass

##RPC: enables and disabled the explainer text for the question based on a bool
@rpc("authority", "reliable", "call_local")
@warning_ignore("shadowed_variable_base_class")
func _show_question_explainer(visible: bool):
	if visible:
		ui_post_question.show()
	else:
		ui_post_question.hide()
	pass

## called by master scene when a player disconnects from the game, updating ui graphics
@rpc("authority", "reliable", "call_local")
func _player_dropped():
	GameState._build_player_number_to_id_table()
	
	for i in range(4):
		get_node("quizInterface/players_region/activePlayer%s" % (i + 1)).hide()
		pass
	
	for i in range(GameState.PlayerCount):
		var player = GameState.players[GameState.playerNumberToIds[i]]
		ui_player_names[i].text = player["name"]
		ui_player_scores[i].text = str(player["score"])
		get_node("quizInterface/players_region/activePlayer%s" % (i + 1)).show()
		pass
	pass

# refrence, status_a: skip, status_b: wrong, status_c, right
## called by server to sync the player statuses, statuses is expected to be a 2d array 
@rpc("authority", "reliable", "call_local")
func _sync_player_statuses(statuses):
	
	if not multiplayer.is_server():	
		player_statuses_ui_2d.resize(GameState.PlayerCount)
		for player_number in range(GameState.PlayerCount):
			player_statuses_ui_2d[player_number].resize(3)
			player_statuses_ui_2d[player_number][0] = statuses[player_number][0]
			player_statuses_ui_2d[player_number][1] = statuses[player_number][1]
			player_statuses_ui_2d[player_number][2] = statuses[player_number][2]
			pass
	$ControlSwapper0.play_backwards("QuestionLoad_B")
	await $ControlSwapper0.animation_finished
	_play_status_animation(statuses)
		
func _play_status_animation(statuses):
	for player_number in range(GameState.PlayerCount):
		if statuses[player_number][0]: # status_a
			get_node("ControlSwapper%s" % player_number).queue("p%sStatus_SkipShow" % (player_number + 1))
		if statuses[player_number][1]: # status_b
			get_node("ControlSwapper%s" % player_number).queue("p%sStatus_WrongShow" % (player_number + 1))
		if statuses[player_number][2]: # status_c
			get_node("ControlSwapper%s" % player_number).queue("p%sStatus_RightShow" % (player_number + 1))
		pass

## called by the server to reset all player statuses to be hidden
@rpc("authority", "reliable", "call_local")
func _reset_player_statuses():
	for player_number in range(GameState.PlayerCount):
		if player_statuses_ui_2d[player_number][0]:
			get_node("ControlSwapper%s" % player_number).queue("p%sStatus_SkipHide" % (player_number + 1))
			player_statuses_ui_2d[player_number][0] = false
		if player_statuses_ui_2d[player_number][1]:
			get_node("ControlSwapper%s" % player_number).queue("p%sStatus_WrongHide" % (player_number + 1))
			player_statuses_ui_2d[player_number][1] = false
		if player_statuses_ui_2d[player_number][2]:
			get_node("ControlSwapper%s" % player_number).queue("p%sStatus_RightHide" % (player_number + 1))
			player_statuses_ui_2d[player_number][2] = false
		pass

## hides the quiz interface and shows the prequiz rules interface
@rpc("authority", "reliable", "call_local")
func _display_prequiz_rules():
	# set the rules dependent elements to hide
	$preQuiz/preSessionOrganizer/RulesText/Rounds.hide()
	$preQuiz/preSessionOrganizer/RulesText/Rounds2.hide()
	
	$preQuiz/preSessionOrganizer/RulesText/Answers.hide()
	$preQuiz/preSessionOrganizer/RulesText/Answers2.hide()
	
	$preQuiz/preSessionOrganizer/RulesText/Score.hide()
	$preQuiz/preSessionOrganizer/RulesText/Score2.hide()
	
	if GameState.quizOptions.win_con_int == 0: # 0 : Highest score after x questions
		if !(GameState.CurrentTheme == "Fatal Surprise"):
			$preQuiz/preSessionOrganizer/RulesText/Rounds.text %= GameState.quizOptions.win_questions
		$preQuiz/preSessionOrganizer/RulesText/Rounds2.text %= GameState.quizOptions.win_questions
		$preQuiz/preSessionOrganizer/RulesText/Rounds.show()
		$preQuiz/preSessionOrganizer/RulesText/Rounds2.show()
		pass
	elif GameState.quizOptions.win_con_int == 1: # 1 : First to answer x questions correctly
		$preQuiz/preSessionOrganizer/RulesText/Answers.text %= GameState.quizOptions.win_questions
		$preQuiz/preSessionOrganizer/RulesText/Answers2.text %= GameState.quizOptions.win_questions
		$preQuiz/preSessionOrganizer/RulesText/Answers.show()
		$preQuiz/preSessionOrganizer/RulesText/Answers2.show()
		pass
	elif GameState.quizOptions.win_con_int == 2: # 2 : First to reach x points
		$preQuiz/preSessionOrganizer/RulesText/Score2.text %= GameState.quizOptions.win_points
		$preQuiz/preSessionOrganizer/RulesText/Score.show()
		$preQuiz/preSessionOrganizer/RulesText/Score2.show()
		pass
	
	$preQuiz/preSessionOrganizer/RulesText/Timer.text %= GameState.quizOptions.timer

	#$preQuiz.show()
	#$quizInterface.hide()
	$ControlSwapper0.play("QuizIntro")
	
	pass

## shows the prequiz rules interface and hides the quiz interface
@rpc("authority", "reliable", "call_local")
func _hide_prequiz_rules():
	#controlswapper handles visibility states
	#$preQuiz.hide()
	#$quizInterface.show()
	$ControlSwapper0.play("QuizStart")
	pass

@rpc("authority", "reliable", "call_local")
func _animate_question_load_a():
	$ControlSwapper0.queue("QuestionLoad_A")
	
@rpc("authority", "reliable", "call_local")
func _animate_question_load_b():
	$ControlSwapper0.queue("QuestionLoad_B")
	
@rpc("authority", "reliable", "call_local")
func _animate_question_unload():
	$ControlSwapper0.queue("QuestionUnload")

@rpc("authority", "reliable", "call_local")
func _ui_present_question_multiple_choice():
	$quizInterface/session_organizer/VerticalAnswerCategories.show()
	$quizInterface/session_organizer/CenteredAnswerCategories.hide()
	pass

@rpc("authority", "reliable", "call_local")
func _ui_present_question_this_that():
	$quizInterface/session_organizer/CenteredAnswerCategories.show()
	$quizInterface/session_organizer/VerticalAnswerCategories.hide()
	$quizInterface/session_organizer/CenteredAnswerCategories/ThisOrThat.show()
	$quizInterface/session_organizer/CenteredAnswerCategories/TrueOrFalse.hide()
	pass
@rpc("authority", "reliable", "call_local")
func _ui_present_question_true_false():
	$quizInterface/session_organizer/CenteredAnswerCategories.show()
	$quizInterface/session_organizer/VerticalAnswerCategories.hide()
	$quizInterface/session_organizer/CenteredAnswerCategories/TrueOrFalse.show()
	$quizInterface/session_organizer/CenteredAnswerCategories/ThisOrThat.hide()
	pass
#endregion

#region RPC functions called by clients to communicate with the server
##RPC: called by clients on the server whenever a player provides input
@rpc("any_peer", "reliable")
func _player_guess(playerId, guess):
	# proccess answer then send updated result to players, don't accept input during pre and post question time
	if multiplayer.is_server() && flag_accept_input:
		if flag_pre_quiz_rules:
			if !GameState._player_has_guessed(playerId):
				GameState._player_guess(playerId, guess, ui_countdown_timer.get_time_left())
				players_answered += 1
				if players_answered >= GameState.PlayerCount:
					GameState._reset_guesses()
					_hide_prequiz_rules.rpc()
					players_answered = 0
					#delay so _hide_prequiz_rules has time to play its animation
					get_tree().create_timer(4.2).timeout.connect(_prequestion_delay_phase)
					pass
			return
		if !ui_countdown_timer.is_stopped():
			if !GameState._player_has_guessed(playerId):
				GameState._player_guess(playerId, guess, ui_countdown_timer.get_time_left())
				players_answered += 1
				_update_ui_player_pannel_locked.rpc(true, playerId)
				if players_answered >= GameState.PlayerCount:
					_postquestion_delay_phase()
					pass
			pass
	pass
	
# called by players when they have loaded in
@rpc("any_peer", "reliable")
func _player_loaded(_peerId):
	GameState.PlayersLoaded += 1
	if GameState.PlayersLoaded == GameState.PlayerCount:
		_start_quiz_client.rpc()
		_start_quiz_server()
		pass
	pass
#endregion

#region local functions used by the server and clients
# if there is a filter enabled, store it as the selected filter, and mark the quiz to use it
func _select_tags_filter():
	useTagFilter = false
	for key in GameState.TagsFilters:
		if GameState.TagsFilters[key]["selected"] == true:
			selectedTagsFilter = GameState.TagsFilters[key]
			useTagFilter = true
			return
	
func _reset_question_rules_visibility():
	# hide all rules text
	$preQuiz/preSessionOrganizer/RulesText/Rounds.hide()
	$preQuiz/preSessionOrganizer/RulesText/Rounds2.hide()
	$preQuiz/preSessionOrganizer/RulesText/Score.hide()
	$preQuiz/preSessionOrganizer/RulesText/Score2.hide()
	$preQuiz/preSessionOrganizer/RulesText/Answers.hide()
	$preQuiz/preSessionOrganizer/RulesText/Answers2.hide()
	$preQuiz/preSessionOrganizer/RulesText/Timer.hide()
	$preQuiz/preSessionOrganizer/RulesText/Timer2.hide()
	
	#show default question layout, hide 2 question layout
	$quizInterface/session_organizer/CenteredAnswerCategories.hide()
	$quizInterface/session_organizer/VerticalAnswerCategories.show()
	pass
	
func _select_music_track():
	if GameState.CurrentTheme == "Patriotic Cipher":
		SoundMaster._play_music_track("msg_theme")
	elif GameState.CurrentTheme == "Fatal Surprise":
		SoundMaster._play_music_track("fatal_theme")
	else:
		SoundMaster._play_music_track("default_theme")

func _set_theme_specific_graphics():
	if GameState.CurrentTheme == "Patriotic Cipher":
		asset_player_pannel_locked = load("res://assets/uiux/session_themes/Patriotic Cipher/label_Cipher_ActivePlayer_locked.tres")
		asset_player_pannel_default = load("res://assets/uiux/session_themes/Patriotic Cipher/label_Cipher_ActivePlayer_default.tres")
	elif GameState.CurrentTheme == "Fatal Surprise":
		asset_player_pannel_locked = load("res://assets/uiux/session_themes/Fatal Surprise/label_Surprise_ActivePlayer_locked.tres")
		asset_player_pannel_default = load("res://assets/uiux/session_themes/Fatal Surprise/label_Surprise_ActivePlayer_default.tres")
	else:
		asset_player_pannel_locked = load("res://assets/uiux/session_themes/default/label_Chalk_ActivePlayer_Locked.tres")
		asset_player_pannel_default = load("res://assets/uiux/session_themes/default/label_Chalk_ActivePlayer_Default.tres")

func _escape_game_menu():
	# back out of the submenu to the options menu
	if flag_in_options_submenu:
		$pauseScreen/pauseCase/pauseOptions.show()
		$pauseScreen/pauseCase/pauseSound.hide()
		$pauseScreen/pauseCase/pauseDisplay.hide()
		flag_in_options_submenu = false
		return
		
	if flag_in_options_menu:
		$pauseScreen/pauseCase/pauseOptions.hide()
		$pauseScreen/pauseCase/pauseBase.show()
		_save_sound_settings()
		_save_display_settings()
		flag_in_options_menu = false
		return
	
	# if not in any submenus toggle between showing and closing the submenu
	if !flag_game_menu_shown:
		$pauseScreen.show()
		flag_game_menu_shown = true
	else:
		$pauseScreen.hide()
		flag_game_menu_shown = false
	pass

##used by the server to decide on the order questions will be presented
func _generate_answer_order():
	# if question type is "true/false" don't shuffle
	var questionType = GameState.CurrentQuizQuestions[current_index]["questionType"]
	if questionType == "True/False":
		var correct:String = GameState.CurrentQuizQuestions[current_index]["correct"]
		if correct.to_lower() == "true":
			local_answer_order = [0, 1, 2, 3]
		else:
			local_answer_order = [1, 0, 2, 3]
		return
	# "this or that", then only shuffle the first two indices
	elif questionType == "This/That":
		var available_indexes_tt = [0,1]
		local_answer_order = [0, 1, 2, 3]
		local_answer_order[0] = available_indexes_tt.pop_at(randi() % available_indexes_tt.size())
		local_answer_order[1] = available_indexes_tt.pop_at(randi() % available_indexes_tt.size())
		return
	#default to multiple choice
	var available_indexes = [0, 1, 2, 3]
	local_answer_order = [0, 1, 2, 3]
	local_answer_order[0] = available_indexes.pop_at(randi() % available_indexes.size())
	local_answer_order[1] = available_indexes.pop_at(randi() % available_indexes.size())
	local_answer_order[2] = available_indexes.pop_at(randi() % available_indexes.size())
	local_answer_order[3] = available_indexes.pop_at(randi() % available_indexes.size())
	
##uses the given questionIndex to find the corrisponding question in the filtered_question_data array
##after it will go through the selected questions chances and store them in the chances_set
func _next_question_data_and_store_chances(questionIndex, selected_index):
	var nextQuestion = filtered_question_data.pop_at(selected_index)
	for chance in nextQuestion["chances"]:
		if !chances_set.has(chance):
			chances_set[chance] = [questionIndex]
		else:
			chances_set[chance].append(questionIndex)
	return nextQuestion

func _start_quiz_server():
	# connect the functions for the delay timers
	ui_prequestion_timer.timeout.connect(_answer_question_phase)
	ui_countdown_timer.timeout.connect(_postquestion_delay_phase)
	ui_postquestion_timer.timeout.connect(_end_of_quiz_phase)
	
	current_index = 0
	GameState._reset_players()
	for i in range(GameState.PlayerCount):
		var player = GameState.players[GameState.playerNumberToIds[i]]
		ui_player_names[i].text = player["name"]
		ui_player_scores[i].text = str(player["score"])
		ui_players[i].visible = true
		pass
	
	GameState.GameStarted = true
	_prequiz_rules_phase()
	pass

func _render_answers_track_correct(current_question, question_order):
	if GameState.CurrentQuizQuestions[current_index]["questionType"] == "True/False":
		correct_answer = question_order[0]
		pass
	elif GameState.CurrentQuizQuestions[current_index]["questionType"] == "This/That":
		correct_answer = question_order[0]
		ui_this_or_that_answers[correct_answer].text = current_question["correct"]
		ui_this_or_that_answers[question_order[1]].text = current_question["wrong"][0]
	else:
		if GameState.CurrentTheme == "Fatal Surprise":
			_apply_scew_to_fatal_answers()
		correct_answer = question_order[0]
		ui_multiple_choice_answers[correct_answer].text = current_question["correct"]
		ui_multiple_choice_answers[question_order[1]].text = current_question["wrong"][0]
		ui_multiple_choice_answers[question_order[2]].text = current_question["wrong"][1]
		ui_multiple_choice_answers[question_order[3]].text = current_question["wrong"][2]

func _apply_scew_to_fatal_answers():
	var current_question = GameState.CurrentQuizQuestions[current_index]
	var average_answer_length = 0
	average_answer_length += current_question["correct"].length()
	average_answer_length += current_question["wrong"][0].length()
	average_answer_length += current_question["wrong"][1].length()
	average_answer_length += current_question["wrong"][2].length()
	average_answer_length /= 4
	
	var scew_modifier = float(max(average_answer_length - 25, 0)) * 0.002
	
	#a1 styleboxes
	surprize_styleBs_a1[0].skew.y = max(0.1 - scew_modifier, 0.01)
	surprize_styleBs_a1[1].skew.y = max(0.1 - scew_modifier, 0.01)
	surprize_styleBs_a1[2].skew.y = max(0.1 - scew_modifier, 0.01)
	
	surprize_styleBs_a2[0].skew.y = max(0.025 - scew_modifier * 0.25, 0.0025)
	surprize_styleBs_a2[1].skew.y = max(0.050 - scew_modifier * 0.5, 0.005)
	surprize_styleBs_a2[2].skew.y = max(0.025 - scew_modifier * 0.25, 0.0025)
	
	surprize_styleBs_a3[0].skew.y = min(-0.025 + scew_modifier * 0.25, -0.0025)
	surprize_styleBs_a3[1].skew.y = min(-0.050 + scew_modifier * 0.5, -0.005)
	surprize_styleBs_a3[2].skew.y = min(-0.025 + scew_modifier * 0.25, -0.0025)
	
	surprize_styleBs_a4[0].skew.y = min(-0.08 + scew_modifier * 0.8, -0.008)
	surprize_styleBs_a4[1].skew.y = min(-0.07 + scew_modifier * 0.7, -0.007)
	surprize_styleBs_a4[2].skew.y = min(-0.08 + scew_modifier * 0.8, -0.008)
	
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair1/a1.add_theme_stylebox_override("hover", surprize_styleBs_a1[0])
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair1/a1.add_theme_stylebox_override("normal", surprize_styleBs_a1[1])
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair1/a1.add_theme_stylebox_override("pressed", surprize_styleBs_a1[2])
	
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair2/a2.add_theme_stylebox_override("hover", surprize_styleBs_a2[0])
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair2/a2.add_theme_stylebox_override("normal", surprize_styleBs_a2[1])
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair2/a2.add_theme_stylebox_override("pressed", surprize_styleBs_a2[2])
	
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair3/a3.add_theme_stylebox_override("hover", surprize_styleBs_a3[0])
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair3/a3.add_theme_stylebox_override("normal", surprize_styleBs_a3[1])
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair3/a3.add_theme_stylebox_override("pressed", surprize_styleBs_a3[2])
	
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair4/a4.add_theme_stylebox_override("hover", surprize_styleBs_a4[0])
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair4/a4.add_theme_stylebox_override("normal", surprize_styleBs_a4[1])
	$quizInterface/session_organizer/VerticalAnswerCategories/MultipleChoice/answer_pair4/a4.add_theme_stylebox_override("pressed", surprize_styleBs_a4[2])


## starts the pre_quiz_rules timer, this phase displays the rules for 1 minute, or until input is recived from all players
func _prequiz_rules_phase():
	flag_accept_input = true
	flag_pre_quiz_rules = true
	_display_prequiz_rules.rpc()
	pass

## starts the pre_question timer, and halts accepting answer input from players
## variable delay to give players time to read the question before allowing them to answer
func _prequestion_delay_phase():
	# add aditional delay depending on how long the question is to read,
	# currently one extra second per 40 characters ( * 1/40 = 0.025)
	var current_question = GameState.CurrentQuizQuestions[current_index]
	@warning_ignore("narrowing_conversion")
	var extra_seconds : int = roundf(current_question["question"].length() * 0.025)
	
	flag_pre_quiz_rules = false
	
	flag_accept_input = false
	flag_pre_question_time = true
	
	_animate_question_load_a.rpc()
	
	# following the timers experation it will move to the answer_question_phase
	ui_prequestion_timer.start(pre_question_delay_default + extra_seconds)
	pass

## starts the timer for the answer phase, answer input is enabled
## shows the players the possible question answers
func _answer_question_phase():
	ui_prequestion_timer.stop()
	
	flag_accept_input = true
	flag_pre_question_time = false
	
	_update_ui_player_pannel_locked_all.rpc(false)
	
	_animate_question_load_b.rpc()
	
	ui_countdown_timer.start(GameState.quizOptions.timer)
	pass
	
## strarts the timer for the post question phase, answer input is disabled
## shows answer explainer
func _postquestion_delay_phase():
	ui_countdown_timer.stop()
	flag_accept_input = false
	flag_post_question_time = true
	
	var question_score_value = 1000
	
	
	# determine player correctness
	var current_question = GameState.CurrentQuizQuestions[current_index]
	@warning_ignore("narrowing_conversion")
	var extra_seconds : int = roundf(current_question["explainer"].length() * 0.025)
	
	GameState._player_correctness(correct_answer, question_score_value)
	GameState._add_chance_hits(current_index)
	GameState._update_profile_statistics(current_question["uuid"])
	
	_create_player_statuses_table()
	_sync_player_statuses.rpc(player_statuses_ui_2d)
	
	# unlock all player pannels during postphase
	_update_ui_player_pannel_locked_all.rpc(false)
	
	
	_show_question_explainer.rpc(true)
	
	#sync player scores
	var scores = {}
	var last_scores = {}
	for key in GameState.players.keys():
		scores[key] = GameState.players[key]["score"]
		last_scores[key] = GameState.players[key]["last_score"]
		pass
	_sync_update_scores_on_clients.rpc(scores, last_scores)
	
	ui_postquestion_timer.start(post_question_delay_default + extra_seconds + 1.0)
	pass
	
## end of question phase occurs after each question
func _end_of_quiz_phase():
	ui_postquestion_timer.stop()
	flag_post_question_time = false
	
	_show_question_explainer.rpc(false)
	_reset_player_statuses.rpc()
	
	_animate_question_unload.rpc()
	
	get_tree().create_timer(1.2).timeout.connect(_next_question)
	pass
	
func _next_question():
	# set player pannel graphics back to their unlocked state
	_update_ui_player_pannel_locked_all.rpc(false)
	current_index += 1
	if current_index < GameState.CurrentQuizQuestions.size(): # still questions in the quiz
		_sync_update_question_on_clients.rpc(current_index)
		players_answered = 0
		GameState._reset_guesses()
		loaded = false
		_generate_answer_order()
		_sync_answer_order.rpc(local_answer_order)
		if GameState.CurrentQuizQuestions[current_index]["questionType"] == "True/False":
			_ui_present_question_true_false.rpc()
		elif GameState.CurrentQuizQuestions[current_index]["questionType"] == "This/That":
			_ui_present_question_this_that.rpc()
		else:
			_ui_present_question_multiple_choice.rpc()
		_prequestion_delay_phase()
	else: # no more questions in the quiz
		# we need to transcribe profile data into its own array to send using rpc
		# as rpc will refuse to send typed objects for security reasons
		var playersData = {}
		for key in GameState.players.keys():
			playersData[key] = GameState.players[key].profileData
			pass
		
		_sync_and_save_client_profile_statistics.rpc(playersData)
		_show_end_of_quiz_screen.rpc()
	pass
	
## called by quit option on local clients exits the multiplayer session completely
func _exit_quiz():
	get_node("quizEnd/PlayerStandingsOrg/1Placer").hide()
	get_node("quizEnd/PlayerStandingsOrg/2Placer").hide()
	get_node("quizEnd/PlayerStandingsOrg/3Placer").hide()
	get_node("quizEnd/PlayerStandingsOrg/4Placer").hide()
	$quizInterface.show()
	$quizEnd.hide()
	QuizEndScreen = false
	GameState._reset_quiz_state()
	exit_quiz.emit()
	queue_free()
	pass

## uses info in GameState to create a table representing which player statuses should be on
func _create_player_statuses_table():
	player_statuses_ui_2d.clear()
	player_statuses_ui_2d.resize(GameState.PlayerCount)
	
	for playerNumber in range(GameState.PlayerCount):
		var playerCorrectness = GameState.players[GameState.playerNumberToIds[playerNumber]]["correct"]
		var playerAnswered = GameState.players[GameState.playerNumberToIds[playerNumber]]["hasGuessed"]
		
		# if player has not answered, they have passed
		if !playerAnswered:
			player_statuses_ui_2d[playerNumber] = [true, false, false]
			continue
		
		# if player's answer is correct
		if playerCorrectness:
			player_statuses_ui_2d[playerNumber] = [false, false, true]
			continue
		# if player's answer is wrong
		else:
			player_statuses_ui_2d[playerNumber] = [false, true, false]
			continue
	
	pass

func select_option_by_text(option_button: OptionButton, target_text: String) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == str(target_text):
			option_button.select(i)
			return
	print("Warning: Text not found in OptionButton:", target_text)
	

# depends on the globabal variables
#var rollup_count
func _local_score_rollup():
	var rollup_max = 10
	var t = float(rollup_count) / float(rollup_max)
	
	if rollup_count <= 0:
		for i in range(GameState.PlayerCount):
			ui_player_scores[i].text = str(GameState.players[GameState.playerNumberToIds[i]]["score"])
	else:
		for i in range(GameState.PlayerCount):
			var current_score = GameState.players[GameState.playerNumberToIds[i]]["score"]
			var last_score = GameState.players[GameState.playerNumberToIds[i]]["last_score"]
		
			ui_player_scores[i].text = str(current_score + (last_score - current_score) * t)
			rollup_count -= 1
		get_tree().create_timer(0.025).timeout.connect(_local_score_rollup)
#endregion

#region functions that translate the timers into minutes and seconds for the ui
func pre_question_clock():
	var time_left = ui_prequestion_timer.get_time_left()
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]
	
func post_question_clock():
	var time_left = ui_postquestion_timer.get_time_left()
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]

func countdown_clock():
	var time_left = ui_countdown_timer.get_time_left()
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]

#endregion

func _load_question_refresh_scores():
	if !loaded:
		for i in range(4):
			get_node("quizInterface/players_region/activePlayer%s" % (i + 1)).hide()
		ui_questions_index.text = str(current_index + 1)
		var current_question = GameState.CurrentQuizQuestions[current_index]
		ui_questions_name.text = current_question["name"]
		ui_questions_body.text = current_question["question"]
		ui_post_question.text = current_question["explainer"]
		_render_answers_track_correct(current_question, local_answer_order)
		for i in range(GameState.PlayerCount):
			get_node("quizInterface/players_region/activePlayer%s" % (i + 1)).show()
			ui_player_scores[i].text = str(GameState.players[GameState.playerNumberToIds[i]]["score"])
		loaded = true

#region functions used for setting up initial quiz state
func _load_quiz_data():
	_load_master_questions()
	_load_master_chances()
	pass

func _load_master_questions():
	var file = FileAccess.open("res://data/question_data.json", FileAccess.READ)
	if file:
		master_question_data = JSON.parse_string(file.get_as_text())
		file.close()
	
	if useTagFilter:
		for question in master_question_data:
			var tagMatch = false
			for tag in selectedTagsFilter["tags"]:
				var escape = false
				for question_tag in question["tags"]:
					if tag in question_tag.to_lower():
						tagMatch = true
						escape = true
						break
				if escape:
					break

			var a = tagMatch
			var b = selectedTagsFilter["blacklist"]
			# need to use XOR operator for whether or not to accept the question into the set
			if  (a or b) and not (a and b):
				filtered_question_data.append(question)
	else:
		for question in master_question_data:
			filtered_question_data.append(question)
	
func _load_master_chances():
	var file = FileAccess.open("res://data/chance_data.json", FileAccess.READ)
	if file:
		master_chances_data = JSON.parse_string(file.get_as_text())
		file.close()
	pass

func _clean_master_questions():
	master_question_data = []
	filtered_question_data = []
	pass
	
func _clean_chance_set_and_master():
	chances_set = {}
	master_chances_data = []
	pass
	
func _select_quiz_questions(quizSize):
	GameState.CurrentQuizQuestions = []
	for i in range(quizSize):
		if filtered_question_data.size() == 0:
			break
		GameState.CurrentQuizQuestions.append(_next_question_data_and_store_chances(i, randi() % filtered_question_data.size()))
	pass
	
func _prepare_quiz_chances(chance_count):
	GameState.CurrentChances = []
	for i in range(chance_count):
		if chances_set.keys().size() == 0:
			break
		_next_chance()

func _next_chance():
	var next_chance = chances_set.keys()[randi() % chances_set.keys().size()]
	for chance in master_chances_data:
		if chance["uuid"] == next_chance:
			GameState._add_chance(chance["name"], chance["description"], chance["type"], chance["uuid"], chance["correct"], chances_set[next_chance], chance["bonus"])
			chances_set.erase(next_chance)
			return
		
func _store_quiz_questions_locally():
	for question in GameState.CurrentQuizQuestions:
		local_question_set_uuids.append(question["uuid"])
		pass
	pass
#endregion

#region Debug Functions used for testing
func _debug_score_order_testing():
	var scoreOrder = ["3", "4", "1", "2"]
	var scores = {"1":400, "2":500, "3":600, "4":700}
	
	print("!Debug Function Start: _debug_score_order_testing")
	for test in scoreOrder:
		print(test)
		
	for n in range(4):
		var highestScore = scores[scoreOrder[n]]
		var indexOfHighest = n
		var swapTemp
		
		for i in range(n, 4):
			if scores[scoreOrder[i]] > highestScore:
				highestScore = scores[scoreOrder[i]]
				indexOfHighest = i
				pass
			pass
		
		swapTemp = scoreOrder[n]
		scoreOrder[n] = scoreOrder[indexOfHighest]
		scoreOrder[indexOfHighest] = swapTemp
		pass
		
	print("!Debug Function End")
	for test in scoreOrder:
		print(test)
	
	pass

func _debug_advance_to_next_question():
	print("!Debug: Skipping question")
	flag_pre_quiz_rules = false
	flag_pre_question_time = false
	flag_post_question_time = false
	flag_accept_input = false
	
	_create_player_statuses_table()
	_show_question_explainer.rpc(false)
	_reset_player_statuses.rpc()
	
	_next_question()
	pass





#endregion

#region buttons for inputing question answers via ui
#region button answer 1
func _on_a_1_button_down():
	# TODO: insert sound effect for button selection
	pass

func _on_a_1_button_up():
	# ignore input until the quiz starts
	var button_value = 0
	if !GameState.GameStarted:
		return
	if multiplayer.is_server(): # call locally if server
		_player_guess(1, button_value)
		pass
	else: #send guess to server
		_player_guess.rpc_id(1, multiplayer.get_unique_id(), button_value)
		pass
	pass
#endregion

#region button answer 2
func _on_a_2_button_down():
	# TODO: insert sound effect for button selection
	pass

func _on_a_2_button_up():
	# ignore input until the quiz starts
	var button_value = 1
	if !GameState.GameStarted:
		return
	if multiplayer.is_server(): # call locally if server
		_player_guess(1, button_value)
		pass
	else: #send guess to server
		_player_guess.rpc_id(1, multiplayer.get_unique_id(), button_value)
		pass
	pass
#endregion

#region button answer 3
func _on_a_3_button_down():
	# TODO: insert sound effect for button selection
	pass

func _on_a_3_button_up():
	# ignore input until the quiz starts
	var button_value = 2
	if !GameState.GameStarted:
		return
	if multiplayer.is_server(): # call locally if server
		_player_guess(1, button_value)
		pass
	else: #send guess to server
		_player_guess.rpc_id(1, multiplayer.get_unique_id(), button_value)
		pass
	pass
#endregion

#region button answer 4
func _on_a_4_button_down():
	# TODO: insert sound effect for button selection
	pass

func _on_a_4_button_up():
	# ignore input until the quiz starts
	var button_value = 3
	if !GameState.GameStarted:
		return
	if multiplayer.is_server(): # call locally if server
		_player_guess(1, button_value)
		pass
	else: #send guess to server
		_player_guess.rpc_id(1, multiplayer.get_unique_id(), button_value)
		pass
	pass
#endregion

#endregion

#region pause menu functionality 
func _on_resume_button_mouse_entered():
	$SFX_Hover1.play()
func _on_resume_button_focus_entered():
	$SFX_Hover1.play()
func _on_resume_button_button_down():
	$SFX_Press.play()
## returns to the game
func _on_resume_button_button_up():
	$pauseScreen.hide()
	flag_game_menu_shown = false
	flag_in_options_submenu = false

func _on_options_button_focus_entered():
	$SFX_Hover2.play()
func _on_options_button_mouse_entered():
	$SFX_Hover2.play()
func _on_options_button_button_down():
	$SFX_Press.play()
## opens the options menu
func _on_options_button_button_up():
	$pauseScreen/pauseCase/pauseBase.hide()
	$pauseScreen/pauseCase/pauseOptions.show()
	flag_in_options_menu = true
	flag_in_options_submenu = false

func _on_quit_button_focus_entered():
	$SFX_Hover3.play()
func _on_quit_button_mouse_entered():
	$SFX_Hover3.play()
func _on_quit_button_button_down():
	$SFX_Press.play()
## returns to main menu if client, returns everyone to multiplayer lobby if host
func _on_quit_button_button_up():
	# if server exit to multiplayer lobby
	if multiplayer.is_server():
		_end_quiz.rpc()
		pass
	# if client, exit multiplayer session and return to main menu
	else: 
		_exit_quiz()
		pass
		
	pass

func _on_options_back_button_focus_entered():
	$SFX_Hover3.play()
func _on_options_back_button_mouse_entered():
	$SFX_Hover3.play()
func _on_options_back_button_button_down():
	$SFX_Press.play()
## backs out of options menu to pause menu
func _on_options_back_button_button_up():
	$pauseScreen/pauseCase/pauseOptions.hide()
	$pauseScreen/pauseCase/pauseBase.show()
	flag_in_options_menu = false
	flag_in_options_submenu = false

func _on_sound_button_focus_entered():
	$SFX_Hover1.play()
func _on_sound_button_mouse_entered():
	$SFX_Hover1.play()
func _on_sound_button_button_down():
	$SFX_Press.play()
## opens the sound options submenu
func _on_sound_button_button_up():
	$pauseScreen/pauseCase/pauseOptions.hide()
	$pauseScreen/pauseCase/pauseSound.show()
	flag_in_options_menu = true
	flag_in_options_submenu = true

func _on_sound_back_button_focus_entered():
	$SFX_Hover3.play()
func _on_sound_back_button_mouse_entered():
	$SFX_Hover3.play()
func _on_sound_back_button_button_down():
	$SFX_Press.play()
## closes the sound options submenu
func _on_sound_back_button_button_up():
	$pauseScreen/pauseCase/pauseSound.hide()
	$pauseScreen/pauseCase/pauseOptions.show()
	flag_in_options_menu = true
	flag_in_options_submenu = false
	_save_sound_settings()

func _on_display_button_focus_entered():
	$SFX_Hover2.play()
func _on_display_button_mouse_entered():
	$SFX_Hover2.play()
func _on_display_button_button_down():
	$SFX_Press.play()
## opens the display options submenu
func _on_display_button_button_up():
	$pauseScreen/pauseCase/pauseOptions.hide()
	$pauseScreen/pauseCase/pauseDisplay.show()
	flag_in_options_menu = true
	flag_in_options_submenu = true

func _on_display_back_button_focus_entered():
	$SFX_Hover3.play()
func _on_display_back_button_mouse_entered():
	$SFX_Hover3.play()
func _on_display_back_button_button_down():
	$SFX_Press.play()
## closes the display options submenu
func _on_display_back_button_button_up():
	$pauseScreen/pauseCase/pauseDisplay.hide()
	$pauseScreen/pauseCase/pauseOptions.show()
	flag_in_options_menu = true
	flag_in_options_submenu = false
	_save_display_settings()
#endregion

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

#region Sound Options
#INFO: volume sliders are handled by MasterVolume.gd script

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
#endregion

#region Display Options

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

