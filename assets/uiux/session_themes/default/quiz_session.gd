extends Control

@onready var questions_name = $session_organizer/question_header/question_name
@onready var questions_index = $session_organizer/question_header/question_index
@onready var questions_body = $session_organizer/question_body
@onready var questions_answer1 = $session_organizer/HBoxContainer/answer_organizer/answer_pair1/a1
@onready var questions_answer2 = $session_organizer/HBoxContainer/answer_organizer/answer_pair2/a2
@onready var questions_answer3 = $session_organizer/HBoxContainer/answer_organizer/answer_pair3/a3
@onready var questions_answer4 = $session_organizer/HBoxContainer/answer_organizer/answer_pair4/a4
var current_index = 0
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
		questions_answer1.text = current_question["correct"]
		questions_answer2.text = current_question["wrong_1"]
		questions_answer3.text = current_question["wrong_2"]
		questions_answer4.text = current_question["wrong_3"]
		loaded = true
