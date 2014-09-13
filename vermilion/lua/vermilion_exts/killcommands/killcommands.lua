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
EXTENSION.Name = "Kill Commands"
EXTENSION.ID = "killcommands"
EXTENSION.Description = "Provides commands to kill people"
EXTENSION.Author = "Jacob Forsyth"
EXTENSION.Permissions = {
	"flatten",
	"lock_player",
	"unlock_player",
	"kill_player",
	"ragdoll_player",
	"strip_ammo",
	"roulette",
	"set_health",
	"explode"
}
EXTENSION.PermissionDefinitions = {
	["punishment"] = "This permission has been removed.",
	["flatten"] = "This player can use the flatten chat command and any features derived from it.",
	["lock_player"] = "This player can use the lockplayer chat command and any features derived from it.",
	["unlock_player"] = "This player can use the unlockplayer chat command and any features derived from it.",
	["kill_player"] = "This player can use the assassinate chat command and any features derived from it.",
	["ragdoll_player"] = "This player can use the ragdoll chat command and any features derived from it.",
	["strip_ammo"] = "This player can use the stripammo chat command and any features derived from it.",
	["roulette"] = "This player can use the roulette chat command and any features derived from it.",
	["set_health"] = "This player can use the health chat command and any features derived from it.",
	["explode"] = "This player can use the explode chat command and any features derived from it."
}

