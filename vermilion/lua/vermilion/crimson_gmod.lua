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

-- Crimson is the generic name for any utility library that I create.

Crimson = {}

Crimson.Dark = true

function Crimson:SetDark(dark)
	self.Dark = dark
end

function Crimson:BuildOptionsScreenFromFile(fileName, panel)
	local data = file.Read(fileName, "LUA")
	data = util.KeyValuesToTablePreserveOrder(data)
	self:BuildOptionsScreen(data, panel)
end

function Crimson:BuildOptionsScreen(layout, panel)
	local objects = {}
	for i,obj in pairs(layout) do
		local inst = nil
		if(obj[1] == "label") then
			inst = self.CreateLabel(obj[2])
		elseif(obj[1] == "checkbox") then
			inst = self.CreateCheckBox(obj[2], obj[3], obj[4])
		elseif(obj[1] == "colourmixer") then
			inst = self.CreateColourMixer(obj[2], obj[3], obj[4], obj[5], obj[6])
		elseif(obj[1] == "button") then
			inst = self.CreateButton(obj[2], obj[3])
		end
		panel:AddItem(inst)
		table.insert(objects, inst)
	end
	return objects
end

function Crimson.CreateLabel(text)
	local label = vgui.Create("DLabel")
	label:SetText(text)
	label:SizeToContents()
	label:SetDark(Crimson.Dark)
	return label
end

function Crimson.CreateCheckBox(text, convar, initialValue)
	if(initialValue == nil) then
		initialValue = GetConVarNumber(convar)
	end
	local checkbox = vgui.Create("DCheckBoxLabel")
	checkbox:SetText(text)
	checkbox:SetConVar(convar)
	checkbox:SetValue(initialValue)
	checkbox:SizeToContents()
	checkbox:SetDark(Crimson.Dark)
	return checkbox
end

function Crimson.CreateColourMixer(palette, alpha, wangs, defaultColour, valueChangedFunc)
	local mixer = vgui.Create("DColorMixer")
	mixer:SetPalette(palette)
	mixer:SetAlphaBar(alpha)
	mixer:SetWangs(wangs)
	mixer:SetColour(defaultColour)
	mixer.ValueChanged = valueChangedFunc
	return mixer
end

function Crimson.CreateButton(text, onClick)
	local button = vgui.Create("DButton")
	button:SetText(text)
	button:SetDark(Crimson.Dark)
	button.DoClick = onClick
	return button 
end

function Crimson.CreateBinder()
	return vgui.Create("DBinder")
end

function Crimson.CreateNumberWang(min, max)
	local wang = vgui.Create("DNumberWang")
	wang:SetMinMax(min, max)
	return wang
end

function Crimson.CreateSlider(text, min, max, decimals, convar)
	local slider = vgui.Create("DNumSlider")
	slider:SetText(text)
	slider:SetMin(min)
	slider:SetMax(max)
	slider:SetDecimals(decimals)
	slider:SetConVar(convar)
	slider:SetDark(Crimson.Dark)
	return slider
end

function Crimson.CreateTextbox(text, panel, convar)
	local textbox = vgui.Create("DTextEntry")
	textbox:SetSize( panel:GetWide(), 35 )
	textbox:SetText( text )
	textbox.OnEnter = function( self )
		RunConsoleCommand(convar, self:GetValue())
	end
	return textbox
end

function Crimson.CreateFrame(props)
	local panel = vgui.Create("DFrame")
	if(props['size'] != nil) then
		panel:SetSize(props['size'][1], props['size'][2])
	end
	if(props['pos'] != nil) then
		panel:SetPos(props['pos'][1], props['pos'][2])
	end
	if(props['closeBtn'] != nil) then
		panel:ShowCloseButton(props['closeBtn'])
	end
	if(props['draggable'] != nil) then
		panel:SetDraggable(props['draggable'])
	end
	panel:SetTitle(props['title'])
	if(props['bgBlur'] != nil) then
		panel:SetBackgroundBlur(props['bgBlur'])
	end
	return panel
end

function Crimson:CreateErrorDialog(text)
	local panel = self.CreateFrame(
		{
			['size'] = { 500, 100 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Error",
			['bgBlur'] = true
		}
	)
	panel:MakePopup()
	panel:DoModal()
	panel:SetAutoDelete(true)
	
	
	Crimson:SetDark(false)
	local textLabel = self.CreateLabel(text)
	textLabel:SizeToContents()
	textLabel:SetPos(250 - (textLabel:GetWide() / 2), 30)
	textLabel:SetParent(panel)
	
	local confirmButton = self.CreateButton("OK", function(self)
		panel:Close()
	end)
	confirmButton:SetPos(200, 75)
	confirmButton:SetSize(100, 20)
	confirmButton:SetParent(panel)
	Crimson:SetDark(true)
end

function Crimson:CreateTextInput(text, completeFunc)
	local panel = self.CreateFrame(
		{
			['size'] = { 500, 100 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Error",
			['bgBlur'] = true
		}
	)
	panel:MakePopup()
	panel:DoModal()
	panel:SetAutoDelete(true)
	
	Crimson:SetDark(false)
	local textLabel = self.CreateLabel(text)
	textLabel:SizeToContents()
	textLabel:SetPos(250 - (textLabel:GetWide() / 2), 30)
	textLabel:SetParent(panel)
	
	local textbox = vgui.Create("DTextEntry")
	textbox:SetPos( 10, 50 )
	textbox:SetSize( panel:GetWide() - 20, 20 )
	textbox:SetParent(panel)
	textbox.OnEnter = function(self)
		completeFunc(self:GetValue())
		panel:Close()
	end
	
	local confirmButton = self.CreateButton("OK", function(self)
		completeFunc(textbox:GetValue())
		panel:Close()
	end)
	confirmButton:SetPos(255, 75)
	confirmButton:SetSize(100, 20)
	confirmButton:SetParent(panel)
	
	local cancelButton = self.CreateButton("Cancel", function(self)
		panel:Close()
	end)
	cancelButton:SetPos(145, 75)
	cancelButton:SetSize(100, 20)
	cancelButton:SetParent(panel)
	
	Crimson:SetDark(true)
end

function Crimson.LookupPlayerByName(name)
	for i,v in pairs(player.GetAll()) do
		if(v:GetName() == name) then
			return v
		end
	end
	return nil
end

function Crimson.LookupPlayerBySteamID(steamid)
	for i,v in pairs(player.GetAll()) do
		if(v:SteamID() == steamid) then
			return v
		end
	end
	return nil
end

function Crimson.TableLen( tab )
	local count = 0
	for _ in pairs( tab ) do count = count + 1 end
	return count
end
