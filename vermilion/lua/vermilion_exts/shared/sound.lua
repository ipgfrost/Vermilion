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
EXTENSION.Name = "Sound Controls"
EXTENSION.ID = "sound"
EXTENSION.Description = "Plays sounds and stuff"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"playsound",
	"stopsound"
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
	"VListSounds",
	"VBroadcastSound"
}
EXTENSION.ActiveSound = {}

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

	function Vermilion:PlaySound(vplayer, path, channel, loop)
		channel = channel or "BaseSound"
		loop = loop or false
		net.Start("VPlaySound")
		net.WriteString(path)
		net.WriteString("BaseSound")
		net.WriteString(tostring(loop))
		net.Send(vplayer)
	end
	
	function Vermilion:PlayStream(vplayer, stream, channel, loop)
		channel = channel or "BaseSound"
		loop = loop or false
		net.Start("VPlaySoundStream")
		net.WriteString(stream)
		net.WriteString(channel)
		net.WriteString(tostring(loop))
		net.Send(vplayer)
	end

	function Vermilion:BroadcastSound(path, channel, loop)
		for i,vplayer in pairs(player.GetHumans()) do
			self:PlaySound(vplayer, path, channel, loop)
		end
	end
	
	function Vermilion:BroadcastStream(stream, channel, loop)
		for i,vplayer in pairs(player.GetHumans()) do
			self:PlayStream(vplayer, stream, channel, loop)
		end
	end
	
	Vermilion:AddChatCommand("playsound", function(sender, text)
		local targetplayer = -1
		local loop = false
		local filename = -1
		local streamfile = -1
		for i,k in pairs(text) do
			if(k == "-targetplayer") then targetplayer = i + 1 end
			if(k == "-loop") then loop = true end
			if(k == "-file") then filename = i + 1 end
			if(k == "-stream") then streamfile = i + 1 end
		end
		if(filename == -1 and streamfile == -1) then
			Vermilion:SendNotify(sender, "Must specify -file or -stream option!", 5, NOTIFY_ERROR)
			return
		end
		if(targetplayer > -1) then
			local targetPlayer = Crimson.LookupPlayerByName(text[targetplayer])
			if(targetPlayer != nil) then
				Vermilion:SendNotify(sender, "Playing " .. text[filename] .. " to " .. text[2], 10, NOTIFY_GENERIC)
				if(streamfile == -1) then 
					net.Start("VPlaySound")
					net.WriteString(text[filename])
				else
					net.Start("VPlaySoundStream")
					net.WriteString(text[streamfile])
				end	
				net.WriteString("BaseSound")
				net.WriteString(tostring(loop))
				net.Send(targetPlayer)
			else
				Vermilion:SendNotify(sender, "Invalid target!", 10, NOTIFY_ERROR)
				return
			end
		end
		if(streamfile == -1) then 
			net.Start("VPlaySound")
			net.WriteString(text[filename])
		else
			net.Start("VPlaySoundStream")
			net.WriteString(text[streamfile])
		end
		
		net.WriteString("BaseSound")
		net.WriteString(tostring(loop))
		net.Broadcast()
	end)
	
	Vermilion:AddChatCommand("stopsound", function(sender, text)
		if(text[1] == "-targetplayer") then
			local targetPlayer = Crimson.LookupPlayerByName(text[2])
			if(targetPlayer != nil) then
				Vermilion:SendNotify(sender, "Stopping sound for " .. text[2], 10, NOTIFY_GENERIC)
				net.Start("VStopSound")
				net.WriteString("BaseSound")
				net.Send(targetPlayer)
			else
				Vermilion:SendNotify(sender, "Invalid target!", 10, NOTIFY_ERROR)
				return
			end
		end
		net.Start("VStopSound")
		net.WriteString("BaseSound")
		net.Broadcast()
	end)
	
	self:AddHook("VNET_VListSounds", function(vplayer)
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
	
	self:AddHook("VNET_VBroadcastSound", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "playsound")) then
			net.Start("VPlaySound")
			net.WriteString(net.ReadString())
			net.WriteString(net.ReadString())
			net.WriteString(net.ReadString()) -- don't loop yet
			net.Broadcast()
		end
	end)
	
	

	Vermilion:AddChatCommand("base", function(sender, text)
		Vermilion:Vox("all your base are beyond to us", player.GetAll())
	end)

	function Vermilion:Vox(str, tplayer)
		local tstr = {}
		if(istable(str)) then tstr = str else tstr = string.Explode(" ", str) end
		local ttime = 0
		for i,k in pairs(tstr) do
			local dur = SoundDuration("vox/" .. k .. ".wav") + 0.05
			timer.Simple(ttime, function()
				Vermilion:PlaySound(tplayer, "vox/" .. k .. ".wav")
			end)
			ttime = ttime + dur
		end
	end
	
	function Vermilion:VoxTime(str)
		local tstr = {}
		if(istable(str)) then tstr = str else tstr = string.Explode(" ", str) end
		local ttime = 0
		table.insert(tstr, "")
		for i,k in pairs(tstr) do
			ttime = ttime + SoundDuration("vox/" .. k .. ".wav") + 0.05
		end
		return ttime
	end

	Vermilion:AddChatCommand("vox", function(sender, text)
		Vermilion:Vox(text, player.GetAll())
	end)
	
	local words = {"one ", "two ", "three ", "four ", "five ", "six ", "seven ", "eight ", "nine "}
	local levels = {"thousand ", "million ", "billion ", "trillion ", "quadrillion ", "quintillion ", "sextillion ", "septillion ", "octillion ", [0] = ""}
	local iwords = {"ten ", "twenty ", "thirty ", "fourty ", "fifty ", "sixty ", "seventy ", "eighty ", "ninety "}
	local twords = {"eleven ", "twelve ", "thirteen ", "fourteen ", "fifteen ", "sixteen ", "seventeen ", "eighteen ", "nineteen "}
	 
	local function digits(n)
	  local i, ret = -1
	  return function()
		i, ret = i + 1, n % 10
		if n > 0 then
		  n = math.floor(n / 10)
		  return i, ret
		end
	  end
	end
	 
	local level = false
	local function getname(pos, dig) --stateful, but effective.
	  level = level or pos % 3 == 0
	  if(dig == 0) then return "" end
	  local name = (pos % 3 == 1 and iwords[dig] or words[dig]) .. (pos % 3 == 2 and "hundred and " or "")
	  if(level) then name, level = name .. levels[math.floor(pos / 3)], false end
	  return name
	end
	
	local function getNum(num)
		local val, vword = num + 0, ""
		 
		for i, v in digits(val) do
		  vword = getname(i, v) .. vword
		end
		 
		for i, v in ipairs(words) do
		  --vword = vword:gsub("ty " .. v, "ty " .. v)
		  vword = vword:gsub("ten " .. v, twords[i])
		end
		 
		if #vword == 0 then return "zero" else return vword end
	end
	Vermilion:AddChatCommand("voxcount", function(sender, text)
		local voxtime = 0
		for val=0,tonumber(text[1]),1 do
			timer.Simple(voxtime, function()
				print(tostring(tonumber(text[1]) - val) .. getNum(tonumber(text[1]) - val))
				Vermilion:Vox(string.Trim(getNum(tonumber(text[1]) - val)), player.GetAll())
			end)
			voxtime = voxtime + Vermilion:VoxTime(getNum(tonumber(text[1]) - val))
		end
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("sound", nil)
	end)
