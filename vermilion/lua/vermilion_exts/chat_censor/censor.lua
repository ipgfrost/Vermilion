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

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "chat_censor"
EXTENSION.ID = "censor"
EXTENSION.Description = "Censors the chat to prevent the discussion of inappropriate topics/advertising"
EXTENSION.Author = "Ned and Foxworrior"
EXTENSION.Permissions = {
	"manage_censor"
}
EXTENSION.PermissionDefinitions = {
	["manage_censor"] = "This player is able to see the Chat Censor tab on the Vermilion Menu and modify it's contents."
}
EXTENSION.NetworkStrings = {
	"VPhraseListLoad",
	"VPhraseListSave",
	"VCensorUpdate",
	"VGetCensorUpdate"
}

function EXTENSION:InitServer()

	function EXTENSION:GetCensored(banned)
		local str = ""
		for i=1,string.len(banned),1 do
			str = str .. "*"
		end
		return str
	end

	self:AddHook("PlayerSay", function(vplayer, text, teamChat)
		if(not EXTENSION:GetData("enabled", false, true)) then return end
		local result = text
		if(string.StartWith(text, "!")) then return end
		for i,k in pairs(EXTENSION:GetData("banned", {}, true)) do
			result = string.Replace(result, k, EXTENSION:GetCensored(k))
		end
		if(EXTENSION:GetData("filter_ips", false, true)) then
			while(true) do
				local st,en = string.find(result, "(%d+.%d+.%d+.%d+)")
				if(st == nil) then break end
				for i=st,en,1 do
					result = string.SetChar(result, i, "*")
				end
			end
		end
		
		return string.Trim(result)
	end)
	
	self:NetHook("VGetCensorUpdate", function(vplayer)
		net.Start("VGetCensorUpdate")
		net.WriteString(tostring(EXTENSION:GetData("enabled", false, true)))
		net.WriteString(tostring(EXTENSION:GetData("filter_ips", false, true)))
		net.WriteString(tostring(EXTENSION:GetData("exemptions", true, true)))
		net.Send(vplayer)
	end)
	
	self:NetHook("VCensorUpdate", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_censor")) then
			EXTENSION:SetData("enabled", tobool(net.ReadString()))
			EXTENSION:SetData("filter_ips", tobool(net.ReadString()))
			EXTENSION:SetData("exemptions", tobool(net.ReadString()))
		end
	end)
	
	self:NetHook("VPhraseListLoad", function(vplayer)
		net.Start("VPhraseListLoad")
		net.WriteTable(EXTENSION:GetData("banned", {}, true))
		net.Send(vplayer)
	end)
	
	self:NetHook("VPhraseListSave", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_censor")) then
			local tab = net.ReadTable()
			EXTENSION:SetData("banned", tab)
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("censor", "manage_censor")
	end)
	
end

