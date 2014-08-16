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
EXTENSION.ClientTabs = {}
EXTENSION.ClientOptions = {
	{ "Alert Sounds", "vermilion_alert_sounds" }
}

function EXTENSION:InitClient()
	local MENU = {}
	MENU.Width = 800
	MENU.Height = 600
	MENU.CurrentHeight = 0
	
	MENU.HasGotTabs = false
	
	-- Create the menu
	MENU.Panel = vgui.Create("DFrame")
	MENU.Panel:SetSize(0, 0)
	MENU.Panel:SetPos(ScrW() / 2, ScrH() / 2)
	MENU.Panel:ShowCloseButton( true )
	MENU.Panel:SetDraggable(false)
	MENU.Panel:SetTitle("Vermilion Menu")
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
		local tabsToMake = {}
		for i,tab in pairs(allowedTabs) do
			local tabData = self.Tabs[tab]
			if(tabData != nil) then
				table.insert(tabsToMake, { ID = tab, Order = tabData[5] })
			end
		end
		table.SortByMember(tabsToMake, "Order", true)
		for i,tab in ipairs(tabsToMake) do
			local tabData = self.Tabs[tab.ID]
			if(tabData != nil) then
				local tpanel = vgui.Create("DPanel", MENU.TabHolder)
				tpanel:StretchToParent(5, 20, 20, 5)
				local success, err = pcall(tabData[4], tpanel)
				if(not success) then
					Vermilion.Log("Failure while generating panel " .. tab.ID .. "!")
					Vermilion.Log(err)
					tpanel:Remove()
				else
					Vermilion.Log("Loading panel " .. tab.ID)
					MENU.TabHolder:AddSheet(tabData[1], tpanel, "icon16/" .. tabData[2], false, false, tabData[3])
				end
			end
		end
	end)
	
	function MENU:BuildWelcomeScreen()
		local welcome = vgui.Create("DPanel", self.TabHolder)
		welcome:StretchToParent(5, 20, 20, 5)
		
		Crimson:SetDark(true)
		
		local title = Crimson.CreateLabel("Welcome To Vermilion")
		title:SetFont("DermaLarge")
		title:SizeToContents()
		title:SetPos((welcome:GetWide() / 2) - (title:GetWide() / 2), 50)
		title:SetParent(welcome)
		
		
		self.TabHolder:AddSheet("Welcome", welcome, "icon16/house.png", false, false, "Welcome")
	end
	
	function MENU:BuildClientOpts()
		local clientOptions = vgui.Create("DPanel", self.TabHolder)
		clientOptions:StretchToParent(5, 20, 20, 5)
		
		Crimson:SetDark(true)
		local pos = 10
		for i,box in pairs(EXTENSION.ClientOptions) do
			local cb = Crimson.CreateCheckBox(box[1], box[2], GetConVarNumber(box[2]))
			cb:SetPos(10, pos)
			cb:SetParent(clientOptions)
			pos = pos + 20
		end
		self.TabHolder:AddSheet("Client Options", clientOptions, "icon16/application.png", false, false, "Client Options")
	end
	
	function MENU:Show()
		if(self.TabHolder and IsValid(self.TabHolder)) then self.TabHolder:Remove() end
		self.TabHolder = vgui.Create("DPropertySheet", self.Panel)
		self.TabHolder:SetPos(0, 20)
		self.TabHolder:SetSize(MENU.Width, 580)
		--self:BuildWelcomeScreen()
		self:BuildClientOpts()
		for i,tab in pairs(EXTENSION.ClientTabs) do
			local tpanel = vgui.Create("DPanel", MENU.TabHolder)
			tpanel:StretchToParent(5, 20, 20, 5)
			local success,err = pcall(tab[4], tpanel)
			if(not success) then
				Vermilion.Log("Failure while generating client panel " .. tab.ID .. "!")
				Vermilion.Log(err)
				tpanel:Remove()
			else
				Vermilion.Log("Loading client panel " .. i)
				MENU.TabHolder:AddSheet(tab[1], tpanel, "icon16/" .. tab[2], false, false, tab[3])
			end
		end
		
		net.Start("Vermilion_TabRequest")
		net.SendToServer()
		timer.Destroy("Vermilion_MenuHide")
		self.Panel:SetVisible(true)
		self.Panel:SetKeyboardInputEnabled(true)
		input.SetCursorPos( ScrW() / 2, ScrH() / 2 )
		timer.Create("Vermilion_MenuShow", 1/60, 0, function()
			if(self.CurrentHeight >= self.Height) then
				self.CurrentHeight = self.Height
			else
				self.CurrentHeight = self.CurrentHeight + 24
			end
			self.Panel:SetSize(self.Width, self.CurrentHeight)
			self.Panel:SetPos((ScrW() / 2) - (self.Width / 2), (ScrH() / 2) - (self.CurrentHeight / 2))
			
			if(self.CurrentHeight == self.Height) then
				timer.Destroy("Vermilion_MenuShow")
				self.IsOpen = true
				
				net.Start("VActivePlayers")
				net.SendToServer()
				
				net.Start("VRanksList")
				net.SendToServer()
				
				net.Start("VWeaponsList")
				net.SendToServer()
				
				net.Start("VEntsList")
				net.SendToServer()
			end
		end)
	end
	
	function MENU:Hide()
		timer.Destroy("Vermilion_MenuShow")
		self.Panel:SetKeyboardInputEnabled(false)
		timer.Create("Vermilion_MenuHide", 1/60, 0, function()
			if(self.CurrentHeight <= 0) then
				self.CurrentHeight = 0
			else
				self.CurrentHeight = self.CurrentHeight - 24
			end
			self.Panel:SetSize(self.Width, self.CurrentHeight)
			self.Panel:SetPos((ScrW() / 2) - (self.Width / 2), (ScrH() / 2) - (self.CurrentHeight / 2))
			
			if(self.CurrentHeight == 0) then
				self.Panel:SetVisible(false)
				self.TabHolder:Remove()
				self.IsOpen = false
				timer.Destroy("Vermilion_MenuHide")
			end
		end)
	end
	
	
	function Vermilion:AddInterfaceTab( tabName, tabNiceName, tabIcon, tabToolTip, tabPanelFunc, order )
		order = order or 9999
		if(EXTENSION.Tabs[tabName] != nil) then
			self.Log("Warning: overwriting tab " .. tabName .. "!")
		end
		EXTENSION.Tabs[tabName] = { tabNiceName, tabIcon, tabToolTip, tabPanelFunc, order }
	end
	
	function Vermilion:AddClientTab( tabName, tabNiceName, tabIcon, tabToolTip, tabPanelFunc )
		if(EXTENSION.ClientTabs[tabName] != nil) then
			self.Log("Warning: overwriting client tab " .. tabName .. "!")
		end
		EXTENSION.ClientTabs[tabName] = { tabNiceName, tabIcon, tabToolTip, tabPanelFunc }
	end
	
	function Vermilion:AddClientOption( optionText, optionConvar )
		table.insert(EXTENSION.ClientOptions, {optionText, optionConvar})
	end
	
	
	concommand.Add("vermilion_menu", function() if(not MENU.isOpen) then MENU:Show() end end)
end

Vermilion:RegisterExtension(EXTENSION)