extends Control

# refrences to quiz ui elements
@onready var questions_name = $session_organizer/question_header/question_name
@onready var questions_index = $session_organizer/question_header/question_index
@onready var countdown_timer = $session_organizer/question_header/Countdown
@onready var countdown_text = $session_organizer/CountdownLabel
@onready var questions_body = $session_organizer/question_body
@onready var post_question = $post_question
@onready var players = [$players_region/player_case,
	$players_region/player_case2,
	$players_region/player_case3,
	$players_region/player_case4]
@onready var answers = [$session_organizer/HBoxContainer/answer_organizer/answer_pair1/a1,
	$session_organizer/HBoxContainer/answer_organizer/answer_pair2/a2,
	$session_organizer/HBoxContainer/answer_organizer/answer_pair3/a3,
	$session_organizer/HBoxContainer/answer_organizer/answer_pair4/a4]
@onready var player_names = [$players_region/player_case/player1_name,
	$players_region/player_case2/player2_name,
	$players_region/player_case3/player3_name,
	$players_region/player_case4/player4_name]
@onready var player_scores = [$players_region/player_case/status_row/score,
	$players_region/player_case2/status_row/score,
	$players_region/player_case3/status_row/score,
	$players_region/player_case4/status_row/score]
	
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

# Called when the node enters the scene tree for the first time.
func _ready():
	if multiplayer.is_server():
		_load_quiz_data()
		_select_quiz_questions(QUIZ_SIZE)
		_prepare_quiz_chances(CHANCE_COUNT)
		_save_quiz_questions_locally()
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
			_send_clock_reading.rpc(local_clock_reading)
			_load_question_refresh_scores()
			countdown_text.text = "%02d:%02d" % local_clock_reading
			pass
		else:
			_load_question_refresh_scores()
			countdown_text.text = "%02d:%02d" % local_clock_reading
			pass
		pass
	pass

func _input(event):
	# ignore input until quiz starts
	if !GameState.GameStarted:
		return
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

@rpc("any_peer", "reliable")
func _send_clock_reading(server_clock):
	local_clock_reading = server_clock
	pass

# called on the server whenever a player inputs a guess
@rpc("any_peer", "reliable")
func _player_guess(playerId, guess):
	# proccess answer then send updated result to players
	if multiplayer.is_server():
		if !countdown_timer.is_stopped():
			if !GameState._player_has_guessed(playerId):
				GameState._player_guess(playerId, guess, countdown_timer.get_time_left())
				players_answered += 1
				if players_answered >= GameState.PlayerCount:
					_end_of_quiz_phase()
					pass
			pass
	pass

# called by the server host on clients to send question and chance data to peers
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
		
		GameState.CurrentQuizQuestions.append(_next_question_data_store_chances(i, questionIndex))
		i += 1
		pass
	
	_clean_master_questions()
	_clean_chance_set_and_master()
	_player_loaded.rpc_id(1, multiplayer.get_unique_id())
	pass

func _generate_answer_order():
	var available_indexes = [0, 1, 2, 3]
	local_answer_order = [0, 1, 2, 3]
	
	local_answer_order[0] = available_indexes.pop_at(randi() % available_indexes.size())
	local_answer_order[1] = available_indexes.pop_at(randi() % available_indexes.size())
	local_answer_order[2] = available_indexes.pop_at(randi() % available_indexes.size())
	local_answer_order[3] = available_indexes.pop_at(randi() % available_indexes.size())
	pass

@rpc("authority", "reliable")
func _sync_answer_order(server_answer_order):
	local_answer_order = server_answer_order
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
	
func _start_quiz_server():
	# quiz data should already be loaded onto clients
	countdown_timer.start(GameState.quizOptions.timer)
	countdown_timer.timeout.connect(_end_of_quiz_phase)
	current_index = 0
	GameState._reset_players()
	for i in range(GameState.PlayerCount):
		var player = GameState.players[GameState.playerNumberToIds[i]]
		player_names[i].text = player["name"]
		player_scores[i].text = str(player["score"])
		players[i].visible = true
		pass
	
	GameState.GameStarted = true
	pass
		
@rpc("authority", "reliable")
func _start_quiz_client():
	GameState._reset_players()
	for i in range(GameState.PlayerCount):
		var player = GameState.players[GameState.playerNumberToIds[i]]
		player_names[i].text = player["name"]
		player_scores[i].text = str(player["score"])
		players[i].visible = true
		pass
	
	GameState.GameStarted = true
	pass
	
func _end_of_quiz_phase():
	GameState._player_correctness(correct_answer,1000)
	GameState._add_chance_hits(current_index)
	#just end quesiton immediately for now
	_next_question()
	pass

func _next_question():
	# play animations?
	current_index += 1
	var scores = {}
	for key in GameState.players.keys():
		scores[key] = GameState.players[key]["score"]
		pass
	if current_index < GameState.CurrentQuizQuestions.size():
		_update_scores_on_clients.rpc(scores)
		_update_question_on_clients.rpc(current_index)
		post_timer = 10.0
		players_answered = 0
		GameState._reset_guesses()
		loaded = false
		countdown_timer.start(GameState.quizOptions.timer)
	else:
		_end_of_quiz.rpc()
	pass

@rpc("authority", "reliable")
func _update_question_on_clients(question_index):
	current_index = question_index
	loaded = false
	pass
	
@rpc("authority", "reliable")
func _update_scores_on_clients(scores):
	for key in scores.keys():
		GameState.players[key]["score"] = scores[key]
		pass
	pass

func countdown_clock():
	var time_left = countdown_timer.get_time_left()
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]
	
func _load_question_refresh_scores():
	if !loaded:
		questions_index.text = str(current_index + 1)
		var current_question = GameState.CurrentQuizQuestions[current_index]
		questions_name.text = current_question["name"]
		questions_body.text = current_question["question"]
		post_question.text = current_question["explainer"]
		_render_answers_track_correct(current_question, local_answer_order)
		for i in range(GameState.PlayerCount):
			player_scores[i].text = str(GameState.players[GameState.playerNumberToIds[i]]["score"])
		loaded = true

func _render_answers_track_correct(current_question, question_order):
	correct_answer = question_order[0]
	answers[correct_answer].text = current_question["correct"]
	answers[question_order[1]].text = current_question["wrong"][0]
	answers[question_order[2]].text = current_question["wrong"][1]
	answers[question_order[3]].text = current_question["wrong"][2]

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
		GameState.CurrentQuizQuestions.append(_next_question_data_store_chances(i, randi() % master_question_data.size()))
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
	
func _next_question_data_store_chances(questionIndex, selected_index):
	var nextQuestion = master_question_data.pop_at(selected_index)
	for chance in nextQuestion["chances"]:
		if !chances_set.has(chance):
			chances_set[chance] = [questionIndex]
		else:
			chances_set[chance].append(questionIndex)
	return nextQuestion
	
func _save_quiz_questions_locally():
	for question in GameState.CurrentQuizQuestions:
		local_question_set_uuids.append(question["uuid"])
		pass
	pass

@rpc("authority", "call_local", "reliable")
func _end_of_quiz():
	GameState._reset_quiz_state()
	end_of_quiz.emit()
	queue_free()
	pass
