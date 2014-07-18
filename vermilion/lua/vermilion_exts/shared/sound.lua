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
}
EXTENSION.ActiveSound = nil

function EXTENSION:InitServer()

	function Vermilion:PlaySound(vplayer, path)
		net.Start("VPlaySound")
		net.WriteString(path)
		net.Send(vplayer)
	end

	function Vermilion:BroadcastSound(path)
		for i,vplayer in pairs(player.GetHumans()) do
			self:PlaySound(vplayer, path)
		end
	end
	
	Vermilion:AddChatCommand("playsound", function(sender, text)
		if(text[1] == "-targetplayer") then
			local targetPlayer = Crimson.LookupPlayerByName(text[2])
			if(targetPlayer != nil) then
				Vermilion:SendNotify(sender, "Playing " .. table.concat(text, " ", 3, table.Count(text)) .. " to " .. text[2], 10, NOTIFY_GENERIC)
				net.Start("VPlaySound")
				net.WriteString(table.concat(text, " ", 3, table.Count(text)))
				net.Send(targetPlayer)
			else
				Vermilion:SendNotify(sender, "Invalid target!", 10, NOTIFY_ERROR)
				return
			end
		end
		net.Start("VPlaySound")
		net.WriteString(table.concat(text, " ", 1, table.Count(text)))
		net.Broadcast()
	end)
	
	Vermilion:AddChatCommand("stopsound", function(sender, text)
		if(text[1] == "-targetplayer") then
			local targetPlayer = Crimson.LookupPlayerByName(text[2])
			if(targetPlayer != nil) then
				Vermilion:SendNotify(sender, "Stopping sound for " .. text[2], 10, NOTIFY_GENERIC)
				net.Start("VStopSound")
				net.Send(targetPlayer)
			else
				Vermilion:SendNotify(sender, "Invalid target!", 10, NOTIFY_ERROR)
				return
			end
		end
		net.Start("VStopSoundEXT")
		net.Broadcast()
	end)
end

function EXTENSION:InitClient()
	self:AddHook("VNET_VPlaySound", function()
		local path = net.ReadString()
		if(EXTENSION.ActiveSound != nil) then
			EXTENSION.ActiveSound:Stop()
		end
		sound.PlayFile("sound/" .. path, "noplay", function(station, errorID)
			if(IsValid(station)) then
				station:Play()
				EXTENSION.ActiveSound = station
			else
				print(errorID)
			end
		end)
	end)
	self:AddHook("VNET_VStopSound", function()
		if(EXTENSION.ActiveSound != nil) then
			EXTENSION.ActiveSound:Stop()
		end
	end)
	
end

Vermilion:RegisterExtension(EXTENSION)