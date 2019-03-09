AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile("cl_database.lua")
AddCSLuaFile("items.lua")
AddCSLuaFile( "shared.lua" )
AddCSLuaFile("cl_round_controller.lua")
AddCSLuaFile("cl_lobby.lua")
AddCSLuaFile("hud.lua")
AddCSLuaFile("cl_tablecam.lua")
AddCSLuaFile("sounds.lua")
AddCSLuaFile("sh_soundmanager.lua")
AddCSLuaFile("cl_options.lua")

include("sv_database.lua")
include("items.lua")
include( "shared.lua" )
include("sv_round_controller.lua")
include("sv_lobby.lua")
include("sv_tablecam.lua")
include("sounds.lua")
include("sh_soundmanager.lua")
include("sv_soundmanager.lua")

function GM:AddNetworkStrings()
	util.AddNetworkString("OpenLobby")
	util.AddNetworkString("StartGame")
	util.AddNetworkString("closeLobby")
	util.AddNetworkString("KEY_USE")
	util.AddNetworkString("ZawaPlay")
	util.AddNetworkString("UpdateRoundStatus")
	util.AddNetworkString("database")
	util.AddNetworkString("UpdateTableView")
	util.AddNetworkString("InventoryDrop")
	util.AddNetworkString("RemovePlayer")
	util.AddNetworkString("FadeInMusic")
	util.AddNetworkString("PlayerTableCheckGUIEnable")
	util.AddNetworkString("ArePlayersReady")
	util.AddNetworkString("AnnounceWinnerOfMatch")
end

GM:AddNetworkStrings()

resource.AddFile("materials/models/gamecard/GameCard_Rock.vmt")
resource.AddFile("materials/models/gamecard/GameCard_Paper.vmt")
resource.AddFile("materials/models/gamecard/GameCard_Scissors.vmt")
resource.AddFile("sound/music/littlezawa_loop_by_bass.wav")
resource.AddFile("sound/ambient/zawa1.wav")
resource.AddFile("sound/ambient/zawa2.wav")
resource.AddFile("models/table/table.dx80.vtx")
resource.AddFile("models/table/table.dx90.vtx")
resource.AddFile("models/table/table.mdl")
resource.AddFile("models/table/table.phy")
resource.AddFile("models/table/table.sw.vtx")
resource.AddFile("models/table/table.vvd")

