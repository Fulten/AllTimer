extends Control

#region Variables
var quiz_session_scene = preload("res://assets/scenes/quiz_session.tscn")
var mp_lobby_scene = preload("res://assets/scenes/multiplayer_lobby.tscn")

var quiz_session_instance
var mp_lobby_instance

const MAX_CONNECTIONS: int = 3 # allow at most 3 other players to connect to server
const PORT: int = 12345
var IP_ADDRESS = "127.0.0.1" # default to local host

var peer

@onready var progress_bar = $progress_bar
#endregion

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	GameState.quiz_phase = GameState.QUIZSTATE.lobby
	GameState._clear_all_players()
	_connect_multiplayer_callback_functions()
	_initilize_mp_lobby_instance()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _set_ip(ip_address):
	IP_ADDRESS = ip_address

func _send_late_join_client_full_data(mp_id):
	var player_ids = []
	player_ids.resize(GameState._player_count())
	var player_names = []
	player_names.resize(GameState._player_count())
	
	var i = 0
	for key in GameState.players:
		player_ids[i] = key
		player_names[i] = GameState.players[key]["name"]
		i += 1
		
	_late_join_client.rpc_id(mp_id, mp_id, player_ids, player_names)

func _send_clients_player_data(mp_id = -1):
	var player_ids = []
	player_ids.resize(GameState._player_count())
	var player_names = []
	player_names.resize(GameState._player_count())
	
	var i = 0
	for key in GameState.players:
		player_ids[i] = key
		player_names[i] = GameState.players[key]["name"]
		i += 1
		
	if mp_id == -1:
		_sync_player_data.rpc(player_ids, player_names)
	else:
		_sync_player_data.rpc_id(player_ids, player_names)

func _close_multiplayer_peer():
	if multiplayer.is_server():
		for mp_id in multiplayer.get_peers():
			multiplayer.multiplayer_peer.disconnect_peer(mp_id)
		multiplayer.multiplayer_peer.close()
	else:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

#region Multiplayer Callback functions
func _connect_multiplayer_callback_functions():
	multiplayer.connected_to_server.connect(_mp_on_connected_to_server)
	multiplayer.connection_failed.connect(_mp_on_connected_fail)
	multiplayer.peer_connected.connect(_mp_on_peer_connected)
	multiplayer.peer_disconnected.connect(_mp_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_mp_on_server_disconnected)

# Emitted when this MultiplayerAPI's multiplayer_peer successfully connected to a server. Only emitted on clients.
func _mp_on_connected_to_server():
	GameState._add_new_player(UserProfiles._get_selected_profile()["name"], multiplayer.get_unique_id())
	mp_lobby_instance._connected_to_server()

# Emitted when this MultiplayerAPI's multiplayer_peer fails to establish a connection to a server. Only emitted on clients.
func _mp_on_connected_fail():
	multiplayer.multiplayer_peer = null
	GameState._clear_all_players()
	mp_lobby_instance._connection_reset("Unable To Connect")

# Emitted when this MultiplayerAPI's multiplayer_peer connects with a new peer. 
# ID is the peer ID of the new peer. Clients get notified when other clients connect to the same server. 
# Upon connecting to a server, a client also receives this signal for the server (with ID being 1).
func _mp_on_peer_connected(id: int):
	if multiplayer.is_server():
		_request_player_data.rpc_id(id)
		print("Info: peer %s has connected to server" % id)

# Emitted when this MultiplayerAPI's multiplayer_peer disconnects from a peer. 
# Clients get notified when other clients disconnect from the same server.
func _mp_on_peer_disconnected(id: int):
	if multiplayer.is_server():
		print("Info: peer %s has disconnected from server" % id)
		if multiplayer.has_multiplayer_peer() and GameState.players.has(id):
			if GameState._in_lobby():
				_remove_player.rpc(id)
			else:
				_deactivate_player.rpc(id)

