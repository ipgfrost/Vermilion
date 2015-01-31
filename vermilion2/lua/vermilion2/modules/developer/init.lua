--[[
 Copyright 2015 Ned Hyett, 

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

MODULE.Name = "Developer Tweaks"
MODULE.ID = "developer"
MODULE.Description = "Enables developer functionality that should usually be disabled on public servers."
MODULE.Author = "Ned"
MODULE.StartDisabled = true
MODULE.Permissions = {
	"bot"
}

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "bot",
		Description = "Adds a bot",
		Syntax = "<number of bots>",
		Permissions = { "bot" },
		Function = function(sender, text, log, glog)
			local num = tonumber(text[1]) or 1
			for i=1,num,1 do
				RunConsoleCommand("bot")
			end
		end
	})
end

function MODULE:InitShared()
	include("vermilion2/modules/developer/interfacebuilder/init.lua")
end

function MODULE:InitServer()

end

function MODULE:InitClient()

end
