extends Control

#region refrences to quiz ui elements
#===================================================
@onready var ui_questions_name = $quizInterface/session_organizer/question_header/question_name
@onready var ui_questions_index = $quizInterface/session_organizer/question_header/question_index
@onready var ui_countdown_timer = $quizInterface/session_organizer/question_header/Countdown
@onready var ui_prequestion_timer = $quizInterface/session_organizer/question_header/Prequestion_timer
@onready var ui_postquestion_timer = $quizInterface/session_organizer/question_header/Postquestion_timer
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
#===================================================
var master_chances_data = []
var master_question_data = []
var filtered_question_data = []
var chances_set = {}

#signals
signal sig_end_of_quiz
signal sig_exit_quiz

var config_path = "user://settings.cfg"
var QuestionDataFile = "res://data/question_data.json"
var config = ConfigFile.new()

var DEBUG = true
var QUIZ_LENGTH = 10
var ROLLUP_MAX = 10

var use_question_filter = false
var question_filter = {}

var pre_question_delay_default = 3.0
var post_question_delay_default = 5.0

var questions = {}
var quiz_questions_list = []
var quiz_question_index = 0 
var quiz_chances = []

var question_name = "n/a"
var question_explainer = "explainer_text"
var question_body = "body_text"
var question_answers = ["answer_0", "answer_1", "answer_2", "answer_3"]
var question_answers_correct_index = -1
var question_type = ""
var question_uuid = ""

var menu_location = MENU.noMenu
var rollup_count = 0

var delta_t = 0.0

var player_input = "p_answer_%s"
var player_statuses_ui_2d: Array[Array]

var players_ready = 0

enum MENU {
	noMenu = 0,
	pauseMenu = 1,
	optionsMenu = 2,
	subMenuSound = 3,
	subMenuDisplay = 4,
}
#endregion

enum QUIZSTATE {
	lobby,
	loading,
	preQuiz,
	endOfRules,
	preQuestion,
	question,
	postQuestion,
	endOfPhase,
	endScreen
}

func _ready():
	$preQuiz.hide()
	$quizInterface.hide()
	menu_location = MENU.noMenu
	_pause_menu_update_graphics()
	_set_theme_specific_graphics()
	_load_config_settings()
	_select_music_track()
	
	if multiplayer.is_server():
		$pauseScreen/pauseCase/pauseBase/quitButton.text = "Lobby"
		_host_setup_quiz()

func _process(delta):
	delta_t += delta
	if delta_t > 0.2:
		if multiplayer.is_server():
			_sync_game_timer.rpc(_get_timer_reading(GameState.quiz_phase))

func _is_event_keypress(event, key) -> bool:
	return event is InputEventKey and event.pressed and event.keycode == key

func _input(event):
	# opens game menu locally on client
	if _is_event_keypress(event, KEY_ESCAPE):
		_escape_game_menu()

	if DEBUG and multiplayer.is_server() and _is_event_keypress(event, KEY_P):
		_DEBUG_next_question()
	
	match GameState.quiz_phase:
		QUIZSTATE.preQuiz:
			for guess in range(4):
				if event.is_action_pressed(player_input % guess):
					_player_ready()
		QUIZSTATE.question:
			for guess in range(4):
				if event.is_action_pressed(player_input % guess):
					#if we're a "this or that" or a "true/false" question ignore input from 3 and 4
					var questionType = _current_question_type()
					if (questionType == "True/False" or questionType == "This/That") and guess > 1:
						break
					_player_guess(guess)
	
	# ignore input until quiz starts
	
func _player_guess(guess):
	if GameState._can_guess():
		if multiplayer.is_server():
			_player_guess_rpc(1, guess)
		else:
			_player_guess_rpc.rpc_id(1, multiplayer.get_unique_id(), guess)

func _player_dropped():
	
	pass
	