function EXTENSION:InitServer()
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "PlayerManagementIntegrate", function()
		if(Vermilion:GetExtension("players") != nil) then
			local ext = Vermilion:GetExtension("players")
			
			ext:AddCommand("Flatten", function(sender, players)
				return sender:HasPermission("flatten")
			end, function(vplayer)
				local SpawnLocation = vplayer:GetPos() + Vector(0,0,250)
				local model = "models/props_c17/column02a.mdl"
				
				local entity = ents.Create("prop_physics")
				vplayer:Freeze(true)
				timer.Simple(3, function()
					vplayer:Freeze(false)
				end)
				entity:SetModel(model)
				entity:SetPos(SpawnLocation)
				entity:SetAngles(Angle(0.0,0.0,0.0))
				entity:Spawn()
				local phys = entity:GetPhysicsObject()
				if !(phys && IsValid(phys)) then entity:Remove() return end
				timer.Simple(5, function()
					entity:Remove()
				end)
			end)
			
			
			ext:AddCommand("Lock", function(sender, players)
				return sender:HasPermission("lock_player")
			end, function(vplayer)
				vplayer:Lock()
			end)
			
			
			ext:AddCommand("Unlock", function(sender, players)
				return sender:HasPermission("unlock_player")
			end, function(vplayer)
				vplayer:UnLock()
			end)
			
			
			ext:AddCommand("Assassinate", function(sender, players)
				return sender:HasPermission("kill_player")
			end, function(vplayer)
				vplayer:KillSilent()
			end)
			
			
			ext:AddCommand("Ragdoll", function(sender, players)
				return sender:HasPermission("ragdoll_player")
			end, function(vplayer)
				vplayer:Vermilion_DoRagdoll()
			end)
			
			
			ext:AddCommand("Strip Ammo", function(sender, players)
				return sender:HasPermission("strip_ammo")
			end, function(vplayer)
				vplayer:RemoveAllAmmo()
			end)
			
			
			ext:AddCommand("Roulette", function(sender, players)
				return sender:HasPermission("roulette")
			end, function(players)
				
			end, true)
			
			ext:AddCommand("Launch", function(sender, players)
				return sender:HasPermission("launch_player")
			end, function(vplayer)
				local phys = vplayer:GetPhysicsObject()
				phys:ApplyForceCenter(Vector(0,0,5000))
			end)
			
			ext:AddCommand("Explode", function(sender, players)
				return sender:HasPermission("explode")
			end, function(vplayer)
				local explode = ents.Create("env_explosion")
				explode:SetPos(vplayer:GetPos())
				explode:Spawn()
				explode:SetKeyValue("iMagnitude", "20")
				explode:Fire("Explode", 0, 0)
				explode:EmitSound("weapon_AWP.Single", 400, 400)
				util.BlastDamage(explode, explode, explode:GetPos(), 20, 100)
			end)
		end
	end)

	Vermilion:AddChatCommand("lockplayer", function(sender, text, log)
		if( not Vermilion:HasPermissionError(sender, "lock_player") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1], false)
		if(!tplayer) then
			log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		tplayer:Lock()
		Vermilion:BroadcastNotify( tplayer:GetName() .. " was locked by " .. sender:GetName())
	end, "<player>")
	
	Vermilion:AddChatPredictor("lockplayer", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)

	Vermilion:AddChatCommand("unlockplayer", function(sender, text, log)
		if( not Vermilion:HasPermissionError(sender, "unlock_player") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1], false)
		if(!tplayer) then
			log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		tplayer:UnLock()
		Vermilion:BroadcastNotify( tplayer:GetName() .. " was unlocked by " .. sender:GetName())
	end, "<player>")
	
	Vermilion:AddChatPredictor("unlockplayer", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)

	Vermilion:AddChatCommand("assassinate", function(sender, text, log)
		if( not Vermilion:HasPermissionError(sender, "kill_player") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1], false)
		if(!tplayer) then
			log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		tplayer:KillSilent()
	end, "<player>")
	
	Vermilion:AddChatPredictor("assassinate", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)

	Vermilion:AddChatCommand("ragdoll", function(sender, text, log)
		if( not Vermilion:HasPermissionError(sender, "ragdoll_player") ) then
			return
		end
		if(table.Count(text) < 1) then
			log("Syntax: !ragdoll <player>")
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1], false)
		if(!tplayer) then
			log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		tplayer:Vermilion_DoRagdoll()
	end, "<player>")
	
	Vermilion:AddChatPredictor("ragdoll", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)

	Vermilion:AddChatCommand("stripammo", function(sender, text, log)
		if( not Vermilion:HasPermissionError(sender, "strip_ammo") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1], false)
		if(!tplayer) then
			log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		tplayer:RemoveAllAmmo()
		Vermilion:SendNotify(tplayer, "Your ammo was removed by " .. sender:GetName())
	end, "<player>")
	
	Vermilion:AddChatPredictor("stripammo", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)

	-- get rid of this, it's a complete mess.
	Vermilion:AddChatCommand("roulette", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "roulette")) then
			return
		end

		if(text[1] != "ALL") then
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(not tplayer) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end

			local Length = table.Count(text)

			if(not Length) then
				log("Not enough players!", VERMILION_NOTIFY_ERROR)
				return
			end

			local Index = math.random(1, Length)

			local tplayer = Crimson.LookupPlayerByName(text[Index], false)

			for i,k in pairs(text) do
				Vermilion:SendNotify(Crimson.LookupPlayerByName(k, false), "The players who are part of this roulette are: " .. table.concat(text, ", ", 1, Length) )
			end

			for i,k in pairs(text) do
				Vermilion:SendNotify(Crimson.LookupPlayerByName(k, false), "The player who is going to die is... " .. tplayer:GetName())
			end

			timer.Simple(3, function()
				tplayer:Kill()
				print(tplayer:GetName() .. " was killed while playing Russian roulette")
				Vermilion:BroadcastNotify(tplayer:GetName() .. " died while playing Russian roulette...")
			end)



		elseif(text[1] == "ALL") then
			Vermilion:BroadcastNotify("WARNING YOU ARE ALL PLAYING RUSSIAN ROULETTE... One of you will die and will be locked ", VERMILION_NOTIFY_ERROR)
			
			local All = player.GetAll()
			local Length = table.Count(All)
			local Index = math.random(1, Length)
			local tplayer = All[Index]

			timer.Simple(1, function()
				Vermilion:BroadcastNotify("The player who is going to die is " .. toplayer:GetName())
			end)
			
			timer.Simple(3, function()
				tplayer:Kill()
				print(tplayer:GetName() .. " was killed while playing Russian roulette")
				tplayer:Lock()
				timer.Simple(tonumber(text[2]), function()
					if(IsValid(tplayer)) then
					tplayer:UnLock()
					end
				end)
			end) 
		end
	end, "[players]/ALL")

	Vermilion:AddChatCommand("flatten", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "flatten")) then
			return
		end

		local tplayer = Crimson.LookupPlayerByName(text[1], false)
		
		if(!tplayer) then
			log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		local Location = tplayer:GetPos()

		local SpawnLocation = Location:Add(Vector(0,0,250))

		local Model = "models/props_c17/column02a.mdl"
		
		local entity = ents.Create("prop_physics")
		tplayer:Freeze(true)
		timer.Simple(3, function()
			tplayer:Freeze(false)
		end)
		entity:SetModel(Model)
		entity:SetPos(Location)
		entity:SetAngles(Angle(0.0,0.0,0.0))
		entity:Spawn()

		local phys = entity:GetPhysicsObject()

		if !(phys && IsValid(phys)) then entity:Remove() return end

		timer.Simple(5, function()
			entity:Remove()
		end)

	end, "<player>")
	
	Vermilion:AddChatPredictor("flatten", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)

	Vermilion:AddChatCommand("launch", function(sender, text, log)
		if( not Vermilion:HasPermissionError(sender, "launch_player") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1], false)

		if(!tplayer) then
			log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end

		local phys = tplayer:GetPhysicsObject()
		phys:ApplyForceCenter(Vector(0,0,5000000))
	end, "<player>")

	Vermilion:AddChatPredictor("launch", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	


	Vermilion:AddChatCommand("health", function(sender, text, log)
		if( not Vermilion:HasPermissionError(sender, "set_health") ) then
			return
		end
		
		if(table.Count(text) == 0) then
			log("Syntax: !health [player] <amount>", VERMILION_NOTIFY_ERROR)
			return
		end
		
		local target = sender
		if(table.Count(text) > 1) then
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(tplayer == nil) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			target = tplayer
		end
		
		local health = nil
		if(table.Count(text) > 1) then
			health = tonumber(text[2])
		else
			health = tonumber(text[1])
		end
		
		if(health == nil) then
			log("That isn't a number!", VERMILION_NOTIFY_ERROR)
			return
		end
		
		target:SetHealth(health)
		
		log("Set health to " .. tostring(health))
	end, "[player] <health>")
	
	Vermilion:AddChatPredictor("health", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("explode", function(sender, text, log)
		if(table.Count(text) < 1) then
			log("Syntax: !explode <player>", VERMILION_NOTIFY_ERROR)
		else
			if(Vermilion:HasPermissionError(vplayer, "explode")) then
				local tplayer = Crimson.LookupPlayerByName(text[1], false)
				if(not IsValid(tplayer)) then
					log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
					return
				end
				local explode = ents.Create("env_explosion")
				explode:SetPos(tplayer:GetPos())
				explode:Spawn()
				explode:SetKeyValue("iMagnitude", "20")
				explode:Fire("Explode", 0, 0)
				explode:EmitSound("weapon_AWP.Single", 400, 400)
				util.BlastDamage(explode, explode, explode:GetPos(), 20, 100)
			end
		end
	end, "<player>")

	Vermilion:AddChatPredictor("explode", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)


end

Vermilion:RegisterExtension(EXTENSION)