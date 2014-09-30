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
VERMILION_NOTIFY_GENERIC = -1
VERMILION_NOTIFY_ERROR = -2
VERMILION_NOTIFY_UNDO = -3
VERMILION_NOTIFY_HINT = -4
VERMILION_NOTIFY_CLEANUP = -5

NOTIFY_GENERIC = 0
NOTIFY_ERROR = 1
NOTIFY_UNDO = 2
NOTIFY_HINT = 3
NOTIFY_CLEANUP = 4

include("vermilion/server/server_utils.lua")
include("vermilion/server/spawn_fix.lua")
include("vermilion/server/player_meta.lua")
include("vermilion/server/server_network.lua")
include("vermilion/server/chat.lua")

local resources = {
	"sound/buttons/lever5.wav",
	"sound/alarms/klaxon1.wav"
}

for i,k in pairs(resources) do
	resource.AddSingleFile(k)
end

util.AddNetworkString("VHTMLMOTD")

Vermilion.MOTDKeywords = {}

function Vermilion:AddMOTDKeyword(word, desc, replacementFunc)
	if(self.MOTDKeywords[word] != nil) then
		self.Log("Warning: overwriting MOTD keyword " .. word .. "!")
	end
	self.MOTDKeywords[word] = { Description = desc, Function = replacementFunc }
end

Vermilion:AddMOTDKeyword("servername", "The host name of the server.", function() return GetHostName() end)
Vermilion:AddMOTDKeyword("activeplayers", "The number of players active on the server.", function() return table.Count(player.GetAll()) end)
Vermilion:AddMOTDKeyword("maxplayers", "The maximum number of players that can be on the server.", function() return game.MaxPlayers() end)
Vermilion:AddMOTDKeyword("map", "The name of the current map.", function() return game.GetMap() end)
Vermilion:AddMOTDKeyword("vermilion_version", "The version of the Vermilion core engine.", function() return Vermilion.GetVersion() end)
Vermilion:AddMOTDKeyword("gamemode", "The name of the current gamemode.", function() return string.SetChar(engine.ActiveGamemode(), 1, string.upper(string.GetChar(engine.ActiveGamemode(), 1))) end)
Vermilion:AddMOTDKeyword("time", "The date formatted as h:m:s am/pm on d/m/y", function() return os.date("%I:%M:%S %p on %d/%m/%Y") end)
Vermilion:AddMOTDKeyword("server_os", "The name of the server operating system.", function()
	if(system.IsWindows()) then
		return "Windows"
	elseif(system.IsOSX()) then
		return "OS X"
	elseif(system.IsLinux()) then
		return "Linux"
	end
end)
Vermilion:AddMOTDKeyword("gmod_version_raw", "Get the raw GMod version number.", function() return VERSION end)
Vermilion:AddMOTDKeyword("gmod_version", "Get the nice GMod version number.", function() return VERSIONSTR end)
Vermilion:AddMOTDKeyword("gmod_branch", "Get the active GMod branch.", function() return BRANCH end)
Vermilion:AddMOTDKeyword("vermilion_menu_nag", "Default nag asking the player to bind a key to the Vermilion Menu.", function() return "Please bind a key to \"vermilion_menu\" to access many helpful features!" end)
Vermilion:AddMOTDKeyword("player_rank", "The rank of the joining player.", function(vplayer) return Vermilion.Ranks[Vermilion:GetRank(vplayer)] end)
Vermilion:AddMOTDKeyword("player_team", "The team of the joining player.", function(vplayer) return vplayer:Team() end)
Vermilion:AddMOTDKeyword("player_steamid", "The SteamID of the joining player.", function(vplayer) return vplayer:SteamID() end)
Vermilion:AddMOTDKeyword("player_steamid64", "The 64-bit SteamID of the joining player.", function(vplayer) return vplayer:SteamID64() end)
Vermilion:AddMOTDKeyword("player_name", "The name of the joining player.", function(vplayer) return vplayer:GetName() end)
Vermilion:AddMOTDKeyword("player_ip", "The IP Address of the joining player.", function(vplayer) return vplayer:IPAddress() end)
Vermilion:AddMOTDKeyword("player_is_admin", "Returns \"are\" or \"are not\" depending if the joining player is an admin.", function(vplayer) if(vplayer:IsAdmin()) then return "are" else return "are not" end end)
Vermilion:AddMOTDKeyword("player_is_listen_host", "Returns \"are\" or \"are not\" depending if the joining player is the listen host.", function(vplayer) if(vplayer:IsListenServerHost()) then return "are" else return "are not" end end)
Vermilion:AddMOTDKeyword("player_is_super_admin", "Returns \"are\" or \"are not\" depending if the joining player is a superadmin.", function(vplayer) if(vplayer:IsSuperAdmin()) then return "are" else return "are not" end end)
Vermilion:AddMOTDKeyword("player_is_admin", "Returns \"are\" or \"are not\" depending if the joining player is an admin.", function(vplayer) if(vplayer:IsAdmin()) then return "are" else return "are not" end end)
Vermilion:AddMOTDKeyword("player_ping", "The ping of the joining player.", function(vplayer) return vplayer:Ping() end)
Vermilion:AddMOTDKeyword("player_suit", "The suit charge level of the joining player.", function(vplayer) return vplayer:Armor() end)
Vermilion:AddMOTDKeyword("player_health", "The health level of the joining player.", function(vplayer) return vplayer:Health() end)



