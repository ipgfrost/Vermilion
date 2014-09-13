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
EXTENSION.Name = "Extension Controls"
EXTENSION.ID = "extensioncontrol"
EXTENSION.Description = "Allows for extensions to be controlled"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"enable_extension",
	"disable_extension",
	"reload_extension",
	"reload_all_extensions"
}
EXTENSION.PermissionDefinitions = {
	["enable_extension"] = "This player can enable a disabled Vermilion Extension to restore certain functionality to Vermilion.",
	["disable_extension"] = "This player can disable an enabled Vermilion Extension to disable certain functionality in Vermilion.",
	["reload_extension"] = "This player can reload an extension using the reloadext chat command.",
	["reload_all_extensions"] = "This player can use a wildcard in the reloadext chat command to reload all loaded extensions."
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"enable_extension",
			"disable_extension",
			"reload_extension",
			"reload_all_extensions"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VExtensionList"
}

function EXTENSION:InitServer()
	self:NetHook("VExtensionList", function(vplayer)
		net.Start("VExtensionList")
		local tab = {}
		for i,k in pairs(Vermilion.Extensions) do
			table.insert(tab, {k.Name, k.ID})
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	Vermilion:AddChatCommand("listexts", function(sender, text)
		Vermilion:SendNotify(sender, "Installed Extensions: " , 10, VERMILION_NOTIFY_HINT)
		for i,k in pairs(Vermilion.Extensions) do
			Vermilion:SendNotify(sender, i, 10, VERMILION_NOTIFY_HINT)
		end
	end)
	
	Vermilion:AddChatCommand("reloadext", function(sender, text)
		if(Crimson.TableLen(text) == 0) then
			Vermilion:SendNotify(sender, "Invalid syntax!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(text[1] == "*") then
			if(Vermilion:HasPermissionError(sender, "reload_all_extensions")) then
				for i,extension in pairs(Vermilion.Extensions) do
					Vermilion.Log("De-initialising extension: " .. i)
					--Vermilion:sendNotify(sender, "De-initialising extension: " .. i)
					extension:Destroy()
				end
				for i,extension in pairs(Vermilion.Extensions) do
					Vermilion.Log("Initialising extension: " .. i)
					Vermilion:SendNotify(sender, "Initialising extension: " .. i)
					if(SERVER) then
						extension:InitServer()
					elseif(CLIENT) then
						extension:InitClient()
					end
					extension:InitShared()
				end
			end
		else
			local edited = false
			for i,k in pairs(Vermilion.Extensions) do
				if(string.find(k.ID, text[1])) then
					Vermilion.Log("De-initialising extension: " .. k.ID)
					k:Destroy()
					Vermilion.Log("Initialising extension: " .. k.ID)
					Vermilion:SendNotify(sender, "Initialising extension: " .. k.ID)
					if(SERVER) then
						k:InitServer()
					elseif(CLIENT) then
						k:InitClient()
					end
					k:InitShared()
					edited = true
				end
			end
			if(not edited) then Vermilion:SendNotify(sender, "No extension found that matches the query!", VERMILION_NOTIFY_ERROR) end
		end
	end, "<extension id>/*")
	
	Vermilion:AddChatPredictor("reloadext", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(Vermilion.Extensions) do
				if(string.StartWith(string.lower(k.ID), string.lower(current))) then
					table.insert(tab, k.ID)
				end
			end
			return tab
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("extension_control", nil)
	end)
end

function EXTENSION:InitClient()
	self:NetHook("VExtensionList", function()
		EXTENSION.ExtList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.ExtList:AddLine(k[1], k[2]).OnSelect = function(self)
				-- do something with k[2] here!
				--net.Start("Ext_InfoRequest")
				--net.WriteString(k[2]) -- how about this?
				--net.SendToServer()
			end
		end
		for i,k in pairs(Vermilion.Extensions) do
			local alreadyExists = false
			for i1,k1 in pairs(EXTENSION.ExtList:GetLines()) do
				if(k1:GetValue(2) == k.ID) then
					alreadyExists = true
					break
				end
			end
			if(not alreadyExists) then
				EXTENSION.ExtList:AddLine(k.Name, k.ID).OnSelect = function(self)
					-- do something with k[2] here!
					
				end
			end
		end
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("extension_control", "Extensions", "brick.png", "Extension Control", function(panel)
			
			local extList = Crimson.CreateList({ "Name", "ID" }, false)
			extList:SetParent(panel)
			extList:SetPos(10, 30)
			extList:SetSize(300, 500)
			EXTENSION.ExtList = extList
			
			net.Start("VExtensionList")
			net.SendToServer()
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)