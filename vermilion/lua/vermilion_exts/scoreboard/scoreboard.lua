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
	"manage_scoreboard",
	"karma_vote"
}
EXTENSION.NetworkStrings = {
	"VScoreboardOpened",
	"VScoreboardDescUpdate",
	"VScoreboardPlayersUpdate",
	"VScoreboardCommand",
	"VCheckScoreboardActive",
	"VScoreboardUpdateRequest"
}

EXTENSION.BaseDescText = "Active Players: %players%/%maxplayers%       Gamemode: %gamemode%       Map: %map%"

EXTENSION.DataTypes = {}

function EXTENSION:AddDataType(name, obtainer, drawer, mandatory)
	mandatory = mandatory or false
	self.DataTypes[name] = { Obtainer = obtainer, Drawer = drawer, IsMandatory = mandatory }
end

function EXTENSION:InitShared()
	self:AddDataType("Name", function(vplayer, requester)
		return vplayer:GetName()
	end, false, true)
	
	self:AddDataType("SteamID", function(vplayer, requester)
		return vplayer:SteamID()
	end, false)
	
	self:AddDataType("KDR", function(vplayer, requester)
		local kdrtext = tostring(vplayer:Frags()) .. ":" .. tostring(vplayer:Deaths()) .. " ("
		if(vplayer:Frags() > vplayer:Deaths()) then
			local kdr = (vplayer:Frags() / (vplayer:Frags() + vplayer:Deaths())) * 100
			kdrtext = kdrtext .. tostring(math.Round(kdr, 1)) .. "%)"
		elseif(vplayer:Deaths() > vplayer:Frags()) then
			local kdr = (vplayer:Deaths() / (vplayer:Deaths() + vplayer:Frags())) * 100
			kdrtext = kdrtext .. "-" ..tostring(math.Round(kdr, 1)) .. "%)"
		else
			kdrtext = kdrtext .. "0%)"
		end
		return kdrtext
	end, false)
	
	self:AddDataType("Rank", function(vplayer, requester)
		return string.SetChar(Vermilion:GetUser(vplayer):GetRank().Name, 1, string.upper(string.GetChar(Vermilion:GetUser(vplayer):GetRank().Name, 1)))
	end, false)
	
	self:AddDataType("Time Connected", function(vplayer, requester)
		return vplayer:TimeConnected()
	end, false)
	
	--[[self:AddDataType("Karma", function(vplayer, requester)
		return Vermilion:GetKarmaRating(vplayer)
	end, function(cell, data)
		--if(data == 1) then
			local image1 = vgui.Create("DImage")
			image1:SetImage("icon16/star.png")
			image1:SizeToContents()
			local cx, cy = cell:GetSize()
			image1:SetPos((cx - image1:GetWide()) / 2, (cy - image1:GetTall()) / 2)
			image1:SetParent(cell)
		--end
	end)]]--
	
	self:AddDataType("Karma", function(vplayer, requester)
		return tostring(Vermilion:GetKarmaRating(vplayer)) .. " / 5"
	end, false)
	
	self:AddDataType("Ping", function(vplayer, requester)
		return vplayer:Ping()
	end, false)
end

