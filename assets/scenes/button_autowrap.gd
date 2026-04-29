extends Button

# Called when the node enters the scene tree for the first time.
func _ready():
	get_child(0).autowrap_mode = TextServer.AUTOWRAP_WORD
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
