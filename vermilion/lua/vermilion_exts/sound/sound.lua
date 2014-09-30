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

-- Todo: set up the system so the server keeps track of where the sound is, and to play it to clients when they join.

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Sound Controls"
EXTENSION.ID = "sound"
EXTENSION.Description = "Plays sounds and stuff"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"playsound",
	"stopsound",
	"use_vox_announcer"
}
EXTENSION.PermissionDefinitions = {
	["playsound"] = "This player is allowed to play sounds to other players and can see the Sound tab in the Vermilion Menu and modify the settings within.",
	["stopsound"] = "This player is allowed to stop other sounds.",
	["use_vox_announcer"] = "This player is allowed to use the vox and voxcount commands in the chat."
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"playsound",
			"stopsound"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VPlaySound",
	"VStopSound",
	"VPlaySoundStream",
	"VBeginStream",
	"VListSounds",
	"VBroadcastSound",
	"VBroadcastStream",
	"VSCGetPlaylist",
	"VSCGetAllPlaylists",
	"VSCSetPlaylist",
	"VSCNewPlaylist",
	"VSCDeletePlaylist",
	"VSCPlayPlaylist",
	"VSCAddToPlaylist",
	"VSCGetPlaylistContent",
	"VSCRemoveFromPlaylist",
	"VSCMoveTrack",
	"VMusicCredits",
	"VPlayEquation"
}



EXTENSION.ActiveSound = {}

EXTENSION.ActivePlaylist = nil
EXTENSION.PlayListIndex = 1
EXTENSION.IsPlayingPlaylist = false
EXTENSION.Credits = nil
EXTENSION.CreditW = 0
EXTENSION.CreditH = 0

EXTENSION.Nodes = {}

local errs = {
	["0"] = "BASS_OK",
	["1"] = "BASS_ERROR_MEM",
	["2"] = "BASS_ERROR_FILEOPEN",
	["3"] = "BASS_ERROR_DRIVER",
	["4"] = "BASS_ERROR_BUFLOST",
	["5"] = "BASS_ERROR_HANDLE",
	["6"] = "BASS_ERROR_FORMAT",
	["7"] = "BASS_ERROR_POSITION",
	["8"] = "BASS_ERROR_INIT",
	["9"] = "BASS_ERROR_START",
	["14"] = "BASS_ERROR_ALREADY",
	["18"] = "BASS_ERROR_NOCHAN",
	["19"] = "BASS_ERROR_ILLTYPE",
	["20"] = "BASS_ERROR_ILLPARAM",
	["21"] = "BASS_ERROR_NO3D",
	["22"] = "BASS_ERROR_NOEAX",
	["23"] = "BASS_ERROR_DEVICE",
	["24"] = "BASS_ERROR_NOPLAY",
	["25"] = "BASS_ERROR_FREQ",
	["27"] = "BASS_ERROR_NOTFILE",
	["29"] = "BASS_ERROR_NOHW",
	["31"] = "BASS_ERROR_EMPTY",
	["32"] = "BASS_ERROR_NONET",
	["33"] = "BASS_ERROR_CREATE",
	["34"] = "BASS_ERROR_NOFX",
	["37"] = "BASS_ERROR_NOTAVAIL",
	["38"] = "BASS_ERROR_DECODE",
	["39"] = "BASS_ERROR_DX",
	["40"] = "BASS_ERROR_TIMEOUT",
	["41"] = "BASS_ERROR_FILEFORM",
	["42"] = "BASS_ERROR_SPEAKER",
	["43"] = "BASS_ERROR_VERSION",
	["44"] = "BASS_ERROR_CODEC",
	["45"] = "BASS_ERROR_ENDED",
	["46"] = "BASS_ERROR_BUSY",
	["-1"] = "BASS_ERROR_UNKNOWN"
}

