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

AddCSLuaFile()

local MODULE = Vermilion:GetModule("prop_protect")

function MODULE:BuddyListInitServer()

	function MODULE:GetBuddyLists()
		return MODULE:GetData("buddylist", {}, true)
	end

	function MODULE:GetBuddyList(vplayer)
		if(not IsValid(vplayer)) then return end
		local lists = self:GetBuddyLists()
		if(lists[vplayer:SteamID()] == nil) then
			lists[vplayer:SteamID()] = {}
		end
		return lists[vplayer:SteamID()]
	end

	function MODULE:GetBuddyListSteamID(steamid)
		local lists = self:GetBuddyLists()
		if(lists[steamid] == nil) then
			lists[steamid] = {}
		end
		return lists[steamid]
	end

	function MODULE:IsBuddyOf(vplayer, buddy)
		if(not IsValid(vplayer) or not IsValid(buddy) or not vplayer:IsPlayer() or not buddy:IsPlayer()) then return false end
		for i,k in pairs(self:GetBuddyList(vplayer)) do
			if(k.SteamID == buddy:SteamID()) then return true end
		end
		return false
	end

	function MODULE:BuddyCanRunAction(vplayer, buddy, action)
		if(not IsValid(buddy) or not buddy:IsPlayer()) then return false end
		if(vplayer == nil) then return true end
		local blist = self:GetBuddyListSteamID(vplayer)
		if(blist == nil) then return false end
		for i,k in pairs(blist) do
			if(k.SteamID == buddy:SteamID() and k.Permissions != nil) then
				return table.HasValue(k.Permissions, action)
			end
		end
		return false
	end

	function MODULE:AddBuddy(vplayer, buddy)
		if(not IsValid(vplayer) or not IsValid(buddy) or not vplayer:IsPlayer() or not buddy:IsPlayer()) then return end
		if(table.Count(self:GetBuddyList(vplayer)) >= 64) then return end
		table.insert(self:GetBuddyList(vplayer), { SteamID = buddy:SteamID(), Permissions = {} })
	end

	function MODULE:DelBuddy(vplayer, buddy)
		if(not IsValid(vplayer) or not IsValid(buddy) or not vplayer:IsPlayer() or not buddy:IsPlayer()) then return end
		for i,k in pairs(self:GetBuddyList(vplayer)) do
			if(k.SteamID == buddy:SteamID()) then self:GetBuddyList(vplayer)[i] = nil end
		end
	end

	function MODULE:DelBuddyBySteamID(vplayer, buddy)
		if(not IsValid(vplayer) or not vplayer:IsPlayer()) then return end
		for i,k in pairs(self:GetBuddyList(vplayer)) do
			if(k.SteamID == buddy) then self:GetBuddyList(vplayer)[i] = nil end
		end
	end

	function MODULE:GetActiveBuddies(vplayer)
		if(not IsValid(vplayer) or not vplayer:IsPlayer()) then return end
		local tab = {}
		for i,k in pairs(MODULE:GetBuddyList(vplayer)) do
			local t = VToolkit.LookupPlayerBySteamID(k.SteamID)
			if(IsValid(t)) then table.insert(tab, t) end
		end
		return tab
	end

	local function sendBuddyList(vplayer, steamid)
		MODULE:NetStart("VGetBuddyList")
		local blist = MODULE:GetBuddyListSteamID(steamid)
		local tab = {}
		for i,k in pairs(blist) do
			if(Vermilion:GetUserBySteamID(k.SteamID) != nil) then
				table.insert(tab, { Name = Vermilion:GetUserBySteamID(k.SteamID).Name, SteamID = k.SteamID, Permissions = k.Permissions })
			end
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end

	self:NetHook("VGetBuddyList", function(vplayer)
		sendBuddyList(vplayer, net.ReadString())
	end)

	self:NetHook("VAddBuddy", function(vplayer)
		local blist = MODULE:GetBuddyList(vplayer)
		if(table.Count(blist) >= 64) then return end
		table.insert(blist, { SteamID = net.ReadString(), Permissions = {} })
		sendBuddyList(vplayer, vplayer:SteamID())
	end)

	self:NetHook("VDelBuddy", function(vplayer)
		local blist = MODULE:GetBuddyList(vplayer)
		local tplayer = net.ReadString()
		for i,k in pairs(blist) do
			if(k.SteamID == tplayer) then blist[i] = nil break end
		end
		sendBuddyList(vplayer, vplayer:SteamID())
	end)

	self:NetHook("VGetBuddyPermissions", function(vplayer)
		local blist = MODULE:GetBuddyList(vplayer)
		local tplayer = net.ReadString()

		local has = false
		for i,k in pairs(blist) do
			if(k.SteamID == tplayer) then
				has = k
				break
			end
		end
		if(not has) then return end

		MODULE:NetStart("VGetBuddyPermissions")
		net.WriteTable(has.Permissions)
		net.Send(vplayer)
	end)

	self:NetHook("VUpdateBuddyPermissions", function(vplayer)
		local blist = MODULE:GetBuddyList(vplayer)
		local tplayer = net.ReadString()
		local typ = net.ReadString()
		local val = net.ReadBoolean()

		local has = false
		for i,k in pairs(blist) do
			if(k.SteamID == tplayer) then
				has = k
				break
			end
		end
		if(not has) then return end
		if(val) then
			if(not table.HasValue(has.Permissions, typ)) then table.insert(has.Permissions, typ) end
		else
			table.RemoveByValue(has.Permissions, typ)
		end
	end)

