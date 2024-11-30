extends Control

const PORT: int = 12345  # The port for hosting and connecting

var peer;

func _ready() -> void:
	$VBoxContainer/Host.pressed.connect(self._on_host_button_pressed)
	$VBoxContainer/Connect.pressed.connect(self._on_connect_button_pressed)
	$VBoxContainer/IPAddress.text = "127.0.0.1"  # Default to localhost
	$StatusLabel.text = "Status: Idle"


func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	var result = peer.listen(PORT, 4)  # Set up the server with a max of 4 connections
	if result == OK:
		multiplayer.set_muliplayer_peer(peer)
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		_add_player()
		$StatusLabel.text = "Hosting on port %d..." % PORT
	else:
		$StatusLabel.text = "Failed to host. Error: %s" % result


func _on_connect_button_pressed() -> void:
	var ip = $VBoxContainer/IPAddress.text
	peer = ENetMultiplayerPeer.new()
	var result = peer.connect_to_host(ip, PORT)
	if result == OK:
		multiplayer.peer = peer
		$StatusLabel.text = "Connecting to %s:%d..." % [ip, PORT]
	else:
		$StatusLabel.text = "Failed to connect. Error: %s" % result


func _add_player(id = 1):
	GameState._add_online_player(id, "Player "+ str(id))


func _exit_game(id):
	multiplayer.peer_disconnected.connect(_remove_player)
	_remove_player(id)


func _remove_player(id = 1):
	rpc("remove_player", id)


@rpc("any_peer", "call_local") func remove_player(id):
	GameState._remove_online_player(id)


func _process(delta: float) -> void:
	if multiplayer.peer != null:
		match multiplayer.peer.connection_status:
			MultiplayerPeer.CONNECTION_CONNECTING:
				$StatusLabel.text = "Connecting..."
			MultiplayerPeer.CONNECTION_CONNECTED:
				if is_hosting:
					$StatusLabel.text = "Hosting and connected."
				else:
					$StatusLabel.text = "Connected to host!"
			MultiplayerPeer.CONNECTION_DISCONNECTED:
				$StatusLabel.text = "Disconnected."
