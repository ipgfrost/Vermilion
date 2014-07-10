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

Vermilion.activated = false

-- Convars
CreateClientConVar("vermilion_alert_sounds", 1, true, false)

-- Networking
net.Receive("Vermilion_Hint", function(len)
	local text = net.ReadString()
	local duration = tonumber(net.ReadString())
	local notifyType = tonumber(net.ReadString())
	notification.AddLegacy( text, notifyType, duration )
	if(notifyType == NOTIFY_ERROR and GetConVarNumber("vermilion_alert_sounds") == 1) then
		sound.PlayFile("sound/alarms/klaxon1.wav", "noplay", function(station, errorID)
			if(IsValid(station)) then
				station:SetVolume(0.1)
				station:Play() 
			else 
				print(errorID)
			end
		end)
	end
	if(notifyType == NOTIFY_GENERIC and GetConVarNumber("vermilion_alert_sounds") == 1) then
		sound.PlayFile("sound/buttons/lever5.wav", "noplay", function(station, errorID)
			if(IsValid(station)) then
				station:SetVolume(0.1)
				station:Play() 
			else 
				print(errorID)
			end
		end)
	end
end)

net.Receive("Vermilion_Sound", function(len)
	local path = net.ReadString()
	sound.PlayFile("sound/" .. path, "", function(station, errorID)
		if(IsValid(station)) then
			station:Play() 
		else 
			print(errorID)
		end
	end)
end)

Vermilion:registerHook( "PopulateToolMenu", "Vermilion-PopulateToolMenu", function()
	spawnmenu.AddToolMenuOption( "Vermilion", "Vermilion", "Vermilion_Options_Client", "Vermilion Client Options", "", "", function( panel )
		panel:ClearControls()
		
		local soundCheckbox = Crimson.createCheckBox("Alert Sounds", "vermilion_alert_sounds", 1)
		panel:AddItem(soundCheckbox)
	end)
end)