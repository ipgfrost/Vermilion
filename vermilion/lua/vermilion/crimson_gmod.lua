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

-- Crimson is the generic name for any utility library that I create.

if(CLIENT) then
	CreateClientConVar("crimson_manualpaint", 1, true, false)
end

Crimson = {}

Crimson.Dark = true

if(CLIENT) then
	surface.CreateFont( 'VermilionButton', {
		font		= 'Helvetica',
		size		= 14,
		weight		= 500,
		additive 	= false,
		antialias 	= true,
		bold		= true,
	} )
end

-- net patches
function net.ReadBoolean()
	return net.ReadBit() == 1
end

-- just to make it look nicer
function net.WriteBoolean(bool)
	net.WriteBit(bool)
end

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

function Crimson.CreateLayoutCollection()
	local collection = {}
	collection.items = {}
	
	function collection:AddItem(item)
		table.insert(self.items, item)
	end
	
	function collection:RemoveItem(item)
		table.RemoveByValue(self.items, item)
	end
end

function Crimson.CreateLabel(text)
	local label = vgui.Create("DLabel")
	label:SetText(text)
	label:SizeToContents()
	label:SetDark(Crimson.Dark)
	return label
end

function Crimson:CreateHeaderLabel(object, text)
	local label = self.CreateLabel(text)
	local ox, oy = object:GetPos()
	local xpos = ((object:GetWide() / 2) + ox) - (label:GetWide() / 2)
	local ypos = oy - 20
	label:SetPos(xpos, ypos)
	label.OldSetText = label.SetText
	function label:SetText(text)
		label:OldSetText(text)
		label:SizeToContents()
		local xpos = ((object:GetWide() / 2) + ox) - (label:GetWide() / 2)
		local ypos = oy - 20
		label:SetPos(xpos, ypos)
		end
	return label
end

function Crimson.CreateComboBox(options, selected)
	local cbox = vgui.Create("DComboBox")
	options = options or {}
	for i,k in pairs(options) do
		cbox:AddChoice(k)
	end
	if(isnumber(selected)) then
		cbox:ChooseOptionID(selected)
	end
	return cbox
end

function Crimson.CreateAvatarImage(vplayer, size)
	local sizes = { 16, 32, 64, 84, 128, 184 }
	if(not table.HasValue(sizes, size)) then
		print("Invalid size (" .. tostring(size) .. ") for AvatarImage!")
		return
	end
	local aimg = vgui.Create("AvatarImage")
	aimg:SetSize(size, size)
	if(not isstring(vplayer)) then
		aimg:SetPlayer(vplayer, size)
	else
		aimg:SetSteamID(util.SteamIDTo64(vplayer), size)
	end
	return aimg
end

function Crimson.CreateCheckBox(text, convar, initialValue)
	local cross = Material("icon16/cross.png")
	local checkbox = vgui.Create("DCheckBoxLabel")
	if(convar == nil) then
		checkbox:SetText(text)
		checkbox:SizeToContents()
		checkbox:SetDark(Crimson.Dark)
	else
		if(initialValue == nil) then
			initialValue = GetConVarNumber(convar)
		end
		checkbox:SetText(text)
		checkbox:SetConVar(convar)
		checkbox:SetValue(initialValue)
		checkbox:SizeToContents()
		checkbox:SetDark(Crimson.Dark)
	end
	if(GetConVarNumber("crimson_manualpaint") == 1) then
		checkbox.Button.Paint = function(self, w, h)
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawRect( 0, 0, w, h )
			surface.SetDrawColor( 255, 0, 0, 255 )
			surface.DrawOutlinedRect( 0, 0, w, h )
			surface.SetMaterial( cross )
			if checkbox:GetChecked() then
				surface.DrawTexturedRect( 2, 2, w - 4, h - 4 )
			end
		end
		checkbox:SetTextColor( Color( 0, 0, 0, 255 ) )
	end
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
	if(GetConVarNumber("crimson_manualpaint") == 1) then
		button:SetColor(Color(0, 0, 0, 255))
		button:SetFont("VermilionButton")
		button.Paint = function(self)
			local w, h = self:GetWide(), self:GetTall()
			-- body
			surface.SetDrawColor( 255, 240, 240, 255 )
			surface.DrawRect( 0, 0, w, h )
			-- frame
			surface.SetDrawColor( 255, 0, 0, 255 )
			surface.DrawOutlinedRect( 0, 0, w, h )
		end
	end
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
	if(convar == nil) then
		textbox:SetSize(panel:GetWide(), 35)
		textbox:SetText(text)
		return textbox
	else
		textbox:SetSize( panel:GetWide(), 35 )
		textbox:SetText( text )
		textbox.OnEnter = function( self )
			RunConsoleCommand(convar, self:GetValue())
		end
	end
	if(GetConVarNumber("crimson_manualpaint") == 1) then
		textbox.m_bBackground = false
		textbox.m_colText = Color( 0, 0, 0, 255 )
		local oldpaint = textbox.Paint
		textbox.Paint = function( self, w, h )
			oldpaint( self, w, h )
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawRect( 0, 0, w, h )
			surface.SetDrawColor( 255, 0, 0, 255 )
			surface.DrawOutlinedRect( 0, 0, w, h )
		end
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
	panel.lblTitle:SetBright(true)
	if(GetConVarNumber("crimson_manualpaint") == 1) then
		panel.Paint = function( self, w, h ) 
			-- body
			surface.SetDrawColor( 100, 0, 0, 200 )
			surface.DrawRect( 0, 0, w, h )
			-- frame
			surface.SetDrawColor( 255, 0, 0, 200 )
			surface.DrawOutlinedRect( 0, 0, w, h )
		end
	end
	return panel
