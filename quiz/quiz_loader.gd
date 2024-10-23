extends Node

var quiz_questions = []

var master_question_data = []

var question_content = { #todo update to a global.gd for autoload and replace in quiz_loader and editor for consistency
	"name": "",
	"question": "",
	"correct": "",
	"wrong_1": "",
	"wrong_2": "",
	"wrong_3": "",
	"explainer": "",
	"tags": ""
}

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	_prepare_quiz_questions(10, []) # Replace with function body.
	pass 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _load_questions(excluded_tags):
	var file = FileAccess.open("res://question_data.json", FileAccess.READ)
	if file:
		master_question_data = JSON.parse_string(file.get_as_text())["questions"]
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

func _clean_questions():
	master_question_data = {"questions": []}

func _prepare_quiz_questions(quiz_size, excluded_tags):
	_load_questions(excluded_tags)
	for i in range(quiz_size):
		if master_question_data.size() == 0:
			break
		quiz_questions.append(master_question_data.pop_at(randi() % master_question_data.size()))
