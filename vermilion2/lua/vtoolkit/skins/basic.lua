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

local Skin = {}

if(CLIENT) then

end

Skin.CreatedBtnFont = false

Skin.CheckboxCross = Material("icon16/cross.png")

Skin.Checkbox = {}
Skin.Checkbox.Config = function(checkbox)
	checkbox:SetTextColor( Color( 0, 0, 0, 255 ) )
end

Skin.Checkbox.Paint = function(self, w, h)
	surface.SetDrawColor( 255, 255, 255, self:GetAlpha() )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( 255, 0, 0, self:GetAlpha() )
	surface.DrawOutlinedRect( 0, 0, w, h )
	surface.SetMaterial( Skin.CheckboxCross )
	if self:GetChecked() then
		surface.DrawTexturedRect( 2, 2, w - 4, h - 4 )
	end
end

Skin.NumberWang = {}
Skin.NumberWang.Paint = function(self, w, h)
	self:OldPaint(w, h)
	surface.SetDrawColor( 255, 0, 0, self:GetAlpha() )
	surface.DrawOutlinedRect( 0, 0, w, h )
end


Skin.Button = {}
Skin.Button.Config = function(button)
	if(not Skin.CreatedBtnFont) then
		if(system.IsOSX() and false) then
			
		else
			surface.CreateFont( 'VToolkitButton', {
				font		= 'Tahoma',
				size		= 13 * (Vermilion.GetActiveLanguageFile(LocalPlayer()).ButtonFontScale or 1),
				weight		= 500,
				additive 	= false,
				antialias 	= true,
				bold		= true,
			} )
		end
		Skin.CreatedBtnFont = true
	end
	button:SetColor(Color(0, 0, 0, 255))
	button:SetFont("VToolkitButton")
end

Skin.Button.Paint = function(self, w, h)
	-- body
	surface.SetDrawColor( 255, 240, 240, self:GetAlpha() )
	surface.DrawRect( 0, 0, w, h )
	-- frame
	surface.SetDrawColor( 255, 0, 0, self:GetAlpha() )
	surface.DrawOutlinedRect( 0, 0, w, h )
end


Skin.Textbox = {}
Skin.Textbox.Config = function(textbox)
	textbox.m_bBackground = false
	textbox.m_colText = Color( 0, 0, 0, 255 )
end

Skin.Textbox.Paint = function( self, w, h )
	surface.SetDrawColor( 255, 255, 255, self:GetAlpha() )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( 255, 0, 0, self:GetAlpha() )
	surface.DrawOutlinedRect( 0, 0, w, h )
	if(self.PlaceholderText != nil and (self:GetValue() == nil or self:GetValue() == "")) then
		surface.SetTextColor(0, 0, 0, 128)
		surface.SetFont(self.m_FontName)
		surface.SetTextPos(2, self:GetTall() / 2 - (select(2, surface.GetTextSize(self.PlaceholderText)) / 2))
		surface.DrawText(self.PlaceholderText)
	end
	self:DrawTextEntryText( self.m_colText, self.m_colHighlight, self.m_colCursor )
end


Skin.Frame = {}
Skin.Frame.Config = function(frame)
	frame.lblTitle:SetBright(true)
end

Skin.Frame.Paint = function( self, w, h )
	-- body
	surface.SetDrawColor( 100, 0, 0, math.Remap(self:GetAlpha(), 0, 255, 0, 200) )
	surface.DrawRect( 0, 0, w, h )
	-- frame
	surface.SetDrawColor( 255, 0, 0, math.Remap(self:GetAlpha(), 0, 255, 0, 200) )
	surface.DrawOutlinedRect( 0, 0, w, h )
end


