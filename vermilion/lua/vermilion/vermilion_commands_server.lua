--[[
 The MIT License

 Copyright 2014 Ned Hyett.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
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