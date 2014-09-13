--[[
 Copyright 2014 Ned Hyett, Foxworrior

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
EXTENSION.Name = "Warps"
EXTENSION.ID = "warps"
EXTENSION.Description = "Allows administrators to define a point that players can warp to."
EXTENSION.Author = "Foxworrior"
EXTENSION.Permissions = {
	"can_be_warped",
	"create_warp",
	"remove_warp",
	"warp"
}
EXTENSION.PermissionDefinitions = {
	["can_be_warped"] = "This player is able to be warped using the warp command.",
	["create_warp"] = "This player is able to create a warp.",
	["remove_warp"] = "This player is able to remove a warp.",
	["warp"] = "This player is able to use the warp command. Note that the player cannot be warped themselves unless they have the can_be_warped permission."
}

function EXTENSION:InitServer()
	
	Vermilion:AddChatCommand("addwarp", function(sender, text, log)
		if (not Vermilion:HasPermissionError(sender, "create_warp")) then
			return
		end

		if(table.Count(text) < 1) then
			log("Syntax: !addwarp <name>", VERMILION_NOTIFY_ERROR)
			return
		end
		if (EXTENSION:GetData("warps", {}, true)[text[1]] != nil) then
			log("A warp with that name already exists.", VERMILION_NOTIFY_ERROR)
			return
		end
		log("Added warp '" .. text[1] .. "'")
		EXTENSION:GetData("warps", {}, true)[text[1]] = sender:GetPos()
	end, "<name>")

	Vermilion:AddChatCommand("removewarp", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "remove_warp")) then
			return
		end

		if(table.Count(text) < 1) then
			log("Syntax: !removewarp <name>", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION:GetData("warps", {}, true)[text[1]] == nil) then
			log("That warp doesn't exist.", VERMILION_NOTIFY_ERROR)
			return
		end
		EXTENSION:GetData("warps", {}, true)[text[1]] = nil
		log("Removed warp '" .. text[1] .. "'")
	end, "<name>")
	
	Vermilion:AddChatPredictor("removewarp", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(EXTENSION:GetData("warps", {}, true)) do
				if(string.StartWith(i, current)) then
					table.insert(tab, i)
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("listwarps", function(sender, text, log)
		local str = ""
		local idx = 1
		for i,k in pairs(EXTENSION:GetData("warps", {}, true)) do
			if(idx == table.Count(EXTENSION:GetData("warps", {}, true))) then
				str = str .. i
			else
				str = str .. i .. ", "
			end
			idx = idx + 1
		end
		log("Active warps: " .. str)
	end)

	Vermilion:AddChatCommand("warp", function(sender, text, log) 
		if(not Vermilion:HasPermissionError(sender, "warp")) then
			return
		end
		
		if(table.Count(text) < 1) then
			log("Syntax: !warp [player] <warp>", VERMILION_NOTIFY_ERROR)
			return
		end

		if(table.Count(text) < 2) then
			if(not Vermilion:HasPermissionError(sender, "can_be_warped") or not Vermilion:HasPermissionError(sender, "warp")) then
				return
			end
			local position = EXTENSION:GetData("warps", {}, true)[text[1]]
			if(position == nil) then
				log("Warp does not exist!", VERMILION_NOTIFY_ERROR)
				return
			end
			log("You have been warped to " .. text[1])
			sender:SetPos(position)
			return
		end

		if(table.Count(text) > 1) then
			if(not Vermilion:HasPermissionError(sender, "warp"))  then
				return
			end
			if(not Vermilion:HasPermissionError(text[1], "can_be_warped")) then
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1])
			if(tplayer == nil) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			local position = EXTENSION:GetData("warps", {}, true)[text[2]]
			if(position == nil) then
				log("Warp does not exist!", VERMILION_NOTIFY_ERROR)
				return
			end
			tplayer:SetPos(position)
			Vermilion:SendNotify(tplayer, "You have been warped to " .. tostring(text[2]))
			log(text[1] .. " has been warped to " .. text[2])
			return
		end


	end, "[player] <warp>")
	
	Vermilion:AddChatPredictor("warp", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(EXTENSION:GetData("warps", {}, true)) do
				if(string.StartWith(i, current)) then
					table.insert(tab, i .. " (warp)")
				end
			end
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k), string.lower(current))) then
					table.insert(tab, k .. " (player)")
				end
			end
			return tab
		end
		if(pos == 2) then
			local tab = {}
			for i,k in pairs(EXTENSION:GetData("warps", {}, true)) do
				if(string.StartWith(i, current)) then
					table.insert(tab, i)
				end
			end
			return tab
		end
	end)
end

function EXTENSION:InitClient()

end

Vermilion:RegisterExtension(EXTENSION)







