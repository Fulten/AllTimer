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
	
signal end_of_quiz
signal player_loaded

var pre_timer = 10.0
var post_timer = 10.0
var current_index = 0
var correct_answer = 0
var loaded = false
var players_answered = 0
var player_input = "p_answer_%s"

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_quiz_data()
	player_loaded.emit()
	print("player [%s] loaded" % multiplayer.get_unique_id())
	pass
	
func _process(delta):
	
	pass

func _input(event):
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
func _player_guess(playerId, guess):
	print("id: [%s], guess: [%s]" % [playerId, guess])
	pass

# called by the server when all the players are loaded in
@rpc("authority", "call_local", "reliable")
func _start_quiz():
	print("the quiz has been started by server")
	pass
	

func _load_quiz_data():
	_load_master_questions(GameState.TagsToExclude)
	pass

func _load_master_questions(excluded_tags):
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
	
func _clean_master_questions():
	master_question_data = []