# Emitted when this MultiplayerAPI's multiplayer_peer disconnects from server. Only emitted on clients.
func _mp_on_server_disconnected():
	multiplayer.multiplayer_peer = null
	GameState._clear_all_players()
	mp_lobby_instance._connection_reset("Disconnected From Server")
#endregions

#region Multiplayer RPC functions
@rpc("authority", "reliable")
func _kick_peer(reason):
	multiplayer.multiplayer_peer = null
	GameState._clear_all_players()
	mp_lobby_instance._connection_reset(reason)

@rpc("authority", "reliable")
func _request_player_data():
	_recive_player_data.rpc_id(multiplayer.get_remote_sender_id(), UserProfiles._get_selected_profile()["name"], GameState.activeId)

@rpc("any_peer", "reliable")
func _recive_player_data(playerName, activeId):
	if !GameState._in_lobby() and GameState._has_active_id(activeId):
		_reactivate_player.rpc(multiplayer.get_remote_sender_id(), activeId)
		_send_late_join_client_full_data(multiplayer.get_remote_sender_id())
		_send_clients_player_data()
		mp_lobby_instance._refresh_connected_players_list()
	elif GameState._player_count() >= 4:
		_kick_peer.rpc_id(multiplayer.get_remote_sender_id(), "Connection Refused,\n lobby is full")
	elif GameState._in_lobby():
		GameState._add_new_player(playerName, multiplayer.get_remote_sender_id())
		_send_clients_player_data()
		mp_lobby_instance._refresh_connected_players_list()
	else: # if the game has already started deny new players
		_kick_peer.rpc_id(multiplayer.get_remote_sender_id(), "Connection Refused,\n quiz in progress")

@rpc("authority", "reliable")
func _late_join_client(activeId, playerIds: Array, playerNames: Array):
	GameState.activeId = activeId
	
	for i in range(playerIds.size()):
		if not GameState.players.has(playerIds[i]):
			GameState._add_new_player(playerNames[i], playerIds[i])
	
	_load_into_quiz()
	_late_join_client_ready.rpc_id(1)

@rpc("any_peer", "reliable")
func _late_join_client_ready():
	quiz_session_instance._server_sync_late_join(multiplayer.get_remote_sender_id())
	
@rpc("authority", "reliable")
func _assign_active_id(id):
	GameState.activeId = id

@rpc("authority", "reliable")
func _sync_player_data(playerIds: Array, playerNames: Array):
	for i in range(playerIds.size()):
		if not GameState.players.has(playerIds[i]):
			GameState._add_new_player(playerNames[i], playerIds[i])
	mp_lobby_instance._refresh_connected_players_list()

@rpc("authority", "call_local", "reliable")
func _remove_player(mp_id):
	GameState._remove_player(mp_id)
	mp_lobby_instance._refresh_connected_players_list()

@rpc("authority", "call_local", "reliable")
func _deactivate_player(mp_id):
	GameState._deactivate_player(mp_id)
	mp_lobby_instance._refresh_connected_players_list()
	if GameState._game_started():
		quiz_session_instance._player_dropped(mp_id)

@rpc("authority", "call_local", "reliable")
func _reactivate_player(mp_id, active_id):
	GameState._reactivate_player(mp_id, active_id)
	mp_lobby_instance._refresh_connected_players_list()
	if GameState._game_started():
		quiz_session_instance._player_rejoined(mp_id)

@rpc("authority", "call_local", "reliable")
func _launch_quiz():
	_load_into_quiz()
#endregion

#region Multiplayer lobby functions
func _initilize_mp_lobby_instance():
	mp_lobby_instance = mp_lobby_scene.instantiate()
	mp_lobby_instance.sig_mp_profile_change.connect(_mp_lobby_profile_changed)
	mp_lobby_instance.sig_mp_host.connect(_mp_lobby_host_server)
	mp_lobby_instance.sig_mp_connect.connect(_mp_lobby_join)
	mp_lobby_instance.sig_mp_disconnect.connect(_mp_lobby_disconnect)
	mp_lobby_instance.sig_mp_kick_peer.connect(_mp_lobby_kick_peer)
	mp_lobby_instance.sig_mp_launch.connect(_mp_lobby_launch_quiz)
	mp_lobby_instance.sig_mp_exit.connect(_mp_lobby_exit)
	get_tree().root.add_child(mp_lobby_instance)

