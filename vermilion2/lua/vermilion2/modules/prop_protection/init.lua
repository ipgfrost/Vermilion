--[[
 Copyright 2015 Ned Hyett,

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

local MODULE = MODULE
MODULE.Name = "Prop Protection"
MODULE.ID = "prop_protect"
MODULE.Description = "Stops players from griefing props. Also implements CPPI v1.3 and buddy lists."
MODULE.Author = "Ned"
MODULE.Permissions = {
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
	"drive_own",
	"drive_others",
	"drive_all",
	"break_own",
	"break_others",
	"break_all",
	"edit_variable_own",
	"edit_variable_others",
	"edit_variable_all",
	"toolgun_own",
	"toolgun_others",
	"toolgun_all",
	"use_own",
	"use_others",
	"use_all",
	"right_click_all",
	"right_click_others",
	"right_click_own",
	"edit_property_all",
	"edit_property_others",
	"edit_property_own",


	"immune_to_antispam",
	"antispam_notify",

	"immune_to_cleanup",
	"delayed_cleanup"
}
MODULE.DefaultPermissions = {
	{ "admin", {
			"grav_gun_pickup_own",
			"grav_gun_pickup_others",
			"grav_gun_punt_own",
			"grav_gun_punt_others",
			"physgun_pickup_own",
			"physgun_pickup_others",
			"physgun_pickup_players",
			"drive_own",
			"drive_others",
			"toolgun_own",
			"toolgun_others",
			"use_own",
			"use_others",
			"right_click_others",
			"right_click_own",
			"break_own",
			"break_others",
			"edit_variable_own",
			"edit_variable_others",
			"edit_property_own",
			"edit_property_others",

			"immune_to_antispam",
			"antispam_notify",

			"immune_to_cleanup"
		}
	},
	{ "player", {
			"grav_gun_pickup_all",
			"grav_gun_pickup_own",
			"grav_gun_punt_own",
			"physgun_pickup_own",
			"drive_own",
			"toolgun_own",
			"use_own",
			"right_click_own",
			"edit_variable_own",
			"edit_property_own",
			"delayed_cleanup"
		}
	}
}
MODULE.PermissionDefinitions = {
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
	["drive_own"] = "This player can drive their own entities.",
	["drive_others"] = "This player can drive other players entities.",
	["drive_all"] = "This player can drive any prop, regardless of who owns the prop. Same as giving the player drive_own and drive_others at the same time.",
	["break_own"] = "This player can break their own entities.",
	["break_others"] = "This player can break other players entities.",
	["break_all"] = "This player can break any prop, regardless of who owns the prop. Same as giving the player break_own and break_others at the same time.",
	["toolgun_all"] = "This player can use the toolgun on any prop, regardless of who owns the prop. Same as giving the player toolgun_own and toolgun_others at the same time.",
	["toolgun_own"] = "This player can only use the toolgun on their own props.",
	["toolgun_others"] = "This player can only use the toolgun on props they do not own.",
	["use_all"] = "This player can USE any prop, regardless of who owns the prop. Same as giving the player use_own and use_others at the same time.",
	["use_own"] = "This player can only USE their own props.",
	["use_others"] = "This player can only USE props that they do not own.",
	["right_click_all"] = "This player can right click on any prop in the contextual menu regardless of who owns the prop. Same as giving the player right_click_own and right_click_others at the same time.",
	["right_click_own"] = "This player can only right click on their own props in the contextual menu.",
	["right_click_others"] = "This player can only right click on props in the contextual menu that they do not own.",
	["immune_to_antispam"] = "This player is not affected by anti-spam.",
	["antispam_notify"] = "This player can receive admin notifications generated by the anti-spam system.",
	["immune_to_cleanup"] = "This player will not have their props deleted after leaving the server.",
	["delayed_cleanup"] = "This player will be able to leave the server and re-connect in a specified time before having their props deleted. Without this permission or the 'immune_to_cleanup' permission, props will be deleted immediately."
}
MODULE.NetworkStrings = {
	"VGetBuddyList",
	"VAddBuddy",
	"VDelBuddy",
	"VGetBuddyPermissions",
	"VUpdateBuddyPermissions",
	
	"VQueryPPSteamID"
}

MODULE.UidCache = {}
CPPI = {}

function MODULE:CanTool(vplayer, ent, tool)
	if(tool == "vermilion2_owner") then return true end
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return true end
	if(ent:CreatedByMap() and MODULE:GetData("prop_protect_world", true)) then
		Vermilion:AddNotification(vplayer, MODULE:TranslateStr("world:cannotuse", nil, vplayer), NOTIFY_ERROR)
		return false
	end
	if(not Vermilion:HasPermission(vplayer, "toolgun_all") and MODULE:GetData("prop_protect_toolgun", true)) then
		if(ent.Vermilion_Owner != vplayer:SteamID() and (not Vermilion:HasPermission(vplayer, "toolgun_others") and not MODULE:BuddyCanRunAction(ent.Vermilion_Owner, vplayer, "toolgun"))) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("toolgun:cannotuse", nil, vplayer), NOTIFY_ERROR)
			return false
		end
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "toolgun_own")) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("toolgun:cannotuse", nil, vplayer), NOTIFY_ERROR)
			return false
		end
	end
	return true
