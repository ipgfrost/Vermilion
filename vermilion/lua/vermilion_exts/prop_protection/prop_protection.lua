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
EXTENSION.Name = "Prop Protection"
EXTENSION.ID = "prop_protect"
EXTENSION.Description = "Handles prop protection"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"manage_prop_protection",
	"grav_gun_pickup_all",
	"grav_gun_pickup_own",
	"grav_gun_pickup_others",
	"grav_gun_punt_all",
	"grav_gun_punt_own",
	"grav_gun_punt_others",
	"physgun_pickup_all",
	"physgun_pickup_own",
	"physgun_pickup_others",
	"physgun_pickup_players",
	"physgun_persist",
	"toolgun_own",
	"toolgun_others",
	"toolgun_all",
	"use_own",
	"use_others",
	"use_all",
	"right_click_all",
	"right_click_others",
	"right_click_own"
}
EXTENSION.PermissionDefinitions = {
	["manage_prop_protection"] = "This player can see the Prop Protection Settings tab in the Vermilion menu and modify the settings within.",
	["grav_gun_pickup_all"] = "This player can pick up any prop with the gravity gun, regardless of who owns the prop. Same as giving the player grav_gun_pickup_own and grav_gun_pickup_others at the same time.",
	["grav_gun_pickup_own"] = "This player can only pick up their own props with the gravity gun.",
	["grav_gun_pickup_others"] = "This player can only pick up props with the gravity gun that they do not own.",
	["grav_gun_punt_all"] = "This player can punt any prop with the gravity gun, regardless of who owns the prop. Same as giving the player grav_gun_punt_own and grav_gun_punt_others at the same time.",
	["grav_gun_punt_own"] = "This player can only punt their own props with the gravity gun.",
	["grav_gun_punt_others"] = "This player can only punt props with the gravity gun that they do not own.",
	["physgun_pickup_all"] = "This player can pick up any prop with the physics gun, regardless of who owns the prop. Same as giving the player physgun_pickup_own and physgun_pickup_others at the same time.",
	["physgun_pickup_own"] = "This player can only pick up their own props with the physics gun.",
	["physgun_pickup_others"] = "This player can only pick up props with the physics gun that they do not own.",
	["physgun_pickup_players"] = "This player can pick up other players with the physics gun.",
	["physgun_persist"] = "This player can pickup/freeze persistent props with the physics gun.",
	["toolgun_all"] = "This player can use the toolgun on any prop, regardless of who owns the prop. Same as giving the player toolgun_own and toolgun_others at the same time.",
	["toolgun_own"] = "This player can only use the toolgun on their own props.",
	["toolgun_others"] = "This player can only use the toolgun on props they do not own.",
	["use_all"] = "This player can USE any prop, regardless of who owns the prop. Same as giving the player use_own and use_others at the same time.",
	["use_own"] = "This player can only USE their own props.",
	["use_others"] = "This player can only USE props that they do not own.",
	["right_click_all"] = "This player can right click on any prop in the contextual menu regardless of who owns the prop. Same as giving the player right_click_own and right_click_others at the same time.",
	["right_click_own"] = "This player can only right click on their own props in the contextual menu.",
	["right_click_others"] = "This player can only right click on props in the contextual menu that they do not own."
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"grav_gun_pickup_own",
			"grav_gun_punt_own",
			"grav_gun_pickup_others",
			"grav_gun_punt_others",
			"physgun_pickup_own",
			"physgun_pickup_others",
			"physgun_pickup_players",
			"toolgun_all",
			"use_all",
			"right_click_all"
		}
	},
	{ "player", {
			"grav_gun_pickup_own",
			"grav_gun_punt_own",
			"physgun_pickup_own",
			"toolgun_own",
			"use_own",
			"right_click_own"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VShowProps"
}

EXTENSION.ShowingProps = false

function EXTENSION:InitServer()

	self:AddHook("GravGunPickupAllowed", function(vplayer, ent)
		if(not EXTENSION:CanGravGunPickup( vplayer, ent )) then return false end
	end)
	
	self:AddHook("GravGunPunt", function(vplayer, ent)
		if(not EXTENSION:CanGravGunPunt( vplayer, ent )) then return false end
	end)
	
	self:AddHook("PhysgunPickup", function(vplayer, ent)
		return EXTENSION:CanPhysgun( vplayer, ent )
	end)
	
	self:AddHook("CanTool", function(vplayer, tr, tool)
		if(tr.Hit and tr.Entity != nil and not EXTENSION:CanTool(vplayer, tr.Entity, tool)) then return false end
	end)
	
	self:AddHook("OnPhysgunFreeze", "Vermilion_Physgun_Freeze", function( weapon, phys, ent, vplayer )
		if(ent:GetPersistent() and Vermilion:HasPermission(vplayer, "physgun_persist")) then
			return true
		end
	end)
	
	self:AddHook("PlayerUse", function(vplayer, ent)
		if(not EXTENSION:CanUse(vplayer, ent)) then return false end
	end)
	
	Vermilion:AddChatCommand("showmyprops", function(sender, text)
		net.Start("VShowProps")
		net.Send(sender)
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		if(Vermilion:GetExtension("server_manager") != nil) then
			local mgr = Vermilion:GetExtension("server_manager")
			mgr:AddOption("prop_protect", "prop_protect_use", "Block unpermitted players from \"using\" other player's props", "Checkbox", "Prop Protection", 30, true, "manage_prop_protection")
			mgr:AddOption("prop_protect", "prop_protect_physgun", "Block unpermitted players from using the physics gun on other player's props", "Checkbox", "Prop Protection", 30, true, "manage_prop_protection")
			mgr:AddOption("prop_protect", "prop_protect_gravgun", "Block unpermitted players from using the gravity gun on other player's props", "Checkbox", "Prop Protection", 30, true, "manage_prop_protection")
			mgr:AddOption("prop_protect", "prop_protect_toolgun", "Block unpermitted players from using the toolgun on other player's props", "Checkbox", "Prop Protection", 30, true, "manage_prop_protection")
			mgr:AddOption("prop_protect", "prop_protect_world", "Blanket ban all physgun/toolgun interaction on map spawned props", "Checkbox", "Prop Protection", 30, true, "manage_prop_protection")
		end
	end)
	
	function EXTENSION:GetAllPropsOwnedByUser(vplayer)
		if(not IsValid(vplayer)) then return {} end
		local tab = {}
		for i,k in pairs(ents.GetAll()) do
			if(IsValid(k)) then
				if(k.Vermilion_Owner == vplayer:SteamID()) then
					table.insert(tab, k)
				end
			end
		end
		return tab
	end
	
end

function EXTENSION:InitClient()
	self:NetHook("VShowProps", function()
		EXTENSION.ShowingProps = not EXTENSION.ShowingProps
		if(EXTENSION.ShowingProps) then
			Vermilion:GetExtension("notifications"):AddNotify("Highlighting your props...")
		else
			Vermilion:GetExtension("notifications"):AddNotify("Not highlighting your props any more!")
		end
	end)

	self:AddHook("PreDrawHalos", "ShowProps", function()
		if(EXTENSION.ShowingProps) then
			local propsToHalo = {}
			for i,k in pairs(ents.GetAll()) do
				if(IsValid(k)) then
					if(k:GetNWString("Vermilion_Owner", "") == LocalPlayer():SteamID()) then
						table.insert(propsToHalo, k)
					end
				end
			end
			halo.Add(propsToHalo, Color(255, 0, 0), 5, 5, 2)
		end
	end)
end

function EXTENSION:CanTool(vplayer, ent, tool)
	if(not IsValid(vplayer) or not IsValid(ent)) then return true end
	if(ent:CreatedByMap() and EXTENSION:GetData("prop_protect_world", true)) then 
		--Vermilion:SendNotify(vplayer, "You can't use the toolgun on a map entity!", VERMILION_NOTIFY_ERROR)
		return false
	end
	if(not Vermilion:HasPermission(vplayer, "toolgun_all") and EXTENSION:GetData("prop_protect_toolgun", true)) then
		if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "toolgun_others")) then
			Vermilion:SendNotify(vplayer, "You cannot use the toolgun on this!", VERMILION_NOTIFY_ERROR)
			return false
		end
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "toolgun_own")) then
			Vermilion:SendNotify(vplayer, "You cannot use the toolgun on this!", VERMILION_NOTIFY_ERROR)
			return false
		end
	end
	return true
