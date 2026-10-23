extends Node

var FILE_PATH_USER_PROFILES = "user://user_profiles.json"
var FILE_PATH_THEME_UNLOCKS = "user://theme_unlocks.json"

class Profile:
	var name: String
	var id: int
	var selected: bool
	
	var score_lowest: int
	var score_highest: int
	
	var questions_answered: Dictionary
	var questions_seen: Dictionary
	var questions_chances: Dictionary
	
	static func create(i_name: String, i_id: int, i_score_low: int, i_score_high: int)-> Profile:
		var profile = Profile.new()
		profile.name = i_name
		profile.id = i_id
		profile.selected = true
		
		profile.score_lowest = i_score_low
		profile.score_highest = i_score_high
		
		profile.questions_answered = {}
		profile.questions_seen = {}
		profile.questions_chances = {}
		
		return profile

	static func copy(old_profile: Profile) -> Profile:
		var profile = Profile.new()
		profile.name = old_profile.name
		profile.id = old_profile.id
		profile.selected = old_profile.selected
		
		profile.score_lowest = old_profile.score_lowest
		profile.score_highest = old_profile.score_highest
		
		profile.questions_answered = old_profile.questions_answered
		profile.questions_seen = old_profile.questions_seen
		profile.questions_chances = old_profile.questions_chances
		
		return profile

	static func from_raw(raw_data: Dictionary) -> Profile:
		var profile = Profile.new()
		profile.name = raw_data["name"]
		profile.id = raw_data["id"]
		profile.selected = raw_data["selected"]
		
		profile.score_lowest = raw_data["score_lowest"]
		profile.score_highest = raw_data["score_highest"]
		
		profile.questions_answered = raw_data["questions_answered"]
		profile.questions_seen = raw_data["questions_seen"]
		profile.questions_chances = raw_data["questions_chances"]
		
		return profile

	func raw() -> Dictionary:
		var profile = {}
		profile["name"] = name
		profile["id"] = id
		profile["selected"] = selected
		
		profile["score_lowest"] = score_lowest
		profile["score_highest"] = score_highest
		
		profile["questions_answered"] = questions_answered
		profile["questions_seen"] = questions_seen
		profile["questions_chances"] = questions_chances
		
		return profile

	func append_answers_answered_seen(question_uuids: Array, question_answers: Array):
		for i in range(question_uuids.size()):
			if questions_seen.has(question_uuids[i]):
				questions_seen[question_uuids[i]] += 1
			else:
				questions_seen[question_uuids[i]] = 1
			if question_answers[i]:
				if questions_answered.has(question_uuids[i]):
					questions_answered[question_uuids[i]] += 1
				else:
					questions_answered[question_uuids[i]] = 1
		
	func append_answers_chances(chances: Array):
		for i in range(chances.size()):
			if questions_chances.has(chances[i]):
				questions_chances[chances[i]] += 1
			else:
				questions_chances[chances[i]] = 1
			pass


#logic for selecting which theme to load is in Master_scene.gd
var THEME_NAMES = [
	"Chalkboard",
	"Patriotic Cipher",
	"Fatal Surprise"
]

##defines how a given theme is unlocked,
## The bool Specific_Award controls if the theme can be unlocked by any kind, 
## or only awards linked to it in the THEME_UNOCKED_BY_CHANCE map
## ex. (type: count, count: 4. theme is unlocked after getting 4 awards)
var THEME_UNLOCK_REQUIRMENT = {
	"Chalkboard": 
		{
			"Specific_Award": false,
			"count": 4
		},
	"Patriotic Cipher": 
		{
			"Specific_Award": false,
			"count": 8
		},
	"Fatal Surprise": 
		{
			"Specific_Award": false,
			"count": 12
		}
}

# table will contain uid for chances, which corrispond to a given theme
var THEME_UNOCKED_BY_CHANCE = {
	
}

var profiles_raw = {}
var profiles = {}
var chance_descriptors = {}
var unlocked_themes = {}

func _ready():
	_load_chance_data()
	_IO_read_themes_unlocks()

#region profile operations
func _new_profile_id()-> int:
	var newID = 0
	if profiles != null:
		for key in profiles.keys():
			if profiles[key].id >= newID:
				newID = profiles[key].id + 1
	return newID

## saves a new profile
func _save_new_profile(new_profile_name):
	if !profiles.has(new_profile_name):
		print("!INFO: Saving New Profile: [%s]" % new_profile_name)
		
		var new_profile = Profile.create(new_profile_name, _new_profile_id(), 0, 0)
		profiles[new_profile_name] = new_profile
		
		_IO_write_profiles()
	else:
		print("!INFO: Profile Name Collision [%s]" % new_profile_name)

## Updates an already existing profile with new statistics
func _overwrite_profile_with_reference(updated_profile: Profile):
	if profiles.has(updated_profile.name):
		profiles[updated_profile.name] = updated_profile
		_IO_write_profiles()
	else:
		print("!INFO: Profile there is no profile with name [%s]" % updated_profile.name)
	pass

