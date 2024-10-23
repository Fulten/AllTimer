extends Control

var json_data = {
	"questions": []
}

var question_content = {
	"name": "",
	"question": "",
	"correct": "",
	"wrong_1": "",
	"wrong_2": "",
	"wrong_3": "",
	"explainer": "",
	"tags": ""
}

@onready var questions_container = $VBoxContainer/Questions
@onready var popup_dialog = $Popup
@onready var question_name = $Popup/Name
@onready var question_text = $Popup/Text
@onready var question_answer_correct = $Popup/correct
@onready var question_answer_wrong1 = $Popup/wrong1
@onready var question_answer_wrong2 = $Popup/wrong2
@onready var question_answer_wrong3 = $Popup/wrong3
@onready var question_post_prompt = $Popup/prompt
@onready var question_tags = $Popup/tags
@onready var add_button = $"VBoxContainer/Add Question"
@onready var edit_button = $"VBoxContainer/Edit Question"
@onready var delete_button = $"VBoxContainer/Delete Question"
@onready var save_button = $Popup/SaveButton

var editing_index: int = -1

func _ready():
	add_button.pressed.connect(_on_add_question_button_pressed)
	edit_button.pressed.connect(_on_edit_question_button_pressed)
	delete_button.pressed.connect(_on_delete_question_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	
	_load_questions()

func _on_add_question_button_pressed():
	editing_index = -1
	question_name.text = question_content["name"]
	question_text.text = question_content["question"]
	question_answer_correct.text = question_content["correct"]
	question_answer_wrong1.text = question_content["wrong_1"]
	question_answer_wrong2.text = question_content["wrong_2"]
	question_answer_wrong3.text = question_content["wrong_3"]
	question_post_prompt.text = question_content["explainer"]
	question_tags.text = question_content["tags"]
	popup_dialog.popup()

func _on_edit_question_button_pressed():
	editing_index = questions_container.get_selected_items()[0];
	if json_data["questions"].size() > 0:
		question_name.text = json_data["questions"][editing_index]["name"]
		question_text.text = json_data["questions"][editing_index]["question"]
		question_answer_correct.text = json_data["questions"][editing_index]["correct"]
		question_answer_wrong1.text = json_data["questions"][editing_index]["wrong_1"]
		question_answer_wrong2.text = json_data["questions"][editing_index]["wrong_2"]
		question_answer_wrong3.text = json_data["questions"][editing_index]["wrong_3"]
		question_post_prompt.text = json_data["questions"][editing_index]["explainer"]
		question_tags.text = json_data["questions"][editing_index]["tags"]
		popup_dialog.popup()

func _on_delete_question_button_pressed():
	if json_data["questions"].size() > 0:
		json_data["questions"].remove_at(questions_container.get_selected_items()[0])
		_save_questions()
		_load_questions()

func _on_save_button_pressed():
	var new_question = question_content.duplicate()
	new_question["name"] = question_name.text
	new_question["question"] = question_text.text
	new_question["correct"] = question_answer_correct.text
	new_question["wrong_1"] = question_answer_wrong1.text
	new_question["wrong_2"] = question_answer_wrong2.text
	new_question["wrong_3"] = question_answer_wrong3.text
	new_question["explainer"] = question_post_prompt.text
	new_question["tags"] = question_tags.text
	if editing_index == -1:
		json_data["questions"].append(new_question)
	else:
		json_data["questions"][editing_index] = new_question
	
	_save_questions()
	_load_questions()
	popup_dialog.hide()

func _save_questions():
	var json_string = JSON.stringify(json_data, "\t")
	var file = FileAccess.open("res://question_data.json", FileAccess.WRITE)
	file.store_string(json_string)
	file.close()

func _load_questions():
	var file = FileAccess.open("res://question_data.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		json_data = JSON.parse_string(json_string)
		file.close()
	questions_container.clear()
	for question in json_data["questions"]:
		questions_container.add_item(question["name"])
