extends Control

#region ui stuff
#===================================================
@onready var ui_questions_name = $quizInterface/session_organizer/question_header/question_name
@onready var ui_questions_index = $quizInterface/session_organizer/question_header/question_index
@onready var ui_countdown_timer = $quizInterface/session_organizer/question_header/Countdown
@onready var ui_prequestion_timer = $quizInterface/session_organizer/question_header/Prequestion_timer
@onready var ui_postquestion_timer = $quizInterface/session_organizer/question_header/Postquestion_timer
@onready var ui_questions_body = $quizInterface/session_organizer/question_body
@onready var ui_post_question = $quizInterface/post_question
@onready var ui_players = [
	$quizInterface/players_region/activePlayer1,
	$quizInterface/players_region/activePlayer2,
	$quizInterface/players_region/activePlayer3,
	$quizInterface/players_region/activePlayer4]
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

var pre_quiz_rules_text_rounds = ""
var pre_quiz_rules_text_rounds2 = ""
var pre_quiz_rules_text_answers = ""
var pre_quiz_rules_text_answers2 = ""
var pre_quiz_rules_text_score = ""
var pre_quiz_rules_text_score2 = ""
var pre_quiz_rules_text_timer = ""
#endregion

#region global variables
#===================================================
var master_chances_data = []
var master_question_data = []
var filtered_question_data = []

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

var pre_question_delay_default = 5.0
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

var ui_playing_statuses_animation = false
var ui_has_status_table = false

var menu_location = MENU.noMenu
var rollup_count = 0

var delta_t = 0.0

var player_input = "p_answer_%s"
var player_statuses_master: Array[Array]
var player_statuses_local: Array[Array]

var players_ready = 0
var phase_in_progress = false

enum MENU {
	noMenu = 0,
	pauseMenu = 1,
	optionsMenu = 2,
	subMenuSound = 3,
	subMenuDisplay = 4,
}
#endregion

var _icons: Dictionary = {}

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
	$preQuiz/preSessionOrganizer/RulesText/ReadyCheck.hide()
	menu_location = MENU.noMenu
	_pause_menu_update_graphics()
	_set_theme_specific_information()
	_load_config_settings()
	_load_icons()
	_select_music_track()
	InputDevice.device_changed.connect(_on_device_changed)
	_on_device_changed(InputDevice.current, InputDevice.last_joypad_id)
	
	for i in range(4):
		ui_players[i].hide()
		
	$quizEnd/ReturnToLobbyButton.text = "Exit Session"
	
	if multiplayer.is_server():
		$quizEnd/ReturnToLobbyButton.text = "Return To Lobby"
		$pauseScreen/pauseCase/pauseBase/quitButton.text = "Lobby"
		
		_host_setup_quiz()

func _load_icons() -> void:
	for device in ["KB", "XB", "PS","NT"]:
		for input in range(1, 5):
			var file := "res://assets/uiux/session_themes/T_%s%s_D.tga" % [device, input]
			_icons["%s%s" % [device, input]] = load(file)
	
func _on_device_changed(device: InputDevice.DeviceType, _id: int) -> void:
	match device:
		InputDevice.DeviceType.KEYBOARD_MOUSE: _replace_icons("KB")
		InputDevice.DeviceType.PLAYSTATION: _replace_icons("PS")
		InputDevice.DeviceType.SWITCH: _replace_icons("NT")
		_: _replace_icons("XB")

func _replace_icons(device: String) -> void:
	%ReadyCheck/ButtonTextures/Button1Texture.texture = _icons["%s1" % [device]]
	%ReadyCheck/ButtonTextures/Button2Texture.texture = _icons["%s2" % [device]]
	%ReadyCheck/ButtonTextures/Button3Texture.texture = _icons["%s3" % [device]]
	%ReadyCheck/ButtonTextures/Button4Texture.texture = _icons["%s4" % [device]]
	%MultipleChoice/answer_pair1/a1_icon.texture = _icons["%s1" % [device]]
	%MultipleChoice/answer_pair2/a2_icon.texture = _icons["%s2" % [device]]
	%MultipleChoice/answer_pair3/a3_icon.texture = _icons["%s3" % [device]]
	%MultipleChoice/answer_pair4/a4_icon.texture = _icons["%s4" % [device]]
	%TrueOrFalse/True/a1_icon.texture = _icons["%s1" % [device]]
	%TrueOrFalse/False/a2_icon.texture = _icons["%s2" % [device]]
	%ThisOrThat/This/a1_icon.texture = _icons["%s1" % [device]]
	%ThisOrThat/That/a2_icon.texture = _icons["%s2" % [device]]

func _process(delta):
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		delta_t += delta
		if delta_t > 0.2:
			delta_t = 0.0
			for key in GameState.players:
				if GameState.players[key]["loaded"]:
					_sync_game_timer.rpc_id(key, _get_timer_reading(GameState.quiz_phase))

