extends Control

@onready var questions_name = $session_organizer/question_header/question_name
@onready var questions_index = $session_organizer/question_header/question_index
@onready var questions_body = $session_organizer/question_body
@onready var post_question = $post_question
@onready var answers = [$session_organizer/HBoxContainer/answer_organizer/answer_pair1/a1,
	$session_organizer/HBoxContainer/answer_organizer/answer_pair2/a2,
	$session_organizer/HBoxContainer/answer_organizer/answer_pair3/a3,
	$session_organizer/HBoxContainer/answer_organizer/answer_pair4/a4]
var current_index = 0
var correct_answer = 0
var loaded = false

# Called when the node enters the scene tree for the first time.
func _ready():
	current_index = 0
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameState.CurrentQuizQuestions.size() > 0:
		_load_question()
	pass

func _load_question():
	if !loaded:
		questions_index.text = str(current_index + 1)
		var current_question = GameState.CurrentQuizQuestions[current_index]
		questions_name.text = current_question["name"]
		questions_body.text = current_question["question"]
		post_question.text = current_question["explainer"]
		_randomize_answers_track_correct(current_question)
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
	loaded = false
	
func _input(event):
	if event.is_action_pressed("next_question"):
		_next_question()
	