func _mp_lobby_profile_changed():
	GameState.activeId = -1

func _mp_lobby_host_server(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		mp_lobby_instance._connection_reset(error_string(error))
		print(error_string(error))
		return
		
	multiplayer.multiplayer_peer = peer
	
	GameState._add_new_player(UserProfiles._get_selected_profile()["name"], multiplayer.get_unique_id())
	mp_lobby_instance._refresh_connected_players_list()
	
	print("Info: Hosting server on IP: %s, PORT: %d" % [IP_ADDRESS, PORT])

func _mp_lobby_join(ip_address):
	_set_ip(ip_address)
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

func _mp_lobby_disconnect():
	if multiplayer.has_multiplayer_peer():
		_close_multiplayer_peer()
		GameState._clear_all_players()
		mp_lobby_instance._refresh_connected_players_list()

func _mp_lobby_kick_peer(peer_id: int):
	if !multiplayer.is_server():
		print("!WARN: peer other than the host attempted to kick player, this shouldn't happen.")
		return
		
	if multiplayer.get_peers().has(peer_id) && peer_id != 1: 
		_kick_peer.rpc_id(peer_id, "Kicked \"%s\"From Lobby." % peer_id)
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		print("Info: peer id:[%s] has been kicked." % peer_id)
	else:
		print("!WARN: attempted to kick peer that does not exist Id:[%s]" % peer_id)

func _mp_lobby_launch_quiz():
	if multiplayer.is_server():
		for peer_id in multiplayer.get_peers():
			_assign_active_id.rpc_id(peer_id, peer_id)
		_launch_quiz.rpc()
	else:
		print("!WARN: attempted to launch quiz as non-host!")

func _mp_lobby_exit():
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null
		GameState._clear_all_players()
		mp_lobby_instance._refresh_connected_players_list()
	_quit_to_main_menu()

func _quit_to_main_menu():
	mp_lobby_instance.queue_free()
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
#endregion

#region quiz session functions
func _load_into_quiz():
	GameState.quiz_phase = GameState.QUIZSTATE.loading
	_initilize_quiz_scene()

func _initilize_quiz_scene():
	_local_update_selected_scene()
	quiz_session_instance = quiz_session_scene.instantiate()
	quiz_session_instance.sig_end_of_quiz.connect(_end_of_quiz_handler)
	quiz_session_instance.sig_exit_quiz.connect(_exit_quiz_handler)
	get_tree().root.add_child(quiz_session_instance)

func _local_update_selected_scene():
	#load chalkboard scene by default in the case of bad input
	var selectedtheme = "res://assets/scenes/quiz_session.tscn"
	if GameState.CurrentTheme == "Patriotic Cipher":
		selectedtheme = "res://assets/scenes/cipher.tscn"
	elif GameState.CurrentTheme == "Fatal Surprise":
		selectedtheme = "res://assets/scenes/fatalSurprise.tscn"
	quiz_session_scene = load(selectedtheme)

func _end_of_quiz_handler():
	GameState.quiz_phase = GameState.QUIZSTATE.lobby
	SoundMaster._play_music_track("mp_lobby")
	mp_lobby_instance._refresh_connected_players_list()
	
	GameState.activeId = -1
	
	if multiplayer.is_server():
		mp_lobby_instance._enable_launch_button()

# if a client leaves an active quiz session, 
func _exit_quiz_handler():
	GameState.quiz_phase = GameState.QUIZSTATE.lobby
	SoundMaster._play_music_track("mp_lobby")
	_close_multiplayer_peer()
	GameState._clear_all_players()
	mp_lobby_instance._reset_lobby()
#endregion
