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
		"selected": false,
		"questions_answered": {},
		"questions_seen": {},
		"questions_chances": {},
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
	var file = FileAccess.open("user://user_profiles.json", FileAccess.READ)
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
	var saveProfilesChanges = false
	
	for key in profiles.keys():
		if !"name" in profiles[key] || !"id" in profiles[key] || !"selected" in profiles[key]:
			profiles.erase(key)
			print("!!Error: Profile [%s] in JSON failed Validation, deleting corrupted entry." % key)
			saveProfilesChanges = true
			pass
			
		if !"questions_answered" in profiles[key]:
			print("!INFO: older profile detected, adding \"questions_answered\" member")
			profiles[key]["questions_answered"] = {}
			saveProfilesChanges = true
			pass
			
		if !"questions_seen" in profiles[key]:
			print("!INFO: older profile detected, adding \"questions_seen\" member")
			profiles[key]["questions_seen"] = {}
			saveProfilesChanges = true
			pass
			
		if !"questions_chances" in profiles[key]:
			print("!INFO: older profile detected, adding \"questions_chances\" member")
			profiles[key]["questions_chances"] = {}
			saveProfilesChanges = true
			pass
			
			
		pass
		
	if saveProfilesChanges:
		_IO_write_profiles()
		pass

func _IO_write_profiles():
	var file = FileAccess.open("user://user_profiles.json", FileAccess.WRITE)
	if file:
		var jsonString = JSON.stringify(profiles)
		file.store_string(jsonString)
		file.close()
		pass
	else:
		print("!!ERROR: Failed to save profile at _save_new_profile")
		pass
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