#region quiz phase functions
#===================================================
func _phase_pre_quiz():
	if DEBUG:
		print("!!DEBUG: Prequiz phase")
	GameState.quiz_phase = QUIZSTATE.preQuiz
	
	ui_prequestion_timer.timeout.connect(_phase_question)
	ui_countdown_timer.timeout.connect(_phase_post_question)
	ui_postquestion_timer.timeout.connect(_phase_end_of_phase)
	
	var q = quiz_questions_list[quiz_question_index]
	question_uuid = q["uuid"]
	
	_set_question_answers_as_randomised_array(q)
	
	_sync_quiz_phase.rpc(
		GameState.quiz_phase, 
		quiz_question_index,
		q["name"], q["explainer"], q["question"], question_answers, q["questionType"], 
		_get_timer_reading(GameState.quiz_phase))

func _phase_end_of_rules():
	if DEBUG:
		print("!!DEBUG: End Of Rules phase")
	GameState.quiz_phase = QUIZSTATE.endOfRules
	_sync_quiz_phase.rpc(
		GameState.quiz_phase, 
		quiz_question_index,
		question_name, question_explainer, question_body, question_answers, question_type, 
		_get_timer_reading(GameState.quiz_phase))
		
	get_tree().create_timer(4.2).timeout.connect(_phase_pre_question)

func _phase_pre_question():
	if DEBUG:
		print("!!DEBUG: Prequestion phase")
	GameState.quiz_phase = QUIZSTATE.preQuestion

	@warning_ignore("narrowing_conversion")
	var extra_seconds : int = roundf(question_body.length() * 0.025)
	
	ui_prequestion_timer.start(pre_question_delay_default + extra_seconds)
	
	_sync_quiz_phase.rpc(
		GameState.quiz_phase, 
		quiz_question_index,
		question_name, question_explainer, question_body, question_answers, question_type, 
		_get_timer_reading(GameState.quiz_phase))
	
func _phase_question():
	if DEBUG:
		print("!!DEBUG: Question phase")
	GameState.quiz_phase = QUIZSTATE.question
	
	ui_prequestion_timer.stop()
	ui_countdown_timer.start(GameState.quizOptions.timer)
	
	_sync_quiz_phase.rpc(
		GameState.quiz_phase, 
		quiz_question_index,
		question_name, question_explainer, question_body, question_answers, question_type, 
		_get_timer_reading(GameState.quiz_phase))
	
func _phase_post_question():
	if DEBUG:
		print("!!DEBUG: Postquestion phase")
	GameState.quiz_phase = QUIZSTATE.postQuestion
	_sync_quiz_phase.rpc(
		GameState.quiz_phase, 
		quiz_question_index,
		question_name, question_explainer, question_body, question_answers, question_type, 
		_get_timer_reading(GameState.quiz_phase))
	
func _phase_end_of_phase():
	if DEBUG:
		print("!!DEBUG: end of phase phase")
	GameState.quiz_phase = QUIZSTATE.endOfPhase
	quiz_question_index += 1
	
	var q = quiz_questions_list[quiz_question_index]
	question_uuid = q["uuid"]
	
	_set_question_answers_as_randomised_array(q)
	
	_sync_quiz_phase.rpc(
		GameState.quiz_phase, 
		quiz_question_index,
		q["name"], q["explainer"], q["question"], question_answers, q["questionType"], 
		_get_timer_reading(GameState.quiz_phase))
	
func _phase_end_screen():
	if DEBUG:
		print("!!DEBUG: endscreen phase")
#endregion
	
#region server side rpc functions
#===================================================
@rpc("authority", "call_local", "reliable")
func _server_ending_quiz():
	GameState._reset_quiz_state()
	sig_end_of_quiz.emit()
	queue_free()
	
@rpc("authority", "call_local", "reliable")
func _sync_quiz_phase(
	quiz_phase, 
	question_index: int,
	q_name: String, 
	q_explain: String, 
	q_body: String, 
	q_answers: Array, 
	q_type: String, 
	timer_reading: Array
	):
	$preQuiz.show()
	$quizInterface.show()
	
	GameState.quiz_phase = quiz_phase
	quiz_question_index = question_index
	
	question_name = q_name
	question_explainer = q_explain
	question_body = q_body
	question_answers = q_answers
	question_type = q_type
	
	_ui_apply_question_data()
	
	match GameState.quiz_phase:
		QUIZSTATE.preQuiz:
			_ui_ani_display_prequiz_rules()
		QUIZSTATE.endOfRules:
			_ui_ani_quiz_start()
		QUIZSTATE.preQuestion:
			_ui_ani_question_load_a()
		QUIZSTATE.question:
			_ui_ani_question_load_b()
		QUIZSTATE.postQuestion:
			pass
		QUIZSTATE.endOfPhase:
			_ui_ani_question_unload()
		QUIZSTATE.endScreen:
			pass

