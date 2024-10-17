extends Control

var json_data = {
	"questions": []
}

var question_content = {
	"name": "enter name here",
	"question": "enter question here",
	"a": "enter answer a",
	"b": "enter answer b",
	"c": "enter answer c",
	"d": "enter answer d",
	"correct": "enter correct selection",
	"explainer": "enter post prompt text or clear",
	"tags": "enter , delimited list of tags for this question"
}

@onready var questions_container = $VBoxContainer/Questions
@onready var popup_dialog = $Popup
@onready var question_name = $Popup/Name
@onready var question_text = $Popup/Text
@onready var question_answer_a = $Popup/a
@onready var question_answer_b = $Popup/b
@onready var question_answer_c = $Popup/c
@onready var question_answer_d = $Popup/d
@onready var question_answer_correct = $Popup/correct
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
	question_answer_a.text = question_content["a"]
	question_answer_b.text = question_content["b"]
	question_answer_c.text = question_content["c"]
	question_answer_d.text = question_content["d"]
	question_answer_correct.text = question_content["correct"]
	question_post_prompt.text = question_content["explainer"]
	question_tags.text = question_content["tags"]
	popup_dialog.popup()

func _on_edit_question_button_pressed():
	editing_index = questions_container.get_selected_items()[0];
	if json_data["questions"].size() > 0:
		question_name.text = json_data["questions"][editing_index]["name"]
		question_text.text = json_data["questions"][editing_index]["question"]
		question_answer_a.text = json_data["questions"][editing_index]["a"]
		question_answer_b.text = json_data["questions"][editing_index]["b"]
		question_answer_c.text = json_data["questions"][editing_index]["c"]
		question_answer_d.text = json_data["questions"][editing_index]["d"]
		question_answer_correct.text = json_data["questions"][editing_index]["correct"]
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
	new_question["a"] = question_answer_a.text
	new_question["b"] = question_answer_b.text
	new_question["c"] = question_answer_c.text
	new_question["d"] = question_answer_d.text
	new_question["correct"] = question_answer_correct.text
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
	var json_string = JSON.stringify(json_data)
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