end

function EXTENSION:CanGravGunPickup( vplayer, ent )
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "grav_gun_pickup_all") and EXTENSION:GetData("prop_protect_gravgun", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_pickup_own")) then return false end
		if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_pickup_others")) then return false end
	end
	return true
end

function EXTENSION:CanGravGunPunt( vplayer, ent )
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "grav_gun_punt_all") and EXTENSION:GetData("prop_protect_gravgun", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_punt_own")) then return false end
		if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_punt_others")) then return false end
	end
	return true
end

function EXTENSION:CanPhysgun( vplayer, ent )
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(ent:CreatedByMap() and EXTENSION:GetData("prop_protect_world", true)) then 
		--Vermilion:SendNotify(vplayer, "You can't use the physgun on a map entity!", VERMILION_NOTIFY_ERROR)
		return false
	end
	if(ent:IsPlayer() and Vermilion:HasPermission(vplayer, "physgun_pickup_players")) then return true end
	if(ent:GetPersistent() and Vermilion:HasPermission(vplayer, "physgun_persist")) then return true end
	if(not Vermilion:HasPermission(vplayer, "physgun_pickup_all") and ent.Vermilion_Owner != nil and EXTENSION:GetData("prop_protect_physgun", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "physgun_pickup_own")) then
			return false
		elseif (ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "physgun_pickup_others")) then
			return false
		end
	end
end

function EXTENSION:CanUse(vplayer, ent)
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "use_all") and EXTENSION:GetData("prop_protect_use", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "use_own")) then return false end
		if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "use_others")) then return false end
	end
	return true
end

Vermilion:RegisterExtension(EXTENSION)