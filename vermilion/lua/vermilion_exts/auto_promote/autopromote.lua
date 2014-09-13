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
EXTENSION.Name = "Auto-Promote"
EXTENSION.ID = "auto_promote"
EXTENSION.Description = "Automatically promotes users after time spent on the server."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"manage_autopromote"
}
EXTENSION.PermissionDefinitions = {
	["manage_autopromote"] = "This player can view the Auto-Promote tab on the Vermilion Menu and modify the settings within."
}
EXTENSION.NetworkStrings = {
	"VGetAutoPromoteListing",
	"VSetAutoPromoteListing"
}

function EXTENSION:InitServer()
	
	timer.Create("V-AutoPromote", 10, 0, function()
		local promotionData = EXTENSION:GetData("promotion_listings", {}, true)
		for i,k in pairs(player.GetHumans()) do
			local vdata = Vermilion:GetUser(k)
			local rank = vdata:GetRank()
			for i1,k1 in pairs(promotionData) do
				if(k1.Rank == rank.Name) then
					if(vdata.Playtime >= k1.Playtime) then
						vdata:SetRank(k1.ToRank)
						Vermilion:BroadcastNotify(k:GetName() .. " was automatically promoted to " .. k1.ToRank .. " after playing for " .. k1.PlaytimeString .. "!", 10)
					end
					break
				end
			end
		end
	end)
	
	self:NetHook("VGetAutoPromoteListing", function(vplayer)
		net.Start("VGetAutoPromoteListing")
		net.WriteTable(EXTENSION:GetData("promotion_listings", {}, true))
		net.Send(vplayer)
	end)
	
	self:NetHook("VSetAutoPromoteListing", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_autopromote")) then
			EXTENSION:SetData("promotion_listings", net.ReadTable())
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("auto_promote", "manage_autopromote")
	end)
	
end

