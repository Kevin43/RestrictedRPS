local function TableExist()
 	if (sql.TableExists("rrps_player_info")) then
 		print("Table exists.")
 	else
 		if not (sql.TableExists("rrps_player_info")) then
 			local query = "CREATE TABLE rrps_player_info ( unique_id varchar(255), money INTEGER, debt INTEGER )"
 			local result = sql.Query(query)
 			if (sql.TableExists("rrps_player_info")) then
 				print("Table created.")
 			else
 				ErrorNoHalt("Something messed up. ")
 				print(sql.LastError(result))
 			end
 		end
 	end
end

local function InitSql()
	TableExist()
end

function UpdatePlayerVarSQL(ply, amount, var)
	if not isnumber(amount) or amount < 0 or amount >= 1 / 0 then return end
	if not var then ErrorNoHalt("Forgot to specify var!") return end

	local query = ("UPDATE rrps_player_info SET "..var.." = '"..amount.."' WHERE unique_id = '"..ply:SteamID().."'")
	//print(query)
	sql.Query(query)
	local result = sql.Query("SELECT unique_id, "..var.." FROM rrps_player_info WHERE unique_id = '"..ply:SteamID().."'")
	if (result) then
		print("Player "..var.." has been updated successfully. ", PrintTable(result))
	else
		ErrorNoHalt("Player "..var.." NOT successful, ", sql.LastError(result))
	end
end

function ReturnPlayerVarSQL(ply, var)
	local query = ("SELECT "..var.." FROM rrps_player_info WHERE unique_id = '"..ply:SteamID().."'")
	local result = sql.Query(query)
	if (result) then
		print("Player "..var.." received, is "..result)
	else
		ErrorNoHalt("Player "..var.." failed to get! ")
		print(sql.LastError(result))
	end
end

function ReturnLeaderboard(ply)
	local query = ("SELECT * FROM rrps_player_info") // to create this, i need a new var in the table for the player name
	local result = sql.Query(query)
	if (result) then
		print("Leaderboard returned.")
		local json = util.TableToJSON(result)
		//PrintTable(result)
		//print(json)
		local data = util.Compress(json)
		if not data then ErrorNoHalt("data is nil!") return end
		print(data)
		net.Start("SendLeaderboardInfo")
			net.WriteData(data, 60)
		net.Send(ply)
		//return result
	else
		ErrorNoHalt("Leaderboard return error!")
	end
end

local function CreateNewPlayer(steamID, ply)
	sql.Query("INSERT INTO rrps_player_info ('unique_id', 'money', 'debt') VALUES ('"..steamID.."', '69', '420')")
	local result = sql.Query("SELECT unique_id, money, debt FROM rrps_player_info WHERE unique_id = '"..steamID.."'")
	if (result) then
		print("Player entry in database created!")
	else
		ErrorNoHalt("Error in CreateNewPlayer, " .. sql.LastError(result))
	end
end

local function PlayerExists(ply)
	local result = sql.Query("SELECT unique_id, money, debt FROM rrps_player_info WHERE unique_id = '"..ply:SteamID().."'")
	if (result) then
		// retrieve stats
	else
		CreateNewPlayer(ply:SteamID(), ply)
	end
end

local function PlayerInitSpawn(ply)
	timer.Create("SteamID_Delay", 1, 1, function()
		timer.Create("SaveStat"..ply:SteamID(), 10, 0, function()
			//saveStat(ply)
		end)
		PlayerExists(ply)
	end)
end

hook.Add("Initialize","InitSql", InitSql)
hook.Add("PlayerInitialSpawn", "PlayerInitSpawnSql", PlayerInitSpawn)