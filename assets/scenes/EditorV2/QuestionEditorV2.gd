extends Control

var chances_raw = []
var questions_raw = []

var questions = {}
var chances = {}

var file_questions_data = "res://question_data.json"
var file_chances_data = "res://chance_data.json"

var ui_question_state_icons = [
	preload("res://assets/scenes/EditorV2/Style/GreenO.png"),
	preload("res://assets/scenes/EditorV2/Style/YellowDash.png"),
	preload("res://assets/scenes/EditorV2/Style/RedX.png")]
	
var ui_label_settings = [
	preload("res://assets/scenes/EditorV2/Style/Question_Editor_Labels.tres"),
	preload("res://assets/scenes/EditorV2/Style/Question_Editor_Labels_yellow.tres"),
	preload("res://assets/scenes/EditorV2/Style/Question_Editor_Labels_red.tres")]
	
var ui_entry_node_refrence = {
	"tags": ["HBoxParent/VBoxQuestionEditor/Header/HBoxTags/Label", 1],
	"chances": ["HBoxParent/VBoxQuestionEditor/QuestionChances", 1],
	"explainer": ["HBoxParent/VBoxQuestionEditor/Header/HBoxPostText/Label", 1],
	"name": ["HBoxParent/VBoxQuestionEditor/Header/HBoxName/Label", 2],
	"body": ["HBoxParent/VBoxQuestionEditor/Header/HBoxQuestionText/Label", 2],
	"correct": ["HBoxParent/VBoxQuestionEditor/Answers/HBoxCorrect/Label", 2],
	"wrong0": ["HBoxParent/VBoxQuestionEditor/Answers/HBoxWrong1/Label", 2],
	"wrong1": ["HBoxParent/VBoxQuestionEditor/Answers/HBoxWrong2/Label", 2],
	"wrong2": ["HBoxParent/VBoxQuestionEditor/Answers/HBoxWrong3/Label", 2],}

class Question:
	var name: String
	var body: String
	var explainer: String
	var correct: String
	var wrong
	var tags
	var chances
	
	var listIndex: int
	var errorState: int
	var errorEntries = []
	
	## converts raw question data into formatted question object
	## should also handel error checking for bad formatting
	func _build_from_raw(
		i_name: String, 
		i_body: String, 
		i_correct: String, 
		i_wrong, 
		i_explainer: String,
		i_tags,
		i_chances):
		
		name = i_name
		body = i_body
		correct = i_correct
		wrong = i_wrong
		explainer = i_explainer
		tags = i_tags
		chances = i_chances
		
		listIndex = -1
		_check_error_state()
	
	## checks for invalid entry data and record it in error entries
	func _check_error_state():
		errorState = 0
		# optional
		if !tags:
			errorState = 1
			errorEntries.append("tags")
		if !chances:
			errorEntries.append("chances")
			errorState = 1
		if explainer == "":
			errorState = 1
			errorEntries.append("explainer")
			
		# critical
		if name == "":
			errorState = 2
			errorEntries.append("name")
		if body == "":
			errorState = 2
			errorEntries.append("body")
		if  correct == "":
			errorState = 2
			errorEntries.append("correct")
		if wrong[0] == "":
			errorState = 2
			errorEntries.append("wrong0")
		if wrong[1] == "":
			errorState = 2
			errorEntries.append("wrong1")
		if wrong[2] == "":
			errorState = 2
			errorEntries.append("wrong2")
			
		pass
		
	## converts formatted object into raw data
	func _convert_to_raw():
		#TODO
		pass
	pass
	
class Chance:
	var name: String
	var description: String
	var type: String
	var correct: bool
	
	func _build_from_raw(
		i_name: String,
		i_description: String,
		i_type: String,
		i_correct: bool):
		
		name = i_name
		description = i_description
		type = i_type
		correct = i_correct
	
	func _convert_to_raw():
		#TODO
		pass
	
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i(300,100))
	DisplayServer.window_set_size(Vector2i(1240,700))
	
	_io_read_questions(file_questions_data)
	_io_read_chances(file_chances_data)
	
	_UI_update_question_list()
	pass

