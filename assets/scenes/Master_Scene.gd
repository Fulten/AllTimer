extends Control

var load_multiplayer_menu_scene = true

var quiz_session_scene = preload("res://assets/scenes/quiz_session.tscn")
var multiplayer_menu_scene = preload("res://assets/scenes/multiplayer_menu.tscn")

var quiz_session_instance
var multiplayer_menu_instance

var multiplayer_menu_vbox

var master_chances_data = []
var master_question_data = []
var chances_set = {}

var players_loaded = 0
var launch_quiz = false

const PORT: int = 12345 # port to use
const MAX_CONNECTIONS: int = 4
var IP_ADDRESS = "127.0.0.1" # use local host

var peer

@onready var progress_bar = $progress_bar

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	# connect multiplayer callback functions
	multiplayer.peer_connected.connect(_mp_on_peer_connected)
	multiplayer.peer_disconnected.connect(_mp_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_mp_on_connected_ok)
	multiplayer.connection_failed.connect(_mp_on_connected_fail)
	multiplayer.server_disconnected.connect(_mp_on_server_disconnected)
	
	GameState.PlayerCount = 1;
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if load_multiplayer_menu_scene && !GameState.GameStarted:
		multiplayer_menu_instance = multiplayer_menu_scene.instantiate()
		get_tree().root.add_child(multiplayer_menu_instance)
		multiplayer_menu_vbox = multiplayer_menu_instance.get_node("VBoxContainer")

		multiplayer_menu_vbox.multiplayer_host.connect(_mp_host_server)
		multiplayer_menu_vbox.multiplayer_connect.connect(_mp_join)
		multiplayer_menu_vbox.launch_quiz.connect(_launch_quiz)
		multiplayer_menu_vbox.multiplayer_disconnect.connect(_mp_disconnect)

		load_multiplayer_menu_scene = false
	pass
	if launch_quiz:
		load_quiz.rpc()
		launch_quiz = false
	pass

func _set_ip(ip_address):
	IP_ADDRESS = ip_address
	pass

# host player has created a multiplayer lobby
func _mp_host_server(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

	var playerData = GameState.Player.new()
	playerData.initilize("Player 1", 1)
	GameState.players[1] = playerData
	
	multiplayer_menu_vbox._update_connected_players(GameState.PlayerCount)
	print("Hosting server on IP: %s, PORT: %d" % [IP_ADDRESS, PORT])
	pass
	
func _mp_disconnect():
	multiplayer.multiplayer_peer = null
	GameState.players.clear()
	GameState.PlayerCount = 0
	pass	

func _mp_join(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	pass

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func _player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == GameState.PlayerCount:
			quiz_session_instance._start_quiz()
			players_loaded = 0
	
func _mp_on_peer_connected(id: int):
	_register_player.rpc_id(id, "Player %s" % multiplayer.get_unique_id())
	print("peer %s to %s" % [id, multiplayer.get_unique_id()])
	pass	
	
@rpc("any_peer", "reliable")
func _register_player(playerName):
	var playerData = GameState.Player.new()
	var newPlayerId = multiplayer.get_remote_sender_id()
	playerData.initilize(playerName, newPlayerId)
	
	GameState.players[newPlayerId] = playerData
	
	GameState.PlayerCount += 1
	multiplayer_menu_vbox._update_connected_players(GameState.PlayerCount)
	print("player %s connected" % playerData.uuid)
pass
	

func _mp_on_peer_disconnected(id: int):
	GameState.players.erase(id)
	GameState.PlayerCount -= 1
	multiplayer_menu_vbox._update_connected_players(GameState.PlayerCount)
	print("player %s disconneted" % id)
	pass

# player has connected to server
func _mp_on_connected_ok():
	var playerData = GameState.Player.new()
	playerData.initilize("Player %s" % multiplayer.get_unique_id(), multiplayer.get_unique_id())
	GameState.players[multiplayer.get_unique_id()] = playerData
	pass

# player has failed to connect to server
func _mp_on_connected_fail():
	multiplayer.multiplayer_peer = null
	pass

func _mp_on_server_disconnected():
	multiplayer.multiplayer_peer = null
	GameState.players.clear()
	pass

# called when the multiplayer menu sends it's signal
@rpc("authority", "call_local", "reliable")
func _launch_quiz():
	if multiplayer.is_server():
		launch_quiz = true
		print("server is launching quiz")
	pass

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("authority", "call_local", "reliable")
func load_quiz():
	quiz_session_instance = quiz_session_scene.instantiate()
	quiz_session_instance.player_loaded.connect(_player_loaded)
	get_tree().root.add_child(quiz_session_instance)
	pass

func _exit_quiz():
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
	pass
