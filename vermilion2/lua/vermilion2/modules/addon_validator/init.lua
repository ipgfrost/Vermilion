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
MODULE.Name = "Addon Validator"
MODULE.ID = "addon_validator"
MODULE.Description = "Checks if the client has all the addons that the server does."
MODULE.Author = "Ned"
MODULE.Permissions = {

}
MODULE.NetworkStrings = {
	"AddonListRequest",
	"ForceAddonRequest"
}

MODULE.SteamStoreAppURL = "http://store.steampowered.com/app/"
MODULE.WorkshopCollectionURL = "http://steamcommunity.com/sharedfiles/filedetails/?id="

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "checkaddons",
		CanRunOnDS = false,
		Function = function(sender, text, log, glog)
			if(not MODULE:GetData("enabled", true, true)) then return end
			MODULE:NetStart("ForceAddonRequest")
			net.Send(sender)
		end
	})

	Vermilion:AddChatCommand({
		Name = "reset_addon_validator",
		Permissions = {
			"*"
		},
		OnlyConsole = true,
		Function = function(sender, text, log, glog)
			MODULE:SetData("enabled", true)
			MODULE:SetData("check_missing_mounts", false)
			MODULE:SetData("kick_missing_mounts", false)
			MODULE:SetData("kick_missing_addon", false)
			MODULE:SetData("provide_collection_id", false)
			MODULE:SetData("collection_id", 0)
		end
	})
end

function MODULE:InitShared()
	self:AddHook(Vermilion.Event.MOD_LOADED, "AddOption", function()
		if(Vermilion:GetModule("server_settings") != nil) then
			local mod = Vermilion:GetModule("server_settings")
			mod:AddCategory("cat:addon_validator", "addon_validator", 35)
			mod:AddOption({
				Module = "addon_validator",
				Name = "enabled",
				GuiText = MODULE:TranslateStr("settingstext"),
				Type = "Checkbox",
				Category = "addon_validator",
				Default = true
			})
			mod:AddOption({
				Module = "addon_validator",
				Name = "check_missing_mounts",
				GuiText = MODULE:TranslateStr("opt:check_missing_mounts"),
				Type = "Checkbox",
				Category = "addon_validator",
				Default = false
			})
			mod:AddOption({
				Module = "addon_validator",
				Name = "kick_missing_mounts",
				GuiText = MODULE:TranslateStr("opt:kick_missing_mounts"),
				Type = "Checkbox",
				Category = "addon_validator",
				Default = false
			})
			mod:AddOption({
				Module = "addon_validator",
				Name = "kick_missing_addon",
				GuiText = MODULE:TranslateStr("opt:kick_missing_addon"),
				Type = "Checkbox",
				Category = "addon_validator",
				Default = false
			})
			mod:AddOption({
				Module = "addon_validator",
				Name = "provide_collection_id",
				GuiText = MODULE:TranslateStr("opt:provide_collection_id"),
				Type = "Checkbox",
				Category = "addon_validator",
				Default = false
			})
			mod:AddOption({
				Module = "addon_validator",
				Name = "collection_id",
				GuiText = MODULE:TranslateStr("opt:collection_id"),
				Type = "NumberWang",
				Bounds = {
					Min = 0,
					Max = nil
				},
				Category = "addon_validator",
				Default = 0
			})
		end
	end)
end

