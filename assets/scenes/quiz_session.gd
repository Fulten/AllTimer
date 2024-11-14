extends Control

@onready var questions_name = $session_organizer/question_header/question_name
@onready var questions_index = $session_organizer/question_header/question_index
@onready var questions_body = $session_organizer/question_body
@onready var post_question = $post_question
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
var timer = 30.0
var current_index = 0
var correct_answer = 0
var loaded = false
var players_answered = 0
var player_guess = [-1,-1,-1,-1]
var player_guess_time = [-1,-1,-1,-1]
var player_correctness = [false,false,false,false]

# Called when the node enters the scene tree for the first time.
func _ready():
	current_index = 0
	GameState._reset_players()
	for i in range(GameState.PlayerCount):
		player_names[i].text = GameState._player_name(i)
		player_scores[i].text = str(GameState._player_score(i))
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_update_timer(delta)
	_handle_end_question()
	_load_question_refresh_scores()
	pass

func _update_timer(delta):
	if players_answered >= GameState.PlayerCount:
		timer = 0
	else:
		timer -= delta

func _handle_end_question():
	if timer <= 0:
		_determine_player_correctness()
		#just end quesiton immediately for now
		_next_question()

func _load_question_refresh_scores():
	if !loaded:
		questions_index.text = str(current_index + 1)
		var current_question = GameState.CurrentQuizQuestions[current_index]
		questions_name.text = current_question["name"]
		questions_body.text = current_question["question"]
		post_question.text = current_question["explainer"]
		_randomize_answers_track_correct(current_question)
		for i in range(GameState.PlayerCount):
			player_scores[i].text = str(GameState._player_score(i))
		loaded = true

func _randomize_answers_track_correct(current_question):
	var available_indexes = [0, 1, 2, 3]
	correct_answer = available_indexes.pop_at(randi() % available_indexes.size())
	answers[correct_answer].text = current_question["correct"]
	answers[available_indexes.pop_at(randi() % available_indexes.size())].text = current_question["wrong"][0]
	answers[available_indexes.pop_at(randi() % available_indexes.size())].text = current_question["wrong"][1]
	answers[available_indexes.pop_at(randi() % available_indexes.size())].text = current_question["wrong"][2]
	
func _determine_player_correctness():
	for i in range(GameState.PlayerCount):
		player_correctness[i] = player_guess[i] == correct_answer

func _next_question():
	# play animations?
	current_index += 1
	if current_index < GameState.CurrentQuizQuestions.size():
		for i in range(GameState.PlayerCount):
			if player_correctness[i]:
				GameState._increase_score(0,100)
			else:
				GameState._increase_score(0,-100)
		GameState._add_chance_hits(current_index,player_correctness)
		timer = 30.0
		_reset_guesses()
		loaded = false
	else:
		get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")

func _reset_guesses():
	players_answered = 0
	for i in range(GameState.PlayerCount):
		player_guess[i] = -1
		player_guess_time[i] = -1

func _input(event):
	if loaded:
		if event.is_action_pressed("next_question"):
			timer = 0
		if timer > 0 && player_guess[0] < 0:
			if event.is_action_pressed("answer_1"):
				player_guess[0] = 0
				player_guess_time[0] = timer
				players_answered += 1
			elif event.is_action_pressed("answer_2"):
				player_guess[0] = 1
				player_guess_time[0] = timer
				players_answered += 1
			elif event.is_action_pressed("answer_3"):
				player_guess[0] = 2
				player_guess_time[0] = timer
				players_answered += 1
			elif event.is_action_pressed("answer_4"):
				player_guess[0] = 3
				player_guess_time[0] = timer
				players_answered += 1
