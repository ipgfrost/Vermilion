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

concommand.Add("vermilion_saveusers", function(vplayer, cmd, args, fullstring)
	if(Vermilion:HasPermissionVerbose(vplayer, "cmd_save_users")) then
		Vermilion:SaveUserStore()
	end
end)

concommand.Add("vermilion_reloadusers", function(vplayer, cmd, args, fullstring)
	if(Vermilion:HasPermissionVerbose(vplayer, "cmd_reload_users")) then
		Vermilion:LoadUserStore()
	end
end)

concommand.Add("vermilion_adduser", function(vplayer, cmd, args, fullstring)
	if(Vermilion:HasPermissionVerbose(vplayer, "cmd_add_user")) then
		Vermilion:AddPlayer(vplayer)
	end
end)

concommand.Add("vermilion_addpermission", function(vplayer, cmd, args, fullstring)
	if(Vermilion:HasPermissionVerbose(vplayer, "cmd_addpermission")) then
		
	end
end)

concommand.Add("vermilion_listexts", function(vplayer, cmd, args, fullstring)
	for i,k in pairs(Vermilion.Extensions) do
		Vermilion.Log(i)
	end
end)

Vermilion:AddChatCommand("listexts", function(sender, text)
	Vermilion:SendNotify(sender, "Installed Extensions: " , 10, NOTIFY_HINT)
	for i,k in pairs(Vermilion.Extensions) do
		Vermilion:SendNotify(sender, i, 10, NOTIFY_HINT)
	end
end)

Vermilion:AddChatCommand("addresource", function(sender, text)
	if(Vermilion:HasPermissionError(sender, "vermilion_add_resource")) then
		local str = table.concat(text, " ", 1, table.Count(text))
		resource.AddSingleFile(str)
		Vermilion:SendNotify(sender, str .. " has been added to the client resources!")
	end
end)