end

function MODULE:BuddyListInitClient()

	self:NetHook("VGetBuddyList", function()
		local blist = net.ReadTable()
		local paneldata = Vermilion.Menu.Pages["buddylist"]

		paneldata.BuddyList:Clear()
		paneldata.QuotaBar:SetFraction(table.Count(blist) / 64)
		paneldata.QuotaHeader:SetText(MODULE:TranslateStr("quotaheader", { tostring(table.Count(blist)) }))

		for i,k in pairs(blist) do
			local plyr = VToolkit.LookupPlayerBySteamID(k.SteamID)
			local friendStatus = "Unknown"
			if(IsValid(plyr)) then
				if(plyr:GetFriendStatus() == "friend") then
					friendStatus = "Friend"
				elseif(plyr:GetFriendStatus() == "none") then
					friendStatus = "Not Friends"
				end
			end
			paneldata.BuddyList:AddLine(k.Name, k.SteamID, friendStatus)
		end
	end)

	self:NetHook("VGetBuddyPermissions", function()
		local paneldata = Vermilion.Menu.Pages["buddylist"]
		local data = net.ReadTable()

		for i,k in pairs(paneldata.PermissionsCheckboxes) do
			k.UpdatingFromServer = true
			k:SetChecked(table.HasValue(data, i))
			k.UpdatingFromServer = false
		end
	end)

	Vermilion.Menu:AddPage({
		ID = "buddylist",
		Name = "Buddy List",
		Order = 0.8,
		Category = "basic",
		Size = { 700, 640 },
		Builder = function(panel, paneldata)
			local buddies = VToolkit:CreateList({
				cols = {
					"Name",
					"SteamID",
					"Friend"
				}
			})
			buddies:SetPos(10, 30)
			buddies:SetParent(panel)
			buddies:SetSize(500, 600)
			paneldata.BuddyList = buddies



			VToolkit:CreateHeaderLabel(buddies, "Buddies"):SetParent(panel)

			local quotaBar = vgui.Create("DProgress")
			quotaBar:SetPos(520, 600)
			quotaBar:SetSize(panel:GetWide() - quotaBar:GetX() - 10, 20)
			quotaBar:SetParent(panel)
			paneldata.QuotaBar = quotaBar

			local quotaHeader = VToolkit:CreateHeaderLabel(quotaBar, MODULE:TranslateStr("quotaheader", { "0" }))
			quotaHeader:SetParent(panel)
			paneldata.QuotaHeader = quotaHeader

			local addBuddyDrawer = VToolkit:CreateRightDrawer(panel, 0)
			paneldata.AddBuddyDrawer = addBuddyDrawer

			local addBuddyList = VToolkit:CreateList({
				cols = {
					"Name"
				}
			})
			addBuddyList:SetPos(10, 40)
			addBuddyList:SetSize(200, panel:GetTall() - 50)
			addBuddyList:SetParent(addBuddyDrawer)
			paneldata.AddBuddyList = addBuddyList

			VToolkit:CreateSearchBox(addBuddyList)

			local addBuddyHeader = VToolkit:CreateHeaderLabel(addBuddyList, MODULE:TranslateStr("activeplayers"))
			addBuddyHeader:SetParent(addBuddyDrawer)

			local addBuddyFinalBtn = VToolkit:CreateButton("Add Player(s)", function()
				if(table.Count(addBuddyList:GetSelected()) == 0) then
					VToolkit:CreateErrorDialog("Must select at least one player to add.")
					return
				end
				addBuddyDrawer:Close()
				MODULE:NetStart("VAddBuddy")
				net.WriteString(addBuddyList:GetSelected()[1].SteamID)
				net.SendToServer()
			end)
			addBuddyFinalBtn:SetTall(30)
			addBuddyFinalBtn:SetPos(addBuddyDrawer:GetWide() - 185, (addBuddyDrawer:GetTall() - addBuddyFinalBtn:GetTall()) / 2)
			addBuddyFinalBtn:SetWide(addBuddyDrawer:GetWide() - addBuddyFinalBtn:GetX() - 15)
			addBuddyFinalBtn:SetParent(addBuddyDrawer)

			local addBuddyBtn = VToolkit:CreateButton("Add Buddy", function()
				addBuddyDrawer:Open()
			end)
			addBuddyBtn:SetParent(panel)
			addBuddyBtn:SetPos(520, 30)
			addBuddyBtn:SetSize(panel:GetWide() - addBuddyBtn:GetX() - 10, 20)


			local editBuddyDrawer = VToolkit:CreateRightDrawer(panel, 0)
			paneldata.EditBuddyDrawer = editBuddyDrawer

			local permissionsList = VToolkit:CreateList({
				cols = {
					"Name",
					""
				},
				multiselect = false
			})
			permissionsList:SetPos(10, 50)
			permissionsList:SetParent(editBuddyDrawer)
			permissionsList:SetSize(editBuddyDrawer:GetWide() - 20, editBuddyDrawer:GetTall() - 70)

			permissionsList.Columns[2]:SetMaxWidth(20)


			local permissions = {
				{ "Toolgun", "toolgun" },
				{ "Gravity Gun", "gravgun" },
				{ "Physics Gun", "physgun" },
				{ "Use", "use" },
				{ "Drive", "drive" },
				{ "Break", "break" },
				{ "Edit Properties", "property" },
				{ "Edit Variables", "variable" }
			}

			local permissionsCB = {}

			for i,k in pairs(permissions) do
				local ln = permissionsList:AddLine(k[1])
				ln.MachineText = k[2]
				local cb = VToolkit:CreateCheckBox("")
				ln.Columns[2]:Add(cb)
				function ln:OnMousePressed(mcode)
					cb:Toggle()
				end
				function ln:IsLineSelected() return false end
				function cb:OnChange(val)
					if(not self.UpdatingFromServer) then
						MODULE:NetStart("VUpdateBuddyPermissions")
						net.WriteString(buddies:GetSelected()[1]:GetValue(2))
						net.WriteString(ln.MachineText)
						net.WriteBoolean(val)
						net.SendToServer()
					end
				end
				permissionsCB[k[2]] = cb
			end
			paneldata.PermissionsCheckboxes = permissionsCB

			local editPermissionsBtn = VToolkit:CreateButton("Edit Buddy Permissions", function()
				MODULE:NetStart("VGetBuddyPermissions")
				net.WriteString(buddies:GetSelected()[1]:GetValue(2))
				net.SendToServer()
				editBuddyDrawer:Open()
			end)
			editPermissionsBtn:SetParent(panel)
			editPermissionsBtn:SetPos(520, 60)
			editPermissionsBtn:SetSize(panel:GetWide() - editPermissionsBtn:GetX() - 10, 20)
			editPermissionsBtn:SetDisabled(true)
			paneldata.EditPermissionsButton = editPermissionsBtn



			local deleteBuddyBtn = VToolkit:CreateButton("Delete Buddy", function()
				MODULE:NetStart("VDelBuddy")
				net.WriteString(buddies:GetSelected()[1]:GetValue(2))
				net.SendToServer()
			end)
			deleteBuddyBtn:SetParent(panel)
			deleteBuddyBtn:SetPos(520, 90)
			deleteBuddyBtn:SetSize(panel:GetWide() - deleteBuddyBtn:GetX() - 10, 20)
			deleteBuddyBtn:SetDisabled(true)
			paneldata.DelBuddyBtn = deleteBuddyBtn

			function buddies:OnRowSelected(index, line)
				editPermissionsBtn:SetDisabled(self:GetSelected()[1] == nil)
				deleteBuddyBtn:SetDisabled(self:GetSelected()[1] == nil)
			end

			addBuddyDrawer:MoveToFront()
			editBuddyDrawer:MoveToFront()
		end,
		OnOpen = function(panel, paneldata)
			paneldata.BuddyList:Clear()
			paneldata.QuotaBar:SetFraction(0)
			paneldata.QuotaHeader:SetText(MODULE:TranslateStr("quotaheader", { "0" }))
			MODULE:NetStart("VGetBuddyList")
			net.WriteString(LocalPlayer():SteamID())
			net.SendToServer()

			paneldata.AddBuddyList:Clear()
			for i,k in pairs(VToolkit.GetValidPlayers()) do
				if(k:SteamID() == LocalPlayer():SteamID()) then continue end
				paneldata.AddBuddyList:AddLine(k:GetName()).SteamID = k:SteamID()
			end
			paneldata.AddBuddyDrawer:Close()
			paneldata.EditBuddyDrawer:Close()
			paneldata.EditPermissionsButton:SetDisabled(true)
			paneldata.DelBuddyBtn:SetDisabled(true)
		end
	})

end