end

function MODULE:CanGravGunPickup( vplayer, ent )
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "grav_gun_pickup_all") and MODULE:GetData("prop_protect_gravgun", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_pickup_own")) then
			if(vplayer.VLastProp != ent) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("gravgun:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		end
		if(ent.Vermilion_Owner != vplayer:SteamID() and (not Vermilion:HasPermission(vplayer, "grav_gun_pickup_others") and not MODULE:BuddyCanRunAction(ent.Vermilion_Owner, vplayer, "gravgun"))) then
			if(vplayer.VLastProp != ent) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("gravgun:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		end
	end
	return true
end

function MODULE:CanGravGunPunt( vplayer, ent )
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "grav_gun_punt_all") and MODULE:GetData("prop_protect_gravgun", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_punt_own")) then
			if(vplayer.VLastProp != ent) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("gravgun:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		end
		if(ent.Vermilion_Owner != vplayer:SteamID() and (not Vermilion:HasPermission(vplayer, "grav_gun_punt_others") and not MODULE:BuddyCanRunAction(ent.Vermilion_Owner, vplayer, "gravgun"))) then
			if(vplayer.VLastProp != ent) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("gravgun:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		end
	end
	return true
end

function MODULE:CanPhysgun( vplayer, ent )
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(ent:IsPlayer() and Vermilion:HasPermission(vplayer, "physgun_pickup_players") and not Vermilion:GetUser(ent):IsImmune(vplayer)) then return true elseif(ent:IsPlayer()) then return false end
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(ent:CreatedByMap() and MODULE:GetData("prop_protect_world", true)) then
		if(vplayer.VLastProp != ent) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("world:cannotuse", nil, vplayer), NOTIFY_ERROR)
			vplayer.VLastProp = ent
			vplayer.VLastPropTime = os.time()
		else
			vplayer.VLastPropTime = os.time()
		end
		return false
	end
	if(not Vermilion:HasPermission(vplayer, "physgun_pickup_all") and ent.Vermilion_Owner != nil and MODULE:GetData("prop_protect_physgun", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "physgun_pickup_own")) then
			if(vplayer.VLastProp != ent) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("physgun:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		elseif (ent.Vermilion_Owner != vplayer:SteamID() and (not Vermilion:HasPermission(vplayer, "physgun_pickup_others") and not MODULE:BuddyCanRunAction(ent.Vermilion_Owner, vplayer, "physgun"))) then
			if(vplayer.VLastProp != ent) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("physgun:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		end
	end
end

function MODULE:CanUse(vplayer, ent)
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(engine.ActiveGamemode() == "darkrp") then
		if(ent:isDoor()) then
			local doorInfo = ent:getDoorData()
			if(doorInfo.owner == nil) then return true end
			if(doorInfo.allowedToOwn != nil) then
				if(doorInfo.owner == vplayer:UserID() or doorInfo.allowedToOwn[vplayer:UserID()] == true) then
					return true
				end
			end
		end
	end
	if(not Vermilion:HasPermission(vplayer, "use_all") and MODULE:GetData("prop_protect_use", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "use_own")) then
			if(vplayer.VLastProp != ent) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("use:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		end
		if(ent.Vermilion_Owner != vplayer:SteamID() and (not Vermilion:HasPermission(vplayer, "use_others") and not MODULE:BuddyCanRunAction(ent.Vermilion_Owner, vplayer, "use"))) then
			if(vplayer.VLastProp != ent) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("use:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		end
	end
	return true
end

function MODULE:CanDrive(vplayer, ent)
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "drive_all") and MODULE:GetData("prop_protect_drive", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "drive_own")) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("drive:cannotuse", nil, vplayer), NOTIFY_ERROR)
			return false
		end
		if(ent.Vermilion_Owner != vplayer:SteamID() and (not Vermilion:HasPermission(vplayer, "drive_others") and not MODULE:BuddyCanRunAction(ent.Vermilion_Owner, vplayer, "drive"))) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("drive:cannotuse", nil, vplayer), NOTIFY_ERROR)
			return false
		end
	end
	return true
end

function MODULE:CanBreak(vplayer, ent)
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(ent:IsPlayer() or not vplayer:IsPlayer()) then return true end
	if(not Vermilion:HasPermission(vplayer, "break_all") and MODULE:GetData("prop_protect_break", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "break_own")) then
			if(vplayer.VLastProp != ent and ent:Health() > 0) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("break:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		end
		if(ent.Vermilion_Owner != vplayer:SteamID() and (not Vermilion:HasPermission(vplayer, "break_others") and not MODULE:BuddyCanRunAction(ent.Vermilion_Owner, vplayer, "break"))) then
			if(vplayer.VLastProp != ent and ent:Health() > 0) then
				Vermilion:AddNotification(vplayer, MODULE:TranslateStr("break:cannotuse", nil, vplayer), NOTIFY_ERROR)
				vplayer.VLastProp = ent
				vplayer.VLastPropTime = os.time()
			else
				vplayer.VLastPropTime = os.time()
			end
			return false
		end
	end
	return true
end

function MODULE:CanProperty(vplayer, ent, property)
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer)) then return false end
	if(Vermilion:GetModule("limit_properties") != nil) then
		local mod = Vermilion:GetModule("limit_properties")
		if(mod:IsPropertyBlocked(vplayer, property)) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("property:cannotuse", nil, vplayer), NOTIFY_ERROR)
			return false
		end
	end
	if(not Vermilion:HasPermission(vplayer, "edit_property_all") and MODULE:GetData("prop_protect_property", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "edit_property_own")) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("property:cannotuse", nil, vplayer), NOTIFY_ERROR)
			return false
		end
		if(ent.Vermilion_Owner != vplayer:SteamID() and (not Vermilion:HasPermission(vplayer, "edit_property_others") and not MODULE:BuddyCanRunAction(ent.Vermilion_Owner, vplayer, "property"))) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("property:cannotuse", nil, vplayer), NOTIFY_ERROR)
			return false
		end
	end
	return true