function EXTENSION:InitServer()
	concommand.Add("toggle_scoreboard", function(vplayer, cmd, args, str)
		if(Vermilion:HasPermission(vplayer, "manage_scoreboard")) then
			if(table.Count(args) < 1) then return end
			if(tobool(args[1])) then
				EXTENSION:SetData("scoreboard_enabled", true)
				Vermilion.Log("Scoreboard enabled!")
			else
				EXTENSION:SetData("scoreboard_enabled", false)
				Vermilion.Log("Scoreboard disabled!")
			end
		end
	end)
	
	self:AddDataChangeHook("scoreboard_enabled", "update_scoreboard", function(val)
		net.Start("VCheckScoreboardActive")
		net.WriteBoolean(val)
		net.Broadcast()
	end)
	
	-- stop suicides taking away from the frags count and add them to deaths instead.
	local pMeta = FindMetaTable("Player")
	if(pMeta.Vermilion_AddFrags == nil) then
		pMeta.Vermilion_AddFrags = pMeta.AddFrags
		function pMeta:AddFrags(num)
			if(num < 0) then 
				self:AddDeaths(num * -1)
				return
			end
			self:Vermilion_AddFrags(num)
		end
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
		local dataTypes = net.ReadTable()
		
		local gdata = {}
		for i,tplayer in pairs(player.GetAll()) do
			local pData = {}
			for qrd,typ in pairs(dataTypes) do
				pData[typ] = EXTENSION.DataTypes[typ].Obtainer(tplayer, vplayer)
			end
			table.insert(gdata, { SteamID = tplayer:SteamID(), Data = pData })
		end
		
		net.WriteTable(gdata)
		net.Send(vplayer)
	end
	
	function EXTENSION:SendUpdatePlayersRequest(target)
		net.Start("VScoreboardUpdateRequest")
		net.Send(target)
	end
	
	self:NetHook("VScoreboardUpdateRequest", function(vplayer)
		EXTENSION:UpdatePlayers(vplayer)
	end)
	
	self:NetHook("VCheckScoreboardActive", function(vplayer)
		net.Start("VCheckScoreboardActive")
		net.WriteBoolean(EXTENSION:GetData("scoreboard_enabled", true, true))
		net.Send(vplayer)
	end)
	
	self:NetHook("VScoreboardOpened", function(vplayer)
		EXTENSION:SendDescUpdate(vplayer)
		EXTENSION:SendUpdatePlayersRequest(vplayer)
	end)
	
	self:AddHook("PlayerInitialSpawn", function(vplayer)
		EXTENSION:SendDescUpdate(player.GetAll())
		EXTENSION:SendUpdatePlayersRequest(player.GetAll())
	end)
	
	self:AddHook("PlayerDisconnected", function(vplayer)
		EXTENSION:SendDescUpdate(player.GetAll())
		EXTENSION:SendUpdatePlayersRequest(player.GetAll())
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
		elseif(command == "lock") then
			if(Vermilion:HasPermission(vplayer, "punishment")) then
				local tplayer = net.ReadEntity()
				if(IsValid(tplayer)) then
					tplayer:Lock()
				end
			end
		elseif(command == "unlock") then
			if(Vermilion:HasPermission(vplayer, "punishment")) then
				local tplayer = net.ReadEntity()
				if(IsValid(tplayer)) then
					tplayer:UnLock()
				end
			end
		elseif(command == "Karma") then
			if(Vermilion:HasPermission(vplayer, "karma_vote")) then
				local tplayer = net.ReadEntity()
				if(tplayer == vplayer) then return end -- can't vote on yourself.
				Vermilion:AddKarma(tplayer, vplayer, net.ReadBoolean())
			end
		end
	end)
end

