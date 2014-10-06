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
EXTENSION.Name = "Security Advisor"
EXTENSION.ID = "security_advisor"
EXTENSION.Description = "Detects problems with the server configuration."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"see_security_advisor_prompt"
}
EXTENSION.PermissionDefinitions = {
	["see_security_advisor_prompt"] = "This player is able to see the security advisor prompt when they spawn."
}
EXTENSION.NetworkStrings = {
	"VFaultListRequest",
	"VFaultListExecute",
	"VFaultListIgnore"
}

function EXTENSION:InitServer()
	self:NetHook("VFaultListRequest", function(vplayer)
		if(not EXTENSION:GetData("enabled", true, true)) then return end
		if(Vermilion:HasPermission(vplayer, "see_security_advisor_prompt")) then
			local faults = {}
			if(GetConVarNumber("sv_cheats") != 0 and not EXTENSION:GetData("sv_cheats_ignore", false, true)) then
				table.insert(faults, {
					Title = "sv_cheats are enabled",
					Description = "By enabling sv_cheats, you are allowing hackers to run potentially dangerous commands.\nThis should be disabled if possible. This cannot be fixed automatically due to Lua restrictions.",
					FixFunction = nil,
					Type = "sv_cheats"
				})
			end
			if(GetConVarNumber("sv_allowcslua") != 0 and not EXTENSION:GetData("sv_allowcslua_ignore", false, true)) then
				table.insert(faults, {
					Title = "Clientside Lua is enabled",
					Description = "Clientside Lua allows clients to run scripts that the server does not have. This means that they can use Lua hacks which cannot be VAC banned.\nIt also allows hackers to interact with the clientside part of Vermilion and potentially vandalise the system and bypass things\nsuch as the bind blocker and sound management, and even send corrupt data to the server and break the serverside component of Vermilion.\n\nThis MUST be disabled to maintain server security otherwise Vermilion will attempt to use higher-level self-defence measures.",
					FixFunction = "sv_allowcslua",
					Type = "sv_allowcslua"
				})
			end
			if(GetConVarNumber("sv_allowupload") != 0 and not EXTENSION:GetData("sv_allowupload_ignore", false, true)) then
				table.insert(faults, {
					Title = "Client uploads are enabled",
					Description = "If this is enabled, connected clients can upload files to the server which can contain potentially malicious content.\nThis is not a high-level threat, however it can open up vulnerabilities for hackers to exploit. The drawback to disabling this is that sprays will no longer work.",
					FixFunction = "sv_allowupload",
					Type = "sv_allowupload"
				})
			end
			net.Start("VFaultListRequest")
			net.WriteTable(faults)
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VFaultListExecute", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "see_security_advisor_prompt")) then
			local command = net.ReadString()
			if(command == "sv_allowcslua") then
				RunConsoleCommand("sv_allowcslua", 0)
			end
			if(command == "sv_allowupload") then
				RunConsoleCommand("sv_allowupload", 0)
			end
		end
	end)
	
	self:NetHook("VFaultListIgnore", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "see_security_advisor_prompt")) then
			local ignored = net.ReadString()
			EXTENSION:SetData(ignored .. "_ignore", true)
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddOptions", function()
		if(Vermilion:GetExtension("server_manager") != nil) then
			Vermilion:GetExtension("server_manager"):AddOption("security_advisor", "enabled", "Enable Security Advisor", "Checkbox", "Misc", 50, true)
		end
	end)
end

function EXTENSION:InitClient()
	CreateClientConVar("vermilion_securitynag_do_not_ask", 0, true, false)
	
	function EXTENSION:SendFixCommand(command)
		net.Start("VFaultListExecute")
		net.WriteString(command)
		net.SendToServer()
	end
	
	self:NetHook("VFaultListRequest", function()
		local faults = net.ReadTable()
		
		if(table.Count(faults) > 0) then
			local frame = Crimson.CreateFrame({
				["size"] = { 600, 600 },
				["pos"] = { (ScrW() / 2) - 300, (ScrH() / 2) - 300},
				["closeBtn"] = true,
				["draggable"] = false,
				["title"] = "Vermilion Security Alert",
				["bgBlur"] = true
			})
			frame:MakePopup()
			frame:SetAutoDelete(true)
			frame:SetKeyboardInputEnabled(true)
			
			local panel = vgui.Create("DPanel", frame)
			panel:SetPos(10, 35)
			panel:SetSize(580, 555)
			
			local faultsList = Crimson.CreateList({ "Fault" }, true, true)
			faultsList:SetPos(10, 120)
			faultsList:SetSize(250, 420)
			faultsList:SetParent(panel)
			
			for i,k in pairs(faults) do
				local ln = faultsList:AddLine(k.Title)
				ln.OnRightClick = function()
					local secmenu = DermaMenu()
					secmenu:SetParent(ln)
					secmenu:AddOption("Open Description", function()
						Derma_Message(k.Description, k.Title .. " - Description", "Close")
					end):SetIcon("icon16/book_open.png")
					if(k.FixFunction != nil) then 
						secmenu:AddOption("Fix", function()
							EXTENSION:SendFixCommand(k.FixFunction)
							faultsList:RemoveLine(ln:GetID())
						end):SetIcon("icon16/wrench.png")
					end
					secmenu:AddOption("Ignore", function()
						net.Start("VFaultListIgnore")
						net.WriteString(k.Type)
						net.SendToServer()
						faultsList:RemoveLine(ln:GetID())
					end):SetIcon("icon16/cross.png")
					secmenu:Open()
				end
			end
			
			local alertText = Crimson.CreateLabel("Vermilion has detected that the server has an insecure configuration.\n\nRight click on the items in the list below for a description of the fault and an option to automatically fix the problem. Leaving these problems unresolved can cause Vermilion to become ineffective and allow hackers to exploit your server.\n\nIf you know of any more vulnerabilities that can be added to the scanner, please let us know on the Vermilion Workshop Page!")
			alertText:SetPos(10, 10)
			alertText:SetWide(panel:GetWide() - 20)
			alertText:SetParent(panel)
			alertText:SetAutoStretchVertical(true)
			alertText:SetWrap(true)
			
			
			local donotaskButton = Crimson.CreateButton("Close and do not ask again", function(self)
				Crimson:CreateConfirmDialog("Are you sure?\nTo reset it, type \"vermilion_securitynag_do_not_ask 0\" into the console!", function()
					RunConsoleCommand("vermilion_securitynag_do_not_ask", "1")
					frame:Close()
				end)
			end)
			donotaskButton:SetPos(330, panel:GetTall() - 50)
			donotaskButton:SetSize(180, 35)
			donotaskButton:SetParent(panel)
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, function()
		if(GetConVarNumber("vermilion_securitynag_do_not_ask") == 0) then
			net.Start("VFaultListRequest")
			net.SendToServer()
		end
	end)
end

Vermilion:RegisterExtension(EXTENSION)