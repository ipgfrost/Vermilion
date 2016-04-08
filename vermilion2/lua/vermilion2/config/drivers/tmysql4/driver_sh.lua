--[[
 Copyright 2015-16 Ned Hyett

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

if(not file.Exists("bin/gmsv_tmysql4_linux.dll", "LUA") and not file.Exists("bin/gmsv_tmysql4_win32.dll", "LUA")) then
	--Vermilion.Log("Not loading tmysql4 data driver; tmysql4 DLLs are not installed!")
	return
end

DRIVER = {}
function loadTMYSQL()
	require("tmysql4")
end

if(xpcall(loadTMYSQL, function(msg)
	Vermilion.Log("Failed to load tmysql4! Did you install libmysqlclient properly?")
end)) then Vermilion.Log("Successfully loaded tmysql4!") else return end

if(SERVER) then
	AddCSLuaFile()
end

function DRIVER:GetData(name, default, set)
	
end

function DRIVER:SetData(name, value)
	
end

function DRIVER:GetModuleData(mod, name, def)
	
end

function DRIVER:SetModuleData(mod, name, val)
	
end

function DRIVER:CreateDefaultDataStructs()
	
end

function DRIVER:RestoreBackup()
	
end

function DRIVER:Load(crashOnErr)
	
end

function DRIVER:Save(verbose)
	
end




Vermilion:RegisterDriver("tmysql4", DRIVER)
DRIVER = nil