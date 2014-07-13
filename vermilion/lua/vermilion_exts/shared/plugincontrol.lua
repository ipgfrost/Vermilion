--[[
 The MIT License

 Copyright 2014 Ned Hyett.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
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

function EXTENSION:InitServer()
	util.AddNetworkString("ExtList_Request")
	util.AddNetworkString("ExtList_Response")
	
	net.Receive("ExtList_Request", function(len, vplayer)
		net.Start("ExtList_Response")
		local tab = {}
		for i,k in pairs(Vermilion.Extensions) do
			table.insert(tab, {k.Name, k.ID})
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)

	Vermilion:AddChatCommand("reloadext", function(sender, text)
		if(Crimson.TableLen(text) == 0) then
			Vermilion:SendNotify(sender, "Invalid syntax!", 5, NOTIFY_ERROR)
			return
		end
		if(text[1] == "*") then
			if(Vermilion:HasPermissionVerboseChat(sender, "reload_all_extensions")) then
				for i,extension in pairs(Vermilion.Extensions) do
					Vermilion.Log("De-initialising extension: " .. i)
					--Vermilion:sendNotify(sender, "De-initialising extension: " .. i, 5, NOTIFY_HINT)
					extension:Destroy()
				end
				for i,extension in pairs(Vermilion.Extensions) do
					Vermilion.Log("Initialising extension: " .. i)
					Vermilion:SendNotify(sender, "Initialising extension: " .. i, 5, NOTIFY_HINT)
					if(SERVER) then
						extension:InitServer()
					elseif(CLIENT) then
						extension:InitClient()
					end
				end
			end
		end
	end)
end

function EXTENSION:InitClient()
	net.Receive("ExtList_Response", function(len)
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
		Vermilion:AddInterfaceTab("extension_control", "Extensions", "icon16/brick.png", "Extension Control", function(TabHolder)
			local panel = vgui.Create("DPanel", TabHolder)
			panel:StretchToParent(5, 20, 20, 5)
			
			local extList = vgui.Create("DListView")
			extList:SetMultiSelect(false)
			extList:AddColumn("Name")
			extList:AddColumn("ID")
			extList:SetParent(panel)
			extList:SetPos(10, 30)
			extList:SetSize(225, 500)
			
			EXTENSION.ExtList = extList
			
			net.Start("ExtList_Request")
			net.SendToServer()
			
			return panel
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)