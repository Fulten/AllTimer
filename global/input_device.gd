extends Node
## Autoload that tracks which kind of device sent the most recent input.
## Register it in Project Settings > Globals > Autoload with the name "InputDevice".
##
## Usage:
##   InputDevice.device_changed.connect(_on_device_changed)
##   if InputDevice.current == InputDevice.DeviceType.PLAYSTATION: ...
##   if InputDevice.is_gamepad(): ...

signal device_changed(device: DeviceType, joypad_id: int)

enum DeviceType { KEYBOARD_MOUSE, XBOX, PLAYSTATION, SWITCH, GENERIC_GAMEPAD }

## Stick/trigger values below this are ignored, so drift and resting triggers
## don't flip the device away from keyboard/mouse.
const STICK_DEADZONE := 0.5
## Mouse movement smaller than this (pixels per event) is ignored, so a bumped
## desk doesn't flip the device away from a controller.
const MOUSE_MOTION_THRESHOLD := 4.0

# USB vendor IDs
const VENDOR_SONY := 0x054C
const VENDOR_MICROSOFT := 0x045E
const VENDOR_NINTENDO := 0x057E

var current: DeviceType = DeviceType.KEYBOARD_MOUSE
var last_joypad_id: int = -1

var _joy_cache: Dictionary = {}  # joypad id (int) -> DeviceType


func _ready() -> void:
	# Keep tracking while the tree is paused (pause menus need correct prompts too).
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


# _input (not _unhandled_input) so events consumed by GUI controls still count.
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			_set_device(DeviceType.KEYBOARD_MOUSE, -1)

	elif event is InputEventMouseMotion:
		if event.relative.length() >= MOUSE_MOTION_THRESHOLD:
			_set_device(DeviceType.KEYBOARD_MOUSE, -1)

	elif event is InputEventJoypadButton:
		if event.pressed:
			_set_device(_get_joy_type(event.device), event.device)

	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) >= STICK_DEADZONE:
			_set_device(_get_joy_type(event.device), event.device)

func is_gamepad() -> bool:
	return current != DeviceType.KEYBOARD_MOUSE


func is_keyboard_mouse() -> bool:
	return current == DeviceType.KEYBOARD_MOUSE


## Handy for debugging: prints e.g. "PLAYSTATION (PS5 Controller)".
func describe() -> String:
	var label: String = DeviceType.keys()[current]
	if is_gamepad() and last_joypad_id >= 0:
		label += " (%s)" % Input.get_joy_name(last_joypad_id)
	return label


func _set_device(device: DeviceType, joypad_id: int) -> void:
	if device == current and joypad_id == last_joypad_id:
		return
	var type_changed := device != current
	current = device
	last_joypad_id = joypad_id
	# Only notify when the *kind* of device changes; swapping between two
	# identical pads doesn't need new button prompts.
	if type_changed:
		device_changed.emit(current, last_joypad_id)


func _get_joy_type(id: int) -> DeviceType:
	if not _joy_cache.has(id):
		_joy_cache[id] = _detect_joy_type(id)
	return _joy_cache[id]


func _detect_joy_type(id: int) -> DeviceType:
	# 1) Vendor ID is the most reliable signal where the platform provides it.
	#    Godot may report it as a String or an int depending on platform/version.
	var info := Input.get_joy_info(id)
	var vendor := int(info.get("vendor_id", 0))
	match vendor:
		VENDOR_SONY:
			return DeviceType.PLAYSTATION
		VENDOR_MICROSOFT:
			return DeviceType.XBOX
		VENDOR_NINTENDO:
			return DeviceType.SWITCH

	# 2) Fall back to the controller name from the SDL gamepad database.
	var name := Input.get_joy_name(id).to_lower()
	for key in ["playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5", "sony"]:
		if name.contains(key):
			return DeviceType.PLAYSTATION
	for key in ["nintendo", "switch", "joy-con", "joycon", "pro controller"]:
		if name.contains(key):
			return DeviceType.SWITCH
	for key in ["xbox", "xinput", "microsoft", "x-box"]:
		if name.contains(key):
			return DeviceType.XBOX

	# 3) Unknown pad (8BitDo in XInput mode, Steam Virtual Gamepad, etc.).
	return DeviceType.GENERIC_GAMEPAD


func _on_joy_connection_changed(device: int, _connected: bool) -> void:
	# The same id can be reused by a different controller after reconnecting.
	_joy_cache.erase(device)
