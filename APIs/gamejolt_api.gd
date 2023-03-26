extends Node

var web = "https://api.gamejolt.com/api/game/v1_2/"
var _http_request = HTTPRequest.new()
var _user_info: String = "user://Additional-APIs/data_user.dat"
var data_user: Dictionary = {
	"username":"",
	"user_token":""
}

func login_GJ(username: String, user_token: String):
	data_user["username"] = username
	data_user["user_token"] = user_token
	var file = FileAccess.open(_user_info, FileAccess.WRITE)
	file.store_var(data_user)

func connect_api(TYPE: String):
	if FileAccess.file_exists(_SaveCFG.gamejolt_file):
		if _SaveCFG.gamejolt_info["game_id"] == "" or _SaveCFG.gamejolt_info["private_key"] == "":
			printerr("To use the Game Jolt API it is necessary to inform the Game ID and Private Key of your Game Jolt project page in Project Settings > Additional APIs > Game Jolt")
		else:
			var LINK_BASE = web + TYPE
			var LINK_INFO = LINK_BASE + "?game_id=" + _SaveCFG.gamejolt_info["game_id"]
			var LINK_WITH_KEY = LINK_INFO + _SaveCFG.gamejolt_info["private_key"]
			var LINK_FINAL = LINK_INFO + "&signature=" + LINK_WITH_KEY.sha1_text()
			print(LINK_FINAL)
	else:
		printerr("To use the Game Jolt API it is necessary to inform the Game ID and Private Key of your Game Jolt project page in Project Settings > Additional APIs > Game Jolt")
