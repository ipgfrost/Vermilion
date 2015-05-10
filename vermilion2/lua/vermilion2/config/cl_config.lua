--[[
 Copyright 2015 Ned Hyett

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

Vermilion.Data.LocalSteamID = nil

net.Receive("VBroadcastUserData", function()
	local sid = net.ReadString()
	if(sid != "") then
		Vermilion.Data.LocalSteamID = sid
	end
	Vermilion.Data.Users = net.ReadTable()
	for i,k in pairs(Vermilion.Data.Users) do
		Vermilion:AttachUserFunctions(k)
	end
	hook.Run(Vermilion.Event.CLIENT_GOT_USERDATA)
	if(Vermilion.Data.Ranks == nil) then return end
	hook.Run(Vermilion.Event.CLIENT_NewPermissionData)
end)

net.Receive("VBroadcastRankData", function()
	Vermilion.Data.Ranks = net.ReadTable()
	for i,k in pairs(Vermilion.Data.Ranks) do
		Vermilion:AttachRankFunctions(k)
	end
	hook.Run(Vermilion.Event.CLIENT_GOT_RANK_DATA)
	if(Vermilion.Data.Users == nil) then return end
	hook.Run(Vermilion.Event.CLIENT_NewPermissionData)
end)

net.Receive("VBroadcastPermissions", function()
	Vermilion.AllPermissions = net.ReadTable()
end)

function Vermilion:LookupPermissionOwner(permission)
	for i,k in pairs(self.AllPermissions) do
		if(k.Permission == permission) then return k.Owner end
	end
end

Vermilion.RankTables = {}
Vermilion:AddHook(Vermilion.Event.CLIENT_GOT_RANK_DATA, "UpdateRankTables", true, function()
	for i,k in pairs(Vermilion.RankTables) do
		Vermilion:PopulateRankTable(k.Table, k.Detailed, k.Protected)
	end
end)

function Vermilion:PopulateRankTable(ranklist, detailed, protected, customiser)
	if(ranklist == nil) then return end
	detailed = detailed or false
	protected = protected or false
	local has = false
	for i,k in pairs(self.RankTables) do
		if(k.Table == ranklist) then
			has = true
			break
		end
	end
	if(not has) then
		table.insert(self.RankTables, { Table = ranklist, Detailed = detailed, Protected = protected })
	end
	ranklist:Clear()
	if(detailed) then
		for i,k in pairs(self.Data.Ranks) do
			if(not protected and k.Protected) then continue end
			local inherits = Vermilion:GetRankByID(k.InheritsFrom)
			if(inherits != nil) then inherits = inherits.Name end
			if(k.IsDefault) then
				local ln = ranklist:AddLine(k.Name, inherits or Vermilion:TranslateStr("none"), i, Vermilion:TranslateStr("yes"))
				ln.Protected = k.Protected
				ln.UniqueRankID = k.UniqueID
				for i1,k1 in pairs(ln.Columns) do
					k1:SetContentAlignment(5)
				end
				local img = vgui.Create("DImage")
				img:SetImage("icon16/" .. k.Icon .. ".png")
				img:SetSize(16, 16)
				ln:Add(img)
				if(isfunction(customiser)) then customiser(ln, k) end
			else
				local ln = ranklist:AddLine(k.Name, inherits or Vermilion:TranslateStr("none"), i, Vermilion:TranslateStr("no"))
				ln.Protected = k.Protected
				ln.UniqueRankID = k.UniqueID
				for i1,k1 in pairs(ln.Columns) do
					k1:SetContentAlignment(5)
				end
				local img = vgui.Create("DImage")
				img:SetImage("icon16/" .. k.Icon .. ".png")
				img:SetSize(16, 16)
				ln:Add(img)
				if(isfunction(customiser)) then customiser(ln, k) end
			end
		end
	else
		for i,k in pairs(self.Data.Ranks) do
			if(not protected and k.Protected) then continue end
			local ln = ranklist:AddLine(k.Name)
			ln.Protected = k.Protected
			ln.UniqueRankID = k.UniqueID
			if(isfunction(customiser)) then customiser(ln, k) end
		end
	end
end

net.Receive("VUpdatePlayerLists", function()
	local tab = net.ReadTable()
	hook.Run("Vermilion_PlayersList", tab)
end)

net.Receive("VModuleConfig", function()
	Vermilion.Data.Module[net.ReadString()] = net.ReadTable()
end)

Vermilion:AddHook("ChatText", "StopDefaultChat", false, function(index, name, text, typ)
	if(typ == "joinleave") then
		return true
	end
end)

function showAutoconfigure()
	local frame = VToolkit:CreateFrame(
		{
			['size'] = { 500, 200 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - " .. "Automatic Configuration",
			['bgBlur'] = true
		}
	)
	frame:MakePopup()
	frame:DoModal()
	frame:SetAutoDelete(true)
	
	local panel = vgui.Create("DPanel", frame)
	panel:SetPos(10, 35)
	panel:SetSize(480, 155)
	
	local text = VToolkit:CreateLabel("Welcome to Vermilion! Since this is the first time setting up Vermilion on this server, would you\nlike me to use a custom configuration to get the server going quickly or would you like to use\nthe default settings?")
	text:SetPos(10, 15)
	text:SetParent(panel)
	
	local defaultButton = VToolkit:CreateButton("Default Settings", function()
		frame:Close()
	end)
	defaultButton:SetPos(10, 85)
	defaultButton:SetSize(150, 50)
	defaultButton:SetParent(panel)
	
	local preconfigureButton = VToolkit:CreateButton("Preconfigured Settings", function()
		net.Start("VUsePreconfigured")
		net.SendToServer()
		frame:Close()
	end)
	preconfigureButton:SetPos(320, 85)
	preconfigureButton:SetSize(150, 50)
	preconfigureButton:SetParent(panel)
end

local showAutoNag = false
local alreadyPosted = false
net.Receive("Vermilion_AutoconfigureNag", function()
	showAutoNag = true
	if(alreadyPosted) then showAutoconfigure() end
end)

Vermilion:AddHook(Vermilion.Event.MOD_POST, "core:autoconfigure", true, function()
	if(showAutoNag) then
		showAutoconfigure()
	end
	alreadyPosted = true
end)

