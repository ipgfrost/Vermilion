--[[
 Copyright 2015-16 Ned Hyett,

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
MODULE.Name = "Kits"
MODULE.ID = "kits"
MODULE.Description = "Create sets of weapons that players can request via commands."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_kits",
	"kitsubscribe",
	"getkit"
}
MODULE.NetworkStrings = {
	"AddKit",
	"DelKit",
	"RenameKit",
	"ListKits",
	"GetKitContents",
	"AddKitContents",
	"DelKitContents",
	"GetAllowedRanks",
	"AddAllowedRank",
	"DelAllowedRank"
}

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "kitsubscribe",
		Description = "Subscribe to a kit to have it given to you each time you spawn.",
		Syntax = "<kitname>",
		CanRunOnDS = false,
		Permissions = { "kitsubscribe" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = {}
				local rnk = Vermilion:GetUser(vplayer):GetRankUID()
				for i,k in pairs(MODULE:GetData("kits", {}, true)) do
					if(table.HasValue(k.RanksAllowed, rnk)) then
						table.insert(tab, k.Name)
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log("bad_syntax", nil, NOTIFY_ERROR)
				return false
			end
			local has = false
			for i,k in pairs(MODULE:GetData("kits", {}, true)) do
				if(k.Name == text[1]) then
					has = true
					break
				end
			end
			if(not has) then return end
			log("Subscribed to kit '" .. text[1] .. "' successfully!")
			MODULE:GetData("subscriptions", {}, true)[sender:SteamID()] = text[1]
		end
	})

	Vermilion:AddChatCommand({
		Name = "kitunsubscribe",
		Description = "Clears a subscription to a kit.",
		CanRunOnDS = false,
		Function = function(sender, text, log, glog)
			log("Unsubscribed from kit successfully!")
			MODULE:GetData("subscriptions", {}, true)[sender:SteamID()] = nil
		end
	})
end

