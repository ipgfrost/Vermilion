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

local MODULE = MODULE
MODULE.Name = "Votes (Incomplete)"
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
	"VCallVote"
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
		Function = function(sender, text, log, glog, tglog)
			if(MODULE.VoteInProgress) then
				log(MODULE:TranslateStr("inprogress", nil, sender), NOTIFY_ERROR)
				return
			end
			local typ = text[1]
			if(MODULE.VoteTypes[typ] == nil) then
				log(MODULE:TranslateStr("notype", nil, sender), NOTIFY_ERROR)
				local str = table.concat(table.GetKeys(MODULE.VoteTypes), ", ")
				log(MODULE:TranslateStr("validtypes", { str }, sender), 15)
				return
			end
			local tcopy = table.Copy(text)
			table.remove(tcopy, 1)
			local vtext, data, pars = MODULE.VoteTypes[typ].Create(tcopy, sender)
			if(not vtext) then
				log(MODULE:TranslateStr("invalidparatype", nil, sender), NOTIFY_ERROR)
				log(pars)
				return
			end
			MODULE:BroadcastVote(typ, vtext, data, 30, sender, tcopy)
		end
	})
	
end

function MODULE:InitServer()
	
	function MODULE:BroadcastVote(typ, text, data, time, caller, data)
		self.VoteInProgress = true
		self.VoteType = typ
		self.VoteResults = { Yes = 0, No = 0 }
		self.Voters = {}
		self.VoteCaller = caller:GetName()
		self.VoteExpires = os.time() + time
		MODULE:NetStart("VCallVote")
		net.WriteString(text)
		net.WriteTable(data)
		net.WriteInt(time, 32)
		net.WriteString(caller:GetName())
		net.Send(Vermilion:GetUsersWithPermission("participate_in_vote"))
		timer.Simple(valid_time + 1, function()
			MODULE.VoteInProgress = false
			local win = MODULE.VoteResults.Yes > MODULE.VoteResults.No
			if(win) then
				for i,k in pairs(Vermilion:GetUsersWithPermission("participate_in_vote")) do
					Vermilion:TransNotify(k, "success", { tostring(math.Round((MODULE.VoteResults.Yes / (MODULE.VoteResults.Yes + MODULE.VoteResults.No)) * 100, 1)) }, nil, nil, MODULE)
				end
				MODULE.VoteTypes[typ].Success(data)
			else
				if((MODULE.VoteResults.Yes + MODULE.VoteResults.No) == 0) then
					for i,k in pairs(Vermilion:GetUsersWithPermission("participate_in_vote")) do
						Vermilion:TransNotify(k, "nopartake", nil, nil, nil, MODULE)
					end
					return
				end
				for i,k in pairs(Vermilion:GetUsersWithPermission("participate_in_vote")) do
					Vermilion:TransNotify(k, "failure", { tostring(math.Round((MODULE.VoteResults.No / (MODULE.VoteResults.Yes + MODULE.VoteResults.No)) * 100, 1)) }, nil, nil, MODULE)
				end
			end
		end)
	end
	
end

function MODULE:InitClient()
	
end