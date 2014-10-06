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
	{ "Alert Sounds", "vermilion_alert_sounds" },
	{ "Use new menu style (experimental) (requires reconnect)", "crimson_manualpaint" }
}

function EXTENSION:InitClient()
	local MENU = {}
	MENU.Width = 800
	MENU.Height = 600
	MENU.CurrentHeight = 0
	MENU.TitleExt = "Client Options"
	MENU.HasGotTabs = false
	
	-- WHEATLEY: Setup a new font for Panel's title
	surface.CreateFont( 'VermilonTitle', {
		font		= 'Helvetica',
		size		= 22,
		weight		= 800,
		additive = false,
		antialias = true,
	} )
	
	-- WHEATLEY: Basic functions for rendering
	local function RenderTab( self )
		local w, h = self:GetWide() - 4, self:GetTall()
		surface.SetDrawColor( 100, 0, 0, 200 )
		surface.DrawRect( 0, 0, w, h )
		surface.SetDrawColor( 255, 0, 0, 200 )
		surface.DrawOutlinedRect( 0, 0, w, h )
	end
	
	local function RenderBody( self )
		local w, h = self:GetWide(), self:GetTall()
		-- body
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawRect( 0, 0, w, h )
		-- frame
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawOutlinedRect( 0, 0, w, h )
	end
	
	local function RenderButton( self )
		local w, h = self:GetWide(), self:GetTall()
		-- body
		surface.SetDrawColor( 255, 0, 0, 45 )
		surface.DrawRect( 0, 0, w, h )
		-- frame
		surface.SetDrawColor( 255, 0, 0, 255 )
		surface.DrawOutlinedRect( 0, 0, w, h )
	end
	
	-- Create the menu
	MENU.Panel = vgui.Create("DFrame")
	MENU.Panel:SetSize(0, 0)
	MENU.Panel:SetPos(ScrW() / 2, ScrH() / 2)
	MENU.Panel:ShowCloseButton( GetConVarNumber("crimson_manualpaint") != 1 )
	MENU.Panel:SetDraggable(false)
	if(GetConVarNumber("crimson_manualpaint") == 1) then
		MENU.Panel:SetTitle("")
	else
		MENU.Panel:SetTitle("Vermilion Menu")
	end
	MENU.Panel:SetBackgroundBlur(true)
	
	MENU.Panel:MakePopup()
	MENU.Panel:SetKeyboardInputEnabled( false )
	MENU.Panel:SetVisible(false)
	
	if(GetConVarNumber("crimson_manualpaint") == 1) then
		-- WHEATLEY: Rendering main frame
		MENU.Panel.Paint = function( self, w, h )
			-- title
			surface.SetFont( 'VermilonTitle' )
			surface.SetTextPos( 2, 2 )
			surface.SetTextColor( 255, 0, 0, 255 )
			surface.DrawText( 'Vermilion Menu - ' .. MENU.TitleExt )
		end
	end
	
	if(GetConVarNumber("crimson_manualpaint") == 1) then
		-- WHEATLEY: Close button
		MENU.CloseBtn = MENU.Panel:Add( 'DButton' )
		MENU.CloseBtn:SetSize( 50, 20 )
		MENU.CloseBtn:SetColor( Color( 255, 255, 255, 255 ) )
		MENU.CloseBtn:SetText( 'Close' )
		MENU.CloseBtn.DoClick = function()
			MENU:Hide()
		end
		MENU.CloseBtn.Paint = RenderButton
	end
	
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
				if(GetConVarNumber("crimson_manualpaint") == 1) then
					tpanel.Paint = RenderBody
				end
				local success, err = pcall(tabData[4], tpanel)
				if(not success) then
					Vermilion.Log("Failure while generating panel " .. tab.ID .. "!")
					Vermilion.Log(err)
					tpanel:Remove()
				else
					Vermilion.Log("Loading panel " .. tab.ID)
					if(GetConVarNumber("crimson_manualpaint") == 1) then
						-- WHEATLEY: Tab rendering system
						local __p = MENU.TabHolder:AddSheet(tabData[1], tpanel, "icon16/" .. tabData[2], false, false, tabData[3])
						__p.Tab.Paint = RenderTab
					else
						MENU.TabHolder:AddSheet(tabData[1], tpanel, "icon16/" .. tabData[2], false, false, tabData[3])
					end
				end
			end
		end
		MENU:BuildCredits()
	end)
	
	function MENU:BuildWelcomeScreen()
		local welcome = vgui.Create("DPanel", self.TabHolder)
		welcome:StretchToParent(5, 20, 20, 5)
		
		if(GetConVarNumber("crimson_manualpaint") == 1) then
			welcome.Paint = RenderBody
		end
		
		Crimson:SetDark(true)
		
		local title = Crimson.CreateLabel("Welcome To Vermilion")
		title:SetFont("DermaLarge")
		title:SizeToContents()
		title:SetPos((welcome:GetWide() / 2) - (title:GetWide() / 2), 50)
		title:SetParent(welcome)
		
		local __p = self.TabHolder:AddSheet("Welcome", welcome, "icon16/house.png", false, false, "Welcome")
		if(GetConVarNumber("crimson_manualpaint") == 1) then
			__p.Tab.Paint = RenderTab
		end		
	end
	
	function MENU:BuildCredits()
		local credits = {
			{
				Name = "Ned",
				SteamID = "STEAM_0:0:44370296",
				Role = "Project Lead - Coding"
			},
			{
				Name = "Foxworrior",
				SteamID = "STEAM_0:1:43536003",
				Role = "Code Contributor"
			},
			{
				Name = "Wheatley",
				SteamID = "STEAM_0:0:44277237",
				Role = "GUI Designer"
			},
			{
				Name = "TehAngel",
				SteamID = "STEAM_0:1:79012222",
				Role = "Ideas, Persuasion and General Help"
			}
		}
		
		local panel = vgui.Create("DPanel", self.TabHolder)
		panel:StretchToParent(5, 20, 20, 5)
		if(GetConVarNumber("crimson_manualpaint") == 1) then
			panel.Paint = RenderBody
		end
		Crimson:SetDark(true)
		
		local title = Crimson.CreateLabel("Vermilion Credits")
		title:SetFont("DermaLarge")
		title:SizeToContents()
		title:SetPos((panel:GetWide() / 2) - (title:GetWide() / 2), 20)
		title:SetParent(panel)
		
		local scroll = vgui.Create("DScrollPanel")
		scroll:SetPos(0, 50)
		scroll:SetSize(panel:GetWide(), panel:GetTall() - 62)
		scroll:SetParent(panel)
		
		local size = 64
		
		for i,k in pairs(credits) do
			local av = Crimson.CreateAvatarImage(k.SteamID, size)
			av:SetPos(10, (i - 1) * (size + 15))
			av:SetParent(scroll)
			
			function av:OnMousePressed(mc)
				print(mc)
				if(mc == MOUSE_LEFT) then
					gui.OpenURL("http://steamcommunity.com/profiles/" .. util.SteamIDTo64(k.SteamID)) -- doesn't work :(
				end
			end
			
			av:SetCursor("hand")
			
			local name = vgui.Create("DLabel")
			steamworks.RequestPlayerInfo(util.SteamIDTo64(k.SteamID))
			timer.Simple(3, function()
				if(not IsValid(name)) then return end
				name:SetText(steamworks.GetPlayerName(util.SteamIDTo64(k.SteamID)))
				name:SizeToContents()
			end)
			name:SetText(k.Name)
			name:SetFont("DermaDefaultBold")
			name:SizeToContents()
			name:SetPos(10 + size + 20, (i - 1) * (size + 15))
			name:SetDark(true)
			name:SetParent(scroll)
			
			local role = vgui.Create("DLabel")
			role:SetText(k.Role)
			role:SizeToContents()
			role:SetPos(10 + size + 20, (i - 1) * (size + 15) + 25)
			role:SetDark(true)
			role:SetParent(scroll)
		end
		
		local thanks = Crimson.CreateLabel("Thank you to anyone else who has contributed ideas and has supported Vermilion throughout development!")
		thanks:SetPos(10, (table.Count(credits)) * (size + 15))
		thanks:SetParent(scroll)
		thanks:SetDark(true)
		
		local gotoWorkshop = Crimson.CreateButton("Open Vermilion Workshop Page", function()
			steamworks.ViewFile("295053419")
		end)
		gotoWorkshop:SetPos(10, (table.Count(credits) + 1) * (size + 15) - 40)
		gotoWorkshop:SetSize(200, 25)
		gotoWorkshop:SetParent(scroll)
		
		local openGithub = Crimson.CreateButton("Open GitHub Repository", function()
			gui.OpenURL("http://github.com/nedhyett/Vermilion")
		end)
		openGithub:SetPos(220, (table.Count(credits) + 1) * (size + 15) - 40)
		openGithub:SetSize(200, 25)
		openGithub:SetParent(scroll)
		
		local geoipPoweredBy = Crimson.CreateLabel("GeoIP Services Powered By the FreeGeoIP project (http://freegeoip.net)!")
		geoipPoweredBy:SetPos(10, (table.Count(credits) + 1.65) * (size + 15) - 40)
		geoipPoweredBy:SetParent(scroll)
		
		local __p = self.TabHolder:AddSheet("Credits", panel, "icon16/award_star_gold_3.png", false, false, "Credits")
		if(GetConVarNumber("crimson_manualpaint") == 1) then
			__p.Tab.Paint = RenderTab
		end
	end
	
	function MENU:BuildClientOpts()
		local clientOptions = vgui.Create("DPanel", self.TabHolder)
		clientOptions:StretchToParent(5, 20, 20, 5)
		if(GetConVarNumber("crimson_manualpaint") == 1) then
			clientOptions.Paint = RenderBody
		end
		
		Crimson:SetDark(true)
		local pos = 10
		for i,box in pairs(EXTENSION.ClientOptions) do
			local cb = Crimson.CreateCheckBox(box[1], box[2], GetConVarNumber(box[2]))
			cb:SetPos(10, pos)
			cb:SetParent(clientOptions)
			pos = pos + 20
		end
		local __p = self.TabHolder:AddSheet("Client Options", clientOptions, "icon16/application.png", false, false, "Client Options")
		if(GetConVarNumber("crimson_manualpaint") == 1) then
			__p.Tab.Paint = RenderTab
		end
	end
	
	function MENU:Show()
		if(self.TabHolder and IsValid(self.TabHolder)) then self.TabHolder:Remove() end
		self.TabHolder = vgui.Create("DPropertySheet", self.Panel)
		self.TabHolder.OldSetTab = self.TabHolder.SetActiveTab
		function self.TabHolder:SetActiveTab(tab)
			MENU.TitleExt = tab:GetText()
			self:OldSetTab(tab)
		end
		self.TabHolder:SetPos(0, 20)
		self.TabHolder:SetSize(MENU.Width, 580)
		
		if(GetConVarNumber("crimson_manualpaint") == 1) then
			self.TabHolder.Paint = function(self, w, h)
				-- body
				surface.SetDrawColor( 100, 0, 0, 200 )
				surface.DrawRect( 0, 0, w, h )
				-- frame
				surface.SetDrawColor( 255, 0, 0, 200 )
				surface.DrawOutlinedRect( 0, 0, w, h )
			end
			self.CloseBtn:SetPos( MENU.Width - 50, 0 )
		end
		
		--self:BuildWelcomeScreen()
		self:BuildClientOpts()
		for i,tab in pairs(EXTENSION.ClientTabs) do
			local tpanel = vgui.Create("DPanel", MENU.TabHolder)
			tpanel:StretchToParent(5, 20, 20, 5)
			if(GetConVarNumber("crimson_manualpaint") == 1) then
				tpanel.Paint = RenderBody
			end
			
			local success,err = pcall(tab[4], tpanel)
			if(not success) then
				Vermilion.Log("Failure while generating client panel " .. tab.ID .. "!")
				Vermilion.Log(err)
				tpanel:Remove()
			else
				Vermilion.Log("Loading client panel " .. i)
				local __p = MENU.TabHolder:AddSheet(tab[1], tpanel, "icon16/" .. tab[2], false, false, tab[3])
				if(GetConVarNumber("crimson_manualpaint") == 1) then
					__p.Tab.Paint = RenderTab
				end
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
				
				Vermilion:RequestRanksList()
				
				Vermilion:RequestWeaponsList()
				
				Vermilion:RequestEntsList()
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
		self.Log("Adding tab " .. tabName .. " with sorting priority " .. tostring(order))
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