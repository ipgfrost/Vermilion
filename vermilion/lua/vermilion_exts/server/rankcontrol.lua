-- The MIT License
--
-- Copyright 2014 Ned Hyett.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local EXTENSION = Vermilion:makeExtensionBase()
EXTENSION.Name = "Rank Controls"
EXTENSION.ID = "rankcontrol"
EXTENSION.Description = "Allows for ranks to be controlled"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"set_rank",
	"add_permission",
	"remove_permission",
	"create_rank",
	"destroy_rank",
	"reset_ranks"
}

function EXTENSION:init()
	
	Vermilion:addChatCommand("resetranks", function(sender, text)
		if(Vermilion:hasPermissionVerboseChat(sender, "reset_ranks")) then
			Vermilion:resetPerms()
			Vermilion:savePerms()
			Vermilion:sendNotify(sender, "Ranks reset to defaults!", 5, NOTIFY_GENERIC)
		end
	end)
	
	concommand.Add("vermilion_resetranks", function(vplayer, cmd, args, fullstring)
		if(Vermilion:hasPermissionVerbose(vplayer, "reset_ranks")) then
			Vermilion:resetPerms()
			Vermilion:savePerms()
			Vermilion.log("Ranks reset!")
		end
	end)
	
	Vermilion:addChatCommand("getrank", function(sender, text)
		if(Crimson.tableLen(text) == 0) then
			Vermilion:sendNotify(sender, tostring(Vermilion:getRank(sender)) .. " => " .. tostring(Vermilion.ranks[Vermilion:getRank(sender)]), 5, NOTIFY_GENERIC)
			return
		end
		local targetPlayer = Crimson.lookupPlayerByName(text[1])
		if(targetPlayer == nil) then
			Vermilion.sendNotify(sender, "Warning: player does not exist!", 5, NOTIFY_GENERIC)
			return
		end
		Vermilion.sendNotify(sender, tostring(Vermilion:getRank(targetPlayer)) .. " => " .. tostring(Vermilion.ranks[Vermilion:getRank(targetPlayer)]), 5, NOTIFY_GENERIC)
	end)
	
	concommand.Add("vermilion_getrank", function(vplayer, cmd, args, fullstring)
		if(Crimson.tableLen(args) == 0) then
			Vermilion.log(tostring(Vermilion:getRank(vplayer)) .. " => " .. tostring(Vermilion.ranks[Vermilion:getRank(vplayer)]))
			return
		end
		local targetPlayer = Crimson.lookupPlayerByName(args[1])
		if(targetPlayer == nil) then
			Vermilion.log("Warning: player does not exist!")
			return
		end
		Vermilion.log(tostring(Vermilion:getRank(targetPlayer)) .. " => " .. tostring(Vermilion.ranks[Vermilion:getRank(targetPlayer)]))
	end, nil, "Get a user's rank.\n Args: <player>")
	
	concommand.Add("vermilion_setrank", function(vplayer, cmd, args, fullstring)
		if(Vermilion:hasPermissionVerbose(vplayer, "cmd_set_rank")) then
			if(Crimson.tableLen(args) == 1) then
				Vermilion:setRank(vplayer, args[1])
				return
			end
			local targetPlayer = Crimson.lookupPlayerByName(args[1])
			if(targetPlayer == nil) then
				Vermilion.log("Warning: player does not exist!")
				return
			end
			Vermilion:setRank(targetPlayer, args[2])
		end
	end, nil, "Set a user's rank.\n Args: <player> <rank>")
	
end

Vermilion:registerExtension(EXTENSION)