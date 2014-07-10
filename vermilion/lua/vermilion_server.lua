-- The MIT License
--
-- Copyright 2014 Ned Hyett.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- Network
local networkStrings = {
	"Vermilion_Hint",
	"Vermilion_Sound",
	"Vermilion_Client_Activate"
}

for i,str in pairs(networkStrings) do
	util.AddNetworkString(str)
end

function Vermilion:sendNotify(vplayer, text, duration, notifyType)
	net.Start("Vermilion_Hint")
	net.WriteString("Vermilion: " .. tostring(text))
	net.WriteString(tostring(duration))
	net.WriteString(tostring(notifyType))
	net.Send(vplayer)
end

function Vermilion:broadcastNotify(text, duration, notifyType)
	self:sendNotify(player.GetHumans(), text, duration, notifyType)
end

function Vermilion:playSound(vplayer, path)
	net.Start("Vermilion_Sound")
	net.WriteString(path)
	net.Send(vplayer)
end

function Vermilion:broadcastSound(path)
	for i,vplayer in pairs(player.GetHumans()) do
		self:playSound(vplayer, path)
	end
end

local META = FindMetaTable("Player")

function META:Vermilion_GetRank()
	return Vermilion:getRank(self)
end

function META:Vermilion_IsOwner()
	return Vermilion:isOwner(self)
end

function META:Vermilion_IsAdmin()
	return Vermilion:isAdmin(self)
end

function META:Vermilion_IsBanned()
	return Vermilion:isBanned(self)
end

-- Hooks
local setOwnerFunc = function(vplayer, model, entity)
	if(entity != nil) then
		entity.Vermilion_Owner = vplayer:SteamID()
		if(not entity:IsPlayer()) then
			entity:SetCustomCollisionCheck(true)
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
	hook.Add(spHook, "Vermilion_SpawnCreatorSet" .. i, setOwnerFunc)
end

Vermilion:registerHook("PlayerSay", "Say1", function(vplayer, text, teamChat)
	if(string.StartWith(text, "!")) then
		local commandText = string.sub(text, 2)
		local parts = string.Explode(" ", commandText, false)
		local commandName = parts[1]
		local command = Vermilion.chatCommands[commandName]
		if(command != nil) then
			table.remove(parts, 1)
			command(vplayer, parts)
		else 
			Vermilion:sendNotify(vplayer, "No such command '" .. commandName .. "'", 5, NOTIFY_ERROR)
		end
		return ""
	end
end)

Vermilion:registerHook("PlayerInitialSpawn", "Advertise", function(vplayer)
	for i,plyr in pairs(player.GetHumans()) do
		if(not plyr == vplayer) then
			Vermilion:sendNotify(plyr, vplayer:Name() .. " has joined the server!", 5, NOTIFY_HINT)
		end
	end
	Vermilion:sendNotify(vplayer, "Welcome to <INSERT SERVER NAME HERE>!", 20, NOTIFY_GENERIC)
	Vermilion:sendNotify(vplayer, "This server is running the Vermilion server administration tool.", 20, NOTIFY_GENERIC)
	Vermilion:sendNotify(vplayer, "Be on your best behaviour!", 20, NOTIFY_GENERIC)
end)

hook.Add("ShouldCollide", "Vermilion_ShouldCollide", function(ent1, ent2)
	if((not ent1:IsWorld() and not ent2:IsWorld())) then
		if((ent1:IsPlayer() and ent1:SteamID() != ent2.Vermilion_Owner) or (ent2:IsPlayer() and ent2:SteamID() != ent1.Vermilion_Owner) or (not ent1:IsPlayer() and not ent2:IsPlayer())) then
			local vplayer1 = Crimson.lookupPlayerBySteamID(ent1.Vermilion_Owner)
			local vplayer2 = Crimson.lookupPlayerBySteamID(ent2.Vermilion_Owner)
			--print(tostring(vplayer1) .. " <=> " .. tostring(vplayer2))
			if(not (vplayer1 == nil or vplayer2 == nil)) then
				if(not Vermilion:hasPermission(vplayer1, "prop_colide_others") or not Vermilion:hasPermission(vplayer2, "prop_collide_others")) then
					return false
				end
			end
			
		end
	end
	
end)