func _is_event_keypress(event, key) -> bool:
	return event is InputEventKey and event.pressed and event.keycode == key

func _input(event):
	if _is_event_keypress(event, KEY_ESCAPE):
		_escape_game_menu()
	
	if DEBUG and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		if _is_event_keypress(event, KEY_N):
			_DEBUG_next_question()
	
	match GameState.quiz_phase:
		QUIZSTATE.preQuiz:
			for guess in range(4):
				if event.is_action_pressed(player_input % guess):
					_player_ready(multiplayer.get_unique_id())
		QUIZSTATE.question:
			for guess in range(4):
				if event.is_action_pressed(player_input % guess):
					var questionType = question_type
					if (questionType == "True/False" or questionType == "This/That") and guess > 1:
						break
					_player_guess(guess)

func _player_guess(guess):
	if GameState._can_guess():
		_player_guess_rpc.rpc_id(1, multiplayer.get_unique_id(), guess)

func _player_dropped(mp_id):
	if GameState._game_started():
		_ui_update_lock_player_pannel(mp_id, true)
	if multiplayer.is_server():
		GameState.players[mp_id].pannel_locked = true
		print("Info: player Dropped id:%s" % mp_id)

func _player_rejoined(mp_id):
	if multiplayer.is_server():
		print("Info: player rejoined id:%s" % mp_id)

#region server side functions that handle syncing with players
#===================================================
func _server_full_sync(mp_id = -1):
	_server_sync_player_info(mp_id)
	_server_sync_quiz_phase(mp_id)
	
func _server_sync_player_info(mp_id = -1):
	var player_ids = []
	player_ids.resize(GameState._player_count())
	var player_scores = []
	player_scores.resize(GameState._player_count())
	var player_scores_last = []
	player_scores_last.resize(GameState._player_count())
	var index = 0
	
	for key in GameState.players:
		player_ids[index] = key
		player_scores[index] = GameState.players[key]["score"]
		player_scores_last[index] = GameState.players[key]["last_score"]
		index += 1
	
	if mp_id == -1:
		_sync_player_info.rpc(player_ids, player_scores, player_scores_last)
	else:
		_sync_player_info.rpc_id(mp_id, player_ids, player_scores, player_scores_last)

func _server_sync_quiz_phase(mp_id = -1):
	var q = quiz_questions_list[quiz_question_index]
	question_uuid = q["uuid"]
	
	if mp_id == -1:
		_sync_quiz_phase.rpc(
			GameState.quiz_phase, 
			quiz_question_index,
			q["name"], q["explainer"], q["question"], question_answers, q["questionType"])
	else:
		_sync_quiz_phase.rpc_id(
			mp_id,
			GameState.quiz_phase, 
			quiz_question_index,
			q["name"], q["explainer"], q["question"], question_answers, q["questionType"])

func _server_sync_late_join(mp_id):
	_server_sync_player_info()
	_server_sync_quiz_phase(mp_id)
	_sync_game_rules.rpc_id(
		mp_id,
		GameState.quizOptions.timer, 
		"Highest score after 10 questions", 
		0,  # cut feature, always use "highest score after x question"
		10, # 10 questions
		GameState.quizOptions.win_points)
	
	if GameState.quiz_phase == QUIZSTATE.endScreen:
		_server_sync_endscreen_info(mp_id)
	
	var pannels_locked = []
	
	for key in GameState.players:
		if GameState.players[key].pannel_locked:
			pannels_locked.append(key)
	
	_late_join_load_in.rpc_id(mp_id, pannels_locked)

func _server_sync_endscreen_info(mp_id = -1):
	var player_ids = []
	player_ids.resize(GameState._player_count())
	var final_scores = []
	final_scores.resize(GameState._player_count())
	var chance_names = []
	chance_names.resize(GameState._player_count())
	for i in range(GameState._player_count()):
		chance_names[i] = []
	
	for key in GameState.players:
		var index = GameState.idToCardIndex[key]
		player_ids[index] = key
		final_scores[index] = GameState.players[key].final_score
	
	for c in GameState.chances:
		for p in GameState.players:
			if GameState.players[p].chance_hits.has(c):
				chance_names[GameState.idToCardIndex[p]].append(GameState.chances[c].name)
	
	if mp_id == -1:
		_sync_player_end_screen.rpc(player_ids, final_scores, chance_names)
	else:
		_sync_player_end_screen.rpc_id(mp_id, player_ids, final_scores, chance_names)

func _server_sync_profile_data():
	for key in GameState.players:
		var question_uuids = []
		
		for question in quiz_questions_list:
			question_uuids.append(question["uuid"])
		
		var player_chances = []
		
		for c in GameState.players[key].chance_hits:
			player_chances.append(c)
		
		if DEBUG:
			print("!!DEBUG: sending profile data to player_id: [%s]" % key)
		if key == 1:
			_sync_profile_data(
				GameState.players[key].final_score, 
				question_uuids, 
				GameState.players[key].answer_record, 
				player_chances)
		elif multiplayer.get_peers().has(key):
			_sync_profile_data.rpc_id(
				key,
				GameState.players[key].final_score, 
				question_uuids, 
				GameState.players[key].answer_record, 
				player_chances)
