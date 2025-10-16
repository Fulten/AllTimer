extends Node

class Player:
	var name: String
	var uuid: int
	var guess: int
	var guessTime: int
	var hasGuessed: bool
	var correct: bool
	var score: int
	var profileData
	var chances
	
	func initilize(u_profile, i_uuid) :
		name = u_profile["name"]
		uuid = i_uuid
		guess = -1
		guessTime = 0
		hasGuessed = false
		correct = false
		score = 0
		profileData = u_profile
		chances = {}
		pass
	func reset_player():
		guess = -1
		guessTime = 0
		hasGuessed = false
		correct = false
		score = 0
		chances = {}
		pass

class QuizOptions:
	var timer: int
	var win_con: String
	var tallies: bool
	var skipping_losses: bool
	var gambling_modes: bool
	
	func initilize(i_timer = 30, i_win_con = "default", i_tallies = false, i_skipping_losses = false, i_gambling_modes = false) :
		timer = i_timer
		win_con = i_win_con
		tallies = i_tallies
		skipping_losses = i_skipping_losses
		gambling_modes = i_gambling_modes
		pass

var quizOptions = QuizOptions.new()

var players = {}

# translates player number to multiplayer id
var playerNumberToIds = [-1, -1, -1, -1]

var PlayerCount = 1

var PlayersLoaded = 0

var CurrentQuizQuestions = [] #The questions to be used in the current quiz
var CurrentQuestionIndex = 0 #The index of question currently on in quiz

var TagsToExclude = [] #The list of tags to be excluded from quizes
var CurrentChances = [] #The list of chance stars to track for the game

var CurrentTheme = "default" #The current quiz theme

var GameStarted = false

func _add_chance(chance_name, description, type, uuid, value, associated_questions: Array):
	CurrentChances.append({ #to be updated when we add more types with an if/switch
		"name": chance_name,
		"description": description,
		"type": type,
		"uuid": uuid,
		"correct": value,
		"associated_questions": [],
		"player_hits": [0,0,0,0],
	})

func _adjust_score(player_index,score):
	var playerId = playerNumberToIds[player_index]
	players[playerId]["score"] += roundf(score * players[playerId]["guessTime"]/30)

func _player_has_guessed(player_id):
	return players[player_id]["guess"] >= 0

func _player_guess(player_id,guess,current_time):
	players[player_id]["guess"] = guess
	players[player_id]["guessTime"] = current_time
	players[player_id]["hasGuessed"] = true
	
func _reset_guesses():
	for i in range(PlayerCount):
		players[playerNumberToIds[i]]["guess"] = -1
		players[playerNumberToIds[i]]["guessTime"] = 0
		players[playerNumberToIds[i]]["hasGuessed"] = false

func _player_correctness(correct_answer, score):
	for i in PlayerCount:
		var playerGuess = players[playerNumberToIds[i]]["guess"]
		players[playerNumberToIds[i]]["correct"] = playerGuess == correct_answer
		if players[playerNumberToIds[i]]["correct"]:
			_adjust_score(i,score)
		else:
			_adjust_score(i,-1*score)

## updates the question answered and seen metrics section of the player profiles
## this is called on the server, and only updates the profile data on the server side
func _update_profile_statistics(current_question_uuid):
	for i in PlayerCount:
		var playerCorrectness = players[playerNumberToIds[i]]["correct"]
		# questions_answered incremented when the user answers the question correctly
		if playerCorrectness:
			if current_question_uuid in players[playerNumberToIds[i]]["profileData"]["questions_answered"]:
				players[playerNumberToIds[i]]["profileData"]["questions_answered"][current_question_uuid] += 1
				pass
			else:
				players[playerNumberToIds[i]]["profileData"]["questions_answered"][current_question_uuid] = 1
				pass
			pass

		# questions_seen incremented when the user sees a question
		if current_question_uuid in players[playerNumberToIds[i]]["profileData"]["questions_seen"]:
			players[playerNumberToIds[i]]["profileData"]["questions_seen"][current_question_uuid] += 1
			pass
		else:
			players[playerNumberToIds[i]]["profileData"]["questions_seen"][current_question_uuid] = 1
			pass
			
		pass
	pass

## checks which chances a user has scored
## and stores them in the profile data
func _add_chance_hits(question_index):
	for chance in CurrentChances:
		if chance["associated_questions"].has(question_index):
			for i in range(PlayerCount):
				if players[playerNumberToIds[i]]["correct"] == chance["correct"]:
					chance["player_hits"][i] += 1
					players[playerNumberToIds[i]]["chances"][chance["uuid"]] = 1
					if chance["uuid"] in players[playerNumberToIds[i]]["profileData"]["questions_chances"]:
						players[playerNumberToIds[i]]["profileData"]["questions_chances"][chance["uuid"]] += 1
						pass
					else:
						players[playerNumberToIds[i]]["profileData"]["questions_chances"][chance["uuid"]] = 1
						pass
					pass
	
func _build_player_number_to_id_table():
	playerNumberToIds = [-1,-1,-1,-1]
	var i = 0
	for key in players.keys():
		playerNumberToIds[i] = key
		i += 1
		pass
	pass

func _reset_players():
	for key in players.keys():
		players[key].reset_player()
		pass

func _reset_quiz_state():
	_reset_players()
	PlayersLoaded = 0
	CurrentQuestionIndex = 0
	CurrentChances.clear()
	CurrentQuizQuestions.clear()
	GameStarted = false
	pass
