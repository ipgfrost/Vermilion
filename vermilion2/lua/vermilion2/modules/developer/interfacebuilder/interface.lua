--[[
 Copyright 2014 Ned Hyett, 

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

VInterfaceBuilder.Interface = {}
local interface = VInterfaceBuilder.Interface

interface.BasePanel = vgui.Create("DFrame")
local BasePanel = interface.BasePanel

BasePanel:SetSize(1300, 700)
BasePanel:DockPadding(0, 29, 0, 0)
BasePanel:SetBackgroundBlur(true)
BasePanel:SetDraggable(false)
BasePanel:SetSizable(false)
BasePanel:SetDeleteOnClose(false)
BasePanel:SetTitle("Vermilion Interface Builder")


BasePanel:Center()
BasePanel:Hide()

function interface:Build()
	self.MenuBar = vgui.Create("DMenuBar", BasePanel)
	self.MenuBar:DockMargin(-3, -6, -3, 0)
	local MenuBar = self.MenuBar
	local File = MenuBar:AddMenu("File")
	File:AddOption("New", function()
	
	end):SetIcon("icon16/page_white_go.png")
	File:AddOption("Save", function()
	
	end):SetIcon("icon16/disk.png")
	File:AddOption("Load", function()
	
	end):SetIcon("icon16/folder_go.png")
	File:AddOption("Export as code", function()
	
	end):SetIcon("icon16/script_code.png")
	local Edit = MenuBar:AddMenu("Edit")
	Edit:AddOption("Edit Base Panel", function()
	
	end):SetIcon("icon16/application_form_edit.png")
	
	local panelProperties = vgui.Create("DProperties")
	panelProperties:Dock(RIGHT)
	panelProperties:SetWide(350)
	panelProperties:SetParent(BasePanel)
	for i=0,100,1 do
		local sw1 = panelProperties:CreateRow("Category1", "Row" .. tostring(i))
		sw1:Setup("VectorColor")
		sw1:SetValue(Vector(1, 0, 0))
	end
	
	local componentsDrawer = VToolkit:CreateLeftDrawer(BasePanel, -((BasePanel:GetWide() / 2) + 55 - 250), false)
	
	local components = VToolkit:CreateList({
		cols = {"Name"},
		multiselect = false
	})
	components:SetWide(250)
	components:Dock(LEFT)
	components:SetParent(componentsDrawer)
	
	local ToggleButton = vgui.Create( "DButton", BasePanel )
	ToggleButton:SetSize( 16, 16 )
	ToggleButton:SetText( "::" )
	ToggleButton.DoClick = function()
		componentsDrawer:Toggle()
	end
	ToggleButton.Think = function()	
		ToggleButton:CenterVertical()
		ToggleButton.x = componentsDrawer.x + componentsDrawer:GetWide() - 8
	end	
	
	for i,k in pairs(derma.GetControlList()) do
		if(k.Description == nil or k.Description == "") then
			components:AddLine(i)
		else
			components:AddLine(i):SetTooltip(k.Description)
		end
	end
	
	local mainview = vgui.Create("DHorizontalScroller")
	mainview:Dock(FILL)
	mainview:SetParent(BasePanel)
	
	componentsDrawer:MoveToFront()
	ToggleButton:MoveToFront()
	components:MoveToFront()
	
end
interface:Build()

function interface:Open()
	self.BasePanel:Show()
	self.BasePanel:MakePopup()
end

concommand.Add("VInterfaceBuilder", function()
	interface:Open()
end)