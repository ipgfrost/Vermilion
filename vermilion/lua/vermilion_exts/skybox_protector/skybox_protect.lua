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
EXTENSION.Name = "Skybox Protector"
EXTENSION.ID = "skybox_protect"
EXTENSION.Description = "Prevents people messing up the skybox."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"skybox_protect"
}
EXTENSION.PermissionDefinitions = {
	["skybox_protect"] = "This player is able to manage the skybox protector."
}

EXTENSION.Skyboxes = {}
EXTENSION.Point1 = {}

function EXTENSION:LoadSettings()
	local rawskyboxes = self:GetData("skyboxes", {})
	if(table.Count(rawskyboxes) == 0) then 
		self:ResetSettings()
		self:SaveSettings()
	end
	for i,k in pairs(rawskyboxes) do
		self.Skyboxes[i] = Crimson.CBound(Vector(k[1], k[2], k[3]), Vector(k[4], k[5], k[6]))
	end
end

function EXTENSION:SaveSettings()
	local rawskyboxes = {}
	for i,k in pairs(self.Skyboxes) do
		rawskyboxes[i] = { k.p1.x, k.p1.y, k.p1.z, k.p2.x, k.p2.y, k.p2.z }
	end
	self:SetData("skyboxes", rawskyboxes)
end

function EXTENSION:ResetSettings()
	EXTENSION.Skyboxes = {}
end

function EXTENSION:InitServer()
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		if(Vermilion:GetExtension("server_manager") != nil) then
			Vermilion:GetExtension("server_manager"):AddOption("skybox_protect", "protect_skybox", "Enable Skybox Protector", "Checkbox", "Misc", 50, false, "skybox_protect")
		end
	end)
	
	self:AddHook("PlayerInitialSpawn", "NoSkyboxNag", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "skybox_protect") and EXTENSION.Skyboxes[game.GetMap()] == nil and EXTENSION:GetData("protect_skybox", false)) then
			timer.Simple(2, function() Vermilion:SendNotify(vplayer, "No skybox area is defined for this map. Please define one or disable skybox protection!", VERMILION_NOTIFY_ERROR) end)
		end
	end)
	
	Vermilion:AddChatCommand("skybox", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "skybox_protect", log)) then
			if(EXTENSION.Skyboxes[game.GetMap()] != nil) then
				log("A skybox for this map has already been defined. By continuing, you will overwrite the old definition.", VERMILION_NOTIFY_ERROR)
			end
			if(EXTENSION.Point1[sender:SteamID()] != nil) then
				local p1 = EXTENSION.Point1[sender:SteamID()]
				local p2 = sender:GetPos()
				local p1t = p1
				local p2t = p2
				if(p1.x < p2.x) then
					p1t = Vector(p2.x, p1t.y, p1t.z)
					p2t = Vector(p1.x, p2t.y, p2t.z)
				end
				if(p1.y < p2.y) then
					p1t = Vector(p1t.x, p2.y, p1t.z)
					p2t = Vector(p2t.x, p1.y, p2t.z)
				end
				if(p1.z < p2.z) then
					p1t = Vector(p1t.x, p1t.y, p2.z)
					p2t = Vector(p2t.x, p2t.y, p1.z)
				end
				EXTENSION.Skyboxes[game.GetMap()] = Crimson.CBound(p1t, p2t)
				log("Defined skybox for " .. game.GetMap() .. "!")
				EXTENSION.Point1[sender:SteamID()] = nil
			else
				EXTENSION.Point1[sender:SteamID()] = sender:GetPos()
				log("Defined point 1.")
			end
		end
	end)
	
	Vermilion:AddChatCommand("cancelskybox", function(sender, text, log)
		if(EXTENSION.Point1[sender:SteamID()] == nil) then
			log("You aren't editing the skybox region.")
			return
		end
		EXTENSION.Point1[sender:SteamID()] = nil
		log("Stopped defining the skybox area.")
	end)
	
	local badClasses = {
		"gmod_hands",
		"predicted_viewmodel",
		"physgun_beam"
	}
	
	local function buildTimer()
		timer.Create("Vermilion_Skyboxes", 1, 0, function()
			if(EXTENSION.Skyboxes[game.GetMap()] != nil) then
				local entsRemoved = 0
				for i,k in pairs(EXTENSION.Skyboxes[game.GetMap()]:GetEnts()) do
					if(not k:CreatedByMap() and not k:IsPlayer() and (not k:IsWeapon() or k:GetOwner() == nil) and not table.HasValue(badClasses, k:GetClass())) then
						k:Remove()
						entsRemoved = entsRemoved + 1
					end
					if(k:IsPlayer()) then
						if(not Vermilion:HasPermission(k, "skybox_protect")) then k:Spawn() Vermilion:SendNotify(k, "Please stay out of the skybox!", VERMILION_NOTIFY_ERROR) end
					end
				end
				if(entsRemoved > 0) then Vermilion:SendNotify(Vermilion:GetUsersWithPermission("skybox_protect"), "Removed " .. tostring(entsRemoved) .. " items from the skybox.", VERMILION_NOTIFY_HINT) end
			end
		end)
	end
	
	if(EXTENSION:GetData("protect_skybox", false)) then
		buildTimer()
	end
	
	self:AddDataChangeHook("protect_skybox", "startprotect", function(val)
		if(val) then
			buildTimer()
		else
			timer.Destroy("Vermilion_Skyboxes")
		end
	end)
	
	self:AddHook("Vermilion-Pre-Shutdown", "skybox_save", function()
		EXTENSION:SaveSettings()
	end)
	
	EXTENSION:LoadSettings()
end

function EXTENSION:InitClient()

end

Vermilion:RegisterExtension(EXTENSION)