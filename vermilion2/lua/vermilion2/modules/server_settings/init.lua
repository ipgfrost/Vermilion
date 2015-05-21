--[[
 Copyright 2015 Ned Hyett

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
MODULE.Name = "Server Settings"
MODULE.ID = "server_settings"
MODULE.Description = "Provides a collection of basic options for administrating the server."
MODULE.Author = "Ned"
MODULE.PreventDisable = true
MODULE.Permissions = {
	"manage_server",
	"manage_userdata",
	"no_fall_damage",
	"reduced_fall_damage",
	"ignore_pvp_state",
	"no_damage",
	"unlimited_ammo",
	"enable_flashlight",
	"noclip",
	"can_spray",
	"chat",
	"use_voip",
	"hear_voip",

	"setnoclip",
	"setnoclip_others",
	"setfalldamage",
	"setfalldamage_others",
	"setdamage",
	"setdamage_others",
	"setflashlight",
	"setflashlight_others",
	"setuammo",
	"setuammo_others",



	"change_motd",


	"anonymous_command_exec"
}
MODULE.NetworkStrings = {
	"VServerGetProperties", -- used to build the settings page
	"VServerUpdate",
	"VRequestMOTD",
	"VUpdateMOTD",
	"VUpdateMOTDSettings",
	"VGetMOTDProperties",
	"VGetCommandMuting",
	"VSetCommandMuting",
	"VUserDataList",
	"VGetUserData",
	"VDelUserData",
	"VResetConfiguration"
}
MODULE.DefaultPermissions = {
	{ Name = "admin", Permissions = {
			"no_fall_damage",
			"no_damage",
			"unlimited_ammo",
			"enable_flashlight",
			"noclip",
			"can_spray",
			"chat",
			"use_voip",
			"hear_voip",
			"setnoclip",
			"setnoclip_others",
			"setfalldamage",
			"setfalldamage_others",
			"setdamage",
			"setdamage_others",
			"setflashlight",
			"setflashlight_others",
			"setuammo",
			"setuammo_others"
		}
	},
	{ Name = "player", Permissions = {
			"reduced_fall_damage",
			"enable_flashlight",
			"noclip",
			"can_spray",
			"chat",
			"use_voip",
			"hear_voip",
			"setnoclip",
			"setfalldamage",
			"setdamage",
			"setflashlight",
			"setuammo"
		}
	}
}

local keylist = {}
if(CLIENT) then
	for i = 0, 200, 1 do
		if(input.GetKeyName(i) != nil) then
			table.insert(keylist, input.GetKeyName(i))
		end
	end
end



local categories = {
	{ Name = MODULE:TranslateStr("cat:limits"), ID = "Limits", Order = 0 },
	{ Name = MODULE:TranslateStr("cat:spawncampprevention"), ID = "SpawncampPrevention", Order = 30 },
	{ Name = MODULE:TranslateStr("cat:misc"), ID = "Misc", Order = 50 },
	{ Name = MODULE:TranslateStr("cat:danger"), ID = "Danger", Order = 1000 }
}

local options = {
	{ Name = "unlimited_ammo", GuiText = MODULE:TranslateStr("unlimited_ammo"), Type = "Combobox", Options = {
			MODULE:TranslateStr("off"),
			MODULE:TranslateStr("all_players"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 3 },
	{ Module = "limit_spawn", Name = "enable_limit_remover", GuiText = MODULE:TranslateStr("limitremover"), Type = "Combobox", Options = {
			MODULE:TranslateStr("off"),
			MODULE:TranslateStr("all_players"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 3 },
	{ Name = "enable_no_damage", GuiText = MODULE:TranslateStr("damage"), Type = "Combobox", Options = {
			MODULE:TranslateStr("off"),
			MODULE:TranslateStr("all_players"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 3 },
	{ Name = "enable_sprinting", GuiText = MODULE:TranslateStr("sprint"), Type = "Combobox", Options = {
			MODULE:TranslateStr("off"),
			MODULE:TranslateStr("all_players"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 3 },
	{ Name = "flashlight_control", GuiText = MODULE:TranslateStr("flashlight"), Type = "Combobox", Options = {
			MODULE:TranslateStr("off"),
			MODULE:TranslateStr("apb"),
			MODULE:TranslateStr("apa"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 4 },
	{ Name = "noclip_control", GuiText = MODULE:TranslateStr("noclipcontrol"), Type = "Combobox", Options = {
			MODULE:TranslateStr("off"),
			MODULE:TranslateStr("apb"),
			MODULE:TranslateStr("apa"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 4 },
	{ Name = "spray_control", GuiText = MODULE:TranslateStr("spraycontrol"), Type = "Combobox", Options = {
			MODULE:TranslateStr("off"),
			MODULE:TranslateStr("apb"),
			MODULE:TranslateStr("apa"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 4 },
	{ Name = "voip_control", GuiText = MODULE:TranslateStr("voip"), Type = "Combobox", Options = {
			MODULE:TranslateStr("voip:dnl"),
			MODULE:TranslateStr("voip:global"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 3 },
	{ Name = "limit_chat", GuiText = MODULE:TranslateStr("chat"), Type = "Combobox", Options = {
			MODULE:TranslateStr("off"),
			MODULE:TranslateStr("chat:global"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 3 },
	{ Name = "disable_fall_damage", GuiText = MODULE:TranslateStr("falldmg"), Type = "Combobox", Options = {
			MODULE:TranslateStr("off"),
			MODULE:TranslateStr("all_players"),
			MODULE:TranslateStr("falldmg:reduced"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 4 },
	{ Name = "disable_owner_nag", GuiText = MODULE:TranslateStr("ownernag"), Type = "Checkbox", Category = "Misc", Default = false, Incomplete = true },
	{ Name = "player_collision_mode", GuiText = MODULE:TranslateStr("plycoll"), Type = "Combobox", Options = {
			MODULE:TranslateStr("plycoll:no"),
			MODULE:TranslateStr("plycoll:always"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Misc", Default = 3, Incomplete = true },
	{ Name = "pvp_mode", GuiText = MODULE:TranslateStr("pvpmode"), Type = "Combobox", Options = {
			MODULE:TranslateStr("pvpmode:allow"),
			MODULE:TranslateStr("pvpmode:disable"),
			MODULE:TranslateStr("permissions_based")
		}, Category = "Limits", Default = 3 },
	{ Name = "driver", GuiText = MODULE:TranslateStr("driver"), Type = "Combobox", Options = table.GetKeys(Vermilion.Drivers), Category = "Danger", Permission = "*", Default = 1 },
	{ Name = "reset_config", GuiText = MODULE:TranslateStr("resetconf"), Type = "Button", Category = "Danger", Permission = "*", Function = function()
		VToolkit:CreateConfirmDialog(MODULE:TranslateStr("resetconf:question"), function()
				MODULE:NetCommand("VResetConfiguration")
			end, {
				Confirm = MODULE:TranslateStr("yes"),
				Deny = MODULE:TranslateStr("noemergency"),
				Default = false
			})
		end
	},
	{ Name = "forced_menu_enabled", GuiText = MODULE:TranslateStr("forced_menu_keybind:enabled"), Type = "Checkbox", Category = "Misc", Permission = "*", Default = false },
	{ Name = "forced_menu_keybind", GuiText = MODULE:TranslateStr("forced_menu_keybind:key"), Type = "Combobox", Options = keylist, Category = "Misc", Permission = "*", Default = 1, SendText = true },
	{ Name = "enable_spawncamp_protection", GuiText = MODULE:TranslateStr("spawncampprevention:enable"), Type = "Checkbox", Category = "SpawncampPrevention", Default = false },
	{ Name = "spawncamp_spawn_inv_time", GuiText = MODULE:TranslateStr("spawncampprevention:timer"), Type = "Slider", Category = "SpawncampPrevention", Default = 20, Bounds = { Min = 5, Max = 60 }, Decimals = 0 },
	//{ Name = "gamemode", GuiText = MODULE:TranslateStr("active_gamemode"), Type = "Combobox", Options = VToolkit.GetGamemodeNames(), Category = "Misc", Default = table.KeyFromValue(VToolkit.GetLowerGamemodeNames(), engine.ActiveGamemode()) }
}

function MODULE:AddCategory(name, id, order)
	for i,k in pairs(categories) do
		if(k.Name == MODULE:TranslateStr(name) or k.ID == id) then return end
	end
	table.insert(categories, { Name = MODULE:TranslateStr(name), ID = id, Order = order })
end

local optMustHave = {
  "Module",
  "Name",
  "GuiText",
  "Type",
  "Category"
}

-- can also have Default, Permission

function MODULE:AddOption(data)
  for i,k in pairs(optMustHave) do
    assert(data[k] != nil)
  end
  table.insert(options, table.Count(options) - 1, data)
end

MODULE.MOTDVars = {}

function MODULE:AddMOTDVar(name, func, desc)
	if(CLIENT) then
		self.MOTDVars[name] = desc
		return
	end
	self.MOTDVars[name] = func
end

function MODULE:InitShared()
	local funcs = {
		{
			Name = "servername",
			Description = "The hostname of the server.",
			Func = function() return GetHostName() end
		},
		{
			Name = "activeplayers",
			Description = "The number of players active on the server.",
			Func = function() return table.Count(player.GetAll()) end
		},
		{
			Name = "maxplayers",
			Description = "The maximum number of players that can join the server.",
			Func = function() return game.MaxPlayers() end
		},
		{
			Name = "map",
			Description = "The name of the current map",
			Func = function() return game.GetMap() end
		},
		{
			Name = "vermilion_version",
			Description = "The version of the Vermilion Core Engine.",
			Func = function() return Vermilion.GetVersion() end
		},
		{
			Name = "gamemode",
			Description = "The name of the current gamemode.",
			Func = function() return engine.ActiveGamemode() end
		},
		{
			Name = "gamemode_upper",
			Description = "The name of the current gamemode in sentence case.",
			Func = function() return string.SetChar(engine.ActiveGamemode(), 1, string.upper(string.GetChar(engine.ActiveGamemode(), 1))) end
		},
		{
			Name = "time",
			Description = "The time formatted as h:m:s am/pm on d/m/y",
			Func = function() return os.date("%I:%M:%S %p on %d/%m/%Y") end
		},
		{
			Name = "server_os",
			Description = "The name of the server operating system.",
			Func = function()
				if(system.IsWindows()) then
					return "Windows"
				elseif(system.IsOSX()) then
					return "OS X"
				elseif(system.IsLinux()) then
					return "Linux"
				end
			end
		},
		{
			Name = "gmod_version_raw",
			Description = "The raw GMod version number.",
			Func = function() return VERSION end
		},
		{
			Name = "gmod_version",
			Description = "The nice GMod version number.",
			Func = function() return VERSIONSTR end
		},
		{
			Name = "gmod_branch",
			Description = "Active GMod branch.",
			Func = function() return BRANCH end
		},
		{
			Name = "vermilion_menu_nag",
			Description = "Default nag asking the player to bind a key to the Vermilion Menu.",
			Func = function() return "Please bind a key to \"vermilion_menu\" to access many helpful features!" end
		},
		{
			Name = "player_rank",
			Description = "The rank of the joining player.",
			Func = function(vplayer) return Vermilion:GetUser(vplayer):GetRankName() end
		},
		{
			Name = "player_team",
			Description = "The team of the joining player.",
			Func = function(vplayer) return vplayer:Team() end
		},
		{
			Name = "player_steamid",
			Description = "The SteamID of the joining player.",
			Func = function(vplayer) return vplayer:SteamID() end
		},
		{
			Name = "player_steamid64",
			Description = "The 64-bit SteamID of the joining player.",
			Func = function(vplayer) return vplayer:SteamID64() end
		},
		{
			Name = "player_name",
			Description = "The name of the joining player.",
			Func = function(vplayer) return vplayer:GetName() end
		},
		{
			Name = "player_ip",
			Description = "The IP Address of the joining player.",
			Func = function(vplayer) return vplayer:IPAddress() end
		}
	}

	for i,k in pairs(funcs) do
		self:AddMOTDVar(k.Name, k.Func, k.Description)
	end
end


function MODULE:RegisterChatCommands()

	Vermilion:AddChatCommand({
		Name = "motd",
		Description = "Request the MOTD again.",
		Function = function(sender, text, log, glog)
			MODULE:NetStart("VRequestMOTD")
			local str = MODULE:GetData("motd", "", true)
			for i,k in pairs(MODULE.MOTDVars) do
				str = string.Replace(str, "%" .. i .. "%", tostring(k(sender) or "%" .. i .. "%"))
			end
			net.WriteString(str)
			net.WriteInt(MODULE:GetData("motd_type", 1, true), 32)
			net.Send(sender)
		end
	})

	Vermilion:AddChatCommand({
		Name = "noclip",
		Description = "Toggles noclip for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setnoclip" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil

			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setnoclip_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end

			if(not IsValid(target)) then
				log("no_users", nil, NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log("player_immune", { target:GetName() }, NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched noclip on for him/herself.")
				else
					glog(sender:GetName() .. " switched noclip on for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched noclip off for him/herself.")
				else
					glog(sender:GetName() .. " switched noclip off for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched noclip " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the noclip state for all players!"
		end
	})

	Vermilion:AddChatCommand({
		Name = "falldamage",
		Description = "Toggles falldamage for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setfalldamage" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil

			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setfalldamage_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end

			if(not IsValid(target)) then
				log("no_users", nil, NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log("player_immune", { target:GetName() }, NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched falldamage on for him/herself.")
				else
					glog(sender:GetName() .. " switched falldamage on for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched falldamage off for him/herself.")
				else
					glog(sender:GetName() .. " switched falldamage off for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched falldamage " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the falldamage state for all players!"
		end
	})


	Vermilion:AddChatCommand({
		Name = "damagemode",
		Description = "Toggles damage for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setdamage" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil

			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setdamage_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end

			if(not IsValid(target)) then
				log("no_users", nil, NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log("player_immune", { target:GetName() }, NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched damage off for him/herself.")
				else
					glog(sender:GetName() .. " switched damage off for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched damage on for him/herself.")
				else
					glog(sender:GetName() .. " switched damage on for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched damage " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the damage state for all players!"
		end
	})

	Vermilion:AddChatCommand({
		Name = "flashlight",
		Description = "Toggles flashlight for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setflashlight" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil

			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setflashlight_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end

			if(not IsValid(target)) then
				log("no_users", nil, NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log("player_immune", { target:GetName() }, NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched the flashlight on for him/herself.")
				else
					glog(sender:GetName() .. " switched the flashlight on for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched the flashlight off for him/herself.")
				else
					glog(sender:GetName() .. " switched the flashlight off for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched the flashlight " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the flashlight state for all players!"
		end
	})

	Vermilion:AddChatCommand({
		Name = "uammo",
		Description = "Toggles unlimited ammo for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setuammo" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil

			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setuammo_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end

			if(not IsValid(target)) then
				log("no_users", nil, NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log("player_immune", { target:GetName() }, NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched unlimited ammo on for him/herself.")
				else
					glog(sender:GetName() .. " switched unlimited ammo on for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched unlimited ammo off for him/herself.")
				else
					glog(sender:GetName() .. " switched unlimited ammo off for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched unlimited ammo " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the unlimited ammo state for all players!"
		end
	})

end

function MODULE:InitServer()

	if(self:GetData("voip_control", 3, true) > 3) then self:SetData("voip_control", 3) end
	self:SetData("gamemode", table.KeyFromValue(VToolkit.GetLowerGamemodeNames(), engine.ActiveGamemode()))


	self:NetHook("VResetConfiguration", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "*")) then
			Vermilion:BroadcastNotification(vplayer:GetName() .. " has reset the configuration! Level reload in 30 seconds!", NOTIFY_ERROR)
			file.Delete(Vermilion.GetFileName("settings"))
			Vermilion:DelHook("ShutDown", "SaveConfiguration")
			timer.Destroy("Vermilion:SaveConfiguration")
			function Vermilion:SaveConfiguration() end
			if(Vermilion:GetModule("map") != nil) then
				local mod = Vermilion:GetModule("map")
				mod:AbortMapChange()
				mod:ScheduleMapChange(game.GetMap(), 30)
				mod.BlockAbort = true
			else
				timer.Simple(30, function()
					RunConsoleCommand("changelevel", game.GetMap())
				end)
			end
		end
	end)

	self:NetHook("VServerGetProperties", function(vplayer)
		local tab = {}
		for i,k in pairs(options) do
			local val = nil
			if(k.Type == "Button") then continue end
			if(k.Module != nil) then
				if(k.Module == "Vermilion") then
					val = Vermilion:GetData(k.Name, k.Default)
				else
					val = Vermilion:GetModuleData(k.Module, k.Name, k.Default)
				end
			else
				val = MODULE:GetData(k.Name, k.Default, false)
			end
			tab[tostring(k.Module) .. k.Name] = val
		end
		MODULE:NetStart("VServerGetProperties")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)

	local function sendUpdatedMenuValue(mod, name)
		local val = nil
		if(mod != nil) then
			if(mod == "Vermilion") then
				val = Vermilion:GetData(name)
			else
				val = Vermilion:GetModuleData(mod, name)
			end
		else
			val = MODULE:GetData(name)
		end
		MODULE:NetStart("VServerGetProperties")
		local tab = {}
		tab[tostring(mod) .. name] = val
		net.WriteTable(tab)
		net.Send(Vermilion:GetUsersWithPermission("manage_server"))
	end

	self:NetHook("VServerUpdate", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_server")) then
			local data = net.ReadTable()
			for i,k in pairs(data) do
				if(k.DoNotUpdate) then continue end
				if(k.Module != nil) then
					if(k.Module == "Vermilion") then
						Vermilion:SetData(k.Name, k.Value)
					else
						Vermilion:SetModuleData(k.Module, k.Name, k.Value)
					end
				else
					self:SetData(k.Name, k.Value)
				end
				sendUpdatedMenuValue(k.Module, k.Name)
			end
		end
	end)

	self:NetHook("VUpdateMOTD", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "change_motd")) then
			MODULE:SetData("motd", net.ReadString())
		end
	end)

	self:NetHook("VUpdateMOTDSettings", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "change_motd")) then
			MODULE:SetData("motd_type", net.ReadInt(32))
		end
	end)

	self:NetHook("VGetMOTDProperties", function(vplayer)
		MODULE:NetStart("VGetMOTDProperties")
		net.WriteString(MODULE:GetData("motd", "", true))
		net.WriteInt(MODULE:GetData("motd_type", 1, true), 32)
		net.Send(vplayer)
	end)

	self:NetHook("VRequestMOTD", function(vplayer)
		MODULE:NetStart("VRequestMOTD")
		local str = MODULE:GetData("motd", "", true)
		for i,k in pairs(MODULE.MOTDVars) do
			//if(string.find(str, "%" .. i .. "%")) then
				str = string.Replace(str, "%" .. i .. "%", tostring(k(vplayer) or "%" .. i .. "%"))
			//end
		end
		net.WriteString(str)
		net.WriteInt(MODULE:GetData("motd_type", 1, true), 32)
		net.Send(vplayer)
	end)

	self:NetHook("VGetCommandMuting", function(vplayer)
		MODULE:NetStart("VGetCommandMuting")
		local tab = {}
		for i,k in pairs(Vermilion.ChatCommands) do
			if(not k.CanMute) then continue end
			table.insert(tab, { Name = i, Value = Vermilion:GetData("muted_commands", {}, true)[i] != false })
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)

	self:NetHook("VSetCommandMuting", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_server")) then
			local typ = net.ReadString()
			local enabled = net.ReadBoolean()
			print("Setting " .. typ .. " to " .. tostring(enabled))
			Vermilion:GetData("muted_commands", {}, true)[typ] = enabled
		end
	end)

	self:AddHook("PlayerSay", function(ply)
		local mode = MODULE:GetData("limit_chat", 3)
		if(mode > 1) then
			if(mode == 2) then
				return ""
			end
			if(mode == 3) then
				if(not Vermilion:HasPermission(ply, "chat")) then return "" end
			end
		end
	end)

	self:AddHook("PlayerSpray", function(ply)
		local mode = MODULE:GetData("spray_control", 4)
		if(mode > 1) then
			if(mode == 2) then
				return false
			end
			if(mode == 3) then
				return true
			end
			if(mode == 4) then
				return Vermilion:HasPermission(ply, "can_spray")
			end
		end
	end)

	self:AddHook("PlayerNoClip", function(ply, enabled)
		if(enabled) then
			local mode = MODULE:GetData("noclip_control", 4)
			if(mode > 1) then
				if(mode == 2) then
					return false
				end
				if(mode == 3) then
					return true
				end
				if(mode == 4) then
					return Vermilion:HasPermission(ply, "noclip") and MODULE:GetData("NoclipPerPlayer", {}, true)[ply:SteamID()] != false
				end
			end
		else
			return true
		end
	end)

	self:AddHook("PlayerSwitchFlashlight", function(ply, enabled)
		if(enabled) then
			local mode = MODULE:GetData("flashlight_control", 4)
			if(mode > 1) then
				if(mode == 2) then
					return false
				end
				if(mode == 3) then
					return true
				end
				if(mode == 4) then
					if(not (Vermilion:HasPermission(ply, "enable_flashlight") and MODULE:GetData("FlashlightPerPlayer", {}, true)[ply:SteamID()] != false)) then return false end
				end
			end
		end
	end)

	self:AddHook("GetFallDamage", function(ply, speed)
		local mode = MODULE:GetData("disable_fall_damage", 4)
		if(mode > 1) then
			if(mode == 2) then
				return 0
			elseif(mode == 3) then
				return 5 -- TODO: make this customisable
			elseif(mode == 4) then
				if(Vermilion:HasPermission(ply, "no_fall_damage") and MODULE:GetData("FallDamagePerPlayer", {}, true)[ply:SteamID()] != false) then return 0 end
				if(Vermilion:HasPermission(ply, "reduced_fall_damage") and MODULE:GetData("FallDamagePerPlayer", {}, true)[ply:SteamID()] != false) then return 5 end
			end
		end
	end)

	self:AddHook("EntityTakeDamage", function(victim, dmg)
		if(dmg:IsDamageType(DMG_FALL)) then return end
		if(MODULE:GetData("enable_no_damage", 3) <= 1) then return end
		local attacker = dmg:GetAttacker()
		if(IsValid(victim) and victim:IsPlayer()) then
			local damageMode = MODULE:GetData("enable_no_damage", 3)
			local pvpMode = MODULE:GetData("pvp_mode", 3)
			if(damageMode > 1 and not (pvpMode > 1 and attacker:IsPlayer() and attacker != victim)) then
				if(damageMode == 2) then
					dmg:ScaleDamage(0)
					return dmg
				elseif(damageMode == 3) then
					if(Vermilion:HasPermission(victim, "no_damage") and MODULE:GetData("DisableDamagePerPlayer", {}, true)[victim:SteamID()] != false) then
						dmg:ScaleDamage(0)
						return dmg
					end
				end
			end
			if(attacker == victim) then return end
			if(not attacker:IsPlayer()) then return end
			if(pvpMode > 1) then
				if(pvpMode == 2) then
					dmg:ScaleDamage(0)
					return dmg
				elseif(pvpMode == 3) then
					if(IsValid(attacker) and attacker:IsPlayer()) then
						if(Vermilion:HasPermission(attacker, "ignore_pvp_state")) then
							return dmg
						end
					end
					dmg:ScaleDamage(0)
					return dmg
				end
			end
		end
	end)

	-- refill ammo every .5 seconds to save processing time.
	timer.Create("Vermilion_UnlimitedAmmo", 1/2, 0, function()
		if(MODULE:GetData("unlimited_ammo", 3) == 1) then return end
		for i,ply in pairs(VToolkit.GetValidPlayers()) do
			if((Vermilion:HasPermission(ply, "unlimited_ammo") and MODULE:GetData("AmmoPerPlayer", {}, true)[ply:SteamID()] != false) or MODULE:GetData("unlimited_ammo", 3) == 2) then
				if(IsValid(ply:GetActiveWeapon())) then
					local twep = ply:GetActiveWeapon()
					if(twep:Clip1() < 500) then twep:SetClip1(500) end
					if(twep:Clip2() < 500) then twep:SetClip2(500) end
					if(twep:GetPrimaryAmmoType() == 10 or twep:GetPrimaryAmmoType() == 8) then
						ply:GiveAmmo(1, twep:GetPrimaryAmmoType(), true)
					elseif(twep:GetSecondaryAmmoType() == 9 or twep:GetSecondaryAmmoType() == 2) then
						ply:GiveAmmo(1, twep:GetSecondaryAmmoType(), true)
					end
				end
			end
		end
	end)

	self:AddHook("PlayerCanHearPlayersVoice", function(listener, talker)
		local mode = MODULE:GetData("voip_control", 3, true)
		if(mode > 1) then
			if(mode > 3) then MODULE:SetData("voip_control", 3) mode = 3 end
			if(mode == 2) then
				return false
			elseif(mode == 3) then
				if(not Vermilion:HasPermission(talker, "use_voip")) then return false end
				if(not Vermilion:HasPermission(listener, "hear_voip")) then return false end
			end
		end
	end)

	self:NetHook("VUserDataList", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_userdata")) then
			MODULE:NetStart("VUserDataList")
			local tab = {}
			for i,k in pairs(Vermilion.Data.Users) do
				table.insert(tab, { Name = k.Name, Rank = k.Rank, SteamID = k.SteamID })
			end
			net.WriteTable(tab)
			net.Send(vplayer)
		end
	end)

	self:NetHook("VGetUserData", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_userdata")) then
			MODULE:NetStart("VGetUserData")
			local username = net.ReadString()
			net.WriteBoolean(true)
			net.WriteString(username)
			for i,k in pairs(Vermilion.Data.Users) do
				if(k.Name == username) then
					net.WriteTable(k)
					break
				end
			end
			net.Send(vplayer)
		end
	end)

	self:NetHook("VDelUserData", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_userdata")) then
			local tSteamID = net.ReadString()
			for i,k in pairs(Vermilion.Data.Users) do
				if(k.SteamID == tSteamID) then
					table.RemoveByValue(Vermilion.Data.Users, k)
					MODULE:NetStart("VUserDataList")
					local tab = {}
					for i,k in pairs(Vermilion.Data.Users) do
						table.insert(tab, { Name = k.Name, Rank = k.Rank, SteamID = k.SteamID })
					end
					net.WriteTable(tab)
					net.Send(vplayer)
					MODULE:NetStart("VGetUserData")
					net.WriteBoolean(false)
					net.Send(vplayer)
					return
				end
			end
		end
	end)



	//spawncamp prevention
	self:AddHook("PlayerSpawn", "AntiSpawnCamp", function(vplayer)
		if(MODULE:GetData("enable_spawncamp_protection", false, true)) then
			vplayer:GodEnable()
			timer.Simple(MODULE:GetData("spawncamp_spawn_inv_time", 20, true), function()
				if(IsValid(vplayer)) then
					vplayer:GodDisable()
				end
			end)
		end
	end)
	
	
	self:AddDataChangeHook("forced_menu_keybind", "FMKB_Key", function(value)
		VToolkit:SetGlobalValue("FMKB_Key", value)
	end)
	self:AddDataChangeHook("forced_menu_enabled", "FMKB_Enabled", function(value)
		VToolkit:SetGlobalValue("FMKB_Enabled", value)
	end)
	VToolkit:SetGlobalValue("FMKB_Enabled", MODULE:GetData("forced_menu_enabled", false, true))
	VToolkit:SetGlobalValue("FMKB_Key", MODULE:GetData("forced_menu_keybind", "0", true))

end

function MODULE:InitClient()

	self:AddHook("PlayerButtonUp", "FMKB_Check", function(ply, key)
		if(VToolkit:GetGlobalValue("FMKB_Enabled") and input.LookupBinding("vermilion_menu") == nil) then
			if(input.GetKeyName(key) == VToolkit:GetGlobalValue("FMKB_Key")) then
				RunConsoleCommand("vermilion_menu")
			end
		end
	end)

	self:AddHook("PlayerNoClip", function(vplayer, enabled)
		if(enabled) then
			return Vermilion:HasPermission("noclip")
		end
	end)

	self:NetHook("VServerGetProperties", function()
		MODULE.UpdatingGUI = true
		for i,k in pairs(net.ReadTable()) do
			for i1,k1 in pairs(options) do
				if(i == tostring(k1.Module) .. k1.Name) then
					if(k1.Type == "Combobox") then
						if(k1.SendText) then
							k1.Impl:ChooseOptionID(table.KeyFromValue(keylist, k))
						else
							k1.Impl:ChooseOptionID(k)
						end
					end
					if(k1.Type == "Checkbox") then k1.Impl:SetValue(k) end
					if(k1.Type == "Slider") then k1.Impl:SetValue(k) end
				end
			end
		end
		MODULE.UpdatingGUI = false
	end)

	self:NetHook("VGetMOTDProperties", function()
		local paneldata = Vermilion.Menu.Pages["motd"]
		local text = net.ReadString()
		local typ = net.ReadInt(32)

		paneldata.TypeCombo.Updating = true
		paneldata.TypeCombo:ChooseOptionID(typ)
		paneldata.TypeCombo.Updating = false

		paneldata.MOTDText:SetValue(text)
		paneldata.UnsavedChanges = false
	end)

	self:NetHook("VGetCommandMuting", function()
		local data = net.ReadTable()
		local paneldata = Vermilion.Menu.Pages["command_muting"]
		local panel = paneldata.Panel

		if(table.Count(paneldata.Controls) > 0) then
			for i,k in pairs(data) do
				local control = paneldata.Controls[k.Name]
				control.AllowUpdate = false
				control:SetValue(k.Value)
				control.AllowUpdate = true
			end
			return
		end

		for i,k in pairs(data) do
			local cb = VToolkit:CreateCheckBox(k.Name)
			cb:SetParent(panel)
			cb:Dock(TOP)
			local bm = 5
			if(table.Count(data) == i) then
				bm = 20
			end
			cb:DockMargin(10, 0, 10, bm)

			cb:SetParent(paneldata.Scroll)
			cb:SetValue(k.Value)
			paneldata.Controls[k.Name] = cb
			cb.AllowUpdate = true

			function cb:OnChange()
				if(not self.AllowUpdate) then return end
				MODULE:NetStart("VSetCommandMuting")
				net.WriteString(k.Name)
				net.WriteBoolean(cb:GetChecked())
				net.SendToServer()
			end
		end
	end)

	self:AddHook(Vermilion.Event.CLIENT_NewPermissionData, function()
		Vermilion.Menu.Pages["server_settings"].Panel:Clear()
		Vermilion.Menu.Pages["server_settings"].Builder(Vermilion.Menu.Pages["server_settings"].Panel, Vermilion.Menu.Pages["server_settings"])
	end)

	function MODULE:DisplayMOTD(typ, text)
		if(text == nil or text == "") then return end
		if(typ == 1) then
			for i,k in pairs(string.Split(text, "\n")) do
				Vermilion:AddNotification(k)
			end
		elseif(typ == 2) then
			local panel = VToolkit:CreateFrame(
				{
					['size'] = { 800, 600 },
					['pos'] = { (ScrW() / 2) - 400, (ScrH() / 2) - 300 },
					['closeBtn'] = true,
					['draggable'] = true,
					['title'] = "Vermilion - MOTD",
					['bgBlur'] = true
				}
			)
			local dhtml = vgui.Create("DHTML")
			dhtml:SetHTML(text)
			dhtml:Dock(FILL)
			dhtml:SetParent(panel)

			panel:MakePopup()
			panel:SetAutoDelete(true)
		elseif(typ == 3) then
			local panel = VToolkit:CreateFrame(
				{
					['size'] = { 800, 600 },
					['pos'] = { (ScrW() / 2) - 400, (ScrH() / 2) - 300 },
					['closeBtn'] = true,
					['draggable'] = true,
					['title'] = "Vermilion - MOTD",
					['bgBlur'] = true
				}
			)
			local dhtml = vgui.Create("DHTML")
			dhtml:OpenURL(text)
			dhtml:Dock(FILL)
			dhtml:SetParent(panel)

			panel:MakePopup()
			panel:SetAutoDelete(true)
		end
	end

	self:NetHook("VRequestMOTD", function()
		local text = net.ReadString()
		local typ = net.ReadInt(32)

		MODULE:DisplayMOTD(typ, text)
	end)

	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		timer.Simple(2, function()
			MODULE:NetCommand("VRequestMOTD")
		end)
	end)

	self:NetHook("VUserDataList", function()
		local paneldata = Vermilion.Menu.Pages["userdata"]
		local panel = paneldata.Panel

		paneldata.UserList:Clear()
		for i,k in pairs(net.ReadTable()) do
			local ln = paneldata.UserList:AddLine(k.Name, Vermilion:GetRankByID(k.Rank).Name)
			ln.SteamID = k.SteamID
			ln.UniqueRankID = k.Rank
		end
	end)

	local function repeatParseTree(tab, cnode)
		for i,k in pairs(tab) do
			if(istable(k)) then
				local nnode = cnode:AddNode(i)
				nnode:SetIcon("icon16/folder.png")
				repeatParseTree(k, nnode)
			else
				local tnode = cnode:AddNode(i)
				tnode:SetIcon("icon16/page.png")
				if(k == "FUNCTION") then
					tnode:SetIcon("icon16/script.png")
					tnode:AddNode("Type: function")
				elseif(k == "IMATERIAL") then
					tnode:AddNode("Type: function")
				elseif(k == "LARGE TABLE") then
					tnode:AddNode("Type: table")
					tnode:SetIcon("icon16/folder.png")
				else
					tnode:AddNode("Type: " .. type(k))
				end
				tnode:AddNode("Value: " .. tostring(k))
			end
		end
	end

	self:NetHook("VGetUserData", function()
		local paneldata = Vermilion.Menu.Pages["userdata"]
		local panel = paneldata.Panel

		if(not net.ReadBoolean()) then
			if(IsValid(paneldata.BaseNode)) then paneldata.BaseNode:Remove() end
			return
		end

		local username = net.ReadString()
		local data = net.ReadTable()

		if(IsValid(paneldata.BaseNode)) then paneldata.BaseNode:Remove() end

		paneldata.BaseNode = paneldata.Tree:AddNode(username)
		repeatParseTree(data, paneldata.BaseNode)
	end)


	Vermilion.Menu:AddCategory("server", 2)

	self:AddMenuPage({
		ID = "server_settings",
		Name = Vermilion:TranslateStr("menu:basicsettings"),
		Order = 0,
		Category = "server",
		Size = { 600, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_server")
		end,
		Builder = function(panel, paneldata)
			MODULE.UpdatingGUI = true
			paneldata.SettingsList = VToolkit:CreateCategoryList()
			paneldata.SettingsList:SetParent(panel)
			paneldata.SettingsList:SetPos(0, 0)
			paneldata.SettingsList:SetSize(600, 560)
			local sl = paneldata.SettingsList

			for i,k in SortedPairsByMemberValue(categories, "Order") do
				k.Impl = sl:Add(k.Name)
			end

			for i,k in pairs(options) do
				if(k.Type == "Combobox") then
					local panel = vgui.Create("DPanel")

					local label = VToolkit:CreateLabel(k.GuiText)
					label:SetDark(true)
					label:SetPos(10, 3 + 3)
					label:SetParent(panel)

					local nonalphabetical = k.NonAlphabetical
					if(nonalphabetical == nil) then nonalphabetical = true end

					local combobox = VToolkit:CreateComboBox(nil, nil, nonalphabetical)
					combobox:SetPos(paneldata.SettingsList:GetWide() - 230, 3)
					combobox:Dock(RIGHT)
					combobox:DockMargin(0, 2, 5, 2)
					combobox:SetParent(panel)
					for i1,k1 in pairs(k.Options) do
						combobox:AddChoice(k1)
					end
					combobox:SetWide(200)

					if(k.Incomplete) then
						local dimage = vgui.Create("DImage")
						dimage:SetImage("icon16/error.png")
						dimage:SetSize(16, 16)
						dimage:SetPos(select(1, combobox:GetPos()) - 25, 5)
						dimage:SetParent(panel)
						dimage:SetTooltip(MODULE:TranslateStr("notimpl"))
					end

					function combobox:OnSelect(index)
						if(MODULE.UpdatingGUI) then return end
						MODULE:NetStart("VServerUpdate")
						if(k.SendText) then
							net.WriteTable({{ Module = k.Module, Name = k.Name, Value = k.Options[index] }})
						else
							net.WriteTable({{ Module = k.Module, Name = k.Name, Value = index}})
						end
						net.SendToServer()
					end

					panel:SetSize(select(1, combobox:GetPos()) + combobox:GetWide() + 10, combobox:GetTall() + 5)
					panel:SetPaintBackground(false)

					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.ID == k.Category) then cat = cat1.Impl break end
					end

					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )

					panel:Dock(TOP)
					panel:SetParent(cat)

					combobox:ChooseOptionID(k.Default)

					if(k.Permission != nil) then
						combobox:SetEnabled(Vermilion:HasPermission(k.Permission))
					end
					k.Impl = combobox
				elseif(k.Type == "Checkbox") then
					local panel = vgui.Create("DPanel")

					local cb = VToolkit:CreateCheckBox(k.GuiText)
					cb:SetDark(true)
					cb:SetPos(10, 3)
					cb:SetParent(panel)

					cb:SetValue(k.Default)

					function cb:OnChange()
						if(MODULE.UpdatingGUI) then return end
						MODULE:NetStart("VServerUpdate")
						net.WriteTable({{Module = k.Module, Name = k.Name, Value = cb:GetChecked()}})
						net.SendToServer()
					end



					panel:SetSize(cb:GetWide() + 10, cb:GetTall() + 5)
					if(k.Incomplete) then
						local dimage = vgui.Create("DImage")
						dimage:SetImage("icon16/error.png")
						dimage:SetSize(16, 16)
						dimage:SetPos(select(1, cb:GetPos()) + cb:GetWide() + 25, 5)
						dimage:SetParent(panel)
						dimage:SetTooltip(MODULE:TranslateStr("notimpl"))
						panel:SetWide(panel:GetWide() + 25)
					end
					panel:SetPaintBackground(false)

					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.ID == k.Category) then cat = cat1.Impl break end
					end

					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )

					panel:Dock(TOP)
					panel:SetParent(cat)

					if(k.Permission != nil) then
						cb:SetEnabled(Vermilion:HasPermission(k.Permission))
					end
					k.Impl = cb
				elseif(k.Type == "Slider") then
					local panel = vgui.Create("DPanel")

					local slider = VToolkit:CreateSlider(k.GuiText, k.Bounds.Min, k.Bounds.Max, k.Decimals or 2)
					slider:SetPos(10, 3)
					slider:SetParent(panel)
					slider:SetWide(400)

					slider:SetValue(k.Default)

					function slider:OnValueChanged(value)
						if(MODULE.UpdatingGUI) then return end
						MODULE:NetStart("VServerUpdate")
						net.WriteTable({{ Module = k.Module, Name = k.Name, Value = math.Round(value, k.Decimals or 2) }})
						net.SendToServer()
					end

					panel:SetSize(slider:GetWide() + 10, slider:GetTall() + 5)
					panel:SetPaintBackground(false)

					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.ID == k.Category) then cat = cat1.Impl break end
					end

					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )

					panel:Dock(TOP)
					panel:SetParent(cat)

					if(k.Permission != nil) then
						slider:SetEnabled(Vermilion:HasPermission(k.Permission))
					end
					k.Impl = slider
				elseif(k.Type == "Colour") then
					-- Implement Me!
				elseif(k.Type == "NumberWang") then
					-- Implement Me!
				elseif(k.Type == "Text") then
					-- Implement Me!
				elseif(k.Type == "Button") then
					if(not Vermilion:HasPermission(k.Permission)) then continue end
					local panel = vgui.Create("DPanel")

					local btn = VToolkit:CreateButton(k.GuiText, function()
						if(k.Function != nil) then k.Function() return end
						MODULE:NetCommand(k.NetCommand)
					end)
					btn:SetPos(10, 3)
					btn:SetParent(panel)
					btn:SetSize(200, 25)

					panel:SetSize(btn:GetWide() + btn:GetX(), btn:GetY() + btn:GetTall() + 3)
					panel:SetPaintBackground(false)

					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.ID == k.Category) then cat = cat1.Impl break end
					end

					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )

					panel:Dock(TOP)
					panel:SetParent(cat)

					k.Impl = btn
				end
			end
			MODULE.UpdatingGUI = false
		end,
		OnOpen = function(panel)
			MODULE:NetCommand("VServerGetProperties")
		end
	})

	self:AddMenuPage({
		ID = "motd",
		Name = Vermilion:TranslateStr("menu:motd"),
		Order = 1,
		Category = "server",
		Size = { 500, 500 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("change_motd")
		end,
		Builder = function(panel, paneldata)
			local motdtext = VToolkit:CreateTextbox("", panel)
			motdtext:SetMultiline(true)
			motdtext:SetPos(10, 10)
			motdtext:SetSize(480, 400)
			motdtext:SetParent(panel)
			motdtext:SetUpdateOnType(true)
			paneldata.MOTDText = motdtext

			paneldata.UnsavedChanges = false

			function motdtext:OnChange()
				paneldata.UnsavedChanges = true
			end

			local typCombo = VToolkit:CreateComboBox({
				MODULE:TranslateStr("motd:std"),
				MODULE:TranslateStr("motd:html"),
				MODULE:TranslateStr("motd:url")
			}, 1, true)
			typCombo:SetParent(panel)
			typCombo:SetPos(10, 415)
			typCombo:SetSize(200, 20)
			typCombo.OnSelect = function(panel, index, value)
				typCombo.VSelectedIndex = index
				if(typCombo.VUpdating) then
					return
				end
				MODULE:NetStart("VUpdateMOTDSettings")
				net.WriteInt(index, 32)
				net.SendToServer()
			end
			paneldata.TypeCombo = typCombo

			local motdVars = VToolkit:CreateButton(MODULE:TranslateStr("motd:showvars"), function()
				local motdpanel2 = VToolkit:CreateFrame(
					{
						['size'] = { 500, 300 },
						['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 150 },
						['closeBtn'] = true,
						['draggable'] = true,
						['title'] = MODULE:TranslateStr("motd:varlist"),
						['bgBlur'] = false
					}
				)
				local varList = VToolkit:CreateList({
					cols = {
						MODULE:TranslateStr("name"),
						MODULE:TranslateStr("motd:vardesc")
					}
				})
				varList:SetPos(10, 30)
				varList:SetSize(480, 260)
				varList:SetParent(motdpanel2)

				for i,k in pairs(MODULE.MOTDVars) do
					varList:AddLine(i, k)
				end

				motdpanel2:MakePopup()
				--motdpanel2:DoModal()
				motdpanel2:SetAutoDelete(true)
			end)
			motdVars:SetPos(370, 415)
			motdVars:SetSize(120, 20)
			motdVars:SetParent(panel)

			local preview = VToolkit:CreateButton(MODULE:TranslateStr("motd:preview"), function()
				MODULE:DisplayMOTD(typCombo.VSelectedIndex, motdtext:GetValue())
			end)
			preview:SetPos(370, 445)
			preview:SetSize(120, 20)
			preview:SetParent(panel)

			local save = VToolkit:CreateButton(MODULE:TranslateStr("motd:save"), function()
				MODULE:NetStart("VUpdateMOTD")
				net.WriteString(motdtext:GetValue())
				net.SendToServer()
				paneldata.UnsavedChanges = false
			end)
			save:SetPos(370, 475)
			save:SetSize(120, 20)
			save:SetParent(panel)

			MODULE:AddHook(Vermilion.Event.MENU_CLOSING, function()
				if(paneldata.UnsavedChanges) then
					VToolkit:CreateConfirmDialog(MODULE:TranslateStr("motd:unsaved"), function()
						Vermilion.Menu:Close(true)
						paneldata.UnsavedChanges = false
					end, { Confirm = MODULE:TranslateStr("yes"), Deny = MODULE:TranslateStr("no"), Default = false })
					return false
				end
			end)

		end,
		OnOpen = function(panel)
			MODULE:NetCommand("VGetMOTDProperties")
		end
	})

	self:AddMenuPage({
		ID = "userdata",
		Name = Vermilion:TranslateStr("menu:userdata"),
		Order = 2,
		Category = "server",
		Size = { 800, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_server") and Vermilion:HasPermission("manage_userdata")
		end,
		Builder = function(panel, paneldata)
			local userList = VToolkit:CreateList({
				cols = {
					MODULE:TranslateStr("name"),
					MODULE:TranslateStr("rank")
				},
				multiselect = false
			})
			userList:SetPos(10, 30)
			userList:SetSize(250, panel:GetTall() - 40)
			userList:SetParent(panel)
			paneldata.UserList = userList

			function userList:OnRowSelected(index, line)
				MODULE:NetStart("VGetUserData")
				net.WriteString(line:GetValue(1))
				net.SendToServer()
				paneldata.DeleteBtn:SetDisabled(false)
			end

			VToolkit:CreateHeaderLabel(userList, MODULE:TranslateStr("userdata:users")):SetParent(panel)
			VToolkit:CreateSearchBox(userList)

			local tree = vgui.Create("DTree")
			tree:SetPos(270, 30)
			tree:SetSize(panel:GetWide() - tree:GetX() - 210, panel:GetTall() - 40)
			tree:SetParent(panel)
			VToolkit:CreateHeaderLabel(tree, MODULE:TranslateStr("userdata:userdata")):SetParent(panel)
			paneldata.Tree = tree


			local deleteBtn = VToolkit:CreateButton(MODULE:TranslateStr("userdata:delete"), function()
				VToolkit:CreateConfirmDialog("Really delete this userdata?", function()
						MODULE:NetStart("VDelUserData")
						net.WriteString(userList:GetSelected()[1].SteamID)
						net.SendToServer()
						paneldata.DeleteBtn:SetDisabled(true)
					end, { Confirm = "Yes", Deny = "No", Default = false })
			end)
			deleteBtn:SetPos(tree:GetX() + tree:GetWide() + 10, (panel:GetTall() - 30) / 2)
			deleteBtn:SetSize(panel:GetWide() - deleteBtn:GetX() - 10, 30)
			deleteBtn:SetParent(panel)
			deleteBtn:SetDisabled(true)
			paneldata.DeleteBtn = deleteBtn

		end,
		OnOpen = function(panel, paneldata)
			MODULE:NetCommand("VUserDataList")
			paneldata.DeleteBtn:SetDisabled(true)
		end
	})

	self:AddMenuPage({
		ID = "voip_channels",
		Name = Vermilion:TranslateStr("menu:voip_channels"),
		Order = 3,
		Category = "server",
		Size = { 600, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_server")
		end,
		Builder = function(panel)
			local label = VToolkit:CreateLabel(Vermilion:TranslateStr("under_construction"))
			label:SetFont("DermaLarge")
			label:SizeToContents()
			label:SetPos((panel:GetWide() - label:GetWide()) / 2, (panel:GetTall() - label:GetTall()) / 2)
			label:SetParent(panel)
		end
	})

	self:AddMenuPage({
		ID = "command_muting",
		Name = Vermilion:TranslateStr("menu:command_muting"),
		Order = 4,
		Category = "server",
		Size = { 600, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_server")
		end,
		Builder = function(panel, paneldata)
			local label = VToolkit:CreateLabel(MODULE:TranslateStr("muting:desc"))
			label:SetParent(panel)
			label:SetWrap(true)
			label:SetTall(label:GetTall() * 2)
			label:Dock(TOP)
			label:DockMargin(10, 10, 10, 20)

			paneldata.Controls = {}

			local scroll = vgui.Create("DScrollPanel")
			scroll:Dock(FILL)
			scroll:SetParent(panel)
			paneldata.Scroll = scroll
		end,
		OnOpen = function(panel)
			MODULE:NetCommand("VGetCommandMuting")
		end
	})
end
