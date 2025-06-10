extends Node

class Player:
	var name: String
	var uuid: int
	var guess: int
	var guessTime: int
	var correct: bool
	var score: int
	
	func initilize(i_name, i_uuid) :
		name = i_name
		uuid = i_uuid
		guess = -1
		guessTime = 0
		correct = false
		score = 0
		pass

var players = {}

var PlayerCount = 1

var CurrentQuizQuestions = [] #The questions to be used in the current quiz
var CurrentQuestionIndex = 0 #The index of question currently on in quiz

var TagsToExclude = [] #The list of tags to be excluded from quizes
var CurrentChances = [] #The list of chance stars to track for the game

var CurrentTheme = "default" #The current quiz theme

var GameStarted = false

func _add_chance(chance_name, description, type, uuid, value):
	CurrentChances.append({ #to be updated when we add more types with an if/switch
		"name": chance_name,
		"description": description,
		"type": type,
		"uuid": uuid,
		"correct": value,
		"player_hits": [0,0,0,0]
	})
	
func _set_name(player_index,name):
	players[player_index]["name"] = name

func _player_name(player_index):
	return players[player_index]["name"]

func _player_score(player_index):
	return players[player_index]["score"]

func _adjust_score(player_index,score):
	players[player_index]["score"] += roundf(score * players[player_index]["guess_time"]/30)

func _player_has_guessed(player_index):
	
	return players[player_index]["guess"] >= 0

func _player_guess(player_index,guess,current_time):
	players[player_index]["guess"] = guess
	players[player_index]["guess_time"] = current_time
	
func _reset_guesses():
	for i in range(PlayerCount):
		players[i]["guess"] = -1
		players[i]["guess_time"] = 0

func _player_correctness(correct_answer,score):
	for i in PlayerCount:
		players[i]["correctness"] = players[i]["guess"] == correct_answer
		if players[i]["correctness"]:
			_adjust_score(i,score)
		else:
			_adjust_score(i,-1*score)

func _add_chance_hits(question_index):
	for chance in CurrentChances:
		if chance["associated_questions"].has(question_index):
			for i in range(PlayerCount):
				if players[i]["correctness"] == chance["correct"]:
					chance["player_hits"][i] += 1
	
func _reset_players():
	for i in range(PlayerCount):
		players[i]["score"] = 0
		players[i]["guess"] = -1
		players[i]["guess_time"] = 0