@rpc("authority", "call_local", "reliable")
func _sync_player_info():
	pass

@rpc("authority", "call_local", "reliable")
func _sync_game_timer(clock_reading: Array):
	$quizInterface/session_organizer/CountdownLabel.text = "%02d:%02d" % clock_reading

@rpc("authority", "reliable")
func _player_load_quiz():
	_client_setup_quiz()

#endregion

#region client side rpc functions
#===================================================
@rpc("any_peer", "reliable")
func _player_guess_rpc(mp_id, guess):
	
	pass

@rpc("any_peer", "reliable")
func _player_setup_done():
	if multiplayer.is_server():
		GameState.players_loaded += 1
		if GameState.players_loaded == GameState._player_count():
			_phase_pre_quiz()

@rpc("any_peer", "reliable")
func _player_ready():
	if multiplayer.is_server():
		players_ready += 1
		if players_ready >= GameState._player_count():
			_phase_end_of_rules()
	else:
		_player_ready.rpc_id(1)
#endregion

#region question related
#===================================================
func _current_question_type() -> String:
	match question_type:
		#if it is a valid question type, return as is
		["Multiple Choice", "True/False", "This/That"]:
			return question_type
		_: #if not default to multiple choice
			return "Multiple Choice"
			
func _set_question_answers_as_randomised_array(question):
	var correct = question["correct"]
	var wrong = question["wrong"]
	var type = question["questionType"]
	var answers = [correct, wrong[0], wrong[1], wrong[2]]
	
	match type:
		"True/False":
			if correct.to_lower() == "true":
				question_answers_correct_index = 0
			else:
				question_answers_correct_index = 1
			question_answers = ["True", "False", "null", "null"]
		"This/That":
			var available_indexes_tt = [0, 1]
			var i = 0
			while available_indexes_tt.size():
				var answer_index = available_indexes_tt.pop_at(randi() % available_indexes_tt.size())
				question_answers[i] = answers[answer_index]
				if answer_index == 0:
					question_answers_correct_index = i
				i += 1
			question_answers[2] = "null"
			question_answers[3] = "null"
		_: # "Multiple Choice"
			var available_indexes_tt = [0, 1, 2, 3]
			var i = 0
			while available_indexes_tt.size():
				var answer_index = available_indexes_tt.pop_at(randi() % available_indexes_tt.size())
				question_answers[i] = answers[answer_index]
				if answer_index == 0:
					question_answers_correct_index = i
				i += 1
#endregion

#region quiz ui and animation functions
#===================================================
func _ui_apply_question_data():
	var type = _current_question_type()
	ui_questions_index.text = "%s" % quiz_question_index
	
	ui_questions_name.text = question_name
	ui_questions_body.text = question_body
	ui_post_question.text = question_explainer
	
	match type:
		"True/False":
			$quizInterface/session_organizer/CenteredAnswerCategories.show()
			$quizInterface/session_organizer/VerticalAnswerCategories.hide()
			$quizInterface/session_organizer/CenteredAnswerCategories/TrueOrFalse.show()
			$quizInterface/session_organizer/CenteredAnswerCategories/ThisOrThat.hide()
		"This/That":
			for i in range(2):
				ui_this_or_that_answers[i].text = question_answers[i]
			$quizInterface/session_organizer/CenteredAnswerCategories.show()
			$quizInterface/session_organizer/VerticalAnswerCategories.hide()
			$quizInterface/session_organizer/CenteredAnswerCategories/TrueOrFalse.hide()
			$quizInterface/session_organizer/CenteredAnswerCategories/ThisOrThat.show()
		_:
			for i in range(4):
				ui_multiple_choice_answers[i].text = question_answers[i]
			$quizInterface/session_organizer/VerticalAnswerCategories.show()
			$quizInterface/session_organizer/CenteredAnswerCategories.hide()

