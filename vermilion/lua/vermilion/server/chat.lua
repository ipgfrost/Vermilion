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

Vermilion.ChatCommands = {}


--[[ 
	Add a chat command to the Vermilion interpreter
	
	@param activator (string) - what the player has to type into chat to activate the command
	@param func (function with params: sender (player), text (table) space split input) - the command handler
]]--
function Vermilion:AddChatCommand(activator, func)
	if(self.ChatCommands[activator] != nil) then
		self.Log("Chat command " .. activator .. " has been overwritten!")
	end
	self.ChatCommands[activator] = func
end



Vermilion:RegisterHook("PlayerSay", "Say1", function(vplayer, text, teamChat)
	if(string.StartWith(text, "!")) then
		local commandText = string.sub(text, 2)
		local parts = string.Explode(" ", commandText, false)
		local commandName = parts[1]
		local command = Vermilion.ChatCommands[commandName]
		if(command != nil) then
			table.remove(parts, 1)
			local success, err = pcall(command, vplayer, parts)
			if(not success) then 
				Vermilion:SendNotify(vplayer, "Command failed with an error " .. tostring(err), 25, NOTIFY_ERROR) 
				Vermilion:Vox("command failed with an error", vplayer)
			end
		else 
			Vermilion:SendNotify(vplayer, "No such command '" .. commandName .. "'", 5, NOTIFY_ERROR)
		end
		return ""
	end
end)