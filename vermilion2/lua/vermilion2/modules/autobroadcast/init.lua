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
MODULE.Name = "Automatic Broadcast"
MODULE.ID = "autobroadcast"
MODULE.Description = "Allows defined messages to be broadcast through the chat using an interval."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_auto_broadcast"
}
MODULE.NetworkStrings = {
	"VGetAutoBroadcastListing",
	"VAddAutoBroadcastListing",
	"VUpdateAutoBroadcastListing",
	"VDelAutoBroadcastListing"
}
MODULE.APIFuncs = {
	{
		Name = "CreateNewAutoBroadcast",
		Parameters = {
			{ Name = "text", Type = "String", Desc = "The text to be broadcast" },
			{ Name = "interval", Type = "Number", Desc = "The interval to broadcast it at (seconds)" },
			{ Name = "displayinterval", Type = "String", Desc = "The interval summary to be displayed on the listings page" }
		},
		Desc = "Creates a new broadcast message"
	}
}

function MODULE:InitServer()
	function MODULE:CreateNewAutoBroadcast(text, interval, displayinterval)
		assert(text != nil and interval != nil and displayinterval != nil)
		MODULE:GetData("listings", { Text = text, Interval = interval, IntervalString = displayinterval })
	end

	timer.Create("Vermilion_AutoBroadcast", 1, 0, function()
		local messages = MODULE:GetData("listings", {}, true)
		for i,k in pairs(messages) do
			if(k.Timeout == nil) then
				k.Timeout = k.Interval
				continue
			end
			k.Timeout = k.Timeout - 1
			if(k.Timeout <= 0) then
				PrintMessage(HUD_PRINTTALK, "[Vermilion] " .. k.Text)
				k.Timeout = k.Interval
			end
		end
	end)

	local function sendListings(vplayer)
		MODULE:NetStart("VGetAutoBroadcastListing")
		net.WriteTable(MODULE:GetData("listings", {}, true))
		net.Send(vplayer)
	end

	self:NetHook("VGetAutoBroadcastListing", function(vplayer)
		sendListings(vplayer)
	end)

	self:NetHook("VAddAutoBroadcastListing", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_auto_broadcast")) then
			table.insert(MODULE:GetData("listings", {}, true), net.ReadTable())
			sendListings(Vermilion:GetUsersWithPermission("manage_auto_broadcast"))
		end
	end)
	
	self:NetHook("VUpdateAutoBroadcastListing", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_auto_broadcast")) then
			local vtab = net.ReadTable()
			for i,k in pairs(MODULE:GetData("listings", {}, true)) do
				if(k.Text == vtab.OText) then
					k.Text = vtab.Text
					k.Interval = vtab.Interval
					k.IntervalString = vtab.IntervalString
					k.Values = vtab.Values
					break
				end
			end
			sendListings(Vermilion:GetUsersWithPermission("manage_auto_broadcast"))
		end
	end)

	self:NetHook("VDelAutoBroadcastListing", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_auto_broadcast")) then
			local target = net.ReadInt(32)
			table.remove(MODULE:GetData("listings", {}, true), target)
			sendListings(Vermilion:GetUsersWithPermission("manage_auto_broadcast"))
		end
	end)
end

