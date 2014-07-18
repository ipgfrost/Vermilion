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

Vermilion.Activated = false

-- Convars
CreateClientConVar("vermilion_alert_sounds", 1, true, false)

-- Networking
net.Receive("Vermilion_Hint", function(len)
	local text = net.ReadString()
	local duration = tonumber(net.ReadString())
	local notifyType = tonumber(net.ReadString())
	notification.AddLegacy( text, notifyType, duration )
	if(notifyType == NOTIFY_ERROR and GetConVarNumber("vermilion_alert_sounds") == 1) then
		sound.PlayFile("sound/alarms/klaxon1.wav", "noplay", function(station, errorID)
			if(IsValid(station)) then
				station:SetVolume(0.1)
				station:Play()
			else
				print(errorID)
			end
		end)
	end
	if(notifyType == NOTIFY_GENERIC and GetConVarNumber("vermilion_alert_sounds") == 1) then
		sound.PlayFile("sound/buttons/lever5.wav", "noplay", function(station, errorID)
			if(IsValid(station)) then
				station:SetVolume(0.1)
				station:Play()
			else
				print(errorID)
			end
		end)
	end
end)

net.Receive("Vermilion_Sound", function(len)
	local path = net.ReadString()
	sound.PlayFile("sound/" .. path, "noplay", function(station, errorID)
		if(IsValid(station)) then
			station:Play()
		else
			print(errorID)
		end
	end)
end)

net.Receive("Vermilion_ErrorMsg", function(len)
	Crimson:CreateErrorDialog(net.ReadString())
end)

net.Receive("VActivePlayers", function(len)
	hook.Call("VActivePlayers", nil, net.ReadTable())
end)

net.Receive("VRanksList", function(len)
	hook.Call("Vermilion_RanksList", nil, net.ReadTable())
end)

function Vermilion:GetWeaponName(vclass)
	return list.Get( "Weapon" )[vclass]['PrintName']
end

function Vermilion:GetNPCName(vclass)
	return list.Get( "NPC" )[vclass]['Name']
end