end

function Crimson:CreateDialog(title, text)
	local panel = self.CreateFrame(
		{
			['size'] = { 500, 100 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - " .. title,
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
	textLabel:SetBright(true)
	
	local confirmButton = self.CreateButton("OK", function(self)
		panel:Close()
	end)
	confirmButton:SetPos(200, 75)
	confirmButton:SetSize(100, 20)
	confirmButton:SetParent(panel)
	Crimson:SetDark(true)
end

function Crimson:CreateErrorDialog(text)
	local panel = self.CreateFrame(
		{
			['size'] = { 500, 100 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - Error",
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
	textLabel:SetBright(true)
	
	local confirmButton = self.CreateButton("OK", function(self)
		panel:Close()
	end)
	confirmButton:SetPos(200, 75)
	confirmButton:SetSize(100, 20)
	confirmButton:SetParent(panel)
	Crimson:SetDark(true)
end

function Crimson:CreateConfirmDialog(text, completeFunc)
	local panel = self.CreateFrame(
		{
			['size'] = { 500, 100 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - Confirm",
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
	textLabel:SetBright(true)
	
	local confirmButton = self.CreateButton("OK", function(self)
		completeFunc()
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

function Crimson:CreateTextInput(text, completeFunc)
	local panel = self.CreateFrame(
		{
			['size'] = { 500, 100 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - Text Entry Required",
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
	textLabel:SetBright(true)
	
	local textbox = Crimson.CreateTextbox("", panel)
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

function Crimson.CreateList(cols, multiselect, sortable)
	if(sortable == nil) then sortable = true end
	if(multiselect == nil) then multiselect = true end
	local lst = vgui.Create("DListView")
	lst:SetMultiSelect(multiselect)
	for i,col in pairs(cols) do
		lst:AddColumn(col)
	end
	if(not sortable) then
		lst:SetSortable(false)
		function lst:SortByColumn(ColumnID, Desc) end
	end
	return lst
end

function Crimson.LookupPlayerByName(name, casesensitive)
	local results = {}
	if(name == nil) then return nil end
	if(casesensitive == nil) then casesensitive = true end
	if(not casesensitive) then
		for i,v in pairs(player.GetAll()) do
			if(string.lower(v:GetName()) == string.lower(name)) then
				table.insert(results, v)
			end
		end
	else
		for i,v in pairs(player.GetAll()) do
			if(v:GetName() == name) then
				table.insert(results, v)
			end
		end
	end
	if(table.Count(results) == 1) then
		return results[1]
	elseif(table.Count(results) > 1 and not casesensitive) then
		print("Ambiguous search results for username '" .. name .. "'. Reverting to case sensitive search.")
		for i,v in pairs(results) do
			if(v:GetName() == name) then
				return v
			end
		end
	elseif(table.Count(results) > 1 and not casesensitive) then
		print("Warning: ambiguous search results for username '" .. name .. "' even though using case sensitive search. Indicative of name hijacking.")
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


function Crimson.SearchRecursively(searchdir, basedir, fileType)
	local files, dirs = file.Find(basedir .. "/*", searchdir)
	local f2 = {}
	for i,k in pairs(files) do
		if(string.EndsWith(k, fileType)) then table.insert(f2, k) end
	end
	files = f2
	for i,k in pairs(dirs) do
		local f1,d1 = Crimson.SearchRecursively(searchdir, basedir .. "/" .. k, fileType)
		for i1,k1 in pairs(f1) do 
			if(string.EndsWith(k1, fileType)) then
				if(string.StartWith(k1, basedir)) then
					table.insert(files, k .. "/" .. k1)
				else
					table.insert(files, basedir .. "/" .. k .. "/" .. k1)
				end
			end
		end
		
	end
	return files
end

function Crimson.CheckAllValid(entList)
	for i,v in pairs(entList) do -- arg is created by ...
		if(not IsValid(v)) then return false end
	end
	return true
end

function Crimson.CBound(p1, p2)
	local CBound = {}
	CBound.p1 = p1
	CBound.p2 = p2
	
	function CBound:IsInside(point)
		if(isentity(point) and point:IsPlayer()) then
			return point:GetPos():WithinAABox(self.p1, self.p2) or point:GetPos():WithinAABox(self.p2, self.p1) or (point:GetPos() + Vector(0, 0, 80)):WithinAABox(self.p1, self.p2) or (point:GetPos() + Vector(0, 0, 80)):WithinAABox(self.p2, self.p1)
		end
		if(isentity(point)) then return point:GetPos():WithinAABox(self.p1, self.p2) or point:GetPos():WithinAABox(self.p2, self.p1) end
		return point:WithinAABox(self.p1, self.p2) or point:WithinAABox(self.p2, self.p1)
	end
	
	function CBound:GetEnts()
		return ents.FindInBox(self.p1, self.p2)
	end
	
	function CBound:Intersects(ocbound)
		for i,k in pairs(ocbound:GetAllVertices()) do
			if(self:IsInside(k)) then return true end
		end
		for i,k in pairs(self:GetAllVertices()) do
			if(ocbound:IsInside(k)) then return true end
		end
		return false
	end
	
	function CBound:GetAllVertices()
		local verts = {}
		table.insert(verts, self.p1)
		table.insert(verts, self.p2)
		table.insert(verts, Vector(self.p1.x, self.p2.y, self.p1.z))
		table.insert(verts, Vector(self.p2.x, self.p1.y, self.p1.z))
		table.insert(verts, Vector(self.p2.x, self.p2.y, self.p1.z))
		table.insert(verts, Vector(self.p1.x, self.p2.y, self.p2.z))
		table.insert(verts, Vector(self.p2.x, self.p1.y, self.p2.z))
		table.insert(verts, Vector(self.p1.x, self.p1.y, self.p2.z))
		return verts
	end
	
	function CBound:Volume()
		local p1w = Vector(self.p1.x, self.p2.y, self.p1.z)
		local p1l = Vector(self.p2.x, self.p1.y, self.p1.z)
		local p1h = Vector(self.p1.x, self.p1.y, self.p2.z)
		
		local saTop = self.p1:Distance(p1w) * self.p1:Distance(p1l)
		return saTop * self.p1:Distance(p1h)
	end
	
	function CBound:SurfaceArea()
		return -1 --cba to do this now
	end
	
	return CBound
end

function Crimson.PerPlayerStorage()
	local storage = {}
	storage.data = {}
	
	function storage:Store(vplayer, key, data)
		if(self.data[vplayer:SteamID()] == nil) then self.data[vplayer:SteamID()] = {} end
		self.data[vplayer:SteamID()][key] = data
	end
	
	function storage:Get(vplayer, key, default)
		if(self.data[vplayer:SteamID()] != nil) then
			if(self.data[vplayer:SteamID()][key] != nil) then return self.data[vplayer:SteamID()][key] end
		end
		return default
	end
	
	function storage:GetPlayerData(vplayer)
		return self.data[vplayer:SteamID()]
	end
	
	function storage:Remove(vplayer, key)
		if(self.data[vplayer:SteamID()] != nil) then
			self.data[vplayer:SteamID()][key] = nil
		end
	end
	
	function storage:HasData(vplayer, key)
		if(self.data[vplayer:SteamID()] != nil) then
			return self.data[vplayer:SteamID()][key] != nil
		end
		return false
	end
	
	function storage:HasPlayer(vplayer)
		return self.data[vplayer:SteamID()] != nil
	end
	
	function storage:Clear(vplayer)
		if(vplayer == nil) then
			self.data[vplayer:SteamID()] = nil
		else
			self.data = {}
		end
	end
	
	function storage:ToJSON()
		return util.TableToJSON(self.data)
	end
end

function Crimson.FindInTable(tab, sorter)
	local rtab = {}
	for i,k in pairs(tab) do
		if(sorter(k)) then rtab[i] = k end
	end
	return rtab
end

function Crimson.NetSanitiseTable(tab)
	local rtab = {}
	for i,k in pairs(tab) do
		if(istable(k)) then rtab[i] = Crimson.NetSanitiseTable(k) else
			if(not (isfunction(k))) then
				rtab[i] = k
			end
		end
	end
	return rtab
end

function Crimson.TimeTable()
	local time = os.date("*t")
	local wday = time.wday - 1
	if(wday == 0) then wday = 7 end
	time.wday = wday
	return time
end

function Crimson.PrintTable ( t, indent, done, log )

	done = done or {}
	indent = indent or 0

	for key, value in pairs (t) do

		log( string.rep ("\t", indent) )

		if  ( istable(value) && !done[value] ) then

			done [value] = true
			log( tostring(key) .. ":" .. "\n" );
			Crimson.PrintTable (value, indent + 2, done, log)

		else

			log( tostring (key) .. "\t=\t" )
			log( tostring(value) .. "\n" )

		end

	end

end

function Crimson.Merge(destination, source)
	for i,k in pairs(source) do
		local has = false
		for i1,k1 in pairs(destination) do
			if(k1 == k) then has = true break end
		end
		if(not has) then table.insert(destination, k) end
	end
end