extends Node

var profiles = {}

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
		"selected": false
	}
	
	return newProfile
	
func _save_profile(newProfile):
	if !profiles.has(newProfile.name):
		print("!INFO: Saving New Profile: [%s]" % newProfile.name)
		profiles[newProfile.name] = newProfile
		_IO_write_profiles()
		pass
	else:
		print("!INFO: Profile Name Collision [%s]" % newProfile.name)
		pass
	pass
	
func _delete_profile(profileName):
	print("!INFO: Deleting Existing Profile: [%s]" % profileName)
	profiles.erase(profileName)
	pass

func _IO_read_profiles():
	var file = FileAccess.open("res://data/user_profiles.json", FileAccess.READ)
	if file:
		profiles = JSON.parse_string(file.get_as_text())
		file.close()
		pass
	else:
		print("!!ERROR: Failed to read profiles at _read_profiles")
		pass
		
	if profiles == null:
		profiles = {}
		return
	
	# validate the json structure
	var corruptedKeys = []
	var hasCorruptedProfile = false
	
	for key in profiles.keys():
		if "name" in profiles[key] || "id" in profiles[key] || "selected" in profiles[key]:
			corruptedKeys.append(key)
			print("!!Error: Profile [%s] in JSON failed Validation, deleting corrupted entry." % key)
			hasCorruptedProfile = true
			pass
		pass
	
	for key in corruptedKeys:
		profiles.erase(key)
		pass
		
	if hasCorruptedProfile:
		_IO_write_profiles()
		pass

func _IO_write_profiles():
	var file = FileAccess.open("res://data/user_profiles.json", FileAccess.WRITE)
	if file:
		var jsonString = JSON.stringify(profiles)
		file.store_string(jsonString)
		file.close()
		pass
	else:
		print("!!ERROR: Failed to save profile at _save_profile")
		pass
	pass

func _get_selected_profile_key():
	if profiles.size() < 1:
		print("!WARNING: no user profile avalible, this should be prevented")
		return "Guest"
	
	for key in profiles.keys():
		if profiles[key]["selected"]:
			return key
		pass
	
	print("!!ERROR: it shouldn't be possible there to be no selected profiles")
	return "Profile not found"