func _update_profile_with_quiz_data(p_name: String, q_score: int, question_uuids: Array, question_answers: Array, chances_scored: Array):
	if profiles.has(p_name):
		var new_profile = Profile.copy(profiles[p_name])

		if q_score > new_profile.score_highest:
			new_profile.score_highest = q_score
		if q_score < new_profile.score_lowest:
			new_profile.score_lowest = q_score
		
		new_profile.append_answers_answered_seen(question_uuids, question_answers)
		new_profile.append_answers_chances(chances_scored)
		
		profiles[new_profile.name] = new_profile
		
		_IO_write_profiles()
	else:
		print("!!!ERROR: there is no profile with name [%s]" % p_name)

func _delete_profile(profileName):
	print("!INFO: Deleting Existing Profile: [%s]" % profileName)
	profiles.erase(profileName)
	_IO_write_profiles()
	pass

func _get_selected_profile_key() -> String:
	if profiles.size() < 1:
		print("!WARNING: no user profiles avalible")
		return "Guest"
	
	for key in profiles.keys():
		if profiles[key]["selected"]:
			return key
	
	print("!WARNING: no profile selected, choosing default")
	profiles[profiles.keys()[0]]["selected"] = true
	_IO_write_profiles()
	return profiles[profiles.keys()[0]]

func _get_selected_profile() -> Profile:
	return profiles[_get_selected_profile_key()]
#endregion

func _check_theme_unlock(award_hash):
	# see if the award is associated with a specific theme first
	if award_hash in THEME_UNOCKED_BY_CHANCE:
		var index = THEME_UNOCKED_BY_CHANCE[award_hash]
		if "count" in unlocked_themes[index]:
			unlocked_themes[index]["count"] += 1
		else:
			unlocked_themes[index]["count"] = 1
	
	for theme in THEME_NAMES:
		if !THEME_UNLOCK_REQUIRMENT[theme]["Specific_Award"]:
			if "count" in unlocked_themes[theme]:
				unlocked_themes[theme]["count"] += 1
			else:
				unlocked_themes[theme]["count"] = 1

## check if the chance uuid passed is valid
func _has_chance_hash(chance_uuid: String):
	if chance_uuid in chance_descriptors:
		return true
	return false

#region File Operations
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
				"icon": entry["icon"],
			}
			chance_descriptors[entry["uuid"]] = chance

func _IO_read_profiles():
	var file = FileAccess.open(FILE_PATH_USER_PROFILES, FileAccess.READ)
	if file:
		profiles_raw = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		print("!!ERROR: Failed to read profiles.")
		
	if profiles_raw == null:
		profiles_raw = {}
	
	# validate the json structure
	var saveProfilesChanges = false
	
	for key in profiles_raw.keys():
		if !"name" in profiles_raw[key] || !"id" in profiles_raw[key] || !"selected" in profiles_raw[key]:
			profiles_raw.erase(key)
			print("!!Error: Profile [%s] in JSON failed Validation, deleting corrupted entry." % key)
			saveProfilesChanges = true
			
		if !"questions_answered" in profiles_raw[key]:
			print("!INFO: older profile detected, adding \"questions_answered\" member")
			profiles_raw[key]["questions_answered"] = {}
			saveProfilesChanges = true
			
		if !"questions_seen" in profiles_raw[key]:
			print("!INFO: older profile detected, adding \"questions_seen\" member")
			profiles_raw[key]["questions_seen"] = {}
			saveProfilesChanges = true
			
		if !"questions_chances" in profiles_raw[key]:
			print("!INFO: older profile detected, adding \"questions_chances\" member")
			profiles_raw[key]["questions_chances"] = {}
			saveProfilesChanges = true
			
		# add new lowest highest score value
		if !"score_lowest" in profiles_raw[key]:
			profiles_raw[key]["score_lowest"] = 0
			saveProfilesChanges = true
			
		if !"score_highest" in profiles_raw[key]:
			profiles_raw[key]["score_highest"] = 0
			saveProfilesChanges = true
		
		# add new unlocked themes
		if !"unlocked_themes" in profiles_raw[key]:
			profiles_raw[key]["unlocked_themes"] = []
			saveProfilesChanges = true
	
		profiles[key] = Profile.from_raw(profiles_raw[key])
	
	if saveProfilesChanges:
		_IO_write_profiles()

func _IO_write_profiles():
	var file = FileAccess.open(FILE_PATH_USER_PROFILES, FileAccess.WRITE)
	
	var profile_data = {}
	for key in profiles:
		profile_data[key] = profiles[key].raw()
	
	if file:
		var jsonString = JSON.stringify(profile_data, "\t")
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
			unlocked_themes[theme] = {}
			unlocked_themes[theme]["unlocked"] = false
			unlocked_themes[theme]["count"] = 0
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
#endregion