#endregion

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
	
	for key in GameState.players:
		GameState.players[key].pannel_locked = true
	_player_pannels_lock.rpc()
	
	_set_question_answers_as_randomised_array(q)
	
	_server_full_sync()
	
	
	_sync_play_phase_animation.rpc()

func _phase_end_of_rules():
	if DEBUG:
		print("!!DEBUG: End Of Rules phase")
	GameState.quiz_phase = QUIZSTATE.endOfRules
	
	_server_full_sync()
	_sync_play_phase_animation.rpc()
	
	get_tree().create_timer(3.2).timeout.connect(_phase_pre_question)

func _phase_pre_question():
	if DEBUG:
		print("!!DEBUG: Prequestion phase")
	GameState.quiz_phase = QUIZSTATE.preQuestion
	
	_server_full_sync()
	
	var extra_seconds : int = 0
	extra_seconds = roundi(question_body.length() * 0.05)
	
	for key in GameState.players:
		GameState.players[key].pannel_locked = false
	_player_pannels_unlock.rpc()
	
	if DEBUG:
		print("!INFO: extra seconds for pre_question phase [%s]" % extra_seconds)
		
	_sync_play_phase_animation.rpc()
	
	ui_prequestion_timer.start(pre_question_delay_default + extra_seconds)

func _phase_question():
	if DEBUG:
		print("!!DEBUG: Question phase")
	GameState.quiz_phase = QUIZSTATE.question
	ui_prequestion_timer.stop()
	
	_server_full_sync()
	_sync_play_phase_animation.rpc()
	
	ui_countdown_timer.start(GameState.quizOptions.timer)
	
func _phase_post_question():
	if DEBUG:
		print("!!DEBUG: Postquestion phase")
	GameState.quiz_phase = QUIZSTATE.postQuestion
	ui_countdown_timer.stop()
	
	for key in GameState.players:
		GameState.players[key].pannel_locked = true
	_player_pannels_lock.rpc()
	
	var extra_seconds : int = roundi(question_explainer.length() * 0.05)
	
	var question_score_value = 1000
	
	GameState._check_player_answers(question_answers_correct_index, question_score_value)
	GameState._check_player_chances(quiz_questions_list[quiz_question_index]["uuid"])
	
	for key in GameState.players:
		GameState.players[key].answer_record[quiz_question_index] = GameState.players[key].correct
	
	_create_player_statuses_table()
	
	var player_ids = []
	player_ids.resize(GameState._player_count())
	for n in range(GameState._player_count()):
		player_ids[n] = GameState.playerCardOrder[n]
		
	_sync_player_statuses.rpc(player_ids, player_statuses_master)
	
	GameState._reset_player_guesses()
	
	_server_full_sync()
	_sync_play_phase_animation.rpc()
	
	ui_postquestion_timer.start(post_question_delay_default + extra_seconds + 1.5)

func _phase_end_of_phase():
	if DEBUG:
		print("!!DEBUG: end of phase phase")
	GameState.quiz_phase = QUIZSTATE.endOfPhase
	ui_postquestion_timer.stop()
	
	for key in GameState.players:
		GameState.players[key]["last_score"] = GameState.players[key]["score"]
	
	_server_full_sync()
	_sync_play_phase_animation.rpc()
	
	if quiz_question_index < QUIZ_LENGTH - 1:
		get_tree().create_timer(1.2).timeout.connect(_phase_next_question)
	else:
		get_tree().create_timer(1.2).timeout.connect(_phase_end_screen)
		
func _phase_next_question():
	quiz_question_index += 1
	
	var q = quiz_questions_list[quiz_question_index]
	question_uuid = q["uuid"]
	
	_set_question_answers_as_randomised_array(q)
	
	_phase_pre_question()

func _phase_end_screen():
	if DEBUG:
		print("!!DEBUG: endscreen phase")
	GameState.quiz_phase = QUIZSTATE.endScreen

	var chance_winners = []
	var highest_hits = 0
	
	for c in GameState.chances:
		for p in GameState.players:
			if GameState.players[p].chance_hits.has(c):
				if GameState.players[p].chance_hits[c] > highest_hits:
					chance_winners = []
					chance_winners.append(p)
					highest_hits = GameState.players[p].chance_hits[c]
				elif GameState.players[p].chance_hits[c] == highest_hits:
					chance_winners.append(p)
		
		for p in chance_winners:
			GameState.players[p].chances_scored.append(c)
		
		chance_winners = []
		highest_hits = 0
	
	for p in GameState.players:
		var final_score = GameState.players[p].score
		for c in GameState.players[p].chances_scored:
			final_score += GameState.chances[c]["bonus"]
		GameState.players[p].final_score = final_score
	
	_server_full_sync()
	_server_sync_endscreen_info()
	
	_sync_play_phase_animation.rpc()
	_server_sync_profile_data()
