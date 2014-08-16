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
local startTime = os.clock()
Vermilion = {}

-- Other addons shouldn't access anything stored here.
Vermilion.internal = {}

Vermilion.EVENT_EXT_LOADED = "Vermilion_LoadedEXT"


local preloadFiles = {
	"autorun/server/von.lua",
	"vermilion/crimson_gmod.lua",
	"vermilion/vermilion_shared.lua",
	"vermilion/vermilion_config.lua",
	"vermilion/vermilion_server.lua"
}

local csLuaFiles = {
	"vermilion/crimson_gmod.lua",
	"autorun/client/vermilion_autorun.lua",
	"vermilion/vermilion_config_client.lua",
	"vermilion/vermilion_shared.lua",
	"vermilion/vermilion_client.lua"
}

-- Internal logging function
function Vermilion.Log( str ) 
	print("[Vermilion] " .. tostring(str))
	file.Append("vermilion/vermilion_server_log.txt", util.DateStamp() .. tostring(str) .. "\n")
end

print("Vermilion: starting...")

for i, luaFile in pairs(csLuaFiles) do
	AddCSLuaFile(luaFile)
end
for i, luaFile in pairs(preloadFiles) do
	include(luaFile)
end
Vermilion:LoadExtensions()
Vermilion.Log("Started in " .. tostring(math.Round(os.clock() - startTime, 4)) .. "ms!")