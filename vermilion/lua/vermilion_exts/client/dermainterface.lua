-- The MIT License
--
-- Copyright 2014 Ned Hyett.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local EXTENSION = Vermilion:makeExtensionBase()
EXTENSION.Name = "Derma Interface"
EXTENSION.ID = "dermainterface"
EXTENSION.Description = "Gives Vermilion a Derma interface"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}

function EXTENSION:init()
	local MENU = {}
	MENU.width = 600
	MENU.height = 600
	MENU.currentWidth = 0
	MENU.currentHeight = 0
	
	-- Create the menu
	MENU.Panel = vgui.Create("DFrame")
	MENU.Panel:SetSize(0, 0)
	MENU.Panel:SetPos(ScrW() / 2, ScrH() / 2)
	MENU.Panel:ShowCloseButton( false )
	MENU.Panel:SetDraggable(false)
	MENU.Panel:SetTitle("Vermilion")
	
	MENU.Panel:MakePopup()
	MENU.Panel:SetKeyboardInputEnabled( false )
	MENU.Panel:SetVisible(false)
	
	function MENU:show()
		timer.Destroy("Vermilion_MenuHide")
		self.Panel:SetVisible(true)
		self.Panel:SetKeyboardInputEnabled(false)
		self.Panel:SetMouseInputEnabled(true)
		input.SetCursorPos( ScrW() / 2, ScrH() / 2 )
		timer.Create("Vermilion_MenuShow", 1/60, 0, function()
			if(self.currentWidth >= self.width) then
				self.currentWidth = self.width
			else
				self.currentWidth = self.currentWidth + 12
			end
			if(self.currentHeight >= self.height) then
				self.currentHeight = self.height
			else
				self.currentHeight = self.currentHeight + 12
			end
			self.Panel:SetSize(self.currentWidth, self.currentHeight)
			self.Panel:SetPos((ScrW() / 2) - (self.currentWidth / 2), (ScrH() / 2) - (self.currentHeight / 2))
			
			if(self.currentHeight == self.height and self.currentWidth == self.width) then
				timer.Destroy("Vermilion_MenuShow")
			end
		end)
	end
	
	function MENU:hide()
		timer.Destroy("Vermilion_MenuShow")
		self.Panel:SetKeyboardInputEnabled(false)
		self.Panel:SetMouseInputEnabled(false)
		timer.Create("Vermilion_MenuHide", 1/60, 0, function()
			if(self.currentWidth <= 0) then
				self.currentWidth = 0
			else
				self.currentWidth = self.currentWidth - 12
			end
			if(self.currentHeight <= 0) then
				self.currentHeight = 0
			else
				self.currentHeight = self.currentHeight - 12
			end
			self.Panel:SetSize(self.currentWidth, self.currentHeight)
			self.Panel:SetPos((ScrW() / 2) - (self.currentWidth / 2), (ScrH() / 2) - (self.currentHeight / 2))
			
			if(self.currentHeight == 0 and self.currentWidth == 0) then
				self.Panel:SetVisible(false)
				timer.Destroy("Vermilion_MenuHide")
			end
		end)
	end
	
	concommand.Add("+vermilion_menu", function() MENU:show() end)
	concommand.Add("-vermilion_menu", function() MENU:hide() end)
end

Vermilion:registerExtension(EXTENSION)