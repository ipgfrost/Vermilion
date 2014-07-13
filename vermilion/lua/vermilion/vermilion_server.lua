--[[
 The MIT License

 Copyright 2014 Ned Hyett.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
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
	"ActivePlayers_Request",
	"ActivePlayers_Response",
	"Vermilion_ErrorMsg"
}

for i,str in pairs(networkStrings) do
	util.AddNetworkString(str)
end

net.Receive("ActivePlayers_Request", function(len, vplayer)
	net.Start("ActivePlayers_Response")
	local activePlayers = {}
	for i,k in pairs(player.GetAll()) do
		local playerDat = Vermilion:GetPlayer(k)
		table.insert(activePlayers, { k:GetName(), k:SteamID(), playerDat['rank'] } )
	end
	net.WriteTable(activePlayers)
	net.Send(vplayer)
end)

function Vermilion:SendNotify(vplayer, text, duration, notifyType)
	if(vplayer == nil or text == nil or duration == nil or notifyType == nil) then
		self.Log("Attempted to send notification with a nil parameter.")
		self.Log(tostring(vplayer) .. " === " .. text .. " === " .. tostring(duration) .. " === " .. tostring(notifyType))
		return
	end
	net.Start("Vermilion_Hint")
	net.WriteString("Vermilion: " .. tostring(text))
	net.WriteString(tostring(duration))
	net.WriteString(tostring(notifyType))
	net.Send(vplayer)
end

function Vermilion:BroadcastNotify(text, duration, notifyType)
	print(player.GetAll())
	self:SendNotify(player.GetAll(), text, duration, notifyType)
end

function Vermilion:BroadcastNotifyOmit(vplayerToOmit, text, duration, notifyType)
	if(vplayerToOmit == nil or text == nil or duration == nil or notifyType == nil) then
		self.Log("Attempted to send notification with a nil parameter.")
		self.Log(tostring(vplayerToOmit) .. " === " .. text .. " === " .. tostring(duration) .. " === " .. tostring(notifyType))
		return
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

function Vermilion:PlaySound(vplayer, path)
	net.Start("Vermilion_Sound")
	net.WriteString(path)
	net.Send(vplayer)
end

function Vermilion:BroadcastSound(path)
	for i,vplayer in pairs(player.GetHumans()) do
		self:PlaySound(vplayer, path)
	end
end

local META = FindMetaTable("Player")

function META:Vermilion_GetRank()
	return Vermilion:GetRank(self)
end

function META:Vermilion_IsOwner()
	return Vermilion:IsOwner(self)
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
		if(not tEnt:IsPlayer()) then
			tEnt:SetCustomCollisionCheck(true)
		end
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
	return SpawnLimitHitFunc(vplayer, "props")
end)

Vermilion:RegisterHook("PlayerSpawnRagdoll", "Vermilion_GMFixRagdoll", function(vplayer, model)
	return SpawnLimitHitFunc(vplayer, "ragdolls")
end)

Vermilion:RegisterHook("PlayerSpawnEffect", "Vermilion_GMFixEffect", function(vplayer, model)
	return SpawnLimitHitFunc(vplayer, "effects")
end)

Vermilion:RegisterHook("PlayerSpawnVehicle", "Vermilion_GMFixVehicle", function(vplayer, model, vehicle, tab)
	return SpawnLimitHitFunc(vplayer, "vehicles")
end)

Vermilion:RegisterHook("PlayerSpawnSWEP", "Vermilion_GMFixSWEP", function(vplayer, swepName, swepTab)
	return SpawnLimitHitFunc(vplayer, "sents")
end)

Vermilion:RegisterHook("PlayerSpawnSENT", "Vermilion_GMFixSENT", function(vplayer, name)
	return SpawnLimitHitFunc(vplayer, "sents")
end)

Vermilion:RegisterHook("PlayerSpawnNPC", "Vermilion_GMFixNPC", function(vplayer, npc_typ, equipment)
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
			if(not success) then Vermilion:SendNotify(vplayer, "Command failed with an error " .. tostring(err), 5, NOTIFY_ERROR) end
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
		Vermilion:BroadcastNotifyOmit(vplayer, vplayer:Name() .. " has joined the server for the first time!", 5, NOTIFY_GENERIC)
		Vermilion:AddPlayer(vplayer)
	else
		Vermilion:BroadcastNotifyOmit(vplayer, vplayer:Name() .. " has joined the server!", 5, NOTIFY_GENERIC)
	end
	
	Vermilion:SendNotify(vplayer, "Welcome to <INSERT SERVER NAME HERE>!", 15, NOTIFY_GENERIC)
	Vermilion:SendNotify(vplayer, "This server is running the Vermilion server administration tool.", 15, NOTIFY_GENERIC)
	Vermilion:SendNotify(vplayer, "Be on your best behaviour!", 15, NOTIFY_GENERIC)
end)


hook.Add("ShouldCollide", "Vermilion_ShouldCollide", function(ent1, ent2)
	if((not ent1:IsWorld() and not ent2:IsWorld())) then
		if((ent1:IsPlayer() and ent1:SteamID() != ent2.Vermilion_Owner) or (ent2:IsPlayer() and ent2:SteamID() != ent1.Vermilion_Owner) or (not ent1:IsPlayer() and not ent2:IsPlayer())) then
			local vplayer1 = Crimson.LookupPlayerBySteamID(ent1.Vermilion_Owner)
			local vplayer2 = Crimson.LookupPlayerBySteamID(ent2.Vermilion_Owner)
			if(not (vplayer1 == nil or vplayer2 == nil) and vplayer1 != vplayer2) then
				if(not Vermilion:HasPermission(vplayer1, "prop_colide_others") or not Vermilion:HasPermission(vplayer2, "prop_collide_others")) then
					return false
				end
			end
		end
	end
end)

