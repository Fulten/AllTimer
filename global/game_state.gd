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

func _add_chance(chance_name,description,type,value,associated_questions: Array):
	CurrentChances.append({ #to be updated when we add more types with an if/switch
		"name": chance_name,
		"description": description,
		"type": type,
		"correct": value,
		"associated_questions": associated_questions,
		"player_hits": [0,0,0,0]
	})

func _set_name(player_index,name):
	Players[player_index]["name"] = name

func _player_name(player_index):
	return Players[player_index]["name"]

func _player_score(player_index):
	return Players[player_index]["score"]

func _increase_score(player_index,score):
	Players[player_index]["score"] += score

func _add_chance_hits(question_index,player_correctness: Array):
	for chance in CurrentChances:
		if chance["associated_questions"].has(question_index):
			for i in range(PlayerCount):
				if player_correctness[i] == chance["correct"]:
					chance["player_hits"][i] += 1
	
func _reset_players():
	for i in range(4):
		Players[i]["score"] = 0
