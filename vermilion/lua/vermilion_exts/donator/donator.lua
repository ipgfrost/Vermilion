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
EXTENSION.Name = "Donator Checker"
EXTENSION.ID = "donator"
EXTENSION.Description = "Checks with a web server to check if a player has donated to the server. Depending on the response, can automatically promote them to a specific rank ect."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"manage_donator_mode"
}
EXTENSION.PermissionDefinitions = {
	["manage_donator_mode"] = "This player is allowed to view the Donator Settings tab in the Vermilion Menu and change the settings within."
}
EXTENSION.NetworkStrings = {
	"VUpdateDonatorMode",
	"VGetDonatorMode"
}

--[[
	Specs for the backend:
	
	- Must return a properly formatted JSON table.
	- Must return a "status" property in the table. If the request failed, return "failed" in this property. Anything else is a success.
	- Must return a "query_result" property if successful. This must be "true" if the player is registered as a donator.
	- May return a "rank_promote" property if successful. This gives the player a new rank.
	- May return an "amount" property if successful. This will be used in the message that is broadcast to all players. Must be a string with the currency information as well. (i.e. £15)
]]--

function EXTENSION:InitServer()
	
	self:AddHook("PlayerInitialSpawn", function(vplayer)
		if(Vermilion:GetSetting("promoted_donators", nil) == nil) then Vermilion:SetSetting("promoted_donators", {}) end
		if(table.HasValue(Vermilion:GetSetting("promoted_donators", {}), vplayer:SteamID())) then return end
		if(Vermilion:GetSetting("donator_mode_enabled", false)) then
			http.Fetch(string.Replace(Vermilion:GetSetting("donator_url", nil), "%steamid%", vplayer:SteamID()), function(body, len, headers, code)
				local tab = util.JSONToTable(body)
				if(tab.status == "failed") then
					Vermilion.Log("Failed to obtain donator information. Server query failed.")
				else
					if(tab.query_result) then
						table.insert(Vermilion:GetSetting("promoted_donators", {}), vplayer:SteamID())
						if(tab.rank_promote) then
							Vermilion:SetRank(vplayer, tab.rank_promote)
						end
						if(tab.amount) then
							Vermilion:BroadcastNotify(vplayer:GetName() .. " is now a donator after donating " .. tab.amount .. "!")
						end
					end
				end
			end, function(err)
				Vermilion.Log("Failed to obtain donator information. Server query failed. (" .. err .. ")")
			end)
		end
	end)
	
	self:NetHook("VUpdateDonatorMode", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_donator_mode")) then
			Vermilion:SetSetting("donator_mode_enabled", tobool(net.ReadString()))
			Vermilion:SetSetting("donator_url", net.ReadString())
		end
	end)
	
	self:NetHook("VGetDonatorMode", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_donator_mode")) then
			net.Start("VGetDonatorMode")
			net.WriteString(tostring(Vermilion:GetSetting("donator_mode_enabled", false)))
			net.WriteString(Vermilion:GetSetting("donator_url", ""))
			net.Send(vplayer)
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("donator_control", "manage_donator_mode")
	end)
	
end

function EXTENSION:InitClient()
	self:NetHook("VGetDonatorMode", function(vplayer)
		EXTENSION.EnableDonatorMode:SetValue(tobool(net.ReadString()))
		EXTENSION.DonatorURL:SetValue(net.ReadString())
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("donator_control", "Donator Settings", "coins.png", "Manage the settings for the donator promotion system.", function(panel)
			
			local urltb = nil
			
			local enabled = vgui.Create("DCheckBoxLabel")
			enabled:SetText("Enable donator promotion mode")
			enabled:SizeToContents()
			enabled:SetPos(10, 10)
			enabled:SetParent(panel)
			enabled:SetDark(true)
			enabled.OnValueChanged = function()
				net.Start("VUpdateDonatorMode")
				net.WriteString(tostring(enabled:GetChecked()))
				net.WriteString(urltb:GetValue())
				net.SendToServer()
			end
			EXTENSION.EnableDonatorMode = enabled
			
			urltb = vgui.Create("DTextEntry")
			urltb:SetPos(10, 200)
			urltb:SetSize(panel:GetWide() - 10, 20)
			urltb:SetParent(panel)
			urltb.OnValueChanged = function()
				net.Start("VUpdateDonatorMode")
				net.WriteString(tostring(enabled:GetChecked()))
				net.WriteString(urltb:GetValue())
				net.SendToServer()
			end
			EXTENSION.DonatorURL = urltb
			
			local tblab = vgui.Create("DLabel")
			tblab:SetPos(10, 50)
			tblab:SetParent(panel)
			tblab:SetText("This is the URL that Vermilion will contact to obtain the information to check which players are donators or not. Place %steamid% as the value of one of the GET\n parameters. The server has to return a JSON table.\n\nSpecs:\n- Must return a properly formatted JSON table.\n- Must return a \"status\" property in the table. If the request failed, return \"failed\" in this property. Anything else is a success.\n- Must return a \"query_result\" property if successful. This must be \"true\" if the player is registered as a donator.\n- May return a \"rank_promote\" property if successful. This gives the player a new rank.\n- May return an \"amount\" property if successful. This will be used in the message that is broadcast to all players.\n Must be a string with the currency information as well. (i.e. £15)")
			tblab:SetWide(panel:GetWide() - 10)
			tblab:SetTall(150)
			tblab:SetDark(true)
			tblab:SizeToContents()
			
		end, 10)
	end)
end

Vermilion:RegisterExtension(EXTENSION)