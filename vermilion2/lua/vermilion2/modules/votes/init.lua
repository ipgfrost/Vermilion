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

local MODULE = MODULE
MODULE.Name = "Votes"
MODULE.ID = "votes"
MODULE.Description = "Allows players to vote on things."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"participate_in_vote",
	"call_vote",
	"vote_management"
}
MODULE.PermissionDefinitions = {
	["call_vote"] = "This player is allowed to call a vote.",
	["participate_in_vote"] = "This player is allowed to answer a vote created by another user.",
	["vote_management"] = "This player is able to see the Voting tab on the Vermilion Menu and change the settings within."
}
MODULE.RankPermissions = {
	{ "admin", {
			"call_vote",
			"participate_in_vote"
		}
	},
	{ "player", {
			"participate_in_vote"
		}
	}
}
MODULE.NetworkStrings = {
	"CallVote"
}

MODULE.VoteTypes = {}

MODULE.VoteInProgress = false
MODULE.VoteType = nil
MODULE.VoteResults = nil
MODULE.Voters = nil
MODULE.VoteCaller = nil
MODULE.VoteExpires = nil
MODULE.VoteWindow = nil

MODULE.Checkboxes = {}

function MODULE:AddVoteType(name, createFunc, sfunc, predictor, localisationString)
	if(self.VoteTypes[name] != nil) then
		Vermilion.Log("Overwriting vote type " .. name .. "!")
	end
	self.VoteTypes[name] = { Create = createFunc, Success = sfunc, Predictor = predictor, LocalisationString = localisationString }
end