function EXTENSION:InitClient()
	
	self:NetHook("VPhraseListLoad", function()
		if(not IsValid(EXTENSION.RankPermissionsList)) then
			return
		end
		EXTENSION.RankPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.RankPermissionsList:AddLine(k)
		end
	end)
	
	self:NetHook("VGetCensorUpdate", function()
		if(IsValid(EXTENSION.EnabledCB)) then
			EXTENSION.EnabledCB:SetValue(tobool(net.ReadString()))
			EXTENSION.IPCensorCB:SetValue(tobool(net.ReadString()))
			EXTENSION.ExemptCB:SetValue(tobool(net.ReadString()))
		end
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("censor", "Chat Censor", "transmit_error.png", "Censor the chat and prevent players from saying certain things.", function(panel)			
			
			local function updateServer()
				net.Start("VCensorUpdate")
				net.WriteString(tostring(EXTENSION.EnabledCB:GetChecked()))
				net.WriteString(tostring(EXTENSION.IPCensorCB:GetChecked()))
				net.WriteString(tostring(EXTENSION.ExemptCB:GetChecked()))
				net.SendToServer()
			end
			
			local enabledCB = Crimson.CreateCheckBox("Enable Chat Censor")
			enabledCB:SetParent(panel)
			enabledCB:SetPos(10, 10)
			enabledCB:SizeToContents()
			enabledCB:SetDark(true)
			EXTENSION.EnabledCB = enabledCB
			enabledCB.OnChange = function()
				updateServer()
			end
			
			local ipCensor = Crimson.CreateCheckBox("Censor IPv4 Addresses")
			ipCensor:SetParent(panel)
			ipCensor:SetPos(10, 30)
			ipCensor:SizeToContents()
			ipCensor:SetDark(true)
			EXTENSION.IPCensorCB = ipCensor
			ipCensor.OnChange = function()
				updateServer()
			end
			
			local exemption = Crimson.CreateCheckBox("Allow users with the 'censor_exempt' permission to be exempt from censoring.")
			exemption:SetParent(panel)
			exemption:SetPos(10, 50)
			exemption:SizeToContents()
			exemption:SetDark(true)
			EXTENSION.ExemptCB = exemption
			exemption.OnChange = function()
				updateServer()
			end
			
			local banafter = Crimson.CreateCheckBox("Ban users after the specified number of censored words: ")
			banafter:SetParent(panel)
			banafter:SetPos(10, 70)
			banafter:SizeToContents()
			banafter:SetDark(true)
			banafter:SetDisabled(true)
			EXTENSION.BanAfterCB = banafter
			
			local banafterwang = Crimson.CreateNumberWang(0, nil)
			banafterwang:SetParent(panel)
			banafterwang:SetPos(310, 68)
			banafterwang:SetDisabled(true)
			
			local adminsee = Crimson.CreateCheckBox("Allow users with the 'censor_override' permission to see censored messages.")
			adminsee:SetParent(panel)
			adminsee:SetPos(10, 90)
			adminsee:SizeToContents()
			adminsee:SetDark(true)
			adminsee:SetDisabled(true)
			EXTENSION.AdminSeeCB = adminsee
			
			local guiRankPermissionsList = Crimson.CreateList({ "Phrase" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(550, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local blockedBindsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Blocked Phrases")
			blockedBindsLabel:SetParent(panel)
			
			
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Blocked Phrases", function(self)
				net.Start("VPhraseListSave")
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, k:GetValue(1))
				end
				net.WriteTable(tab)
				net.SendToServer()
			end)
			saveRankPermissionsButton:SetPos(565, 500)
			saveRankPermissionsButton:SetSize(210, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			
			
			local giveRankPermissionButton = Crimson.CreateButton("Add Phrase", function(self)
				Crimson:CreateTextInput("Enter the prase to look for (patterns/regexes work too!):", function(result)
					for i,k in pairs(guiRankPermissionsList:GetLines()) do
						if(k:GetValue(1) == result) then
							Crimson:CreateErrorDialog("Cannot add duplicate phrase.")
							return
						end
					end
					guiRankPermissionsList:AddLine(result)
				end)
			end)
			giveRankPermissionButton:SetPos(565, 350)
			giveRankPermissionButton:SetSize(210, 30)
			giveRankPermissionButton:SetParent(panel)
			
			
			
			local removeRankPermissionButton = Crimson.CreateButton("Remove Phrase", function(self)
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one phrase to remove from the list of blocked phrases for this rank!")
					return
				end
				local tab = {}
				for i,k in ipairs(guiRankPermissionsList:GetLines()) do
					if(not k:IsSelected()) then
						table.insert(tab, k:GetValue(1))
					end
				end
				guiRankPermissionsList:Clear()
				for i,k in ipairs(tab) do
					guiRankPermissionsList:AddLine(k)
				end
			end)
			removeRankPermissionButton:SetPos(565, 390)
			removeRankPermissionButton:SetSize(210, 30)
			removeRankPermissionButton:SetParent(panel)
			
			net.Start("VPhraseListLoad")
			net.SendToServer()
			
			net.Start("VGetCensorUpdate")
			net.SendToServer()
			
		end, 8.5)
	end)
end

Vermilion:RegisterExtension(EXTENSION)