#endregion

#region server side rpc functions
#===================================================
@rpc("authority", "call_local", "reliable")
func _server_ending_quiz():
	GameState._reset_quiz_state()
	
	#remove inactive players from session when returning to lobby
	var inactive_players = []
	for key in GameState.players:
		if not GameState.players[key]["active"]:
			inactive_players.append(key)
	
	for key in inactive_players:
		GameState.players.erase(key)
	
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
	q_type: String
	):
	
	if GameState._game_started():
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

@rpc("authority", "call_local", "reliable")
func _sync_play_phase_animation():
	ui_post_question.hide()
		
	if ui_playing_statuses_animation:
		ui_playing_statuses_animation = false
		_ui_ani_reset_player_statuses(player_statuses_local)
		await $ControlSwapper0.animation_finished
		
	match GameState.quiz_phase:
		QUIZSTATE.preQuiz:
			_ui_update_prequiz_rules()
			_ui_ani_quiz_intro()
			return
		QUIZSTATE.endOfRules:
			_ui_ani_quiz_start()
			return
		QUIZSTATE.preQuestion:
			_ui_ani_question_load_a()
		QUIZSTATE.question:
			_ui_ani_question_load_b()
		QUIZSTATE.postQuestion:
			ui_post_question.show()
			_ui_ani_question_answers_unload()
			if ui_has_status_table:
				await $ControlSwapper0.animation_finished
				_ui_ani_update_player_statuses(player_statuses_local)
				ui_has_status_table = false
				ui_playing_statuses_animation = true
		QUIZSTATE.endOfPhase:
			_ui_ani_question_unload()
		QUIZSTATE.endScreen:
			_ui_setup_end_screen()
			_ui_ani_display_end_screen()
			
	$preQuiz/preSessionOrganizer/RulesText/ReadyCheck.hide()

@rpc("authority", "call_local", "reliable")
func _sync_player_info(player_ids: Array, player_scores: Array, player_scores_last):
	for i in range(player_ids.size()):
		GameState.players[player_ids[i]]["score"] = player_scores[i]
		GameState.players[player_ids[i]]["last_score"] = player_scores_last[i]
	
		_ui_update_player_panels()
		_ui_update_scores()