end

function MODULE:CanEditVariable(vplayer, ent, key, val, edit)
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "edit_variable_all") and MODULE:GetData("prop_protect_variable", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "edit_variable_own")) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("variable:cannotuse", nil, vplayer), NOTIFY_ERROR)
			return false
		end
		if(ent.Vermilion_Owner != vplayer:SteamID() and (not Vermilion:HasPermission(vplayer, "edit_variable_others") and not MODULE:BuddyCanRunAction(ent.Vermilion_Owner, vplayer, "variable"))) then
			Vermilion:AddNotification(vplayer, MODULE:TranslateStr("variable:cannotuse", nil, vplayer), NOTIFY_ERROR)
			return false
		end
	end
	return true
end

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "cancelautocleanup",
		Description = "Stops the autocleanup process for a player.",
		Syntax = "<name>",
		CanMute = true,
		Permissions = { "manage_prop_protection" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(Vermilion.Data.Users) do
					if(timer.Exists("VPropCleanup" .. k.SteamID)) then
						table.insert(tab, k.Name)
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local steamid = nil
			local name = nil
			for i,k in pairs(Vermilion.Data.Users) do
				if(string.find(string.lower(k.Name), string.lower(text[1]))) then steamid = k.SteamID name = k.Name break end
			end
			if(steamid == nil) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return false
			end
			if(not timer.Exists("VPropCleanup" .. steamid)) then
				log("Cannot abort auto-cleanup for this player; no auto-cleanup is in progress.", NOTIFY_ERROR)
				return false
			end
			timer.Destroy("VPropCleanup" .. steamid)
			glog(sender:GetName() .. " stopped the automatic prop cleanup for " .. name)
		end
	})
