extends Node

var master_question_data = []

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	_prepare_quiz_questions(10, GameState.TagsToExclude)
	
	pass 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _load_master_questions(excluded_tags):
	var file = FileAccess.open("res://question_data.json", FileAccess.READ)
	if file:
		master_question_data = JSON.parse_string(file.get_as_text())
		file.close()
	var i = 0
	for question in master_question_data:
		var tagMatch = false
		for tag in excluded_tags:
			if tag in question:
				tagMatch = true
				break
		if tagMatch:
			master_question_data[i] = question
			i += 1
	master_question_data = Array(master_question_data).slice(0, i)

func _clean_master_questions():
	master_question_data = []

func _prepare_quiz_questions(quiz_size, excluded_tags):
	_load_master_questions(excluded_tags)
	GameState.CurrentQuizQuestions = []
	for i in range(quiz_size):
		if master_question_data.size() == 0:
			break
		GameState.CurrentQuizQuestions.append(master_question_data.pop_at(randi() % master_question_data.size()))
	_clean_master_questions()
