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
MODULE.Name = "Chat Censor"
MODULE.ID = "chat_censor"
MODULE.Description = "Blocks words and IPv4 addresses in chat."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_chat_censor"
}
MODULE.NetworkStrings = {
	"VPhraseListLoad",
	"VAddPhrase",
	"VRemovePhrase",
	"VEditPhrase",
	"VCensorUpdate",
	"VGetCensorUpdate"
}

function MODULE:InitServer()
	function MODULE:GetCensored(banned)
		local str = ""
		for i=1,string.len(banned),1 do
			str = str .. "*"
		end
		return str
	end

	self:AddHook("VPlayerSay", function(vplayer, text, teamChat)
		if(not MODULE:GetData("enabled", false, true)) then return end
		local result = text
		if(string.StartWith(text, "!")) then return end
		for i,k in pairs(MODULE:GetData("banned", {}, true)) do
			result = string.Replace(result, k, MODULE:GetCensored(k))
		end
		if(MODULE:GetData("filter_ips", false, true)) then
			while(true) do
				local st,en = string.find(result, "(%d+.%d+.%d+.%d+)")
				if(st == nil) then break end
				for i=st,en,1 do
					result = string.SetChar(result, i, "*")
				end
			end
		end
		if(result != text) then
			return string.Trim(result)
		end
	end)

	local function sendPhraseList(vplayer)
		MODULE:NetStart("VPhraseListLoad")
		net.WriteTable(MODULE:GetData("banned", {}, true))
		net.Send(vplayer)
	end

	self:NetHook("VPhraseListLoad", function(vplayer)
		sendPhraseList(vplayer)
	end)

	self:NetHook("VAddPhrase", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_chat_censor")) then
			local newPhrase = net.ReadString()
			if(not table.HasValue(MODULE:GetData("banned", {}, true), newPhrase)) then
				table.insert(MODULE:GetData("banned", {}, true), newPhrase)
			end
			sendPhraseList(Vermilion:GetUsersWithPermission("manage_chat_censor"))
		end
	end)

	self:NetHook("VRemovePhrase", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_chat_censor")) then
			local phrase = net.ReadString()
			table.RemoveByValue(MODULE:GetData("banned", {}, true), phrase)
			sendPhraseList(Vermilion:GetUsersWithPermission("manage_chat_censor"))
		end
	end)

	self:NetHook("VEditPhrase", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_chat_censor")) then
			local oldPhrase = net.ReadString()
			local newPhrase = net.ReadString()

			for i,k in pairs(MODULE:GetData("banned", {}, true)) do
				if(k == oldPhrase) then
					MODULE:GetData("banned", {}, true)[i] = newPhrase
					break
				end
			end
			sendPhraseList(Vermilion:GetUsersWithPermission("manage_chat_censor"))
		end
	end)

	self:NetHook("VCensorUpdate", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_chat_censor")) then
			MODULE:SetData("enabled", net.ReadBoolean())
			MODULE:SetData("filter_ips", net.ReadBoolean())

			MODULE:NetStart("VGetCensorUpdate")
			net.WriteBoolean(MODULE:GetData("enabled", false, true))
			net.WriteBoolean(MODULE:GetData("filter_ips", false, true))
			net.Send(Vermilion:GetUsersWithPermission("manage_chat_censor"))
		end
	end)

	self:NetHook("VGetCensorUpdate", function(vplayer)
		MODULE:NetStart("VGetCensorUpdate")
		net.WriteBoolean(MODULE:GetData("enabled", false, true))
		net.WriteBoolean(MODULE:GetData("filter_ips", false, true))
		net.Send(vplayer)
	end)
end

