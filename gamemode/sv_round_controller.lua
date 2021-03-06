GM.round_status = 0 -- 0 equals end, 1 = active
local ply = FindMetaTable("Player")
local roundtime
local compoundtime

function GM:BeginRound()
	if GetGlobalBool("IsRoundStarted", false) then return end
	AdjustRoundLength()
	AdjustCompoundRate()
	print(roundtime)
	net.Start("UpdateRoundCompoundTimes")
		net.WriteFloat(compoundtime)
		net.WriteInt(roundtime, 16)
	net.Broadcast()
	hook.Run("RoundStarted")
	self.round_status = 1
	self:UpdateClientRoundStatus()
	timer.Create("CompoundInterestTime", GetConVar("rps_interestrepeat"):GetFloat(), 0, function()
		//print("interest time!")
		CompoundInterest()
	end)
	local players = player.GetAll()
	self.roundstart = CurTime()
	SetGlobalFloat("roundstart", self.roundstart)
	SetGlobalBool("IsRoundStarted", true)
	print("beginning round!")

	for k, v in pairs(players) do
		// no more nwvars, they exponentially scale data
		v:UpdatePlayerVar("rockcards", 4)
		v:UpdatePlayerVar("papercards", 4)
		v:UpdatePlayerVar("scissorscards", 4)
		v:UpdatePlayerVar("stars", 3)
		v:SetNWInt("Luck", 50)
		// luck will be used for determining what songs auto play
	end

	timer.Create("PlayerStarsPunishment", 4, 0, function()
		for k, ply in pairs(player.GetAll()) do
			if ply:Team() == TEAM_PLAYERS then
				if ply:ReturnPlayerVar("stars") == 0 and not ply:GetNWBool("Defeated") then
					if not ply:GetNWBool("Defeated", false) then 
						ply:SetNWBool("Defeated", true)
						//ply:ChatPrint(ply:Nick() .. " has been defeated!")
						ChatPrintToAllPlayers(ply:Nick() .. " has been defeated!")
						ply:SetNWInt("Luck", 0)
						print(ply:Nick() .. " has been defeated!")
					end
				end
			end
		end
	end)

	timer.Create("PlayerWinCondition", 4, 0, function()
		for k, ply in pairs(player.GetAll()) do
			//print(ply:Nick() .. " " .. ply:Team())
			if ply:Team() == TEAM_PLAYERS then
				if ply:ReturnPlayerVar("stars") >= 3 
				and ply:ReturnPlayerVar("rockcards") == 0 
				and ply:ReturnPlayerVar("papercards") == 0 
				and ply:ReturnPlayerVar("scissorscards") == 0 then // the table wins nwint is to make sure the player didn't legit just drop all their cards to cheat
					if ply:GetNWBool("Victorious", false) then return end
					ply:SetNWBool("Victorious", true)
					//ply:ChatPrint(ply:Nick() .. " is victorious!")
					ChatPrintToAllPlayers(ply:Nick() .. " is victorious!")
					ply:SetNWInt("Luck", 100)
					print(ply:Nick() .. " is victorious!")
					net.Start("AnnounceVictory")
					net.Send(ply)
				end	
			end
		end
	end)
	// update money here
end

function AdjustRoundLength()
	roundtime = (player.GetCount() * 70) 
	if player.GetCount() == 1 then roundtime = 20000 end
	GetConVar("rps_roundtime"):SetInt(roundtime)
	//SetGlobalInt("RoundTime", GetConVar("rps_roundtime"):GetInt())
	//print(GetConVar("rps_roundtime"):GetInt())
end

function AdjustCompoundRate()
	compoundtime = GetConVar("rps_roundtime"):GetInt() / 24
	GetConVar("rps_interestrepeat"):SetFloat(compoundtime)
	//SetGlobalFloat("interestrepeat", GetConVar("rps_interestrepeat"):GetFloat())
end

function GM:Think()
	if self.round_status == 1 and self.roundstart <= CurTime() then
		self.endroundtime = CurTime() + self:GetRoundTime()
		SetGlobalFloat("endroundtime", self.endroundtime) // returning 0>???
		//print("is this even running")
		self.roundstart = math.huge
	elseif self.endroundtime <= CurTime() then
		if not (GetGlobalBool("IsRoundStarted", false)) then return end
		SetGlobalBool("IsRoundStarted", false)
		self:EndRound()
		print("end round time")
	end
