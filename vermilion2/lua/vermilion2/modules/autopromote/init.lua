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
MODULE.Name = "Auto-Promote"
MODULE.ID = "auto_promote"
MODULE.Description = "Automatically promotes users to different ranks depending on playtime."
MODULE.Author = "Ned"
MODULE.Tabs = {
	"autopromote"
}
MODULE.Permissions = {
	"manage_autopromote"
}
MODULE.NetworkStrings = {
	"VGetAutoPromoteListings",
	"VAddAutoPromoteListing",
	"VDelAutoPromoteListings",
	"VEditAutoPromoteListing"
}

function MODULE:InitServer()

	-- check the listings for consistency when a rank is deleted to make sure we
	-- are not promoting people from or to a non-existent rank.
	self:AddHook(Vermilion.Event.RankDeleted, function(uid)
		for i,k in pairs(MODULE:GetData("promotion_listings_mk2", {}, true)) do
			if(k.Rank == uid or k.ToRank == uid) then
				table.RemoveByValue(MODULE:GetData("promotion_listings_mk2", {}, true), k)
			end
		end
	end)

	function MODULE:CreateListingUID()
		local vars = string.ToTable("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -- source array, modify this to make more complex IDs.
		local out = ""
		for i=1,15,1 do -- 15 chars long
			out = out .. table.Random(vars)
		end

		for i,k in pairs(self:GetData("promotion_listings_mk2", {}, true)) do
			if(k.UniqueID == out) then return self:CreateListingUID() end -- make completely sure that we are not duplicating rank IDs.
		end

		return out
	end

	-- upgrade the old format
	if(not self:GetData("promotion_listings_mk2", nil) and self:GetData("promotion_listings", nil)) then
		Vermilion.Log("Updating Auto-Promote data storage to UID model...")
		self:SetData("promotion_listings_mk2", {})
		for i,k in pairs(MODULE:GetData("promotion_listings", {}, true)) do
			local tab = {}
			tab.UniqueID = self:CreateListingUID()
			tab.Rank = Vermilion:GetRank(k.Rank):GetUID()
			tab.ToRank = Vermilion:GetRank(k.ToRank):GetUID()
			tab.TimerValues = {
				S = k.Playtime % 60,
				M = math.floor((k.Playtime % 3600) / 60),
				H = math.floor((k.Playtime % 86400) / 3600),
				D = math.floor((k.Playtime % 2592000) / 86400)
			}
			table.insert(self:GetData("promotion_listings_mk2", {}, true), tab)
		end
		MODULE:SetData("promotion_listings", nil)
		Vermilion.Log("Auto-Promote data storage upgraded...")
	end

	local pDataMeta = {}
	function pDataMeta:GetTotalTime()
		return (self.TimerValues.S) + (self.TimerValues.M * 60) + (self.TimerValues.H * 3600) + (self.TimerValues.D * 86400)
	end
	function pDataMeta:GetTotalTimeString()
		return tostring(self.TimerValues.D) .. "d " .. tostring(self.TimerValues.H) .. "h " .. tostring(self.TimerValues.M) .. "m " .. tostring(self.TimerValues.S) .. "s"
	end


	for i,k in pairs(MODULE:GetData("promotion_listings_mk2", {}, true)) do
		setmetatable(k, { __index = pDataMeta })
	end

	function sendAutoPromoteListings(vplayer)
		MODULE:NetStart("VGetAutoPromoteListings")

			local tab = {}
			for i,k in pairs(MODULE:GetData("promotion_listings_mk2", {}, true)) do
				local t1 = {}
				t1.UniqueID = k.UniqueID
				t1.Rank = k.Rank
				t1.ToRank = k.ToRank

				-- add these two values since the metatable doesn't exist on the client.
				t1.TimerValues = k.TimerValues
				t1.TValuesString = k:GetTotalTimeString()


				table.insert(tab, t1)
			end

			net.WriteTable(tab)
			net.Send(vplayer)
	end


	self:NetHook("VGetAutoPromoteListings", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_autopromote")) then
			sendAutoPromoteListings(vplayer)
		end
	end)

	self:NetHook("VAddAutoPromoteListing", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_autopromote")) then
			local tab = net.ReadTable()
			tab.UniqueID = self:CreateListingUID()
			setmetatable(tab, { __index = pDataMeta })
			table.insert(MODULE:GetData("promotion_listings_mk2", {}, true), tab)
			sendAutoPromoteListings(Vermilion:GetUsersWithPermission("manage_autopromote"))
		end
	end)

	self:NetHook("VDelAutoPromoteListings", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_autopromote")) then
			local tab = net.ReadTable()
			for i,k in pairs(tab) do
				for i1,k1 in pairs(MODULE:GetData("promotion_listings_mk2", {}, true)) do
					if(k1.UniqueID == k) then
						table.RemoveByValue(MODULE:GetData("promotion_listings_mk2", {}, true), k1)
						break
					end
				end
			end
			sendAutoPromoteListings(Vermilion:GetUsersWithPermission("manage_autopromote"))
		end
	end)

	self:NetHook("VEditAutoPromoteListing", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_autopromote")) then
			local tab = net.ReadTable()
			for i,k in pairs(MODULE:GetData("promotion_listings_mk2", {}, true)) do
				if(k.UniqueID == tab.UniqueID) then
					k.Rank = tab.Rank
					k.ToRank = tab.ToRank
					k.TimerValues = tab.TimerValues
					sendAutoPromoteListings(Vermilion:GetUsersWithPermission("manage_autopromote"))
					break
				end
			end
		end
	end)

	timer.Create("V-AutoPromote", 10, 0, function()
		local pdata = MODULE:GetData("promotion_listings_mk2", {}, true)
		for i,k in pairs(player.GetHumans()) do
			local vPlayerData = Vermilion:GetUser(k)
			if(vPlayerData == nil) then
				Vermilion.Log("Cannot autopromote; the management engine is missing userdata!")
				continue
			end
			local rank = vPlayerData:GetRank()
			for i1,k1 in pairs(pdata) do
				if(k1.Rank == rank:GetUID()) then
					if(vPlayerData.Playtime >= k1:GetTotalTime()) then
						vPlayerData:SetRank(k1.ToRank)
						MODULE:TransBroadcastNotify("autodone", { k:GetName(), Vermilion:GetRankByID(k1.ToRank), k1:GetTotalTimeString() })
					end
				end
			end
		end
	end)

end

function MODULE:InitClient()

	self:NetHook("VGetAutoPromoteListings", function()
		local paneldata = Vermilion.Menu.Pages["autopromote"]
		if(IsValid(paneldata.Panel)) then
			paneldata.Listings:Clear()
			local tab = net.ReadTable()
			for i,k in pairs(tab) do
				local ln = paneldata.Listings:AddLine(Vermilion:GetRankByID(k.Rank):GetName(), Vermilion:GetRankByID(k.ToRank):GetName(), k.TValuesString)
				ln.ListingUID = k.UniqueID
				ln.TimerValues = k.TimerValues
				ln.FromRankUID = k.Rank
				ln.ToRankUID = k.ToRank
			end
			paneldata.Listings:OnRowSelected()
		end
	end)

	function buildAddAutoPromote(panel, paneldata)
		local drawer = VToolkit:CreateRightDrawer(panel, 0, true)

		local fromRankLabel = VToolkit:CreateLabel(MODULE:TranslateStr("from"))
		fromRankLabel:SetPos(10, 52)
		fromRankLabel:SetDark(true)
		fromRankLabel:SetParent(drawer)

		local fromRankCombo = VToolkit:CreateComboBox(nil, nil, true)
		fromRankCombo:SetPos(fromRankLabel:GetWide() + 20, 50)
		fromRankCombo:SetSize(250, 20)
		fromRankCombo:SetParent(drawer)
		fromRankCombo:SetValue("From Rank")
		fromRankCombo.OnSelect = function(panel, index, value)
			fromRankCombo.SelectedValue = fromRankCombo:GetOptionData(index)
		end
		paneldata.AddFromRankCombo = fromRankCombo

		local toRankLabel = VToolkit:CreateLabel(MODULE:TranslateStr("to"))
		toRankLabel:SetPos(10, 82)
		toRankLabel:SetDark(true)
		toRankLabel:SetParent(drawer)

		local toRankCombo = VToolkit:CreateComboBox(nil, nil, true)
		toRankCombo:SetPos(toRankLabel:GetWide() + 20, 80)
		toRankCombo:SetSize(250, 20)
		toRankCombo:SetParent(drawer)
		toRankCombo:SetValue("To Rank")
		toRankCombo.OnSelect = function(panel, index, value)
			toRankCombo.SelectedValue = toRankCombo:GetOptionData(index)
		end
		paneldata.AddToRankCombo = toRankCombo

		local off = math.Max(fromRankLabel:GetWide(), toRankLabel:GetWide())
		fromRankCombo:SetX(off + 20)
		toRankCombo:SetX(off + 20)

		fromRankCombo:SetWide(drawer:GetWide() - 40 - off)
		toRankCombo:SetWide(drawer:GetWide() - 40 - off)

		local wangs = vgui.Create("DPanel")
		wangs:SetDrawBackground(false)
		wangs:SetParent(drawer)

		local timeLabel = VToolkit:CreateLabel(MODULE:TranslateStr("after"))
		timeLabel:SetPos(10, 120)
		timeLabel:SetDark(true)
		timeLabel:SetParent(drawer)

		local daysLabel = VToolkit:CreateLabel(MODULE:TranslateStr("dayslabel"))
		daysLabel:SetPos(10 + ((64 - daysLabel:GetWide()) / 2), 0)
		daysLabel:SetParent(wangs)

		local daysWang = VToolkit:CreateNumberWang(0, 999)
		daysWang:SetPos(10, 15)
		daysWang:SetParent(wangs)



		local hoursLabel = VToolkit:CreateLabel(MODULE:TranslateStr("hourslabel"))
		hoursLabel:SetPos(84 + ((64 - hoursLabel:GetWide()) / 2), 0)
		hoursLabel:SetParent(wangs)

		local hoursWang = VToolkit:CreateNumberWang(0, 24)
		hoursWang:SetPos(84, 15)
		hoursWang:SetParent(wangs)
		hoursWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 24) then
				wang:SetValue(0)
				daysWang:SetValue(daysWang:GetValue() + 1)
			end
		end



		local minsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("minuteslabel"))
		minsLabel:SetPos(158 + ((64 - minsLabel:GetWide()) / 2), 0)
		minsLabel:SetParent(wangs)

		local minsWang = VToolkit:CreateNumberWang(0, 60)
		minsWang:SetPos(158, 15)
		minsWang:SetParent(wangs)
		minsWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 60) then
				wang:SetValue(0)
				hoursWang:SetValue(hoursWang:GetValue() + 1)
			end
		end



		local secondsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("secondslabel"))
		secondsLabel:SetPos(232 + ((64 - secondsLabel:GetWide()) / 2), 0)
		secondsLabel:SetParent(wangs)

		local secondsWang = VToolkit:CreateNumberWang(0, 60)
		secondsWang:SetPos(232, 15)
		secondsWang:SetParent(wangs)
		secondsWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 60) then
				wang:SetValue(0)
				minsWang:SetValue(minsWang:GetValue() + 1)
			end
		end

		wangs:SetSize(secondsWang:GetX() + secondsWang:GetWide() + 10, secondsWang:GetY() + secondsWang:GetTall())
		wangs:SetPos((drawer:GetWide() - wangs:GetWide()) / 2, 140)

		timeLabel:MoveToFront()

		local addButton = VToolkit:CreateButton(MODULE:TranslateStr("add"), function()
			local from = fromRankCombo.SelectedValue
			local to = toRankCombo.SelectedValue

			if(from == nil or to == nil) then
				VToolkit:CreateErrorDialog(MODULE:TranslateStr("add:error:inittarrank"))
				return
			end

			if(from == to) then
				VToolkit:CreateErrorDialog(MODULE:TranslateStr("add:error:diff"))
				return
			end

			for i,k in pairs(paneldata.Listings:GetLines()) do
				if(k.FromRankUID == from and k.ToRankUID == to) then
					VToolkit:CreateErrorDialog(MODULE:TranslateStr("add:error:exists"))
					return
				end
			end

			if(secondsWang:GetValue() == 0 and minsWang:GetValue() == 0 and hoursWang:GetValue() == 0 and daysWang:GetValue() == 0) then
				VToolkit:CreateErrorDialog(MODULE:TranslateStr("add:error:time:0"))
				return
			end

			local tab = {}
			tab.Rank = from
			tab.ToRank = to
			tab.TimerValues = {
				S = secondsWang:GetValue(),
				M = minsWang:GetValue(),
				H = hoursWang:GetValue(),
				D = daysWang:GetValue()
			}

			MODULE:NetStart("VAddAutoPromoteListing")
			net.WriteTable(tab)
			net.SendToServer()

			fromRankCombo:SetValue("")
			toRankCombo:SetValue("")
			secondsWang:SetValue(0)
			minsWang:SetValue(0)
			hoursWang:SetValue(0)
			daysWang:SetValue(0)

			drawer:Close()
		end)
		addButton:SetPos(10, wangs:GetY() + wangs:GetTall() + 20)
		addButton:SetSize(drawer:GetWide() - 20, 30)
		addButton:SetParent(drawer)

		return drawer
	end

	function buildEditAutoPromote(panel, paneldata)
		local drawer = VToolkit:CreateRightDrawer(panel, 0, true)

		local fromRankLabel = VToolkit:CreateLabel(MODULE:TranslateStr("from"))
		fromRankLabel:SetPos(10, 52)
		fromRankLabel:SetDark(true)
		fromRankLabel:SetParent(drawer)

		local fromRankCombo = VToolkit:CreateComboBox(nil, nil, true)
		fromRankCombo:SetPos(fromRankLabel:GetWide() + 20, 50)
		fromRankCombo:SetSize(250, 20)
		fromRankCombo:SetParent(drawer)
		fromRankCombo:SetValue("From Rank")
		fromRankCombo.OnSelect = function(panel, index, value)
			fromRankCombo.SelectedValue = fromRankCombo:GetOptionData(index)
		end
		paneldata.EditFromRankCombo = fromRankCombo

		local toRankLabel = VToolkit:CreateLabel(MODULE:TranslateStr("to"))
		toRankLabel:SetPos(10, 82)
		toRankLabel:SetDark(true)
		toRankLabel:SetParent(drawer)

		local toRankCombo = VToolkit:CreateComboBox(nil, nil, true)
		toRankCombo:SetPos(toRankLabel:GetWide() + 20, 80)
		toRankCombo:SetSize(250, 20)
		toRankCombo:SetParent(drawer)
		toRankCombo:SetValue("To Rank")
		toRankCombo.OnSelect = function(panel, index, value)
			toRankCombo.SelectedValue = toRankCombo:GetOptionData(index)
		end
		paneldata.EditToRankCombo = toRankCombo

		local off = math.Max(fromRankLabel:GetWide(), toRankLabel:GetWide())
		fromRankCombo:SetX(off + 20)
		toRankCombo:SetX(off + 20)

		fromRankCombo:SetWide(drawer:GetWide() - 40 - off)
		toRankCombo:SetWide(drawer:GetWide() - 40 - off)

		local wangs = vgui.Create("DPanel")
		wangs:SetDrawBackground(false)
		wangs:SetParent(drawer)

		local timeLabel = VToolkit:CreateLabel(MODULE:TranslateStr("after"))
		timeLabel:SetPos(10, 120)
		timeLabel:SetDark(true)
		timeLabel:SetParent(drawer)

		local daysLabel = VToolkit:CreateLabel(MODULE:TranslateStr("dayslabel"))
		daysLabel:SetPos(10 + ((64 - daysLabel:GetWide()) / 2), 0)
		daysLabel:SetParent(wangs)

		local daysWang = VToolkit:CreateNumberWang(0, 999)
		daysWang:SetPos(10, 15)
		daysWang:SetParent(wangs)
		drawer.DaysWang = daysWang



		local hoursLabel = VToolkit:CreateLabel(MODULE:TranslateStr("hourslabel"))
		hoursLabel:SetPos(84 + ((64 - hoursLabel:GetWide()) / 2), 0)
		hoursLabel:SetParent(wangs)

		local hoursWang = VToolkit:CreateNumberWang(0, 24)
		hoursWang:SetPos(84, 15)
		hoursWang:SetParent(wangs)
		hoursWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 24) then
				wang:SetValue(0)
				daysWang:SetValue(daysWang:GetValue() + 1)
			end
		end
		drawer.HoursWang = hoursWang



		local minsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("minuteslabel"))
		minsLabel:SetPos(158 + ((64 - minsLabel:GetWide()) / 2), 0)
		minsLabel:SetParent(wangs)

		local minsWang = VToolkit:CreateNumberWang(0, 60)
		minsWang:SetPos(158, 15)
		minsWang:SetParent(wangs)
		minsWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 60) then
				wang:SetValue(0)
				hoursWang:SetValue(hoursWang:GetValue() + 1)
			end
		end
		drawer.MinsWang = minsWang



		local secondsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("secondslabel"))
		secondsLabel:SetPos(232 + ((64 - secondsLabel:GetWide()) / 2), 0)
		secondsLabel:SetParent(wangs)

		local secondsWang = VToolkit:CreateNumberWang(0, 60)
		secondsWang:SetPos(232, 15)
		secondsWang:SetParent(wangs)
		secondsWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 60) then
				wang:SetValue(0)
				minsWang:SetValue(minsWang:GetValue() + 1)
			end
		end
		drawer.SecondsWang = secondsWang

		wangs:SetSize(secondsWang:GetX() + secondsWang:GetWide() + 10, secondsWang:GetY() + secondsWang:GetTall())
		wangs:SetPos((drawer:GetWide() - wangs:GetWide()) / 2, 140)

		timeLabel:MoveToFront()

		local addButton = VToolkit:CreateButton(MODULE:TranslateStr("editapply"), function()
			local from = fromRankCombo.SelectedValue
			local to = toRankCombo.SelectedValue

			if(from == nil or to == nil) then
				VToolkit:CreateErrorDialog(MODULE:TranslateStr("add:error:inittarrank"))
				return
			end

			if(from == to) then
				VToolkit:CreateErrorDialog(MODULE:TranslateStr("add:error:diff"))
				return
			end

			for i,k in pairs(paneldata.Listings:GetLines()) do
				if(k.FromRankUID == from and k.ToRankUID == to) then
					VToolkit:CreateErrorDialog(MODULE:TranslateStr("add:error:exists"))
					return
				end
			end

			if(secondsWang:GetValue() == 0 and minsWang:GetValue() == 0 and hoursWang:GetValue() == 0 and daysWang:GetValue() == 0) then
				VToolkit:CreateErrorDialog(MODULE:TranslateStr("add:error:time:0"))
				return
			end

			local tab = {}
			tab.UniqueID = drawer.CurrentUID
			tab.Rank = from
			tab.ToRank = to
			tab.TimerValues = {
				S = secondsWang:GetValue(),
				M = minsWang:GetValue(),
				H = hoursWang:GetValue(),
				D = daysWang:GetValue()
			}

			MODULE:NetStart("VEditAutoPromoteListing")
			net.WriteTable(tab)
			net.SendToServer()

			fromRankCombo:SetValue("")
			toRankCombo:SetValue("")
			secondsWang:SetValue(0)
			minsWang:SetValue(0)
			hoursWang:SetValue(0)
			daysWang:SetValue(0)

			drawer:Close()
		end)
		addButton:SetPos(10, wangs:GetY() + wangs:GetTall() + 20)
		addButton:SetSize(drawer:GetWide() - 20, 30)
		addButton:SetParent(drawer)

		return drawer
	end

	Vermilion.Menu:AddCategory("ranks", 3)

	Vermilion.Menu:AddPage({
		ID = "autopromote",
		Name = Vermilion:TranslateStr("menu:autopromote"),
		Order = 6,
		Category = "ranks",
		Size = { 700, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_autopromote")
		end,
		Builder = function(panel, paneldata)
			local listings = VToolkit:CreateList({
				cols = {
					MODULE:TranslateStr("list:from"),
					MODULE:TranslateStr("list:to"),
					MODULE:TranslateStr("list:after")
				},
				multiselect = false
			})
			listings:SetPos(10, 30)
			listings:SetSize(400, panel:GetTall() - 40)
			listings:SetParent(panel)
			paneldata.Listings = listings

			local listingsLabel = VToolkit:CreateHeaderLabel(listings, MODULE:TranslateStr("header"))
			listingsLabel:SetParent(panel)


			local addPanel = buildAddAutoPromote(panel, paneldata)

			local addButton = VToolkit:CreateButton(MODULE:TranslateStr("addmain"), function()
				addPanel:Open()
			end)
			addButton:SetParent(panel)
			addButton:SetPos(panel:GetWide() - 285, 30)
			addButton:SetSize(panel:GetWide() - addButton:GetX() - 5, 30)

			local editPanel = buildEditAutoPromote(panel, paneldata)

			local editButton = VToolkit:CreateButton(MODULE:TranslateStr("edit"), function()
				local ln = listings:GetSelected()[1]
				for i,k in pairs(paneldata.EditFromRankCombo.Data) do
					if(k == ln.FromRankUID) then
						paneldata.EditFromRankCombo:ChooseOptionID(i)
						break
					end
				end
				for i,k in pairs(paneldata.EditToRankCombo.Data) do
					if(k == ln.ToRankUID) then
						paneldata.EditToRankCombo:ChooseOptionID(i)
						break
					end
				end
				editPanel.DaysWang:SetValue(ln.TimerValues.D)
				editPanel.HoursWang:SetValue(ln.TimerValues.H)
				editPanel.MinsWang:SetValue(ln.TimerValues.M)
				editPanel.SecondsWang:SetValue(ln.TimerValues.S)

				editPanel.CurrentUID = ln.ListingUID

				editPanel:Open()
			end)
			editButton:SetParent(panel)
			editButton:SetPos(panel:GetWide() - 285, 70)
			editButton:SetSize(panel:GetWide() - editButton:GetX() - 5, 30)
			editButton:SetDisabled(true)

			local delButton = VToolkit:CreateButton(MODULE:TranslateStr("removemain"), function()
				local tab = {}
				for i,k in pairs(listings:GetSelected()) do
					table.insert(tab, k.ListingUID)
				end
				MODULE:NetStart("VDelAutoPromoteListings")
				net.WriteTable(tab)
				net.SendToServer()
			end)
			delButton:SetParent(panel)
			delButton:SetPos(panel:GetWide() - 285, 110)
			delButton:SetSize(panel:GetWide() - delButton:GetX() - 5, 30)
			delButton:SetDisabled(true)

			function listings:OnRowSelected(index, line)
				editButton:SetDisabled(table.Count(self:GetSelected()) != 1)
				delButton:SetDisabled(self:GetSelected()[1] == nil)
			end

			addPanel:MoveToFront()
			editPanel:MoveToFront()

		end,
		OnOpen = function(panel, paneldata)
			MODULE:NetCommand("VGetAutoPromoteListings")

			paneldata.AddFromRankCombo:Clear()
			paneldata.AddToRankCombo:Clear()
			paneldata.EditFromRankCombo:Clear()
			paneldata.EditToRankCombo:Clear()
			for i,k in pairs(Vermilion.Data.RankOverview) do
				if(k.Name != "owner") then
					paneldata.AddFromRankCombo:AddChoice(k.Name, k.UniqueID)
					paneldata.EditFromRankCombo:AddChoice(k.Name, k.UniqueID)
				end
				paneldata.AddToRankCombo:AddChoice(k.Name, k.UniqueID)
				paneldata.EditToRankCombo:AddChoice(k.Name, k.UniqueID)
			end
		end
	})

end
