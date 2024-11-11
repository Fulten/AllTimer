extends Node

var Players = [{
	"name": "",
	"score": 0
},
{
	"name": "",
	"score": 0
},
{
	"name": "",
	"score": 0
},
{
	"name": "",
	"score": 0
}]
var PlayerCount = 1

var CurrentQuizQuestions = [] #The questions to be used in the current quiz
var CurrentQuestionIndex = 0 #The index of question currently on in quiz

var TagsToExclude = [] #The list of tags to be excluded from quizes
var CurrentChances = [] #The list of chance stars to track for the game

var CurrentTheme = "default" #The current quiz theme

func _add_chance(chance_name,description):
	CurrentChances.append({
		"name": chance_name,
		"description": description,
		"count_p1": 0,
		"count_p2": 0,
		"count_p3": 0,
		"count_p4": 0
	})

func _set_name(player_index,name):
	Players[player_index]["name"] = name

func _player_name(player_index):
	return Players[player_index]["name"]

func _player_score(player_index):
	return Players[player_index]["score"]

func _increase_score(player_index,score):
	Players[player_index]["score"] += score

func _reset_players():
	for i in range(4):
		Players[i]["score"] = 0
