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

-- Network
local networkStrings = {
	"Vermilion_Hint",
	"Vermilion_Sound",
	"Vermilion_Client_Activate",
	"VActivePlayers",
	"Vermilion_ErrorMsg",
	"VRanksList"
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

function Vermilion:SendNotify(vplayer, text, duration, notifyType)
	if(vplayer == nil or text == nil) then
		self.Log("Attempted to send notification with a nil parameter.")
		self.Log(tostring(vplayer) .. " === " .. text .. " === " .. tostring(duration) .. " === " .. tostring(notifyType))
		return
	end
	if(duration == nil) then
		duration = 5
	end
	if(notifyType == nil) then
		notifyType = NOTIFY_GENERIC
	end
	net.Start("Vermilion_Hint")
	net.WriteString("Vermilion: " .. tostring(text))
	net.WriteString(tostring(duration))
	net.WriteString(tostring(notifyType))
	net.Send(vplayer)
end

function Vermilion:BroadcastNotify(text, duration, notifyType)
	self:SendNotify(player.GetAll(), text, duration, notifyType)
end

function Vermilion:BroadcastNotifyOmit(vplayerToOmit, text, duration, notifyType)
	if(vplayerToOmit == nil or text == nil) then
		self.Log("Attempted to send notification with a nil parameter.")
		self.Log(tostring(vplayerToOmit) .. " === " .. text .. " === " .. tostring(duration) .. " === " .. tostring(notifyType))
		return
	end
	if(duration == nil) then
		duration = 5
	end
	if(notifyType == nil) then
		notifyType = NOTIFY_GENERIC
	end
	net.Start("Vermilion_Hint")
	net.WriteString("Vermilion: " .. tostring(text))
	net.WriteString(tostring(duration))
	net.WriteString(tostring(notifyType))
	net.SendOmit(vplayerToOmit)
end

function Vermilion:SendMessageBox(vplayer, text)
	if(vplayer == nil or text == nil) then
		self.Log("Attempted to send messagebox with a nil parameter!")
		self.Log(tostring(vplayer) .. " === " .. tostring(text))
	end
	net.Start("Vermilion_ErrorMsg")
	net.WriteString(text)
	net.Send(vplayer)
end

local META = FindMetaTable("Player")

function META:Vermilion_GetRank()
	return Vermilion:GetRank(self)
end

function META:Vermilion_IsOwner()
	return Vermilion:IsOwner(self)
end

function META:IsAdmin()
	return Vermilion:HasPermission(self, "identify_as_admin")
end

function META:Vermilion_IsAdmin()
	return Vermilion:IsAdmin(self)
end

function META:Vermilion_IsBanned()
	return Vermilion:IsBanned(self)
end

-- Hooks
local setOwnerFunc = function(vplayer, model, entity)
	local tEnt = entity
	if(tEnt == nil) then -- some of the hooks only have 2 parameters.
		tEnt = model
	end
	if(tEnt) then
		tEnt.Vermilion_Owner = vplayer:SteamID()
		--[[ if(not tEnt:IsPlayer()) then
			tEnt:SetCustomCollisionCheck(true)
		end ]]
	end
end

local spawnedFuncs = {
	"PlayerSpawnedProp",
	"PlayerSpawnedSENT",
	"PlayerSpawnedNPC",
	"PlayerSpawnedVehicle",
	"PlayerSpawnedEffect",
	"PlayerSpawnedRagdoll",
	"PlayerSpawnedSWEP"
}

local spawnFuncs = { 
	"PlayerSpawnProp",
	"PlayerSpawnSENT",
	"PlayerSpawnNPC",
	"PlayerSpawnVehicle",
	"PlayerSpawnEffect",
	"PlayerSpawnSWEP"
}

-- Entity Creator stuff
for i,spHook in pairs(spawnedFuncs) do
	Vermilion:RegisterHook(spHook, "Vermilion_SpawnCreatorSet" .. i, setOwnerFunc)
end

local function SpawnLimitHitFunc(vplayer, vtype)
	if(not IsValid(vplayer)) then return end
	local notLimitHit = vplayer:CheckLimit(vtype)
	if(notLimitHit == true) then
		return true
	end
end

Vermilion:RegisterHook("PlayerSpawnProp", "Vermilion_GMFixProp", function(vplayer, model)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_prop")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "props")
end)

Vermilion:RegisterHook("PlayerSpawnRagdoll", "Vermilion_GMFixRagdoll", function(vplayer, model)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_ragdoll")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "ragdolls")
end)

Vermilion:RegisterHook("PlayerSpawnEffect", "Vermilion_GMFixEffect", function(vplayer, model)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_effect")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "effects")
end)

Vermilion:RegisterHook("PlayerSpawnVehicle", "Vermilion_GMFixVehicle", function(vplayer, model, vehicle, tab)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_vehicle")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "vehicles")
end)

Vermilion:RegisterHook("PlayerSpawnSWEP", "Vermilion_GMFixSWEP", function(vplayer, swepName, swepTab)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_weapon")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "sents")
end)

Vermilion:RegisterHook("PlayerSpawnSENT", "Vermilion_GMFixSENT", function(vplayer, name)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_entity")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "sents")
end)

Vermilion:RegisterHook("PlayerSpawnNPC", "Vermilion_GMFixNPC", function(vplayer, npc_typ, equipment)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_npc")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "npcs")
end)

Vermilion:RegisterHook("PlayerSay", "Say1", function(vplayer, text, teamChat)
	if(string.StartWith(text, "!")) then
		local commandText = string.sub(text, 2)
		local parts = string.Explode(" ", commandText, false)
		local commandName = parts[1]
		local command = Vermilion.ChatCommands[commandName]
		if(command != nil) then
			table.remove(parts, 1)
			local success, err = pcall(command, vplayer, parts)
			if(not success) then Vermilion:SendNotify(vplayer, "Command failed with an error " .. tostring(err), 25, NOTIFY_ERROR) end
		else 
			Vermilion:SendNotify(vplayer, "No such command '" .. commandName .. "'", 5, NOTIFY_ERROR)
		end
		return ""
	end
end)

Vermilion:RegisterHook("PlayerInitialSpawn", "Advertise", function(vplayer)
	timer.Simple( 1, function() 
		net.Start("Vermilion_Client_Activate")
		net.Send(vplayer)
	end)
	if(Vermilion:GetPlayer(vplayer) == nil) then
		Vermilion:BroadcastNotifyOmit(vplayer, vplayer:Name() .. " has joined the server for the first time!")
		Vermilion:AddPlayer(vplayer)
	else
		Vermilion:BroadcastNotifyOmit(vplayer, vplayer:Name() .. " has joined the server!")
	end
	
	Vermilion:SendNotify(vplayer, "Welcome to " .. GetHostName() .. "!", 15, NOTIFY_GENERIC)
	Vermilion:SendNotify(vplayer, "This server is running the Vermilion server administration tool.", 15, NOTIFY_GENERIC)
	Vermilion:SendNotify(vplayer, "Be on your best behaviour!", 15, NOTIFY_GENERIC)
end)