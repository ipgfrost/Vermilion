--[[
 Copyright 2014 Ned Hyett, 

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
EXTENSION.Name = "Profiles"
EXTENSION.ID = "profiles"
EXTENSION.Description = "Provides server profiles"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {

}

EXTENSION.DataTypes = {}

function EXTENSION:AddType(typ, sfunc, gfunc)
	if(sfunc == nil) then
		sfunc = function() end
	end
	if(gfunc == nil) then
		gfunc = function() end
	end
	self.DataTypes[typ] = { SetupFunction = sfunc, GetFunction = gfunc }  
end

function EXTENSION:InitServer()
	self:AddHook("Vermilion_RegisteredUser", function(userTable)
		for i,k in pairs(EXTENSION.DataTypes) do
			local val = k.SetupFunction(userTable)
			if(val != nil) then
				userTable[i] = val
			end
		end
	end)
	
	self:AddType("FirstJoin", function(userTable)
		return os.time()
	end, function(userTable)
		return userTable.FirstJoin
	end)
	
	self:AddType("CumulativeDeaths", function(userTable)
		return 0
	end, function(userTable)
		return userTable.CumulativeDeaths
	end)
	
	self:AddType("CumulativeKills", function(userTable)
		return 0
	end, function(userTable)
		return userTable.CumulativeKills
	end)
	
	self:AddType("BanData", nil, function(userTable)
		return 
	end)
end

function EXTENSION:InitClient()

end

Vermilion:RegisterExtension(EXTENSION)