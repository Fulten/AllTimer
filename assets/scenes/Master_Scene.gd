extends Control

#region Variables
var quiz_session_scene = preload("res://assets/scenes/quiz_session.tscn")
var mp_lobby_scene = preload("res://assets/scenes/multiplayer_lobby.tscn")

var quiz_session_instance
var mp_lobby_instance
var mp_lobby_root

enum MP_STATE {
	LOBBY = 0,
	STARTGAME = 1,
	INGAME = 2,
	STOPGAME = 3
}

var load_multiplayer_lobby_scene = true

var GAME_STATE = MP_STATE.LOBBY

var players_loaded = 0

const MAX_CONNECTIONS: int = 3 # allow at most 3 other players to connect to server
const PORT: int = 12345
var IP_ADDRESS = "127.0.0.1" # default to local host

var peer

@onready var progress_bar = $progress_bar
#endregion

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	_connect_multiplayer_callback_functions()
	GameState.PlayerCount = 1;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if load_multiplayer_lobby_scene && !GameState.GameStarted:
		_initilize_mp_lobby_instance()
		_connect_mp_lobby_signals()
		load_multiplayer_lobby_scene = false

#region Multiplayer Callback functions
func _connect_multiplayer_callback_functions():
	multiplayer.peer_connected.connect(_mp_on_peer_connected)
	multiplayer.peer_disconnected.connect(_mp_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_mp_on_connected_ok)
	multiplayer.connection_failed.connect(_mp_on_connected_fail)
	multiplayer.server_disconnected.connect(_mp_on_server_disconnected)

func _mp_on_peer_connected(id: int):
	if !GameState.GameStarted:
		_register_player.rpc_id(id, UserProfiles.profiles[UserProfiles._get_selected_profile_key()])
		print("peer %s to %s" % [id, multiplayer.get_unique_id()])
	elif multiplayer.is_server():
		_kick_peer.rpc_id(id, "Connection Refused, quiz in progress")
		
func _mp_on_peer_disconnected(id: int):
	GameState.players.erase(id)
	GameState.PlayerCount -= 1
	mp_lobby_root._update_connected_players()
	
	if GameState.GameStarted:
		quiz_session_instance._player_dropped()
		
	print("Info: player %s disconneted" % id)
	
# player has connected to server
func _mp_on_connected_ok():
	var playerData = GameState.Player.new()
	playerData.initilize(UserProfiles.profiles[UserProfiles._get_selected_profile_key()], multiplayer.get_unique_id())
	GameState.players[multiplayer.get_unique_id()] = playerData
	mp_lobby_instance._connected_to_server()

# player has failed to connect to server
func _mp_on_connected_fail():
	multiplayer.multiplayer_peer = null
	mp_lobby_instance._connection_reset("Failed To Connect")
	
# player has been disconnected from server
func _mp_on_server_disconnected():
	multiplayer.multiplayer_peer = null
	GameState.players.clear()
	mp_lobby_instance._connection_reset("Disconnected From Server")
#endregion

#region Multiplayer RPC functions
@rpc("any_peer", "reliable")
func _register_player(playerProfile):
	# if the game is already in progress deny new connections

	var playerData = GameState.Player.new()
	var newPlayerId = multiplayer.get_remote_sender_id()
	playerData.initilize(playerProfile, newPlayerId)
	
	GameState.players[newPlayerId] = playerData
	
	GameState.PlayerCount += 1
	mp_lobby_root._refresh_connected_players_list()
	print("Info: player %s connected" % playerData.uuid)

@rpc("authority", "call_local", "reliable")
func load_quiz():
	_local_update_selected_scene()
	quiz_session_instance = quiz_session_scene.instantiate()
	quiz_session_instance.end_of_quiz.connect(_end_of_quiz_handler)
	quiz_session_instance.exit_quiz.connect(_exit_quiz_handler)
	get_tree().root.add_child(quiz_session_instance)

@rpc("authority", "reliable")
func _kick_peer(reason):
	multiplayer.multiplayer_peer = null
	GameState.players.clear()
	mp_lobby_instance._connection_reset(reason)

# called by the server to start the quiz
@rpc("authority", "call_local", "reliable")
func _launch_quiz():
	if multiplayer.has_multiplayer_peer() && multiplayer.is_server():
		GAME_STATE = MP_STATE.STARTGAME
		print("Info: server is launching quiz")


#endregion

#region Multiplayer lobby functions
func _initilize_mp_lobby_instance():
	mp_lobby_instance = mp_lobby_scene.instantiate()
	get_tree().root.add_child(mp_lobby_instance)
	mp_lobby_root = mp_lobby_instance.get_node("/root/MultiplayerLobby")

func _connect_mp_lobby_signals():
	mp_lobby_root.sig_mp_host.connect(_mp_lobby_host_server)
	mp_lobby_root.sig_mp_connect.connect(_mp_lobby_join)
	mp_lobby_root.sig_mp_disconnect.connect(_mp_lobby_disconnect)
	mp_lobby_root.sig_mp_kick_peer.connect(_mp_lobby_kick_peer)
	mp_lobby_root.sig_mp_launch.connect(_mp_lobby_launch_quiz)
	mp_lobby_root.sig_mp_exit.connect(_mp_lobby_exit)

func _mp_lobby_host_server(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

	var playerData = GameState.Player.new()
	playerData.initilize(UserProfiles.profiles[UserProfiles._get_selected_profile_key()], 1)
	GameState.players[1] = playerData
	
	mp_lobby_instance._refresh_connected_players_list()
	print("Hosting server on IP: %s, PORT: %d" % [IP_ADDRESS, PORT])

func _mp_lobby_join(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

func _mp_lobby_disconnect():
	if multiplayer.has_multiplayer_peer():
		print("Peer Id:[%s], disconnecting" % multiplayer.get_unique_id())
		multiplayer.multiplayer_peer = null
	GameState.players.clear()
	GameState.PlayerCount = 1

func _mp_lobby_kick_peer(peer_id: int):
	if multiplayer.get_peers().has(peer_id) && peer_id != 1: 
		_kick_peer.rpc_id(peer_id, "Kicked From Lobby.")
		print("Peer Id:[%s] has been kicked." % peer_id)
	else:
		print("!WARN: attempted to kick peer that does not exist Id:[%s]" % peer_id)

func _mp_lobby_launch_quiz():
	if multiplayer.is_server():
		_launch_quiz.rpc()
	else:
		print("!WARN!: recived launch quiz signal from non host!")

func _mp_lobby_exit():
	_quit_to_main_menu()

#endregion


func _set_ip(ip_address):
	IP_ADDRESS = ip_address

func _end_of_quiz_handler():
	SoundMaster._play_music_track("mp_lobby")
	if multiplayer.is_server():
		mp_lobby_instance._enable_launch_button()
	
func _exit_quiz_handler():
	multiplayer.multiplayer_peer = null
	mp_lobby_instance._reset_lobby()

func _quit_to_main_menu():
	#TODO: send a disconnet packet to all connected peers
	mp_lobby_instance.queue_free()
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")

func _local_update_selected_scene():
	#load chalkboard scene by default in the case of bad input
	var selectedtheme = "res://assets/scenes/quiz_session.tscn"

	if GameState.CurrentTheme == "Patriotic Cipher":
		selectedtheme = "res://assets/scenes/cipher.tscn"
	elif GameState.CurrentTheme == "Fatal Surprise":
		selectedtheme = "res://assets/scenes/fatalSurprise.tscn"
	
	quiz_session_scene = load(selectedtheme)