function MODULE:InitClient()
	self:NetHook("VPhraseListLoad", function()
		local paneldata = Vermilion.Menu.Pages["chat_censor"]

		paneldata.PhraseList:Clear()
		for i,k in pairs(net.ReadTable()) do
			paneldata.PhraseList:AddLine(k)
		end
		paneldata.PhraseList:OnRowSelected()
	end)

	self:NetHook("VGetCensorUpdate", function()
		local paneldata = Vermilion.Menu.Pages["chat_censor"]
		paneldata.CanUpdateServer = false
		paneldata.EnabledCheckbox:SetValue(net.ReadBoolean())
		paneldata.IPCensorCB:SetValue(net.ReadBoolean())
		paneldata.CanUpdateServer = true
	end)

	Vermilion.Menu:AddCategory("player", 4)

	self:AddMenuPage({
		ID = "chat_censor",
		Name = Vermilion:TranslateStr("menu:chat_censor"),
		Order = 6,
		Category = "player",
		Size = { 800, 525 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_chat_censor")
		end,
		Builder = function(panel, paneldata)
			local function updateServer()
				if(not paneldata.CanUpdateServer) then return end
				MODULE:NetStart("VCensorUpdate")
				net.WriteBoolean(paneldata.EnabledCheckbox:GetChecked())
				net.WriteBoolean(paneldata.IPCensorCB:GetChecked())
				net.SendToServer()
			end

			local enabledCB = VToolkit:CreateCheckBox(MODULE:TranslateStr("enable"))
			enabledCB:SetParent(panel)
			enabledCB:SetPos(620, 30)
			enabledCB:SizeToContents()
			enabledCB:SetDark(true)
			enabledCB.OnChange = function()
				updateServer()
			end
			paneldata.EnabledCheckbox = enabledCB

			local ipCensor = VToolkit:CreateCheckBox(MODULE:TranslateStr("ipv4"))
			ipCensor:SetParent(panel)
			ipCensor:SetPos(620, 50)
			ipCensor:SizeToContents()
			ipCensor:SetDark(true)
			ipCensor.OnChange = function()
				updateServer()
			end
			paneldata.IPCensorCB = ipCensor


			local addPhrasePanel = VToolkit:CreateRightDrawer(panel)

			local phraseData = VToolkit:CreateTextbox()
			phraseData:SetPos(10, 40)
			phraseData:SetSize(425, 25)
			phraseData:SetParent(addPhrasePanel)

			local addPhraseButton = VToolkit:CreateButton(MODULE:TranslateStr("new"), function()
				if(phraseData:GetValue() == nil or phraseData:GetValue() == "") then return end
				paneldata.PhraseList:AddLine(phraseData:GetValue())
				MODULE:NetStart("VAddPhrase")
				net.WriteString(phraseData:GetValue())
				net.SendToServer()
				addPhrasePanel:Close()
			end)
			addPhraseButton:SetPos(10, phraseData:GetY() + phraseData:GetTall() + 10)
			addPhraseButton:SetSize(425, 30)
			addPhraseButton:SetParent(addPhrasePanel)

			local editPhrasePanel = VToolkit:CreateRightDrawer(panel)

			local ephraseData = VToolkit:CreateTextbox()
			ephraseData:SetPos(10, 40)
			ephraseData:SetSize(425, 25)
			ephraseData:SetParent(editPhrasePanel)
			paneldata.EPhraseData = ephraseData

			local editPhraseButton = VToolkit:CreateButton(MODULE:TranslateStr("new"), function()
				if(ephraseData:GetValue() == nil or ephraseData:GetValue() == "") then return end
				local old = paneldata.PhraseList:GetSelected()[1]:GetValue(1)
				paneldata.PhraseList:GetSelected()[1]:SetValue(1, ephraseData:GetValue())
				MODULE:NetStart("VEditPhrase")
				net.WriteString(old)
				net.WriteString(ephraseData:GetValue())
				net.SendToServer()
				editPhrasePanel:Close()
			end)
			editPhraseButton:SetPos(10, ephraseData:GetY() + ephraseData:GetTall() + 10)
			editPhraseButton:SetSize(425, 30)
			editPhraseButton:SetParent(editPhrasePanel)



			local addPhrase = VToolkit:CreateButton(MODULE:TranslateStr("add"), function()
				addPhrasePanel:Open()
			end)
			addPhrase:SetPos(620, 90)
			addPhrase:SetParent(panel)
			addPhrase:SetSize(panel:GetWide() - addPhrase:GetX() - 10, 25)


			local editPhrase = VToolkit:CreateButton(MODULE:TranslateStr("edit"), function()
				paneldata.EPhraseData:SetValue(paneldata.PhraseList:GetSelected()[1]:GetValue(1))
				editPhrasePanel:Open()
			end)
			editPhrase:SetPos(620, 125)
			editPhrase:SetParent(panel)
			editPhrase:SetSize(panel:GetWide() - editPhrase:GetX() - 10, 25)
			editPhrase:SetDisabled(true)
			paneldata.EditPhraseBtn = editPhrase

			local remPhrase = VToolkit:CreateButton(MODULE:TranslateStr("remove"), function()
				for i,k in pairs(paneldata.PhraseList:GetSelected()) do
					MODULE:NetStart("VRemovePhrase")
					net.WriteString(k:GetValue(1))
					net.SendToServer()
					paneldata.PhraseList:RemoveLine(k:GetID())
				end
			end)
			remPhrase:SetPos(620, 160)
			remPhrase:SetParent(panel)
			remPhrase:SetSize(panel:GetWide() - remPhrase:GetX() - 10, 25)
			remPhrase:SetDisabled(true)
			paneldata.RemPhraseBtn = remPhrase

			local phraseList = VToolkit:CreateList({
				cols = {
					MODULE:TranslateStr("phrase")
				}
			})
			phraseList:SetParent(panel)
			phraseList:SetPos(10, 30)
			phraseList:SetSize(600, 480)
			paneldata.PhraseList = phraseList

			function phraseList:OnRowSelected(index, line)
				local enabled = self:GetSelected()[1] == nil
				editPhrase:SetDisabled(enabled)
				remPhrase:SetDisabled(enabled)
			end

			local blockedBindsLabel = VToolkit:CreateHeaderLabel(phraseList, MODULE:TranslateStr("list"))
			blockedBindsLabel:SetParent(panel)

			addPhrasePanel:MoveToFront()
			editPhrasePanel:MoveToFront()
		end,
		OnOpen = function(panel, paneldata)
			MODULE:NetCommand("VPhraseListLoad")
			MODULE:NetCommand("VGetCensorUpdate")
			paneldata.EditPhraseBtn:SetDisabled(true)
			paneldata.RemPhraseBtn:SetDisabled(true)

			paneldata.EditPhrasePanel:Close()
			paneldata.AddPhrasePanel:Close()
		end
	})
end