@rpc("authority", "reliable")
func _sync_game_rules(
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
	
@rpc("authority", "call_local", "reliable")
func _sync_game_timer(clock_reading: Array):
	$quizInterface/session_organizer/CountdownLabel.text = "%02d:%02d" % clock_reading

@rpc("authority", "call_local", "reliable")
func _sync_player_statuses(player_ids: Array, statuses):
	player_statuses_local.resize(GameState._player_count())
	for n in range(player_ids.size()):
		var i = GameState.idToCardIndex[player_ids[n]]
		player_statuses_local[n].resize(3)
		player_statuses_local[n][0] = statuses[i][0]
		player_statuses_local[n][1] = statuses[i][1]
		player_statuses_local[n][2] = statuses[i][2]
		
	ui_has_status_table = true

@rpc("authority", "call_local", "reliable")
func _sync_player_end_screen(ids, final_scores, chance_names):
	for i in range(ids.size()):
		GameState.players[ids[i]].final_score = final_scores[i]
		for chance_name in chance_names[i]:
			GameState.players[ids[i]].chance_names.append(chance_name)

@rpc("authority", "call_local", "reliable")
func _sync_profile_data(p_score, question_uuids, answers, chances_scored):
	UserProfiles._update_profile_with_quiz_data(
		UserProfiles._get_selected_profile_key(),
		p_score,
		question_uuids,
		answers,
		chances_scored)

@rpc("authority", "reliable")
func _player_load_quiz():
	_client_setup_quiz()

@rpc("authority", "reliable")
func _late_join_load_in(pannels_locked: Array):
	_io_load_master_chances()
	_ui_update_prequiz_rules()
	
	for key in pannels_locked:
		_ui_update_lock_player_pannel(key, true)
	
	match GameState.quiz_phase:
		QUIZSTATE.preQuiz:
			$ControlSwapper0.play("QuizIntro", -1, 10.0, false)
		QUIZSTATE.endOfRules:
			$ControlSwapper0.play("QuizStart", -1, 20.0, false)
		QUIZSTATE.preQuestion:
			$preQuiz/preSessionOrganizer/RulesText/ReadyCheck.hide()
			$ControlSwapper0.play("QuizStart", -1, 20.0, false)
			await $ControlSwapper0.animation_finished
			$ControlSwapper0.play("QuestionLoad_A", -1, 20.0, false)
		QUIZSTATE.question:
			$preQuiz/preSessionOrganizer/RulesText/ReadyCheck.hide()
			$ControlSwapper0.play("QuizStart", -1, 20.0, false)
			await $ControlSwapper0.animation_finished
			$ControlSwapper0.play("QuestionLoad_A", -1, 20.0, false)
			await $ControlSwapper0.animation_finished
			$ControlSwapper0.play("QuestionLoad_B", -1, 20.0, false)
		QUIZSTATE.postQuestion:
			$preQuiz/preSessionOrganizer/RulesText/ReadyCheck.hide()
			$ControlSwapper0.play("QuizStart", -1, 20.0, false)
			await $ControlSwapper0.animation_finished
			$ControlSwapper0.play("QuestionLoad_A", -1, 20.0, false)
			ui_post_question.show()
		QUIZSTATE.endOfPhase:
			$preQuiz/preSessionOrganizer/RulesText/ReadyCheck.hide()
			$ControlSwapper0.play("QuizStart", -1, 20.0, false)
			await $ControlSwapper0.animation_finished
			$ControlSwapper0.play("QuestionLoad_A", -1, 20.0, false)
			await $ControlSwapper0.animation_finished
			$ControlSwapper0.play("QuestionUnload", -1, 20.0, false)
		QUIZSTATE.endScreen:
			$preQuiz/preSessionOrganizer/RulesText/ReadyCheck.hide()
			_ui_setup_end_screen()
			$ControlSwapper0.play("QuizFinish", -1, 20.0, false)
	
	_late_join_player_setup_done.rpc_id(1)

@rpc("authority", "call_local", "reliable")
func _player_pannels_lock():
	_ui_update_lock_all_player_pannels(true)

@rpc("authority", "call_local", "reliable")
func _player_pannels_unlock():
	_ui_update_lock_all_player_pannels(false)

@rpc("authority", "call_local", "reliable")
func _player_update_pannel_lock(mp_id, locked):
	_ui_update_lock_player_pannel(mp_id, locked)

@rpc("authority", "call_local", "reliable")
func _sync_player_pannels_lock(ids, locked):
	for i in range(ids.size()):
		_ui_update_lock_player_pannel(ids[i], locked[i])
#endregion

#region client side rpc functions
#===================================================
@rpc("any_peer", "reliable", "call_local")
func _player_guess_rpc(mp_id, guess):
	if GameState.quiz_phase == QUIZSTATE.question:
		if not ui_countdown_timer.is_stopped() and not GameState.players[mp_id].hasGuessed:
			GameState.players[mp_id].make_guess(guess, ui_countdown_timer.get_time_left())
			GameState.players[mp_id].pannel_locked = true
			_player_update_pannel_lock.rpc(mp_id, true)
		if GameState._have_all_players_answered():
			_phase_post_question()

@rpc("any_peer", "reliable")
func _player_setup_done():
	GameState.players[multiplayer.get_remote_sender_id()]["loaded"] = true
	if multiplayer.is_server():
		GameState.players_loaded += 1
		if GameState.players_loaded == GameState._player_count():
			_phase_pre_quiz()

@rpc("any_peer", "reliable")
func _player_ready(mp_id):
	if multiplayer.is_server():
		GameState.players[mp_id]["ready"] = true
		if GameState._are_all_players_ready():
			_phase_end_of_rules()
	else:
		_player_ready.rpc_id(1, mp_id)

@rpc("any_peer", "reliable")
func _late_join_player_setup_done():
	var mp_id = multiplayer.get_remote_sender_id()
	GameState.players[mp_id]["loaded"] = true
	
	if GameState.players[mp_id].hasGuessed or GameState._pannels_locked_phase():
		GameState.players[mp_id].pannel_locked = true
	else:
		GameState.players[mp_id].pannel_locked = false
	
	var ids = []
	ids.resize(GameState._player_count())
	var locked = []
	locked.resize(GameState._player_count())
	
	for i in range(ids.size()):
		ids[i] = GameState.playerCardOrder[i]
		locked[i] = GameState.players[GameState.playerCardOrder[i]].pannel_locked
	
	_sync_player_pannels_lock.rpc(ids, locked)
#endregion

#region server utilities
#===================================================
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

func _create_player_statuses_table():
	player_statuses_master.clear()
	player_statuses_master.resize(GameState._player_count())
	
	for n in range(GameState._player_count()):
		var playerCorrectness = GameState.players[GameState.playerCardOrder[n]]["correct"]
		var playerAnswered = GameState.players[GameState.playerCardOrder[n]]["hasGuessed"]
		
		if !playerAnswered:
			player_statuses_master[n] = [true, false, false]
		elif playerCorrectness:
			player_statuses_master[n] = [false, false, true]
		else:
			player_statuses_master[n] = [false, true, false]
#endregion

#region quiz ui and animation functions
#===================================================
func _ui_update_player_panels():
	for i in range(GameState._player_count()):
		if GameState.playerCardOrder[i] != -1:
			var player_info = GameState.players[GameState.playerCardOrder[i]]
			ui_player_names[i].text = player_info["name"]
			ui_players[i].show()
		else:
			ui_players[i].hide()

func _ui_update_scores():
	for key in GameState.players:
		if GameState.players[key]["score"] != GameState.players[key]["last_score"]:
			if rollup_count <= 0:
				rollup_count = 10
				_ui_local_score_rollup()
			break
	
func _ui_local_score_rollup():
	var t = float(rollup_count) / float(ROLLUP_MAX)
	
	if rollup_count <= 0:
		for i in range(GameState._player_count()):
			ui_player_scores[i].text = str(GameState.players[GameState.playerCardOrder[i]]["score"])
	else:
		for i in range(GameState._player_count()):
			var player = GameState.players[GameState.playerCardOrder[i]]
			var current_score = player["score"]
			var last_score = player["last_score"]
			var negative: bool = current_score - last_score < 0
			var score_text = "  %s"
			if rollup_count % 4 <= 1:
				if negative:
					score_text = "\\/%s"
				else:
					score_text = "/\\%s"
			score_text = score_text % str(current_score + (last_score - current_score) * t)
			ui_player_scores[i].text = score_text
		rollup_count -= 1
		get_tree().create_timer(0.06).timeout.connect(_ui_local_score_rollup)

func _ui_update_lock_player_pannel(mp_id, locked: bool):
	var card_index = GameState.idToCardIndex[mp_id] + 1
	var player_case = "quizInterface/players_region/activePlayer%s/player_case/player_name" % card_index
	if locked:
		get_node(player_case).set_label_settings(asset_player_pannel_locked)
	else:
		get_node(player_case).set_label_settings(asset_player_pannel_default)

func _ui_update_lock_all_player_pannels(locked: bool):
	for key in GameState.players:
		_ui_update_lock_player_pannel(key, locked)

func _ui_apply_question_data():
	var type = question_type
	ui_questions_index.text = "%s" % (quiz_question_index + 1)
	
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

func _ui_ani_update_player_statuses(statuses):
	for n in range(GameState._player_count()):
		if statuses[n][0]: # status_a
			get_node("ControlSwapper%s" % n).queue("p%sStatus_SkipShow" % (n + 1))
		if statuses[n][1]: # status_b
			get_node("ControlSwapper%s" % n).queue("p%sStatus_WrongShow" % (n + 1))
		if statuses[n][2]: # status_c
			get_node("ControlSwapper%s" % n).queue("p%sStatus_RightShow" % (n + 1))

## called by the server to reset all player statuses to be hidden
func _ui_ani_reset_player_statuses(statuses):
	for n in range(GameState._player_count()):
		if statuses[n][0]:
			get_node("ControlSwapper%s" % n).queue("p%sStatus_SkipHide" % (n + 1))
			statuses[n][0] = false
		if statuses[n][1]:
			get_node("ControlSwapper%s" % n).queue("p%sStatus_WrongHide" % (n + 1))
			statuses[n][1] = false
		if statuses[n][2]:
			get_node("ControlSwapper%s" % n).queue("p%sStatus_RightHide" % (n + 1))
			statuses[n][2] = false

func _ui_update_prequiz_rules():
	# set the rules dependent elements to hide
	$preQuiz/preSessionOrganizer/RulesText/Rounds.hide()
	$preQuiz/preSessionOrganizer/RulesText/Rounds2.hide()
	$preQuiz/preSessionOrganizer/RulesText/Answers.hide()
	$preQuiz/preSessionOrganizer/RulesText/Answers2.hide()
	$preQuiz/preSessionOrganizer/RulesText/Score.hide()
	$preQuiz/preSessionOrganizer/RulesText/Score2.hide()
	
	var win_con_int = 0
	var win_questions = 10
	var win_points = 5000
	var timer = 30
	
	if GameState.quizOptions.win_con_int:
		win_con_int = GameState.quizOptions.win_con_int
	if GameState.quizOptions.win_questions:
		win_questions = GameState.quizOptions.win_questions
	if GameState.quizOptions.win_points:
		win_points = GameState.quizOptions.win_points
	if GameState.quizOptions.timer:
		timer = GameState.quizOptions.timer
	
	if win_con_int == 0: # 0 : Highest score after x questions
		if !(GameState.CurrentTheme == "Fatal Surprise"):
			$preQuiz/preSessionOrganizer/RulesText/Rounds.text = pre_quiz_rules_text_rounds % win_questions
		$preQuiz/preSessionOrganizer/RulesText/Rounds2.text = pre_quiz_rules_text_rounds2 % win_questions
		$preQuiz/preSessionOrganizer/RulesText/Rounds.show()
		$preQuiz/preSessionOrganizer/RulesText/Rounds2.show()
	elif win_con_int == 1: # 1 : First to answer x questions correctly
		$preQuiz/preSessionOrganizer/RulesText/Answers.text = pre_quiz_rules_text_answers % win_questions
		$preQuiz/preSessionOrganizer/RulesText/Answers2.text = pre_quiz_rules_text_answers2 % win_questions
		$preQuiz/preSessionOrganizer/RulesText/Answers.show()
		$preQuiz/preSessionOrganizer/RulesText/Answers2.show()
	elif win_con_int == 2: # 2 : First to reach x points
		$preQuiz/preSessionOrganizer/RulesText/Score2.text = pre_quiz_rules_text_score2 % win_points
		$preQuiz/preSessionOrganizer/RulesText/Score.show()
		$preQuiz/preSessionOrganizer/RulesText/Score2.show()
	$preQuiz/preSessionOrganizer/RulesText/Timer.text = pre_quiz_rules_text_timer % timer

func _on_control_swapper_0_animation_finished(anim_name):
	if GameState.quiz_phase == QUIZSTATE.preQuiz and "QuizIntro" == anim_name:
		$preQuiz/preSessionOrganizer/RulesText/ReadyCheck.show()
		$ControlSwapper0.play("QuizPrompting")

func _ui_ani_quiz_intro():
	$ControlSwapper0.queue("QuizIntro")

func _ui_ani_quiz_start():
	$ControlSwapper0.play("QuizStart")

func _ui_ani_question_load_a():
	$ControlSwapper0.play("QuestionLoad_A")

func _ui_ani_question_load_b():
	$ControlSwapper0.play("QuestionLoad_B")

func _ui_ani_question_answers_unload():
	$ControlSwapper0.play_backwards("QuestionLoad_B")
	
func _ui_ani_question_unload():
	$ControlSwapper0.play("QuestionUnload")
	
func _ui_ani_display_end_screen():
	$ControlSwapper0.play("QuizFinish")
	
func _ui_setup_end_screen():
	# order players by score
	var scoreOrder = []
	
	for key in GameState.players:
		scoreOrder.append(key)
	
	# create an index of the player entries thats sorted based on score
	for n in range(GameState._player_count()):
		var highestScore = GameState.players[scoreOrder[n]].score
		var indexOfHighest = n
		var swapTemp
		
		for i in range(n, GameState._player_count()):
			if GameState.players[scoreOrder[i]].score > highestScore:
				highestScore = GameState.players[scoreOrder[i]].score
				indexOfHighest = i
		
		swapTemp = scoreOrder[n]
		scoreOrder[n] = scoreOrder[indexOfHighest]
		scoreOrder[indexOfHighest] = swapTemp
	
	#setup ui
	for n in range(4):
		var uiNumber = n + 1
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer" % uiNumber).hide()
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/MedalCase/Awards" % uiNumber)["text"] = "N/A"
	
	for n in range(GameState._player_count()):
		var uiNum = n + 1
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/Name" % uiNum).text = GameState.players[scoreOrder[n]].name
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/ScoreDisplay/Score" % uiNum).text = "%s" % GameState.players[scoreOrder[n]].score
		
		var chanceStr = ""
		for chance_name in GameState.players[scoreOrder[n]].chance_names:
			chanceStr += "%s, " % chance_name
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/MedalCase/Awards" % uiNum)["text"] = chanceStr
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer" % uiNum).show()
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
	
func dynamic_music_answers(percentage: float):
	if SoundMaster.next_track == "appear" and percentage <= .5:
		SoundMaster._dynamic_next_track("midway")
	elif SoundMaster.next_track == "midway" and percentage <=.25:
		SoundMaster._dynamic_next_track("outta_time")
#endregion

#region setup for quiz chances and questions
#===========================================================
func _host_setup_quiz():
	_select_question_filter()
	_io_load_master_questions()
	_generate_filtered_question_set()
	_io_load_master_chances()
	
	QUIZ_LENGTH = GameState.quizOptions.win_questions
	var question_count = _select_quiz_questions(QUIZ_LENGTH)
	if question_count < QUIZ_LENGTH:
		QUIZ_LENGTH = question_count
		print("!Info: fewer than max questions picked, only %s questions in this quiz" % question_count)
	
	if QUIZ_LENGTH <= 0:
		print("!Info: a quiz was generated with no questions, this was likely caused by a question filter. \n Disabling filter and generating a new quiz.")
		use_question_filter = false
		_generate_filtered_question_set()
		QUIZ_LENGTH = 10
		question_count = _select_quiz_questions(QUIZ_LENGTH)
		QUIZ_LENGTH = question_count
		if question_count == 0:
			print("!!ERROR: generated a quiz with no questions when using unfiltered question data.\n Its possible question_data.json is corrupted.")
			_server_ending_quiz.rpc()
	
	
	for key in GameState.players:
		GameState.players[key].answer_record = []
		GameState.players[key].answer_record.resize(QUIZ_LENGTH)
		for i in range(GameState.players[key].answer_record.size()):
			GameState.players[key].answer_record[i] = false
	
	_clean_questions_data()
	_sync_game_rules.rpc(
		GameState.quizOptions.timer, 
		"Highest score after 10 questions", 
		0,  # cut feature, always use "highest score after x question"
		10, # 10 questions
		GameState.quizOptions.win_points)
	_player_load_quiz.rpc()
	_player_setup_done()
	if DEBUG:
		print("!!DEBUG: Awards possible for this question set:")
		var i = 0
		for key in GameState.chances:
			print("%s: name: %s, uuid: %s" % [i, GameState.chances[key]["name"], key])
			i += 1

func _client_setup_quiz():
	_io_load_master_chances()
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

func _generate_filtered_question_set():
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
	master_chances_data = []

func _select_quiz_questions(quizSize) -> int:
	var quiz_size = 0
	for i in range(quizSize):
		# return early if we run out of questions,
		if filtered_question_data.size() == 0:
			return quiz_size
		
		var question = filtered_question_data.pop_at(randi() % filtered_question_data.size())
		quiz_questions_list.append(question)
		for key in question["chances"]:
			if GameState.chances.has(key):
				GameState.chances[key].related_questions.append(question["uuid"])
			else:
				var chance = _get_chance_data_from_uuid(key)
				GameState.chances[key] = GameState.Chance.create(chance["name"], chance["correct"], chance["bonus"], key)
				GameState.chances[key].related_questions.append(question["uuid"])
		quiz_size += 1
	return quiz_size

func _get_chance_data_from_uuid(chance_uuid) -> Dictionary:
	for chance in master_chances_data:
		if chance["uuid"] == chance_uuid:
			return chance
	return {}
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

func _set_theme_specific_information():
	if GameState.CurrentTheme == "Patriotic Cipher":
		pre_quiz_rules_text_rounds = "The player with the highest score after %s rounds wins."
		pre_quiz_rules_text_rounds2 = "The quiz will end after %s round(s)"
		pre_quiz_rules_text_answers = "The first agent to correctly answer %s questions wins."
		pre_quiz_rules_text_answers2 = "The quiz will end when an agent correctly answers %s questions"
		pre_quiz_rules_text_score = "The first agent to reach the high score wins."
		pre_quiz_rules_text_score2 = "The quiz will end when an agent achieves a score of %s"
		pre_quiz_rules_text_timer = "Agents will have %s seconds to answer each question."
		
		asset_player_pannel_locked = load("res://assets/uiux/session_themes/Patriotic Cipher/label_Cipher_ActivePlayer_locked.tres")
		asset_player_pannel_default = load("res://assets/uiux/session_themes/Patriotic Cipher/label_Cipher_ActivePlayer_default.tres")
	elif GameState.CurrentTheme == "Fatal Surprise":
		pre_quiz_rules_text_rounds = "There's an exact number of rounds in this one, whoever has the highest score at the end takes it all."
		pre_quiz_rules_text_rounds2 = "This exam lasts for %s round(s), don't let it slip through your fingers."
		pre_quiz_rules_text_answers = "Score doesn't apply in this run, so there's no penalty for wrong answers."
		pre_quiz_rules_text_answers2 = "Once somebody answers %s questions correctly, they get crowned winner. You like crowns?"
		pre_quiz_rules_text_score = "There's a target score we need you to hit before the exam ends -"
		pre_quiz_rules_text_score2 = "The first person to reach %s points wins, that's gotta be you."
		pre_quiz_rules_text_timer = "Members only get %s seconds per question."
		
		asset_player_pannel_locked = load("res://assets/uiux/session_themes/Fatal Surprise/label_Surprise_ActivePlayer_locked.tres")
		asset_player_pannel_default = load("res://assets/uiux/session_themes/Fatal Surprise/label_Surprise_ActivePlayer_default.tres")
	else:
		pre_quiz_rules_text_rounds = "The player with the highest score after %s rounds wins."
		pre_quiz_rules_text_rounds2 = "The quiz will end after %s round(s)"
		pre_quiz_rules_text_answers = "The first player to correctly answer %s questions wins."
		pre_quiz_rules_text_answers2 = "The quiz will end when a player correctly answers %s questions"
		pre_quiz_rules_text_score = "The first player to reach the high score wins."
		pre_quiz_rules_text_score2 = "The quiz will end when a player achieves a score of %s"
		pre_quiz_rules_text_timer = "Players will have %s seconds to answer each question."
		
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
	if multiplayer.is_server():
		_server_ending_quiz.rpc()
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
	ui_prequestion_timer.stop()
	ui_countdown_timer.stop()
	ui_postquestion_timer.stop()
	
	if quiz_question_index < QUIZ_LENGTH - 1:
		_phase_next_question()
	else:
		_phase_end_screen()
#endregion

func _on_return_to_lobby_button_focus_entered():
	$SFX_Hover3.play()
func _on_return_to_lobby_button_mouse_entered():
	$SFX_Hover3.play()
func _on_return_to_lobby_button_button_down():
	$SFX_Press.play()
func _on_return_to_lobby_button_button_up():
	if multiplayer.is_server():
		_server_ending_quiz.rpc()
	else: 
		_client_disconnect_from_server()
