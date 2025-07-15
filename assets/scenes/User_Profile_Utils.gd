extends Node


var UserProfiles = {}


func _new_profile(profileName):
	var newID = 0
	if UserProfiles != null:
		for key in UserProfiles.keys():
			if UserProfiles[key]["id"] >= newID:
				newID = UserProfiles[key]["id"] + 1
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
	if !UserProfiles.has(newProfile.name):
		print("!INFO: Saving New Profile: [%s]" % newProfile.name)
		UserProfiles[newProfile.name] = newProfile
		_IO_write_profiles()
		pass
	else:
		print("!INFO: Profile Name Collision [%s]" % newProfile.name)
		pass
	pass
	
func _delete_profile(profileName):
	print("!INFO: Deleting Existing Profile: [%s]" % profileName)
	UserProfiles.erase(profileName)
	pass

func _IO_read_profiles():
	var file = FileAccess.open("res://data/user_profiles.json", FileAccess.READ)
	if file:
		UserProfiles = JSON.parse_string(file.get_as_text())
		file.close()
		pass
	else:
		print("!!ERROR: Failed to read profiles at _read_profiles")
		pass
		
	if UserProfiles == null:
		UserProfiles = {}
		pass
	

func _IO_write_profiles():
	var file = FileAccess.open("res://data/user_profiles.json", FileAccess.WRITE)
	if file:
		var jsonString = JSON.stringify(UserProfiles)
		file.store_string(jsonString)
		file.close()
		pass
	else:
		print("!!ERROR: Failed to save profile at _save_profile")
		pass
	pass