func _ui_apply_scew_to_fatal_answers():
	var average_answer_length = 0
	average_answer_length += question_answers[0].length()
	average_answer_length += question_answers[1].length()
	average_answer_length += question_answers[2].length()
	average_answer_length += question_answers[3].length()
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

func _ui_play_status_animation(statuses):
	for player_number in range(GameState.PlayerCount):
		if statuses[player_number][0]: # status_a
			get_node("ControlSwapper%s" % player_number).queue("p%sStatus_SkipShow" % (player_number + 1))
		if statuses[player_number][1]: # status_b
			get_node("ControlSwapper%s" % player_number).queue("p%sStatus_WrongShow" % (player_number + 1))
		if statuses[player_number][2]: # status_c
			get_node("ControlSwapper%s" % player_number).queue("p%sStatus_RightShow" % (player_number + 1))

## called by the server to reset all player statuses to be hidden
func _ui_reset_player_statuses():
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

func _ui_local_score_rollup():
	var t = float(rollup_count) / float(ROLLUP_MAX)
	
	if rollup_count <= 0:
		for i in range(GameState.PlayerCount):
			ui_player_scores[i].text = str(GameState.players[GameState.playerNumberToIds[i]]["score"])
	else:
		for i in range(GameState.PlayerCount):
			var current_score = GameState.players[GameState.playerNumberToIds[i]]["score"]
			var last_score = GameState.players[GameState.playerNumberToIds[i]]["last_score"]
		
			ui_player_scores[i].text = str(current_score + (last_score - current_score) * t)
			rollup_count -= 1
		get_tree().create_timer(0.025).timeout.connect(_ui_local_score_rollup)

func _ui_ani_display_prequiz_rules():
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
	elif GameState.quizOptions.win_con_int == 1: # 1 : First to answer x questions correctly
		$preQuiz/preSessionOrganizer/RulesText/Answers.text %= GameState.quizOptions.win_questions
		$preQuiz/preSessionOrganizer/RulesText/Answers2.text %= GameState.quizOptions.win_questions
		$preQuiz/preSessionOrganizer/RulesText/Answers.show()
		$preQuiz/preSessionOrganizer/RulesText/Answers2.show()
	elif GameState.quizOptions.win_con_int == 2: # 2 : First to reach x points
		$preQuiz/preSessionOrganizer/RulesText/Score2.text %= GameState.quizOptions.win_points
		$preQuiz/preSessionOrganizer/RulesText/Score.show()
		$preQuiz/preSessionOrganizer/RulesText/Score2.show()

	$preQuiz/preSessionOrganizer/RulesText/Timer.text %= GameState.quizOptions.timer
	$ControlSwapper0.play("QuizIntro")
	
func _on_control_swapper_0_animation_finished(anim_name):
	if "QuizIntro" == anim_name:
		$ControlSwapper0.play("QuizPrompting")
	
func _ui_ani_quiz_start():
	$ControlSwapper0.play("QuizStart")

func _ui_ani_question_load_a():
	$ControlSwapper0.queue("QuestionLoad_A")

func _ui_ani_question_load_b():
	$ControlSwapper0.queue("QuestionLoad_B")
	
func _ui_ani_question_unload():
	$ControlSwapper0.queue("QuestionUnload")
#endregion

#region timers
#===================================================
func _get_timer_reading(quiz_phase):
	match quiz_phase:
		QUIZSTATE.preQuestion:
			return clock_pre_question()
		QUIZSTATE.question:
			return clock_countdown()
		QUIZSTATE.postQuestion:
			return clock_post_question()
		_:
			return [0,0]

func clock_pre_question():
	var time_left = ui_prequestion_timer.get_time_left()
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]
	
func clock_countdown():
	var time_left = ui_countdown_timer.get_time_left()
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]
	
func clock_post_question():
	var time_left = ui_postquestion_timer.get_time_left()
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]

#endregion

