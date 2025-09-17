extends Control

#region refrences to quiz ui elements
@onready var ui_questions_name = $quizInterface/session_organizer/question_header/question_name
@onready var ui_questions_index = $quizInterface/session_organizer/question_header/question_index
@onready var ui_countdown_timer = $quizInterface/session_organizer/question_header/Countdown
@onready var ui_countdown_text = $quizInterface/session_organizer/CountdownLabel
@onready var ui_questions_body = $quizInterface/session_organizer/question_body
@onready var ui_post_question = $quizInterface/post_question
@onready var ui_players = [$quizInterface/players_region/activePlayer1/player_case,
	$quizInterface/players_region/activePlayer2/player_case,
	$quizInterface/players_region/activePlayer3/player_case,
	$quizInterface/players_region/activePlayer4/player_case]
@onready var ui_answers = [$quizInterface/session_organizer/HBoxContainer/answer_organizer/answer_pair1/a1,
	$quizInterface/session_organizer/HBoxContainer/answer_organizer/answer_pair2/a2,
	$quizInterface/session_organizer/HBoxContainer/answer_organizer/answer_pair3/a3,
	$quizInterface/session_organizer/HBoxContainer/answer_organizer/answer_pair4/a4]
@onready var ui_player_names = [$quizInterface/players_region/activePlayer1/player_case/player_name,
	$quizInterface/players_region/activePlayer2/player_case/player_name,
	$quizInterface/players_region/activePlayer3/player_case/player_name,
	$quizInterface/players_region/activePlayer4/player_case/player_name]
@onready var ui_player_scores = [$quizInterface/players_region/activePlayer1/player_case/status_row/score,
	$quizInterface/players_region/activePlayer2/player_case/status_row/score,
	$quizInterface/players_region/activePlayer3/player_case/status_row/score,
	$quizInterface/players_region/activePlayer4/player_case/status_row/score]
@onready var ui_question_answer_buttons = [$quizInterface/session_organizer/HBoxContainer/answer_organizer/answer_pair1/a1,
$quizInterface/session_organizer/HBoxContainer/answer_organizer/answer_pair2/a2,
$quizInterface/session_organizer/HBoxContainer/answer_organizer/answer_pair3/a3,
$quizInterface/session_organizer/HBoxContainer/answer_organizer/answer_pair4/a4]

var asset_player_pannel_locked
var asset_player_pannel_default
#endregion

#region global variables
var master_chances_data = []
var master_question_data = []
var chances_set = {}

var local_question_set_uuids = []

signal end_of_quiz

var QUIZ_SIZE = 10
var CHANCE_COUNT = 3

var pre_timer = 10.0
var post_timer = 10.0
var current_index = 0
var correct_answer = 0
var loaded = false
var players_answered = 0
var player_input = "p_answer_%s"

var local_clock_reading = [0,0]
var local_answer_order = [0, 1, 2, 3]

var QuizEndScreen = false
#endregion

##Called when the node enters the scene tree for the first time.
##primarily used by the server to setup the quiz session
func _ready():
	asset_player_pannel_locked = load("res://assets/uiux/session_themes/default/label_Chalk_ActivePlayer_Locked.tres")
	asset_player_pannel_default = load("res://assets/uiux/session_themes/default/label_Chalk_ActivePlayer_Default.tres")

	if multiplayer.is_server():
		_load_quiz_data()
		_select_quiz_questions(QUIZ_SIZE)
		_prepare_quiz_chances(CHANCE_COUNT)
		_store_quiz_questions_locally()
		GameState._build_player_number_to_id_table()
		_sync_server_client_data.rpc(local_question_set_uuids, GameState.playerNumberToIds)
		_clean_master_questions()
		_clean_chance_set_and_master()
		_generate_answer_order()
		_sync_answer_order.rpc(local_answer_order)
		_player_loaded(multiplayer.get_unique_id())
		print("server [%s] loaded" % multiplayer.get_unique_id())
		pass
	pass

