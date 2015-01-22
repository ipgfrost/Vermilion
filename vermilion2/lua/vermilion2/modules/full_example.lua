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

--[[
	This file will never be loaded by Vermilion and is here to serve as a reference file for all the possible properties that Vermilion
	will be looking for in a module file.
]]--

--[[
	MODULE is defined by Vermilion before loading the file. It is in the global scope.
	
	It will only be defined by Vermilion in your init.lua file. It will be nil outside
	of the init.lua file where you must define it as a local variable yourself.
]]--

MODULE.Name = "Base" -- human readable name
MODULE.ID = "base" -- machine unique id (usually the same as the module folder)
MODULE.Description = "Something" -- a short description of the module (or a witty placeholder)
MODULE.Author = "Ned" -- your name / online nickname
MODULE.Permissions = { -- a list of permissions that Vermilion should load. Note that you cannot dynamically add and remove permissions.
	"your_permission_name_here",
	"my_new_permission"
}


function MODULE:InitServer()
	
end

function MODULE:InitClient()
	
end

Vermilion:RegisterModule(MODULE)