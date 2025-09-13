extends Control

var load_multiplayer_lobby_scene = true

var quiz_session_scene = preload("res://assets/scenes/quiz_session.tscn")
var multiplayer_lobby_scene = preload("res://assets/scenes/multiplayer_lobby.tscn")

var quiz_session_instance
var multiplayer_lobby_instance

var multiplayer_lobby_script

var master_chances_data = []
var master_question_data = []
var chances_set = {}

var players_loaded = 0
var launch_quiz = false

const PORT: int = 12345 # port to use
const MAX_CONNECTIONS: int = 3
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
	if load_multiplayer_lobby_scene && !GameState.GameStarted:
		multiplayer_lobby_instance = multiplayer_lobby_scene.instantiate()
		get_tree().root.add_child(multiplayer_lobby_instance)
		multiplayer_lobby_script = multiplayer_lobby_instance.get_node("/root/MultiplayerLobby")

		multiplayer_lobby_script.multiplayer_host.connect(_mp_host_server)
		multiplayer_lobby_script.multiplayer_connect.connect(_mp_join)
		multiplayer_lobby_script.launch_quiz.connect(_launch_quiz)
		multiplayer_lobby_script.multiplayer_disconnect.connect(_mp_disconnect)

		load_multiplayer_lobby_scene = false
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
	playerData.initilize(UserProfiles.profiles[UserProfiles._get_selected_profile_key()], 1)
	GameState.players[1] = playerData
	
	multiplayer_lobby_script._update_connected_players()
	print("Hosting server on IP: %s, PORT: %d" % [IP_ADDRESS, PORT])
	pass
	
func _mp_disconnect():
	if multiplayer.has_multiplayer_peer():
		print("Peer id %s, disconnecting" % multiplayer.get_unique_id())
		multiplayer.multiplayer_peer = null
		pass
	GameState.players.clear()
	GameState.PlayerCount = 1
	pass	

func _mp_join(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	pass

func _mp_on_peer_connected(id: int):
	if !GameState.GameStarted:
		_register_player.rpc_id(id, UserProfiles.profiles[UserProfiles._get_selected_profile_key()])
		print("peer %s to %s" % [id, multiplayer.get_unique_id()])
		pass
	elif multiplayer.is_server():
		_kick_peer.rpc_id(id, "Connection Refused, quiz in progress")
		pass
	
@rpc("any_peer", "reliable")
func _register_player(playerProfile):
	# if the game is already in progress deny connection

	var playerData = GameState.Player.new()
	var newPlayerId = multiplayer.get_remote_sender_id()
	playerData.initilize(playerProfile["name"], newPlayerId)
	
	GameState.players[newPlayerId] = playerData
	
	GameState.PlayerCount += 1
	multiplayer_lobby_script._update_connected_players()
	print("player %s connected" % playerData.uuid)
	pass

func _mp_on_peer_disconnected(id: int):
	GameState.players.erase(id)
	GameState.PlayerCount -= 1
	multiplayer_lobby_script._update_connected_players()
	print("player %s disconneted" % id)
	pass

# player has connected to server
func _mp_on_connected_ok():
	var playerData = GameState.Player.new()
	playerData.initilize(UserProfiles.profiles[UserProfiles._get_selected_profile_key()], multiplayer.get_unique_id())
	GameState.players[multiplayer.get_unique_id()] = playerData
	multiplayer_lobby_instance._connected_to_server()
	pass

# player has failed to connect to server
func _mp_on_connected_fail():
	multiplayer.multiplayer_peer = null
	multiplayer_lobby_instance._connection_reset("connection failed")
	pass

func _mp_on_server_disconnected():
	multiplayer.multiplayer_peer = null
	GameState.players.clear()
	multiplayer_lobby_instance._connection_reset("server disconnected")
	pass

# called when the multiplayer menu sends it's signal
@rpc("authority", "call_local", "reliable")
func _launch_quiz():
	if multiplayer.has_multiplayer_peer() && multiplayer.is_server():
		launch_quiz = true
		print("server is launching quiz")
	pass

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("authority", "call_local", "reliable")
func load_quiz():
	quiz_session_instance = quiz_session_scene.instantiate()
	quiz_session_instance.end_of_quiz.connect(_end_of_quiz_handler)
	get_tree().root.add_child(quiz_session_instance)
	pass

@rpc("authority", "reliable")
func _kick_peer(reason):
	multiplayer.multiplayer_peer = null
	GameState.players.clear()
	multiplayer_lobby_instance._connection_reset(reason)
	pass

func _end_of_quiz_handler():
	if multiplayer.is_server():
		multiplayer_lobby_instance._enable_launch_button()
		pass
	else:
		
		pass
	pass

func _exit_quiz():
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
	pass