end

function CompoundInterest()
	//print("ok in function")
	//PrintTable(players)
	local body = 1 + GetConVar("rps_interestrate"):GetFloat()
	for k, v in pairs(player.GetAll()) do// it don't gotta check all players...  ; edit from future: what the hell do you mean you don't have to
		if v:Team() ~= TEAM_PLAYERS or v:GetNWBool("Victorious", false) then return end
		//print(body)
		local money = v:ReturnPlayerVar("debt")
		//print(money)
		local moneyAfter = money * math.pow(body,1)
		//print(moneyAfter)
		v:UpdatePlayerVar("debt", moneyAfter)
		//print(v:databaseGetValue("money"))
	end
end

function GM:EndRound()
	// do SQL stuff here to save to a database, use darkrp as reference
	self.round_status = 0
	self:UpdateClientRoundStatus()
	hook.Run("RoundEnded")
	timer.Destroy("CompoundInterestTime")
	sql.Begin()
	for k, v in pairs(player.GetAll()) do
		if not v then ErrorNoHalt("what???") return end
		if v:Team() == TEAM_PLAYERS then 
			local playerMoney = v:ReturnPlayerVar("money")
			local playerMoneySQL = ReturnPlayerVarSQL(v, "money")
			local playerDebt = v:ReturnPlayerVar("debt")
			local playerDebtSQL = ReturnPlayerVarSQL(v, "debt")

			if (playerMoney > 0) then
				playerMoney = playerMoney + v:ReturnPlayerVar("stars") * 100000
				v:UpdatePlayerVar("money", playerMoney)
				local newdebt = playerMoney - playerDebt
				//if v:GetNWBool("Defeated", false) then newdebt = newdebt + 2000000 end
				//if v:GetNWBool("Victorious", false) then newdebt = newdebt - 2000000 end
				//if v:ReturnPlayerVar("rockcards") == 0 and v:ReturnPlayerVar("scissorscards") == 0 and v:ReturnPlayerVar("papercards") == 0 then // cause fuck optimization
					//newdebt = newdebt - (v:ReturnPlayerVar("stars") * 300000)
				//end idk why this is here
				// you fucking idiot THIS WAS A GOOD IDEA SOMEWHAT

				if newdebt > 0 then 
					// player has more money than debt
					print("newdebt > 0")
					UpdatePlayerVarSQL(v, newdebt + playerMoneySQL, "money") 
					//UpdatePlayerVarSQL(v, playerDebt - newdebt, "debt")
					UpdatePlayerVarSQL(v, playerDebtSQL - newdebt, "debt")
					if playerDebtSQL - newdebt <= 0 then
						UpdatePlayerVarSQL(0, "debt") // if the money covers the debt, then set it to 0
					end
				end

				if newdebt < 0 then 
					// player has more DEBT than money
					print("newdebt < 0")
					if playerMoneySQL - newdebt <= 0 then
						UpdatePlayerVarSQL(v, 0, "money") // sets your money to 0 if you cant cover debt
						UpdatePlayerVarSQL(v, playerDebtSQL + math.abs(newdebt), "debt")
					else
						UpdatePlayerVarSQL(v, playerMoneySQL + newdebt, "money")
						// dont need to set debt here because you could cover debt
					end
					
					//UpdatePlayerVarSQL(v, (math.abs(newdebt) + playerDebtSQL), "debt")  
				end

				if newdebt == 0 then 
					// player has equal money and debt
					//UpdatePlayerVarSQL(v, 0, "money")
					//UpdatePlayerVarSQL(v, 0, "debt") no need to update any vars, if newdebt is 0, that means they can pay off their debt.
				end
			end
		end
	end
	sql.Commit()
	timer.Simple(25, function()
		print("reloading map!")
		RunConsoleCommand("changelevel", game.GetMap())
	end)
end

function GM:GetRoundStatus()
	-- body
	return self.round_status
end

function GM:UpdateClientRoundStatus()
	-- body
	net.Start("UpdateRoundStatus")
		net.WriteInt(self.round_status, 4)
	net.Broadcast()
end

// place compound stuff here
//timer.Create("CompoundInterest",75,0,compoundInterest)