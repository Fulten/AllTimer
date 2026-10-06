extends Control

@onready var ui_mp_peer_display = [
	$LobbyOrganizer/Columns/NetworkingColumn/PeerCase/Peer0,
	$LobbyOrganizer/Columns/NetworkingColumn/PeerCase/Peer1,
	$LobbyOrganizer/Columns/NetworkingColumn/PeerCase/Peer2,
	$LobbyOrganizer/Columns/NetworkingColumn/PeerCase/Peer3,
	$LobbyOrganizer/Columns/NetworkingColumn/PeerCase/Peer4]
# as multiplayer lobby will be instantiated by the master scene
# we can use signals to relay actions to the master scene
signal sig_mp_profile_change
signal sig_mp_host
signal sig_mp_connect (ip)
signal sig_mp_kick_peer (mp_id: int)
signal sig_mp_disconnect
signal sig_mp_launch
signal sig_mp_exit

var ip_address = "127.0.0.1"
var IpInputTextNode

var profiles_list_id_to_name = {}

func _ready():
	$StateChangers/LaunchButton.grab_focus()
	IpInputTextNode = $LobbyOrganizer/Columns/NetworkingColumn/IPField
	IpInputTextNode.set("text", ip_address)
	_ui_refresh_profiles_dropdown()
	SoundMaster._play_music_track("mp_lobby")
	_init_filter_preset()
	_init_theme_selector()
	select_theme_by_text($LobbyOrganizer/Columns/SettingsColumn/ThemeCase/ThemesList, GameState.CurrentTheme)

func _process(_delta):
	pass

#region functions called by master scene
func _refresh_connected_players_list():
	_ui_update_connected_players()
	
func _connection_reset(error):
	print("Connection Failed: %s" % error)
	get_node("ConnectionFailedPopupCase").show()
	_ui_update_connected_players()
	_ui_reset_menu()

func _connected_to_server():
	_ui_finished_joining()
	
func _reset_lobby():
	_ui_reset_menu()
	
func _enable_launch_button():
	$StateChangers/LaunchButton.disabled = false
#endregion

#region functions used to communicate with master
func _profile_changed():
	sig_mp_profile_change.emit()

func _hosting_server():
	sig_mp_host.emit(ip_address)
	
func _joining_server():
	sig_mp_connect.emit(ip_address)

func _launching_server():
	sig_mp_launch.emit()

func _disconnecting():
	sig_mp_disconnect.emit()
	_ui_update_connected_players()
	
func _kicking_peer(mp_id):
	sig_mp_kick_peer.emit(mp_id)
	
func _quit_to_main_menu():
	sig_mp_exit.emit()
#endregion

#region UI functionality
func select_theme_by_text(option_button: OptionButton, target_text: String) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == str(target_text):
			option_button.select(i)
			return
	# if an invalid theme is selected use the default instead
	option_button.select(0)
	GameState.CurrentTheme = option_button.get_item_text(0)

func _init_theme_selector():
	var ui_themesList = $LobbyOrganizer/Columns/SettingsColumn/ThemeCase/ThemesList
	ui_themesList.clear()
	ui_themesList.add_item("Default")
	for theme in UserProfiles.THEME_NAMES:
		# uncomment the following comments, and delete the extra "ui_themesList.add_item(theme)"
		#if UserProfiles.unlocked_themes[theme]["unlocked"]:
		#	ui_themesList.add_item(theme)
		ui_themesList.add_item(theme)

func _init_filter_preset():
	$LobbyOrganizer/Columns/SettingsColumn/Filters/FilterPresetList.clear()
	var whitelist_btn = $LobbyOrganizer/Columns/SettingsColumn/Filters/WhitelistToggle
	if GameState.TagsFilters.size() > 0:
		var i:int = 0
		var selected:int = 0
		for key in GameState.TagsFilters:
			$LobbyOrganizer/Columns/SettingsColumn/Filters/FilterPresetList.add_item(key)
			if GameState.TagsFilters[key]["selected"]:
				selected = i
			i += 1
		$LobbyOrganizer/Columns/SettingsColumn/Filters/FilterPresetList.selected = selected
		# set the blacklist button
		if GameState.TagsFilters[$LobbyOrganizer/Columns/SettingsColumn/Filters/FilterPresetList.get_item_text(selected)]["blacklist"]:
			whitelist_btn.text = "Is Blacklist: True"
			whitelist_btn.button_pressed = true
		else:
			whitelist_btn.text = "Is Blacklist: False"
	else:
		#if there are no filters
		$LobbyOrganizer/Columns/SettingsColumn/Filters/FilterPresetList.add_item("N/A")
		$LobbyOrganizer/Columns/SettingsColumn/Filters/FilterPresetList.disabled = true
		whitelist_btn.disabled = true

