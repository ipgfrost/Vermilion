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

-- Crimson is the generic name for any utility library that I create.

Crimson = {}

function Crimson:buildOptionsScreenFromFile(fileName, panel)
	local data = file.Read(fileName, "LUA")
	data = util.KeyValuesToTablePreserveOrder(data)
	self:buildOptionsScreen(data, panel)
end

function Crimson:buildOptionsScreen(layout, panel)
	local objects = {}
	for i,obj in pairs(layout) do
		local inst = nil
		if(obj[1] == "label") then
			inst = self.createLabel(obj[2])
		elseif(obj[1] == "checkbox") then
			inst = self.createCheckBox(obj[2], obj[3], obj[4])
		elseif(obj[1] == "colourmixer") then
			inst = self.createColourMixer(obj[2], obj[3], obj[4], obj[5], obj[6])
		elseif(obj[1] == "button") then
			inst = self.createButton(obj[2], obj[3])
		end
		panel:AddItem(inst)
		table.insert(objects, inst)
	end
	return objects
end

function Crimson.createLabel(text)
	local label = vgui.Create("DLabel")
	label:SetText(text)
	label:SizeToContents()
	label:SetDark(true)
	return label
end

function Crimson.createCheckBox(text, convar, initialValue)
	local checkbox = vgui.Create("DCheckBoxLabel")
	checkbox:SetText(text)
	checkbox:SetConVar(convar)
	checkbox:SetValue(initialValue)
	checkbox:SizeToContents()
	checkbox:SetDark(true)
	return checkbox
end

function Crimson.createColourMixer(palette, alpha, wangs, defaultColour, valueChangedFunc)
	local mixer = vgui.Create("DColorMixer")
	mixer:SetPalette(palette)
	mixer:SetAlphaBar(alpha)
	mixer:SetWangs(wangs)
	mixer:SetColour(defaultColour)
	mixer.ValueChanged = valueChangedFunc
	return mixer
end

function Crimson.createButton(text, onClick)
	local button = vgui.Create("DButton")
	button:SetText(text)
	button:SetDark(true)
	button.DoClick = onClick
	return button 
end

function Crimson.createBinder()
	return vgui.Create("DBinder")
end

function Crimson.createNumberWang(min, max)
	local wang = vgui.Create("DNumberWang")
	wang:SetMinMax(min, max)
	return wang
end

function Crimson.createSlider(text, min, max, decimals, convar)
	local slider = vgui.Create("DNumSlider")
	slider:SetText(text)
	slider:SetMin(min)
	slider:SetMax(max)
	slider:SetDecimals(decimals)
	slider:SetConVar(convar)
	slider:SetDark(true)
	return slider
end

function Crimson.createTextbox(text, panel, convar)
	local textbox = vgui.Create("DTextEntry")
	textbox:SetSize( panel:GetWide(), 35 )
	textbox:SetText( text )
	textbox.OnEnter = function( self )
		RunConsoleCommand(convar, self:GetValue())
	end
	return textbox
end

function Crimson.lookupPlayerByName(name)
	for i,v in pairs(player.GetAll()) do
		if(v:GetName() == name) then
			return v
		end
	end
	return nil
end

function Crimson.lookupPlayerBySteamID(steamid)
	for i,v in pairs(player.GetAll()) do
		if(v:SteamID() == steamid) then
			return v
		end
	end
	return nil
end

function Crimson.tableLen( tab )
	local count = 0
	for _ in pairs( tab ) do count = count + 1 end
	return count
end
