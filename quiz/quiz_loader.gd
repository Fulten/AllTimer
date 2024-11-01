extends Node

var master_question_data = []
var chances_set = {}

var master_chances_data = []

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	_prepare_quiz_questions(10, GameState.TagsToExclude)
	_prepare_quiz_chances(3, GameState.TagsToExclude)
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
		if !tagMatch:
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
		GameState.CurrentQuizQuestions.append(_next_question_store_chances())
	_clean_master_questions()

func _next_question_store_chances():
	var next_question = master_question_data.pop_at(randi() % master_question_data.size())
	for chance in next_question["chances"]:
		if !chances_set.has(chance):
			chances_set[chance] = true

func _clean_chance_set_and_master():
	chances_set = {}
	master_chances_data = []

func _load_master_chances():
	var file = FileAccess.open("res://chance_data.json", FileAccess.READ)
	if file:
		master_chances_data = JSON.parse_string(file.get_as_text())
		file.close()

func _prepare_quiz_chances(chance_count, chances_in_game):
	GameState.CurrentChances = []
	for i in range(chance_count):
		if chances_set.keys().size() == 0:
			break
		_next_chance()
	_clean_chance_set_and_master()

func _next_chance():
	var next_chance = chances_set.keys()[randi() % chances_set.keys().size()]
	chances_set.remove[next_chance]
	var description = ""
	for chance in master_chances_data:
		if chance["name"] == next_chance:
			description = chance["description"]
			break
	GameState._add_chance(next_chance, description)
