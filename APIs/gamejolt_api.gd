extends Node
var data_user: Dictionary = {
	"username":"",
	"user_token":"",
	"user_id" : 0
}
var user_file: String = "user://gj-credentials.dat"
enum {USER, DATA_STORE, TROPHY, SESSIONS, TIME, SCORES, FRIENDS}

func connect_api(type: String, require_user: bool, action_type, code:= ""):
	if FileAccess.file_exists(_SaveCFG.file_cfg):
		if _SaveCFG.gamejolt_info["game_id"] == "" or _SaveCFG.gamejolt_info["private_key"] == "":
			printerr("To use the Game Jolt API it is necessary to inform the Game ID and Private Key of your Game Jolt project page in Project Settings > Additional APIs > Game Jolt.")
		else:
			var LINK = "https://api.gamejolt.com/api/game/v1_2/" + type + "/?game_id=" + _SaveCFG.gamejolt_info["game_id"]
			if require_user == true:
				if data_user["username"] != "" or data_user["user_token"] != "" or FileAccess.file_exists(_SaveCFG.file_cfg) == false:
					LINK += "&username=" + data_user["username"] + "&user_token=" + data_user["user_token"]
				else:
					printerr("Username and User Token is required for this function!")
			LINK += code
			var LINK_WITH_KEY: String = LINK + _SaveCFG.gamejolt_info["private_key"]
			var LINK_COMPLETE = LINK + "&signature=" + LINK_WITH_KEY.sha1_text()
			return await connect_web(LINK_COMPLETE, action_type)
	else:
		printerr("To use the Game Jolt API it is necessary to inform the Game ID and Private Key of your Game Jolt project page in Project Settings > Additional APIs > Game Jolt.")

func connect_web(LINK, action_type):
	var https_request = HTTPRequest.new()
	add_child(https_request)
	https_request.request(LINK)
	var data = await https_request.request_completed
	https_request.queue_free()
	return data_processing(data,action_type)

func data_processing(data, action_type):
	var json_data = JSON.parse_string(data[3].get_string_from_utf8())
	var response: Dictionary = json_data["response"]
	if response["success"] == "true":
		var response_data
		match action_type:
			USER:
				if response.has("users") == true:
					response_data = response.users[0]
				else:
					response_data = response.success
			DATA_STORE:
				response_data = response
				if response.has("data") == true:
					response_data = response.data
				if response.has("keys") == true:
					response_data = response.keys
				if response.size() == 1:
					response_data = response.success
			TROPHY:
				if response.has("trophies") == true:
					response_data = response.trophies
				else:
					response_data = response.success
			SESSIONS:
					response_data = response.success
			TIME:
					response_data = response
					response_data.erase("success")
			SCORES:
				if response.has("scores") == true:
					response_data = response.scores
				if response.has("rank") == true:
					response_data = response.rank
				if response.has("tables") == true:
					response_data = response.tables
				if response.size() == 1:
					response_data = response.success
			FRIENDS:
					response_data = response.friends
		return response_data
	else:
		if response.has("message") == true:
			printerr(response.message)
		return response["success"]
