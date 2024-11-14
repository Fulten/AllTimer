extends Control

const uuid_util = preload('res://addons/uuid/uuid.gd')
var json_data = []

var chance_content = {
	"uuid": "",
	"name": "",
	"type": "QUESTION",
	"correct": false,
	"description": ""
}

@onready var chances_container = $VBoxContainer/Chances
@onready var popup_dialog = $Popup
@onready var chance_name = $Popup/Name
@onready var chance_type = $Popup/type
@onready var chance_correct = $Popup/correct
@onready var chance_description = $Popup/Description
@onready var add_button = $"VBoxContainer/Add Chance"
@onready var edit_button = $"VBoxContainer/Edit Chance"
@onready var delete_button = $"VBoxContainer/Delete Chance"
@onready var save_button = $Popup/SaveButton

var editing_index: int = -1
var editing_uuid: String;

func _ready():
	add_button.pressed.connect(_on_add_chance_button_pressed)
	edit_button.pressed.connect(_on_edit_chance_button_pressed)
	delete_button.pressed.connect(_on_delete_chance_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	
	_load_chances()

func _on_add_chance_button_pressed():
	editing_index = -1
	editing_uuid = uuid_util.v4()
	chance_name.text = chance_content["name"]
	chance_description.text = chance_content["description"]
	chance_type.text = chance_content["type"]
	chance_correct.button_pressed = chance_content["correct"]
	popup_dialog.popup()

func _on_edit_chance_button_pressed():
	editing_index = 0
	if !chances_container.get_selected_items().is_empty():
		editing_index = chances_container.get_selected_items()[0];
	if json_data.size() > 0:
		editing_uuid = json_data[editing_index]["uuid"]
		chance_name.text = json_data[editing_index]["name"]
		chance_description.text = json_data[editing_index]["description"]
		chance_type.text = json_data[editing_index]["type"]
		chance_correct.button_pressed = json_data[editing_index]["correct"]
		popup_dialog.popup()

func _on_delete_chance_button_pressed():
	if json_data.size() > 0 && !chances_container.get_selected_items().is_empty():
		json_data.remove_at(chances_container.get_selected_items()[0])
		_save_chances()
		_load_chances()

func _on_save_button_pressed():
	var new_chance = chance_content.duplicate()
	new_chance["uuid"] = editing_uuid
	new_chance["name"] = chance_name.text
	new_chance["description"] = chance_description.text
	new_chance["type"] = chance_type.text
	new_chance["correct"] = chance_correct.is_pressed()
	if editing_index == -1:
		json_data.append(new_chance)
	else:
		json_data[editing_index] = new_chance
	
	_save_chances()
	_load_chances()
	popup_dialog.hide()

func _save_chances():
	var json_string = JSON.stringify(json_data, "\t")
	var file = FileAccess.open("res://chance_data.json", FileAccess.WRITE)
	file.store_string(json_string)
	file.close()

func _load_chances():
	var file = FileAccess.open("res://chance_data.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		json_data = JSON.parse_string(json_string)
		file.close()
	chances_container.clear()
	for chance in json_data:
		chances_container.add_item(chance["name"])