function EXTENSION:InitClient()
	local enabled = true
	CreateClientConVar("vermilion_show_sb_bg", 0, true, false)
	
	self:NetHook("VCheckScoreboardActive", function()
		enabled = net.ReadBoolean()
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "FirstCheck", function()
		net.Start("VCheckScoreboardActive")
		net.SendToServer()
	end)
	
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
	
	local types = { "Name", "SteamID", "Rank", "KDR", "Ping", "Karma" }
	
	self:NetHook("VScoreboardUpdateRequest", function()
		net.Start("VScoreboardUpdateRequest")
		net.WriteTable(types)
		net.SendToServer()
	end)

	
	
	self:NetHook("VScoreboardDescUpdate", function()
		if(IsValid(EXTENSION.DescriptionLabel)) then
			EXTENSION.BaseDescText = net.ReadString()
			EXTENSION.DescriptionLabel:SetText(EXTENSION.BaseDescText)
			EXTENSION.DescriptionLabel:SizeToContents()
		end
	end)
	
	self:NetHook("VScoreboardPlayersUpdate", function()
		if(not Vermilion.ScoreboardOpened) then return end
		if(IsValid(EXTENSION.PlayerList)) then EXTENSION.PlayerList:Remove() end
		local playerList = Crimson.CreateList(types)
		if(not IsValid(playerList) or not IsValid(EXTENSION.DescriptionLabel) or not IsValid(EXTENSION.ScoreBoardPanel)) then return end
		if(IsValid(EXTENSION.LoadingPanel)) then EXTENSION.LoadingPanel:Remove() end
		playerList:SetPos(0, select(2, EXTENSION.DescriptionLabel:GetPos()) + EXTENSION.DescriptionLabel:GetTall() + 35)
		playerList:SetSize(EXTENSION.ScoreBoardPanel:GetWide(), EXTENSION.ScoreBoardPanel:GetTall() - select(2, playerList:GetPos()))
		playerList:SetParent(EXTENSION.ScoreBoardPanel)
		playerList:SetDrawBackground(false)
		
		EXTENSION.PlayerList = playerList
		
		local gdata = net.ReadTable()
		playerList:Clear()
		for i,k in pairs(gdata) do
			local pdatag = k.Data
			local vplayer = Crimson.LookupPlayerBySteamID(k.SteamID)
			if(not IsValid(vplayer)) then vplayer = Crimson.LookupPlayerByName(pdatag.Name) end
			if(IsValid(vplayer)) then
				
				--local ln = EXTENSION.PlayerList:AddLine(vplayer:GetName(), k.SteamID, k.KDR, vplayer:Ping(), k.Rank, k.TimeConnected)
				local vri = 1
				local lndat = {}
				for iad,dfr in pairs(types) do
					lndat[vri] = pdatag[dfr]
					vri = vri + 1
				end
				local ln = playerList:AddLine()
				
				local avatar = Crimson.CreateAvatarImage(k.SteamID, 16)
				ln:Add(avatar)
				
				for indr,dfr in pairs(lndat) do
					ln:SetValue(indr, dfr)
				end
				
				
				for i1,k1 in pairs(ln.Columns) do
					k1:SetContentAlignment(5)
					local drawer = EXTENSION.DataTypes[types[i1]].Drawer
					if(isfunction(drawer)) then
						local oldDraw = k1.Draw
						k1.Draw = function(self)
							oldDraw()
							drawer(lndat[i1], k1)
						end
					end
				end
				
				ln.OnRightClick = function()
					local conmenu = DermaMenu()
					conmenu:SetParent(ln)
					if(LocalPlayer():IsAdmin()) then -- temp fix (the player will be able to click the buttons, but individual permissions will still be checked on the server).
						local adminmenu = conmenu:AddSubMenu("Administrate")
						adminmenu:AddOption("Ban", function()
							local bans = Vermilion:GetExtension("bans")
							if(bans != nil) then
								bans:CreateBanForPanel(k.SteamID)
							end
						end):SetIcon("icon16/delete.png")
						adminmenu:AddOption("Kick", function()
							if(Vermilion:GetExtension("bans") != nil) then
								net.Start("VKickPlayer")
								net.WriteBoolean(false)
								net.WriteString(k.SteamID)
								net.WriteString("Kicked from Scoreboard")
								net.SendToServer()
							end
						end):SetIcon("icon16/disconnect.png")
						adminmenu:AddOption("Kill", function()
							net.Start("VScoreboardCommand")
							net.WriteString("kill")
							net.WriteEntity(vplayer)
							net.SendToServer()
						end):SetIcon("icon16/gun.png")
						adminmenu:AddOption("Give", function()
							Derma_Message("Not implemented.", "Warning", "OK")
						end):SetIcon("icon16/add.png")
						
						local rankmenu = adminmenu:AddSubMenu("Set Rank")
						rankmenu:AddOption("NOT IMPLEMENTED")
						
						adminmenu:AddOption("Set Health", function()
							Derma_StringRequest("Enter Health Amount", "Enter a number to set the health of this player to.", "100", function(text)
								if(tonumber(text) == nil) then
									Derma_Message(text .. " is not a valid number!", "Invalid Input", "OK")
									return
								end
								net.Start("VScoreboardCommand")
								net.WriteString("sethealth")
								net.WriteEntity(vplayer)
								net.WriteString(text)
								net.SendToServer()
							end)
						end):SetIcon("icon16/heart.png")
						adminmenu:AddOption("Set Armour", function()
							Derma_Message("Not implemented.", "Warning", "OK")
						end):SetIcon("icon16/shield.png")
						adminmenu:AddOption("Sudo", function()
							Derma_Message("Not implemented.", "Warning", "OK")
						end):SetIcon("icon16/transmit_blue.png")
						
						local lockmenu = adminmenu:AddSubMenu("Lock/Unlock")
						lockmenu:AddOption("Lock", function()
							net.Start("VScoreboardCommand")
							net.WriteString("lock")
							net.WriteEntity(vplayer)
							net.SendToServer()
						end):SetIcon("icon16/lock.png")
						lockmenu:AddOption("Unlock", function()
							net.Start("VScoreboardCommand")
							net.WriteString("unlock")
							net.WriteEntity(vplayer)
							net.SendToServer()
						end):SetIcon("icon16/lock_open.png")
						
						adminmenu:AddOption("Reset KDR", function()
							Derma_Message("Not implemented.", "Warning", "OK")
						end):SetIcon("icon16/award_star_delete.png")
					end
					
					local ppmenu = conmenu:AddSubMenu("Prop protection")
					local ppcmenu = ppmenu:AddSubMenu("Clear (admin only)")
					ppcmenu:AddOption("Clear All"):SetIcon("icon16/world_delete.png")
					ppcmenu:AddOption("Clear Props"):SetIcon("icon16/application_view_tile.png")
					ppcmenu:AddOption("Clear SENTs"):SetIcon("icon16/bricks.png")
					ppcmenu:AddOption("Clear SWEPs"):SetIcon("icon16/gun.png")
					ppcmenu:AddOption("Clear Vehicles"):SetIcon("icon16/car.png")
					ppcmenu:AddOption("Clear Ragdolls"):SetIcon("icon16/user_suit.png")
					ppcmenu:AddOption("Clear Effects"):SetIcon("icon16/wand.png")
					ppcmenu:AddOption("Clear NPCs"):SetIcon("icon16/user_female.png")
					ppmenu:AddOption("Request access to props"):SetIcon("icon16/database_connect.png")
					
					local karmaMenu = conmenu:AddSubMenu("Karma")
					karmaMenu:AddOption("Positive", function()
						net.Start("VScoreboardCommand")
						net.WriteString("Karma")
						net.WriteEntity(vplayer)
						net.WriteBoolean(true)
						net.SendToServer()
					end):SetIcon("icon16/add.png")
					karmaMenu:AddOption("Negative", function()
						net.Start("VScoreboardCommand")
						net.WriteString("Karma")
						net.WriteEntity(vplayer)
						net.WriteBoolean(false)
						net.SendToServer()
					end):SetIcon("icon16/delete.png")
					
					conmenu:AddOption("Private Message"):SetIcon("icon16/user_comment.png")
					conmenu:AddOption("Open Steam Profile", function()
						if(IsValid(vplayer)) then vplayer:ShowProfile() end
					end):SetIcon("icon16/page_find.png")
					conmenu:AddOption("Open Vermilion Profile", function()
						if(Vermilion:GetExtension("profiles") != nil) then
							Vermilion:GetExtension("profiles"):OpenProfile(vplayer)
						end
					end):SetIcon("icon16/comment.png")
					
					conmenu:Open()
				end
			end
		end
	end)
	
	self:AddHook("HUDDrawScoreBoard", function()
		if(enabled) then
			return true
		end
	end)
	
	self:AddHook("ScoreboardShow", function()
		Vermilion.ScoreboardOpened = true
		if(not enabled) then return end
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
		
		local loadingPanel = vgui.Create("DPanel")
		loadingPanel:SetPos(0, select(2, EXTENSION.DescriptionLabel:GetPos()) + EXTENSION.DescriptionLabel:GetTall() + 35)
		loadingPanel:SetSize(EXTENSION.ScoreBoardPanel:GetWide(), EXTENSION.ScoreBoardPanel:GetTall() - select(2, loadingPanel:GetPos()))
		loadingPanel:SetParent(sbPanel)
		EXTENSION.LoadingPanel = loadingPanel
		
		local loadingLabel = Crimson.CreateLabel("Loading Data From Server...")
		loadingLabel:SetFont("ScoreBoardTitle")
		loadingLabel:SetTextColor(Vermilion.Colours.Black)
		loadingLabel:SizeToContents()
		local lpx, lpy = loadingPanel:GetSize()
		loadingLabel:SetPos((lpx - loadingLabel:GetWide()) / 2, (lpy - loadingLabel:GetTall()) / 2)
		loadingLabel:SetParent(loadingPanel)
		
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
		Vermilion.ScoreboardOpened = false
		if(not enabled) then return end
		EXTENSION.ScoreBoardPanel:Remove()
		EXTENSION.ScoreBoardPanel = nil
		gui.EnableScreenClicker(false)
		timer.Destroy("Vermilion_Scoreboard_Refresh")
		return false
	end)
end

Vermilion:RegisterExtension(EXTENSION)