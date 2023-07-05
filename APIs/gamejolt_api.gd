extends Node
var data_user: Dictionary = {
	"username":"",
	"user_token":"",
	"user_id" : 0
}
var user_file: String = "user://gj-credentials.dat"
enum {USER, DATA_STORE, TROPHY, SESSIONS, TIME, SCORES, FRIENDS}

func _ready():
	_SaveCFG.load_cfg()
	if FileAccess.file_exists(".gj-credentials"):
		var file = FileAccess.open(".gj-credentials",FileAccess.READ)
		var data = {}
		for i in range(3):
			data.merge({i : file.get_line()})
		await user_login(data[1],data[2])
	else:
		if FileAccess.file_exists(user_file):
			var file = FileAccess.open(user_file,FileAccess.READ)
			data_user = file.get_var()

func data_fetch(require_user: bool,key: String):
	var code = "&key=" + key
	return await connect_api("data_store",require_user,DATA_STORE,code)

func data_get_keys(require_user: bool,pattern:= ""):
	var code = ""
	if pattern != "":
		code = "&pattern=" + pattern
	return await connect_api("data_store/get_keys",require_user,DATA_STORE,code)

func data_remove(require_user: bool,key: String):
	var code = "&key=" + key
	return await connect_api("data_store/remove",require_user,DATA_STORE,code)
	
func data_set(require_user: bool,key: String,data: String):
	var code = "&key=" + key + "&data=" + data
	return await connect_api("data_store/set",require_user,DATA_STORE,code)

func data_update(require_user: bool,key: String,operation: String,value: String):
	var code = "&key=" + key + "&operation=" + operation + "&value=" + value
	return await connect_api("data_store/update",require_user,DATA_STORE,code)

func friends_list():
	return await connect_api("friends",true,FRIENDS)

func sessions_check():
	return await connect_api("sessions/check",true,SESSIONS)

func sessions_close():
	return await connect_api("sessions/close",true,SESSIONS)

func sessions_open():
	return await connect_api("sessions/open",true,SESSIONS)

func sessions_ping(status:=""):
	var code = ""
	if status != "":
		code = "&status=" + status
	return await connect_api("sessions/ping",true,SESSIONS,code)

func scores_add(require_user: bool,score:String,sort:int,table_id:int=0,guest:String="",extra_data:String=""):
	var code = "&score=" + score + "&sort=" + str(sort)
	if table_id != 0:
		code += "&table_id=" + str(table_id)
	if guest != "":
		code += "&guest=" + guest
	if extra_data != "":
		code += "&extra_data=" + extra_data 
	return await connect_api("scores/add",require_user,SCORES,code)

func scores_fetch(require_user: bool,table_id:int=0,limit:int=0,better_than:int=0,worse_than:int=0,guest:String=""):
	var code = ""
	if table_id != 0:
		code += "&table_id=" + str(table_id)
	if limit != 0:
		code += "&limit=" + str(limit)
	if better_than != 0:
		code += "&better_than=" + str(better_than)
	if worse_than != 0:
		code += "&worse_than=" + str(worse_than)
	if guest != "":
		code += "&guest=" + guest
	return await connect_api("scores",require_user,SCORES,code)

func scores_get_rank(sort:int,table_id:int=0):
	var code = "&sort=" + str(sort) 
	if table_id != -0:
		code += "&table_id=" + str(table_id)
	return await connect_api("scores/get-rank",false,SCORES,code)

func scores_table():
	return await connect_api("scores/tables",false,SCORES)

func time_server():
	return await connect_api("time", false, TIME)

func trophy_achieved(achieved:bool):
	var code = ""
	code = "&achieved=" + str(achieved)
	return await connect_api("trophies",true,TROPHY,code)

func trophy_add(trophy_id: int):
	var code = "&trophy_id=" + str(trophy_id)
	return await connect_api("trophies/add-achieved",true,TROPHY, code)

func trophies_info(trophy_id:=0):
	var code = ""
	if trophy_id != 0:
		code = "&trophy_id=" + str(trophy_id)
	return await connect_api("trophies",true,TROPHY,code)

func trophy_remove(trophy_id: int):
	var code = "&trophy_id=" + str(trophy_id)
	return await connect_api("trophies/remove-achieved",true,TROPHY, code)

func user_auth(username: String, user_token: String):
	var code = "&username=" + username + "&user_token=" + user_token
	return await connect_api("users/auth", false, USER, code)

func username_fetch(username: String):
	var code = "&username=" + username
	return await connect_api("users", false, USER, code)

func user_id_fetch(user_id: int):
	var code = "&user_id=" + str(user_id)
	return await connect_api("users", false, USER, code)

func user_login(username: String, user_token: String):
	if await user_auth(username, user_token) == "true":
		data_user["username"] = username
		data_user["user_token"] = user_token
		var data = await username_fetch(username)
		data_user["user_id"] = data["id"]
		_SaveCFG.data_save(data_user,user_file)
		return true
	else:
		return false

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