func _ui_update_connected_players():
	for n in range(0, 4):
		ui_mp_peer_display[n].text = ""
		ui_mp_peer_display[n].hide()
	var k = 0
	for key in GameState.players:
		if k > 3:
			print("ERROR: Players array has exceeded size 4")
			return
		if GameState.players[key]["active"]:
			ui_mp_peer_display[k].text = GameState.players[key].name
			ui_mp_peer_display[k].show()
			k += 1

func _ui_finished_joining():
	$LobbyOrganizer/Columns/NetworkingColumn/JoiningLabel.hide()
	$LobbyOrganizer/Columns/NetworkingColumn/JoinedLabel.show()

func _ui_refresh_profiles_dropdown():
	var profile_list = $LobbyOrganizer/Columns/SettingsColumn/ProfileCase/ProfilesList
	var id = 0
	profile_list.clear()
	
	if UserProfiles.profiles.size() <= 0: # use placeholder if profiles list is empty
		profile_list.add_item("N/A")
		return
	for key in UserProfiles.profiles.keys():
		profile_list.add_item(UserProfiles.profiles[key]["name"])
		profiles_list_id_to_name[id] = UserProfiles.profiles[key]["name"]
		if (UserProfiles.profiles[key]["selected"]):
			profile_list.select(id)
		id += 1

func _ui_reset_menu():
	$LobbyOrganizer/Columns/NetworkingColumn/HostingLabel.hide()
	$LobbyOrganizer/Columns/NetworkingColumn/JoiningLabel.hide()
	$LobbyOrganizer/Columns/NetworkingColumn/JoinedLabel.hide()
	$LobbyOrganizer/Columns/NetworkingColumn/CancelConnectionButton.hide()
	$LobbyOrganizer/Columns/NetworkingColumn/PeerConnectors.show()
	
	$LobbyOrganizer/Columns/SettingsColumn/ProfileCase/ProfilesList.disabled = false
	
	$LobbyOrganizer/Columns/NetworkingColumn/CancelConnectionButton.disabled = true
	$LobbyOrganizer/Columns/NetworkingColumn/PeerConnectors/HostButton.disabled = false
	$LobbyOrganizer/Columns/NetworkingColumn/PeerConnectors/JoinButton.disabled = false
	$StateChangers/LaunchButton.disabled = true
#endregion

#region Ui Signals
func _on_host_button_mouse_entered():
	$SFX_Hover.play()
func _on_host_button_focus_entered():
	$SFX_Hover.play()
func _on_host_button_button_down():
	$SFX_Press.play()
func _on_host_button_button_up():
	$LobbyOrganizer/Columns/NetworkingColumn/PeerConnectors.hide()
	$LobbyOrganizer/Columns/NetworkingColumn/HostingLabel.show()
	$LobbyOrganizer/Columns/NetworkingColumn/CancelConnectionButton.show()
	
	$LobbyOrganizer/Columns/SettingsColumn/ProfileCase/ProfilesList.disabled = true
	$LobbyOrganizer/Columns/NetworkingColumn/CancelConnectionButton.disabled = false
	
	$LobbyOrganizer/Columns/NetworkingColumn/PeerConnectors/HostButton.disabled = true
	$LobbyOrganizer/Columns/NetworkingColumn/PeerConnectors/JoinButton.disabled = true
	$StateChangers/LaunchButton.disabled = false
	_hosting_server()

func _on_join_button_mouse_entered():
	$SFX_Hover.play()
func _on_join_button_focus_entered():
	$SFX_Hover.play()
func _on_join_button_button_down():
	$SFX_Press.play()
