local cardChoice = false;
local moneyAfterFormat = 0
local debtAfterFormat = 0
local compoundTimeLeft = 0
local compoundTimeRate = nil
local pmeta = FindMetaTable("Player")
local rockcards = 0
local papercards = 0
local scissorscards = 0
local stars = 0
local _roundstart = false
local rockmat, papermat, scissorsmat, timemat, zawamat, feltmat
local _curtimesubtract = nil
local ChoiceTimer, totalTime
local choiceTime = 0
local EndRoundTime
local timeLimit
include("circles.lua")

function GM:HUDShouldDraw(name)
	if name == "CHudBattery" or
		name == "CHudHealth" or 
		name == "CHudSuitPower" then
			return false
	else
		return true
	end
end

print("hud paint")

function attachCurrency(str)
	return "¥" .. str 
end

// look man this stuff is hard, i miss my c# string format
function formatMoney(n)
	if not n then return attachCurrency("0") end

	if n >= 1e14 then return attachCurrency(tostring(n)) end
    if n <= -1e14 then return "-" .. attachCurrency(tostring(math.abs(n))) end

    local negative = n < 0

    n = tostring(math.abs(n))
    local sep = sep or ","
    local dp = string.find(n, "%.") or #n + 1

    for i = dp - 4, 1, -3 do
        n = n:sub(1, i) .. sep .. n:sub(i + 1)
    end

    return (negative and "-" or "") .. attachCurrency(n)
end

local width = ScrW()
local height = ScrH()

local function normalize(min, max, val)
	if not min or not max or not val then ErrorNoHalt("you forgot min max or val!") return end
    local delta = max - min
    return (val - min) / delta
end

local roundTimerCircle = draw.CreateCircle(CIRCLE_FILLED)
roundTimerCircle:SetRadius(35)
roundTimerCircle:SetPos(width * 0.55, height * 0.045)
roundTimerCircle:SetAngles(0, 360)
roundTimerCircle:SetRotation(270)

local compoundTimerCircle = draw.CreateCircle(CIRCLE_FILLED)
compoundTimerCircle:SetRadius(25)
compoundTimerCircle:SetPos(width * 0.55, height * 0.045)
compoundTimerCircle:SetAngles(0, 360)
compoundTimerCircle:SetRotation(270)

local circleDivider = draw.CreateCircle(CIRCLE_FILLED)
circleDivider:SetRadius(15)
circleDivider:SetPos(width * 0.55, height * 0.045)
circleDivider:SetAngles(0, 360)

