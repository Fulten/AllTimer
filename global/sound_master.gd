extends Node

#region variables
var songs = {}
var effects = {}

var audioStreamPlayerMusic: AudioStreamPlayer2D
var audioStreamPlayerEffects: AudioStreamPlayer2D

var songDelayTimer: Timer

var next_track = ""
var next_track_loop = true

#endregion

func _ready():
	audioStreamPlayerMusic = AudioStreamPlayer2D.new()
	audioStreamPlayerEffects = AudioStreamPlayer2D.new()
	songDelayTimer = Timer.new()
	
	add_child(audioStreamPlayerMusic)
	add_child(audioStreamPlayerEffects)
	add_child(songDelayTimer)
	
	#audio stream music
	audioStreamPlayerMusic.bus = "Music"
	audioStreamPlayerMusic.max_polyphony = 1
	#audio stream effects
	audioStreamPlayerEffects.bus = "SFX"
	audioStreamPlayerEffects.max_polyphony = 1
	#timer
	songDelayTimer.timeout.connect(_private_next_track)
	songDelayTimer.one_shot = true
	
	_private_music_to_load()
	_private_effects_to_load()

# loads music tracks to be played
func _private_music_to_load():
	# main menu music
	_load_music_track("res://assets/uiux/main_menu/bgm_main.mp3", "main_menu")
	_load_music_track("res://assets/uiux/main_menu/bgm_lobby.mp3", "mp_lobby")
	_load_music_track("res://assets/uiux/main_menu/bgm_quiz.mp3", "default_theme")
	_load_music_track("res://assets/uiux/session_themes/Patriotic Cipher/MGS3 OST - Battle in the Base.mp3", "msg_theme")
	# quiz session music

# loads sound effects to be played
func _private_effects_to_load():
	_load_sound_effect("res://assets/uiux/main_menu/SFX_ButtonHover.mp3","btn_hover")
	_load_sound_effect("res://assets/uiux/main_menu/SFX_ButtonPress.mp3","btn_press")
	_load_sound_effect("res://assets/uiux/main_menu/sfx_click.mp3","sfx_click")
	_load_sound_effect("res://assets/uiux/main_menu/sfx_hover.mp3","sfx_hover")
	pass
	
func _load_music_track(file_path: String, song_name: String):
	if FileAccess.file_exists(file_path):
		songs[song_name] = load(file_path)
	else:
		print("!!Error: file under path:[%s] was not found." % file_path)
	
func _load_sound_effect(file_path: String, effect_name: String):
	if FileAccess.file_exists(file_path):
		effects[effect_name] = load(file_path)
	else:
		print("!!Error: file under path:[%s] was not found." % file_path)
	pass
	
func _play_music_track(song_name: String, looping: bool = true):
	if songs.has(song_name):
		next_track = song_name
		next_track_loop = looping
		# use a tween to fade out the volume before the next track plays
		var songDelayTween = create_tween()
		songDelayTween.tween_property(audioStreamPlayerMusic, "volume_db", -60.0, 0.9)
		
		songDelayTimer.start(1.0)
	else:
		print("!!Error: song by name:[%s] was not found in songs map" % song_name)

func _private_next_track():
	audioStreamPlayerMusic.stream = songs[next_track]
	audioStreamPlayerMusic.stream.loop = next_track_loop
	audioStreamPlayerMusic.volume_db = 0.0
	audioStreamPlayerMusic.play()

func _stop_music_track():
	if audioStreamPlayerMusic.playing:
		var songDelayTween = create_tween()
		songDelayTween.tween_property(audioStreamPlayerMusic, "volume_db", -60.0, 0.9)
		songDelayTween.tween_callback(audioStreamPlayerMusic.stop) 
	pass
		
func _play_sound_effect(effect_name: String):
	if effects.has(effect_name):
		audioStreamPlayerEffects.stream = effects[effect_name]
		audioStreamPlayerEffects.play()
	else:
		print("!!Error: effect by name:[%s] was not found in effects map" % effect_name)

func _is_music_playing():
	return audioStreamPlayerMusic.playing
	
func _is_effect_playing():
	return audioStreamPlayerEffects.playing

## expects a value between 0 and 100, 100 being loud, and 0 being silent
func _set_bus_volume_music(volume_int: int):
	var volume_db: float
	volume_db = (75-volume_int)*-0.3
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), volume_db) 
	pass
	
## expects a value between 0 and 100, 100 being loud, and 0 being silent
func _set_bus_volume_effect(volume_int: int):
	var volume_db: float
	volume_db = (75-volume_int)*-0.3
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), volume_db) 
	pass
