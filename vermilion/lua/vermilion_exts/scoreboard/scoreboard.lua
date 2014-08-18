--[[
 Copyright 2014 Ned Hyett

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 in compliance with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License
 is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 or implied. See the License for the specific language governing permissions and limitations under
 the License.
 
 The right to upload this project to the Steam Workshop (which is operated by Valve Corporation) 
 is reserved by the original copyright holder, regardless of any modifications made to the code,
 resources or related content. The original copyright holder is not affiliated with Valve Corporation
 in any way, nor claims to be so. 
]]

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Scoreboard"
EXTENSION.ID = "scoreboard"
EXTENSION.Description = "Replaces the default scoreboard with something that can interact with Vermilion."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}
EXTENSION.NetworkStrings = {
	"VScoreboardOpened",
	"VScoreboardDescUpdate",
	"VScoreboardPlayersUpdate",
	"VScoreboardCommand"
}

EXTENSION.BaseDescText = "Active Players: %players%/%maxplayers%       Gamemode: %gamemode%       Map: %map%"

function EXTENSION:InitServer()
	-- stop suicides taking away from the frags count and add them to deaths instead.
	local pMeta = FindMetaTable("Player")
	pMeta.Vermilion_AddFrags = pMeta.AddFrags
	function pMeta:AddFrags(num)
		if(num < 0) then 
			self:AddDeaths(num * -1)
			return
		end
		self:Vermilion_AddFrags(num)
	end

	function EXTENSION:SendDescUpdate(vplayer)
		net.Start("VScoreboardDescUpdate")
		local repls = {
			["%players%"] = table.Count(player.GetAll()),
			["%maxplayers%"] = game.MaxPlayers(),
			["%gamemode%"] = string.SetChar(engine.ActiveGamemode(), 1, string.upper(string.GetChar(engine.ActiveGamemode(), 1))),
			["%map%"] = game.GetMap()
		}
		local str = EXTENSION.BaseDescText
		for i,k in pairs(repls) do
			str = string.Replace(str, i, tostring(k))
		end
		net.WriteString(str)
		net.Send(vplayer)
	end
	
	function EXTENSION:UpdatePlayers(vplayer)
		net.Start("VScoreboardPlayersUpdate")
		local gdata = {}
		for i,k in pairs(player.GetAll()) do
			local kdrtext = tostring(k:Frags()) .. ":" .. tostring(k:Deaths()) .. " ("
			if(k:Frags() > k:Deaths()) then
				local kdr = (k:Frags() / (k:Frags() + k:Deaths())) * 100
				kdrtext = kdrtext .. tostring(math.Round(kdr, 1)) .. "%)"
			elseif(k:Deaths() > k:Frags()) then
				local kdr = (k:Deaths() / (k:Deaths() + k:Frags())) * 100
				kdrtext = kdrtext .. "-" ..tostring(math.Round(kdr, 1)) .. "%)"
			else
				kdrtext = kdrtext .. "0%)"
			end
			local data = {
				Name = k:GetName(),
				SteamID = k:SteamID(),
				KDR = kdrtext,
				Rank = string.SetChar(Vermilion:GetUser(k):GetRank().Name, 1, string.upper(string.GetChar(Vermilion:GetUser(k):GetRank().Name, 1))),
				TimeConnected = 0
			}
			table.insert(gdata, data)
		end
		net.WriteTable(gdata)
		net.Send(vplayer)
	end
	
	self:NetHook("VScoreboardOpened", function(vplayer)
		EXTENSION:SendDescUpdate(vplayer)
		EXTENSION:UpdatePlayers(vplayer)
	end)
	
	self:AddHook("PlayerInitialSpawn", function(vplayer)
		EXTENSION:SendDescUpdate(player.GetAll())
		EXTENSION:UpdatePlayers(player.GetAll())
	end)
	
	self:AddHook("PlayerDisconnected", function(vplayer)
		EXTENSION:SendDescUpdate(player.GetAll())
		EXTENSION:UpdatePlayers(player.GetAll())
	end)
	
	self:NetHook("VScoreboardCommand", function(vplayer)
		local command = net.ReadString()
		if(command == "kill") then
			if(Vermilion:HasPermission(vplayer, "punishment")) then
				local tplayer = net.ReadEntity()
				if(IsValid(tplayer)) then
					tplayer:Kill()
				end
			end
		end
	end)