func _process(_delta):
	if GameState.GameStarted:
		if multiplayer.is_server():
			local_clock_reading =  countdown_clock()
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
	if multiplayer.is_server() and QuizEndScreen and (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_end_quiz.rpc()
		pass
	for i in range(4):
		if event.is_action_pressed(player_input % i):
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
	
@rpc("authority", "reliable")
func _sync_update_scores_on_clients(scores):
	for key in scores.keys():
		GameState.players[key]["score"] = scores[key]
		pass
	pass

@rpc("authority", "call_local", "reliable")
func _show_end_of_quiz_screen():
	ui_countdown_timer.stop()
	QuizEndScreen = true
	
	var scoreOrder = []
	
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
		GameState.players[scoreOrder[n]]
		var uiNum = n + 1
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/Name" % uiNum).text = GameState.players[scoreOrder[n]].name
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer/ScoreDisplay/Score" % uiNum).text = "%s" % GameState.players[scoreOrder[n]].score
		
		for chanceKey in GameState.players[scoreOrder[n]]["chances"].keys():
			var chanceStr = ""
			chanceStr += "%s, " % chanceKey
			
			get_node("quizEnd/PlayerStandingsOrg/%sPlacer/MedalCase/Awards" % uiNum)["text"] = chanceStr
			
		
		get_node("quizEnd/PlayerStandingsOrg/%sPlacer" % uiNum).show()
		pass
	
	
	$quizInterface.hide()
	$quizEnd.show()
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
##RPC: accepts a bool, and tells the clients and server to switch a given players pannel between the locked and unlcoked states
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
	
	UserProfiles._overwrite_profile_with_reference(profileData)
	pass
	
#endregion

#region RPC functions called by clients to communicate with the server
##RPC: called by clients on the server whenever a player inputs a guess
@rpc("any_peer", "reliable")
func _player_guess(playerId, guess):
	# proccess answer then send updated result to players
	if multiplayer.is_server():
		if !ui_countdown_timer.is_stopped():
			if !GameState._player_has_guessed(playerId):
				GameState._player_guess(playerId, guess, ui_countdown_timer.get_time_left())
				players_answered += 1
				_update_ui_player_pannel_locked.rpc(true, playerId)
				if players_answered >= GameState.PlayerCount:
					_end_of_quiz_phase()
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
##used by the server to decide on the order questions will be presented
func _generate_answer_order():
	var available_indexes = [0, 1, 2, 3]
	local_answer_order = [0, 1, 2, 3]
	local_answer_order[0] = available_indexes.pop_at(randi() % available_indexes.size())
	local_answer_order[1] = available_indexes.pop_at(randi() % available_indexes.size())
	local_answer_order[2] = available_indexes.pop_at(randi() % available_indexes.size())
	local_answer_order[3] = available_indexes.pop_at(randi() % available_indexes.size())
	pass
	
##uses the given questionIndex to find the corrisponding question in the master_question_data array
##after it will go through the selected questions chances and store them in the chances_set
func _next_question_data_and_store_chances(questionIndex, selected_index):
	var nextQuestion = master_question_data.pop_at(selected_index)
	for chance in nextQuestion["chances"]:
		if !chances_set.has(chance):
			chances_set[chance] = [questionIndex]
		else:
			chances_set[chance].append(questionIndex)
	return nextQuestion

func _start_quiz_server():
	# quiz data should already be loaded onto clients
	ui_countdown_timer.start(GameState.quizOptions.timer)
	ui_countdown_timer.timeout.connect(_end_of_quiz_phase)
	current_index = 0
	GameState._reset_players()
	for i in range(GameState.PlayerCount):
		var player = GameState.players[GameState.playerNumberToIds[i]]
		ui_player_names[i].text = player["name"]
		ui_player_scores[i].text = str(player["score"])
		ui_players[i].visible = true
		pass
	
	GameState.GameStarted = true
	pass

func _end_of_quiz_phase():
	var current_question = GameState.CurrentQuizQuestions[current_index]
	GameState._player_correctness(correct_answer,1000)
	GameState._add_chance_hits(current_index)
	GameState._update_profile_statistics(current_question["uuid"])
	#just end quesiton immediately for now
	_next_question()
	pass
	
func _render_answers_track_correct(current_question, question_order):
	correct_answer = question_order[0]
	ui_answers[correct_answer].text = current_question["correct"]
	ui_answers[question_order[1]].text = current_question["wrong"][0]
	ui_answers[question_order[2]].text = current_question["wrong"][1]
	ui_answers[question_order[3]].text = current_question["wrong"][2]

func _next_question():
	# play animations?
	# set player pannel graphics back to their unlocked state
	for playerId in GameState.players.keys():
		_update_ui_player_pannel_locked.rpc(false, playerId)
		pass
		
	current_index += 1
	var scores = {}
	for key in GameState.players.keys():
		scores[key] = GameState.players[key]["score"]
		pass
	if current_index < GameState.CurrentQuizQuestions.size():
		_sync_update_scores_on_clients.rpc(scores)
		_sync_update_question_on_clients.rpc(current_index)
		post_timer = 10.0
		players_answered = 0
		GameState._reset_guesses()
		loaded = false
		_generate_answer_order()
		_sync_answer_order.rpc(local_answer_order)
		ui_countdown_timer.start(GameState.quizOptions.timer)
	else:
		_sync_update_scores_on_clients.rpc(scores)
		
		# we need to transcribe profile data into its own array to send using rpc
		# as rpc will refuse to send typed objects for security reasons
		var playersData = {}
		for key in GameState.players.keys():
			playersData[key] = GameState.players[key].profileData
			pass
		
		_sync_and_save_client_profile_statistics.rpc(playersData)
		_show_end_of_quiz_screen.rpc()
	pass
	
func _ui_hide_player_statuses(player_number):
	ui_players[player_number].player_case.status_row.status_a.visible = false
	ui_players[player_number].player_case.status_row.status_b.visible = false
	ui_players[player_number].player_case.status_row.status_c.visible = false
	pass
#endregion

func countdown_clock():
	var time_left = ui_countdown_timer.get_time_left()
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]
	
