--[[
 Copyright 2015-16 Ned Hyett,

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

local MODULE = MODULE
MODULE.Name = "Sounds"
MODULE.ID = "sound"
MODULE.Description = "Plays sounds from files, the internet and the SoundCloud API."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"playsound",
	"playstream",
	"stopsound",
	"pausesound",
	"unpausesound",

	"use_playlists"
}
MODULE.NetworkStrings = {
	"QueueSound",
	"QueueStream",
	"PlaySound",
	"PlayStream",
	"Stop",
	"Pause",
	"Unpause",
	"ShowSoundInfo",

	"SoundCloudGetPlaylists",
	"SoundCloudGetPlaylistContent",
	"SoundCloudNewPlaylist",
	"SoundCloudAddToPlaylist",
	"SoundCloudEditPlaylist",
	"SoundCloudRemoveFromPlaylist",
	"SoundCloudRemovePlaylist",
	"SoundCloudPlayPlaylist",
	"SoundCloudBroadcastPlaylist",
	"SoundCloudAddToPlaylistQuestion"
}

MODULE.TYPE_FILE = -1
MODULE.TYPE_STREAM = -2

MODULE.CreditW = 0
MODULE.CreditH = 0

MODULE.Channels = {}
MODULE.Visualisers = {}

function MODULE:RegisterVisualiser(name, drawFunc)
	self.Visualisers[name] = drawFunc
end

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "playsound",
		Description = "Plays a sound to a player.",
		Syntax = "<path> [target:nil/name] [loop:true/false] [volume:0-100]",
		CanMute = true,
		Permissions = { "playsound" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then

			elseif(pos == 2) then
				return VToolkit.MatchPlayerPart(VToolkit.GetValidPlayers(), current)
			elseif(pos == 3) then
				return VToolkit.MatchStringPart({"true", "false"}, current)
			end
		end,
		Function = function(sender, text, log, glog)
			local path = nil
			local target = VToolkit.GetValidPlayers(false) -- don't include bots; they can't hear.
			local loop = false
			local volume = 100

			if(table.Count(text) < 1) then
				log("Missing path!", nil, NOTIFY_ERROR)
				return
			end

			path = text[1]

			if(table.Count(text) >= 2) then
				if(text[2] != "nil") then
					target = VToolkit.LookupPlayer(text[2])
					if(not IsValid(target)) then
						log("No such player!", nil, NOTIFY_ERROR)
						return
					end
				end
			end

			if(table.Count(text) >= 3) then
				if(tobool(text[3]) != nil) then
					loop = tobool(text[3])
				else
					log("Invalid loop parameter!", nil, NOTIFY_ERROR)
					return
				end
			end

			if(table.Count(text) >= 4) then
				if(tonumber(text[4]) != nil) then
					volume = tonumber(text[4])
					if(volume < 0 or volume > 100) then
						log("Invalid volume parameter!", nil, NOTIFY_ERROR)
						return
					end
				else
					log("Invalid volume parameter!", nil, NOTIFY_ERROR)
					return
				end
			end

			MODULE:SendSound(target, path, "BaseSound", { Volume = volume, Loop = loop })
			glog(sender:GetName() .. " is playing a sound.")
		end
	})

	Vermilion:AddChatCommand({
		Name = "playstream",
		Description = "Plays a stream to a player.",
		Syntax = "<url> [target:nil/name] [loop:true/false] [volume:0-100]",
		CanMute = true,
		Permissions = { "playsound" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then

			elseif(pos == 2) then
				return VToolkit.MatchPlayerPart(current)
			elseif(pos == 3) then
				return VToolkit.MatchStringPart({"true", "false"}, current)
			end
		end,
		Function = function(sender, text, log, glog)
			local url = nil
			local target = VToolkit.GetValidPlayers(false)
			local loop = false
			local volume = 100

			if(table.Count(text) < 1) then
				log("Missing URL!", nil, NOTIFY_ERROR)
				return
			end

			url = text[1]

			if(table.Count(text) >= 2) then
				if(text[2] != "nil") then
					target = VToolkit.LookupPlayer(text[2])
					if(not IsValid(target)) then
						log("No such player!", nil, NOTIFY_ERROR)
						return
					end
				end
			end

			if(table.Count(text) >= 3) then
				if(tobool(text[3]) != nil) then
					loop = tobool(text[3])
				else
					log("Invalid loop parameter!", nil, NOTIFY_ERROR)
					return
				end
			end

			if(table.Count(text) >= 4) then
				if(tonumber(text[4]) != nil) then
					volume = tonumber(text[4])
					if(volume < 0 or volume > 100) then
						log("Invalid volume parameter!", nil, NOTIFY_ERROR)
						return
					end
				else
					log("Invalid volume parameter!", nil, NOTIFY_ERROR)
					return
				end
			end

			MODULE:SendStream(target, url, "BaseSound", { Volume = volume, Loop = loop })
			glog(sender:GetName() .. " is playing a stream.")
		end
	})

	Vermilion:AddChatCommand({
		Name = "stopsound",
		Description = "Stops a sound.",
		Syntax = "[target:nil/name] [channel]",
		CanMute = true,
		Permissions = { "stopsound" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = VToolkit.GetValidPlayers(false)
			local channel = "BaseSound"

			if(table.Count(text) >= 1) then
				if(text[1] != "nil") then
					target = VToolkit.LookupPlayer(text[1])
					if(not IsValid(target)) then
						log("No such player!", nil, NOTIFY_ERROR)
						return
					end
				end
			end

			if(table.Count(text) >= 2) then
				channel = text[2]
			end

			MODULE:NetStart("Stop")
			net.WriteString(channel)
			net.Send(target)

			glog(sender:GetName() .. " stopped the sound in the " .. channel .. " channel.")
		end
	})

	Vermilion:AddChatCommand({
		Name = "pausesound",
		Description = "Pauses a sound",
		Syntax = "[target:nil/name] [channel]",
		CanMute = true,
		Permissions = { "pausesound" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = VToolkit.GetValidPlayers(false)
			local channel = "BaseSound"

			if(table.Count(text) >= 1) then
				if(text[1] != "nil") then
					target = VToolkit.LookupPlayer(text[1])
					if(not IsValid(target)) then
						log("No such player!", nil, NOTIFY_ERROR)
						return
					end
				end
			end

			if(table.Count(text) >= 2) then
				channel = text[2]
			end

			MODULE:NetStart("Pause")
			net.WriteString(channel)
			net.Send(target)

			glog(sender:GetName() .. " paused the sound in the " .. channel .. " channel.")
		end
	})

	Vermilion:AddChatCommand({
		Name = "unpausesound",
		Description = "Resumes playing a paused sound",
		Syntax = "[target:nil/name] [channel]",
		CanMute = true,
		Permissions = { "unpausesound" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log)
			local target = VToolkit.GetValidPlayers(false)
			local channel = "BaseSound"

			if(table.Count(text) >= 1) then
				if(text[1] != "nil" and text[1] != "@") then
					target = VToolkit.LookupPlayer(text[1])
					if(not IsValid(target)) then
						log("No such player!", nil, NOTIFY_ERROR)
						return
					end
				end
			end

			if(table.Count(text) >= 2) then
				channel = text[2]
			end

			MODULE:NetStart("Unpause")
			net.WriteString(channel)
			net.Send(target)

			glog(sender:GetName() .. " resumed the sound in the " .. channel .. " channel.")
		end
	})

	Vermilion:AddChatCommand({
		Name = "song",
		Description = "Shows the credits for the last sound played, if any.",
		Function = function(sender, text, log)
			MODULE:NetStart("ShowSoundInfo")
			net.WriteBool(false)
			net.Send(sender)
		end
	})

end

function MODULE:InitShared()
	if(SERVER) then
		AddCSLuaFile("vermilion2/modules/sound/soundcloud_bindings.lua")
		AddCSLuaFile("vermilion2/modules/sound/soundcloud.lua")
		AddCSLuaFile("vermilion2/modules/sound/sound_browser.lua")
		AddCSLuaFile("vermilion2/modules/sound/soundcloud_playlists.lua")
	end
	include("vermilion2/modules/sound/soundcloud_bindings.lua")
	include("vermilion2/modules/sound/soundcloud.lua")
	include("vermilion2/modules/sound/sound_browser.lua")
	include("vermilion2/modules/sound/soundcloud_playlists.lua")
end

function MODULE:InitServer()

	function MODULE:SendSound(vplayer, path, channel, parameters)
		MODULE:NetStart("PlaySound")
		net.WriteString(path)
		net.WriteString(channel)
		net.WriteTable(parameters or {})
		net.Send(vplayer)
	end

	function MODULE:BroadcastSound(path, channel, parameters)
		self:SendSound(VToolkit.GetValidPlayers(false), path, channel, parameters)
	end

	function MODULE:SendStream(vplayer, url, channel, parameters)
		MODULE:NetStart("PlayStream")
		net.WriteString(url)
		net.WriteString(channel)
		net.WriteTable(parameters or {})
		net.Send(vplayer)
	end

	function MODULE:BroadcastStream(url, channel, parameters)
		self:SendStream(VToolkit.GetValidPlayers(false), url, channel, parameters)
	end

	self:NetHook("PlaySound", { "playsound" }, function(vplayer)
		local path = net.ReadString()
		local channel = net.ReadString()
		local parameters = net.ReadTable()

		MODULE:BroadcastSound(path, channel, parameters)
	end)

	self:NetHook("PlayStream", { "playstream" }, function(vplayer)
		local url = net.ReadString()
		local channel = net.ReadString()
		local parameters = net.ReadTable()
		local info = net.ReadTable()

		MODULE:NetStart("ShowSoundInfo")
		net.WriteBool(true)
		net.WriteTable(info)
		net.Send(vplayer)

		MODULE:BroadcastStream(url, channel, parameters)
	end)

end

function MODULE:InitClient()

	CreateClientConVar("vermilion_fft", 1, true, false)
	CreateClientConVar("vermilion_fft_type", "Default", true, false)

	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		if(MODULE.Visualisers[GetConVarString("vermilion_fft_type")] == nil) then
			RunConsoleCommand("vermilion_fft_type", "Default")
		end
		local mod = Vermilion:GetModule("client_settings")
		if(mod == nil) then return end
		mod:AddOption({
			GuiText = "Enable Visualiser",
			ConVar = "vermilion_fft",
			Type = "Checkbox",
			Category = "Features"
		})
		mod:AddOption({
			GuiText = "Visualiser Style",
			ConVar = "vermilion_fft_type",
			Type = "Combobox",
			Category = "Graphics",
			Options = table.GetKeys(MODULE.Visualisers),
			SetAs = "text"
		})
	end)

	self:NetHook("PlaySound", function()
		local path = net.ReadString()
		local channel = net.ReadString()
		local parameters = net.ReadTable()
		MODULE:QueueSoundFile(path, channel, parameters, function(data)
			MODULE:PlayChannel(channel)
		end)
	end)

	self:NetHook("PlayStream", function()
		local url = net.ReadString()
		local channel = net.ReadString()
		local parameters = net.ReadTable()
		MODULE:QueueSoundStream(url, channel, parameters, function(data)
			MODULE:PlayChannel(channel)
		end)
	end)

	self:NetHook("Stop", function()
		local channel = net.ReadString()
		MODULE:StopChannel(channel)
	end)

	self:NetHook("ShowSoundInfo", function()
		if(not net.ReadBool()) then
			MODULE.Credits = MODULE.OldCredits
		else
			MODULE.Credits = net.ReadTable()
		end
		timer.Simple(20, function()
			MODULE.OldCredits = MODULE.Credits
			MODULE.Credits = nil
		end)
	end)

	local function setChannel(name, data)
		if(MODULE.Channels[name] != nil) then
			if(IsValid(MODULE.Channels[name].AudioChannel)) then
				MODULE.Channels[name].AudioChannel:Stop()
			end
		end
		MODULE.Channels[name] = data
	end

	function MODULE:GetChannel(name)
		return self.Channels[name]
	end

	local requiredFileParamters = {
		{ Name = "Volume", Default = 1 },
		{ Name = "Loop", Default = false }
	}

	local requiredStreamParameters = {
		{ Name = "Volume", Default = 1 },
		{ Name = "Loop", Default = false }
	}

	function MODULE:QueueSoundFile(path, channel, parameters, callback)
		parameters = parameters or {}

		for i,k in pairs(requiredFileParamters) do
			if(parameters[k.Name] == nil) then
				parameters[k.Name] = k.Default
			end
		end

		local data = { Type = MODULE.TYPE_FILE, Path = path, Ready = false, AudioChannel = nil, Done = false, Started = false }
		table.Merge(data, parameters)
		setChannel(channel, data)

		local typ = ""
		if(data.Loop) then
			typ = "noblock"
		end

		sound.PlayFile("sound/" .. data.Path, "noplay " .. typ, function(channel, errid, errnam)
			if(IsValid(channel)) then
				channel:EnableLooping(data.Loop)
				channel:SetVolume(data.Volume)
				data.AudioChannel = channel
				data.Ready = true
				if(isfunction(callback)) then callback(data) end
			else
				Vermilion.Log(errnam)
			end
		end)
	end

	function MODULE:QueueSoundStream(url, channel, parameters, callback)
		parameters = parameters or {}

		for i,k in pairs(requiredFileParamters) do
			if(parameters[k.Name] == nil) then
				parameters[k.Name] = k.Default
			end
		end

		local data = { Type = MODULE.TYPE_STREAM, URL = url, Ready = false, AudioChannel = nil, Done = false, Started = false }
		table.Merge(data, parameters)
		setChannel(channel, data)

		local typ = ""
		if(data.Loop) then
			typ = "noblock"
		end

		sound.PlayURL(data.URL, "noplay " .. typ, function(channel, errid, errnam)
			if(IsValid(channel)) then
				channel:EnableLooping(data.Loop)
				channel:SetVolume(data.Volume)
				data.AudioChannel = channel
				data.Ready = true
				if(isfunction(callback)) then callback(data) end
			else
				Vermilion.Log(errnam)
			end
		end)
	end

	function MODULE:PlaySoundFile(path, channel, parameters)
		self:QueueSoundFile(path, channel, parameters, function(data)
			MODULE:PlayChannel(channel)
		end)
	end

	function MODULE:PlaySoundStream(url, channel, parameters)
		self:QueueSoundStream(url, channel, parameters, function(data)
			MODULE:PlayChannel(channel)
		end)
	end

	function MODULE:ValidateChannel(channel)
		if(self:GetChannel(channel) == nil) then return false end
		if(not self:GetChannel(channel).Ready) then return false end
		if(not IsValid(self:GetChannel(channel).AudioChannel)) then return false end

		return true
	end

	function MODULE:PlayChannel(channel)
		if(not self:ValidateChannel(channel)) then return false end
		self:GetChannel(channel).AudioChannel:Play()
		self:GetChannel(channel).Started = true
		return true
	end

	function MODULE:PauseChannel(channel)
		if(not self:ValidateChannel(channel)) then return false end
		self:GetChannel(channel).AudioChannel:Pause()
		return true
	end

	function MODULE:StopChannel(channel)
		if(not self:ValidateChannel(channel)) then return false end
		self:GetChannel(channel).AudioChannel:Stop()
		return true
	end

	timer.Create("VSoundFinishedEventTest", 3, 0, function()
		for i,k in pairs(MODULE.Channels) do
			if(k.Done) then continue end
			if(not k.Started) then continue end
			if(not IsValid(k.AudioChannel) or k.AudioChannel:GetState() == GMOD_CHANNEL_STOPPED) then
				k.Done = true
				hook.Run("VAudioChannelStopped", i)
			end
		end
	end)


	self:RegisterVisualiser("Default", function(data, percent, xpos, ypos, width, spacing)
		for i,k in pairs(data) do
			if(i > 80) then break end -- limit to 80 channels
			local colour = Color(255, 0, 0, 255)
			if(percent >= i) then colour = Color(0, 0, 255, 255) end -- draw the progress through the track
			draw.RoundedBox(2, xpos, ypos - ((k / 2) * (500 + (i * 8)) ), width, k * (500 + (i * 8)), colour)
			xpos = xpos + width + spacing
		end
	end)

	self:RegisterVisualiser("Scope", function(data, percent, xpos, ypos, width, spacing)
		for i,k in pairs(data) do
			if(i > 80) then break end -- limit to 80 channels.
			local colour = Color(255, 0, 0, 255)
			if(percent >= i) then colour = Color(0, 0, 255, 255) end
			surface.SetDrawColor(colour)
			if(table.Count(data) < i + 1) then
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
					surface.DrawLine(xpos, (ypos + yh) - (((k / 2) * (500 + (i * 8))) * ryh), xpos + width + spacing, (ypos + yh) - (((data[i + 1] / 2) * (500 + ((i+1) * 8))) * ryh2))
				end
			end
			xpos = xpos + width + spacing
		end
	end)

	--[[ local visualiserFunction = nil
	local devData = nil

	self:RegisterVisualiser("Development", function(data, percent, xpos, ypos, width, spacing)
		if(visualiserFunction == nil) then return end
		VDATA = data
		VPERCENT = percent
		VXPOS = xpos
		VYPOS = ypos
		VWIDTH = width
		VSPACING = spacing
		visualiserFunction()
	end)

	concommand.Add("vermilion_visualiserbuilder", function()
		local panel = VToolkit:CreateFrame({
			size = { 600, 600 },
			pos = { (ScrW() - 600) / 2, (ScrH() - 650) / 2 },
			title = "Vermilion Visualiser Editor",
			closeBtn = true
		})

		local code = VToolkit:CreateTextbox()
		code:SetPos(0, 30)
		code:SetSize(600, 500)
		code:SetParent(panel)
		code:SetMultiline(true)
		code:SetUpdateOnType(true)
		code:SetTabbingDisabled(true)

		function code:OnChange(val)
			devData = val
		end

		function

		if(devData != nil) then
			code:SetValue(devData)
		end

		local compileBtn = VToolkit:CreateButton("Compile Code", function()
			visualiserFunction = CompileString(code:GetValue(), "Vermilion_VisualiserDev")
		end)
		compileBtn:SetPos(490, 570)
		compileBtn:SetSize(100, 20)
		compileBtn:SetParent(panel)

		panel:MakePopup()
		panel:DoModal()
		panel:SetAutoDelete(true)
	end) ]]

	self:AddHook("HUDShouldDraw", function(name)
		if(name == "NetGraph") then
			if(GetConVarNumber("vermilion_fft") != 1) then return end
			if(not MODULE:ValidateChannel("BaseSound")) then return end
			if(MODULE:GetChannel("BaseSound").AudioChannel:GetState() == 0) then return end
			return false
		end
	end)

	self:AddHook("HUDPaint", "FFTDraw", function()
		if(MODULE.Credits != nil) then
			local pos = 0
			local maxw = 0
			for i,k in pairs(MODULE.Credits) do
				local w,h = draw.SimpleText(k, "Default", ScrW() - 0 - 20, ScrH() - MODULE.CreditH - 100 + pos, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
				if(w > maxw) then maxw = w end
				pos = pos + h + 10
			end

			MODULE.CreditW = maxw
			MODULE.CreditH = pos
		end
		if(MODULE:ValidateChannel("BaseSound") and GetConVarNumber("vermilion_fft") == 1 and MODULE:GetChannel("BaseSound").AudioChannel:GetState() != 0) then
			local tab = {}
			local num = MODULE:GetChannel("BaseSound").AudioChannel:FFT(tab, FFT_256)
			local width = 5
			local spacing = 1

			if(num > 80) then num = 80 end -- limit to 80 channels
			local xpos = ScrW() - 10 - ((width + spacing) * num)
			local totalLen = xpos
			local ypos = ScrH() - 100
			local percent = (MODULE:GetChannel("BaseSound").AudioChannel:GetTime() / MODULE:GetChannel("BaseSound").AudioChannel:GetLength()) * num -- get the progress through the track as a percentage of the number of channels.
			if(not isfunction(MODULE.Visualisers[GetConVarString("vermilion_fft_type")])) then
				MODULE.Visualisers["Default"](tab, percent, xpos, ypos, width, spacing)
				return
			end
			MODULE.Visualisers[GetConVarString("vermilion_fft_type")](tab, percent, xpos, ypos, width, spacing)
		end
	end)

end
