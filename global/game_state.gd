extends Node

var Players = [{
	"name": "Cool Guy",
	"guess": -1,
	"guess_time": 0,
	"correctness": false,
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

func _remove_online_player(player_id):
	for i in range(PlayerCount):
		if Players[i]["online_id"] == player_id:
			Players.remove_at(i)
			return

func _add_online_player(player_id,player_name):
	if PlayerCount < 4:
		PlayerCount += 1
		Players.append({
			"name": player_name,
			"online_id": player_id,
			"guess": -1,
			"guess_time": 0,
			"correctness": false,
			"score": 0
		})
		return PlayerCount - 1
	return -1
	
func _set_name(player_index,name):
	Players[player_index]["name"] = name

func _player_name(player_index):
	return Players[player_index]["name"]

func _player_score(player_index):
	return Players[player_index]["score"]

func _adjust_score(player_index,score):
	Players[player_index]["score"] += roundf(score * Players[player_index]["guess_time"]/30)

func _player_has_guessed(player_index):
	return Players[player_index]["guess"] >= 0

func _player_guess(player_index,guess,current_time):
	Players[player_index]["guess"] = guess
	Players[player_index]["guess_time"] = current_time
	
func _reset_guesses():
	for i in range(PlayerCount):
		Players[i]["guess"] = -1
		Players[i]["guess_time"] = 0

func _player_correctness(correct_answer,score):
	for i in PlayerCount:
		Players[i]["correctness"] = Players[i]["guess"] == correct_answer
		if Players[i]["correctness"]:
			_adjust_score(i,score)
		else:
			_adjust_score(i,-1*score)

func _add_chance_hits(question_index):
	for chance in CurrentChances:
		if chance["associated_questions"].has(question_index):
			for i in range(PlayerCount):
				if Players[i]["correctness"] == chance["correct"]:
					chance["player_hits"][i] += 1
	
func _reset_players():
	for i in range(PlayerCount):
		Players[i]["score"] = 0
		Players[i]["guess"] = -1
		Players[i]["guess_time"] = 0
