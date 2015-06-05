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

--[[
	GENERIC = Blue ("Exclamation")
	ERROR = Red ("Error Triangle")
	HINT = Green ("Help Orb")
]]--

Vermilion:AddHook(Vermilion.Event.MOD_LOADED, "AddJoinLeaveOption", true, function()
	local mod = Vermilion:GetModule("server_settings")
	if(mod != nil) then
		mod:AddOption({
			Module = "Vermilion",
			Name = "joinleave_enabled",
			GuiText = Vermilion:TranslateStr("config:joinleave_enabled"),
			Type = "Checkbox",
			Category = "Misc",
			Default = true
			})
	end
end)

if(CLIENT) then
	local notifications = {}

	local notifybg = nil

	timer.Simple(1, function()
		notifybg = vgui.Create("DPanel")
		notifybg:SetDrawBackground(false)
		notifybg:SetPos(ScrW() - 298, 100)
		notifybg:SetSize(300, ScrH() + 100)
	end)

	timer.Create("VOrganiseNotify", 0.1, 0, function()
		local currentY = 0
		for i,k in pairs(notifications) do
			if(IsValid(k)) then
				k.OldIY = k.IntendedY
				k.IntendedY = (currentY + (k.MaxH / 2))
				if(k.OldIY != k.IntendedY and k.DoneMain) then
					local mt = k.IntendedY - (k.MaxH / 2)
					k:MoveTo(k:GetX(), mt, 0.2, 0, -3)
				end
				currentY = currentY + (k.MaxH + 5)
			end
		end
	end)

	local function DrawErrorSign( x, y, w, h )
		local clr = ( CurTime() % 0.8 > 0.2 ) and Vermilion.Colours.Red or Color( 0, 0, 0, 0 )
		surface.SetDrawColor( clr )
		surface.SetTextColor( clr )
		surface.DrawLine( x, y + h, x + w / 2, y )
		surface.DrawLine( x + w, y + h, x + w / 2, y )
		surface.DrawLine( x + w, y + h, x, y + h )
		surface.SetFont( 'DermaDefaultBold' )
		if(system.IsOSX()) then
			surface.SetTextPos( (x + w / 2) - 2.75, y + h / 3 )
		else
			surface.SetTextPos( (x + w / 2) - 0.25, y + h / 3 )
		end
		surface.DrawText( '!' )
	end

	local function DrawNoteSign( x, y, w, h )
		surface.SetTextColor( 100, 150, 255, 255 * math.Clamp( math.sin( CurTime() * 4 ), 0.5, 1 ) )
		surface.SetFont( 'DermaLarge' )
		if(system.IsOSX()) then
			surface.SetTextPos( x + w / 2 - surface.GetTextSize( '!' ) / 2, y - 2)
		else
			surface.SetTextPos( x + w / 2 - surface.GetTextSize( '!' ) / 2, y )
		end
		surface.DrawText( '!' )
	end

	local function DrawHintSign(x, y, w, h)
		surface.SetTextColor( 50, 255, 50, 255 * math.Clamp(math.sin(CurTime() * 4), 0.5, 1))
		surface.SetFont('DermaLarge')
		if(system.IsOSX()) then
			surface.SetTextPos( x + w / 2 - surface.GetTextSize( '?' ) / 2, y - 2 )
		else
			surface.SetTextPos( x + w / 2 - surface.GetTextSize( '?' ) / 2, y )
		end
		surface.DrawText("?")
	end

	local function breakNotification(text, max)
		local wordsBuffer = {}
		local lines = {}

		local u = string.Split(text, " ")
		local f = {}
		for i,k in pairs(u) do
			local m = string.Split(k, "\n")
			local j = {}
			for q,r in pairs(m) do
				table.insert(j, r)
				table.insert(j, "\n")
			end
			table.remove(j, table.Count(j))
			table.Add(f, j)
		end

		for i,word in ipairs(f) do -- iterate over words
			local w, h = surface.GetTextSize(table.concat(wordsBuffer, " "))
			if (w > max or word == "\n") then
				table.insert(lines, table.concat(wordsBuffer, " "))
				table.Empty(wordsBuffer)
				if(word != "\n") then table.insert(wordsBuffer, word) end
			elseif(word != "\n") then
				table.insert(wordsBuffer, word)
			end
		end

		if (table.Count(wordsBuffer) > 0) then
			table.insert(lines, table.concat(wordsBuffer, " "))
		end

		return lines
	end


	local function buildNotify(text, typ)
		local notify = vgui.Create("DPanel")
		notify:DockMargin(0, 0, 0, 5)

		surface.SetFont('DermaDefaultBold')
		local size = select(2, surface.GetTextSize("Vermilion")) + 3
		surface.SetFont("DermaDefault")
		local data = breakNotification(text, 220)
		for i,k in pairs(data) do
			if(k == "\n") then continue end
			size = size + select(2, surface.GetTextSize(k)) + 1
		end
		notify.MaxW = 300
		notify.MaxH = size + 5
		notify:SetSize(0, 0)

		notify.TYPE = typ or NOTIFY_GENERIC
		notify.TEXT = data

		notify.Paint = function( self, w, h )
			surface.SetDrawColor( 5, 5, 5, 220 )
			surface.DrawRect( 0, 0, w, h )
			local iconsize = h - 10
			if(self.TYPE == NOTIFY_ERROR) then DrawErrorSign( w - 30, 5, 20, 20 ) surface.SetDrawColor( Vermilion.Colours.Red ) surface.SetTextColor( Vermilion.Colours.Red ) end
			if(self.TYPE == NOTIFY_GENERIC) then DrawNoteSign( w - 30, 2, 20, 20 ) surface.SetDrawColor( 100, 150, 255, 255 ) surface.SetTextColor( 100, 150, 255, 255 ) end
			if(self.TYPE == NOTIFY_HINT) then DrawHintSign( w - 30, 2, 20, 20 ) surface.SetDrawColor( 50, 255, 50, 255) surface.SetTextColor( 50, 255, 50, 255) end
			surface.DrawOutlinedRect( 0, 0, w, h )

			surface.SetTextPos( 5, 2 )
			surface.SetFont( 'DermaDefaultBold' )
			surface.DrawText( 'Vermilion' )

			local offset = 1
			surface.SetTextPos( 5, select(2, surface.GetTextSize("Vermilion")) + 4)
			surface.SetFont( 'DermaDefault' )
			for i,k in pairs(data) do
				if(k == "\n") then continue end
				surface.SetTextPos( 5, select(2, surface.GetTextSize("Vermilion")) + 3 + (select(2, surface.GetTextSize(data[1])) * (i - 1)))
				surface.DrawText(k)
			end

		end

		return notify
	end


	function Vermilion:AddNotification(text, typ, time)
		if(notifybg == nil) then
			Vermilion.Log("Warning: notification area not initialised while sending notification: " .. text)
			return
		end
		local notify = buildNotify(text, typ)
		notify.IntendedX = 300
		local stser = 0
		for i,k in pairs(notifybg:GetChildren()) do
			stser = stser + k.MaxH + 5
		end
		--if(table.Count(notifybg:GetChildren()) != 0) then
			stser = stser - 5
		--end
		notify.IntendedY = stser + (notify.MaxH / 2)
		notify:SetParent(notifybg)
		table.insert(notifications, notify)

		local anim = VToolkit:CreateNotificationAnimForPanel(notify)
		local finished = false
		local animData = {
			Pos = -1,
			OnlyOne = table.Count(notifybg:GetChildren()) == 1,
			NotifyPanel = notifybg,
			Callback = function()
				finished = true
				notify.DoneMain = true
				timer.Simple(time or 10, function()
					if(not IsValid(notify) or not table.HasValue(notifications, notify)) then return end
					notify:AlphaTo(0, 2, 0, function()
						table.RemoveByValue(notifications, notify)
						notify:Remove()
					end)
				end)
			end
		}

		notify.AnimationThink = function()
			if(not finished) then anim:Run() else notify.AnimationThink = nil end
		end

		anim:Start(3, animData)
		return function()
			notify:AlphaTo(0, 2, 0, function()
				table.RemoveByValue(notifications, notify)
				notify:Remove()
			end)
		end
	end

	function Vermilion:AddNotify(text, typ, time)
		self:AddNotification(text, typ, time)
	end

	net.Receive("VNotify", function()
		local notifyData = net.ReadTable()
		Vermilion:AddNotification(Vermilion:TranslateStr(notifyData.BaseString, notifyData.Replacements), net.ReadInt(32), net.ReadInt(32))
	end)

else
	util.AddNetworkString("VNotify")

	function Vermilion:AddNotification(recipient, baseString, replacements, typ, time)
		typ = typ or NOTIFY_GENERIC
		time = time or 10
		net.Start("VNotify")
		net.WriteTable({ BaseString = baseString, Replacements = replacements })
		net.WriteInt(typ, 32)
		net.WriteInt(time, 32)
		net.Send(recipient)
	end

	function Vermilion:AddNotify(recipient, baseString, replacements, typ, time)
		self:AddNotification(recipient, baseString, replacements, typ, time)
	end

	function Vermilion:BroadcastNotification(baseString, replacements, typ, time)
		Vermilion.Log("[Notification:Broadcast] " .. Vermilion:TranslateStr(baseString, replacements))
		self:AddNotification(VToolkit.GetValidPlayers(false), baseString, replacements, typ, time)
	end

	function Vermilion:BroadcastNotify(baseString, replacements, typ, time)
		self:BroadcastNotification(baseString, replacements, typ, time)
	end

end