## updates the item list "QuestionList"
func _UI_update_question_list():
	%QuestionList.clear()
	
	for key in questions:
		questions[key].listIndex = (%QuestionList.add_item(questions[key].name, ui_question_state_icons[questions[key].errorState]))
	pass

## fill out the detailed question information in the ui
func _UI_present_question_data(uuid):
	#simple information
	$"HBoxParent/VBoxQuestionEditor/Question Hash/Text".text = uuid
	$HBoxParent/VBoxQuestionEditor/Header/HBoxName/Text.text = questions[uuid].name
	$HBoxParent/VBoxQuestionEditor/Header/HBoxQuestionText/Text.text = questions[uuid].body
	$HBoxParent/VBoxQuestionEditor/Header/HBoxPostText/Text.text = questions[uuid].explainer
	
	# answers
	$HBoxParent/VBoxQuestionEditor/Answers/HBoxCorrect/Text.text = questions[uuid].correct
	$HBoxParent/VBoxQuestionEditor/Answers/HBoxWrong1/Text.text = questions[uuid].wrong[0]
	$HBoxParent/VBoxQuestionEditor/Answers/HBoxWrong2/Text.text = questions[uuid].wrong[1]
	$HBoxParent/VBoxQuestionEditor/Answers/HBoxWrong3/Text.text = questions[uuid].wrong[2]
	pass
	
	#formmated information
	var tagsText = ""
	for tag in questions[uuid].tags:
		tagsText += tag + ", "
	tagsText = tagsText.erase(tagsText.length()-2,2)
	$HBoxParent/VBoxQuestionEditor/Header/HBoxTags/Text.text = tagsText
	_UI_update_chances_list(uuid)
	_UI_highlight_error_state(questions[uuid].errorEntries)
	
func _UI_update_chances_list(question_uuid):
	%ChancesList.clear()
	for chance_uuid in questions[question_uuid].chances:
		%ChancesList.add_item(chances[chance_uuid].name)
	pass
	
func _UI_highlight_error_state(errorEntries):
	for key in ui_entry_node_refrence:
		get_node(ui_entry_node_refrence[key][0]).label_settings = ui_label_settings[0]
	
	for key in errorEntries:
		get_node(ui_entry_node_refrence[key][0]).label_settings = ui_label_settings[ui_entry_node_refrence[key][1]]
		pass
	pass
	
#region file IO
func _io_read_questions(file_name: String):
	print("!INFO: Reading Question Data")
	var file = FileAccess.open(file_name, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		questions_raw = JSON.parse_string(json_string)
		file.close()
	else:
		print("!!ERROR: Unable to access [\"%s\"]" % file_name)
		return
	questions.clear()
	for question_raw in questions_raw:
		var question = Question.new()
		question._build_from_raw(
			question_raw["name"],
			question_raw["question"],
			question_raw["correct"],
			question_raw["wrong"],
			question_raw["explainer"],
			question_raw["tags"],
			question_raw["chances"])
		questions[question_raw["uuid"]] = question
	pass
	
func _io_write_questions(file_name: String):
	
	pass

func _io_read_chances(file_name: String):
	print("!INFO: Reading Chances Data")
	var file = FileAccess.open(file_name, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		chances_raw = JSON.parse_string(json_string)
		file.close()
	chances.clear()
	for chance_raw in chances_raw:
		var chance = Chance.new()
		chance._build_from_raw(
			chance_raw["name"],
			chance_raw["description"],
			chance_raw["type"],
			chance_raw["correct"])
		chances[chance_raw["uuid"]] = chance
	pass
	
func _io_write_chances(file_name: String):
	
	pass
#endregion

#region UI interactions
## refresh question list from file
func _on_btn_reload_button_up():
	_io_read_questions(file_questions_data)
	_UI_update_question_list()
	pass

## (disabled) doesn't make much sense with the current ui layout
## load the questions contents into the screen
func _on_btn_edit_button_up():
	pass

## create new blank question entry
func _on_btn_new_button_up():
	pass

func _on_btn_delete_button_up():
	pass
	
func _on_question_list_item_selected(index):
	for key in questions:
		if questions[key].listIndex == index:
			_UI_present_question_data(key)

#endregion

