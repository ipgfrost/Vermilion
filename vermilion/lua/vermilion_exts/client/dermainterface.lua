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
EXTENSION.Name = "Derma Interface - ClientSide"
EXTENSION.ID = "dermainterface"
EXTENSION.Description = "Gives Vermilion a Derma interface"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}
EXTENSION.Tabs = {}

function EXTENSION:InitClient()
	local MENU = {}
	MENU.Width = 600
	MENU.Height = 600
	MENU.CurrentWidth = 0
	MENU.CurrentHeight = 0
	
	MENU.HasGotTabs = false
	
	-- Create the menu
	MENU.Panel = vgui.Create("DFrame")
	MENU.Panel:SetSize(0, 0)
	MENU.Panel:SetPos(ScrW() / 2, ScrH() / 2)
	MENU.Panel:ShowCloseButton( true )
	MENU.Panel:SetDraggable(false)
	MENU.Panel:SetTitle("Vermilion Settings")
	MENU.Panel:SetBackgroundBlur(true)
	
	MENU.Panel:MakePopup()
	MENU.Panel:SetKeyboardInputEnabled( false )
	MENU.Panel:SetVisible(false)
	
	function MENU.Panel:Close()
		MENU:Hide()
	end
	
	MENU.IsOpen = false
	
	net.Receive("Vermilion_TabResponse", function(len)
		local allowedTabs = net.ReadTable()
		for i,tab in pairs(allowedTabs) do
			local tabData = self.Tabs[tab]
			if(tabData != nil) then
				local tabPanel = tabData[4](MENU.TabHolder)
				Vermilion.Log("Loading panel " .. tab)
				MENU.TabHolder:AddSheet(tabData[1], tabPanel, tabData[2], false, false, tabData[3])
			end
		end
	end)
	
	function MENU:BuildClientOpts()
		local clientOptions = vgui.Create("DPanel", self.TabHolder)
		clientOptions:StretchToParent(5, 20, 20, 5)
		
		Crimson:SetDark(true)
		local alertSoundCheckbox = Crimson.CreateCheckBox("Alert Sounds", "vermilion_alert_sounds", GetConVarNumber("vermilion_alert_sounds"))
		alertSoundCheckbox:SetParent(clientOptions)
		alertSoundCheckbox:SetPos( 10, 10 )
		self.TabHolder:AddSheet("Client Options", clientOptions, "icon16/application.png", false, false, "Client Options")
	end
	
	function MENU:Show()
		if(self.TabHolder) then self.TabHolder:Remove() end
		self.TabHolder = vgui.Create("DPropertySheet", self.Panel)
		self.TabHolder:SetPos(0, 20)
		self.TabHolder:SetSize(600, 580)
		self:BuildClientOpts()
		
		net.Start("Vermilion_TabRequest")
		net.SendToServer()
		timer.Destroy("Vermilion_MenuHide")
		self.Panel:SetVisible(true)
		self.Panel:SetKeyboardInputEnabled(true)
		input.SetCursorPos( ScrW() / 2, ScrH() / 2 )
		timer.Create("Vermilion_MenuShow", 1/60, 0, function()
			if(self.CurrentWidth >= self.Width) then
				self.CurrentWidth = self.Width
			else
				self.CurrentWidth = self.CurrentWidth + 24
			end
			if(self.CurrentHeight >= self.Height) then
				self.CurrentHeight = self.Height
			else
				self.CurrentHeight = self.CurrentHeight + 24
			end
			self.Panel:SetSize(self.CurrentWidth, self.CurrentHeight)
			self.Panel:SetPos((ScrW() / 2) - (self.CurrentWidth / 2), (ScrH() / 2) - (self.CurrentHeight / 2))
			
			if(self.CurrentHeight == self.Height and self.CurrentWidth == self.Width) then
				timer.Destroy("Vermilion_MenuShow")
				self.IsOpen = true
				net.Start("VActivePlayers")
				net.SendToServer()
				net.Start("VRanksList")
				net.SendToServer()
			end
		end)
	end
	
	function MENU:Hide()
		timer.Destroy("Vermilion_MenuShow")
		self.Panel:SetKeyboardInputEnabled(false)
		timer.Create("Vermilion_MenuHide", 1/60, 0, function()
			if(self.CurrentWidth <= 0) then
				self.CurrentWidth = 0
			else
				self.CurrentWidth = self.CurrentWidth - 24
			end
			if(self.CurrentHeight <= 0) then
				self.CurrentHeight = 0
			else
				self.CurrentHeight = self.CurrentHeight - 24
			end
			self.Panel:SetSize(self.CurrentWidth, self.CurrentHeight)
			self.Panel:SetPos((ScrW() / 2) - (self.CurrentWidth / 2), (ScrH() / 2) - (self.CurrentHeight / 2))
			
			if(self.CurrentHeight == 0 and self.CurrentWidth == 0) then
				self.Panel:SetVisible(false)
				self.IsOpen = false
				timer.Destroy("Vermilion_MenuHide")
			end
		end)
	end
	
	
	function Vermilion:AddInterfaceTab( tabName, tabNiceName, tabIcon, tabToolTip, tabPanelFunc )
		if(EXTENSION.Tabs[tabName] != nil) then
			self.Log("Warning: overwriting tab " .. tabName .. "!")
		end
		EXTENSION.Tabs[tabName] = { tabNiceName, tabIcon, tabToolTip, tabPanelFunc }
	end
	
	
	concommand.Add("vermilion_menu", function() if(not MENU.isOpen) then MENU:Show() end end)
end

Vermilion:RegisterExtension(EXTENSION)