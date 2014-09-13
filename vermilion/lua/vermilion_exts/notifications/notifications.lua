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
EXTENSION.Name = "Notifications"
EXTENSION.ID = "notifications"
EXTENSION.Description = "Displays notifications on the client."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}
EXTENSION.NetworkStrings = {
	"VNotification"
}
EXTENSION.Notifications = {}

function EXTENSION:InitServer()
	
	function Vermilion:SendNotify(target, text, time, typ)
		if(typ != nil) then
			if(typ < 0) then
				typ = (typ * -1) - 1
			else
				self.Log("Warning: invalid notify type! Reverting to default.")
				typ = nil
			end
		end
		if(typ == nil and time != nil and time < 0) then
			typ = (time * -1) - 1
			time = nil
		end
		if(target == nil or text == nil) then
			self.Log("Attempted to send notification with a nil parameter.")
			self.Log(tostring(target) .. " === " .. text .. " === " .. tostring(time) .. " === " .. tostring(typ))
			return
		end
		if(time == nil) then
			time = 5
		end
		if(typ == nil) then
			typ = NOTIFY_GENERIC
		end
		net.Start("VNotification")
		net.WriteString(text)
		net.WriteString(tostring(typ))
		net.WriteString(tostring(time))
		net.Send(target)
	end
	
	function Vermilion:BroadcastNotify(text, time, typ)
		self:SendNotify(player.GetAll(), text , time, typ)
	end
	
end

function EXTENSION:InitClient()

	CreateClientConVar("vermilion_redirect_notify", 0, true, false)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, function()
		if(Vermilion:GetExtension("dermainterface") != nil) then
			Vermilion:AddClientOption("Redirect notifications to chat", "vermilion_redirect_notify")
		end
	end)
	
	function EXTENSION:AddNotify(text, time, typ, force)
		time = time or 5
		typ = typ or NOTIFY_GENERIC
		local uid = nil
		if(GetConVarNumber("vermilion_redirect_notify") == 1 and not force) then
			local text1 = text
			if(not string.StartWith(text, "[Vermilion] ")) then
				text1 = "[Vermilion] " .. text1
			end
			if(typ == NOTIFY_GENERIC) then
				chat.AddText(Color(0, 255, 0), text1)
			elseif(typ == NOTIFY_ERROR) then
				chat.AddText(Color(255, 0, 0), text1)
			elseif(typ == NOTIFY_HINT) then
				chat.AddText(Color(0, 0, 255), text1)
			end
		else
			local sptext = {}
			local str1 = ""
			for i,k in pairs(string.Explode(" ", "[Vermilion] " .. text)) do
				if(string.len(str1 .. " " .. k) >= 100) then
					table.insert(sptext, string.Trim(str1))
					str1 = ""
				end
				str1 = str1 .. " " .. k
			end
			table.insert(sptext, string.Trim(str1))
			local sptext1 = {}
			for i,k in pairs(sptext) do
				if(k != nil and k != "") then table.insert(sptext1, k) end
			end
			local text1 = table.concat(sptext, "\n")
			uid = util.CRC(tostring(math.random()))
			table.insert(self.Notifications, {Text = text1, Type = typ, Time = os.time() + time, UID = uid})
		end
		if(typ == NOTIFY_ERROR and GetConVarNumber("vermilion_alert_sounds") == 1) then
			sound.PlayFile("sound/alarms/klaxon1.wav", "noplay", function(station, errorID)
				if(IsValid(station)) then
					station:SetVolume(0.1)
					station:Play()
				else
					print(errorID)
				end
			end)
		end
		if(typ == NOTIFY_GENERIC and GetConVarNumber("vermilion_alert_sounds") == 1) then
			sound.PlayFile("sound/buttons/lever5.wav", "noplay", function(station, errorID)
				if(IsValid(station)) then
					station:SetVolume(0.1)
					station:Play()
				else
					print(errorID)
				end
			end)
		end
		if(typ == NOTIFY_HINT and GetConVarNumber("vermilion_alert_sounds") == 1) then
			sound.PlayFile("sound/ambient/machines/thumper_shutdown1.wav", "noplay", function(station, errorID)
				if(IsValid(station)) then
					station:SetVolume(0.5)
					station:Play()
				else
					print(errorID)
				end
			end)
		end
		return uid
	end
	
	function EXTENSION:CancelNotify(uid)
		for i,k in pairs(EXTENSION.Notifications) do
			if(k.UID == uid) then k.Time = 0 end
		end
	end
	
	self:NetHook("VNotification", function()
		local text = net.ReadString()
		local typ = tonumber(net.ReadString())
		local time = tonumber(net.ReadString())
		EXTENSION:AddNotify(text, time, typ)
	end)
	
	self:AddHook("HUDPaint", function()
		surface.SetFont("DermaDefault")
		local deadNotifications = {}
		local ypos = 250
		for i,k in pairs(EXTENSION.Notifications) do
			if(k.Offset == nil) then
				local w = surface.GetTextSize(k.Text)
				w = w + 22
				k.Offset = w
				k.MaxOffset = w
			end
			local w,h = surface.GetTextSize(k.Text)
			if(k.Type == 0) then -- generic (green)
				surface.SetDrawColor(Color(0, 255, 0))
			elseif(k.Type == 3) then -- info (blue)
				surface.SetDrawColor(Color(0, 0, 255))
			elseif(k.Type == 1) then -- error (red)
				surface.SetDrawColor(Color(255, 0, 0))
			end
			surface.DrawRect(ScrW() - 20 - 2 - w + k.Offset, ypos, w + 20, h + 14)
			surface.SetDrawColor(Color(255, 255, 255))
			surface.DrawRect(ScrW() - 20 - w + k.Offset, ypos + 2, w + 16, h + 10)
			surface.SetTextColor(Color(0, 0, 0))
			for i1,k1 in pairs(string.Explode("\n", k.Text)) do
				surface.SetTextPos(ScrW() - 15 - w + k.Offset, ypos + 7 + ((i1 - 1) * 14))
				surface.DrawText(k1)
			end
			if(k.Offset > 0 and k.Time > os.time()) then k.Offset = k.Offset - 5 elseif(k.Time > os.time()) then k.Offset = 0 end
			if(k.Offset < k.MaxOffset and k.Time < os.time()) then k.Offset = k.Offset + 5 end
			if(k.Offset >= k.MaxOffset and k.Time < os.time()) then table.insert(deadNotifications, k) end
			ypos = ypos + h + 20
		end
		for i,k in pairs(deadNotifications) do
			table.RemoveByValue(EXTENSION.Notifications, k)
		end
	end)

end

Vermilion:RegisterExtension(EXTENSION)