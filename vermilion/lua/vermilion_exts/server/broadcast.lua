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
EXTENSION.Name = "Broadcast Message Chat Command"
EXTENSION.ID = "broadcast"
EXTENSION.Description = "Broadcasts a hint"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"broadcast_hint"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"broadcast_hint"
		}
	}
}

function EXTENSION:InitServer()
	Vermilion:AddChatCommand("broadcast", function(sender, text)
		if(Vermilion:HasPermissionError(sender, "broadcast_hint")) then
			Vermilion:BroadcastNotify(table.concat(text, " ", 1, table.Count(text)), 10, NOTIFY_HINT)
		end
	end)
end

Vermilion:RegisterExtension(EXTENSION)