func _load_question_refresh_scores():
	if !loaded:
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
	var i = 0
	for question in master_question_data:
		var tagMatch = false
		for tag in GameState.TagsToExclude:
			if tag in question:
				tagMatch = true
				break
		if !tagMatch:
			master_question_data[i] = question
			i += 1
	pass
	
func _load_master_chances():
	var file = FileAccess.open("res://data/chance_data.json", FileAccess.READ)
	if file:
		master_chances_data = JSON.parse_string(file.get_as_text())
		file.close()
	pass

func _clean_master_questions():
	master_question_data = []
	pass
	
func _clean_chance_set_and_master():
	chances_set = {}
	master_chances_data = []
	pass
	
func _select_quiz_questions(quizSize):
	GameState.CurrentQuizQuestions = []
	for i in range(quizSize):
		if master_question_data.size() == 0:
			break
		GameState.CurrentQuizQuestions.append(_next_question_data_and_store_chances(i, randi() % master_question_data.size()))
	pass
	
func _prepare_quiz_chances(chance_count):
	GameState.CurrentChances = []
	for i in range(chance_count):
		if chances_set.keys().size() == 0:
			break
		_next_chance()

func _next_chance():
	var next_chance = chances_set.keys()[randi() % chances_set.keys().size()]
	var description = ""
	for chance in master_chances_data:
		if chance["uuid"] == next_chance:
			GameState._add_chance(chance["name"], chance["description"], chance["type"], chance["uuid"], chance["correct"], chances_set[next_chance])
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
	
	print("!Debug")
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
		
	print("!Debug")
	for test in scoreOrder:
		print(test)
	
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
