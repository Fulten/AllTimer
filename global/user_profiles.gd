extends Node

var FILE_PATH_USER_PROFILES = "user://user_profiles.json"
var FILE_PATH_THEME_UNLOCKS = "user://theme_unlocks.json"

#logic for selecting which theme to load is in Master_scene.gd
#
var THEME_NAMES = [
	"Chalkboard",
	"Patriotic Cipher",
	"Fatal Surprise"
]

# table will contain uid for chances, which corrispod to a given theme
var THEME_UNOCKED_BY_CHANCE = {
	
}


var profiles = {}
var chance_descriptors = {}
var unlocked_themes = {}



func _ready():
	_load_chance_data()
	_IO_read_themes_unlocks()

func _new_profile(profileName):
	var newID = 0
	if profiles != null:
		for key in profiles.keys():
			if profiles[key]["id"] >= newID:
				newID = profiles[key]["id"] + 1
				pass
			pass
		pass
	
	var newProfile = {
		"name": profileName,
		"id": newID,
		"score_lowest": 0,
		"score_highest": 0,
		"selected": false,
		"questions_answered": {},
		"questions_seen": {},
		"questions_chances": {},
		"unlocked_themes": [],
	}
	
	return newProfile

## saves a new profile
func _save_new_profile(newProfile):
	if !profiles.has(newProfile.name):
		print("!INFO: Saving New Profile: [%s]" % newProfile.name)
		profiles[newProfile.name] = newProfile
		_IO_write_profiles()
		pass
	else:
		print("!INFO: Profile Name Collision [%s]" % newProfile.name)
		pass
	pass

## Updates an already existing profile with new statistics
func _overwrite_profile_with_reference(updatedProfile):
	if profiles.has(updatedProfile.name):
		print("!INFO: Updating Profile With Name: [%s]" % updatedProfile.name)	
		var newProfile = {
			"name": updatedProfile["name"],
			"id": updatedProfile["id"],
			"score_lowest": updatedProfile["score_lowest"],
			"score_highest": updatedProfile["score_highest"],
			"selected": updatedProfile["selected"],
			"questions_answered": updatedProfile["questions_answered"],
			"questions_seen": updatedProfile["questions_seen"],
			"questions_chances": updatedProfile["questions_chances"],
		}
		profiles[updatedProfile.name] = newProfile
		_IO_write_profiles()
		pass
	else:
		print("!INFO: Profile there is no profile with name [%s]" % updatedProfile.name)
		pass
	pass

func _delete_profile(profileName):
	print("!INFO: Deleting Existing Profile: [%s]" % profileName)
	profiles.erase(profileName)
	pass

func _IO_read_profiles():
	var file = FileAccess.open(FILE_PATH_USER_PROFILES, FileAccess.READ)
	if file:
		profiles = JSON.parse_string(file.get_as_text())
		file.close()
		pass
	else:
		print("!!ERROR: Failed to read profiles.")
		pass
		
	if profiles == null:
		profiles = {}
		return
	
	# validate the json structure
	var saveProfilesChanges = false
	
	for key in profiles.keys():
		if !"name" in profiles[key] || !"id" in profiles[key] || !"selected" in profiles[key]:
			profiles.erase(key)
			print("!!Error: Profile [%s] in JSON failed Validation, deleting corrupted entry." % key)
			saveProfilesChanges = true
			
		if !"questions_answered" in profiles[key]:
			print("!INFO: older profile detected, adding \"questions_answered\" member")
			profiles[key]["questions_answered"] = {}
			saveProfilesChanges = true
			
		if !"questions_seen" in profiles[key]:
			print("!INFO: older profile detected, adding \"questions_seen\" member")
			profiles[key]["questions_seen"] = {}
			saveProfilesChanges = true
			
		if !"questions_chances" in profiles[key]:
			print("!INFO: older profile detected, adding \"questions_chances\" member")
			profiles[key]["questions_chances"] = {}
			saveProfilesChanges = true
			
		# add new lowest highest score value
		if !"score_lowest" in profiles[key]:
			profiles[key]["score_lowest"] = 0
			saveProfilesChanges = true
			
		if !"score_highest" in profiles[key]:
			profiles[key]["score_highest"] = 0
			saveProfilesChanges = true
		
		# add new unlocked themes
		if !"unlocked_themes" in profiles[key]:
			profiles[key]["unlocked_themes"] = []
			saveProfilesChanges = true
		
	if saveProfilesChanges:
		_IO_write_profiles()

func _IO_write_profiles():
	var file = FileAccess.open(FILE_PATH_USER_PROFILES, FileAccess.WRITE)
	if file:
		var jsonString = JSON.stringify(profiles)
		file.store_string(jsonString)
		file.close()
	else:
		print("!!ERROR: Failed to save profile.")

func _IO_read_themes_unlocks():
	var file = FileAccess.open(FILE_PATH_THEME_UNLOCKS, FileAccess.READ)
	if file:
		unlocked_themes = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		print("!!ERROR: Failed to read theme unlocks.")
		
	var update_file = false
	
	# fillout any themes missing from theme unlocks
	for theme in THEME_NAMES:
		if !theme in unlocked_themes:
			unlocked_themes[theme] = false
			update_file = true
	
	if update_file:
		_IO_write_themes_unlocks()

func _IO_write_themes_unlocks():
	var file = FileAccess.open(FILE_PATH_THEME_UNLOCKS, FileAccess.WRITE)
	if file:
		var jsonString = JSON.stringify(unlocked_themes)
		file.store_string(jsonString)
		file.close()
	else:
		print("!!ERROR: Failed to save theme unlocks.")
	pass
	
func _get_selected_profile_key():
	if profiles.size() < 1:
		print("!WARNING: no user profile avalible")
		return "Guest"
	
	for key in profiles.keys():
		if profiles[key]["selected"]:
			return key
		pass
	
	print("!!ERROR: it shouldn't be possible there to be no selected profile")
	return "Profile not found"

## load name, description, and type into a refrence dictionary
func _load_chance_data():
	var file = FileAccess.open("res://data/chance_data.json", FileAccess.READ)
	var raw_chance_data
	if file:
		raw_chance_data = JSON.parse_string(file.get_as_text())
		file.close()
		
		for entry in raw_chance_data:
			var chance = {
				"name": entry["name"],
				"description": entry["description"],
				"type": entry["type"],
			}
			chance_descriptors[entry["uuid"]] = chance
		
	pass

## check if the chance uuid passed is valid
func _has_chance_hash(chance_uuid: String):
	if chance_uuid in chance_descriptors:
		return true
	return false
