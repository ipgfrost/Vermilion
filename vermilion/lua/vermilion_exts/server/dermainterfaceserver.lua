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
EXTENSION.Name = "Derma Interface - ServerSide"
EXTENSION.ID = "dermainterfaceserver"
EXTENSION.Description = "Gives Vermilion a Derma interface"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}
EXTENSION.Tabs = {}

function EXTENSION:InitServer()
	util.AddNetworkString("Vermilion_TabRequest")
	util.AddNetworkString("Vermilion_TabResponse")
	util.AddNetworkString("VPermissionsList")
	
	net.Receive("Vermilion_TabRequest", function(len, vplayer)
		net.Start("Vermilion_TabResponse")
		local allowedTabs = {}
		for i,k in ipairs(EXTENSION.Tabs) do
			if(k[2] == nil) then
				table.insert(allowedTabs, k[1])
			elseif(Vermilion:HasPermission(vplayer, k[2])) then
				table.insert(allowedTabs, k[1])
			end
		end
		net.WriteTable(allowedTabs)
		net.Send(vplayer)
	end)
	
	function Vermilion:AddInterfaceTab( tabName, permission )
		for i,k in pairs(EXTENSION.Tabs) do
			if(k[1] == tabName) then
				return
			end
		end
		table.insert(EXTENSION.Tabs, { tabName, permission })
	end
end

Vermilion:RegisterExtension(EXTENSION)