extends Control

var master_question_data = []
var chances_set = {}

var master_chances_data = []

var launch_quiz = false
var multiplayer_menu = true

var quiz_session_instance
var multiplayer_menu_instance
var multiplayer_menu_vbox

var quiz_session_scene = preload("res://assets/scenes/quiz_session.tscn")
var player_input_scene = preload("res://assets/scenes/player.tscn")
var multiplayer_menu_scene = preload("res://assets/scenes/multiplayer_menu.tscn")

var player_input_instances = []
@onready var progress_bar = $progress_bar

const PORT: int = 12345 # port to use
const MAX_CONNECTIONS: int = 4
var IP_ADDRESS = "127.0.0.1" # use local host

var peer

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	progress_bar.value = 0
	_prepare_quiz_questions(10, GameState.TagsToExclude)
	progress_bar.value = 25
	_prepare_quiz_chances(3)
	progress_bar.value = 50

	multiplayer.peer_connected.connect(_mp_on_player_connected)
	multiplayer.peer_disconnected.connect(_mp_on_player_disconnected)
	multiplayer.connected_to_server.connect(_mp_on_connected_ok)
	multiplayer.connection_failed.connect(_mp_on_connected_fail)
	multiplayer.server_disconnected.connect(_mp_on_server_disconnected)
	GameState.PlayerCount = 1;

	progress_bar.value = 100
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if multiplayer_menu && !GameState.GameStarted:
		multiplayer_menu_instance = multiplayer_menu_scene.instantiate()
		get_tree().root.add_child(multiplayer_menu_instance)
		multiplayer_menu_vbox = multiplayer_menu_instance.get_node("VBoxContainer")

		multiplayer_menu_vbox.multiplayer_host.connect(_mp_host_server)
		multiplayer_menu_vbox.multiplayer_connect.connect(_mp_join)
		multiplayer_menu_vbox.launch_quiz.connect(_launch_quiz)

		multiplayer_menu = false
	pass
	if launch_quiz && progress_bar.value == 100:
		# get_tree().change_scene_to_file("res://assets/scenes/quiz_session.tscn")	
		quiz_session_instance = quiz_session_scene.instantiate()
		get_tree().root.add_child(quiz_session_instance)
		quiz_session_instance.end_of_quiz.connect(_exit_quiz)
		
		# instantiate players
		for i in range(GameState.PlayerCount):
			var player_instance = player_input_scene.instantiate()
			player_instance._set_player(i)
			get_tree().root.add_child(player_instance)
			player_input_instances.append(player_instance)
			pass

		# connect players
		for i in range(GameState.PlayerCount):
			player_input_instances[i].player_guess.connect(quiz_session_instance._player_input)
			pass
		
		quiz_session_instance._start_quiz()
		launch_quiz = false
	pass

func _set_ip(ip_address):
	IP_ADDRESS = ip_address
	pass

func _mp_host_server():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CONNECTIONS)
	multiplayer.multiplayer_peer = peer
	print("Hosting server on IP: %s, PORT: %d" % [IP_ADDRESS, PORT])
	pass
	
func _mp_join(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)

	multiplayer.multiplayer_peer = peer
	pass


	
func _mp_on_player_connected(id: int):
	print(id)
	pass

func _mp_on_player_disconnected(id: int):
	print(id)
	pass

# player has connected to server
func _mp_on_connected_ok():

	pass

# player has failed to connect to server
func _mp_on_connected_fail():

	pass

func _mp_on_server_disconnected():

	pass

func _launch_quiz():
	launch_quiz = true
	pass

func _load_master_questions(excluded_tags):
	var file = FileAccess.open("res://data/question_data.json", FileAccess.READ)
	if file:
		master_question_data = JSON.parse_string(file.get_as_text())
		file.close()
	var i = 0
	for question in master_question_data:
		var tagMatch = false
		for tag in excluded_tags:
			if tag in question:
				tagMatch = true
				break
		if !tagMatch:
			master_question_data[i] = question
			i += 1
	master_question_data = Array(master_question_data).slice(0, i)

func _clean_master_questions():
	master_question_data = []

func _prepare_quiz_questions(quiz_size, excluded_tags):
	var progress_increment = 50/(quiz_size + 2)
	_load_master_questions(excluded_tags)
	progress_bar.value += progress_increment
	GameState.CurrentQuizQuestions = []
	for i in range(quiz_size):
		if master_question_data.size() == 0:
			break
		GameState.CurrentQuizQuestions.append(_next_question_store_chances(i))
		progress_bar.value += progress_increment
	_clean_master_questions()

func _next_question_store_chances(question_index):
	var next_question = master_question_data.pop_at(randi() % master_question_data.size())
	for chance in next_question["chances"]:
		if !chances_set.has(chance):
			chances_set[chance] = [question_index]
		else:
			chances_set[chance].append(question_index)
	return next_question

func _clean_chance_set_and_master():
	chances_set = {}
	master_chances_data = []

func _load_master_chances():
	var file = FileAccess.open("res://data/chance_data.json", FileAccess.READ)
	if file:
		master_chances_data = JSON.parse_string(file.get_as_text())
		file.close()

func _prepare_quiz_chances(chance_count):
	var progress_increment = 50/(chance_count + 2)
	_load_master_chances()
	progress_bar.value += progress_increment
	GameState.CurrentChances = []
	for i in range(chance_count):
		if chances_set.keys().size() == 0:
			break
		_next_chance()
		progress_bar.value += progress_increment
	_clean_chance_set_and_master()

func _next_chance():
	var next_chance = chances_set.keys()[randi() % chances_set.keys().size()]
	var description = ""
	for chance in master_chances_data:
		if chance["uuid"] == next_chance:
			GameState._add_chance(chance["name"], chance["description"], chance["type"], chance["correct"], chances_set[next_chance])
			chances_set.erase(next_chance)
			return

func _exit_quiz():
	for i in range(GameState.PlayerCount):
		player_input_instances[i]._freePlayer()
		pass
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
	pass