Skin.WindowPanel = {}
Skin.WindowPanel.Paint = function(self, w, h)
	-- body
	surface.SetDrawColor( 100, 0, 0, math.Remap(self:GetAlpha(), 0, 255, 0, 200) )
	surface.DrawRect( 0, 0, w, h )
	-- frame
	surface.SetDrawColor( 255, 0, 0, math.Remap(self:GetAlpha(), 0, 255, 0, 200) )
	surface.DrawOutlinedRect( 0, 0, w, h )
end


Skin.PropertySheet = {}
Skin.PropertySheet.Paint = function(self, w, h)
	if(self.VHideBG == true) then return end
	-- body
	surface.SetDrawColor( 100, 0, 0, math.Remap(self:GetAlpha(), 0, 255, 0, 200) )
	surface.DrawRect( 0, 0, w, h )
	-- frame
	surface.SetDrawColor( 255, 0, 0, math.Remap(self:GetAlpha(), 0, 255, 0, 200) )
	surface.DrawOutlinedRect( 0, 0, w, h )
end

Skin.PropertySheetTab = {}
Skin.PropertySheetTab.Paint = function(self, w, h)
	surface.SetDrawColor( 100, 0, 0, 255 )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( 255, 0, 0, 255 )
	surface.DrawOutlinedRect( 0, 0, w, h )
end

Skin.CollapsibleCateogryHeader = {}
Skin.CollapsibleCateogryHeader.Paint = function(self, w, h)
	surface.SetDrawColor(255, 0, 0, self:GetAlpha())
	surface.DrawRect(0, 0, w, 20)
end

Skin.ListView = {}
Skin.ListView.Paint = function(self, w, h)
	self:OldPaint(w, h)
	surface.SetDrawColor( 255, 0, 0, self:GetAlpha() )
	surface.DrawOutlinedRect( 0, 0, w, h )
end

Skin.ScrollBarGrip = {}
Skin.ScrollBarGrip.Paint = function(self, w, h)
	if(self.Depressed) then
		surface.SetDrawColor( 255, 0, 0, self:GetAlpha() / 2 )
	elseif(self.Hovered) then
		surface.SetDrawColor( 255, 0, 0, self:GetAlpha() / 1.5 )
	else
		surface.SetDrawColor( 255, 0, 0, self:GetAlpha() )
	end
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(0, 0, 0, self:GetAlpha() / 1.5)
end

Skin.ScrollBarUp = {}
Skin.ScrollBarUp.Paint = function(self, w, h)
	if(self.Depressed) then
		surface.SetDrawColor( 255, 0, 0, self:GetAlpha() / 2 )
	elseif(self.Hovered) then
		surface.SetDrawColor( 255, 0, 0, self:GetAlpha() / 1.5 )
	else
		surface.SetDrawColor( 255, 0, 0, self:GetAlpha() )
	end
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(0, 0, 0, self:GetAlpha() / 1.5)
	surface.DrawOutlinedRect(0, 0, w, h)
	draw.NoTexture()
	surface.DrawPoly({
		{ x = (w / 2) - (w / 3), y = h - 5 },
		{ x = w / 2, y = 5 },
		{ x = (w / 2) + (w / 3), y = h - 5 }
	})

end

Skin.ScrollBarDown = {}
Skin.ScrollBarDown.Paint = function(self, w, h)
	if(self.Depressed) then
		surface.SetDrawColor( 255, 0, 0, self:GetAlpha() / 2 )
	elseif(self.Hovered) then
		surface.SetDrawColor( 255, 0, 0, self:GetAlpha() / 1.5 )
	else
		surface.SetDrawColor( 255, 0, 0, self:GetAlpha() )
	end
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(0, 0, 0, self:GetAlpha() / 1.5)
	surface.DrawOutlinedRect(0, 0, w, h)
	draw.NoTexture()
	surface.DrawPoly({
		{ x = (w / 2) - (w / 3), y = 5 },

		{ x = (w / 2) + (w / 3), y = 5 }, { x = w / 2, y = h - 5 },
	})

end

VToolkit:RegisterSkin("Basic", Skin)
