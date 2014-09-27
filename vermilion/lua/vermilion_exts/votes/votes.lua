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
EXTENSION.Name = "Votes"
EXTENSION.ID = "votes"
EXTENSION.Description = "Allow players to vote on things."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"call_vote",
	"participate_in_vote",
	"vote_management"
}
EXTENSION.PermissionDefinitions = {
	["call_vote"] = "This player is allowed to call a vote.",
	["participate_in_vote"] = "This player is allowed to answer a vote created by another user.",
	["vote_management"] = "This player is able to see the Voting tab on the Vermilion Menu and change the settings within."
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"call_vote"
		}
	},
	{ "player", {
			"participate_in_vote"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VCallVote"
}

EXTENSION.VoteTypes = {}

EXTENSION.VoteInProgress = false
EXTENSION.VoteType = nil
EXTENSION.VoteResults = nil
EXTENSION.Voters = nil
EXTENSION.VoteCaller = nil
EXTENSION.VoteExpires = nil

EXTENSION.Checkboxes = {}

function EXTENSION:AddVoteType(name, createFunc, sfunc, predictor)
	if(self.VoteTypes[name] != nil) then
		Vermilion.Log("Overwriting vote type " .. name .. "!")
	end
	EXTENSION.VoteTypes[name] = { Create = createFunc, Success = sfunc, Predictor = predictor }
end


function EXTENSION:BroadcastVote(typ, text, valid_time, caller, data)
	self.VoteInProgress = true
	self.VoteType = typ
	self.VoteResults = { Yes = 0, No = 0 }
	self.Voters = {}
	self.VoteCaller = caller:GetName()
	self.VoteExpires = os.time() + valid_time
	net.Start("VCallVote")
	net.WriteString(text)
	net.WriteString(tostring(valid_time))
	net.WriteString(caller:GetName())
	net.Send(Vermilion:GetUsersWithPermission("participate_in_vote"))
	timer.Simple(valid_time + 1, function()
		EXTENSION.VoteInProgress = false
		local win = EXTENSION.VoteResults.Yes > EXTENSION.VoteResults.No
		if(win) then
			Vermilion:SendNotify(Vermilion:GetUsersWithPermission("participate_in_vote"), "Vote succeeded with " .. tostring(math.Round((EXTENSION.VoteResults.Yes / (EXTENSION.VoteResults.Yes + EXTENSION.VoteResults.No)) * 100, 1)) .. "% of players saying yes.")
			EXTENSION.VoteTypes[typ].Success(data)
		else
			if((EXTENSION.VoteResults.Yes + EXTENSION.VoteResults.No) == 0) then
				Vermilion:BroadcastNotify("Vote failed because nobody responded to the vote.")
				return
			end
			Vermilion:SendNotify(Vermilion:GetUsersWithPermission("participate_in_vote"), "Vote failed with " .. tostring(math.Round((EXTENSION.VoteResults.No / (EXTENSION.VoteResults.Yes + EXTENSION.VoteResults.No)) * 100, 1)) .. "% of players saying no.")
		end
	end)
end

function EXTENSION:InitServer()


	EXTENSION:AddVoteType("map", function(data) 
		if(table.Count(data) < 1) then return false, "Syntax: <map>" end
		if(not file.Exists("maps/" .. data[1] .. ".bsp", "GAME")) then return false, "Map does not exist!" end
		if(not EXTENSION:GetData("vote_map", true)) then return false, "This vote type is disabled." end
		return "Change level to " .. data[1] .. "?"
	end, function(data)
		RunConsoleCommand("vermilion_changelevel", data[1], 60)
	end, function(pos, current, all)
		if(pos == 2) then
			if(Vermilion:GetExtension("maps") != nil) then
				local tab = {}
				for i,k in pairs(Vermilion:GetExtension("maps").MapCache) do
					if(string.StartWith(string.lower(k[1]), string.lower(current))) then
						table.insert(tab, k[1])
					end
				end
				return tab
			end
		end
	end)
		
	EXTENSION:AddVoteType("ban", function(data)
		if(table.Count(data) < 2) then return false, "Syntax: <player> <time in minutes>" end
		if(Crimson.LookupPlayerByName(data[1]) == nil) then return false, Vermilion.Lang.NoSuchPlayer end
		if(tonumber(data[2]) == nil) then return false, "That isn't a number!" end
		if(not EXTENSION:GetData("vote_ban", true)) then return false, "This vote type is disabled." end
		return "Ban " .. data[1] .. " from the server for " .. tonumber(data[2]) .. " minutes?"
	end, function(data)
		Vermilion:BanPlayerFor(data[1], nil, "Votebanned", 0, 0, 0, 0, 0, tonumber(data[2]), 0)
	end, function(pos, current, all)
		if(pos == 2) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	EXTENSION:AddVoteType("unban", function(data)
		if(table.Count(data) < 1) then return false, "Syntax: <player>" end
		local has = false
		for i,k in pairs(Vermilion:GetModuleData("bans", "bans", {})) do
			if(Vermilion:GetUserSteamID(k[1]).Name == data[1]) then has = true break end
		end
		if(not has) then return false, "This player hasn't been banned." end
		if(not EXTENSION:GetData("vote_unban", true)) then return false, "This vote type is disabled." end
		return "Unban " .. data[1] .. "?"
	end, function(data)
		Vermilion:UnbanPlayer(Vermilion:GetUser(data[1]).SteamID)
	end)

	EXTENSION:AddVoteType("kick", function(data)
		if(table.Count(data) < 1) then return false, "Syntax: <player>" end
		if(Crimson.LookupPlayerByName(data[1]) == nil) then return false, Vermilion.Lang.NoSuchPlayer end
		if(not EXTENSION:GetData("vote_kick", true)) then return false, "This vote type is disabled." end
		return "Kick " .. data[1] .. " from the server?"
	end, function(data)
		local tplayer = Crimson.LookupPlayerByName(data[1])
		if(not IsValid(tplayer)) then return end
		Vermilion:BroadcastNotify(data[1] .. " was kicked by Console: Votekicked", 10, VERMILION_NOTIFY_ERROR)
		tplayer:Kick("Kicked by Console: Votekicked")
	end, function(pos, current, all)
		if(pos == 2) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	EXTENSION:AddVoteType("playsound", function(data)
		if(table.Count(data) < 1) then return false, "Syntax: <path>" end
		if(not file.Exists("sound/" .. data[1], "GAME")) then return false, "Sound does not exist." end
		if(not EXTENSION:GetData("vote_playsound", true)) then return false, "This vote type is disabled." end
		return "Play " .. data[1] .. " to all players?"
	end, function(data)
		Vermilion:BroadcastSound(data[1], "BaseSound", false, 100)
	end)
	
	EXTENSION:AddVoteType("playstream", function(data)
		if(table.Count(data) < 1) then return false, "Syntax: <url>" end
		if(not EXTENSION:GetData("vote_playstream", true)) then return false, "This vote type is disabled." end
		return "Play " .. data[1] .. " to all players?"
	end, function(data)
		Vermilion:BroadcastStream(data[1], "BaseSound", false, 100)
	end)
	
	EXTENSION:AddVoteType("stopsound", function(data)
		if(not EXTENSION:GetData("vote_stopsound", true)) then return false, "This vote type is disabled." end
		return "Stop playing sounds?"
	end, function(data)
		net.Start("VStopSound")
		net.WriteString("BaseSound")
		net.Broadcast()
	end)

	
	Vermilion:AddChatCommand("callvote", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "call_vote")) then
			if(EXTENSION.VoteInProgress) then
				log("There is already a vote in progress. Please wait until it has finished.", VERMILION_NOTIFY_ERROR)
				return
			end
			local typ = text[1]
			if(EXTENSION.VoteTypes[typ] == nil) then
				log("No such vote type.", VERMILION_NOTIFY_ERROR)
				local str = table.concat(table.GetKeys(EXTENSION.VoteTypes), ", ")
				log("Valid vote types: " .. str, 15)
				return
			end
			local tcopy = table.Copy(text)
			table.remove(tcopy, 1)
			local vtext, pars = EXTENSION.VoteTypes[typ].Create(tcopy)
			if(not vtext) then
				log("Invalid parameters for this vote type!", VERMILION_NOTIFY_ERROR)
				log(pars)
				return
			end
			EXTENSION:BroadcastVote(typ, vtext, 30, sender, tcopy)
		end
	end, "<type> <data>")
	
	Vermilion:AddChatPredictor("callvote", function(pos, current, all)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(EXTENSION.VoteTypes) do
				if(string.StartWith(string.lower(i), string.lower(current))) then
					table.insert(tab, i)
				end
			end
			return tab
		end
		if(pos > 1) then
			if(EXTENSION.VoteTypes[all[1]] != nil) then
				if(EXTENSION.VoteTypes[all[1]].Predictor != nil) then
					return EXTENSION.VoteTypes[all[1]].Predictor(pos, current, all)
				end
			end
		end
	end)
	
	self:AddHook("ShowHelp", function(vplayer)
		if(EXTENSION.VoteInProgress and not table.HasValue(EXTENSION.Voters, vplayer:SteamID())) then
			EXTENSION.VoteResults.Yes = EXTENSION.VoteResults.Yes + 1
			table.insert(EXTENSION.Voters, vplayer:SteamID())
		end
	end)
	
	self:AddHook("ShowTeam", function(vplayer)
		if(EXTENSION.VoteInProgress and not table.HasValue(EXTENSION.Voters, vplayer:SteamID())) then
			EXTENSION.VoteResults.No = EXTENSION.VoteResults.No + 1
			table.insert(EXTENSION.Voters, vplayer:SteamID())
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_POST, "AddGui1", function()
		if(Vermilion:GetExtension("server_manager") != nil) then
			local mgr = Vermilion:GetExtension("server_manager")
			for i,k in pairs(EXTENSION.VoteTypes) do
				mgr:AddOption("votes", "vote_" .. i, "Enable " .. i .. " votes", "Checkbox", "Votes", 35, true, "vote_management")
			end
		end
	end)
	
end

function EXTENSION:InitClient()
	
	self:NetHook("VCallVote", function()
		local text = net.ReadString()
		local time = tonumber(net.ReadString())
		local ttext = "VOTE - Called by " .. net.ReadString() .. "\n\n" .. text .. "\n\n" .. input.LookupBinding("gm_showhelp") .. " - Yes | " .. input.LookupBinding("gm_showteam") .. " - No"
		EXTENSION.NotificationUID = Vermilion:GetExtension("notifications"):AddNotify(ttext, time, NOTIFY_HINT, true)
		EXTENSION.VoteInProgress = true
		timer.Simple(time, function()
			EXTENSION.VoteInProgress = false
		end)
	end)
		
	self:AddHook("PlayerBindPress", function(vplayer, bind, pressed)
		if((bind == "gm_showhelp" or bind == "gm_showteam") and pressed) then
			if(EXTENSION.VoteInProgress or true) then
				Vermilion:GetExtension("notifications"):CancelNotify(EXTENSION.NotificationUID)
				EXTENSION.VoteInProgress = false
				RunConsoleCommand(bind)
				return true
			end
		end
	end)

end

Vermilion:RegisterExtension(EXTENSION)