function MODULE:InitServer()


	self:NetHook("AddonListRequest", function(vplayer)
		if(not MODULE:GetData("enabled", true, true)) then return end
		local tab = {}
		local serverAddons = engine.GetAddons()
		local clientAddons = net.ReadTable()
		local clientMountedContent = net.ReadTable()
		for i,k in pairs(engine.GetAddons()) do
			local has = false
			for i1,k1 in pairs(clientAddons) do
				if(k1 == k.wsid) then
					has = true
					break
				end
			end
			if(k.mounted and not has) then table.insert(tab, { Title = k.title, ID = k.wsid, Type = "Addon" }) end
		end
		if(MODULE:GetData("check_missing_mounts", false, true)) then
			for i,k in pairs(engine.GetGames()) do
				if(not k.mounted or not k.installed) then continue end
				local has = false
				for i1,k1 in pairs(clientMountedContent) do
					if(k1 == k.depot) then
						has = true
						break
					end
				end
				if(not has) then table.insert(tab, { Title = k.title, ID = k.depot, Type = "MountedContent" }) end
			end
		end

		local atab = {}
		local mtab = {}

		if(MODULE:GetData("kick_missing_addon", false, true)) then
			for i,k in pairs(tab) do
				if(k.Type == "Addon") then
					table.insert(atab, k.Title)
				end
			end
		end

		if(MODULE:GetData("kick_missing_mounts", false, true)) then
			for i,k in pairs(tab) do
				if(k.Type == "Addon") then
					table.insert(mtab, k.Title)
				end
			end
		end

		if(table.Count(atab) + table.Count(mtab) > 0) then
			local text = ""
			if(table.Count(atab) > 0) then
				text = text .. MODULE:TranslateStr("disconnect:missing_addons", nil, vplayer) .. "\n" .. table.concat(atab, "\n") .. "\n"
			end
			if(table.Count(mtab) > 0) then
				text = text .. MODULE:TranslateStr("disconnect:missing_mounts", nil, vplayer) .. "\n" .. table.concat(mtab, "\n") .. "\n"
			end
			if(provideCollectionID) then
				text = text .. MODULE:TranslateStr("disconnect:collection", { collectionID }, vplayer)
			end
			vplayer:Kick("\n" .. string.Trim(text))
			return
		end

		MODULE:NetStart("AddonListRequest")
		net.WriteBoolean(MODULE:GetData("check_missing_mounts", false))
		net.WriteBoolean(MODULE:GetData("provide_collection_id", false))
		if(MODULE:GetData("provide_collection_id")) then
			net.WriteInt(MODULE:GetData("collection_id", 0), 32)
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
end

function MODULE:InitClient()

	CreateClientConVar("vermilion_addonnag_do_not_ask", 0, true, false)

	self:NetHook("AddonListRequest", function()
		local checkMissingMounts = net.ReadBoolean()
		local provideCollectionID = net.ReadBoolean()
		local collectionID = nil
		if(provideCollectionID) then
			collectionID = net.ReadInt(32)
		end
		local missingAddons = net.ReadTable()

		Vermilion.Log("Missing " .. tostring(table.Count(missingAddons)) .. " addons!")

		if(table.Count(missingAddons) > 0) then
			local frame = VToolkit:CreateFrame({
				["size"] = { 600, 600 },
				["closeBtn"] = true,
				["draggable"] = false,
				["title"] = MODULE:TranslateStr("title"),
				["bgBlur"] = true
			})
			frame:MakePopup()
			frame:DoModal()
			frame:SetAutoDelete(true)
			frame:SetKeyboardInputEnabled(true)

			local panel = vgui.Create("DPanel", frame)
			panel:SetPos(10, 35)
			panel:SetSize(580, 555)

			local missingAddonsList = VToolkit:CreateList({
				cols = {
					"Addon"
				},
				multiselect = false,
				sortable = true,
				centre = true
			})
			missingAddonsList:SetPos(10, 120)
			missingAddonsList:SetSize(250, 420)
			missingAddonsList:SetParent(panel)

			for i,k in pairs(missingAddons) do
				local ln = missingAddonsList:AddLine(k.Title)
				ln.ID = k.ID
				ln.Type = k.Type
			end

			local alertText = vgui.Create("DTextEntry")
			alertText:SetDrawBackground(false)
			alertText:SetMultiline(true)
			alertText:SetPos(10, 10)
			alertText:SetWide(panel:GetWide() - 20)
			alertText:SetTall(missingAddonsList:GetY() - 10)
			alertText:SetParent(panel)
			alertText:SetValue(MODULE:TranslateStr("windowtext"))
			alertText:SetEditable(false)


			local openInWSButton = VToolkit:CreateButton(MODULE:TranslateStr("open_workshop_page"), function(self)
				steamworks.ViewFile(missingAddonsList:GetSelected()[1].ID)
			end)
			openInWSButton:SetPos(330, 180)
			openInWSButton:SetSize(180, 35)
			openInWSButton:SetParent(panel)
			openInWSButton:SetDisabled(true)


			local openInSteamButton
			if(checkMissingMounts) then
				openInSteamButton = VToolkit:CreateButton(MODULE:TranslateStr("open_steam_store"), function(self)
					gui.OpenURL(MODULE.SteamStoreAppURL .. missingAddonsList:GetSelected()[1].ID)
				end)
				openInSteamButton:SetPos(330, 230)
				openInSteamButton:SetSize(180, 35)
				openInSteamButton:SetParent(panel)
				openInSteamButton:SetDisabled(true)
			end

			local openCollectionButton
			if(provideCollectionID) then
				openCollectionButton = VToolkit:CreateButton(MODULE:TranslateStr("open_collection"), function(self)
					gui.OpenURL(MODULE.WorkshopCollectionURL .. tostring(collectionID))
				end)
				openCollectionButton:SetPos(330, 280)
				openCollectionButton:SetSize(180, 35)
				openCollectionButton:SetParent(panel)
			end

			function missingAddonsList:OnRowSelected(index, line)
				openInWSButton:SetDisabled(true)
				if(checkMissingMounts) then openInSteamButton:SetDisabled(true) end
				if(line.Type == "Addon") then
					openInWSButton:SetDisabled(false)
				elseif (line.Type == "MountedContent") then
					openInSteamButton:SetDisabled(false)
				end
			end

			local donotaskButton = VToolkit:CreateButton(MODULE:TranslateStr("dna"), function(self)
				VToolkit:CreateConfirmDialog(MODULE:TranslateStr("dna:confirm"), function()
					RunConsoleCommand("vermilion_addonnag_do_not_ask", "1")
					frame:Close()
				end, { Confirm = MODULE:TranslateStr("yes"), Deny = MODULE:TranslateStr("no"), Default = false })
			end)
			donotaskButton:SetPos(330, panel:GetTall() - 50)
			donotaskButton:SetSize(180, 35)
			donotaskButton:SetParent(panel)
		end
	end)

	self:AddHook(Vermilion.Event.MOD_POST, function()
		if(GetConVarNumber("vermilion_addonnag_do_not_ask") == 0) then
			MODULE:NetStart("AddonListRequest")
			local tab = {}
			for i,k in pairs(engine.GetAddons()) do
				if(k.mounted) then table.insert(tab, k.wsid) end
			end
			net.WriteTable(tab)
			local tabm = {}
			for i,k in pairs(engine.GetGames()) do
				if(k.mounted and k.installed) then table.insert(tabm, k.depot) end
			end
			net.WriteTable(tabm)
			net.SendToServer()
		end
	end)

	self:NetHook("ForceAddonRequest", function()
		MODULE:NetStart("AddonListRequest")
		local tab = {}
		for i,k in pairs(engine.GetAddons()) do
			if(k.mounted) then table.insert(tab, k.wsid) end
		end
		net.WriteTable(tab)
		local tabm = {}
		for i,k in pairs(engine.GetGames()) do
			if(k.mounted and k.installed) then table.insert(tabm, k.depot) end
		end
		net.WriteTable(tabm)
		net.SendToServer()
	end)

end