function MODULE:InitServer()

	function MODULE:WouldRun(ply)
		return MODULE:GetData("subscriptions", {}, true)[ply:SteamID()] != nil
	end

	self:AddHook("PlayerLoadout", function(ply)
		if(MODULE:GetData("subscriptions", {}, true)[ply:SteamID()] != nil) then
			local kit = nil
			for i,k in pairs(MODULE:GetData("kits", {}, true)) do
				if(k.Name == MODULE:GetData("subscriptions", {}, true)[ply:SteamID()]) then
					kit = k
					break
				end
			end
			if(kit == nil) then return end
			ply:StripWeapons()
			for i,k in pairs(kit.Contents) do
				ply:Give(k)
			end
			return true
		end
	end)

	local function sendKitList(vplayer)
		local tab = {}
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			table.insert(tab, k.Name)
		end
		MODULE:NetStart("ListKits")
		net.WriteTable(tab)
		net.Send(vplayer)
	end

	local function sendKitContent(vplayer, kitname)
		MODULE:NetStart("GetKitContents")
		net.WriteString(kitname)
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			if(k.Name == kitname) then
				net.WriteTable(k.Contents)
				break
			end
		end
		net.Send(vplayer)
	end

	self:NetHook("ListKits", function(vplayer)
		sendKitList(vplayer)
	end)

	self:NetHook("AddKit", { "manage_kits" }, function(vplayer)
		local name = net.ReadString()
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			if(k.Name == name) then return end
		end
		table.insert(MODULE:GetData("kits", {}, true), {
			Name = name,
			Contents = {},
			RanksAllowed = {}
		})
		sendKitList(Vermilion:GetUsersWithPermission("manage_kits"))
	end)

	self:NetHook("DelKit", { "manage_kits" }, function(vplayer)
		local name = net.ReadString()
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			if(k.Name == name) then
				table.RemoveByValue(MODULE:GetData("kits", {}, true), k)
				break
			end
		end
		sendKitList(Vermilion:GetUsersWithPermission("manage_kits"))
	end)

	self:NetHook("GetKitContents", { "manage_kits" }, function(vplayer)
		local name = net.ReadString()
		sendKitContent(vplayer, name)
	end)

	self:NetHook("AddKitContents", { "manage_kits" }, function(vplayer)
		local name = net.ReadString()
		local weapon = net.ReadString()

		local kit = nil
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			if(k.Name == name) then
				kit = k
				break
			end
		end
		if(kit == nil) then return end
		if(not table.HasValue(kit.Contents, weapon)) then
			table.insert(kit.Contents, weapon)
		end
		sendKitContent(Vermilion:GetUsersWithPermission("manage_kits"), name)
	end)

	self:NetHook("DelKitContents", { "manage_kits" }, function(vplayer)
		local name = net.ReadString()
		local weapon = net.ReadString()

		local kit = nil
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			if(k.Name == name) then
				kit = k
				break
			end
		end
		if(kit == nil) then return end
		table.RemoveByValue(kit.Contents, weapon)
		sendKitContent(Vermilion:GetUsersWithPermission("manage_kits"), name)
	end)

	self:NetHook("RenameKit", { "manage_kits" }, function(vplayer)
		local name = net.ReadString()
		local newName = net.ReadString()

		for i,k in pairs(MODULE:GetData("subscriptions", {}, true)) do
			if(k == name) then k = newName end
		end

		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			if(k.Name == name) then
				k.Name = newName
				break
			end
		end
		sendKitList(Vermilion:GetUsersWithPermission("manage_kits"))
	end)

	self:NetHook("GetAllowedRanks", function(vplayer)
		local name = net.ReadString()
		local kit = nil
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			if(k.Name == name) then
				kit = k
				break
			end
		end
		if(kit == nil) then return end
		MODULE:NetStart("GetAllowedRanks")
		net.WriteString(name)
		net.WriteTable(kit.RanksAllowed)
		net.Send(vplayer)
	end)

	self:NetHook("AddAllowedRank", { "manage_kits" }, function(vplayer)
		local name = net.ReadString()
		local kit = nil
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			if(k.Name == name) then
				kit = k
				break
			end
		end
		if(kit == nil) then return end
		local rankname = net.ReadString()
		if(not table.HasValue(kit.RanksAllowed, rankname)) then table.insert(kit.RanksAllowed, rankname) end
	end)

	self:NetHook("DelAllowedRank", { "manage_kits" }, function(vplayer)
		local name = net.ReadString()
		local kit = nil
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			if(k.Name == name) then
				kit = k
				break
			end
		end
		if(kit == nil) then return end
		local rankname = net.ReadString()
		table.RemoveByValue(kit.RanksAllowed, rankname)
	end)

	self:NetHook(Vermilion.Event.RankDeleted, function(uid)
		for i,k in pairs(MODULE:GetData("kits", {}, true)) do
			for i1,k1 in pairs(k.RanksAllowed) do
				if(k1 == uid) then k.RanksAllowed[i1] = nil end
			end
		end
	end)

end

