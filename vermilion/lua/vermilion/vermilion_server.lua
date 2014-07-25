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

-- These aren't added by gmod when on the server.
NOTIFY_GENERIC = 0
NOTIFY_ERROR = 1
NOTIFY_UNDO = 2
NOTIFY_HINT = 3
NOTIFY_CLEANUP = 4

include("vermilion/server/server_utils.lua")
include("vermilion/server/spawn_fix.lua")
include("vermilion/server/player_meta.lua")
include("vermilion/server/server_network.lua")
include("vermilion/server/chat.lua")

local resources = {
	"sound/buttons/lever5.wav",
	"sound/alarms/klaxon1.wav"
}

for i,k in pairs(resources) do
	resource.AddSingleFile(k)
end

function Vermilion:CreateEffect(effect, pos, angle, scale)
	net.Start("VEffect")
	net.WriteString(effect)
	net.WriteVector(pos)
	net.WriteAngle(angle)
	net.WriteString(tostring(scale))
	net.Broadcast()
end

Vermilion:RegisterHook("PlayerInitialSpawn", "Advertise", function(vplayer)
	timer.Simple( 1, function() 
		net.Start("Vermilion_Client_Activate")
		net.Send(vplayer)
	end)
	if(Vermilion:GetExtension("geoip") != nil) then
		if(Vermilion:GetPlayer(vplayer) == nil) then
			Vermilion.GetGeoIPForPlayer(vplayer, function(tab)
				Vermilion:BroadcastNotify(vplayer:GetName() .. " has joined the server from " .. tab['country_name'] .. " for the first time!")
				vplayer.Vermilion_Location = tab['country_code']
				vplayer:SetNWString("Country_Code", tab['country_code'])
			end)
			Vermilion:AddPlayer(vplayer)
		else
			Vermilion.GetGeoIPForPlayer(vplayer, function(tab)
				Vermilion:BroadcastNotify(vplayer:GetName() .. " has joined the server from " .. tab['country_name'])
				vplayer.Vermilion_Location = tab['country_code']
				vplayer:SetNWString("Country_Code", tab['country_code'])
			end)
		end
	else
		if(Vermilion:GetPlayer(vplayer) == nil) then
			Vermilion:BroadcastNotify(vplayer:GetName() .. " has joined the server for the first time!")
			Vermilion:AddPlayer(vplayer)
		else
			Vermilion:BroadcastNotify(vplayer:GetName() .. " has joined the server!")
		end
	end
	
	Vermilion:SendNotify(vplayer, "Welcome to " .. GetHostName() .. "!", 15, NOTIFY_GENERIC)
	Vermilion:SendNotify(vplayer, "This server is running the Vermilion server administration tool.", 15, NOTIFY_GENERIC)
	Vermilion:SendNotify(vplayer, "Be on your best behaviour!", 15, NOTIFY_GENERIC)
end)