func _on_join_button_button_up():
	$LobbyOrganizer/Columns/NetworkingColumn/PeerConnectors.hide()
	$LobbyOrganizer/Columns/NetworkingColumn/JoiningLabel.show()
	$LobbyOrganizer/Columns/NetworkingColumn/CancelConnectionButton.show()
	
	$LobbyOrganizer/Columns/SettingsColumn/ProfileCase/ProfilesList.disabled = true
	
	$LobbyOrganizer/Columns/NetworkingColumn/CancelConnectionButton.disabled = false
	$LobbyOrganizer/Columns/NetworkingColumn/PeerConnectors/HostButton.disabled = true
	$LobbyOrganizer/Columns/NetworkingColumn/PeerConnectors/JoinButton.disabled = true
	_joining_server()

func _on_cancel_connection_button_mouse_entered():
	$SFX_Hover.play()
func _on_cancel_connection_button_focus_entered():
	$SFX_Hover.play()
func _on_cancel_connection_button_button_down():
	$SFX_Press.play()
func _on_cancel_connection_button_button_up():
	_ui_reset_menu()
	_disconnecting()

func _on_launch_button_mouse_entered():
	$SFX_Hover.play()
func _on_launch_button_focus_entered():
	$SFX_Hover.play()
func _on_launch_button_button_down():
	$SFX_Press.play()
func _on_launch_button_button_up():
	$StateChangers/LaunchButton.disabled = true
	_launching_server()

func _on_back_to_main_button_mouse_entered():
	$SFX_Hover.play()
func _on_back_to_main_button_focus_entered():
	$SFX_Hover.play()
func _on_back_to_main_button_button_down():
	$SFX_Press.play()
func _on_back_to_main_button_button_up():
	_quit_to_main_menu()

func _on_conn_fail_ack_mouse_entered():
	$SFX_Hover.play()
func _on_conn_fail_ack_focus_entered():
	$SFX_Hover.play()
func _on_conn_fail_ack_button_down():
	$SFX_Press.play()
func _on_conn_fail_ack_button_up():
	get_node("ConnectionFailedPopupCase").hide()

func _on_whitelist_toggle_button_up():
	var key = $LobbyOrganizer/Columns/SettingsColumn/Filters/FilterPresetList.get_item_text($LobbyOrganizer/Columns/SettingsColumn/Filters/FilterPresetList.get_selected_id())
	var button = $LobbyOrganizer/Columns/SettingsColumn/Filters/WhitelistToggle
	if button.button_pressed:
		button.text = "Is Blacklist: True"
		GameState.TagsFilters[key]["blacklist"] = true
	else:
		button.text = "Is Blacklist: False"
		GameState.TagsFilters[key]["blacklist"] = false
	GameState._IO_write_tags_filter()

func _on_filter_preset_list_item_selected(index):
	var key = $LobbyOrganizer/Columns/SettingsColumn/Filters/FilterPresetList.get_item_text(index)
	var whitelist_btn = $LobbyOrganizer/Columns/SettingsColumn/Filters/WhitelistToggle
	#update the selected tag
	for filter in GameState.TagsFilters:
		GameState.TagsFilters[filter]["selected"] = false
		pass
	GameState.TagsFilters[key]["selected"] = true
	# set the blacklist button
	if GameState.TagsFilters[key]["blacklist"]:
		whitelist_btn.text = "Is Blacklist: True"
		whitelist_btn.button_pressed = true
	else:
		whitelist_btn.text = "Is Blacklist: False"
		whitelist_btn.button_pressed = false
		
	GameState._IO_write_tags_filter()

func _on_ip_field_text_changed():
	ip_address = IpInputTextNode.get("text")
	
func _on_themes_list_item_selected(index):
	var ui_themesList = $LobbyOrganizer/Columns/SettingsColumn/ThemeCase/ThemesList
	GameState.CurrentTheme = ui_themesList.get_item_text(index)
	# save change to theme to file
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		config.set_value("video", "theme", ui_themesList.get_item_text(ui_themesList.get_selected_id()))
		config.save("user://settings.cfg")

func _on_profiles_list_item_selected(index):
	for key in UserProfiles.profiles.keys():
		UserProfiles.profiles[key]["selected"] = false
		
	UserProfiles.profiles[profiles_list_id_to_name[index]]["selected"] = true
	UserProfiles._IO_write_profiles()
	_profile_changed()
#endregion