end

function MODULE:InitShared()

	CPPI.CPPI_DEFER = -666888
	CPPI.CPPI_NOTIMPLEMENTED = -999333

	function CPPI.GetName()
		return "Vermilion CPPI Module"
	end

	function CPPI.GetVersion()
		return Vermilion.GetVersionString()
	end

	function CPPI.GetInterfaceVersion()
		return 1.3
	end

	function CPPI.GetNameFromUID( uid )
		if(MODULE.UidCache[uid] != nil) then return MODULE.UidCache[uid] end
		for i,k in pairs(player.GetAll()) do
			if(IsValid(k)) then
				if(not table.HasValue(MODULE.UidCache, k:GetName())) then
					MODULE.UidCache[k:UniqueID()] = k:GetName()
				end
			end
		end
		if(MODULE.UidCache[uid] != nil) then return MODULE.UidCache[uid] end
		return nil
	end

	local pMeta = FindMetaTable("Player")
	function pMeta:CPPIGetFriends()
		if(SERVER) then
			return MODULE:GetActiveBuddies(self)
		end
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	self:AddHook(Vermilion.Event.MOD_LOADED, "AddGui", function()
		if(Vermilion:GetModule("server_settings") != nil) then
			local mgr = Vermilion:GetModule("server_settings")
			mgr:AddCategory("cat:prop_protect", "Prop Protection", 2)

			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_enabled",
				GuiText = "Enable Prop Protection",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_use",
				GuiText = "Block unpermitted players from \"using\" other player's props",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_physgun",
				GuiText = "Block unpermitted players from using the physics gun on other player's props",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_gravgun",
				GuiText = "Block unpermitted players from using the gravity gun on other player's props",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_toolgun",
				GuiText = "Block unpermitted players from using the toolgun on other player's props",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_break",
				GuiText = "Block unpermitted players from breaking other player's props",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_drive",
				GuiText = "Block unpermitted players from driving other player's props",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_variable",
				GuiText = "Block unpermitted players from editing variables on other player's props",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_property",
				GuiText = "Block unpermitted players from editing properties on other player's props",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "prop_protect_world",
				GuiText = "Blanket ban all physgun/toolgun interaction on map spawned props",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})


			mgr:AddOption({
				Module = "prop_protect",
				Name = "auto_cleanup_enabled",
				GuiText = "Enable Auto-Cleanup",
				Type = "Checkbox",
				Category = "Prop Protection",
				Default = true,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "auto_cleanup_delay",
				GuiText = "Auto-Cleanup delay (minutes)",
				Type = "Slider",
				Category = "Prop Protection",
				Default = 2,
				Permission = "manage_prop_protection",
				Bounds = { Min = 1, Max = 60 * 12 },
				Decimals = 0
			})

			mgr:AddCategory("cat:antispam", "Anti-Spam", 3)

			mgr:AddOption({
				Module = "prop_protect",
				Name = "antispam_enabled",
				GuiText = "Enable Anti-Spam",
				Type = "Checkbox",
				Category = "Anti-Spam",
				Default = false,
				Permission = "manage_prop_protection"
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "antispam_propslimit",
				GuiText = "Max props in time limit",
				Type = "Slider",
				Category = "Anti-Spam",
				Default = true,
				Permission = "manage_prop_protection",
				Bounds = { Min = 0, Max = 50 },
				Decimals = 0
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "antispam_timelimit",
				GuiText = "Time limit",
				Type = "Slider",
				Category = "Anti-Spam",
				Default = true,
				Permission = "manage_prop_protection",
				Bounds = { Min = 1, Max = 20 },
				Decimals = 0
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "antispam_action1",
				GuiText = "First Infraction",
				Type = "Combobox",
				Category = "Anti-Spam",
				Default = 1,
				Permission = "manage_prop_protection",
				Options = {
					"Warn Only",
					"Block spawning for 30 seconds",
					"Block spawning for 1 minute",
					"Kick",
					"Ban for 5 minutes",
					"Ban for 10 minutes",
					"Ban for 20 minutes",
					"Ban for 30 minutes",
					"Ban for 1 hour",
					"Ban for 1 day",
					"Permanently Ban",
					"Notify Administrators"
				}
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "antispam_action2",
				GuiText = "Second Infraction",
				Type = "Combobox",
				Category = "Anti-Spam",
				Default = 1,
				Permission = "manage_prop_protection",
				Options = {
					"Warn Only",
					"Block spawning for 30 seconds",
					"Block spawning for 1 minute",
					"Kick",
					"Ban for 5 minutes",
					"Ban for 10 minutes",
					"Ban for 20 minutes",
					"Ban for 30 minutes",
					"Ban for 1 hour",
					"Ban for 1 day",
					"Permanently Ban",
					"Notify Administrators"
				}
			})
			mgr:AddOption({
				Module = "prop_protect",
				Name = "antispam_action3",
				GuiText = "Third Infraction",
				Type = "Combobox",
				Category = "Anti-Spam",
				Default = 1,
				Permission = "manage_prop_protection",
				Options = {
					"Warn Only",
					"Block spawning for 30 seconds",
					"Block spawning for 1 minute",
					"Kick",
					"Ban for 5 minutes",
					"Ban for 10 minutes",
					"Ban for 20 minutes",
					"Ban for 30 minutes",
					"Ban for 1 hour",
					"Ban for 1 day",
					"Permanently Ban",
					"Notify Administrators"
				}
			})
		end
	end)