Vermilion:RegisterHook("PlayerInitialSpawn", "Advertise", function(vplayer)
	timer.Simple( 1, function() 
		net.Start("Vermilion_Client_Activate")
		net.WriteTable(Vermilion.InfoStores)
		net.Send(vplayer)
	end)
	if(Vermilion:GetExtension("geoip") != nil and not vplayer:IsBot()) then
		if(not Vermilion:HasUser(vplayer)) then
			Vermilion.GetGeoIPForPlayer(vplayer, function(tab)
				Vermilion:BroadcastNotify(string.format(Vermilion.Lang.JoinedServerFirstGeoIP, vplayer:GetName(), tab['country_name']))
				vplayer.Vermilion_Location = tab['country_code']
				vplayer:SetNWString("Country_Code", tab['country_code'])
				timer.Simple(5, function()
					Vermilion:GetUser(vplayer).CountryCode = tab['country_code']
					Vermilion:GetUser(vplayer).CountryName = tab['country_name']
				end)
			end, function() 
				local vuser = Vermilion:GetUser(vplayer)
				if(vuser != nil) then
					vplayer.Vermilion_Location = vuser.CountryCode
					vplayer:SetNWString("Country_Code", vuser.CountryCode)
				end
			end)
			Vermilion:AddUser(vplayer:GetName(), vplayer:SteamID())
			vplayer:SetNWString("Vermilion_Rank", Vermilion:GetUser(vplayer):GetRank().Name)
			vplayer:SetNWString("Vermilion_Identify_Admin", Vermilion:HasPermission(vplayer, "identify_as_admin"))
			if(not Vermilion:OwnerExists() and (game.SinglePlayer() or vplayer:IsListenServerHost())) then
				Vermilion.Log(string.format(Vermilion.Lang.SettingOwner, vplayer:GetName()))
				Vermilion:GetUser(vplayer):SetRank("owner")
			end
			
		else
			Vermilion.GetGeoIPForPlayer(vplayer, function(tab)
				Vermilion:BroadcastNotify(string.format(Vermilion.Lang.JoinedServerGeoIP, vplayer:GetName(), tab['country_name']))
				vplayer.Vermilion_Location = tab['country_code']
				vplayer:SetNWString("Country_Code", tab['country_code'])
				timer.Simple(5, function()
					Vermilion:GetUser(vplayer).CountryCode = tab['country_code']
					Vermilion:GetUser(vplayer).CountryName = tab['country_name']
				end)
			end, function()
				local vuser = Vermilion:GetUser(vplayer)
				if(vuser != nil) then
					vplayer.Vermilion_Location = vuser.CountryCode
					vplayer:SetNWString("Country_Code", vuser.CountryCode)
				end
			end)
			vplayer:SetNWString("Vermilion_Rank", Vermilion:GetUser(vplayer):GetRank().Name)
			vplayer:SetNWString("Vermilion_Identify_Admin", Vermilion:HasPermission(vplayer, "identify_as_admin"))
			if(not Vermilion:OwnerExists() and (game.SinglePlayer() or vplayer:IsListenServerHost())) then
				Vermilion.Log(string.format(Vermilion.Lang.SettingOwner, vplayer:GetName()))
				Vermilion:GetUser(vplayer):SetRank("owner")
			end
		end
	else
		if(not Vermilion:HasUser(vplayer)) then
			Vermilion:BroadcastNotify(string.format(Vermilion.Lang.JoinedServerFirst, vplayer:GetName()))
			Vermilion:AddUser(vplayer:GetName(), vplayer:SteamID())
			vplayer:SetNWString("Vermilion_Rank", Vermilion:GetUser(vplayer):GetRank().Name)
			vplayer:SetNWBool("Vermilion_Identify_Admin", Vermilion:HasPermission(vplayer, "identify_as_admin"))
			if(not Vermilion:OwnerExists() and (game.SinglePlayer() or vplayer:IsListenServerHost())) then
				Vermilion.Log(string.format(Vermilion.Lang.SettingOwner, vplayer:GetName()))
				Vermilion:GetUser(vplayer):SetRank("owner")
			end
		else
			if(not Vermilion:OwnerExists() and (game.SinglePlayer() or vplayer:IsListenServerHost())) then
				Vermilion.Log(string.format(Vermilion.Lang.SettingOwner, vplayer:GetName()))
				Vermilion:GetUser(vplayer):SetRank("owner")
			end
			Vermilion:BroadcastNotify(string.format(Vermilion.Lang.JoinedServer, vplayer:GetName()))
			vplayer:SetNWString("Vermilion_Rank", Vermilion:GetUser(vplayer):GetRank().Name)
			vplayer:SetNWBool("Vermilion_Identify_Admin", Vermilion:HasPermission(vplayer, "identify_as_admin"))
		end
	end
	
	
	timer.Simple(2, function()
		if(not Vermilion:OwnerExists() and not Vermilion:GetModuleData("server_manager", "disable_owner_nag", false)) then
			Vermilion:SendNotify(vplayer, "No owner exists for this server!", 15, VERMILION_NOTIFY_ERROR)
			Vermilion:SendNotify(vplayer, "If you are the owner of the server, please type 'vermilion_setrank \"" .. vplayer:GetName() .. "\" owner' into the DEDICATED SERVER console!", 15, VERMILION_NOTIFY_ERROR)
			Vermilion:SendNotify(vplayer, "You can disable this notification in the Server Settings tab of the Vermilion Menu.", 15, VERMILION_NOTIFY_ERROR)
		end
		Vermilion:SendMOTD(vplayer)
	end)
end)

function Vermilion:SendMOTD(vplayer)
	local motd = Vermilion:GetModuleData("server_manager", "motd", "Welcome to %servername%!\nThis server is running the Vermilion Server Administration Tool!\nBe on your best behaviour!")
	if(Vermilion:GetModuleData("server_manager", "motdisurl", false)) then
		net.Start("VHTMLMOTD")
		net.WriteBit(true)
		net.WriteString(motd)
		net.Send(vplayer)
		return
	end
	for i,k in pairs(Vermilion.MOTDKeywords) do
		if(string.find(motd, "%" .. i .. "%", 1, true)) then
			motd = string.Replace(motd, "%" .. i .. "%", tostring(k.Function(vplayer)))
		end
	end
	if(Vermilion:GetModuleData("server_manager", "motdishtml", false)) then
		net.Start("VHTMLMOTD")
		net.WriteBit(true)
		net.WriteString(motd)
		net.Send(vplayer)
		return
	end
	for i,k in pairs(string.Explode("\n", motd)) do
		Vermilion:SendNotify(vplayer, k, 10)
	end
end

function Vermilion:GetPermissionDefinition(permission)
	return hook.Call("VDefinePermission", permission)
end