end

function EXTENSION:InitClient()
	self:AddHook("VNET_VListSounds", function()
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
	self:AddHook("VActivePlayers", function(tab)
		if(not IsValid(EXTENSION.ActivePlayersList)) then
			return
		end
		EXTENSION.ActivePlayersList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.ActivePlayersList:AddLine( k[1], k[3] )
		end
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("sound", "Sound", "sound.png", "Play a sound to everybody on the server or specific players", function(panel)
		
			local fileTree = vgui.Create("DTree")
			fileTree:SetPos(10, 30)
			fileTree:SetPadding(5)
			fileTree:SetSize(220, 505)
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
		
		
		
			local playerList = Crimson.CreateList({ "Name", "Rank" })
			playerList:SetParent(panel)
			playerList:SetPos(240, 30)
			playerList:SetSize(200, panel:GetTall() - 50)
			EXTENSION.ActivePlayersList = playerList

			local playerListLabel = Crimson:CreateHeaderLabel(playerList, "Active Players")
			playerListLabel:SetParent(panel)
			
			
			
			local playToAllButton = Crimson.CreateButton("Broadcast Sound", function(self)
				local selected = fileTree:GetSelectedItem()
				if(selected == nil or selected:HasChildren()) then
					Crimson:CreateErrorDialog("Must select a sound file to play!")
					return
				end
				for i,k in pairs(EXTENSION.Nodes) do
					if(k == selected) then
						net.Start("VBroadcastSound")
						net.WriteString(i)
						net.WriteString("BaseSound")
						net.WriteString(tostring(false)) -- don't loop yet
						net.SendToServer()
						break
					end
				end
			end)
			playToAllButton:SetPos(450, (panel:GetTall() / 2) - 40)			
			playToAllButton:SetSize(120, 30)
			playToAllButton:SetParent(panel)
		

		
			local playToSelectedButton = Crimson.CreateButton("Send To Selected", function(self)
			
			end)
			playToSelectedButton:SetPos(450, (panel:GetTall() / 2))
			playToSelectedButton:SetSize(120, 30)
			playToSelectedButton:SetParent(panel)
		end)
	end)

	self:AddHook("VNET_VPlaySound", function()
		local path = net.ReadString()
		local index = net.ReadString()
		local loop = tobool(net.ReadString())
		if(EXTENSION.ActiveSound[index] != nil) then
			EXTENSION.ActiveSound[index]:Stop()
		end
		sound.PlayFile("sound/" .. path, "noplay", function(station, errorID)
			if(IsValid(station)) then
				station:EnableLooping(loop)
				station:Play()
				EXTENSION.ActiveSound[index] = station
			else
				print(errs[tostring(errorID)])
			end
		end)
	end)
	
	self:AddHook("VNET_VPlaySoundStream", function()
		local stream = net.ReadString()
		local index = net.ReadString()
		local loop = tobool(net.ReadString())
		if(EXTENSION.ActiveSound[index] != nil) then
			EXTENSION.ActiveSound[index]:Stop()
		end
		sound.PlayURL(stream, "noplay", function(station, errorID, errName)
			if( IsValid(station) ) then
				station:EnableLooping(loop)
				station:Play()
				EXTENSION.ActiveSound[index] = station
			else
				print(errs[tostring(errorID)])
			end
		end)
	end)
	
	self:AddHook("VNET_VStopSound", function()
		local index = net.ReadString()
		if(EXTENSION.ActiveSound[index] != nil) then
			EXTENSION.ActiveSound[index]:Stop()
		end
	end)
	
end

Vermilion:RegisterExtension(EXTENSION)