function EXTENSION:InitServer()
	
	--[[
		Utility functions
	]]--

	function Vermilion:PlaySound(vplayer, path, channel, loop, volume)
		channel = channel or "BaseSound"
		loop = loop or false
		volume = volume or 100
		net.Start("VPlaySound")
		net.WriteString(path)
		net.WriteString("BaseSound")
		net.WriteBoolean(loop)
		net.WriteString(tostring(volume))
		EXTENSION.ActiveSound[channel] = { Path = path, Stream = false, Loop = loop, Volume = volume, Position = 0 }
		net.Send(vplayer)
	end
	
	function Vermilion:PlayStream(vplayer, stream, channel, loop, volume, max)
		channel = channel or "BaseSound"
		loop = loop or false
		volume = volume or 100
		max = max or 1
		net.Start("VPlaySoundStream")
		net.WriteString(stream)
		net.WriteString(channel)
		net.WriteBoolean(loop)
		net.WriteString(tostring(volume))
		EXTENSION.ActiveSound[channel] = { Path = stream, Stream = true, Loop = loop, volume = volume, Position = 0, ReportedPlayers = {}, MaxPlayers = max }
		net.Send(vplayer)
	end

	function Vermilion:BroadcastSound(path, channel, loop, volume)
		for i,vplayer in pairs(player.GetHumans()) do
			self:PlaySound(vplayer, path, channel, loop, volume)
		end
	end
	
	function Vermilion:BroadcastStream(stream, channel, loop, volume)
		for i,vplayer in pairs(player.GetHumans()) do
			self:PlayStream(vplayer, stream, channel, loop, volume, table.Count(player.GetHumans()))
		end
	end
	
	--[[
		Chat commands
	]]--
	
	--[[ Vermilion:AddChatCommand("playequation", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "playsound", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !playequation <equation>", VERMILION_NOTIFY_ERROR)
				return
			end
			net.Start("VPlayEquation")
			net.WriteString(text[1])
			net.Broadcast()
		end
	end, "<equation>") ]]
	
	Vermilion:AddChatCommand("playsound", function(sender, text)
		local targetplayer = -1
		local loop = false
		local filename = -1
		local streamfile = -1
		local volume = -1
		for i,k in pairs(text) do
			if(k == "-targetplayer") then targetplayer = i + 1 end
			if(k == "-loop") then loop = true end
			if(k == "-file") then filename = i + 1 end
			if(k == "-stream") then streamfile = i + 1 end
			if(k == "-vol") then volume = i + 1 end
		end
		if(volume == -1) then
			volume = 100 
		else
			volume = tonumber(text[volume])
		end
		if(filename == -1 and streamfile == -1) then
			Vermilion:SendNotify(sender, "Must specify -file or -stream option!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(targetplayer > -1) then
			local targetPlayer = Crimson.LookupPlayerByName(text[targetplayer])
			if(targetPlayer != nil) then
				Vermilion:SendNotify(sender, "Playing " .. text[streamfile] .. " to " .. text[targetplayer], 10, VERMILION_NOTIFY_ERROR)
				if(streamfile == -1) then
					Vermilion:PlaySound(targetPlayer, text[filename], "BaseSound", loop, volume)
				else
					Vermilion:PlayStream(targetPlayer, text[streamfile], "BaseSound", loop, volume)
				end
			else
				Vermilion:SendNotify(sender, "Invalid target!", 10, VERMILION_NOTIFY_ERROR)
			end
			return
		end
		if(streamfile == -1) then 
			Vermilion:BroadcastSound(text[filename], "BaseSound", loop, volume)
		else
			Vermilion:BroadcastStream(text[streamfile], "BaseSound", loop, volume)
		end
	end, "[-stream <url>] [-file <path>] [-vol <number 0-100>] [-loop] [-targetplayer <player>]")
	
	Vermilion:AddChatPredictor("playsound", function(pos, current, all)
		if(pos % 2 != 0) then
			local tab = {
				"-stream",
				"-file",
				"-vol",
				"-loop",
				"-targetplayer"
			}
			local rtab = {}
			for i,k in pairs(tab) do
				local has = false
				for i1,k1 in pairs(all) do
					if(k == k1) then
						has = true
						break
					end
				end
				if(not has and string.StartWith(k, current)) then
					table.insert(rtab, k)
				end
			end
			return rtab
		end
		if(pos - 1 > 0) then
			if(all[pos -1] == "-targetplayer") then
				local tab = {}
				for i,k in pairs(player.GetAll()) do
					if(string.StartWith(k:GetName(), current)) then
						table.insert(tab, k:GetName())
					end
				end
				return tab
			end
		end
	end)
	
	Vermilion:AddChatCommand("stopsound", function(sender, text)
		if(text[1] == "-targetplayer") then
			local targetPlayer = Crimson.LookupPlayerByName(text[2])
			if(targetPlayer != nil) then
				Vermilion:SendNotify(sender, "Stopping sound for " .. text[2], 10)
				net.Start("VStopSound")
				net.WriteString("BaseSound")
				net.Send(targetPlayer)
			else
				Vermilion:SendNotify(sender, "Invalid target!", 10, VERMILION_NOTIFY_ERROR)
				return
			end
		end
		net.Start("VStopSound")
		net.WriteString("BaseSound")
		net.Broadcast()
	end, "[-targetplayer <player>]")
	
	--[[
		Network hooks
	]]--
	
	--[[
		Lists all sounds that the server has mounted.
	]]--
	self:NetHook("VListSounds", function(vplayer)
		net.Start("VListSounds")
		local basePth = net.ReadString()
		print("listing sounds in sound" .. basePth)
		local endSlsht = ""
		if(not string.EndsWith(basePth, "/")) then
			endSlsht = "/"
		end
		local a,b = file.Find("sound" .. basePth .. endSlsht .. "*", "GAME")
		net.WriteTable(a)
		net.WriteTable(b)
		net.WriteString(basePth)
		net.Send(vplayer)
	end)
	
	--[[
		Receives a request from the client to play a sound file.
	]]--
	self:NetHook("VBroadcastSound", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "playsound")) then
			Vermilion:BroadcastSound(net.ReadString(), net.ReadString(), tobool(net.ReadString()), tonumber(net.ReadString()))
		end
	end)
	
	--[[
		Receives a request from the client to play a stream.
	]]--	
	self:NetHook("VBroadcastStream", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "playsound")) then
			net.Start("VPlaySoundStream")
			local filename = net.ReadString()
			local volume = tonumber(net.ReadString())
			local loop = net.ReadBoolean()
			local credits = nil
			if(net.ReadBoolean()) then
				credits = net.ReadString()
			end
			Vermilion:BroadcastStream(filename, "BaseSound", loop, volume)
			if(credits != nil) then
				net.Start("VMusicCredits")
				net.WriteString(credits)
				net.Broadcast()
			end
		end
	end)
	
	--[[
		Collects reports from connected clients that they were able to connect to the stream. When all clients have reported a success, begin the stream.
		
		Note: this might break if a player joins while clients are trying to load a stream.
	]]--
	self:NetHook("VBeginStream", function(vplayer)
		local channel = string.Trim(net.ReadString())
		if(not table.HasValue(EXTENSION.ActiveSound[channel].ReportedPlayers, vplayer:GetName())) then
			table.insert(EXTENSION.ActiveSound[channel].ReportedPlayers, vplayer:GetName())
		end
		local hasAllNames = true
		for i,k in pairs(player.GetHumans()) do
			if(not table.HasValue(EXTENSION.ActiveSound[channel].ReportedPlayers, k:GetName())) then
				hasAllNames = false
				break
			end
		end
		if(table.Count(EXTENSION.ActiveSound[channel].ReportedPlayers) == EXTENSION.ActiveSound[channel].MaxPlayers) then hasAllNames = true end
		if(hasAllNames) then
			net.Start("VBeginStream")
			net.WriteString(channel)
			net.Broadcast()
		end
	end)
	
	--[[
		Misc
	]]--
	
	include("vermilion_exts/sound/vox.lua")
	include("vermilion_exts/sound/soundcloud.lua")
	
	self:SoundCloudInitServer()
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("sound", "playsound")
	end)