function MODULE:RegisterChatCommands()

	Vermilion:AddChatCommand({
		Name = "callvote",
		Description = "Start a vote",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:callvote:syntax", nil, vplayer) end,
		CanMute = true,
		Permissions = { "call_vote" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(MODULE.VoteTypes) do
					if(string.StartWith(string.lower(i), string.lower(current))) then
						table.insert(tab, i)
					end
				end
				return tab
			elseif(pos > 1) then
				if(MODULE.VoteTypes[all[1]] != nil) then
					if(MODULE.VoteTypes[all[1]].Predictor != nil) then
						return MODULE.VoteTypes[all[1]].Predictor(pos, current, all)
					end
				end
			end
		end,
		Function = function(sender, text, log, glog)
			if(MODULE.VoteInProgress) then
				log("votes:inprogress", nil, NOTIFY_ERROR)
				return
			end
			local typ = text[1]
			if(MODULE.VoteTypes[typ] == nil) then
				log("votes:notype", nil, NOTIFY_ERROR)
				local str = table.concat(table.GetKeys(MODULE.VoteTypes), ", ")
				log("votes:validtypes", { str }, 15)
				return
			end
			if(not MODULE:GetData("vote_" .. typ, true, true)) then
				log("votes:disabled", NOTIFY_ERROR)
				return
			end
			local tcopy = table.Copy(text)
			table.remove(tcopy, 1)
			local vtext, data = MODULE.VoteTypes[typ].Create(tcopy, sender, log)
			if(not vtext) then
				return
			end
			MODULE:BroadcastVote(typ, vtext, data, 30, sender, tcopy)
		end
	})

end

function MODULE:InitShared()

	MODULE:AddVoteType("map", function(data, sender, log)
		if(table.Count(data) < 1) then log("votes:maps:syntax", nil, NOTIFY_ERROR) return end
		if(not file.Exists("maps/" .. data[1] .. ".bsp", "GAME")) then log("votes:maps:dne", nil, NOTIFY_ERROR) return end
		return "votes:maps:question", { data[1] }
	end, function(data)
		RunConsoleCommand("vermilion", "changelevel", data[1], 60)
	end, function(pos, current, all)
		if(pos == 2) then
			if(Vermilion:GetModule("map") != nil) then
				local mps = {}
				for i,k in pairs(Vermilion:GetModule("map").MapCache) do
					table.insert(mps, k[1])
				end
				return VToolkit.MatchStringPart(mps, current)
			end
		end
	end)

	MODULE:AddVoteType("ban", function(data, sender, log)
		if(table.Count(data) < 2) then log("votes:ban:syntax", nil, NOTIFY_ERROR) return end
		if(VToolkit.LookupPlayer(data[1]) == nil) then log("no_users", nil, NOTIFY_ERROR) return end
		if(tonumber(data[2]) == nil) then log("not_number", nil, NOTIFY_ERROR) return end
		return "votes:ban:question", data[1]
	end, function(data)
		Vermilion:GetModule("bans"):BanPlayer(VToolkit.LookupPlayer(data[1]), nil, tonumber(data[2]), "Votebanned", nil, nil, nil)
	end, function(pos, current, all)
		if(pos == 2) then
			return VToolkit.MatchPlayerPart(current)
		end
	end)

	MODULE:AddVoteType("unban", function(data, sender, log)
		if(table.Count(data) < 1) then log("votes:unban:syntax", nil, NOTIFY_ERROR) return end
		local has = false
		for i,k in pairs(Vermilion:GetModuleData("bans", "bans", {})) do
			if(Vermilion:GetUserBySteamID(k[1]).Name == data[1]) then has = true break end
		end
		if(not has) then log("votes:unban:notbanned", nil, NOTIFY_ERROR) return end
		return "votes:unban:question", data[1]
	end, function(data)
		Vermilion:GetModule("bans"):UnbanPlayer(Vermilion:GetUserByName(data[1]).Name)
	end)

	MODULE:AddVoteType("kick", function(data, sender, log)
		if(table.Count(data) < 1) then log("votes:kick:syntax", nil, NOTIFY_ERROR) return end
		if(VToolkit.LookupPlayer(data[1]) == nil) then log("no_users", nil, NOTIFY_ERROR) return end
		return "votes:kick:question", data[1]
	end, function(data)
		local tplayer = VToolkit.LookupPlayer(data[1])
		if(not IsValid(tplayer)) then return end
		Vermilion:BroadcastNotify("votes:kick:done", { data[1] }, NOTIFY_ERROR)
		tplayer:Kick("Kicked by Console: Votekicked")
	end, function(pos, current, all)
		if(pos == 2) then
			return VToolkit.MatchPlayerPart(current)
		end
	end)


	self:AddHook(Vermilion.Event.MOD_LOADED, "AddGui", function()
		if(Vermilion:GetModule("server_settings") != nil) then
			local mgr = Vermilion:GetModule("server_settings")
			mgr:AddCategory("cat:votes", "Votes", 16)
			for i,k in pairs(MODULE.VoteTypes) do
				mgr:AddOption({
					Module = "votes",
					Name = "vote_" .. i,
					GuiText = MODULE:TranslateStr("enabletext", { i }),
					Type = "Checkbox",
					Category = "Votes",
					Default = true,
					Permission = "vote_management"
					})
			end
		end
	end)
end

function MODULE:InitServer()

	function MODULE:BroadcastVote(typ, text, data, time, caller, data)
		self.VoteInProgress = true
		self.VoteType = typ
		self.VoteResults = { Yes = 0, No = 0 }
		self.Voters = {}
		self.VoteCaller = caller:GetName()
		self.VoteExpires = os.time() + time
		MODULE:NetStart("CallVote")
		net.WriteString(text)
		net.WriteTable(data)
		net.WriteInt(time, 32)
		net.WriteString(caller:GetName())
		net.Send(Vermilion:GetUsersWithPermission("participate_in_vote"))
		timer.Simple(time + 1, function()
			MODULE.VoteInProgress = false
			local win = MODULE.VoteResults.Yes > MODULE.VoteResults.No
			if(win) then
				for i,k in pairs(Vermilion:GetUsersWithPermission("participate_in_vote")) do
					Vermilion:AddNotification(k, "votes:success", { tostring(math.Round((MODULE.VoteResults.Yes / (MODULE.VoteResults.Yes + MODULE.VoteResults.No)) * 100, 1)) })
				end
				MODULE.VoteTypes[typ].Success(data)
			else
				if((MODULE.VoteResults.Yes + MODULE.VoteResults.No) == 0) then
					for i,k in pairs(Vermilion:GetUsersWithPermission("participate_in_vote")) do
						Vermilion:AddNotification(k, "votes:nopartake")
					end
					return
				end
				for i,k in pairs(Vermilion:GetUsersWithPermission("participate_in_vote")) do
					Vermilion:AddNotification(k, "votes:failure", { tostring(math.Round((MODULE.VoteResults.No / (MODULE.VoteResults.Yes + MODULE.VoteResults.No)) * 100, 1)) })
				end
			end
		end)
	end




	self:AddHook("ShowHelp", function(vplayer)
		if(MODULE.VoteInProgress and not table.HasValue(MODULE.Voters, vplayer:SteamID())) then
			MODULE.VoteResults.Yes = MODULE.VoteResults.Yes + 1
			table.insert(MODULE.Voters, vplayer:SteamID())
		end
	end)

	self:AddHook("ShowTeam", function(vplayer)
		if(MODULE.VoteInProgress and not table.HasValue(MODULE.Voters, vplayer:SteamID())) then
			MODULE.VoteResults.No = MODULE.VoteResults.No + 1
			table.insert(MODULE.Voters, vplayer:SteamID())
		end
	end)


end

function MODULE:InitClient()
	self:NetHook("CallVote", function()
		local text = net.ReadString()
		local data = net.ReadTable()
		local time = net.ReadInt(32)
    local caller = net.ReadString()
		local ttext = MODULE:TranslateStr("header", { caller }) .. "\n\n" .. MODULE:TranslateStr(text, data) .. "\n\n" .. MODULE:TranslateStr("footer", { input.LookupBinding("gm_showhelp"), input.LookupBinding("gm_showteam") })
		MODULE.VoteWindow = Vermilion:AddNotification(ttext, NOTIFY_HINT, time)
		MODULE.VoteInProgress = true
		timer.Simple(time, function()
			MODULE.VoteInProgress = false
		end)
	end)

	self:AddHook("PlayerBindPress", function(vplayer, bind, pressed)
		if((bind == "gm_showhelp" or bind == "gm_showteam") and pressed) then
			if(MODULE.VoteInProgress) then
				MODULE.VoteWindow()
				MODULE.VoteInProgress = false
				RunConsoleCommand(bind)
				if(bind == "gm_showhelp") then
					Vermilion:AddNotification(MODULE:TranslateStr("vyes"))
				else
					Vermilion:AddNotification(MODULE:TranslateStr("vno"))
				end
				return false
			end
		end
	end)
end
