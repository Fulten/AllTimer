extends Control

const uuid_util = preload('res://addons/uuid/uuid.gd')
var chance_data = []
var json_data = []

var question_content = {
	"uuid": "",
	"name": "",
	"question": "",
	"correct": "",
	"wrong_1": "",
	"wrong_2": "",
	"wrong_3": "",
	"explainer": "",
	"tags": "",
	"chances": ""
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
@onready var question_chances = $Popup/chances
@onready var add_button = $"VBoxContainer/Add Question"
@onready var edit_button = $"VBoxContainer/Edit Question"
@onready var delete_button = $"VBoxContainer/Delete Question"
@onready var save_button = $Popup/SaveButton

var editing_index: int = -1
var editing_uuid: String;


func _ready():
	add_button.pressed.connect(_on_add_question_button_pressed)
	edit_button.pressed.connect(_on_edit_question_button_pressed)
	delete_button.pressed.connect(_on_delete_question_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	
	_load_questions()
	_load_chances()


func _on_add_question_button_pressed():
	editing_index = -1
	editing_uuid = uuid_util.v4()
	question_name.text = ""
	question_text.text = ""
	question_answer_correct.text = ""
	question_answer_wrong1.text = ""
	question_answer_wrong2.text = ""
	question_answer_wrong3.text = ""
	question_post_prompt.text = ""
	question_tags.text = ""
	question_chances.deselect_all()
	popup_dialog.popup()


func _on_edit_question_button_pressed():
	editing_index = 0
	if !questions_container.get_selected_items().is_empty():
		editing_index = questions_container.get_selected_items()[0]
	if json_data.size() > 0:
		editing_uuid = json_data[editing_index]["uuid"]
		question_name.text = json_data[editing_index]["name"]
		question_text.text = json_data[editing_index]["question"]
		question_answer_correct.text = json_data[editing_index]["correct"]
		question_answer_wrong1.text = json_data[editing_index]["wrong"][0]
		question_answer_wrong2.text = json_data[editing_index]["wrong"][1]
		question_answer_wrong3.text = json_data[editing_index]["wrong"][2]
		question_post_prompt.text = json_data[editing_index]["explainer"]
		question_tags.text = _array_to_string(json_data[editing_index]["tags"])
		_select_chance_by_uuids(json_data[editing_index]["chances"])
		popup_dialog.popup()


func _array_to_string(arr: Array) -> String:
	var s = ""
	for i in arr:
		if s == "":
			s = i
		else:
			s += ","+i
	return s


func _on_delete_question_button_pressed():
	if json_data.size() > 0 && !questions_container.get_selected_items().is_empty():
		json_data.remove_at(questions_container.get_selected_items()[0])
		_save_questions()
		_load_questions()


func _on_save_button_pressed():
	var new_question = question_content.duplicate()
	new_question["uuid"] = editing_uuid
	new_question["name"] = question_name.text
	new_question["question"] = question_text.text
	new_question["correct"] = question_answer_correct.text
	new_question["wrong"] = [question_answer_wrong1.text,question_answer_wrong2.text,question_answer_wrong3.text]
	new_question["explainer"] = question_post_prompt.text
	new_question["tags"] = question_tags.text.split(",")
	new_question["chances"] = _selected_chance_uuids()
	if editing_index == -1:
		json_data.append(new_question)
	else:
		json_data[editing_index] = new_question
	
	_save_questions()
	_load_questions()
	question_chances.deselect_all()
	popup_dialog.hide()


func _selected_chance_uuids():
	if question_chances.is_anything_selected():
		var selected_chances = []
		for chance in question_chances.get_selected_items():
			selected_chances.append(question_chances.get_item_metadata(chance))
		return selected_chances
	else:
		return []


func _select_chance_by_uuids(chance_uuids):
	for chance_uuid in chance_uuids:
		for i in range(question_chances.get_item_count()):
			if question_chances.get_item_metadata(i) == chance_uuid:
				question_chances.select(i, false)
			


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
	for question in json_data:
		questions_container.add_item(question["name"])


func _load_chances():
	var file = FileAccess.open("res://chance_data.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		chance_data = JSON.parse_string(json_string)
		file.close()
	question_chances.clear()
	for chance in chance_data:
		var index = question_chances.add_item(chance["name"])
		question_chances.set_item_metadata(index, chance["uuid"])
