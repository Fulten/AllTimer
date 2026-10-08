extends Node


#region Class Definitions
class Player:
	var name: String
	var active: bool
	
	var guess: int
	var guessTime: int
	var hasGuessed: bool
	var correct: bool
	var score: int
	var last_score: int
	var profileData
	var chances
	
	func initilize(p_name):
		name = p_name
		active = true
		
		guess = -1
		guessTime = 0
		hasGuessed = false
		correct = false
		score = 0
		last_score = 0
		chances = {}
		
	func reset_player():
		guess = -1
		guessTime = 0
		hasGuessed = false
		correct = false
		score = 0
		last_score = 0
		chances = {}
		
	func new_from(old_player):
		name = old_player["name"]
		active = true
		
		guess = -1
		guessTime = 0
		hasGuessed = false
		correct = false
		score = old_player["score"]
		last_score = old_player["last_score"]
		chances = old_player["chances"]


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
#endregion

#region variables
var quizOptions = QuizOptions.new()

var players = {}
var players_loaded = 0

# translates player number to multiplayer id
var playerCardOrder = [-1, -1, -1, -1]

var activeId = -1
var quiz_phase = QUIZSTATE.lobby

var CurrentTheme = "Chalkboard" #The current quiz theme

var QuestionDataFile = "res://data/question_data.json"
var CurrentQuizQuestions = [] #The questions to be used in the current quiz
var CurrentQuestionIndex = 0 #The index of question currently on in quiz

var questions = {}
var tags_list = {}

var TagsFilterFile = "user://quiz_filters.json"
var TagsFilters = {}

var CurrentChances = [] #The list of chance stars to track for the game

enum QUIZSTATE {
	lobby = 0,
	loading = 1,
	preQuiz = 2,
	preQuestion = 3,
	question = 4,
	postQuestion = 5,
	PostQuiz = 5,
}
#endregion

#region player related functions
func _new_player(p_name, mp_id):
	var playerData = GameState.Player.new()
	playerData.initilize(p_name)
	GameState.players[mp_id] = playerData
	_build_player_number_to_id_table()

func _remove_player(mp_id):
	players.erase(mp_id)
	_build_player_number_to_id_table()

func _clear_players():
	players.clear()
	playerCardOrder = [-1,-1,-1,-1]

func _has_active_id(temp_id: int):
	for key in players:
		if key == temp_id:
			return true

func _deactivate_player(mp_id):
	if players.has(mp_id):
		players[mp_id]["active"] = false
		_build_player_number_to_id_table()
	
func _reactivate_player(mp_id, mp_activeId):
	for key in players:
		if key == mp_activeId:
			var playerData = GameState.Player.new()
			playerData.new_from(players[key])
			_remove_player(key)
			players[mp_id] = playerData
			_build_player_number_to_id_table()
			return
	
func _reset_players():
	for key in players.keys():
		players[key].reset_player()
		
func _player_count() -> int:
	var i = 0
	for key in players:
		if players[key]["active"]:
			i += 1
	return i

func _build_player_number_to_id_table():
	playerCardOrder = [-1,-1,-1,-1]
	var i = 0
	for key in players.keys():
		if players[key]["active"]:
			playerCardOrder[i] = key
			i += 1

func _player_has_guessed(player_id):
	return players[player_id]["guess"] >= 0

func _player_guess(player_id,guess,current_time):
	players[player_id]["guess"] = guess
	players[player_id]["guessTime"] = current_time
	players[player_id]["hasGuessed"] = true
	
func _reset_player_guesses():
	for key in players:
		players[key]["guess"] = -1
		players[key]["guessTime"] = 0
		players[key]["hasGuessed"] = false

func _player_answer_correctness(correct_answer, score):
	for key in players:
		#if player slot is inactive pass
		if not players[key]["active"]:
			continue
			
		var playerGuess = players[key]["guess"]
		# if the player has passed make no change to score
		if not players[key]["hasGuessed"]:
			players[key]["last_score"] = players[key]["score"]
			continue
			
		players[key]["correct"] = playerGuess == correct_answer
		if players[key]["correct"]:
			_adjust_player_score(key, score)
		else:
			_adjust_player_score(key, -score)

func _adjust_player_score(key, score):
	players[key]["last_score"] = players[key]["score"]
	# var awarded_points = roundf(score * players[playerId]["guessTime"]/30) # old scoring function
	var awarded_points = (score + score * players[key]["guessTime"]/quizOptions.timer)/2
	players[key]["score"] += awarded_points
#endregion

func _game_started():
	return !(quiz_phase < QUIZSTATE.preQuiz)

func _in_lobby():
	return quiz_phase == QUIZSTATE.lobby

#region functions related to chances
func _add_chance(chance_name, description, type, uuid, value, associated_questions: Array, bonus):
	CurrentChances.append({ #to be updated when we add more types with an if/switch
		"name": chance_name,
		"description": description,
		"type": type,
		"uuid": uuid,
		"correct": value,
		"associated_questions": associated_questions,
		"player_hits": [0,0,0,0],
		"bonus": bonus
	})

func _get_chance_from_uuid(chance_uuid):
	for chance in CurrentChances:
		if chance["uuid"] == chance_uuid:
			return chance

## checks which chances a user has scored
## and stores them in the profile data
func _add_chance_hits(question_index):
	for chance in CurrentChances:
		if chance["associated_questions"].has(question_index):
			for key in players:
				if players[key]["correct"] == chance["correct"]:
					chance["player_hits"][key] += 1
					players[key]["chances"][chance["uuid"]] = 1
					if chance["uuid"] in players[key]["profileData"]["questions_chances"]:
						players[key]["profileData"]["questions_chances"][chance["uuid"]] += 1
					else:
						players[key]["profileData"]["questions_chances"][chance["uuid"]] = 1
#endregion

#region functions called during the end of the quiz
## updates the question answered and seen metrics section of the player profiles
## this is called on the server, and only updates the profile data on the server side
func _update_profile_statistics(current_question_uuid):
	for key in players:
		var playerCorrect = players[key]["correct"]
		# questions_answered incremented when the user answers the question correctly
		if playerCorrect:
			if current_question_uuid in players[key]["profileData"]["questions_answered"]:
				players[key]["profileData"]["questions_answered"][current_question_uuid] += 1
			else:
				players[key]["profileData"]["questions_answered"][current_question_uuid] = 1

		# questions_seen incremented when the user sees a question
		if current_question_uuid in players[key]["profileData"]["questions_seen"]:
			players[key]["profileData"]["questions_seen"][current_question_uuid] += 1
		else:
			players[key]["profileData"]["questions_seen"][current_question_uuid] = 1

func _reset_quiz_state():
	_reset_players()
	players_loaded = 0
	CurrentQuestionIndex = 0
	CurrentChances.clear()
	CurrentQuizQuestions.clear()
	quiz_phase = QUIZSTATE.lobby

#endregion

#region functions called to build the tags filter
func _build_complete_tags_list():
	_io_read_questions(QuestionDataFile)
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
#endregion