end

function MODULE:InitServer()
	timer.Create("V_PP_LastProp", 2, 0, function()
		for i,k in pairs(player.GetAll()) do
			if(k.VLastPropTime != nil) then
				if(k.VLastPropTime >= os.time() - 2) then continue end
			end
			k.VLastProp = nil
		end
	end)

	self:AddHook("GravGunPickupAllowed", function(vplayer, ent)
		if(not MODULE:CanGravGunPickup( vplayer, ent )) then return false end
	end)

	self:AddHook("GravGunPunt", function(vplayer, ent)
		if(not MODULE:CanGravGunPunt( vplayer, ent )) then return false end
	end)

	self:AddHook("PhysgunPickup", function(vplayer, ent)
		return MODULE:CanPhysgun( vplayer, ent )
	end)

	self:AddHook("CanTool", function(vplayer, tr, tool)
		if(tr.Hit and tr.Entity != nil and not MODULE:CanTool(vplayer, tr.Entity, tool)) then return false end
	end)

	self:AddHook("PlayerUse", function(vplayer, ent)
		if(not MODULE:CanUse(vplayer, ent)) then return false end
	end)

	self:AddHook("CanDrive", function(vplayer, ent)
		if(not MODULE:CanDrive(vplayer, ent)) then return false end
	end)

	self:AddHook("CanProperty", function(vplayer, prop, ent)
		if(not MODULE:CanProperty(vplayer, ent, prop)) then return false end
	end)

	self:AddHook("CanEditVariable", function(ent, vplayer, key, val, editor)
		if(not MODULE:CanEditVariable(vplayer, ent, key, val, editor)) then return false end
	end)

	self:AddHook("EntityTakeDamage", function(target, dmg)
		if(not MODULE:CanBreak(dmg:GetAttacker(), target) and not target:IsPlayer()) then dmg:ScaleDamage(0) return dmg end
	end)

	local eMeta = FindMetaTable("Entity")
	function eMeta:CPPIGetOwner()
		if(self.Vermilion_Owner == nil) then return nil, nil end
		local oPlayer = VToolkit:LookupPlayerBySteamID(self.Vermilion_Owner)
		return oPlayer, CPPI.CPPI_NOTIMPLEMENTED
	end


	function eMeta:CPPISetOwner(vplayer)
		if(IsValid(vplayer)) then
			if(hook.Call("CPPIAssignOwnership", nil, vplayer, self) != false) then
				Vermilion.Log("Warning (" .. tostring(self) .. "): prop owner was overwritten by CPPI!")
				self.Vermilion_Owner = vplayer:SteamID()
				self:SetNWString("Vermilion_Owner", vplayer:SteamID())
				return true
			end
		end
		return false
	end

	function eMeta:CPPISetOwnerUID( uid )
		local vplayer = VToolkit:LookupPlayerByName(CPPI.GetNameFromUID(uid))
		if(IsValid(vplayer)) then
			if(hook.Call("CPPIAssignOwnership", nil, vplayer, self) != false) then
				self.Vermilion_Owner = vplayer:SteamID()
				self:SetNWString("Vermilion_Owner", vplayer:SteamID())
				return true
			end
		end
		return false
	end

	function eMeta:CPPICanTool( vplayer, tool )
		return MODULE:CanTool(vplayer, self, tool) == nil
	end

	function eMeta:CPPICanPhysgun( vplayer )
		return MODULE:CanPhysgun( vplayer, self )
	end

	function eMeta:CPPICanPickup( vplayer )
		return MODULE:CanGravGunPickup( vplayer, self )
	end

	function eMeta:CPPICanPunt( vplayer )
		return MODULE:CanGravGunPunt( vplayer, self )
	end

	function eMeta:CPPICanUse( vplayer )
		return MODULE:CanUse(vplayer, self)
	end

	function eMeta:CPPICanDamage( vplayer )
		return MODULE:CanBreak(vplayer, self)
	end

	function eMeta:CPPIDrive(vplayer)
		return MODULE:CanDrive(vplayer, self)
	end

	function eMeta:CPPICanProperty(vplayer, prop)
		return MODULE:CanProperty(vplayer, self, prop)
	end

	function eMeta:CPPICanEditVariable(vplayer, key, val, edit)
		return MODULE:CanEditVariable(vplayer, self, key, val, edit)
	end

	local function doInfraction(ply, num)
		local infractionMode = 1
		if(num == 1) then
			infractionMode = MODULE:GetData("antispam_action1", 1, true)
		elseif(num == 2) then
			infractionMode = MODULE:GetData("antispam_action2", 1, true)
		else
			infractionMode = MODULE:GetData("antispam_action3", 1, true)
		end

		local UserData = Vermilion:GetUser(ply)

		if(infractionMode == 1) then
			Vermilion:AddNotification(ply, "You have spawned too many props in a short space of time. Please wait for the quota to reset in " .. tostring(math.Round(timer.TimeLeft("VAntiSpam_Reset"), 2)) .. " seconds. Infraction: " .. tostring(num) .. ".", NOTIFY_HINT)
		elseif(infractionMode == 2) then
			Vermilion:GetUser(ply).AntiSpamBlockedUntil = os.time() + 30
			Vermilion:AddNotification(ply, "You have spawned too many props in a short space of time. Please wait 30 seconds for the quota to reset. Infraction: " .. tostring(num) .. ".", NOTIFY_ERROR)
		elseif(infractionMode == 3) then
			Vermilion:GetUser(ply).AntiSpamBlockedUntil = os.time() + 60
			Vermilion:AddNotification(ply, "You have spawned too many props in a short space of time. Please wait 1 minute for the quota to reset. Infraction: " .. tostring(num) .. ".", NOTIFY_ERROR)
		elseif(infractionMode == 4) then
			Vermilion:BroadcastNotification(ply:GetName() .. " was kicked by anti-spam. Infraction: " .. tostring(num))
			ply:Kick("Kicked by anti-spam. Infraction: " .. tostring(num))
		elseif(infractionMode == 5) then
			Vermilion:GetModule("bans"):BanPlayer(ply, nil, 60 * 5, "Banned by anti-spam for 5 minutes. Infraction: " .. tostring(num))
		elseif(infractionMode == 6) then
			Vermilion:GetModule("bans"):BanPlayer(ply, nil, 60 * 10, "Banned by anti-spam for 10 minutes. Infraction: " .. tostring(num))
		elseif(infractionMode == 7) then
			Vermilion:GetModule("bans"):BanPlayer(ply, nil, 60 * 20, "Banned by anti-spam for 20 minutes. Infraction: " .. tostring(num))
		elseif(infractionMode == 8) then
			Vermilion:GetModule("bans"):BanPlayer(ply, nil, 60 * 30, "Banned by anti-spam for 30 minutes. Infraction: " .. tostring(num))
		elseif(infractionMode == 9) then
			Vermilion:GetModule("bans"):BanPlayer(ply, nil, 60 * 60, "Banned by anti-spam for 1 hour. Infraction: " .. tostring(num))
		elseif(infractionMode == 10) then
			Vermilion:GetModule("bans"):BanPlayer(ply, nil, 60 * 60 * 24, "Banned by anti-spam for 1 day. Infraction: " .. tostring(num))
		elseif(infractionMode == 11) then
			Vermilion:GetModule("bans"):BanPlayer(ply, nil, 0, "Banned by anti-spam permanently. Infraction: " .. tostring(num))
		elseif(infractionMode == 12) then
			Vermilion:AddNotification(Vermilion:GetUsersWithPermission("antispam_notify"), ply:GetName() .. " is spamming props.")
		end

		UserData.AntiSpamInfractionsExpire = os.time() + (60 * 60 * 24)
		UserData.AntiSpamWaitUntilReset = true
		UserData.AntiSpamNextInfractionLevel = num + 1
		if(UserData.AntiSpamNextInfractionLevel > 3) then
			UserData.AntiSpamNextInfractionLevel = 1
		end
	end

	local function doSpawnChecks(ply)
		if(Vermilion:GetUser(ply).AntiSpamBlockedUntil != nil) then
			if(os.time() <= Vermilion:GetUser(ply).AntiSpamBlockedUntil) then
				Vermilion:AddNotification(ply, "You have been blocked from spawning props. Please wait for your cooldown to expire.", NOTIFY_HINT)
				return false
			end
		end
		if(Vermilion:GetUser(ply).AntiSpamWaitUntilReset) then
			if(Vermilion:GetUser(ply).AntiSpamCooldown == 0) then
				Vermilion:GetUser(ply).AntiSpamWaitUntilReset = false
			else
				Vermilion:AddNotification(ply, "You have spawned too many props in a short space of time. Please wait for the quota to reset in " .. tostring(math.Round(timer.TimeLeft("VAntiSpam_Reset"), 2)) .. " seconds.", NOTIFY_HINT)
				return false
			end
		end
		if(Vermilion:GetUser(ply).AntiSpamInfractionsExpire == nil) then Vermilion:GetUser(ply).AntiSpamInfractionsExpire = 0 end
		if(os.time() >= Vermilion:GetUser(ply).AntiSpamInfractionsExpire) then
			Vermilion:GetUser(ply).AntiSpamNextInfractionLevel = 1
		end
		if(Vermilion:GetUser(ply).AntiSpamCooldown >= MODULE:GetData("antispam_propslimit", 5, true) and MODULE:GetData("antispam_enabled", false, true)) then
			doInfraction(ply, Vermilion:GetUser(ply).AntiSpamNextInfractionLevel or 1)
			return false
		end
		if(Vermilion:GetUser(ply).AntiSpamCooldown == nil) then Vermilion:GetUser(ply).AntiSpamCooldown = 0 end
		Vermilion:GetUser(ply).AntiSpamCooldown = Vermilion:GetUser(ply).AntiSpamCooldown + 1
	end

	local antiSpamHooks = {
		"PlayerSpawnProp",
		"PlayerSpawnEffect",
		"PlayerSpawnNPC",
		"PlayerSpawnRagdoll",
		"PlayerSpawnSENT",
		"PlayerSpawnSWEP",
		"PlayerSpawnVehicle"
	}

	for i,k in pairs(antiSpamHooks) do
		self:AddHook(k, k .. tostring(i), function(ply)
			if(Vermilion:HasPermission(ply, "immune_to_antispam")) then return end
			return doSpawnChecks(ply)
		end)
	end

	local function doAntiSpamReset()
		for i,ply in pairs(VToolkit.GetValidPlayers()) do
			if(Vermilion:GetUser(ply) == nil) then
				Vermilion.Log("Cannot update anti-spam data; the management engine is missing userdata for '" .. ply:GetName() .. "'...")
				continue
			end
			if(Vermilion:GetUser(ply).AntiSpamCooldown == nil) then Vermilion:GetUser(ply).AntiSpamCooldown = 0 end
			if(Vermilion:GetUser(ply).AntiSpamCooldown >= MODULE:GetData("antispam_propslimit", 5, true)) then
				Vermilion:AddNotification(ply, "Anti-Spam limit reset.", NOTIFY_HINT)
			end
			Vermilion:GetUser(ply).AntiSpamCooldown = 0
		end
	end

	timer.Create("VAntiSpam_Reset", MODULE:GetData("antispam_timelimit", 5, true), 0, function()
		doAntiSpamReset()
	end)

	self:AddDataChangeHook("antispam_timelimit", "reloadantispam", function(val)
		timer.Destroy("VAntiSpam_Reset")
		timer.Create("VAntiSpam_Reset", val, 0, function()
			doAntiSpamReset()
		end)
	end)

	local function cleanupPlayerProps(steamid)
		Vermilion:BroadcastNotification("Cleaning up " .. Vermilion:GetUserBySteamID(steamid).Name .. "'s props...", NOTIFY_HINT)
		for i,k in pairs(ents.GetAll()) do
			if(k.Vermilion_Owner == steamid) then
				SafeRemoveEntity(k)
			end
		end
	end

	self:AddHook("PlayerInitialSpawn", function(vplayer)
		timer.Destroy("VPropCleanup" .. vplayer:SteamID())
	end)

	self:AddHook("PlayerDisconnected", function(vplayer)
		if(not MODULE:GetData("auto_cleanup_enabled", true, true)) then return end
		if(Vermilion:HasPermission(vplayer, "immune_to_cleanup")) then return end
		if(not Vermilion:HasPermission(vplayer, "delayed_cleanup")) then
			cleanupPlayerProps(vplayer:SteamID())
			return
		end
		local steamid = vplayer:SteamID()
		--Vermilion:BroadcastNotification("Cleaning up " .. vplayer:GetName() .. "'s props in " .. tostring(MODULE:GetData("auto_cleanup_delay", 2, true)) .. " minutes...", NOTIFY_HINT)
		timer.Create("VPropCleanup" .. vplayer:SteamID(), MODULE:GetData("auto_cleanup_delay", 2, true) * 60, 1, function()
			cleanupPlayerProps(steamid)
		end)
	end)

	include("vermilion2/modules/prop_protection/buddylist.lua")
	include("vermilion2/modules/prop_protection/ownerview.lua")
	self:BuddyListInitServer()
	self:OwnerViewInitServer()

end

function MODULE:InitClient()
	local eMeta = FindMetaTable("Entity")
	function eMeta:CPPIGetOwner()
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	include("vermilion2/modules/prop_protection/buddylist.lua")
	include("vermilion2/modules/prop_protection/ownerview.lua")
	self:BuddyListInitClient()
	self:OwnerViewInitClient()
end
