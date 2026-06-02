extends Node

var file_path_questions_data = "res://data/question_data.json"

class Player:
	var name: String
	var uuid: int
	var guess: int
	var guessTime: int
	var hasGuessed: bool
	var correct: bool
	var score: int
	var last_score: int
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
		last_score = 0
		profileData = u_profile
		chances = {}
		pass
	func reset_player():
		guess = -1
		guessTime = 0
		hasGuessed = false
		correct = false
		score = 0
		last_score = 0
		chances = {}
		pass

class QuizOptions:
	var timer: int # length of question answer phase timer
	var win_con: String
	var win_con_int: int

	var win_questions: int
	var win_points: int

	# win_con_int : win_con
	# 0 : Highest score after 10 questions
	# 1 : First to answer 10 questions correctly
	# 2 : First to reach 1000 points

	func initilize(i_timer = 30, i_win_con = "default", i_win_con_int = 0, i_win_questions = 10, i_win_points = 1000) :
		timer = i_timer
		win_con = i_win_con # textual representation of wincondition
		win_con_int = i_win_con_int #integer representation of windcondition
		
		win_questions = i_win_questions
		win_points = i_win_points


var quizOptions = QuizOptions.new()

var players = {}

# translates player number to multiplayer id
var playerNumberToIds = [-1, -1, -1, -1]

var PlayerCount = 1

var PlayersLoaded = 0

var CurrentQuizQuestions = [] #The questions to be used in the current quiz
var CurrentQuestionIndex = 0 #The index of question currently on in quiz

var questions = {}
var tags_list = {}

var TagsFilterFile = "user://quiz_filters.json"
var TagsFilters = {}

var CurrentChances = [] #The list of chance stars to track for the game

var CurrentTheme = "Chalkboard" #The current quiz theme

var GameStarted = false

class Question:
	var name: String
	var body: String
	var explainer: String
	var correct: String
	var wrong
	var tags
	var chances
	var questionType: String
	
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
		i_chances,
		i_questionType):
		
		name = i_name
		body = i_body
		correct = i_correct
		wrong = i_wrong
		explainer = i_explainer
		tags = i_tags
		chances = i_chances
		questionType = i_questionType
		listIndex = -1

func _add_chance(chance_name, description, type, uuid, value, associated_questions: Array):
	CurrentChances.append({ #to be updated when we add more types with an if/switch
		"name": chance_name,
		"description": description,
		"type": type,
		"uuid": uuid,
		"correct": value,
		"associated_questions": associated_questions,
		"player_hits": [0,0,0,0],
	})

func _get_chance_from_uuid(chance_uuid):
	for chance in CurrentChances:
		if chance["uuid"] == chance_uuid:
			return chance
	pass

func _adjust_score(player_index,score):
	var playerId = playerNumberToIds[player_index]
	players[playerId]["last_score"] = players[playerId]["score"]
	# var awarded_points = roundf(score * players[playerId]["guessTime"]/30) # old scoring function
	var awarded_points = (score + score * players[playerId]["guessTime"]/quizOptions.timer)/2
	players[playerId]["score"] += awarded_points

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
		# if the player has passed make no change to score
		if not players[playerNumberToIds[i]]["hasGuessed"]:
			players[playerNumberToIds[i]]["last_score"] = players[playerNumberToIds[i]]["score"]
			continue
		
		players[playerNumberToIds[i]]["correct"] = playerGuess == correct_answer
		if players[playerNumberToIds[i]]["correct"]:
			_adjust_score(i, score)
		else:
			_adjust_score(i, -score)

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
	
func _build_complete_tags_list():
	_io_read_questions(file_path_questions_data)
	# find all tags and numerate them
	for key in questions:
		for tag in questions[key]["tags"]:
			if tag in tags_list:
				tags_list[tag] += 1
			else:
				tags_list[tag] = 1
		

func _io_read_questions(file_name: String):
	print("!INFO: Reading Question Data")
	var file = FileAccess.open(file_name, FileAccess.READ)
	var questions_raw
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
			question_raw["chances"],
			question_raw["questionType"])
		questions[question_raw["uuid"]] = question

func _IO_read_tags_filter():
	var file = FileAccess.open(TagsFilterFile, FileAccess.READ)
	var missing = false
	
	if file:
		TagsFilters = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		print("!!ERROR: Failed to read tags filters")
		
	if TagsFilters == null:
		TagsFilters = {}
		_IO_write_tags_filter()
		return
	
	for key in TagsFilters:
		if !"selected" in TagsFilters[key]:
			TagsFilters[key]["selected"] = false
			
		if !"blacklist" in TagsFilters[key]:
			TagsFilters[key]["blacklist"] = false
			missing = true
	
		if !"tags" in TagsFilters[key]:
			TagsFilters[key]["tags"] = []
			missing = true
		
		for i in range(0, TagsFilters[key]["tags"].size()):
			TagsFilters[key]["tags"][i] = TagsFilters[key]["tags"][i].to_lower()
		
	if missing:
		_IO_write_tags_filter()
		return
		
func _IO_write_tags_filter():
	var file = FileAccess.open(TagsFilterFile, FileAccess.WRITE)
	if file:
		var jsonString = JSON.stringify(TagsFilters)
		file.store_string(jsonString)
		file.close()
	else:
		print("!!ERROR: Failed to save tags filters")