function EXTENSION:InitClient()

	self:NetHook("VGetAutoPromoteListing", function()
		if(IsValid(EXTENSION.PromotionTable)) then
			EXTENSION.PromotionTable:Clear()
			local tab = net.ReadTable()
			for i,k in pairs(tab) do
				--[[
					Java Code to calculate times:
					long different = end.getTime() - start.getTime();
					long secInMil = 1000;
					long minInMil = secInMil * 60;
					long hrsInMil = minInMil * 60;
					long dayInMil = hrsInMil * 24;
					long elapsedDays = different / dayInMil;
					different = different % dayInMil;
					long elapsedHours = different / hrsInMil;
					different = different % hrsInMil;
					long elapsedMins = different / minInMil;
					different = different % minInMil;
					long elapsedSeconds = different / secInMil;
					return new long[]{elapsedDays, elapsedHours, elapsedMins, elapsedSeconds};
				]]
				EXTENSION.PromotionTable:AddLine(k.Rank, k.ToRank, k.PlaytimeString).TotalTime = k.Playtime
			end
		end
	end)
	
	self:AddHook("VRanksList", function(tab)
		if(IsValid(EXTENSION.FromRankCombo) and IsValid(EXTENSION.ToRankCombo)) then
			EXTENSION.ToRankCombo:Clear()
			EXTENSION.FromRankCombo:Clear()
			for i,k in pairs(tab) do
				EXTENSION.ToRankCombo:AddChoice(k[1])
				EXTENSION.FromRankCombo:AddChoice(k[1])
			end
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("auto_promote", "Auto-Promote", "clock_add.png", "Allow users to be promoted to different ranks after playing on the server for some time.", function(panel)
			local listings = Crimson.CreateList({"From Rank", "To Rank", "After Playing For"}, false)
			listings:SetPos(10, 30)
			listings:SetSize(765, 320)
			listings:SetParent(panel)
			
			EXTENSION.PromotionTable = listings
			
			local listingsLabel = Crimson:CreateHeaderLabel(listings, "Auto-Promotion Listings")
			listingsLabel:SetParent(panel)
			
			local removeListing = Crimson.CreateButton("Remove Listing", function()
				if(table.Count(listings:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one listing to remove.")
					return
				end
				local tab = {}
				for i,k in pairs(listings:GetLines()) do
					local add = true
					for i1,k1 in pairs(listings:GetSelected()) do
						if(k1 == k) then add = false break end
					end
					if(add) then
						table.insert(tab, { k:GetValue(1), k:GetValue(2), k:GetValue(3), k.TotalTime })
					end
				end
				listings:Clear()
				for i,k in pairs(tab) do
					listings:AddLine(k[1], k[2], k[3]).TotalTime = k[4]
				end
			end)
			removeListing:SetPos(670, 360)
			removeListing:SetSize(105, 30)
			removeListing:SetParent(panel)
			
			local saveListings = Crimson.CreateButton("Save Listings", function()
				local tab = {}
				for i,k in pairs(listings:GetLines()) do
					table.insert(tab, { Rank = k:GetValue(1), ToRank = k:GetValue(2), PlaytimeString = k:GetValue(3), Playtime = k.TotalTime})
				end
				net.Start("VSetAutoPromoteListing")
				net.WriteTable(tab)
				net.SendToServer()
			end)
			saveListings:SetPos(555, 360)
			saveListings:SetSize(105, 30)
			saveListings:SetParent(panel)
			
			local fromRankLabel = vgui.Create("DLabel")
			fromRankLabel:SetPos(10, 402)
			fromRankLabel:SetText("From Rank: ")
			fromRankLabel:SizeToContents()
			fromRankLabel:SetDark(true)
			fromRankLabel:SetParent(panel)
			
			local fromRankCombo = vgui.Create("DComboBox")
			fromRankCombo:SetPos(fromRankLabel:GetWide() + 20, 400)
			fromRankCombo:SetSize(200, 20)
			fromRankCombo:SetParent(panel)
			fromRankCombo:SetValue("From Rank")
			fromRankCombo.OnSelect = function(panel, index, value)
				fromRankCombo.SelectedValue = value
			end
			EXTENSION.FromRankCombo = fromRankCombo
			
			local toRankLabel = vgui.Create("DLabel")
			toRankLabel:SetPos(10, 432)
			toRankLabel:SetText("To Rank: ")
			toRankLabel:SizeToContents()
			toRankLabel:SetDark(true)
			toRankLabel:SetParent(panel)
			
			local toRankCombo = vgui.Create("DComboBox")
			toRankCombo:SetPos(toRankLabel:GetWide() + 20, 430)
			toRankCombo:SetSize(200, 20)
			toRankCombo:SetParent(panel)
			toRankCombo:SetValue("To Rank")
			toRankCombo.OnSelect = function(panel, index, value)
				toRankCombo.SelectedValue = value
			end
			EXTENSION.ToRankCombo = toRankCombo
			
			local timeLabel = vgui.Create("DLabel")
			timeLabel:SetPos(10, 460)
			timeLabel:SetText("After Playing For (running total since first ever spawn, not since last promotion):")
			timeLabel:SizeToContents()
			timeLabel:SetDark(true)
			timeLabel:SetParent(panel)
			
			local daysLabel = Crimson.CreateLabel("Days:")
			daysLabel:SetPos(10 + ((64 - daysLabel:GetWide()) / 2), 480)
			daysLabel:SetParent(panel)
			
			local daysWang = Crimson.CreateNumberWang(0, 999)
			daysWang:SetPos(10, 495)
			daysWang:SetParent(panel)
			
			
			
			local hoursLabel = Crimson.CreateLabel("Hours:")
			hoursLabel:SetPos(84 + ((64 - hoursLabel:GetWide()) / 2), 480)
			hoursLabel:SetParent(panel)
			
			local hoursWang = Crimson.CreateNumberWang(0, 24)
			hoursWang:SetPos(84, 495)
			hoursWang:SetParent(panel)
			hoursWang.OnValueChanged = function(wang, val)
				if(tonumber(val) == 24) then
					wang:SetValue(0)
					daysWang:SetValue(daysWang:GetValue() + 1)
				end
			end
			
			
			
			local minsLabel = Crimson.CreateLabel("Minutes:")
			minsLabel:SetPos(158 + ((64 - minsLabel:GetWide()) / 2), 480)
			minsLabel:SetParent(panel)
			
			local minsWang = Crimson.CreateNumberWang(0, 60)
			minsWang:SetPos(158, 495)
			minsWang:SetParent(panel)
			minsWang.OnValueChanged = function(wang, val)
				if(tonumber(val) == 60) then
					wang:SetValue(0)
					hoursWang:SetValue(hoursWang:GetValue() + 1)
				end
			end
			
			
			
			local secondsLabel = Crimson.CreateLabel("Seconds:")
			secondsLabel:SetPos(232 + ((64 - secondsLabel:GetWide()) / 2), 480)
			secondsLabel:SetParent(panel)
			
			local secondsWang = Crimson.CreateNumberWang(0, 60)
			secondsWang:SetPos(232, 495)
			secondsWang:SetParent(panel)
			secondsWang.OnValueChanged = function(wang, val)
				if(tonumber(val) == 60) then
					wang:SetValue(0)
					minsWang:SetValue(minsWang:GetValue() + 1)
				end
			end
			
			local addListingButton = Crimson.CreateButton("Add Listing", function()
				if(fromRankCombo.SelectedValue == nil or toRankCombo.SelectedValue == nil) then
					Crimson:CreateErrorDialog("Please input the initial rank and the target rank correctly!")
					return
				end
				if(fromRankCombo.SelectedValue == toRankCombo.SelectedValue) then
					Crimson:CreateErrorDialog("Must select two different ranks.")
					return
				end
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
					Crimson:CreateErrorDialog("Must have playtime greater than zero.")
					return
				end
				
				listings:AddLine(fromRankCombo.SelectedValue, toRankCombo.SelectedValue, tostring(daysWang:GetValue()) .. "d " .. tostring(hoursWang:GetValue()) .. "h " .. tostring(minsWang:GetValue()) .. "m " .. tostring(secondsWang:GetValue()) .. "s").TotalTime = time
				
			end)
			addListingButton:SetPos(306, 485)
			addListingButton:SetSize(105, 30)
			addListingButton:SetParent(panel)
			
			net.Start("VGetAutoPromoteListing")
			net.SendToServer()
			
		end, 2.1)
	end)

end

Vermilion:RegisterExtension(EXTENSION)