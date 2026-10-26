extends Node


#region Class Definitions
class Player:
	var name: String
	var active: bool
	var loaded: bool
	var ready: bool
	
	var pannel_locked: bool
	
	var final_score: int
	var score: int
	var last_score: int
	
	var guess: int
	var guessTime: int
	var hasGuessed: bool
	var correct: bool
	
	var answer_record: Array
	var chances_scored: Array
	var chance_names: Array
	var chance_hits: Dictionary
	
	static func create(p_name) -> Player:
		var new_player = Player.new()
		new_player.name = p_name
		new_player.active = true
		new_player.loaded = false
		new_player.ready = false
		
		new_player.pannel_locked = false
		
		new_player.final_score = 0
		new_player.score = 0
		new_player.last_score = 0
		
		new_player.guess = -1
		new_player.guessTime = 0
		new_player.hasGuessed = false
		new_player.correct = false
		
		new_player.answer_record = []
		new_player.chances_scored = []
		new_player.chance_names = []
		new_player.chance_hits = {}
		
		return new_player
	
	static func copy(old_player: Player) -> Player:
		var new_player = Player.new()
		new_player.name = old_player.name
		new_player.active = old_player.active
		new_player.loaded = old_player.loaded
		new_player.ready = old_player.ready
		
		new_player.pannel_locked = old_player.pannel_locked
		
		new_player.final_score = old_player.final_score
		new_player.score = old_player.score
		new_player.last_score = old_player.last_score
		
		new_player.guess = old_player.guess
		new_player.guessTime = old_player.guessTime
		new_player.hasGuessed = old_player.hasGuessed
		new_player.correct = old_player.correct
		
		new_player.answer_record = old_player.answer_record
		new_player.chances_scored = old_player.chances_scored
		new_player.chance_names = old_player.chance_names
		new_player.chance_hits = old_player.chance_hits
		
		return new_player
	
	func make_guess(player_guess, current_time):
		guess = player_guess
		guessTime = current_time
		hasGuessed = true

	func chance_hit(uuid):
		if chance_hits.has(uuid):
			chance_hits[uuid] += 1
		else:
			chance_hits[uuid] = 1
	
	func reset_state() -> void:
		loaded = false
		ready = false
		
		final_score = 0
		score = 0
		last_score = 0
		
		guess = -1
		guessTime = 0
		hasGuessed = false
		correct = false
		
		chance_hits = {}
		chance_names = []
		chances_scored = []
		
	func reset_guess() -> void:
		guess = -1
		guessTime = 0
		hasGuessed = false
		correct = false

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

	func initilize(i_timer = 30, i_win_con = "default", i_win_con_int = 0, i_win_questions = 10, i_win_points = 5000) :
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

class Chance:
	var name: String
	var correct: bool
	var bonus: int
	var uuid
	
	var related_questions: Array
	
	static func create(i_name, i_correct, i_bonus, i_uuid) -> Chance:
		var chance = Chance.new()
		chance.name = i_name
		chance.correct = i_correct
		chance.bonus = i_bonus
		chance.uuid = i_uuid
		
		chance.related_questions = []
		return chance
#endregion

#region variables
var quizOptions = QuizOptions.new()

var players = {}
var players_loaded = 0

# translates player number to multiplayer id
var playerCardOrder = [-1, -1, -1, -1]
var idToCardIndex = {}

var activeId = -1
var quiz_phase

var CurrentTheme = "Chalkboard" #The current quiz theme

var QuestionDataFile = "res://data/question_data.json"

var questions = {}
var chances = {}
var tags_list = {}

var TagsFilterFile = "user://quiz_filters.json"
var TagsFilters = {}

#endregion

enum QUIZSTATE {
	lobby,
	loading,
	preQuiz,
	endOfRules,
	preQuestion,
	question,
	postQuestion,
	endOfPhase,
	endScreen
}

func _reset_quiz_state():
	quiz_phase = QUIZSTATE.lobby
	_reset_all_players()
	chances.clear()
	players_loaded = 0

#region player related functions
func _add_new_player(p_name, mp_id): 
	players[mp_id] = Player.create(p_name)
	_build_player_number_to_id_table()

func _remove_player(mp_id):
	players.erase(mp_id)
	_build_player_number_to_id_table()

func _clear_all_players():
	players.clear()
	playerCardOrder = [-1,-1,-1,-1]
	idToCardIndex = {}

func _reset_all_players():
	for key in players:
		players[key].reset_state()

func _has_active_id(temp_id: int):
	if temp_id == 1:
		return false
	for key in players:
		if key == temp_id:
			return true

func _deactivate_player(mp_id):
	if players.has(mp_id):
		players[mp_id].active = false
		players[mp_id].loaded = false

func _reactivate_player(mp_id, active_id):
	if players.has(active_id):
		players[mp_id] = Player.copy(players[active_id])
		_remove_player(active_id)

func _player_count() -> int:
	return players.size()

func _build_player_number_to_id_table():
	playerCardOrder = [-1,-1,-1,-1]
	idToCardIndex = {}
	var i = 0
	for key in players:
		playerCardOrder[i] = key
		idToCardIndex[key] = i
		i += 1

func _reset_player_guesses():
	for key in players:
		players[key].reset_guess()

func _check_player_answers(correct_answer, score):
	for key in players:
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

func _check_player_chances(question_uuid):
	for chance_key in chances:
		if chances[chance_key].related_questions.has(question_uuid):
			for key in players:
				if players[key]["hasGuessed"] and (players[key]["correct"] == chances[chance_key].correct):
					players[key].chance_hit(chance_key)

func _adjust_player_score(key, score):
	players[key]["last_score"] = players[key]["score"]
	var awarded_points = (score + score * players[key]["guessTime"] / quizOptions.timer) / 2
	players[key]["score"] += awarded_points
#endregion

#region boolean queries
func _game_started() -> bool:
	return (quiz_phase != QUIZSTATE.lobby 
		and quiz_phase != QUIZSTATE.loading
		and quiz_phase != QUIZSTATE.preQuiz)

func _in_lobby() -> bool:
	return quiz_phase == QUIZSTATE.lobby

func _can_guess() -> bool:
	return quiz_phase == QUIZSTATE.question

func _player_has_guessed(player_id) -> bool:
	return players[player_id]["hasGuessed"]

func _have_all_players_answered() -> bool:
	var all_players_answered = true
	for key in players:
		if players[key]["loaded"] and not players[key]["hasGuessed"]:
			all_players_answered = false
	return all_players_answered

func _are_all_players_ready() -> bool:
	var players_ready = true
	for key in players:
		if players[key]["loaded"] and not players[key]["ready"]:
			players_ready = false
	return players_ready
#endregion

#region question filter section
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