end

function EXTENSION:InitClient()
	CreateClientConVar("Vermilion_Scoreboard", 1, true, false)
	CreateClientConVar("vermilion_show_sb_bg", 0, true, false)

	surface.CreateFont( "ScoreBoardTitle", {
		font = "Roboto",
		size = 56,
		weight = 500,
		antialias = true
	})
	surface.CreateFont("ScoreBoardSub", {
		font = "Roboto",
		size = 23,
		weight = 500,
		antialias = true
	})
	surface.CreateFont("ScoreBoardSub2", {
		font = "Roboto",
		size = 18,
		weight = 500,
		antialias = true
	})

	
	
	self:NetHook("VScoreboardDescUpdate", function()
		if(IsValid(EXTENSION.DescriptionLabel)) then
			EXTENSION.BaseDescText = net.ReadString()
			EXTENSION.DescriptionLabel:SetText(EXTENSION.BaseDescText)
			EXTENSION.DescriptionLabel:SizeToContents()
		end
	end)
	
	self:NetHook("VScoreboardPlayersUpdate", function()
		if(not IsValid(EXTENSION.PlayerList)) then return end
		local gdata = net.ReadTable()
		EXTENSION.PlayerList:Clear()
		for i,k in pairs(gdata) do
			local vplayer = Crimson.LookupPlayerBySteamID(k.SteamID)
			if(not IsValid(vplayer)) then vplayer = Crimson.LookupPlayerByName(k.Name) end
			if(IsValid(vplayer)) then
				local ln = EXTENSION.PlayerList:AddLine(vplayer:GetName(), k.SteamID, k.KDR, vplayer:Ping(), k.Rank, k.TimeConnected)
				
				for i1,k1 in pairs(ln.Columns) do
					k1:SetContentAlignment(5)
				end
				
				ln.OnRightClick = function()
					local conmenu = DermaMenu()
					conmenu:SetParent(ln)
					
					local adminmenu = conmenu:AddSubMenu("Administrate")
					adminmenu:AddOption("Ban", function()
						local bans = Vermilion:GetExtension("bans")
						if(bans != nil) then
							bans:CreateBanForPanel(k.SteamID)
						end
					end)
					adminmenu:AddOption("Kick", function()
						if(Vermilion:GetExtension("bans") != nil) then
							net.Start("VKickPlayer")
							net.WriteString(vplayer:SteamID())
							net.WriteString("Kicked from Scoreboard")
							net.SendToServer()
						end
					end)
					adminmenu:AddOption("Kill", function()
						net.Start("VScoreboardCommand")
						net.WriteString("kill")
						net.WriteEntity(vplayer)
						net.SendToServer()
					end)
					adminmenu:AddOption("Give")
					
					local rankmenu = adminmenu:AddSubMenu("Set Rank")
					
					
					adminmenu:AddOption("Set Health")
					adminmenu:AddOption("Set Armour")
					adminmenu:AddOption("Sudo")
					
					local lockmenu = adminmenu:AddSubMenu("Lock/Unlock")
					lockmenu:AddOption("Lock")
					lockmenu:AddOption("Unlock")
					
					adminmenu:AddOption("Reset KDR")
					
					local ppmenu = conmenu:AddSubMenu("Prop protection")
					local ppcmenu = ppmenu:AddSubMenu("Clear (admin only)")
					ppcmenu:AddOption("Clear All")
					ppcmenu:AddOption("Clear Props")
					ppcmenu:AddOption("Clear SENTs")
					ppcmenu:AddOption("Clear SWEPs")
					ppcmenu:AddOption("Clear Vehicles")
					ppcmenu:AddOption("Clear Ragdolls")
					ppcmenu:AddOption("Clear Effects")
					ppcmenu:AddOption("Clear NPCs")
					ppmenu:AddOption("Request access to props")
					
					conmenu:AddOption("Private Message")
					conmenu:AddOption("Open Steam Profile", function()
						if(IsValid(vplayer)) then vplayer:ShowProfile() end
					end)
					conmenu:AddOption("Open Vermilion Profile")
					
					conmenu:Open()
				end
			end
		end
	end)
	
	self:AddHook("HUDDrawScoreBoard", function()
		if(GetConVarNumber("Vermilion_Scoreboard") == 1) then
			return true
		end
	end)
	
	self:AddHook("ScoreboardShow", function()
		if(GetConVarNumber("Vermilion_Scoreboard") != 1) then return end
		gui.EnableScreenClicker(true)
		local sbPanel = vgui.Create("DPanel")
		EXTENSION.ScoreBoardPanel = sbPanel
		sbPanel:SetDrawBackground(GetConVarNumber("vermilion_show_sb_bg") == 1)
		sbPanel:SetPos(100, 100)
		sbPanel:SetSize(ScrW() - 200, ScrH() - 200)
		
		local serverNameLabel = vgui.Create("DLabel")
		serverNameLabel:SetPos(0, 0)
		serverNameLabel:SetText(GetHostName())
		serverNameLabel:SetFont("ScoreBoardTitle")
		serverNameLabel:SizeToContents()
		serverNameLabel:SetTextColor(Color(255, 255, 255))
		serverNameLabel:SetParent(sbPanel)
		
		local shortMOTDLabel = vgui.Create("DLabel")
		shortMOTDLabel:SetPos(0, serverNameLabel:GetTall() + 5)
		shortMOTDLabel:SetText("Placeholder")
		shortMOTDLabel:SetFont("ScoreBoardSub")
		shortMOTDLabel:SizeToContents()
		shortMOTDLabel:SetTextColor(Color(255, 255, 255))
		shortMOTDLabel:SetParent(sbPanel)
		
		local descriptionLabel = vgui.Create("DLabel")
		descriptionLabel:SetPos(0, select(2, shortMOTDLabel:GetPos()) + shortMOTDLabel:GetTall() + 5)
		descriptionLabel:SetText(EXTENSION.BaseDescText)
		descriptionLabel:SetFont("ScoreBoardSub2")
		descriptionLabel:SizeToContents()
		descriptionLabel:SetTextColor(Color(255, 255, 255))
		descriptionLabel:SetParent(sbPanel)
		
		EXTENSION.DescriptionLabel = descriptionLabel
		
		local playerList = Crimson.CreateList({"Name", "SteamID", "KDR", "Ping", "Rank", "Time Connected"})
		playerList:SetPos(0, select(2, descriptionLabel:GetPos()) + descriptionLabel:GetTall() + 35)
		playerList:SetSize(sbPanel:GetWide(), sbPanel:GetTall() - select(2, playerList:GetPos()))
		playerList:SetParent(sbPanel)
		playerList:SetDrawBackground(false)
		
		EXTENSION.PlayerList = playerList
		
		net.Start("VScoreboardOpened")
		net.SendToServer()
		
		timer.Create("Vermilion_Scoreboard_Refresh", 2, 0, function()
			if(not IsValid(playerList)) then return end
			for i,k in pairs(playerList:GetLines()) do
				local tplayer = Crimson.LookupPlayerBySteamID(k:GetValue(2))
				if(IsValid(tplayer) and not tplayer:IsBot()) then
					k:SetValue(4, tplayer:Ping())
				end
			end
		end)
		
		return false
	end)
	
	self:AddHook("ScoreboardHide", function()
		if(GetConVarNumber("Vermilion_Scoreboard") != 1) then return end
		EXTENSION.ScoreBoardPanel:Remove()
		gui.EnableScreenClicker(false)
		timer.Destroy("Vermilion_Scoreboard_Refresh")
		return false
	end)
end

Vermilion:RegisterExtension(EXTENSION)