function MODULE:InitClient()

	self:NetHook("ListKits", function()
		local paneldata = Vermilion.Menu.Pages["kit_creator"]
		local tab = net.ReadTable()
		paneldata.KitList:Clear()
		for i,k in pairs(tab) do
			paneldata.KitList:AddLine(k)
		end
	end)

	self:NetHook("GetKitContents", function()
		if(Vermilion.Menu.Pages["kit_creator"].KitList:GetSelected()[1] == nil) then return end
		if(Vermilion.Menu.Pages["kit_creator"].KitList:GetSelected()[1]:GetValue(1) != net.ReadString()) then return end
		local data = net.ReadTable()
		local kit_contents_list = Vermilion.Menu.Pages["kit_creator"].KitContents
		local weps = Vermilion.Menu.Pages["kit_creator"].Weapons
		if(IsValid(kit_contents_list)) then
			kit_contents_list:Clear()
			for i,k in pairs(data) do
				for i1,k1 in pairs(weps) do
					if(k1.ClassName == k) then
						kit_contents_list:AddLine(k1.Name).ClassName = k
					end
				end
			end
		end
	end)

	self:NetHook("GetAllowedRanks", function(vplayer)
		local name = net.ReadString()
		local data = net.ReadTable()
		local paneldata = Vermilion.Menu.Pages["kit_creator"]
		local allowedrnks = paneldata.KitPermissionsAllowedRanks
		allowedrnks:Clear()
		for i,k in pairs(data) do
			allowedrnks:AddLine(k)
		end
	end)

	Vermilion.Menu:AddCategory("player", 4)

	self:AddMenuPage({
		ID = "kit_creator",
		Name = "Kit Creator",
		Order = 10,
		Category = "player",
		Size = { 900, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_kits")
		end,
		Builder = function(panel, paneldata)
			local addKit = nil
			local delKit = nil
			local renKit = nil
			local openKitPermissions = nil
			local giveWeapon = nil
			local takeWeapon = nil
			local kitList = nil
			local allPermissions = nil
			local kitContents = nil

			local default = {
				["weapon_crowbar"] = "models/weapons/w_crowbar.mdl",
				["weapon_pistol"] = "models/weapons/w_pistol.mdl",
				["weapon_smg1"] = "models/weapons/w_smg1.mdl",
				["weapon_frag"] = "models/weapons/w_grenade.mdl",
				["weapon_physcannon"] = "models/weapons/w_Physics.mdl",
				["weapon_crossbow"] = "models/weapons/w_crossbow.mdl",
				["weapon_shotgun"] = "models/weapons/w_shotgun.mdl",
				["weapon_357"] = "models/weapons/w_357.mdl",
				["weapon_rpg"] = "models/weapons/w_rocket_launcher.mdl",
				["weapon_ar2"] = "models/weapons/w_irifle.mdl",
				["weapon_bugbait"] = "models/weapons/w_bugbait.mdl",
				["weapon_slam"] = "models/weapons/w_slam.mdl",
				["weapon_stunstick"] = "models/weapons/w_stunbaton.mdl",
				["weapon_physgun"] = "models/weapons/w_Physics.mdl"
			}
			function paneldata.getMdl(class)
				if(default[class] != nil) then return default[class] end
				return weapons.Get(class).WorldModel
			end

			paneldata.PreviewPanel = VToolkit:CreatePreviewPanel("model", panel, function(ent)
				ent:SetPos(Vector(20, 20, 45))
			end)


			kitList = VToolkit:CreateList({
				cols = {
					"Name"
				},
				multiselect = false,
				centre = true
			})
			kitList:SetPos(10, 30)
			kitList:SetSize(200, panel:GetTall() - 110)
			kitList:SetParent(panel)
			paneldata.KitList = kitList

			VToolkit:CreateSearchBox(kitList)

			local kitHeader = VToolkit:CreateHeaderLabel(kitList, "Kits")
			kitHeader:SetParent(panel)

			function kitList:OnRowSelected(index, line)
				giveWeapon:SetDisabled(not (self:GetSelected()[1] != nil and allPermissions:GetSelected()[1] != nil))
				takeWeapon:SetDisabled(not (self:GetSelected()[1] != nil and kitContents:GetSelected()[1] != nil))
				delKit:SetDisabled(self:GetSelected()[1] == nil)
				renKit:SetDisabled(self:GetSelected()[1] == nil)
				openKitPermissions:SetDisabled(self:GetSelected()[1] == nil)
				MODULE:NetStart("GetKitContents")
				net.WriteString(self:GetSelected()[1]:GetValue(1))
				net.SendToServer()
			end

			local addKitPanel = VToolkit:CreateLeftDrawer(panel)
			paneldata.AddKitPanel = addKitPanel

			local kitName = VToolkit:CreateTextbox()
			kitName:SetPos(10, 40)
			kitName:SetSize(addKitPanel:GetWide() - 25, 25)
			kitName:SetParent(addKitPanel)

			local addKitFinalButton = VToolkit:CreateButton("Add Kit", function()
				local fKitName = kitName:GetValue()
				if(fKitName == nil or fKitName == "") then
					VToolkit:CreateErrorDialog("Invalid kit name!")
					return
				end
				for i,k in pairs(kitList:GetLines()) do
					if(k:GetValue(1) == fKitName) then
						VToolkit:CreateErrorDialog("Kit already exists!")
						return
					end
				end
				kitList:AddLine(fKitName)
				MODULE:NetStart("AddKit")
				net.WriteString(fKitName)
				net.SendToServer()
				addKitPanel:Close()
				kitName:SetValue("")
			end)
			addKitFinalButton:SetPos(10, 75)
			addKitFinalButton:SetSize(addKitPanel:GetWide() - 25, 25)
			addKitFinalButton:SetParent(addKitPanel)

			addKit = VToolkit:CreateButton("New Kit", function()
				addKitPanel:Open()
			end)
			addKit:SetPos(10, panel:GetTall() - 70)
			addKit:SetSize(98, 25)
			addKit:SetParent(panel)

			delKit = VToolkit:CreateButton("Delete Kit", function()
				VToolkit:CreateConfirmDialog("Really delete kit?", function()
					MODULE:NetStart("DelKit")
					net.WriteString(kitList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
					delKit:SetDisabled(true)
					renKit:SetDisabled(true)
					openKitPermissions:SetDisabled(true)
					kitList:RemoveLine(kitList:GetSelected()[1]:GetID())
				end, { Confirm = "Yes", Deny = "No", Default = false })
			end)
			delKit:SetPos(210 - 98, panel:GetTall() - 70)
			delKit:SetSize(98, 25)
			delKit:SetParent(panel)
			delKit:SetDisabled(true)
			paneldata.DelKit = delKit

			local renKitPanel = VToolkit:CreateLeftDrawer(panel)
			paneldata.RenKitPanel = renKitPanel

			local newKitName = VToolkit:CreateTextbox()
			newKitName:SetPos(10, 40)
			newKitName:SetSize(renKitPanel:GetWide() - 25, 25)
			newKitName:SetParent(renKitPanel)

			local renKitFinalButton = VToolkit:CreateButton("Rename Kit", function()
				local fKitName = newKitName:GetValue()
				if(fKitName == nil or fKitName == "") then
					VToolkit:CreateErrorDialog("Invalid kit name!")
					return
				end
				for i,k in pairs(kitList:GetLines()) do
					if(k:GetValue(1) == fKitName) then
						VToolkit:CreateErrorDialog("Kit already exists!")
						return
					end
				end
				local oldKitName = kitList:GetSelected()[1]:GetValue(1)
				kitList:GetSelected()[1]:SetValue(1, fKitName)
				MODULE:NetStart("RenameKit")
				net.WriteString(oldKitName)
				net.WriteString(fKitName)
				net.SendToServer()
				renKitPanel:Close()
				kitName:SetValue("")
			end)
			renKitFinalButton:SetPos(10, 75)
			renKitFinalButton:SetSize(renKitPanel:GetWide() - 25, 25)
			renKitFinalButton:SetParent(renKitPanel)

			renKit = VToolkit:CreateButton("Rename Kit", function()
				newKitName:SetValue(kitList:GetSelected()[1]:GetValue(1))
				renKitPanel:Open()
			end)
			renKit:SetPos(10, panel:GetTall() - 35)
			renKit:SetSize(98, 25)
			renKit:SetDisabled(true)
			renKit:SetParent(panel)
			paneldata.RenKit = renKit

			local kitPermissionPanel = VToolkit:CreateLeftDrawer(panel, 100)
			paneldata.KitPermissionPanel = kitPermissionPanel

			local kitPermissionsAllRanks = VToolkit:CreateList({
				cols = {
					"Name"
				},
				sortable = false,
				multiselect = false
			})
			kitPermissionsAllRanks:SetParent(kitPermissionPanel)
			kitPermissionsAllRanks:SetPos(10, 40)
			kitPermissionsAllRanks:SetSize(200, kitPermissionPanel:GetTall() - 50)
			paneldata.KitPermissionsAllRanks = kitPermissionsAllRanks

			VToolkit:CreateHeaderLabel(kitPermissionsAllRanks, "Ranks"):SetParent(kitPermissionPanel)

			local kitPermissionsAllowedRanks = VToolkit:CreateList({
				cols = {
					"Name"
				},
				sortable = false,
				multiselect = false
			})
			kitPermissionsAllowedRanks:SetParent(kitPermissionPanel)
			kitPermissionsAllowedRanks:SetPos(380, 40)
			kitPermissionsAllowedRanks:SetSize(200, kitPermissionPanel:GetTall() - 50)
			paneldata.KitPermissionsAllowedRanks = kitPermissionsAllowedRanks

			VToolkit:CreateHeaderLabel(kitPermissionsAllowedRanks, "Allowed Ranks"):SetParent(kitPermissionPanel)
			VToolkit:CreateHeaderLabel(kitPermissionsAllRanks, "Ranks"):SetParent(kitPermissionPanel)

			local addKitPermission = VToolkit:CreateButton("Allow", function()
				if(kitPermissionsAllRanks:GetSelected()[1] == nil) then
					VToolkit:CreateErrorDialog("Must select at least one rank to add to the list of allowed ranks!")
					return
				end
				for i,k in pairs(kitPermissionsAllRanks:GetSelected()) do
					local has = false
					for i1,k1 in pairs(kitPermissionsAllowedRanks:GetLines()) do
						if(k1:GetValue(1) == k:GetValue(1)) then
							has = true
							break
						end
					end
					if(not has) then
						kitPermissionsAllowedRanks:AddLine(k:GetValue(1))
						MODULE:NetStart("AddAllowedRank")
						net.WriteString(kitList:GetSelected()[1]:GetValue(1))
						net.WriteString(k:GetValue(1))
						net.SendToServer()
					end
				end
			end)
			addKitPermission:SetPos(220, 100)
			addKitPermission:SetSize(150, 20)
			addKitPermission:SetParent(kitPermissionPanel)

			local remKitPermission = VToolkit:CreateButton("Deny", function()
				if(kitPermissionsAllowedRanks:GetSelected()[1] == nil) then
					VToolkit:CreateErrorDialog("Must select at least one rank to remove from the list of allowed ranks!")
					return
				end
				for i,k in pairs(kitPermissionsAllowedRanks:GetSelected()) do
					MODULE:NetStart("DelAllowedRank")
					net.WriteString(kitList:GetSelected()[1]:GetValue(1))
					net.WriteString(k:GetValue(1))
					net.SendToServer()
					kitPermissionsAllowedRanks:RemoveLine(k:GetID())
				end
			end)
			remKitPermission:SetPos(220, 130)
			remKitPermission:SetSize(150, 20)
			remKitPermission:SetParent(kitPermissionPanel)


			openKitPermissions = VToolkit:CreateButton("Permissions", function()
				MODULE:NetStart("GetAllowedRanks")
				net.WriteString(kitList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				kitPermissionPanel:Open()
			end)
			openKitPermissions:SetPos(210 - 98, panel:GetTall() - 35)
			openKitPermissions:SetSize(98, 25)
			openKitPermissions:SetParent(panel)
			openKitPermissions:SetDisabled(true)
			paneldata.OpenKitPermissions = openKitPermissions



			kitContents = VToolkit:CreateList({
				cols = {
					"Name"
				}
			})
			kitContents:SetPos(220, 30)
			kitContents:SetSize(240, panel:GetTall() - 40)
			kitContents:SetParent(panel)
			paneldata.KitContents = kitContents

			local kitContentsHeader = VToolkit:CreateHeaderLabel(kitContents, "Kit Contents")
			kitContentsHeader:SetParent(panel)

			function kitContents:OnRowSelected(index, line)
				takeWeapon:SetDisabled(not (self:GetSelected()[1] != nil and kitList:GetSelected()[1] != nil))
			end

			VToolkit:CreateSearchBox(kitContents)


			allPermissions = VToolkit:CreateList({
				cols = {
					"Name"
				}
			})
			allPermissions:SetPos(panel:GetWide() - 250, 30)
			allPermissions:SetSize(240, panel:GetTall() - 40)
			allPermissions:SetParent(panel)
			paneldata.AllPermissions = allPermissions

			local allPermissionsHeader = VToolkit:CreateHeaderLabel(allPermissions, "All Weapons")
			allPermissionsHeader:SetParent(panel)

			function allPermissions:OnRowSelected(index, line)
				giveWeapon:SetDisabled(not (self:GetSelected()[1] != nil and kitList:GetSelected()[1] != nil))
			end

			VToolkit:CreateSearchBox(allPermissions)



			giveWeapon = VToolkit:CreateButton("Add Weapon", function()
				for i,k in pairs(allPermissions:GetSelected()) do
					local has = false
					for i1,k1 in pairs(kitContents:GetLines()) do
						if(k.ClassName == k1.ClassName) then has = true break end
					end
					if(has) then continue end
					kitContents:AddLine(k:GetValue(1)).ClassName = k.ClassName

					MODULE:NetStart("AddKitContents")
					net.WriteString(kitList:GetSelected()[1]:GetValue(1))
					net.WriteString(k.ClassName)
					net.SendToServer()
				end
			end)
			giveWeapon:SetPos(select(1, kitContents:GetPos()) + kitContents:GetWide() + 10, 100)
			giveWeapon:SetWide(panel:GetWide() - 20 - select(1, allPermissions:GetWide()) - select(1, giveWeapon:GetPos()))
			giveWeapon:SetParent(panel)
			giveWeapon:SetDisabled(true)

			takeWeapon = VToolkit:CreateButton("Remove Weapon", function()
				for i,k in pairs(kitContents:GetSelected()) do
					MODULE:NetStart("DelKitContents")
					net.WriteString(kitList:GetSelected()[1]:GetValue(1))
					net.WriteString(k.ClassName)
					net.SendToServer()

					kitContents:RemoveLine(k:GetID())
				end
			end)
			takeWeapon:SetPos(select(1, kitContents:GetPos()) + kitContents:GetWide() + 10, 130)
			takeWeapon:SetWide(panel:GetWide() - 20 - select(1, allPermissions:GetWide()) - select(1, takeWeapon:GetPos()))
			takeWeapon:SetParent(panel)
			takeWeapon:SetDisabled(true)

			addKitPanel:MoveToFront()
			renKitPanel:MoveToFront()
			kitPermissionPanel:MoveToFront()

			paneldata.GiveWeapon = giveWeapon
			paneldata.TakeWeapon = takeWeapon
		end,
		OnOpen = function(panel, paneldata)
			if(paneldata.Weapons == nil) then
				paneldata.Weapons = {}
				for i,k in pairs(list.Get("Weapon")) do
					local name = k.PrintName
					if(name == nil or name == "") then
						name = k.ClassName
					end
					table.insert(paneldata.Weapons, { Name = name, ClassName = k.ClassName })
				end
			end
			if(table.Count(paneldata.AllPermissions:GetLines()) == 0) then
				for i,k in pairs(paneldata.Weapons) do
					local ln = paneldata.AllPermissions:AddLine(k.Name)
					ln.ClassName = k.ClassName

					ln.ModelPath = paneldata.getMdl(k.ClassName)

					ln.OldCursorMoved = ln.OnCursorMoved
					ln.OldCursorEntered = ln.OnCursorEntered
					ln.OldCursorExited = ln.OnCursorExited

					function ln:OnCursorEntered()
						paneldata.PreviewPanel:SetVisible(true)
						paneldata.PreviewPanel.ModelView:SetModel(ln.ModelPath)

						if(self.OldCursorEntered) then self:OldCursorEntered() end
					end

					function ln:OnCursorExited()
						paneldata.PreviewPanel:SetVisible(false)

						if(self.OldCursorExited) then self:OldCursorExited() end
					end

					function ln:OnCursorMoved(x,y)
						if(IsValid(paneldata.PreviewPanel)) then
							local x, y = input.GetCursorPos()
							paneldata.PreviewPanel:SetPos(x - 180, y - 117)
						end

						if(self.OldCursorMoved) then self:OldCursorMoved(x,y) end
					end
				end
			end
			paneldata.KitContents:Clear()
			paneldata.GiveWeapon:SetDisabled(true)
			paneldata.TakeWeapon:SetDisabled(true)
			paneldata.DelKit:SetDisabled(true)
			paneldata.RenKit:SetDisabled(true)
			paneldata.OpenKitPermissions:SetDisabled(true)

			paneldata.KitPermissionPanel:Close()
			paneldata.AddKitPanel:Close()
			paneldata.RenKitPanel:Close()

			Vermilion:PopulateRankTable(paneldata.KitPermissionsAllRanks, false, true)

			MODULE:NetCommand("ListKits")
		end
	})
end