end

function EXTENSION:InitClient()
	CreateClientConVar("vermilion_fft", 1, true, false)
	CreateClientConVar("vermilion_fft_type", 1, true, false)
	
	include("vermilion_exts/sound/soundcloud.lua")
	EXTENSION:SoundCloudInitClient()
	
	function Vermilion:PlaySound(path, index)
		index = index or "BaseSound"
		if(EXTENSION.ActiveSound[index] != nil) then
			EXTENSION.ActiveSound[index]:Stop()
		end
		local typ = "noplay"
		if(loop) then
			typ = typ .. " noblock"
		end
		sound.PlayFile("sound/" .. path, typ, function(station, errorID)
			if(IsValid(station)) then
				station:EnableLooping(loop)
				station:Play()
				EXTENSION.ActiveSound[index] = station
			else
				print(errs[tostring(errorID)])
			end
		end)
	end
	
	function EXTENSION:PlayStream(stream, index, loop, volume, fcallback)
		if(EXTENSION.ActiveSound[index] != nil) then EXTENSION.ActiveSound[index]:Stop() end
		local typ = "noplay"
		if(loop) then typ = typ .. " noblock" end
		sound.PlayURL(stream, typ, function(station, errorID, errName)
			if(IsValid(station)) then
				station:EnableLooping(loop)
				station:SetVolume(volume)
				EXTENSION.ActiveSound[index] = station
				net.Start("VBeginStream")
				net.WriteString(index)
				net.SendToServer()
			else
				fcallback(errs[tostring(errorID)])
			end
		end)
	end
	
	self:NetHook("VPlayEquation", function()
		local equation = net.ReadString()
		equation = string.Replace(equation, "%dat%", "Vermilion.SoundData")
		local equfunc = CompileString(equation)
		local val = math.Rand(0, 1000000)
		sound.Generate("gen" .. tostring(val), 44100, 5, function(t)
			Vermilion.SoundData = t
			equfunc()
		end)
		surface.PlaySound("gen" .. tostring(val))
	end)
	
	self:NetHook("VMusicCredits", function()
		EXTENSION.Credits = string.Explode("\n", net.ReadString())
		timer.Simple(10, function()
			EXTENSION.Credits = nil
		end)
	end)

	self:NetHook("VListSounds", function()
		local ftab = net.ReadTable()
		local dtab = net.ReadTable()
		local path = net.ReadString()
		local tnode = EXTENSION.Nodes[path]
		for i,k in pairs(dtab) do
			local nnode = tnode:AddNode(k)
			EXTENSION.Nodes[path .. "/" .. k] = nnode
			nnode.Expander.DoClick = function()
				nnode:SetExpanded( !nnode.m_bExpanded )
				if(nnode.m_bExpanded and not nnode:HasChildren()) then
					net.Start("VListSounds")
					net.WriteString(path .. "/" .. k)
					net.SendToServer()					
				end
			end
			nnode:SetForceShowExpander(true)
		end
		for i,k in pairs(ftab) do
			local nnode = tnode:AddNode(k)
			EXTENSION.Nodes[path .. "/" .. k] = nnode
			nnode:SetIcon("icon16/page.png")
		end
	end)
	
	
	self:NetHook("VBeginStream", function()
		local channel = net.ReadString()
		if(IsValid(EXTENSION.ActiveSound[channel])) then
			EXTENSION.ActiveSound[channel]:Play()
		end
	end)
	
	self:NetHook("VPlaySound", function()
		local path = net.ReadString()
		local index = net.ReadString()
		local loop = net.ReadBoolean()
		local volume = tonumber(net.ReadString()) / 100
		if(EXTENSION.ActiveSound[index] != nil) then
			EXTENSION.ActiveSound[index]:Stop()
		end
		local typ = "noplay"
		if(loop) then typ = typ .. " noblock" end
		sound.PlayFile("sound/" .. path, typ, function(station, errorID)
			if(IsValid(station)) then
				station:EnableLooping(loop)
				station:Play()
				station:SetVolume(volume)
				EXTENSION.ActiveSound[index] = station
			else
				print(errs[tostring(errorID)])
			end
		end)
	end)
	
	self:NetHook("VPlaySoundStream", function()
		local stream = net.ReadString()
		local index = net.ReadString()
		local loop = net.ReadBoolean()
		local volume = tonumber(net.ReadString()) / 100
		EXTENSION:PlayStream(stream, index, loop, volume, function(errid)
			if(errid == "BASS_ERROR_TIMEOUT") then
				LocalPlayer():ChatPrint("[Vermilion] Failed to load stream: Operation timed out! (1/3)")
				EXTENSION:PlayStream(stream, index, loop, volume, function(errid1)
					if(errid1 == "BASS_ERROR_TIMEOUT") then
						LocalPlayer():ChatPrint("[Vermilion] Failed to load stream: Operation timed out! (2/3)")
						EXTENSION:PlayStream(stream, index, loop, volume, function(errid2)
							if(errid1 == "BASS_ERROR_TIMEOUT") then
								LocalPlayer():ChatPrint("[Vermilion] Failed to load stream: Operation timed out! (3/3)")
								net.Start("VBeginStream")
								net.WriteString(index)
								net.SendToServer() -- lie to the server, we don't want to stop others from listening to the sound.
							end
						end)
					end
				end)
			end
		end)
	end)
	
	self:NetHook("VStopSound", function()
		local index = net.ReadString()
		if(EXTENSION.ActiveSound[index] != nil) then
			EXTENSION.ActiveSound[index]:Stop()
		end
	end)
	
	self:AddHook("VActivePlayers", function(tab)
		if(not IsValid(EXTENSION.ActivePlayersList)) then
			return
		end
		EXTENSION.ActivePlayersList:Clear()
		for i,k in pairs(tab) do
			local ln = EXTENSION.ActivePlayersList:AddLine( k[1], k[3] )
			ln.V_SteamID = k[2]
			ln.OnRightClick = function()
				local conmenu = DermaMenu()
				conmenu:SetParent(ln)
				conmenu:AddOption("Open Steam Profile", function()
					local tplayer = Crimson.LookupPlayerBySteamID(ln.V_SteamID)
					if(IsValid(tplayer)) then tplayer:ShowProfile() end
				end):SetIcon("icon16/page_find.png")
				conmenu:AddOption("Open Vermilion Profile", function()
					
				end):SetIcon("icon16/comment.png")
				conmenu:Open()
			end
		end
	end)
	
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("sound", "Sound", "sound.png", "Play a sound to everybody on the server or specific players", function(panel)
		
			local fileTree = vgui.Create("DTree")
			fileTree:SetPos(10, 30)
			fileTree:SetPadding(5)
			fileTree:SetSize(370, 505)
			fileTree:SetParent(panel)
			
			local soundBrowserLabel = Crimson:CreateHeaderLabel(fileTree, "Sound Browser")
			soundBrowserLabel:SetParent(panel)
			
			local rootNode = fileTree:AddNode("sound")
			EXTENSION.Nodes[""] = rootNode
			rootNode.Expander.DoClick = function()
				rootNode:SetExpanded( !rootNode.m_bExpanded )
				if(rootNode.m_bExpanded and not rootNode:HasChildren()) then
					net.Start("VListSounds")
					net.WriteString("")
					net.SendToServer()		
				end
			end
			rootNode:SetForceShowExpander(true)
		
			
			local volumeSlider = vgui.Create("DNumSlider")
			volumeSlider:SetPos(465, (panel:GetTall() / 2) + 40)
			volumeSlider:SetSize(320, 25)
			volumeSlider:SetMin(0)
			volumeSlider:SetMax(100)
			volumeSlider:SetDecimals(0)
			volumeSlider:SetValue(100)
			volumeSlider:SetDark(true)
			volumeSlider:SetParent(panel)
			
		
			local playerList = Crimson.CreateList({ "Name", "Rank" })
			playerList:SetParent(panel)
			playerList:SetPos(390, 30)
			playerList:SetSize(200, panel:GetTall() - 50)
			EXTENSION.ActivePlayersList = playerList

			local playerListLabel = Crimson:CreateHeaderLabel(playerList, "Active Players")
			playerListLabel:SetParent(panel)
			
			local soundCloudButton = Crimson.CreateButton("SoundCloud® Browser", function(self)
				EXTENSION:BuildSoundCloudBrowser()
			end)
			soundCloudButton:SetPos(600, (panel:GetTall() / 2) - 100)
			soundCloudButton:SetSize(170, 30)
			soundCloudButton:SetParent(panel)
			
			local playToAllButton = Crimson.CreateButton("Broadcast Sound", function(self)
				local selected = fileTree:GetSelectedItem()
				if(selected == nil or selected:HasChildren()) then
					Crimson:CreateErrorDialog("Must select a sound file to play!")
					return
				end
				for i,k in pairs(EXTENSION.Nodes) do
					if(k == selected) then
						net.Start("VBroadcastSound")
						net.WriteString(i) -- filename
						net.WriteString("BaseSound") -- channel
						net.WriteBoolean(false) -- loop
						net.WriteString(tostring(100)) -- volume
						net.SendToServer()
						break
					end
				end
			end)
			playToAllButton:SetPos(600, (panel:GetTall() / 2) - 40)			
			playToAllButton:SetSize(170, 30)
			playToAllButton:SetParent(panel)
		

		
			local playToSelectedButton = Crimson.CreateButton("Send To Selected", function(self)
				
			end)
			playToSelectedButton:SetPos(600, (panel:GetTall() / 2))
			playToSelectedButton:SetSize(170, 30)
			playToSelectedButton:SetParent(panel)
			
			
			
		end)
	end)
	
	self:AddHook("Think", "PlaylistThinker", function()
		if(EXTENSION.ActivePlaylist != nil and IsValid(EXTENSION.ActiveSound["BaseSound"])) then
			if(EXTENSION.ActiveSound["BaseSound"]:GetState() == 0 and EXTENSION.IsPlayingPlaylist) then
				if(EXTENSION.PlayListIndex >= table.Count(EXTENSION.ActivePlaylist)) then
					EXTENSION.ActivePlaylist = nil
					EXTENSION.PlayListIndex = 1
					EXTENSION.IsPlayingPlaylist = false
				else
					EXTENSION.ActiveSound["BaseSound"] = nil
					EXTENSION.PlayListIndex = EXTENSION.PlayListIndex + 1
					sound.PlayURL(EXTENSION.ActivePlaylist[EXTENSION.PlayListIndex].StreamURL .. "?client_id=" .. EXTENSION.SoundCloud.ClientID, "noplay", function(station, errorID, errName)
						if(IsValid(station)) then
							EXTENSION.Credits = string.Explode("\n", EXTENSION.ActivePlaylist[EXTENSION.PlayListIndex].Title .. "\n" .. EXTENSION.ActivePlaylist[EXTENSION.PlayListIndex].Uploader .. "\nStreamed from SoundCloud")
							timer.Simple(10, function()
								EXTENSION.Credits = nil
							end)
							station:Play()
							EXTENSION.IsPlayingPlaylist = true
							EXTENSION.ActiveSound["BaseSound"] = station
						else
							EXTENSION.ActivePlaylist = nil
							EXTENSION.PlayListIndex = 1
							EXTENSION.IsPlayingPlaylist = false
						end
					end)
				end
			end
		end
	end)
	
	self:AddHook("HUDPaint", "FFTDraw", function()
		if(EXTENSION.Credits != nil) then
			local pos = 0
			local maxw = 0
			for i,k in pairs(EXTENSION.Credits) do
				local w,h = draw.SimpleText(k, "Default", ScrW() - EXTENSION.CreditW - 20, ScrH() - EXTENSION.CreditH - 100 + pos, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				if(w > maxw) then maxw = w end
				pos = pos + h + 10
			end
			
			EXTENSION.CreditW = maxw
			EXTENSION.CreditH = pos
		end
		if(IsValid(EXTENSION.ActiveSound["BaseSound"]) and GetConVarNumber("vermilion_fft") == 1 and EXTENSION.ActiveSound["BaseSound"]:GetState() != 0) then
			local tab = {}
			local num = EXTENSION.ActiveSound["BaseSound"]:FFT(tab, FFT_256)
			local width = 5
			local spacing = 1
			
			if(num > 80) then num = 80 end -- limit to 80 channels
			local xpos = ScrW() - 10 - ((width + spacing) * num)
			local totalLen = xpos
			local ypos = ScrH() - 100
			local percent = (EXTENSION.ActiveSound["BaseSound"]:GetTime() / EXTENSION.ActiveSound["BaseSound"]:GetLength()) * num -- get the progress through the track as a percentage of the number of channels.
			if(GetConVarNumber("vermilion_fft_type") == 1) then
				for i,k in pairs(tab) do
					if(i > 80) then break end -- limit to 80 channels
					local colour = Color(255, 0, 0, 255)
					if(percent >= i) then colour = Color(0, 0, 255, 255) end -- draw the progress through the track
					draw.RoundedBox(2, xpos, ypos - ((k / 2) * (500 + (i * 8)) ), width, k * (500 + (i * 8)), colour)
					xpos = xpos + width + spacing
				end
			elseif(GetConVarNumber("vermilion_fft_type") == 2) then
				for i,k in pairs(tab) do
					if(i > 80) then break end -- limit to 80 channels.
					local colour = Color(255, 0, 0, 255)
					if(percent >= i) then colour = Color(0, 0, 255, 255) end
					surface.SetDrawColor(colour)
					if(table.Count(tab) < i + 1) then
						for yh = 3,-3,-1 do
							surface.DrawLine(xpos, (ypos + yh) - ((k /2) * (500 + (i * 8))), xpos + width + spacing, ypos + 1)
						end
					else
						for yh = 3,-3,-1 do
							local ryh = 1
							if(i % 2 == 0) then
								ryh = -1
							end
							local ryh2 = 1
							if((i + 1) % 2 == 0) then
								ryh2 = -1
							end
							surface.DrawLine(xpos, (ypos + yh) - (((k / 2) * (500 + (i * 8))) * ryh), xpos + width + spacing, (ypos + yh) - (((tab[i + 1] / 2) * (500 + ((i+1) * 8))) * ryh2))
						end
					end
					xpos = xpos + width + spacing
				end
			end
		end
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, function()
		if(Vermilion:GetExtension("dermainterface") != nil) then
			Vermilion:AddClientOption("Enable Sound Visualiser", "vermilion_fft")
		end
	end)
	
end

Vermilion:RegisterExtension(EXTENSION)