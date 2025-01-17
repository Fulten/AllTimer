extends Control

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
var pre_timer = 10.0
var post_timer = 10.0
var current_index = 0
var correct_answer = 0
var loaded = false
var players_answered = 0
var player_input = "p%s_answer_%s"

signal end_of_quiz

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _start_quiz():
	countdown_timer.start(30)
	countdown_timer.timeout.connect(_handle_end_question)
	current_index = 0
	GameState._reset_players()
	for i in range(GameState.PlayerCount):
		player_names[i].text = GameState._player_name(i)
		player_scores[i].text = str(GameState._player_score(i))
		players[i].visible = true
	pass

func countdown_clock():
	var time_left = countdown_timer.get_time_left()
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	countdown_text.text = "%02d:%02d" % countdown_clock()
	_load_question_refresh_scores()
	pass


func _handle_end_question():
	GameState._player_correctness(correct_answer,1000)
	GameState._add_chance_hits(current_index)
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


func _next_question():
	# play animations?
	current_index += 1
	if current_index < GameState.CurrentQuizQuestions.size():
		post_timer = 10.0
		players_answered = 0
		GameState._reset_guesses()
		loaded = false
		countdown_timer.start(30)
	else:
		# get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn") send a signal instead
		end_of_quiz.emit()
		queue_free()


func _check_player_input_record_guess(player_index,event):
	for i in range(4):
		if event.is_action_pressed(player_input % [player_index,i]):
			GameState._player_guess(player_index,i,countdown_timer.get_time_left())
			players_answered += 1
			if players_answered >= GameState.PlayerCount:
				_handle_end_question()
			return true
	return false

func _player_input(player_index, guess):
	if !countdown_timer.is_stopped():
		if !GameState._player_has_guessed(player_index):
			GameState._player_guess(player_index, guess, countdown_timer.get_time_left())
			players_answered += 1
			if players_answered >= GameState.PlayerCount:
				_handle_end_question()
	pass

func _input_old(event):
	if loaded:
		if event.is_action_pressed("next_question"):
			_handle_end_question()
		if !countdown_timer.is_stopped():
			for i in range(GameState.PlayerCount):
				if !GameState._player_has_guessed(i):
					if _check_player_input_record_guess(i,event):
						break