local function DrawInfo()
	if not _roundstart or localplayer:Team() == TEAM_SPECTATOR then return end

	//local curtimecheck = SysTime()
	// IN THE FUTURE: make a table for all of these shared divisions/multiplications
	surface.SetDrawColor(255, 255, 255, 210)
	surface.SetMaterial(rockmat)
	surface.DrawTexturedRect(width * 0.15, height * 0.86, width / 6, height / 6)

	surface.SetMaterial(papermat)
	surface.DrawTexturedRect(width * 0.40, height * 0.86, width / 6, height / 6)

	surface.SetMaterial(scissorsmat)
	surface.DrawTexturedRect(width * 0.65, height * 0.86, width / 6, height / 6)

	draw.RoundedBox(8, width / 6.4, 0, width / 4.8, height / 13.5, Color(100, 30, 30, 230)) // compound debt
	surface.SetDrawColor(170, 50, 50, 255)
	surface.DrawRect(width / 6.1935, height / 108, width / 5.0526, height / 18)

	draw.RoundedBox(8, width / 2.7428, 0, width / 3.84, height / 10.8, Color(0, 0, 0, 230)) // middle timer/stars
	surface.SetDrawColor(50, 50, 50, 255)
	surface.DrawRect(width / 2.7042, height / 108, width / 4, height / 13.5)

	draw.RoundedBox(8, width / 1.6, 0, width / 4.8, height / 13.5, Color(0, 120, 60, 230)) // actual money
	surface.SetDrawColor(0, 190, 95, 255)
	surface.DrawRect(width / 1.5867, height / 108, width / 5.0526, height / 18)	//all these divisions better not be laggy
	//print(SysTime() - curtimecheck)
	// in the future, move the values to its own variables cuz all this arithmetic must not be healthy

	local roundColor
	local compoundColor
	local timeLeft = math.max(0, GetGlobalFloat("endroundtime", 0) - CurTime())
	local compoundTxt
	local txt
	//roundTimerCircle:SetAngles(0, normalize(0, compoundtimer, timeLeft))
	//print(normalize(0, compoundtimer, timeLeft))
	//print(compoundtimer, timeLeft)
	//roundTimerCircle:SetAngles(0, normalize(0, RoundTimer, timeLeft) * 360)
	compoundTimerCircle:SetAngles(0, normalize(0, CompoundTimer, compoundTimeLeft) * 360)
	//print(normalize(0, roundtimer, timeLeft))

	/*draw.NoTexture()
	surface.SetDrawColor(0, 190, 100, 255)
	roundTimerCircle:Draw()*/
	draw.NoTexture()
	surface.SetDrawColor(180, 80, 80, 255)
	compoundTimerCircle:Draw()
	draw.NoTexture()
	surface.SetDrawColor(50, 50, 50, 255)
	circleDivider:Draw()
	if ChoiceTimer then
		choiceColor = InterpolateColor(Color(255, 0, 0), Color(0, 255, 0), totalTime, totalTime - choiceTime, totalTime - timeLimit)
		//print(totalTime .. " - " .. choiceTime .. " = " .. totalTime - choiceTime)
		draw.NoTexture()
		surface.SetDrawColor(choiceColor)
		ChoiceTimer:Draw()
	end

	if not txt then txt = string.ToMinutesSeconds(timeLeft) end
	if not compoundTxt then compoundTxt = string.ToMinutesSeconds(compoundTimeLeft) end

	rockcards = localplayer:ReturnPlayerVar("rockcards")
	papercards = localplayer:ReturnPlayerVar("papercards")
	scissorscards = localplayer:ReturnPlayerVar("scissorscards")
	stars = localplayer:ReturnPlayerVar("stars")
	if not rockcards or not papercards or not scissorscards then
		rockcards = 0
		papercards = 0
		scissorscards = 0
	end

	roundColor = InterpolateColor(Color(10, 210, 10), Color(255, 0, 0), RoundTimer, timeLeft)
	compoundColor = InterpolateColor(Color(10, 210, 10), Color(255, 0, 0), CompoundTimer, compoundTimeLeft)

	// in the future, if scrw > 1920, switch to a different, bigger font
	draw.SimpleTextOutlined(rockcards, 			"CardText", 	width * 0.27, 	height * 0.929, 	Color(114, 6, 6, 255), 	TEXT_ALIGN_CENTER, 	TEXT_ALIGN_TOP, 3, Color(255, 255, 255, 255))
	draw.SimpleTextOutlined(papercards, 		"CardText", 	width * 0.52, 	height * 0.929, 	Color(114, 6, 6, 255), 	TEXT_ALIGN_CENTER, 	TEXT_ALIGN_TOP, 3, Color(255, 255, 255, 255))
	draw.SimpleTextOutlined(scissorscards, 		"CardText", 	width * 0.77, 	height * 0.929, 	Color(114, 6, 6, 255), 	TEXT_ALIGN_CENTER, 	TEXT_ALIGN_TOP, 3, Color(255, 255, 255, 255))
	draw.SimpleTextOutlined(moneyAfterFormat, 	"NormalText", 	width / 1.58, 	height * 0.015, 	Color(48, 221, 55, 255),TEXT_ALIGN_LEFT, 	TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined(debtAfterFormat, 	"NormalText", 	width / 6.1, 	height * 0.015, 	Color(255, 80, 80, 255),TEXT_ALIGN_LEFT, 	TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	//draw.SimpleTextOutlined(txt, 				"NormalText", 	width / 1.76, 	height * 0.01, 		roundColor, 			TEXT_ALIGN_LEFT, 	TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined(compoundTxt,		"NormalText", 	width / 1.76, 	height * 0.03, 		compoundColor, 			TEXT_ALIGN_LEFT, 	TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined("Stars: " .. stars, "CardText", 	width * 0.41, 	height * 0.015, 	Color(255, 191, 0, 255),TEXT_ALIGN_CENTER, 	TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
end

function InterpolateColor(startcolor, finishcolor, maxvalue, currentvalue, minvalue)
	local hsvStart = ColorToHSV(finishcolor)
	local hsvFinish = ColorToHSV(startcolor)
	minvalue = minvalue or 0
	local hueLerp = Lerp(normalize(minvalue, maxvalue, currentvalue), hsvStart, hsvFinish)
	return HSVToColor(hueLerp, 1, 1)
end

local function UpdateDebt()
	if not _roundstart then return end
	if (LocalPlayer():ReturnPlayerVar("debt") == nil) then ErrorNoHalt("debt shouldnt be nil") return end
	local roundedDebt = math.Round(LocalPlayer():ReturnPlayerVar("debt"), 2)
	debtAfterFormat = formatMoney(roundedDebt)
end

local function UpdateMoney()
	if not _roundstart then return end
	if (LocalPlayer():ReturnPlayerVar("money") == nil) then ErrorNoHalt("how in the world is money nil??") return end
	local roundedMoney = math.Round(LocalPlayer():ReturnPlayerVar("money"), 2)
	// somehow add a lerp?
	moneyAfterFormat = formatMoney(roundedMoney)
end

function ZawaEffect()
	//surface.SetDrawColor(255, 255, 255, 210)
	//surface.SetMaterial(zawamat)
	//surface.DrawTexturedRect(math.random(0, width), math.random(0, height), 256, 256)
	print("zawaing bro im zawaing")
	local zawaFrame = vgui.Create("DFrame")
	zawaFrame:SetSize(256, 256)
	zawaFrame:SetPos(math.random(256, width - 256), math.random(256, height - 256))
	zawaFrame:ShowCloseButton(false)
	zawaFrame:SetDraggable(false)
	zawaFrame:SetTitle("")
	zawaFrame.Paint = function(s, w, h)
		draw.RoundedBox(0,0,0,w,h,Color(0, 0, 0, 0))
	end

	local zawaImg = vgui.Create("DImage", zawaFrame)
	zawaImg:SetSize(256, 256)
	zawaImg:SetImage("zawa.png")
	zawaImg:SetImageColor(Color(255, 255, 255, 0))
	
	local alpha = 0
	timer.Create("FadeInZawa", 0.002, 0, function()
		//print("fading in")
		//print(alpha)
		if alpha >= 255 then 
			timer.Create("FadeOutZawa", 0.002, 0, function()
				//print("fading out")
				//print(alpha)
				zawaImg:SetImageColor(Color(255, 255, 255, alpha))
				alpha = alpha - 10
				if alpha <= 0 then
					zawaFrame:Close()
					timer.Destroy("FadeOutZawa")
				end
			end)
			timer.Destroy("FadeInZawa")
		end
		zawaImg:SetImageColor(Color(255, 255, 255, alpha))
		alpha = alpha + 10
	end)
end

local function ZawaParticles()
	local playerpos = LocalPlayer():GetPos()
	local emitter = ParticleEmitter(playerpos)

	for i = 0, 3 do
		local part = emitter:Add(zawamat, playerpos)
		if (part) then
			part:SetPos(Vector(playerpos.x + math.random(-20, 20), playerpos.y + math.random(-20, 20), playerpos.z + math.random(-20, 20)))
			part:SetDieTime( math.random(2, 3) ) -- How long the particle should "live"
			part:SetStartAlpha( 255 ) -- Starting alpha of the particle
			part:SetEndAlpha( 0 ) -- Particle size at the end if its lifetime
			part:SetStartSize( 40 ) -- Starting size
			part:SetEndSize( 0 ) -- Size when removed

			part:SetGravity( Vector( 0, 0, 30 ) ) -- Gravity of the particle
			part:SetVelocity( VectorRand() * 50 ) -- Initial velocity of the particle
		end
	end
	emitter:Finish()
end

local function UpdateCompoundTime()
	compoundTimeRate = CompoundTimer + CurTime()
	//ZawaParticles()
	//print(compoundTimeRate) // time to take a break
end

function GM:Think()
	if not _roundstart then return end
	compoundTimeLeft = compoundTimeRate - CurTime()
end

function draw.OutlinedBox( x, y, w, h, thickness, clr )
	surface.SetDrawColor( clr )
	for i=0, thickness - 1 do
		surface.DrawOutlinedRect( x + i, y + i, w - i * 2, h - i * 2 )
	end
end // gmod wiki

local function CardChoiceGUI(enabled)
	if enabled then
		local choice = nil
		local dButtonRock, dButtonPaper, dButtonScissors
		local confirmColor = Color(255, 255, 255, 255)
		local defaultColor = Color(255, 255, 255, 150)
		local cardSpacing = 50
		local guiScale = ScrW() / 1920

		local bgFrame = vgui.Create("DFrame")
		bgFrame:SetSize(845 / guiScale, 470 / guiScale)
		bgFrame:CenterHorizontal()
		bgFrame:SetPos(bgFrame:GetPos(), 390 / guiScale)
		bgFrame:ShowCloseButton(false)
		bgFrame:SetDraggable(false)
		bgFrame:SetTitle("")
		bgFrame.Paint = function(self, w, h)
			//surface.SetDrawColor(131, 131, 7, 255)
			draw.OutlinedBox(0, 0, w, h, 10, Color(184, 184, 9, 255))
		end

		local frame = vgui.Create("DFrame")	
		frame:SetSize(825 / guiScale, 450 / guiScale)
		//frame:Center()
		//print(frame:GetSize())
		frame:CenterHorizontal()
		frame:SetPos(frame:GetPos(), 400 / guiScale)
		frame:SetVisible(true)
		frame:ShowCloseButton(false)
		frame:SetDraggable(false)
		frame:SetTitle("")
		frame:MakePopup()
		frame:SetKeyboardInputEnabled(false)
		frame.Paint = function(self, w, h)
			surface.SetDrawColor(255, 255, 255, 190)
			surface.SetMaterial(feltmat)
			surface.DrawTexturedRect(0, 0, w, h)
		end

		local timeText = vgui.Create("DFrame")
		timeText:SetSize(250, 150)
		timeText:CenterHorizontal()
		timeText:SetPos(timeText:GetPos() + 50 / guiScale, 300 / guiScale)
		timeText:ShowCloseButton(false)
		timeText:SetDraggable(false)
		timeText:SetTitle("")
		timeText.Paint = function(self, w, h)
			draw.SimpleTextOutlined(string.TrimLeft(string.ToMinutesSecondsMilliseconds(choiceTime), "00:"), "InfoRUS3", 2, 2, Color(255, 170, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0))
		end

		ChoiceTimer = draw.CreateCircle(CIRCLE_FILLED)
		ChoiceTimer:SetRadius(35)
		ChoiceTimer:SetPos(width / 2, height / 5)
		ChoiceTimer:SetAngles(0, 360)
		ChoiceTimer:SetRotation(270)

		totalTime = timeLimit + CurTime()
		choiceTime = CurTime()

		timer.Create("CircleAngleSetter", 0, 0, function()
			choiceTime = totalTime - CurTime()
			//print(choiceTime)
			ChoiceTimer:SetAngles(0, normalize(0, timeLimit, choiceTime) * 360)
		end)

		timer.Create("ChoiceTimeLimit", timeLimit, 1, function() 
			if not choice then
				choice = "Rock"
				RunConsoleCommand("rps_selection", "Rock")
			end
			timer.Destroy("ChoiceTimeLimit")
			timer.Destroy("CircleAngleSetter")
			ChoiceTimer = nil
			totalTime = nil
			choiceTime = nil
			local ent = LocalPlayer():GetNWEntity("TableUsing", NULL)
			net.Start("ArePlayersReady")
			net.WriteEntity(ent)
			net.WriteBool(true)
			net.SendToServer()
			frame:Close()
			timeText:Close()
			bgFrame:Close()
			// i need to write the entity that the player is looking at...
		end)

		local dButtonReady = vgui.Create("DButton", frame)
		dButtonReady:SetText("Confirm Choice")
		dButtonReady:CenterHorizontal()
		dButtonReady:SetPos((frame:GetWide() / 2) - 100, 375 / guiScale)
		dButtonReady:SetSize(200, 60)
		dButtonReady:SetEnabled(false)
		dButtonReady.DoClick = function()
			timer.Destroy("ChoiceTimeLimit")
			timer.Destroy("CircleAngleSetter")
			ChoiceTimer = nil
			totalTime = nil
			choiceTime = nil
			choice = nil
			local ent = LocalPlayer():GetNWEntity("TableUsing", NULL)
			net.Start("ArePlayersReady")
			net.WriteEntity(ent)
			net.WriteBool(true)
			net.SendToServer()
			frame:Close()
			timeText:Close()
			bgFrame:Close()
		end

		local rockBorder = vgui.Create("DFrame", frame)
		rockBorder:SetSize(245, 315)
		rockBorder:SetPos(15, 40)
		rockBorder:ShowCloseButton(false)
		rockBorder:SetDraggable(false)
		rockBorder:SetTitle("")
		rockBorder.Paint = function(self, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(237, 135, 209))
		end

		local paperBorder = vgui.Create("DFrame", frame)
		paperBorder:SetSize(245, 315)
		paperBorder:SetPos(240 + cardSpacing, 40)
		paperBorder:ShowCloseButton(false)
		paperBorder:SetDraggable(false)
		paperBorder:SetTitle("")
		paperBorder.Paint = function(self, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(95, 226, 246))
		end

		local scissorsBorder = vgui.Create("DFrame", frame)
		scissorsBorder:SetSize(245, 315)
		scissorsBorder:SetPos(515 + cardSpacing, 40)
		scissorsBorder:ShowCloseButton(false)
		scissorsBorder:SetDraggable(false)
		scissorsBorder:SetTitle("")
		scissorsBorder.Paint = function(self, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(220, 232, 120))
		end

		local function SetButtonColors()
			if choice == "Rock" then
				dButtonRock:SetColor(confirmColor)
				dButtonPaper:SetColor(defaultColor)
				dButtonScissors:SetColor(defaultColor) // i hate this so much
				rockBorder:SetVisible(true)
				paperBorder:SetVisible(false)
				scissorsBorder:SetVisible(false)
			elseif choice == "Paper" then
				dButtonRock:SetColor(defaultColor)
				dButtonPaper:SetColor(confirmColor)
				dButtonScissors:SetColor(defaultColor)
				rockBorder:SetVisible(false)
				paperBorder:SetVisible(true)
				scissorsBorder:SetVisible(false)
			elseif choice == "Scissors" then
				dButtonRock:SetColor(defaultColor)
				dButtonPaper:SetColor(defaultColor)
				dButtonScissors:SetColor(confirmColor)
				rockBorder:SetVisible(false)
				paperBorder:SetVisible(false)
				scissorsBorder:SetVisible(true)
			elseif not choice then
				return
			end
		end

		dButtonRock = vgui.Create("DImageButton", frame)
		dButtonRock:SetImage("choice_rock.png")
		//dButtonRock:SetText("Rock")
		dButtonRock:SetPos(25, 50)
		dButtonRock:SetSize(225, 295)
		dButtonRock:SetStretchToFit(true)
		dButtonRock.DoClick = function()
			//dButtonRock:SetColor(confirmColor)
			RunConsoleCommand("rps_selection", "Rock")
			choice = "Rock"
			dButtonReady:SetEnabled(true)
			SetButtonColors()
		end

		dButtonPaper = vgui.Create("DImageButton", frame)
		dButtonPaper:SetImage("choice_paper.png")
		//dButtonPaper:SetText("Paper")
		dButtonPaper:SetPos(250 + cardSpacing, 50)
		dButtonPaper:SetSize(225, 295)
		dButtonPaper:SetStretchToFit(true)
		dButtonPaper.DoClick = function()
			//dButtonPaper:SetColor(confirmColor)
			RunConsoleCommand("rps_selection", "Paper")
			choice = "Paper"
			dButtonReady:SetEnabled(true)
			SetButtonColors()
		end

		dButtonScissors = vgui.Create("DImageButton", frame)
		dButtonScissors:SetImage("choice_scissors.png")
		//dButtonScissors:SetText("Scissors")
		dButtonScissors:SetPos(525 + cardSpacing, 50)
		dButtonScissors:SetSize(225, 295)
		dButtonScissors:SetStretchToFit(true)
		dButtonScissors.DoClick = function()
			//dButtonScissors:SetColor(confirmColor)
			RunConsoleCommand("rps_selection", "Scissors")
			choice = "Scissors"
			dButtonReady:SetEnabled(true)
			SetButtonColors()
		end

		//dButtonRock:SetColor(defaultColor)
		//dButtonPaper:SetColor(defaultColor)
		//dButtonScissors:SetColor(defaultColor)

		if (LocalPlayer():ReturnPlayerVar("rockcards") < 1) then
			print("disabled")
			dButtonRock:SetEnabled(false)
		end
		if (LocalPlayer():ReturnPlayerVar("papercards") < 1) then
			dButtonPaper:SetEnabled(false)
		end
		if (LocalPlayer():ReturnPlayerVar("scissorscards") < 1) then
			dButtonScissors:SetEnabled(false)
		end
		
	elseif not enabled then
		//close all frames
	end
end

net.Receive("PlayerTableCheckGUIEnable", function(len, ply)
	//cardChoice = true
	timeLimit = net.ReadUInt(12)
	print("playertablecheckguienable has been received")
	CardChoiceGUI(true)
end)

local function safeText(text)
	return string.match(text, "^#([a-zA-Z_]+)$") and text .. " " or text
end

pmeta.drawPlayerInfo = pmeta.drawPlayerInfo or function(self)
	if not _roundstart then return end
	local pos = self:EyePos()

	pos.z = pos.z + 10
	pos = pos:ToScreen()

	draw.SimpleText(safeText(self:Nick()), "ScoreboardDefault", pos.x + 1, pos.y + 1, Color(0, 0, 0, 255), 1)
	draw.SimpleText(safeText(self:Nick()), "ScoreboardDefault", pos.x, pos.y, Color(255, 255, 255, 255), 1)
	if self:Team() ~= TEAM_PLAYERS then return end

	draw.SimpleText(self:ReturnPlayerVar("stars") .. " Stars", "ScoreboardDefault", pos.x + 1, pos.y + 21, Color(0, 0, 0, 255), 1)
	draw.SimpleText(self:ReturnPlayerVar("stars") .. " Stars", "ScoreboardDefault", pos.x, pos.y + 20, Color(255, 191, 0, 255), 1)
end

local function DrawEntityDisplay()
    local shootPos = localplayer:GetShootPos()
    local aimVec = localplayer:GetAimVector()

    for _, ply in pairs(players or player.GetAll()) do
        if not IsValid(ply) or ply == localplayer or not ply:Alive() or ply:GetNoDraw() or ply:IsDormant() then continue end
        local hisPos = ply:GetShootPos()

        if hisPos:DistToSqr(shootPos) < 80000 then
            local pos = hisPos - shootPos
            local unitPos = pos:GetNormalized()
            if unitPos:Dot(aimVec) > 0.95 then
                local trace = util.QuickTrace(shootPos, pos, localplayer)
                if trace.Hit and trace.Entity ~= ply then break end
                ply:drawPlayerInfo()
            end
        end
    end
end

hook.Add("RoundStarted", "roundstarthud", function()
	rockmat = Material("hud_rock.png")
	papermat = Material("hud_paper.png")
	scissorsmat = Material("hud_scissors.png")
	timemat = Material("time_bg.png")
	feltmat = Material("felt_bg.png")
	//zawamat = Material("zawa")
	timer.Create("UpdateMoney", 0.5, 0, UpdateMoney)
	timer.Create("UpdateDebt", 0.5, 0, UpdateDebt)

	compoundTimeRate = CompoundTimer + CurTime()
	print(compoundTimeRate)
	//EndRoundTime = GetGlobalFloat("endroundtime", 0)
	//compoundtimer = GetGlobalFloat("interestrepeat", 75)
	//print(compoundtimer)
	//roundtimer = GetGlobalInt("endroundtime", 1200)
	//print(roundtimer)
	_curtimesubtract = CurTime()
	_roundstart = true
	timer.Create("CompoundTimeHUD", CompoundTimer, 0, UpdateCompoundTime)
	//ZawaEffect()
	//timer.Simple(2, function() CardChoiceGUI(true) end)
end)

function GM:HUDPaint()
	localplayer = localplayer and IsValid(localplayer) and localplayer or LocalPlayer()
    if not IsValid(localplayer) then return end

    DrawInfo()
    DrawEntityDisplay()
end

net.Receive("TableSetPhase", function()
	local phaseDelay = net.ReadUInt(5)
	local timeLeft = phaseDelay
	local frame = vgui.Create("DFrame")
	frame:SetSize(500, 500)
	frame:SetPos(width / 2, height / 6)
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)
	frame:SetTitle("")
	frame.Paint = function(self, w, h)
		draw.SimpleTextOutlined(tostring(timeLeft), "CardText", 0, 0, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(255, 255, 255))
	end

	/*local text = vgui.Create("DLabel", frame)
	text:SetFont("CardText")
	text:SetText(tostring(phaseDelay))
	text:SetColor(Color(255, 0, 0))
	text:SetSize(500, 500)*/

	timer.Create("LowerTime", 1, phaseDelay, function()
		timeLeft = timeLeft - 1
		//text:SetText(tostring(timeLeft))
		if timeLeft <= 0 then
			frame:Close()
			timer.Destroy("LowerTime")
		end
	end)
end)