#region setup for quiz chances and questions
#===========================================================
func _host_setup_quiz():
	
	_select_question_filter()
	_io_load_master_questions()
	_io_load_master_chances()
	var question_count = _select_quiz_questions(QUIZ_LENGTH)
	if question_count < QUIZ_LENGTH:
		print("Info: fewer than max questions picked, only %s questions in this quiz" % question_count)

	_clean_questions_data()
	_clean_chance_data()
	
	_player_load_quiz.rpc()
	_player_setup_done()
	
	#TODO: add a sanity check if a player manages to drop during quiz load 
	#that'll send server and lobby back to the tile after some seconds if the quiz still hasn't started
	
func _client_setup_quiz():
	_player_setup_done.rpc_id(1)
	
func _select_question_filter():
	use_question_filter = false
	for key in GameState.TagsFilters:
		if GameState.TagsFilters[key]["selected"] == true:
			question_filter = GameState.TagsFilters[key]
			use_question_filter = true
			return

func _io_load_master_questions():
	var file = FileAccess.open("res://data/question_data.json", FileAccess.READ)
	if file:
		master_question_data = JSON.parse_string(file.get_as_text())
		file.close()
	# if tags filter is enabled, only store matching questions in the question set
	if use_question_filter:
		for question in master_question_data:
			var tagMatch = false
			for tag in question_filter["tags"]:
				var escape = false
				for question_tag in question["tags"]:
					if tag in question_tag.to_lower():
						tagMatch = true
						escape = true
						break
				if escape:
					break

			var a = tagMatch
			var b = question_filter["blacklist"]
			# need to use XOR operator for whether or not to accept the question into the set
			if  (a or b) and not (a and b):
				filtered_question_data.append(question)
	else: # otherwise store the complete list
		for question in master_question_data:
			filtered_question_data.append(question)
	
func _clean_questions_data():
	master_question_data = []
	filtered_question_data = []
	
func _io_load_master_chances():
	var file = FileAccess.open("res://data/chance_data.json", FileAccess.READ)
	if file:
		master_chances_data = JSON.parse_string(file.get_as_text())
		file.close()

func _clean_chance_data():
	chances_set = {}
	master_chances_data = []

func _select_quiz_questions(quizSize) -> int:
	var quiz_size = 0
	for i in range(quizSize):
		# return early if we run out of questions,
		if filtered_question_data.size() == 0:
			return 0
		
		var question = filtered_question_data.pop_at(randi() % filtered_question_data.size())
		quiz_questions_list.append(question)
		for chance in question["chances"]:
			if chances_set.has(chance):
				chances_set[chance].append(question["uuid"])
			else:
				chances_set[chance] = [question["uuid"]]
		quiz_size += 1
	return quiz_size

func _get_chance_data_from_uuid(chance_uuid):
	for chance in master_chances_data:
		if chance["uuid"] == chance_uuid:
			return chance
	return null
#endregion

#region setup for graphics and sound
#===================================================
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
#endregion

#region answer buttons
#===================================================
func _on_a_1_button_down():
	# TODO: insert sound effect for button selection
	pass
func _on_a_1_button_up():
	_player_guess(0)
	
func _on_a_2_button_down():
	# TODO: insert sound effect for button selection
	pass
func _on_a_2_button_up():
	_player_guess(1)

func _on_a_3_button_down():
	# TODO: insert sound effect for button selection
	pass
func _on_a_3_button_up():
	_player_guess(2)
	
func _on_a_4_button_down():
	# TODO: insert sound effect for button selection
	pass
func _on_a_4_button_up():
	_player_guess(3)
#endregion

#region pause menu
#===================================================
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

func select_option_by_text(option_button: OptionButton, target_text: String) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == str(target_text):
			option_button.select(i)
			return
	print("Warning: Text not found in OptionButton:", target_text)
	
func _client_disconnect_from_server():
	GameState._reset_quiz_state()
	sig_exit_quiz.emit()
	queue_free()

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

#region debug and testing functions
#===================================================
func _DEBUG_next_question():
	pass
	
func _DEBUG_restart_from_beginning():
	pass
#endregion
