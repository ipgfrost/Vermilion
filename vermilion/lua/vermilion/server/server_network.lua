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

local networkStrings = {
	"Vermilion_Hint",
	"Vermilion_Sound",
	"Vermilion_Client_Activate",
	"VActivePlayers",
	"VRanksList",
	"VWeaponsList",
	"VEntsList",
	"VEffect",
	"Vermilion_ErrorMsg"
}

for i,str in pairs(networkStrings) do
	util.AddNetworkString(str)
end

function Vermilion.internal:UpdateActivePlayers(vplayer)
	if(vplayer == nil) then
		vplayer = player.GetAll()
	end
	net.Start("VActivePlayers")
	local activePlayers = {}
	for i,cplayer in pairs(player.GetAll()) do
		local playerDat = Vermilion:GetPlayer(cplayer)
		table.insert(activePlayers, { cplayer:GetName(), cplayer:SteamID(), playerDat['rank'] } )
	end
	net.WriteTable(activePlayers)
	net.Send(vplayer)
end

net.Receive("VActivePlayers", function(len, vplayer)
	Vermilion.internal:UpdateActivePlayers(vplayer)
end)

Vermilion:RegisterHook("PlayerConnect", "ActivePlayersUpdate", function()
	Vermilion.internal:UpdateActivePlayers()
end)

net.Receive("VWeaponsList", function(len, vplayer)
	net.Start("VWeaponsList")
	local tab = {}
	for i,k in pairs(list.Get("Weapon")) do
		table.insert(tab, { Class = i, PrintName = k.PrintName })
	end
	net.WriteTable(tab)
	net.Send(vplayer)
end)

net.Receive("VRanksList", function(len, vplayer)
	net.Start("VRanksList")
	local ranksTab = {}
	for i,k in pairs(Vermilion.Ranks) do
		local isDefault = "No"
		if(Vermilion:GetSetting("default_rank", "player") == k) then
			isDefault = "Yes"
		end
		table.insert(ranksTab, { k, isDefault })
	end
	net.WriteTable(ranksTab)
	net.Send(vplayer)
end)

net.Receive("VEntsList", function(len, vplayer)
	net.Start("VEntsList")
	local tab = {}
	for i,k in pairs(list.Get("SpawnableEntities")) do
		table.insert(tab, { Class = i, PrintName = k.PrintName })
	end
	net.WriteTable(tab)
	net.Send(vplayer)
end)