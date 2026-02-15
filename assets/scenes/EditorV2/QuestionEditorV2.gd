extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i(300,100))
	DisplayServer.window_set_size(Vector2i(1240,700))
	pass
