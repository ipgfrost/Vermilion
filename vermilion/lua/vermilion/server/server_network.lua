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
	local activePlayers = {}
	for i,cplayer in pairs(player.GetAll()) do
		local playerDat = Vermilion:GetUser(cplayer)
		table.insert(activePlayers, { cplayer:GetName(), cplayer:SteamID(), playerDat:GetRank().Name } )
	end
	
	net.Start("VActivePlayers")
	net.WriteTable(activePlayers)
	net.Send(vplayer)
end

net.Receive("VActivePlayers", function(len, vplayer)
	Vermilion.internal:UpdateActivePlayers(vplayer)
end)

Vermilion:RegisterHook("PlayerConnect", "ActivePlayersUpdate", function()
	Vermilion.internal:UpdateActivePlayers()
end)

local oldWeapons = {}

function Vermilion:SendWeaponsList(vplayer)
	local hasGot = net.ReadBoolean()
	local crc = nil
	if(hasGot) then crc = net.ReadString() end


	local tab = {}
	for i,k in pairs(list.Get("Weapon")) do
		table.insert(tab, { Class = i, PrintName = k.PrintName })
	end
	
	local resend = true
	
	if(table.Count(oldWeapons) == 0) then
		oldWeapons = tab
	else
		if(oldWeapons == tab) then
			resend = false
		end
	end
	
	if(hasGot and crc != util.CRC(table.ToString(tab))) then
		resend = true
	end
	
	net.Start("VWeaponsList")
	net.WriteBoolean(resend)
	if(resend) then
		net.WriteTable(tab)
	else
		oldWeapons = tab
	end
	net.Send(vplayer)
end

local oldRanks = {}

function Vermilion:SendRanksList(vplayer)
	local hasGot = net.ReadBoolean()
	local crc = nil
	if(hasGot) then crc = net.ReadString() end

	local ranksTab = {}
	for i,k in pairs(Vermilion.Settings.Ranks) do
		local isDefault = "No"
		if(Vermilion:GetSetting("default_rank", "player") == k.Name) then
			isDefault = "Yes"
		end
		table.insert(ranksTab, { k.Name, isDefault })
	end
	
	local resend = true
	
	if(table.Count(oldRanks) == 0) then
		oldRanks = ranksTab
	else
		if(oldRanks == ranksTab) then
			resend = false
		end
	end
	
	if(hasGot and crc != util.CRC(table.ToString(ranksTab))) then
		resend = true
	end
	
	net.Start("VRanksList")
	net.WriteBoolean(resend)
	if(resend) then
		net.WriteTable(ranksTab)
	else
		oldRanks = ranksTab
	end
	net.Send(vplayer)
end

function Vermilion:SendEntsList(vplayer)
	local tab = {}
	for i,k in pairs(list.Get("SpawnableEntities")) do
		table.insert(tab, { Class = i, PrintName = k.PrintName })
	end
	
	net.Start("VEntsList")
	net.WriteTable(tab)
	net.Send(vplayer)
end

net.Receive("VWeaponsList", function(len, vplayer)
	Vermilion:SendWeaponsList(vplayer)
end)

net.Receive("VRanksList", function(len, vplayer)
	Vermilion:SendRanksList(vplayer)
end)

net.Receive("VEntsList", function(len, vplayer)
	Vermilion:SendEntsList(vplayer)
end)