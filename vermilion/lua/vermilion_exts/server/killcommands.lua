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
	"punishment"
}

function EXTENSION:InitServer()
	Vermilion:AddChatCommand("lockplayer", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1])
		if(!tplayer) then
			Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
			return
		end
		tplayer:Lock()
		Vermilion:BroadcastNotify( tplayer:GetName() .. " was locked by " .. sender:GetName())
	end)

	Vermilion:AddChatCommand("unlockplayer", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1])
		if(!tplayer) then
			Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
			return
		end
		tplayer:UnLock()
		Vermilion:BroadcastNotify( tplayer:GetName() .. " was unlocked by " .. sender:GetName())
	end)

	Vermilion:AddChatCommand("assassinate", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1])
		if(!tplayer) then
			Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
			return
		end
		tplayer:KillSilent()
	end)

	Vermilion:AddChatCommand("ragdoll", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1])
		if(!tplayer) then
			Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
			return
		end
		tplayer:Freeze()
		tplayer:CreateRagdoll()
		Vermilion:SendNotify(tplayer, "You have been turned into a ragdoll")
	end)

	Vermilion:AddChatCommand("removeammo", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1])
		if(!tplayer) then
			Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
			return
		end
		tplayer:RemoveAllAmmo()
		Vermilion:SendNotify(tplayer, "Your ammo was removed by " .. sender:GetName())
	end)


	Vermilion:AddChatCommand("roulette", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end

		if text[1] != "ALL" then

			local tplayer = Crimson.LookupPlayerByName(text[1])
			if(!tplayer) then
				Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
				return
			end

			local Length = table.Count(text)

			if !Length then
				Vermilion:SendNotify(sender, "Not enough players!", 5, NOTIFY_ERROR)
				return
			end

			local Index = math.random(1,Length)

			local tplayer = Crimson.LookupPlayerByName(text[Index])

			for i,k in pairs(text) do
				Vermilion:SendNotify(Crimson.LookupPlayerByName(k), "The players who are part of this roulette are: " .. table.concat(text, ", ", 1, Length) )
			end

			for i,k in pairs(text) do
				Vermilion:SendNotify(Crimson.LookupPlayerByName(k), "The player who is going to die is... " .. tplayer:GetName())
			end

			timer.Simple(3, function()
				tplayer:Kill()
				print(tplayer:GetName() .. " was killed while playing Russian roulette")
				Vermilion:BroadcastNotify(tplayer:GetName() .. " died while playing Russian roulette...")
			end)



		elseif text[1] == "ALL" then
			Vermilion:BroadcastNotify("WARNING YOU ARE ALL PLAYING RUSSIAN ROULETTE... One of you will die and will be locked ",5, NOTIFY_ERROR)
			
			local All = player.GetAll()
			local Length = table.Count(All)
			local Index = math.random(1, Length)
			local tplayer = All[Index]

			for i,k in pairs(All) do
				timer.Simple(1, function()
					Vermilion:SendNotify(k, "The player who is going to die is... " .. tplayer:GetName() )
				end)
			end
			timer.Simple(3, function()
				tplayer:Kill()
				print(tplayer:GetName() .. " was killed while playing Russian roulette")
				tplayer:Lock()
				timer.Simple(tonumber(text[2]), function()
					if IsValid(tplayer) then
					tplayer:UnLock()
					end
				end)
			end) 
		end
	end)

	Vermilion:AddChatCommand("flatten", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end

		local tplayer = Crimson.LookupPlayerByName(text[1])
		
		if(!tplayer) then
			Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
			return
		end
		local Location = tplayer:GetShootPos()

		Vermilion:SendNotify(sender, tostring(Location))

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

	end)

	Vermilion:AddChatCommand("launch", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1])

		if(!tplayer) then
			Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
			return
		end

		local phys = tplayer:GetPhysicsObject()
		phys:ApplyForceCenter(Vector(0,0,5000000))
	end)


	Vermilion:AddChatCommand("teleport", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1])
		local lplayer = Crimson.LookupPlayerByName(text[2])
		if(!tplayer) then
				Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
				return
			end
		if(!lplayer) then
				Vermilion:SendNotify(sender, "Player does not exist", 5, NOTIFY_ERROR)
				return
			end

		local Target = lplayer:GetShootPos()
		Target:Add(Vector(0,0,5))

		Vermilion:SendNotify(sender, tostring(lplayer:GetShootPos()), 5, NOTIFY_ERROR)
		tplayer:SetPos(Vector(Target))

	end)


	Vermilion:AddChatCommand("health", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "punishment") ) then
			return
		end
		
		
		if Crimson.LookupPlayerByName(text[1]) == Crimson.LookupPlayerByName(sender) then
		local tplayer = Crimson.LookupPlayerByName(text[1])

		tplayer:SetHealth(text[2])
		Vermilion:SendNotify(sender, "Your health has been set to "..tostring(text[2]))

	else
		Crimson.LookupPlayerByName(tplayer):SetHealth(text[2])
		Vermilion:SendNotify(sender, "Your health has been set to "..tostring(text[2]))
	end
	end)



end

Vermilion:RegisterExtension(EXTENSION)