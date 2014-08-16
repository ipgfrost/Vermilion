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
EXTENSION.Name = "Configuration Importer"
EXTENSION.ID = "importer"
EXTENSION.Description = "Imports settings from other management solutions."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"importer_management"
}
EXTENSION.NetworkStrings = {
	"VImportSettings"
}

EXTENSION.PermissionTranslations = {
	["evolve"] = { Translations = {
			["Noclip access"] = {"noclip"},
			["Ban"] = {"ban", "ban_management"},
			["Permaban"] = {"ban", "ban_management"},
			["Unban"] = {"unban", "ban_management"},
			["Map changing"] = {"map_management"},
			["Decal cleanup"] = {"server_management"},
			["No limits"] = {"no_spawn_restrictions"},
			["Explode"] = {"punishment"},
			["Gag"] = {"punishment"},
			["Ignite"] = {"punishment"},
			["Imitate"] = {"punishment"},
			["Jail"] = {"punishment"},
			["Ragdoll"] = {"punishment"},
			["Rocket"] = {"punishment"},
			["Blind"] = {"punishment"},
			["Slap"] = {"punishment"},
			["Slay"] = {"punishment"},
			["Strip"] = {"punishment"},
			["Mute"] = {"punishment"},
			["Map reload"] = {"map_management"},
			["Kick"] = {"ban_management", "kick"},
			["Noclip"] = {"noclip"},
			["Unlimited ammo"] = {"unlimited_ammo"},
			["Physgun players"] = {"physgun_pickup_players"}
		}
	}
}

function EXTENSION:InitServer()
	
	self:NetHook("VImportSettings", function(vplayer)
		local errs = {}
		local typ = net.ReadString()
		if(typ == "evolve") then
			local ptranslations = EXTENSION.PermissionTranslations.evolve.Translations
			if(not file.Exists("ev_playerinfo.txt", "DATA")) then
				Vermilion:SendMessageBox(vplayer, "Evolve is not installed!")
				return
			end
			local usersTable = von.deserialize(file.Read("ev_playerinfo.txt", "DATA"))
			local ranksTable = von.deserialize(file.Read("ev_userranks.txt", "DATA"))
			for i,k in pairs(ranksTable) do
				if(not table.HasValue(Vermilion.Ranks, i)) then
					table.insert(Vermilion.Ranks, table.Count(Vermilion.Ranks) - 1, { i, {} })
					
				end
				local rankPermissions = Vermilion.RankPerms[Vermilion:LookupRank(i)][2]
				for i1,k1 in pairs(k.Privileges) do
					if(string.StartWith(k1, "@") or string.StartWith(k1, ":") or string.StartWith(k1, "#")) then
						table.insert(errs, "Permission " .. k1 .. " is a permission for a weapon/entity/tool and is incompatible with the transfer process as the Evolve addon parses the meaning backwards (Evolve uses weapon/entity/tool whitelists, Vermilion uses blacklists)!")
					else
						local translation = ptranslations[k1]
						if(translation == nil) then
							table.insert(errs, "Permission " .. k1 .. " does not have a translation to a Vermilion permission; not added!")
						else
							for i2,p in pairs(translation) do
								if(not table.HasValue(rankPermissions, p)) then table.insert(rankPermissions, p) end
							end
						end
					end
				end
				Vermilion.RankPerms[Vermilion:LookupRank(i)][2] = rankPermissions
			end
			for i,k in pairs(usersTable) do
				local user = Vermilion:GetPlayer(k.SteamID)
				if(user != nil) then
					if(k.Rank != nil) then
						user["rank"] = k.Rank
					end
				else
					if(k.Rank == nil) then
						table.insert(errs, "User " .. k.Nick .. " was not imported because they don't have a rank!")
					else
						Vermilion.UserStore[k.SteamID] = {
							["rank"] = k.Rank,
							["name"] = k.Nick
						}
					end
				end
			end
			Vermilion:SaveUserStore()
			Vermilion:SavePermissions()
		elseif(typ == "exsto") then
		
		elseif(typ == "assmod") then
		
		elseif(typ == "ulx") then
			
		end
	end)
	
end

function EXTENSION:InitClient()
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("importer", "Configuration Importer", "database_gear.png", "Import settings from other management solutions.", function(panel)
			
			
			
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)