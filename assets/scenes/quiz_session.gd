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
var current_index = 0
var correct_answer = 0
var loaded = false

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
	_load_question_refresh_scores()
	pass

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
		GameState._increase_score(0,100)
		loaded = false
	else:
		get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
	
func _input(event):
	if event.is_action_pressed("next_question"):
		_next_question()
	
