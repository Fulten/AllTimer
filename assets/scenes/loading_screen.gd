extends Control

var multiplayer_menu = true

var quiz_session_scene = preload("res://assets/scenes/quiz_session.tscn")
var multiplayer_menu_scene = preload("res://assets/scenes/multiplayer_menu.tscn")

var quiz_session_instance
var multiplayer_menu_instance

var multiplayer_menu_vbox

var master_chances_data = []
var master_question_data = []
var chances_set = {}

var players = {};
var player_info = { "name": "Name"}

var players_loaded = 0
var launch_quiz = false

const PORT: int = 12345 # port to use
const MAX_CONNECTIONS: int = 4
var IP_ADDRESS = "127.0.0.1" # use local host

var peer

@onready var progress_bar = $progress_bar

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal start_loading(peer_id)

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	progress_bar.value = 0
	_prepare_quiz_questions(10, GameState.TagsToExclude)
	progress_bar.value = 25
	_prepare_quiz_chances(3)
	progress_bar.value = 50
	
	# connect multiplayer callback functions
	multiplayer.peer_connected.connect(_mp_on_player_connected)
	multiplayer.peer_disconnected.connect(_mp_on_player_disconnected)
	multiplayer.connected_to_server.connect(_mp_on_connected_ok)
	multiplayer.connection_failed.connect(_mp_on_connected_fail)
	multiplayer.server_disconnected.connect(_mp_on_server_disconnected)
	GameState.PlayerCount = 1;

	progress_bar.value = 100
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if multiplayer_menu && !GameState.GameStarted:
		multiplayer_menu_instance = multiplayer_menu_scene.instantiate()
		get_tree().root.add_child(multiplayer_menu_instance)
		multiplayer_menu_vbox = multiplayer_menu_instance.get_node("VBoxContainer")

		multiplayer_menu_vbox.multiplayer_host.connect(_mp_host_server)
		multiplayer_menu_vbox.multiplayer_connect.connect(_mp_join)
		multiplayer_menu_vbox.launch_quiz.connect(_launch_quiz)
		multiplayer_menu_vbox.multiplayer_disconnect.connect(_mp_disconnect)

		multiplayer_menu = false
	pass
	if launch_quiz && progress_bar.value == 100:		
		load_quiz.rpc()
		launch_quiz = false
	pass

func _set_ip(ip_address):
	IP_ADDRESS = ip_address
	pass

func _mp_host_server(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	
	players[1] = player_info
	player_connected.emit(1, player_info)
	multiplayer_menu_vbox._update_connected_players(GameState.PlayerCount)
	print("Hosting server on IP: %s, PORT: %d" % [IP_ADDRESS, PORT])
	pass
	
func _mp_disconnect():
	multiplayer.multiplayer_peer = null
	pass	

func _mp_join(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	pass

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			quiz_session_instance._start_quiz()
			players_loaded = 0
	
func _mp_on_player_connected(id: int):
	_register_player.rpc_id(id, player_info)
	print("player %s joined" % id)
	pass	
	
@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	
	GameState.PlayerCount += 1
	multiplayer_menu_vbox._update_connected_players(GameState.PlayerCount)

func _mp_on_player_disconnected(id: int):
	players.erase(id)
	player_disconnected.emit(id)
	GameState.PlayerCount -= 1
	multiplayer_menu_vbox._update_connected_players(GameState.PlayerCount)
	print("player %s disconneted" % id)
	pass

# player has connected to server
func _mp_on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)
	pass

# player has failed to connect to server
func _mp_on_connected_fail():
	multiplayer.multiplayer_peer = null
	pass

func _mp_on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	pass

# called when the multiplayer menu sends it's signal
@rpc("call_local", "reliable")
func _launch_quiz():
	launch_quiz = true
	pass

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_quiz():
	quiz_session_instance = quiz_session_scene.instantiate()
	get_tree().root.add_child(quiz_session_instance)

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
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
	pass