function MODULE:InitClient()

	self:NetHook("VGetAutoBroadcastListing", function()
		local paneldata = Vermilion.Menu.Pages["autobroadcast"]
		if(IsValid(paneldata.Panel)) then
			paneldata.MessageTable:Clear()
			for i,k in pairs(net.ReadTable()) do
				local ln = paneldata.MessageTable:AddLine(k.Text, k.IntervalString)
				ln.TotalTime = k.Interval
				ln.Values = k.Values
			end
			paneldata.MessageTable:OnRowSelected()
		end
	end)

	Vermilion.Menu:AddCategory("server", 2)

	Vermilion.Menu:AddPage({
			ID = "autobroadcast",
			Name = Vermilion:TranslateStr("menu:autobroadcast"),
			Order = 6,
			Category = "server",
			Size = { 785, 540 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_auto_broadcast")
			end,
			Builder = function(panel, paneldata)
				local listings = VToolkit:CreateList({
					cols = MODULE:TranslateTable({ "list:text", "list:interval" }),
					multiselect = true
				})
				listings:SetPos(10, 30)
				listings:SetSize(765, 460)
				listings:SetParent(panel)

				listings.Columns[2]:SetFixedWidth(100)

				paneldata.MessageTable = listings

				local listingsLabel = VToolkit:CreateHeaderLabel(listings, MODULE:TranslateStr("list:title"))
				listingsLabel:SetParent(panel)

				local removeListing = VToolkit:CreateButton(MODULE:TranslateStr("remove"), function()
					if(table.Count(listings:GetSelected()) == 0) then
						return
					end
					local tab = {}
					local rtab = {}
					for i,k in pairs(listings:GetLines()) do
						for i1,k1 in pairs(listings:GetSelected()) do
							if(k1 == k) then
								MODULE:NetStart("VDelAutoBroadcastListing")
								net.WriteInt(i, 32)
								net.SendToServer()
								break
							end
						end
					end
				end)
				removeListing:SetPos(670, 500)
				removeListing:SetSize(105, 30)
				removeListing:SetParent(panel)
				removeListing:SetDisabled(true)
				
				
				local editMessagePanel = VToolkit:CreateRightDrawer(panel, 0, true)
				paneldata.EditMessagePanel = editMessagePanel

				local emessageBox = VToolkit:CreateTextbox("")
				emessageBox:SetPos(10, 40)
				emessageBox:SetSize(425, 410)
				emessageBox:SetParent(editMessagePanel)
				emessageBox:SetMultiline(true)



				local etimeLabel = VToolkit:CreateLabel(MODULE:TranslateStr("new:interval"))
				etimeLabel:SetPos(10, 470)
				etimeLabel:SetDark(true)
				etimeLabel:SetParent(editMessagePanel)



				local edaysLabel = VToolkit:CreateLabel(MODULE:TranslateStr("dayslabel"))
				edaysLabel:SetPos(10 + ((64 - edaysLabel:GetWide()) / 2), 490)
				edaysLabel:SetParent(editMessagePanel)

				local edaysWang = VToolkit:CreateNumberWang(0, 999)
				edaysWang:SetPos(10, 505)
				edaysWang:SetParent(editMessagePanel)



				local ehoursLabel = VToolkit:CreateLabel(MODULE:TranslateStr("hourslabel"))
				ehoursLabel:SetPos(84 + ((64 - ehoursLabel:GetWide()) / 2), 490)
				ehoursLabel:SetParent(editMessagePanel)

				local ehoursWang = VToolkit:CreateNumberWang(0, 24)
				ehoursWang:SetPos(84, 505)
				ehoursWang:SetParent(editMessagePanel)
				ehoursWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 24) then
						wang:SetValue(0)
						edaysWang:SetValue(edaysWang:GetValue() + 1)
					end
				end



				local eminsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("minuteslabel"))
				eminsLabel:SetPos(158 + ((64 - eminsLabel:GetWide()) / 2), 490)
				eminsLabel:SetParent(editMessagePanel)

				local eminsWang = VToolkit:CreateNumberWang(0, 60)
				eminsWang:SetPos(158, 505)
				eminsWang:SetParent(editMessagePanel)
				eminsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						ehoursWang:SetValue(ehoursWang:GetValue() + 1)
					end
				end



				local esecondsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("secondslabel"))
				esecondsLabel:SetPos(232 + ((64 - esecondsLabel:GetWide()) / 2), 490)
				esecondsLabel:SetParent(editMessagePanel)

				local esecondsWang = VToolkit:CreateNumberWang(0, 60)
				esecondsWang:SetPos(232, 505)
				esecondsWang:SetParent(editMessagePanel)
				esecondsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						eminsWang:SetValue(eminsWang:GetValue() + 1)
					end
				end

				local editListingButton = VToolkit:CreateButton(MODULE:TranslateStr("edit:add"), function()
					local time = 0
					-- seconds per year = 31557600
					-- average seconds per month = 2592000
					-- seconds per week = 604800
					-- seconds per day = 86400
					-- seconds per hour = 3600

					time = time + (esecondsWang:GetValue())
					time = time + (eminsWang:GetValue() * 60)
					time = time + (ehoursWang:GetValue() * 3600)
					time = time + (edaysWang:GetValue() * 86400)

					if(time == 0) then
						VToolkit:CreateErrorDialog(MODULE:TranslateStr("new:gz"))
						return
					end

					MODULE:NetStart("VUpdateAutoBroadcastListing")
					net.WriteTable({ OText = editMessagePanel.OriginalMessage, Text = emessageBox:GetValue(), IntervalString = tostring(edaysWang:GetValue()) .. "d " .. tostring(ehoursWang:GetValue()) .. "h " .. tostring(eminsWang:GetValue()) .. "m " .. tostring(esecondsWang:GetValue()) .. "s", Interval = time, Values = { d = edaysWang:GetValue(), h = ehoursWang:GetValue(), m = eminsWang:GetValue(), s = esecondsWang:GetValue() } })
					net.SendToServer()

					emessageBox:SetValue("")
					editMessagePanel:Close()
				end)
				editListingButton:SetPos(326, 495)
				editListingButton:SetSize(105, 30)
				editListingButton:SetParent(editMessagePanel)
				
				
				local editListing = VToolkit:CreateButton(MODULE:TranslateStr("edit"), function()
					if(table.Count(listings:GetSelected()) == 0) then
						VToolkit:CreateErrorDialog(MODULE:TranslateStr("edit:g1"))
						return
					end
					
					local ln = listings:GetSelected()[1]
					
					emessageBox:SetValue(ln:GetValue(1))
					
					if(ln.Values != nil) then
						edaysWang:SetValue(ln.Values.d)
						ehoursWang:SetValue(ln.Values.h)
						eminsWang:SetValue(ln.Values.m)
						esecondsWang:SetValue(ln.Values.s)
					end
					
					editMessagePanel.OriginalMessage = ln:GetValue(1)
					
					editMessagePanel:Open()
				end)
				editListing:SetPos(555, 500)
				editListing:SetSize(105, 30)
				editListing:SetParent(panel)
				editListing:SetDisabled(true)
				


				function listings:OnRowSelected(index, line)
					local enabled = self:GetSelected()[1] == nil
					removeListing:SetDisabled(enabled)
					editListing:SetDisabled(table.Count(self:GetSelected()) != 1)
				end


				local addMessagePanel = VToolkit:CreateRightDrawer(panel, 0, true)
				paneldata.AddMessagePanel = addMessagePanel

				local addMessageButton = VToolkit:CreateButton(MODULE:TranslateStr("new"), function()
					addMessagePanel:Open()
				end)
				addMessageButton:SetPos(10, 500)
				addMessageButton:SetSize(105, 30)
				addMessageButton:SetParent(panel)


				local messageBox = VToolkit:CreateTextbox("")
				messageBox:SetPos(10, 40)
				messageBox:SetSize(425, 410)
				messageBox:SetParent(addMessagePanel)
				messageBox:SetMultiline(true)



				local timeLabel = VToolkit:CreateLabel(MODULE:TranslateStr("new:interval"))
				timeLabel:SetPos(10, 470)
				timeLabel:SetDark(true)
				timeLabel:SetParent(addMessagePanel)



				local daysLabel = VToolkit:CreateLabel(MODULE:TranslateStr("dayslabel"))
				daysLabel:SetPos(10 + ((64 - daysLabel:GetWide()) / 2), 490)
				daysLabel:SetParent(addMessagePanel)

				local daysWang = VToolkit:CreateNumberWang(0, 999)
				daysWang:SetPos(10, 505)
				daysWang:SetParent(addMessagePanel)



				local hoursLabel = VToolkit:CreateLabel(MODULE:TranslateStr("hourslabel"))
				hoursLabel:SetPos(84 + ((64 - hoursLabel:GetWide()) / 2), 490)
				hoursLabel:SetParent(addMessagePanel)

				local hoursWang = VToolkit:CreateNumberWang(0, 24)
				hoursWang:SetPos(84, 505)
				hoursWang:SetParent(addMessagePanel)
				hoursWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 24) then
						wang:SetValue(0)
						daysWang:SetValue(daysWang:GetValue() + 1)
					end
				end



				local minsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("minuteslabel"))
				minsLabel:SetPos(158 + ((64 - minsLabel:GetWide()) / 2), 490)
				minsLabel:SetParent(addMessagePanel)

				local minsWang = VToolkit:CreateNumberWang(0, 60)
				minsWang:SetPos(158, 505)
				minsWang:SetParent(addMessagePanel)
				minsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						hoursWang:SetValue(hoursWang:GetValue() + 1)
					end
				end



				local secondsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("secondslabel"))
				secondsLabel:SetPos(232 + ((64 - secondsLabel:GetWide()) / 2), 490)
				secondsLabel:SetParent(addMessagePanel)

				local secondsWang = VToolkit:CreateNumberWang(0, 60)
				secondsWang:SetPos(232, 505)
				secondsWang:SetParent(addMessagePanel)
				secondsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						minsWang:SetValue(minsWang:GetValue() + 1)
					end
				end

				local addListingButton = VToolkit:CreateButton(MODULE:TranslateStr("new:add"), function()
					local time = 0
					-- seconds per year = 31557600
					-- average seconds per month = 2592000
					-- seconds per week = 604800
					-- seconds per day = 86400
					-- seconds per hour = 3600

					time = time + (secondsWang:GetValue())
					time = time + (minsWang:GetValue() * 60)
					time = time + (hoursWang:GetValue() * 3600)
					time = time + (daysWang:GetValue() * 86400)

					if(time == 0) then
						VToolkit:CreateErrorDialog(MODULE:TranslateStr("new:gz"))
						return
					end

					MODULE:NetStart("VAddAutoBroadcastListing")
					net.WriteTable({ Text = messageBox:GetValue(), IntervalString = tostring(daysWang:GetValue()) .. "d " .. tostring(hoursWang:GetValue()) .. "h " .. tostring(minsWang:GetValue()) .. "m " .. tostring(secondsWang:GetValue()) .. "s", Interval = time, Values = { d = daysWang:GetValue(), h = hoursWang:GetValue(), m = minsWang:GetValue(), s = secondsWang:GetValue() } })
					net.SendToServer()

					messageBox:SetValue("")
					secondsWang:SetValue(0)
					minsWang:SetValue(0)
					hoursWang:SetValue(0)
					daysWang:SetValue(0)
					addMessagePanel:Close()
				end)
				addListingButton:SetPos(326, 495)
				addListingButton:SetSize(105, 30)
				addListingButton:SetParent(addMessagePanel)
				
				
				editMessagePanel:MoveToFront()
				addMessagePanel:MoveToFront()
			end,
			OnOpen = function(panel, paneldata)
				MODULE:NetCommand("VGetAutoBroadcastListing")
				paneldata.AddMessagePanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
			end
		})
end