CreateConVar("rps_roundtime", "1200", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Amount of time it takes for RRPS round to end.")

local developerMode = false

------ Deletes a directory, this function is called recursively!--- do NOT use a trailing slash with this function.---
function file.PurgeDirectory(name)
	local files, directories = file.Find(name .. "/*", "DATA");

	-- Delete files 
	for a, f in pairs(files) do
		file.Delete(name .. "/" .. f);
	end-- Recurse directories
	for b, d in pairs(directories) do
		file.PurgeDirectory(name .. "/" .. d);
	end
	-- Delete directory folder, please note that if a single file in this directory failed to delete then-- this call will fail.  file.Delete can fail if it's open with something else, file.Open'd in another-- addon for example
    file.Delete(name)
end

if file.Exists("server/rrps/players","DATA") then
	file.PurgeDirectory("server/rrps/players")
	print("purging rps directory")
end

local startWeapons = {
	"weapon_fists"
}

//local pmeta = FindMetaTable("Player")

/*function pmeta:GiveLoadout()
	for k, v in pairs(startWeapons) do
		self:Give(v)
	end
end*/

function GM:PlayerSpawn(ply)
	ply:SetModel("models/player/group01/male_07.mdl")
	ply:SetupHands()
end

function GM:PlayerConnect(name, ip) 
	print("Player "..name.." has connected with IP ("..ip..")")
end

function GM:PlayerInitialSpawn(ply) 
	print("Player "..ply:Name().." has spawned.")
end

function GM:PlayerAuthed(ply, steamID, uniqueID)
	print("Player: ".. ply:Nick() .. ", has gotten authed.")
	ply:databaseCheck()
end

function GM:PlayerDisconnected(ply)
	ply:databaseDisconnect()
end

hook.Add("PlayerSay", "CommandIdent", function(ply, text, team)
	local playerMsg = string.lower(text)
	playerMsg = string.Explode(" ", playerMsg)
	// drop money command
	if (playerMsg[1] == "/dropmoney") then
		if (tonumber(playerMsg[2])) then
			local amount = tonumber(playerMsg[2])
			local plyBalance = ply:databaseGetValue("money")

			if (amount > 0 and amount <= plyBalance) then
				ply:databaseSetValue("money", plyBalance - amount)

				scripted_ents.Get("money_entity"):SpawnFunction(ply, ply:GetEyeTrace(), "money_entity"):SetValue(amount)
			end

			return ""
		end
	end
	// give money command
	if (playerMsg[1] == "/givemoney") then
		if (tonumber(playerMsg[2])) then
			local amount = tonumber(playerMsg[2])
			local plyBalance = ply:databaseGetValue("money")
			if (amount > 0) then
				ply:databaseSetValue("money", plyBalance + amount)
				print("giving " .. ply:Nick() .. " money")
			end

			return ""
		end
	end
	// check cards command
	if (playerMsg[1] == "/cards") then
		local rockcardAmount = 0
		local papercardAmount = 0
		local scissorscardAmount = 0
		for k, v in pairs(player.GetAll()) do
			//if (v:databaseGetValue("rockcards") == nil) then ErrorNoHalt("what is goin on") return end
			//print(v:inventoryGetItemAmount("rockcards"))
			rockcardAmount = rockcardAmount + v:inventoryGetItemAmount("rockcards")
			//print(rockcardAmount)
			papercardAmount = papercardAmount + v:inventoryGetItemAmount("papercards")
			scissorscardAmount = scissorscardAmount + v:inventoryGetItemAmount("scissorscards")
		end
		ply:ChatPrint(string.format("There are %i rock cards, %i paper cards, and %i scissors cards remaining.", rockcardAmount, papercardAmount, scissorscardAmount))
	end
	if (playerMsg[1] == "/developer") then
		if not ply:IsSuperAdmin() then return "" end
		if (tonumber(playerMsg[2])) then
			if (playerMsg[2] == "0") then developerMode = false end
			if (playerMsg[2] == "1") then developerMode = true end

			phy:ChatPrint("Setting developer mode to " .. developerMode)
			return ""
		end
	end
end)

hook.Add("PlayerUse", "PreventUseTable", function(ply, ent)
	if (!IsValid(ent)) then return end

	if (ent:GetName() == "rps_table") then
		if !ply:inventoryHasItem("stars", 1) then 
			print(ply:GetName() .. " has no stars") 
			return false
		end
	end
end)

function GM:CanPlayerSuicide( ply )
	return ply:IsSuperAdmin()
end

net.Receive("ZawaPlay", function(len, ply)
	ReadSound("ambient/zawa1.wav", false)
	print("zawa")
end)

net.Receive("KEY_USE", function(len, ply)
	hook.Call("KEY_USE", GAMEMODE, ply)
end)

/*hook.Add("Think", "PlayerStopMove", function()
	for _, v in pairs(player.GetAll()) do
		//print(v:GetNWBool("TableView"))
		if v:GetNWBool("TableView") then
			v:SetAbsVelocity(Vector(0,0,0))
		end
	end
end)*/

-- Music controller here.
-- idea: have music randomly chosen, or maybe chosen based on how successful you are

/*timer.Simple(945, function() 
	--plays 945 seconds in, 16 minutes 45 seconds. to fit in zawa song
	ReadSound("music/ultrazawa.wav", true)
end)*/ -- NO NO NO IF IT'S SERVERSIDE THEN IT'S A BITCH