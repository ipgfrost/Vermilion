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
EXTENSION.Name = "GeoIP Controller"
EXTENSION.ID = "geoip"
EXTENSION.Description = "Handles GeoIP stuff"
EXTENSION.Author = "Ned"
EXTENSION.NetworkStrings = {
	"VGeoIP"
}

EXTENSION.GeoIPCallbacks = {}


function EXTENSION:InitServer()
	
	self:NetHook("VGeoIP", function(vplayer)
		EXTENSION.GeoIPCallbacks[vplayer:GetName()](net.ReadString())
		EXTENSION.GeoIPCallbacks[vplayer:GetName()] = nil
	end)

	function Vermilion.GetGeoIPForPlayer(vplayer, callback, failcallback)
		failcallback = failcallback or function() end
		if(IsValid(vplayer)) then
			local ip = vplayer:IPAddress()
			if(ip == "Error!") then
				return false
			end
			if(string.StartWith(ip, "192.168")) then --assume internal
				net.Start("VGeoIP")
				EXTENSION.GeoIPCallbacks[vplayer:GetName()] = function(tip)
					http.Fetch( "http://freegeoip.net/json/" .. string.Trim(tip), function(b1, l1, h1, c1)
						if(c1 == 403) then
							print("Used up query quota. If this is a problem, please change set up a local instance of the freegeoip service and change the target.")
							failcallback()
							return
						end
						callback(util.JSONToTable(b1))
					end, function(err)
						print("Error while fetching GeoIP information for " .. tip .. "!")
						print(err)
						failcallback()
					end)
				end
				net.Send(vplayer)
				return
			end
			if(vplayer:IPAddress() == "loopback" or vplayer:IPAddress() == "127.0.0.1") then
				http.Fetch("http://icanhazip.com/", function(body, len, headers, code)
					http.Fetch( "http://freegeoip.net/json/" .. string.Trim(body), function(b1, l1, h1, c1)
						if(c1 == 403) then
							print("Used up query quota. If this is a problem, please change set up a local instance of the freegeoip service and change the target.")
							failcallback()
							return
						end
						callback(util.JSONToTable(b1))
					end, function(err)
						print("Error while fetching GeoIP information for " .. ip .. "!")
						print(err)
						failcallback()
					end)
				end, function(err)
					print("Error while fetching GeoIP information for " .. ip .. "!")
					print(err)
					failcallback()
				end)
				return
			end
			if(string.find(ip, ":")) then
				ip = string.Explode(":", ip)[1]
			end
			http.Fetch( "http://freegeoip.net/json/" .. ip, function(body, len, headers, code)
				if(code == 403) then
					print("Used up query quota. If this is a problem, please change set up a local instance of the freegeoip service and change the target.")
					failcallback()
					return
				end
				callback(util.JSONToTable(body))
			end, function(err)
				print("Error while fetching GeoIP information for " .. ip .. "!")
				print(err)
				failcallback()
			end)
		else
			failcallback()
			return false
		end
	end
	
	Vermilion:AddChatCommand("where", function(sender, text)
		local tplayer = nil
		if(table.Count(text) == 0) then 
			tplayer = sender
		else
			tplayer = Crimson.LookupPlayerByName(text[1], false)
		end
		if(tplayer == nil) then
			Vermilion:SendNotify(sender, Vermilion.Lang.NoSuchPlayer, 5, VERMILION_NOTIFY_ERROR)
			return
		end
		if(not Vermilion.GetGeoIPForPlayer(tplayer, function(tab)
			Vermilion:SendNotify(sender, tplayer:GetName() .. " is located in " .. tab["country_name"])
		end)) then
			--Vermilion:SendNotify(sender, "GeoIP information for this player cannot be determined!", 5, VERMILION_NOTIFY_ERROR)
		end
	end, "[player]")
	
	Vermilion:AddChatPredictor("where", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	self:AddDataChangeHook("enabled", "EnabledHook", function(val)
		SetGlobalBool("VGeoIPHudEnabled", val)
	end)
	
	SetGlobalBool("VGeoIPHudEnabled", EXTENSION:GetData("enabled", true, true))
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "Settings", function()
		if(Vermilion:GetExtension("server_manager") != nil) then
			Vermilion:GetExtension("server_manager"):AddOption("geoip", "enabled", "Enable GeoIP Services", "Checkbox", "Misc", 50, true)
		end
	end)
	
	include("vermilion_exts/geoip/joinnotify.lua")

end

function EXTENSION:InitClient()
	Vermilion:RegisterSafeHook("HUDDrawTargetID", "VTarget", function() -- this needs to go somewhere else when I replace the TargetID. Perhaps use a slots system in the TargetID window?
		if(not GetGlobalBool("VGeoIPHudEnabled", true)) then return end
		
		local tr = util.GetPlayerTrace( LocalPlayer() )
		local trace = util.TraceLine( tr )
		if (!trace.Hit) then return end
		if (!trace.HitNonWorld) then return end
		
		if (not trace.Entity:IsPlayer() or trace.Entity:IsBot()) then
			return
		end
		
		local MouseX, MouseY = gui.MousePos()
		
		if ( MouseX == 0 && MouseY == 0 ) then
		
			MouseX = ScrW() / 2
			MouseY = ScrH() / 2
		
		end
		
		local x = MouseX
		local y = MouseY
		
		x = x - 22 / 2
		y = y + 75

		if(trace.Entity.VCountry == nil or trace.Entity.VCountry == "") then
			trace.Entity.VCountry = string.lower(trace.Entity:GetNWString("Country_Code"))
			trace.Entity.VCountryMat = Material("flags16/" .. trace.Entity.VCountry .. ".png", "noclamp smooth")
		end
		
		surface.SetMaterial(trace.Entity.VCountryMat)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(x, y, 24, 16.5)
		
	end)
	
	self:NetHook("VGeoIP", function() -- called by the server if it cannot determine the correct IP address itself (local network/VPN would cause this sort of issue)
		http.Fetch("http://icanhazip.com/", function(body, len, headers, code)
			net.Start("VGeoIP")
			net.WriteString(body)
			net.SendToServer()
		end, function(err)
		
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)